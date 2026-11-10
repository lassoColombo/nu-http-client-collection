# Auto-generated client for Amazon EC2 Container Service v2014-11-13
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ecs/2014-11-13/openapi.json
# Auth: --token flag or $env.AMAZON_EC2_CONTAINER_SERVICE_TOKEN

const BASE_URL = "http://ecs.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_EC2_CONTAINER_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://ecs.us-east-1.amazonaws.com" "http://ecs.us-east-2.amazonaws.com" "http://ecs.us-west-1.amazonaws.com" "http://ecs.us-west-2.amazonaws.com" "http://ecs.us-gov-west-1.amazonaws.com" "http://ecs.us-gov-east-1.amazonaws.com" "http://ecs.ca-central-1.amazonaws.com" "http://ecs.eu-north-1.amazonaws.com" "http://ecs.eu-west-1.amazonaws.com" "http://ecs.eu-west-2.amazonaws.com" "http://ecs.eu-west-3.amazonaws.com" "http://ecs.eu-central-1.amazonaws.com" "http://ecs.eu-south-1.amazonaws.com" "http://ecs.af-south-1.amazonaws.com" "http://ecs.ap-northeast-1.amazonaws.com" "http://ecs.ap-northeast-2.amazonaws.com" "http://ecs.ap-northeast-3.amazonaws.com" "http://ecs.ap-southeast-1.amazonaws.com" "http://ecs.ap-southeast-2.amazonaws.com" "http://ecs.ap-east-1.amazonaws.com" "http://ecs.ap-south-1.amazonaws.com" "http://ecs.sa-east-1.amazonaws.com" "http://ecs.me-south-1.amazonaws.com" "https://ecs.us-east-1.amazonaws.com" "https://ecs.us-east-2.amazonaws.com" "https://ecs.us-west-1.amazonaws.com" "https://ecs.us-west-2.amazonaws.com" "https://ecs.us-gov-west-1.amazonaws.com" "https://ecs.us-gov-east-1.amazonaws.com" "https://ecs.ca-central-1.amazonaws.com" "https://ecs.eu-north-1.amazonaws.com" "https://ecs.eu-west-1.amazonaws.com" "https://ecs.eu-west-2.amazonaws.com" "https://ecs.eu-west-3.amazonaws.com" "https://ecs.eu-central-1.amazonaws.com" "https://ecs.eu-south-1.amazonaws.com" "https://ecs.af-south-1.amazonaws.com" "https://ecs.ap-northeast-1.amazonaws.com" "https://ecs.ap-northeast-2.amazonaws.com" "https://ecs.ap-northeast-3.amazonaws.com" "https://ecs.ap-southeast-1.amazonaws.com" "https://ecs.ap-southeast-2.amazonaws.com" "https://ecs.ap-east-1.amazonaws.com" "https://ecs.ap-south-1.amazonaws.com" "https://ecs.sa-east-1.amazonaws.com" "https://ecs.me-south-1.amazonaws.com" "http://ecs.cn-north-1.amazonaws.com.cn" "http://ecs.cn-northwest-1.amazonaws.com.cn" "https://ecs.cn-north-1.amazonaws.com.cn" "https://ecs.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AmazonEC2ContainerServiceV20141113.CreateCapacityProvider"] }
def x-amz-target-completer-1 [] { ["AmazonEC2ContainerServiceV20141113.CreateCluster"] }
def launch-type-completer [] { ["EC2" "EXTERNAL" "FARGATE"] }
def scheduling-strategy-completer [] { ["DAEMON" "REPLICA"] }
def propagate-tags-completer [] { ["NONE" "SERVICE" "TASK_DEFINITION"] }
def x-amz-target-completer-2 [] { ["AmazonEC2ContainerServiceV20141113.CreateService"] }
def x-amz-target-completer-3 [] { ["AmazonEC2ContainerServiceV20141113.CreateTaskSet"] }
def name-completer [] { ["awsvpcTrunking" "containerInsights" "containerInstanceLongArnFormat" "fargateFIPSMode" "serviceLongArnFormat" "tagResourceAuthorization" "taskLongArnFormat"] }
def x-amz-target-completer-4 [] { ["AmazonEC2ContainerServiceV20141113.DeleteAccountSetting"] }
def x-amz-target-completer-5 [] { ["AmazonEC2ContainerServiceV20141113.DeleteAttributes"] }
def x-amz-target-completer-6 [] { ["AmazonEC2ContainerServiceV20141113.DeleteCapacityProvider"] }
def x-amz-target-completer-7 [] { ["AmazonEC2ContainerServiceV20141113.DeleteCluster"] }
def x-amz-target-completer-8 [] { ["AmazonEC2ContainerServiceV20141113.DeleteService"] }
def x-amz-target-completer-9 [] { ["AmazonEC2ContainerServiceV20141113.DeleteTaskDefinitions"] }
def x-amz-target-completer-10 [] { ["AmazonEC2ContainerServiceV20141113.DeleteTaskSet"] }
def x-amz-target-completer-11 [] { ["AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance"] }
def x-amz-target-completer-12 [] { ["AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition"] }
def x-amz-target-completer-13 [] { ["AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders"] }
def x-amz-target-completer-14 [] { ["AmazonEC2ContainerServiceV20141113.DescribeClusters"] }
def x-amz-target-completer-15 [] { ["AmazonEC2ContainerServiceV20141113.DescribeContainerInstances"] }
def x-amz-target-completer-16 [] { ["AmazonEC2ContainerServiceV20141113.DescribeServices"] }
def x-amz-target-completer-17 [] { ["AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition"] }
def x-amz-target-completer-18 [] { ["AmazonEC2ContainerServiceV20141113.DescribeTaskSets"] }
def x-amz-target-completer-19 [] { ["AmazonEC2ContainerServiceV20141113.DescribeTasks"] }
def x-amz-target-completer-20 [] { ["AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint"] }
def x-amz-target-completer-21 [] { ["AmazonEC2ContainerServiceV20141113.ExecuteCommand"] }
def x-amz-target-completer-22 [] { ["AmazonEC2ContainerServiceV20141113.GetTaskProtection"] }
def x-amz-target-completer-23 [] { ["AmazonEC2ContainerServiceV20141113.ListAccountSettings"] }
def target-type-completer [] { ["container-instance"] }
def x-amz-target-completer-24 [] { ["AmazonEC2ContainerServiceV20141113.ListAttributes"] }
def x-amz-target-completer-25 [] { ["AmazonEC2ContainerServiceV20141113.ListClusters"] }
def status-completer [] { ["ACTIVE" "DEREGISTERING" "DRAINING" "REGISTERING" "REGISTRATION_FAILED"] }
def x-amz-target-completer-26 [] { ["AmazonEC2ContainerServiceV20141113.ListContainerInstances"] }
def x-amz-target-completer-27 [] { ["AmazonEC2ContainerServiceV20141113.ListServices"] }
def x-amz-target-completer-28 [] { ["AmazonEC2ContainerServiceV20141113.ListServicesByNamespace"] }
def x-amz-target-completer-29 [] { ["AmazonEC2ContainerServiceV20141113.ListTagsForResource"] }
def status-completer-1 [] { ["ACTIVE" "ALL" "INACTIVE"] }
def x-amz-target-completer-30 [] { ["AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies"] }
def status-completer-2 [] { ["ACTIVE" "DELETE_IN_PROGRESS" "INACTIVE"] }
def sort-completer [] { ["ASC" "DESC"] }
def x-amz-target-completer-31 [] { ["AmazonEC2ContainerServiceV20141113.ListTaskDefinitions"] }
def desired-status-completer [] { ["PENDING" "RUNNING" "STOPPED"] }
def x-amz-target-completer-32 [] { ["AmazonEC2ContainerServiceV20141113.ListTasks"] }
def x-amz-target-completer-33 [] { ["AmazonEC2ContainerServiceV20141113.PutAccountSetting"] }
def x-amz-target-completer-34 [] { ["AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault"] }
def x-amz-target-completer-35 [] { ["AmazonEC2ContainerServiceV20141113.PutAttributes"] }
def x-amz-target-completer-36 [] { ["AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders"] }
def x-amz-target-completer-37 [] { ["AmazonEC2ContainerServiceV20141113.RegisterContainerInstance"] }
def network-mode-completer [] { ["awsvpc" "bridge" "host" "none"] }
def pid-mode-completer [] { ["host" "task"] }
def ipc-mode-completer [] { ["host" "none" "task"] }
def x-amz-target-completer-38 [] { ["AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition"] }
def x-amz-target-completer-39 [] { ["AmazonEC2ContainerServiceV20141113.RunTask"] }
def x-amz-target-completer-40 [] { ["AmazonEC2ContainerServiceV20141113.StartTask"] }
def x-amz-target-completer-41 [] { ["AmazonEC2ContainerServiceV20141113.StopTask"] }
def x-amz-target-completer-42 [] { ["AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges"] }
def x-amz-target-completer-43 [] { ["AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange"] }
def x-amz-target-completer-44 [] { ["AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange"] }
def x-amz-target-completer-45 [] { ["AmazonEC2ContainerServiceV20141113.TagResource"] }
def x-amz-target-completer-46 [] { ["AmazonEC2ContainerServiceV20141113.UntagResource"] }
def x-amz-target-completer-47 [] { ["AmazonEC2ContainerServiceV20141113.UpdateCapacityProvider"] }
def x-amz-target-completer-48 [] { ["AmazonEC2ContainerServiceV20141113.UpdateCluster"] }
def x-amz-target-completer-49 [] { ["AmazonEC2ContainerServiceV20141113.UpdateClusterSettings"] }
def x-amz-target-completer-50 [] { ["AmazonEC2ContainerServiceV20141113.UpdateContainerAgent"] }
def x-amz-target-completer-51 [] { ["AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState"] }
def x-amz-target-completer-52 [] { ["AmazonEC2ContainerServiceV20141113.UpdateService"] }
def x-amz-target-completer-53 [] { ["AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet"] }
def x-amz-target-completer-54 [] { ["AmazonEC2ContainerServiceV20141113.UpdateTaskProtection"] }
def x-amz-target-completer-55 [] { ["AmazonEC2ContainerServiceV20141113.UpdateTaskSet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-capacity-provider" "create-cluster" "create-service" "create-task-set" "delete-account-setting" "delete-attributes" "delete-capacity-provider" "delete-cluster" "delete-service" "delete-task-definitions" "delete-task-set" "deregister-container-instance" "deregister-task-definition" "describe-capacity-providers" "describe-clusters" "describe-container-instances" "describe-services" "describe-task-definition" "describe-task-sets" "describe-tasks" "discover-poll-endpoint" "execute-command" "get-task-protection" "list-account-settings" "list-attributes" "list-clusters" "list-container-instances" "list-services" "list-services-by-namespace" "list-tags-for-resource" "list-task-definition-families" "list-task-definitions" "list-tasks" "put-account-setting" "put-account-setting-default" "put-attributes" "put-cluster-capacity-providers" "register-container-instance" "register-task-definition" "run-task" "start-task" "stop-task" "submit-attachment-state-changes" "submit-container-state-change" "submit-task-state-change" "tag-resource" "untag-resource" "update-capacity-provider" "update-cluster" "update-cluster-settings" "update-container-agent" "update-container-instances-state" "update-service" "update-service-primary-task-set" "update-task-protection" "update-task-set" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
  scope commands | where decl_id in $cmd_ids | each {|cmd|
    let sig = $cmd.signatures | values | first
    let params = $sig
      | where parameter_type not-in ["input" "output"]
      | where parameter_name not-in $builtin_flags
      | select parameter_name parameter_type syntax_shape is_optional description
    let return_type = ($sig | where parameter_type == "output" | get -o syntax_shape | first | default "any")
    {
      name: ($cmd.name | str replace $"($mod_name) " "")
      description: $cmd.description
      extra_description: $cmd.extra_description
      return_type: $return_type
      params: $params
    }
  }
}

# Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling. Only capacity providers that use an Auto Scaling group can be created. Amazon ECS tasks on Fargate use the FARGATE and FARGATE_SPOT capacity providers. These providers are available to all accounts in the Amazon Web Services Regions that Fargate supports.
#
# POST /
# operationId: CreateCapacityProvider
export def "create-capacity-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer # required
  name: string # The name of the capacity provider. Up to 255 characters are allowed. They include letters (both upper and lowercase letters), numbers, underscores (_), and hyphens (-). The name can't be prefixed with "aws", "ecs", or "fargate".
  auto_scaling_group_provider: record # The details of the Auto Scaling group for the capacity provider. — shape: {autoScalingGroupArn: string, managedScaling?: record, managedTerminationProtection?: "ENABLED"|"DISABLED"}
  --tags: list # The metadata that you apply to the capacity provider to categorize and organize them more conveniently. Each tag consists of a key and an optional value. You define both of them. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
]: any -> oneof<record<capacityProvider: record<capacityProviderArn: string, name: string, status: string, autoScalingGroupProvider: record<autoScalingGroupArn: string, managedScaling: record, managedTerminationProtection: string>, updateStatus: string, updateStatusReason: string, tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.CreateCapacityProvider")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "autoScalingGroupProvider": $auto_scaling_group_provider, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new Amazon ECS cluster. By default, your account receives a default cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the CreateCluster action. When you call the CreateCluster API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account. This is so that it can manage required resources in other Amazon Web Services services on your behalf. However, if the user that makes the call doesn't have permissions to create the service-linked role, it isn't created. For more information, see Using service-linked roles for Amazon ECS (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: CreateCluster
export def "create-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1 # required
  --cluster-name: string # The name of your cluster. If you don't specify a name for your cluster, you create a cluster that's named default. Up to 255 letters (uppercase and lowercase), numbers, underscores, and hyphens are allowed.
  --tags: list # The metadata that you apply to the cluster to help you categorize and organize them. Each tag consists of a key and an optional value. You define both. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
  --settings: list # The setting to use when creating a cluster. This parameter is used to turn on CloudWatch Container Insights for a cluster. If this value is specified, it overrides the containerInsights value set with PutAccountSetting or PutAccountSettingDefault. — item shape: {name?: "containerInsights", value?: string}
  --configuration: record # The execute command configuration for the cluster. — shape: {executeCommandConfiguration?: record}
  --capacity-providers: list<string> # The short name of one or more capacity providers to associate with the cluster. A capacity provider must be associated with a cluster before it can be included as part of the default capacity provider strategy of the cluster or used in a capacity provider strategy when calling the CreateService (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CreateService.html) or RunTask (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_RunTask.html) actions. If specifying a capacity provider that uses an Auto Scaling group, the capacity provider must be created but not associated with another cluster. New Auto Scaling group capacity providers can be created with the CreateCapacityProvider (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CreateCapacityProvider.html) API operation. To use a Fargate capacity provider, specify either the FARGATE or FARGATE_SPOT capacity providers. The Fargate capacity providers are available to all accounts and only need to be associated with a cluster to be used. The PutCapacityProvider (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PutCapacityProvider.html) API operation is used to update the list of available capacity providers for a cluster after the cluster is created.
  --default-capacity-provider-strategy: list # The capacity provider strategy to set as the default for the cluster. After a default capacity provider strategy is set for a cluster, when you call the CreateService (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CreateService.html) or RunTask (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_RunTask.html) APIs with no capacity provider strategy or launch type specified, the default capacity provider strategy for the cluster is used. If a default capacity provider strategy isn't defined for a cluster when it was created, it can be defined later with the PutClusterCapacityProviders API operation. — item shape: {capacityProvider: string, weight?: int, base?: int}
  --service-connect-defaults: record # Use this parameter to set a default Service Connect namespace. After you set a default Service Connect namespace, any new services with Service Connect turned on that are created in the cluster are added as client services in the namespace. This setting only applies to new services that set the enabled parameter to true in the ServiceConnectConfiguration. You can set the namespace of each service individually in the ServiceConnectConfiguration to override this default parameter. Tasks that run in a namespace can use short names to connect to services in the namespace. Tasks can connect to services across all of the clusters in the namespace. Tasks connect through a managed proxy container that collects logs and metrics for increased visibility. Only the tasks that Amazon ECS services create are supported with Service Connect. For more information, see Service Connect (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html) in the Amazon Elastic Container Service Developer Guide. — shape: {namespace: string}
]: any -> oneof<record<cluster: record<clusterArn: string, clusterName: string, configuration: record<executeCommandConfiguration: record>, status: string, registeredContainerInstancesCount: int, runningTasksCount: int, pendingTasksCount: int, activeServicesCount: int, statistics: list<record>, tags: list<record>, settings: list<record>, capacityProviders: list<string>, defaultCapacityProviderStrategy: list<record>, attachments: list<record>, attachmentsStatus: string, serviceConnectDefaults: record<namespace: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.CreateCluster")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clusterName": $cluster_name, "tags": $tags, "settings": $settings, "configuration": $configuration, "capacityProviders": $capacity_providers, "defaultCapacityProviderStrategy": $default_capacity_provider_strategy, "serviceConnectDefaults": $service_connect_defaults} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Runs and maintains your desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the desiredCount, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see the UpdateService action. Starting April 15, 2023, Amazon Web Services will not onboard new customers to Amazon Elastic Inference (EI), and will help current customers migrate their workloads to options that offer better price and performance. After April 15, 2023, new customers will not be able to launch instances with Amazon EI accelerators in Amazon SageMaker, Amazon ECS, or Amazon EC2. However, customers who have used Amazon EI at least once during the past 30-day period are considered current customers and will be able to continue using the service. In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see Service load balancing (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html) in the Amazon Elastic Container Service Developer Guide. Tasks for services that don't use a load balancer are considered healthy if they're in the RUNNING state. Tasks for services that use a load balancer are considered healthy if they're in the RUNNING state and are reported as healthy by the load balancer. There are two service scheduler strategies available: REPLICA - The replica scheduling strategy places and maintains your desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see Service scheduler concepts (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) in the Amazon Elastic Container Service Developer Guide. DAEMON - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. The service scheduler also evaluates the task placement constraints for running tasks. It also stops tasks that don't meet the placement constraints. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see Service scheduler concepts (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) in the Amazon Elastic Container Service Developer Guide. You can optionally specify a deployment configuration for your service. The deployment is initiated by changing properties. For example, the deployment might be initiated by the task definition or by your desired count of a service. This is done with an UpdateService operation. The default value for a replica service for minimumHealthyPercent is 100%. The default value for a daemon service for minimumHealthyPercent is 0%. If a service uses the ECS deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the RUNNING state during a deployment. Specifically, it represents it as a percentage of your desired number of tasks (rounded up to the nearest integer). This happens when any of your container instances are in the DRAINING state if the service contains tasks using the EC2 launch type. Using this parameter, you can deploy without using additional cluster capacity. For example, if you set your service to have desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. If they're in the RUNNING state, tasks for services that don't use a load balancer are considered healthy . If they're in the RUNNING state and reported as healthy by the load balancer, tasks for services that do use a load balancer are considered healthy . The default value for minimum healthy percent is 100%. If a service uses the ECS deployment controller, the maximum percent parameter represents an upper limit on the number of tasks in a service that are allowed in the RUNNING or PENDING state during a deployment. Specifically, it represents it as a percentage of the desired number of tasks (rounded down to the nearest integer). This happens when any of your container instances are in the DRAINING state if the service contains tasks using the EC2 launch type. Using this parameter, you can define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%. If a service uses either the CODE_DEPLOY or EXTERNAL deployment controller types and tasks that use the EC2 launch type, the minimum healthy percent and maximum percent values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the RUNNING state. This is while the container instances are in the DRAINING state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used. This is the case even if they're currently visible when describing your service. When creating a service that uses the EXTERNAL deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the CreateTaskSet operation. For more information, see Amazon ECS deployment types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html) in the Amazon Elastic Container Service Developer Guide. When the service scheduler launches new tasks, it determines task placement. For information about task placement and task placement strategies, see Amazon ECS task placement (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: CreateService
export def "create-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that you run your service on. If you do not specify a cluster, the default cluster is assumed.
  service_name: string # The name of your service. Up to 255 letters (uppercase and lowercase), numbers, underscores, and hyphens are allowed. Service names must be unique within a cluster, but you can have similarly named services in multiple clusters within a Region or across multiple Regions.
  --task-definition: string # The family and revision (family:revision) or full ARN of the task definition to run in your service. If a revision isn't specified, the latest ACTIVE revision is used. A task definition must be specified if the service uses either the ECS or CODE_DEPLOY deployment controllers. For more information about deployment types, see Amazon ECS deployment types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html).
  --load-balancers: list # A load balancer object representing the load balancers to use with your service. For more information, see Service load balancing (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html) in the Amazon Elastic Container Service Developer Guide. If the service uses the rolling update (ECS) deployment controller and using either an Application Load Balancer or Network Load Balancer, you must specify one or more target group ARNs to attach to the service. The service-linked role is required for services that use multiple target groups. For more information, see Using service-linked roles for Amazon ECS (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html) in the Amazon Elastic Container Service Developer Guide. If the service uses the CODE_DEPLOY deployment controller, the service is required to use either an Application Load Balancer or Network Load Balancer. When creating an CodeDeploy deployment group, you specify two target groups (referred to as a targetGroupPair). During a deployment, CodeDeploy determines which task set in your service has the status PRIMARY, and it associates one target group with it. Then, it also associates the other target group with the replacement task set. The load balancer can also have up to two listeners: a required listener for production traffic and an optional listener that you can use to perform validation tests with Lambda functions before routing production traffic to it. If you use the CODE_DEPLOY deployment controller, these values can be changed when updating the service. For Application Load Balancers and Network Load Balancers, this object must contain the load balancer target group ARN, the container name, and the container port to access from the load balancer. The container name must be as it appears in a container definition. The load balancer name parameter must be omitted. When a task from this service is placed on a container instance, the container instance and port combination is registered as a target in the target group that's specified here. For Classic Load Balancers, this object must contain the load balancer name, the container name , and the container port to access from the load balancer. The container name must be as it appears in a container definition. The target group ARN parameter must be omitted. When a task from this service is placed on a container instance, the container instance is registered with the load balancer that's specified here. Services with tasks that use the awsvpc network mode (for example, those with the Fargate launch type) only support Application Load Balancers and Network Load Balancers. Classic Load Balancers aren't supported. Also, when you create any target groups for these services, you must choose ip as the target type, not instance. This is because tasks that use the awsvpc network mode are associated with an elastic network interface, not an Amazon EC2 instance. — item shape: {targetGroupArn?: string, loadBalancerName?: string, containerName?: string, containerPort?: int}
  --service-registries: list # The details of the service discovery registry to associate with this service. For more information, see Service discovery (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html). Each service may be associated with one service registry. Multiple service registries for each service isn't supported. — item shape: {registryArn?: string, port?: int, containerName?: string, containerPort?: int}
  --desired-count: int # The number of instantiations of the specified task definition to place and keep running on your cluster. This is required if schedulingStrategy is REPLICA or isn't specified. If schedulingStrategy is DAEMON then this isn't required.
  --client-token: string # An identifier that you provide to ensure the idempotency of the request. It must be unique and is case sensitive. Up to 32 ASCII characters are allowed.
  --launch-type: string@launch-type-completer # The infrastructure that you run your service on. For more information, see Amazon ECS launch types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html) in the Amazon Elastic Container Service Developer Guide. The FARGATE launch type runs your tasks on Fargate On-Demand infrastructure. Fargate Spot infrastructure is available for use but a capacity provider strategy must be used. For more information, see Fargate capacity providers (https://docs.aws.amazon.com/AmazonECS/latest/userguide/fargate-capacity-providers.html) in the Amazon ECS User Guide for Fargate. The EC2 launch type runs your tasks on Amazon EC2 instances registered to your cluster. The EXTERNAL launch type runs your tasks on your on-premises server or virtual machine (VM) capacity registered to your cluster. A service can use either a launch type or a capacity provider strategy. If a launchType is specified, the capacityProviderStrategy parameter must be omitted.
  --capacity-provider-strategy: list # The capacity provider strategy to use for the service. If a capacityProviderStrategy is specified, the launchType parameter must be omitted. If no capacityProviderStrategy or launchType is specified, the defaultCapacityProviderStrategy for the cluster is used. A capacity provider strategy may contain a maximum of 6 capacity providers. — item shape: {capacityProvider: string, weight?: int, base?: int}
  --platform-version: string # The platform version that your tasks in the service are running on. A platform version is specified only for tasks using the Fargate launch type. If one isn't specified, the LATEST platform version is used. For more information, see Fargate platform versions (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html) in the Amazon Elastic Container Service Developer Guide.
  --role: string # The name or full Amazon Resource Name (ARN) of the IAM role that allows Amazon ECS to make calls to your load balancer on your behalf. This parameter is only permitted if you are using a load balancer with your service and your task definition doesn't use the awsvpc network mode. If you specify the role parameter, you must also specify a load balancer object with the loadBalancers parameter. If your account has already created the Amazon ECS service-linked role, that role is used for your service unless you specify a role here. The service-linked role is required if your task definition uses the awsvpc network mode or if the service is configured to use service discovery, an external deployment controller, multiple target groups, or Elastic Inference accelerators in which case you don't specify a role here. For more information, see Using service-linked roles for Amazon ECS (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html) in the Amazon Elastic Container Service Developer Guide. If your specified role has a path other than /, then you must either specify the full role ARN (this is recommended) or prefix the role name with the path. For example, if a role with the name bar has a path of /foo/ then you would specify /foo/bar as the role name. For more information, see Friendly names and paths (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-friendly-names) in the IAM User Guide.
  --deployment-configuration: record # Optional deployment parameters that control how many tasks run during a deployment and the ordering of stopping and starting tasks. — shape: {deploymentCircuitBreaker?: record, maximumPercent?: int, minimumHealthyPercent?: int, alarms?: record}
  --placement-constraints: list # An array of placement constraint objects to use for tasks in your service. You can specify a maximum of 10 constraints for each task. This limit includes constraints in the task definition and those specified at runtime. — item shape: {type?: "distinctInstance"|"memberOf", expression?: string}
  --placement-strategy: list # The placement strategy objects to use for tasks in your service. You can specify a maximum of 5 strategy rules for each service. — item shape: {type?: "random"|"spread"|"binpack", field?: string}
  --network-configuration: record # The network configuration for a task or service. — shape: {awsvpcConfiguration?: record}
  --health-check-grace-period-seconds: int # The period of time, in seconds, that the Amazon ECS service scheduler ignores unhealthy Elastic Load Balancing target health checks after a task has first started. This is only used when your service is configured to use a load balancer. If your service has a load balancer defined and you don't specify a health check grace period value, the default value of 0 is used. If you do not use an Elastic Load Balancing, we recommend that you use the startPeriod in the task definition health check parameters. For more information, see Health check (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html). If your service's tasks take a while to start and respond to Elastic Load Balancing health checks, you can specify a health check grace period of up to 2,147,483,647 seconds (about 69 years). During that time, the Amazon ECS service scheduler ignores health check status. This grace period can prevent the service scheduler from marking tasks as unhealthy and stopping them before they have time to come up.
  --scheduling-strategy: string@scheduling-strategy-completer # The scheduling strategy to use for the service. For more information, see Services (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html). There are two service scheduler strategies available: REPLICA-The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. This scheduler strategy is required if the service uses the CODE_DEPLOY or EXTERNAL deployment controller types. DAEMON-The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. The service scheduler also evaluates the task placement constraints for running tasks and will stop tasks that don't meet the placement constraints. When you're using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. Tasks using the Fargate launch type or the CODE_DEPLOY or EXTERNAL deployment controller types don't support the DAEMON scheduling strategy.
  --deployment-controller: record # The deployment controller to use for the service. For more information, see Amazon ECS deployment types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html) in the Amazon Elastic Container Service Developer Guide. — shape: {type: "ECS"|"CODE_DEPLOY"|"EXTERNAL"}
  --tags: list # The metadata that you apply to the service to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. When a service is deleted, the tags are deleted as well. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
  --enable-ecs-managed-tags: oneof<nothing, bool> # Specifies whether to turn on Amazon ECS managed tags for the tasks within the service. For more information, see Tagging your Amazon ECS resources (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-using-tags.html) in the Amazon Elastic Container Service Developer Guide.
  --propagate-tags: string@propagate-tags-completer # Specifies whether to propagate the tags from the task definition to the task. If no value is specified, the tags aren't propagated. Tags can only be propagated to the task during task creation. To add tags to a task after task creation, use the TagResource (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_TagResource.html) API action.
  --enable-execute-command: oneof<nothing, bool> # Determines whether the execute command functionality is turned on for the service. If true, this enables execute command functionality on all containers in the service tasks.
  --service-connect-configuration: record # The Service Connect configuration of your Amazon ECS service. The configuration for this service to discover and connect to services, and be discovered by, and connected from, other services within a namespace. Tasks that run in a namespace can use short names to connect to services in the namespace. Tasks can connect to services across all of the clusters in the namespace. Tasks connect through a managed proxy container that collects logs and metrics for increased visibility. Only the tasks that Amazon ECS services create are supported with Service Connect. For more information, see Service Connect (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html) in the Amazon Elastic Container Service Developer Guide. — shape: {enabled: bool, namespace?: string, services?: list, logConfiguration?: record}
]: any -> oneof<record<service: record<serviceArn: string, serviceName: string, clusterArn: string, loadBalancers: list<record>, serviceRegistries: list<record>, status: string, desiredCount: int, runningCount: int, pendingCount: int, launchType: string, capacityProviderStrategy: list<record>, platformVersion: string, platformFamily: string, taskDefinition: string, deploymentConfiguration: record<deploymentCircuitBreaker: record, maximumPercent: int, minimumHealthyPercent: int, alarms: record>, taskSets: list<record>, deployments: list<record>, roleArn: string, events: list<record>, createdAt: string, placementConstraints: list<record>, placementStrategy: list<record>, networkConfiguration: record<awsvpcConfiguration: record>, healthCheckGracePeriodSeconds: int, schedulingStrategy: string, deploymentController: record<type: string>, tags: list<record>, createdBy: string, enableECSManagedTags: bool, propagateTags: string, enableExecuteCommand: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.CreateService")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "serviceName": $service_name, "taskDefinition": $task_definition, "loadBalancers": $load_balancers, "serviceRegistries": $service_registries, "desiredCount": $desired_count, "clientToken": $client_token, "launchType": $launch_type, "capacityProviderStrategy": $capacity_provider_strategy, "platformVersion": $platform_version, "role": $role, "deploymentConfiguration": $deployment_configuration, "placementConstraints": $placement_constraints, "placementStrategy": $placement_strategy, "networkConfiguration": $network_configuration, "healthCheckGracePeriodSeconds": $health_check_grace_period_seconds, "schedulingStrategy": $scheduling_strategy, "deploymentController": $deployment_controller, "tags": $tags, "enableECSManagedTags": $enable_ecs_managed_tags, "propagateTags": $propagate_tags, "enableExecuteCommand": $enable_execute_command, "serviceConnectConfiguration": $service_connect_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create a task set in the specified cluster and service. This is used when a service uses the EXTERNAL deployment controller type. For more information, see Amazon ECS deployment types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: CreateTaskSet
export def "create-task-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3 # required
  service: string # The short name or full Amazon Resource Name (ARN) of the service to create the task set in.
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the service to create the task set in.
  --external-id: string # An optional non-unique tag that identifies this task set in external systems. If the task set is associated with a service discovery registry, the tasks in this task set will have the ECS_TASK_SET_EXTERNAL_ID Cloud Map attribute set to the provided value.
  task_definition: string # The task definition for the tasks in the task set to use.
  --network-configuration: record # The network configuration for a task or service. — shape: {awsvpcConfiguration?: record}
  --load-balancers: list # A load balancer object representing the load balancer to use with the task set. The supported load balancer types are either an Application Load Balancer or a Network Load Balancer. — item shape: {targetGroupArn?: string, loadBalancerName?: string, containerName?: string, containerPort?: int}
  --service-registries: list # The details of the service discovery registries to assign to this task set. For more information, see Service discovery (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html). — item shape: {registryArn?: string, port?: int, containerName?: string, containerPort?: int}
  --launch-type: string@launch-type-completer # The launch type that new tasks in the task set uses. For more information, see Amazon ECS launch types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html) in the Amazon Elastic Container Service Developer Guide. If a launchType is specified, the capacityProviderStrategy parameter must be omitted.
  --capacity-provider-strategy: list # The capacity provider strategy to use for the task set. A capacity provider strategy consists of one or more capacity providers along with the base and weight to assign to them. A capacity provider must be associated with the cluster to be used in a capacity provider strategy. The PutClusterCapacityProviders API is used to associate a capacity provider with a cluster. Only capacity providers with an ACTIVE or UPDATING status can be used. If a capacityProviderStrategy is specified, the launchType parameter must be omitted. If no capacityProviderStrategy or launchType is specified, the defaultCapacityProviderStrategy for the cluster is used. If specifying a capacity provider that uses an Auto Scaling group, the capacity provider must already be created. New capacity providers can be created with the CreateCapacityProvider API operation. To use a Fargate capacity provider, specify either the FARGATE or FARGATE_SPOT capacity providers. The Fargate capacity providers are available to all accounts and only need to be associated with a cluster to be used. The PutClusterCapacityProviders API operation is used to update the list of available capacity providers for a cluster after the cluster is created. — item shape: {capacityProvider: string, weight?: int, base?: int}
  --platform-version: string # The platform version that the tasks in the task set uses. A platform version is specified only for tasks using the Fargate launch type. If one isn't specified, the LATEST platform version is used.
  --scale: record # A floating-point percentage of the desired number of tasks to place and keep running in the task set. — shape: {value?: float, unit?: "PERCENT"}
  --client-token: string # The identifier that you provide to ensure the idempotency of the request. It's case sensitive and must be unique. It can be up to 32 ASCII characters are allowed.
  --tags: list # The metadata that you apply to the task set to help you categorize and organize them. Each tag consists of a key and an optional value. You define both. When a service is deleted, the tags are deleted. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
]: any -> oneof<record<taskSet: record<id: string, taskSetArn: string, serviceArn: string, clusterArn: string, startedBy: string, externalId: string, status: string, taskDefinition: string, computedDesiredCount: int, pendingCount: int, runningCount: int, createdAt: string, updatedAt: string, launchType: string, capacityProviderStrategy: list<record>, platformVersion: string, platformFamily: string, networkConfiguration: record<awsvpcConfiguration: record>, loadBalancers: list<record>, serviceRegistries: list<record>, scale: record<value: float, unit: string>, stabilityStatus: string, stabilityStatusAt: string, tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.CreateTaskSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"service": $service, "cluster": $cluster, "externalId": $external_id, "taskDefinition": $task_definition, "networkConfiguration": $network_configuration, "loadBalancers": $load_balancers, "serviceRegistries": $service_registries, "launchType": $launch_type, "capacityProviderStrategy": $capacity_provider_strategy, "platformVersion": $platform_version, "scale": $scale, "clientToken": $client_token, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Disables an account setting for a specified user, role, or the root user for an account.
#
# POST /
# operationId: DeleteAccountSetting
export def "delete-account-setting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4 # required
  name: string@name-completer # The resource name to disable the account setting for. If serviceLongArnFormat is specified, the ARN for your Amazon ECS services is affected. If taskLongArnFormat is specified, the ARN and resource ID for your Amazon ECS tasks is affected. If containerInstanceLongArnFormat is specified, the ARN and resource ID for your Amazon ECS container instances is affected. If awsvpcTrunking is specified, the ENI limit for your Amazon ECS container instances is affected.
  --principal-arn: string # The Amazon Resource Name (ARN) of the principal. It can be an user, role, or the root user. If you specify the root user, it disables the account setting for all users, roles, and the root user of the account unless a user or role explicitly overrides these settings. If this field is omitted, the setting is changed only for the authenticated user.
]: any -> oneof<record<setting: record<name: string, value: string, principalArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeleteAccountSetting")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "principalArn": $principal_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes one or more custom attributes from an Amazon ECS resource.
#
# POST /
# operationId: DeleteAttributes
export def "delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that contains the resource to delete attributes. If you do not specify a cluster, the default cluster is assumed.
  attributes: list # The attributes to delete from your resource. You can specify up to 10 attributes for each request. For custom attributes, specify the attribute name and target ID, but don't specify the value. If you specify the target ID using the short form, you must also specify the target type. — item shape: {name: string, value?: string, targetType?: "container-instance", targetId?: string}
]: any -> oneof<record<attributes: table<name: string, value: string, targetType: string, targetId: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeleteAttributes")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "attributes": $attributes} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the specified capacity provider. The FARGATE and FARGATE_SPOT capacity providers are reserved and can't be deleted. You can disassociate them from a cluster using either the PutClusterCapacityProviders API or by deleting the cluster. Prior to a capacity provider being deleted, the capacity provider must be removed from the capacity provider strategy from all services. The UpdateService API can be used to remove a capacity provider from a service's capacity provider strategy. When updating a service, the forceNewDeployment option can be used to ensure that any tasks using the Amazon EC2 instance capacity provided by the capacity provider are transitioned to use the capacity from the remaining capacity providers. Only capacity providers that aren't associated with a cluster can be deleted. To remove a capacity provider from a cluster, you can either use PutClusterCapacityProviders or delete the cluster.
#
# POST /
# operationId: DeleteCapacityProvider
export def "delete-capacity-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6 # required
  capacity_provider: string # The short name or full Amazon Resource Name (ARN) of the capacity provider to delete.
]: any -> oneof<record<capacityProvider: record<capacityProviderArn: string, name: string, status: string, autoScalingGroupProvider: record<autoScalingGroupArn: string, managedScaling: record, managedTerminationProtection: string>, updateStatus: string, updateStatusReason: string, tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeleteCapacityProvider")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"capacityProvider": $capacity_provider} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the specified cluster. The cluster transitions to the INACTIVE state. Clusters with an INACTIVE status might remain discoverable in your account for a period of time. However, this behavior is subject to change in the future. We don't recommend that you rely on INACTIVE clusters persisting. You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with ListContainerInstances and deregister them with DeregisterContainerInstance.
#
# POST /
# operationId: DeleteCluster
export def "delete-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7 # required
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster to delete.
]: any -> oneof<record<cluster: record<clusterArn: string, clusterName: string, configuration: record<executeCommandConfiguration: record>, status: string, registeredContainerInstancesCount: int, runningTasksCount: int, pendingTasksCount: int, activeServicesCount: int, statistics: list<record>, tags: list<record>, settings: list<record>, capacityProviders: list<string>, defaultCapacityProviderStrategy: list<record>, attachments: list<record>, attachmentsStatus: string, serviceConnectDefaults: record<namespace: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeleteCluster")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you can't delete it, and you must update the service to a desired task count of zero. For more information, see UpdateService. When you delete a service, if there are still running tasks that require cleanup, the service status moves from ACTIVE to DRAINING, and the service is no longer visible in the console or in the ListServices API operation. After all tasks have transitioned to either STOPPING or STOPPED status, the service status moves from DRAINING to INACTIVE. Services in the DRAINING or INACTIVE status can still be viewed with the DescribeServices API operation. However, in the future, INACTIVE services may be cleaned up and purged from Amazon ECS record keeping, and DescribeServices calls on those services return a ServiceNotFoundException error. If you attempt to create a new service with the same name as an existing service in either ACTIVE or DRAINING status, you receive an error.
#
# POST /
# operationId: DeleteService
export def "delete-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the service to delete. If you do not specify a cluster, the default cluster is assumed.
  service: string # The name of the service to delete.
  --force: oneof<nothing, bool> # If true, allows you to delete a service even if it wasn't scaled down to zero tasks. It's only necessary to use this if the service uses the REPLICA scheduling strategy.
]: any -> oneof<record<service: record<serviceArn: string, serviceName: string, clusterArn: string, loadBalancers: list<record>, serviceRegistries: list<record>, status: string, desiredCount: int, runningCount: int, pendingCount: int, launchType: string, capacityProviderStrategy: list<record>, platformVersion: string, platformFamily: string, taskDefinition: string, deploymentConfiguration: record<deploymentCircuitBreaker: record, maximumPercent: int, minimumHealthyPercent: int, alarms: record>, taskSets: list<record>, deployments: list<record>, roleArn: string, events: list<record>, createdAt: string, placementConstraints: list<record>, placementStrategy: list<record>, networkConfiguration: record<awsvpcConfiguration: record>, healthCheckGracePeriodSeconds: int, schedulingStrategy: string, deploymentController: record<type: string>, tags: list<record>, createdBy: string, enableECSManagedTags: bool, propagateTags: string, enableExecuteCommand: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeleteService")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "service": $service, "force": $force} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes one or more task definitions. You must deregister a task definition revision before you delete it. For more information, see DeregisterTaskDefinition (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeregisterTaskDefinition.html). When you delete a task definition revision, it is immediately transitions from the INACTIVE to DELETE_IN_PROGRESS. Existing tasks and services that reference a DELETE_IN_PROGRESS task definition revision continue to run without disruption. Existing services that reference a DELETE_IN_PROGRESS task definition revision can still scale up or down by modifying the service's desired count. You can't use a DELETE_IN_PROGRESS task definition revision to run new tasks or create new services. You also can't update an existing service to reference a DELETE_IN_PROGRESS task definition revision. A task definition revision will stay in DELETE_IN_PROGRESS status until all the associated tasks and services have been terminated.
#
# POST /
# operationId: DeleteTaskDefinitions
export def "delete-task-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9 # required
  task_definitions: list<string> # The family and revision (family:revision) or full Amazon Resource Name (ARN) of the task definition to delete. You must specify a revision. You can specify up to 10 task definitions as a comma separated list.
]: any -> oneof<record<taskDefinitions: table<taskDefinitionArn: string, containerDefinitions: list, family: string, taskRoleArn: string, executionRoleArn: string, networkMode: string, revision: int, volumes: list, status: string, requiresAttributes: list, placementConstraints: list, compatibilities: list, runtimePlatform: record, requiresCompatibilities: list, cpu: string, memory: string, inferenceAccelerators: list, pidMode: string, ipcMode: string, proxyConfiguration: record, registeredAt: string, deregisteredAt: string, registeredBy: string, ephemeralStorage: record>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeleteTaskDefinitions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"taskDefinitions": $task_definitions} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a specified task set within a service. This is used when a service uses the EXTERNAL deployment controller type. For more information, see Amazon ECS deployment types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: DeleteTaskSet
export def "delete-task-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10 # required
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the service that the task set found in to delete.
  service: string # The short name or full Amazon Resource Name (ARN) of the service that hosts the task set to delete.
  task_set: string # The task set ID or full Amazon Resource Name (ARN) of the task set to delete.
  --force: oneof<nothing, bool> # If true, you can delete a task set even if it hasn't been scaled down to zero.
]: any -> oneof<record<taskSet: record<id: string, taskSetArn: string, serviceArn: string, clusterArn: string, startedBy: string, externalId: string, status: string, taskDefinition: string, computedDesiredCount: int, pendingCount: int, runningCount: int, createdAt: string, updatedAt: string, launchType: string, capacityProviderStrategy: list<record>, platformVersion: string, platformFamily: string, networkConfiguration: record<awsvpcConfiguration: record>, loadBalancers: list<record>, serviceRegistries: list<record>, scale: record<value: float, unit: string>, stabilityStatus: string, stabilityStatusAt: string, tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeleteTaskSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "service": $service, "taskSet": $task_set, "force": $force} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks. If you intend to use the container instance for some other purpose after deregistration, we recommend that you stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources. Deregistering a container instance removes the instance from a cluster, but it doesn't terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing. If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents aren't automatically deregistered when terminated).
#
# POST /
# operationId: DeregisterContainerInstance
export def "deregister-container-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the container instance to deregister. If you do not specify a cluster, the default cluster is assumed.
  container_instance: string # The container instance ID or full ARN of the container instance to deregister. For more information about the ARN format, see Amazon Resource Name (ARN) (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html#ecs-resource-ids) in the Amazon ECS Developer Guide.
  --force: oneof<nothing, bool> # Forces the container instance to be deregistered. If you have tasks running on the container instance when you deregister it with the force option, these tasks remain running until you terminate the instance or the tasks stop through some other means, but they're orphaned (no longer monitored or accounted for by Amazon ECS). If an orphaned task on your container instance is part of an Amazon ECS service, then the service scheduler starts another copy of that task, on a different container instance if possible. Any containers in orphaned service tasks that are registered with a Classic Load Balancer or an Application Load Balancer target group are deregistered. They begin connection draining according to the settings on the load balancer or target group.
]: any -> oneof<record<containerInstance: record<containerInstanceArn: string, ec2InstanceId: string, capacityProviderName: string, version: int, versionInfo: record<agentVersion: string, agentHash: string, dockerVersion: string>, remainingResources: list<record>, registeredResources: list<record>, status: string, statusReason: string, agentConnected: bool, runningTasksCount: int, pendingTasksCount: int, agentUpdateStatus: string, attributes: list<record>, registeredAt: string, attachments: list<record>, tags: list<record>, healthStatus: record<overallStatus: string, details: list>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "containerInstance": $container_instance, "force": $force} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as INACTIVE. Existing tasks and services that reference an INACTIVE task definition continue to run without disruption. Existing services that reference an INACTIVE task definition can still scale up or down by modifying the service's desired count. If you want to delete a task definition revision, you must first deregister the task definition revision. You can't use an INACTIVE task definition to run new tasks or create new services, and you can't update an existing service to reference an INACTIVE task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect. At this time, INACTIVE task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future. We don't recommend that you rely on INACTIVE task definitions persisting beyond the lifecycle of any associated tasks and services. You must deregister a task definition revision before you delete it. For more information, see DeleteTaskDefinitions (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeleteTaskDefinitions.html).
#
# POST /
# operationId: DeregisterTaskDefinition
export def "deregister-task-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12 # required
  task_definition: string # The family and revision (family:revision) or full Amazon Resource Name (ARN) of the task definition to deregister. You must specify a revision.
]: any -> oneof<record<taskDefinition: record<taskDefinitionArn: string, containerDefinitions: list<record>, family: string, taskRoleArn: string, executionRoleArn: string, networkMode: string, revision: int, volumes: list<record>, status: string, requiresAttributes: list<record>, placementConstraints: list<record>, compatibilities: list<string>, runtimePlatform: record<cpuArchitecture: string, operatingSystemFamily: string>, requiresCompatibilities: list<string>, cpu: string, memory: string, inferenceAccelerators: list<record>, pidMode: string, ipcMode: string, proxyConfiguration: record<type: string, containerName: string, properties: any>, registeredAt: string, deregisteredAt: string, registeredBy: string, ephemeralStorage: record<sizeInGiB: int>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"taskDefinition": $task_definition} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes one or more of your capacity providers.
#
# POST /
# operationId: DescribeCapacityProviders
export def "describe-capacity-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13 # required
  --capacity-providers: list<string> # The short name or full Amazon Resource Name (ARN) of one or more capacity providers. Up to 100 capacity providers can be described in an action.
  --include: list<string> # Specifies whether or not you want to see the resource tags for the capacity provider. If TAGS is specified, the tags are included in the response. If this field is omitted, tags aren't included in the response.
  --max-results: int # The maximum number of account setting results returned by DescribeCapacityProviders in paginated output. When this parameter is used, DescribeCapacityProviders only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another DescribeCapacityProviders request with the returned nextToken value. This value can be between 1 and 10. If this parameter is not used, then DescribeCapacityProviders returns up to 10 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated DescribeCapacityProviders request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes.
]: any -> oneof<record<capacityProviders: table<capacityProviderArn: string, name: string, status: string, autoScalingGroupProvider: record, updateStatus: string, updateStatusReason: string, tags: list>, failures: table<arn: string, reason: string, detail: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"capacityProviders": $capacity_providers, "include": $include, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes one or more of your clusters.
#
# POST /
# operationId: DescribeClusters
export def "describe-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14 # required
  --clusters: list<string> # A list of up to 100 cluster names or full cluster Amazon Resource Name (ARN) entries. If you do not specify a cluster, the default cluster is assumed.
  --include: list<string> # Determines whether to include additional information about the clusters in the response. If this field is omitted, this information isn't included. If ATTACHMENTS is specified, the attachments for the container instances or tasks within the cluster are included, for example the capacity providers. If SETTINGS is specified, the settings for the cluster are included. If CONFIGURATIONS is specified, the configuration for the cluster is included. If STATISTICS is specified, the task and service count is included, separated by launch type. If TAGS is specified, the metadata tags associated with the cluster are included.
]: any -> oneof<record<clusters: table<clusterArn: string, clusterName: string, configuration: record, status: string, registeredContainerInstancesCount: int, runningTasksCount: int, pendingTasksCount: int, activeServicesCount: int, statistics: list, tags: list, settings: list, capacityProviders: list, defaultCapacityProviderStrategy: list, attachments: list, attachmentsStatus: string, serviceConnectDefaults: record>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DescribeClusters")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clusters": $clusters, "include": $include} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes one or more container instances. Returns metadata about each container instance requested.
#
# POST /
# operationId: DescribeContainerInstances
export def "describe-container-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the container instances to describe. If you do not specify a cluster, the default cluster is assumed. This parameter is required if the container instance or container instances you are describing were launched in any cluster other than the default cluster.
  container_instances: list<string> # A list of up to 100 container instance IDs or full Amazon Resource Name (ARN) entries.
  --include: list<string> # Specifies whether you want to see the resource tags for the container instance. If TAGS is specified, the tags are included in the response. If CONTAINER_INSTANCE_HEALTH is specified, the container instance health is included in the response. If this field is omitted, tags and container instance health status aren't included in the response.
]: any -> oneof<record<containerInstances: table<containerInstanceArn: string, ec2InstanceId: string, capacityProviderName: string, version: int, versionInfo: record, remainingResources: list, registeredResources: list, status: string, statusReason: string, agentConnected: bool, runningTasksCount: int, pendingTasksCount: int, agentUpdateStatus: string, attributes: list, registeredAt: string, attachments: list, tags: list, healthStatus: record>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DescribeContainerInstances")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "containerInstances": $container_instances, "include": $include} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes the specified services running in your cluster.
#
# POST /
# operationId: DescribeServices
export def "describe-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN)the cluster that hosts the service to describe. If you do not specify a cluster, the default cluster is assumed. This parameter is required if the service or services you are describing were launched in any cluster other than the default cluster.
  services: list<string> # A list of services to describe. You may specify up to 10 services to describe in a single operation.
  --include: list<string> # Determines whether you want to see the resource tags for the service. If TAGS is specified, the tags are included in the response. If this field is omitted, tags aren't included in the response.
]: any -> oneof<record<services: table<serviceArn: string, serviceName: string, clusterArn: string, loadBalancers: list, serviceRegistries: list, status: string, desiredCount: int, runningCount: int, pendingCount: int, launchType: string, capacityProviderStrategy: list, platformVersion: string, platformFamily: string, taskDefinition: string, deploymentConfiguration: record, taskSets: list, deployments: list, roleArn: string, events: list, createdAt: string, placementConstraints: list, placementStrategy: list, networkConfiguration: record, healthCheckGracePeriodSeconds: int, schedulingStrategy: string, deploymentController: record, tags: list, createdBy: string, enableECSManagedTags: bool, propagateTags: string, enableExecuteCommand: bool>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DescribeServices")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "services": $services, "include": $include} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes a task definition. You can specify a family and revision to find information about a specific task definition, or you can simply specify the family to find the latest ACTIVE revision in that family. You can only describe INACTIVE task definitions while an active task or service references them.
#
# POST /
# operationId: DescribeTaskDefinition
export def "describe-task-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  task_definition: string # The family for the latest ACTIVE revision, family and revision (family:revision) for a specific revision in the family, or full Amazon Resource Name (ARN) of the task definition to describe.
  --include: list<string> # Determines whether to see the resource tags for the task definition. If TAGS is specified, the tags are included in the response. If this field is omitted, tags aren't included in the response.
]: any -> oneof<record<taskDefinition: record<taskDefinitionArn: string, containerDefinitions: list<record>, family: string, taskRoleArn: string, executionRoleArn: string, networkMode: string, revision: int, volumes: list<record>, status: string, requiresAttributes: list<record>, placementConstraints: list<record>, compatibilities: list<string>, runtimePlatform: record<cpuArchitecture: string, operatingSystemFamily: string>, requiresCompatibilities: list<string>, cpu: string, memory: string, inferenceAccelerators: list<record>, pidMode: string, ipcMode: string, proxyConfiguration: record<type: string, containerName: string, properties: any>, registeredAt: string, deregisteredAt: string, registeredBy: string, ephemeralStorage: record<sizeInGiB: int>>, tags: table<key: string, value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"taskDefinition": $task_definition, "include": $include} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes the task sets in the specified cluster and service. This is used when a service uses the EXTERNAL deployment controller type. For more information, see Amazon ECS Deployment Types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: DescribeTaskSets
export def "describe-task-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the service that the task sets exist in.
  service: string # The short name or full Amazon Resource Name (ARN) of the service that the task sets exist in.
  --task-sets: list<string> # The ID or full Amazon Resource Name (ARN) of task sets to describe.
  --include: list<string> # Specifies whether to see the resource tags for the task set. If TAGS is specified, the tags are included in the response. If this field is omitted, tags aren't included in the response.
]: any -> oneof<record<taskSets: table<id: string, taskSetArn: string, serviceArn: string, clusterArn: string, startedBy: string, externalId: string, status: string, taskDefinition: string, computedDesiredCount: int, pendingCount: int, runningCount: int, createdAt: string, updatedAt: string, launchType: string, capacityProviderStrategy: list, platformVersion: string, platformFamily: string, networkConfiguration: record, loadBalancers: list, serviceRegistries: list, scale: record, stabilityStatus: string, stabilityStatusAt: string, tags: list>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DescribeTaskSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "service": $service, "taskSets": $task_sets, "include": $include} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes a specified task or tasks. Currently, stopped tasks appear in the returned results for at least one hour.
#
# POST /
# operationId: DescribeTasks
export def "describe-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the task or tasks to describe. If you do not specify a cluster, the default cluster is assumed. This parameter is required if the task or tasks you are describing were launched in any cluster other than the default cluster.
  tasks: list<string> # A list of up to 100 task IDs or full ARN entries.
  --include: list<string> # Specifies whether you want to see the resource tags for the task. If TAGS is specified, the tags are included in the response. If this field is omitted, tags aren't included in the response.
]: any -> oneof<record<tasks: table<attachments: list, attributes: list, availabilityZone: string, capacityProviderName: string, clusterArn: string, connectivity: string, connectivityAt: string, containerInstanceArn: string, containers: list, cpu: string, createdAt: string, desiredStatus: string, enableExecuteCommand: bool, executionStoppedAt: string, group: string, healthStatus: string, inferenceAccelerators: list, lastStatus: string, launchType: string, memory: string, overrides: record, platformVersion: string, platformFamily: string, pullStartedAt: string, pullStoppedAt: string, startedAt: string, startedBy: string, stopCode: string, stoppedAt: string, stoppedReason: string, stoppingAt: string, tags: list, taskArn: string, taskDefinitionArn: string, version: int, ephemeralStorage: record>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DescribeTasks")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "tasks": $tasks, "include": $include} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent. Returns an endpoint for the Amazon ECS agent to poll for updates.
#
# POST /
# operationId: DiscoverPollEndpoint
export def "discover-poll-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  --container-instance: string # The container instance ID or full ARN of the container instance. For more information about the ARN format, see Amazon Resource Name (ARN) (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html#ecs-resource-ids) in the Amazon ECS Developer Guide.
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that the container instance belongs to.
]: any -> oneof<record<endpoint: string, telemetryEndpoint: string, serviceConnectEndpoint: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"containerInstance": $container_instance, "cluster": $cluster} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Runs a command remotely on a container within a task. If you use a condition key in your IAM policy to refine the conditions for the policy statement, for example limit the actions to a specific cluster, you receive an AccessDeniedException when there is a mismatch between the condition key value and the corresponding parameter value. For information about required permissions and considerations, see Using Amazon ECS Exec for debugging (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html) in the Amazon ECS Developer Guide.
#
# POST /
# operationId: ExecuteCommand
export def "execute-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  --cluster: string # The Amazon Resource Name (ARN) or short name of the cluster the task is running in. If you do not specify a cluster, the default cluster is assumed.
  --container: string # The name of the container to execute the command on. A container name only needs to be specified for tasks containing multiple containers.
  command: string # The command to run on the container.
  --interactive: oneof<nothing, bool> # Use this flag to run your command in interactive mode.
  task: string # The Amazon Resource Name (ARN) or ID of the task the container is part of.
]: any -> oneof<record<clusterArn: string, containerArn: string, containerName: string, interactive: bool, session: record<sessionId: string, streamUrl: string, tokenValue: string>, taskArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ExecuteCommand")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "container": $container, "command": $command, "interactive": $interactive, "task": $task} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "interactive") == null) { error make --unspanned { msg: "required body field 'interactive' missing: pass --interactive or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the protection status of tasks in an Amazon ECS service.
#
# POST /
# operationId: GetTaskProtection
export def "get-task-protection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the service that the task sets exist in.
  --tasks: list<string> # A list of up to 100 task IDs or full ARN entries.
]: any -> oneof<record<protectedTasks: table<taskArn: string, protectionEnabled: bool, expirationDate: string>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.GetTaskProtection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "tasks": $tasks} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the account settings for a specified principal.
#
# POST /
# operationId: ListAccountSettings
export def "list-account-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  --name: string@name-completer # The name of the account setting you want to list the settings for.
  --value: string # The value of the account settings to filter results with. You must also specify an account setting name to use this parameter.
  --principal-arn: string # The ARN of the principal, which can be a user, role, or the root user. If this field is omitted, the account settings are listed only for the authenticated user. Federated users assume the account setting of the root user and can't have explicit account settings set for them.
  --effective-settings: oneof<nothing, bool> # Determines whether to return the effective settings. If true, the account settings for the root user or the default setting for the principalArn are returned. If false, the account settings for the principalArn are returned if they're set. Otherwise, no account settings are returned.
  --body-next-token: string # The nextToken value returned from a ListAccountSettings request indicating that more results are available to fulfill the request and further calls will be needed. If maxResults was provided, it's possible the number of results to be fewer than maxResults. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes. (spec name: nextToken)
  --body-max-results: int # The maximum number of account setting results returned by ListAccountSettings in paginated output. When this parameter is used, ListAccountSettings only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListAccountSettings request with the returned nextToken value. This value can be between 1 and 10. If this parameter isn't used, then ListAccountSettings returns up to 10 results and a nextToken value if applicable. (spec name: maxResults)
]: any -> oneof<record<settings: table<name: string, value: string, principalArn: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListAccountSettings")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"name": $name, "value": $value, "principalArn": $principal_arn, "effectiveSettings": $effective_settings, "nextToken": $body_next_token, "maxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, ListAttributes returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value. You can do this, for example, to see which container instances in a cluster are running a Linux AMI (ecs.os-type=linux).
#
# POST /
# operationId: ListAttributes
export def "list-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster to list attributes. If you do not specify a cluster, the default cluster is assumed.
  target_type: string@target-type-completer # The type of the target to list attributes with.
  --attribute-name: string # The name of the attribute to filter the results with.
  --attribute-value: string # The value of the attribute to filter results with. You must also specify an attribute name to use this parameter.
  --body-next-token: string # The nextToken value returned from a ListAttributes request indicating that more results are available to fulfill the request and further calls are needed. If maxResults was provided, it's possible the number of results to be fewer than maxResults. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes. (spec name: nextToken)
  --body-max-results: int # The maximum number of cluster results that ListAttributes returned in paginated output. When this parameter is used, ListAttributes only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListAttributes request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListAttributes returns up to 100 results and a nextToken value if applicable. (spec name: maxResults)
]: any -> oneof<record<attributes: table<name: string, value: string, targetType: string, targetId: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListAttributes")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"cluster": $cluster, "targetType": $target_type, "attributeName": $attribute_name, "attributeValue": $attribute_value, "nextToken": $body_next_token, "maxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of existing clusters.
#
# POST /
# operationId: ListClusters
export def "list-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  --body-next-token: string # The nextToken value returned from a ListClusters request indicating that more results are available to fulfill the request and further calls are needed. If maxResults was provided, it's possible the number of results to be fewer than maxResults. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes. (spec name: nextToken)
  --body-max-results: int # The maximum number of cluster results that ListClusters returned in paginated output. When this parameter is used, ListClusters only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListClusters request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListClusters returns up to 100 results and a nextToken value if applicable. (spec name: maxResults)
]: any -> oneof<record<clusterArns: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListClusters")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextToken": $body_next_token, "maxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of container instances in a specified cluster. You can filter the results of a ListContainerInstances operation with cluster query language statements inside the filter parameter. For more information, see Cluster Query Language (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: ListContainerInstances
export def "list-container-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the container instances to list. If you do not specify a cluster, the default cluster is assumed.
  --filter: string # You can filter the results of a ListContainerInstances operation with cluster query language statements. For more information, see Cluster Query Language (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html) in the Amazon Elastic Container Service Developer Guide.
  --body-next-token: string # The nextToken value returned from a ListContainerInstances request indicating that more results are available to fulfill the request and further calls are needed. If maxResults was provided, it's possible the number of results to be fewer than maxResults. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes. (spec name: nextToken)
  --body-max-results: int # The maximum number of container instance results that ListContainerInstances returned in paginated output. When this parameter is used, ListContainerInstances only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListContainerInstances request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListContainerInstances returns up to 100 results and a nextToken value if applicable. (spec name: maxResults)
  --status: string@status-completer # Filters the container instances by status. For example, if you specify the DRAINING status, the results include only container instances that have been set to DRAINING using UpdateContainerInstancesState. If you don't specify this parameter, the default is to include container instances set to all states other than INACTIVE.
]: any -> oneof<record<containerInstanceArns: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListContainerInstances")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"cluster": $cluster, "filter": $filter, "nextToken": $body_next_token, "maxResults": $body_max_results, "status": $status} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of services. You can filter the results by cluster, launch type, and scheduling strategy.
#
# POST /
# operationId: ListServices
export def "list-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster to use when filtering the ListServices results. If you do not specify a cluster, the default cluster is assumed.
  --body-next-token: string # The nextToken value returned from a ListServices request indicating that more results are available to fulfill the request and further calls will be needed. If maxResults was provided, it is possible the number of results to be fewer than maxResults. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes. (spec name: nextToken)
  --body-max-results: int # The maximum number of service results that ListServices returned in paginated output. When this parameter is used, ListServices only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListServices request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListServices returns up to 10 results and a nextToken value if applicable. (spec name: maxResults)
  --launch-type: string@launch-type-completer # The launch type to use when filtering the ListServices results.
  --scheduling-strategy: string@scheduling-strategy-completer # The scheduling strategy to use when filtering the ListServices results.
]: any -> oneof<record<serviceArns: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListServices")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"cluster": $cluster, "nextToken": $body_next_token, "maxResults": $body_max_results, "launchType": $launch_type, "schedulingStrategy": $scheduling_strategy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation lists all of the services that are associated with a Cloud Map namespace. This list might include services in different clusters. In contrast, ListServices can only list services in one cluster at a time. If you need to filter the list of services in a single cluster by various parameters, use ListServices. For more information, see Service Connect (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: ListServicesByNamespace
export def "list-services-by-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  namespace: string # The namespace name or full Amazon Resource Name (ARN) of the Cloud Map namespace to list the services in. Tasks that run in a namespace can use short names to connect to services in the namespace. Tasks can connect to services across all of the clusters in the namespace. Tasks connect through a managed proxy container that collects logs and metrics for increased visibility. Only the tasks that Amazon ECS services create are supported with Service Connect. For more information, see Service Connect (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html) in the Amazon Elastic Container Service Developer Guide.
  --body-next-token: string # The nextToken value that's returned from a ListServicesByNamespace request. It indicates that more results are available to fulfill the request and further calls are needed. If maxResults is returned, it is possible the number of results is less than maxResults. (spec name: nextToken)
  --body-max-results: int # The maximum number of service results that ListServicesByNamespace returns in paginated output. When this parameter is used, ListServicesByNamespace only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListServicesByNamespace request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListServicesByNamespace returns up to 10 results and a nextToken value if applicable. (spec name: maxResults)
]: any -> oneof<record<serviceArns: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListServicesByNamespace")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"namespace": $namespace, "nextToken": $body_next_token, "maxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the tags for an Amazon ECS resource.
#
# POST /
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  resource_arn: string # The Amazon Resource Name (ARN) that identifies the resource to list the tags for. Currently, the supported resources are Amazon ECS tasks, services, task definitions, clusters, and container instances.
]: any -> oneof<record<tags: table<key: string, value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceArn": $resource_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of task definition families that are registered to your account. This list includes task definition families that no longer have any ACTIVE task definition revisions. You can filter out task definition families that don't contain any ACTIVE task definition revisions by setting the status parameter to ACTIVE. You can also filter the results with the familyPrefix parameter.
#
# POST /
# operationId: ListTaskDefinitionFamilies
export def "list-task-definition-families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  --family-prefix: string # The familyPrefix is a string that's used to filter the results of ListTaskDefinitionFamilies. If you specify a familyPrefix, only task definition family names that begin with the familyPrefix string are returned.
  --status: string@status-completer-1 # The task definition family status to filter the ListTaskDefinitionFamilies results with. By default, both ACTIVE and INACTIVE task definition families are listed. If this parameter is set to ACTIVE, only task definition families that have an ACTIVE task definition revision are returned. If this parameter is set to INACTIVE, only task definition families that do not have any ACTIVE task definition revisions are returned. If you paginate the resulting output, be sure to keep the status value constant in each subsequent request.
  --body-next-token: string # The nextToken value returned from a ListTaskDefinitionFamilies request indicating that more results are available to fulfill the request and further calls will be needed. If maxResults was provided, it is possible the number of results to be fewer than maxResults. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes. (spec name: nextToken)
  --body-max-results: int # The maximum number of task definition family results that ListTaskDefinitionFamilies returned in paginated output. When this parameter is used, ListTaskDefinitions only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListTaskDefinitionFamilies request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListTaskDefinitionFamilies returns up to 100 results and a nextToken value if applicable. (spec name: maxResults)
]: any -> oneof<record<families: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"familyPrefix": $family_prefix, "status": $status, "nextToken": $body_next_token, "maxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of task definitions that are registered to your account. You can filter the results by family name with the familyPrefix parameter or by status with the status parameter.
#
# POST /
# operationId: ListTaskDefinitions
export def "list-task-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  --family-prefix: string # The full family name to filter the ListTaskDefinitions results with. Specifying a familyPrefix limits the listed task definitions to task definition revisions that belong to that family.
  --status: string@status-completer-2 # The task definition status to filter the ListTaskDefinitions results with. By default, only ACTIVE task definitions are listed. By setting this parameter to INACTIVE, you can view task definitions that are INACTIVE as long as an active task or service still references them. If you paginate the resulting output, be sure to keep the status value constant in each subsequent request.
  --sort: string@sort-completer # The order to sort the results in. Valid values are ASC and DESC. By default, (ASC) task definitions are listed lexicographically by family name and in ascending numerical order by revision so that the newest task definitions in a family are listed last. Setting this parameter to DESC reverses the sort order on family name and revision. This is so that the newest task definitions in a family are listed first.
  --body-next-token: string # The nextToken value returned from a ListTaskDefinitions request indicating that more results are available to fulfill the request and further calls will be needed. If maxResults was provided, it is possible the number of results to be fewer than maxResults. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes. (spec name: nextToken)
  --body-max-results: int # The maximum number of task definition results that ListTaskDefinitions returned in paginated output. When this parameter is used, ListTaskDefinitions only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListTaskDefinitions request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListTaskDefinitions returns up to 100 results and a nextToken value if applicable. (spec name: maxResults)
]: any -> oneof<record<taskDefinitionArns: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListTaskDefinitions")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"familyPrefix": $family_prefix, "status": $status, "sort": $sort, "nextToken": $body_next_token, "maxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of tasks. You can filter the results by cluster, task definition family, container instance, launch type, what IAM principal started the task, or by the desired status of the task. Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour.
#
# POST /
# operationId: ListTasks
export def "list-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster to use when filtering the ListTasks results. If you do not specify a cluster, the default cluster is assumed.
  --container-instance: string # The container instance ID or full ARN of the container instance to use when filtering the ListTasks results. Specifying a containerInstance limits the results to tasks that belong to that container instance.
  --family: string # The name of the task definition family to use when filtering the ListTasks results. Specifying a family limits the results to tasks that belong to that family.
  --body-next-token: string # The nextToken value returned from a ListTasks request indicating that more results are available to fulfill the request and further calls will be needed. If maxResults was provided, it's possible the number of results to be fewer than maxResults. This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes. (spec name: nextToken)
  --body-max-results: int # The maximum number of task results that ListTasks returned in paginated output. When this parameter is used, ListTasks only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another ListTasks request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListTasks returns up to 100 results and a nextToken value if applicable. (spec name: maxResults)
  --started-by: string # The startedBy value to filter the task results with. Specifying a startedBy value limits the results to tasks that were started with that value. When you specify startedBy as the filter, it must be the only filter that you use.
  --service-name: string # The name of the service to use when filtering the ListTasks results. Specifying a serviceName limits the results to tasks that belong to that service.
  --desired-status: string@desired-status-completer # The task desired status to use when filtering the ListTasks results. Specifying a desiredStatus of STOPPED limits the results to tasks that Amazon ECS has set the desired status to STOPPED. This can be useful for debugging tasks that aren't starting properly or have died or finished. The default status filter is RUNNING, which shows tasks that Amazon ECS has set the desired status to RUNNING. Although you can filter results based on a desired status of PENDING, this doesn't return any results. Amazon ECS never sets the desired status of a task to that value (only a task's lastStatus may have a value of PENDING).
  --launch-type: string@launch-type-completer # The launch type to use when filtering the ListTasks results.
]: any -> oneof<record<taskArns: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.ListTasks")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"cluster": $cluster, "containerInstance": $container_instance, "family": $family, "nextToken": $body_next_token, "maxResults": $body_max_results, "startedBy": $started_by, "serviceName": $service_name, "desiredStatus": $desired_status, "launchType": $launch_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies an account setting. Account settings are set on a per-Region basis. If you change the root user account setting, the default settings are reset for users and roles that do not have specified individual account settings. For more information, see Account Settings (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html) in the Amazon Elastic Container Service Developer Guide. When serviceLongArnFormat, taskLongArnFormat, or containerInstanceLongArnFormat are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified user, role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource is defined by the opt-in status of the user or role that created the resource. You must turn on this setting to use Amazon ECS features such as resource tagging. When awsvpcTrunking is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If awsvpcTrunking is turned on, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see Elastic Network Interface Trunking (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html) in the Amazon Elastic Container Service Developer Guide. When containerInsights is specified, the default setting indicating whether Amazon Web Services CloudWatch Container Insights is turned on for your clusters is changed. If containerInsights is turned on, any new clusters that are created will have Container Insights turned on unless you disable it during cluster creation. For more information, see CloudWatch Container Insights (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html) in the Amazon Elastic Container Service Developer Guide. Amazon ECS is introducing tagging authorization for resource creation. Users must have permissions for actions that create the resource, such as ecsCreateCluster. If tags are specified when you create a resource, Amazon Web Services performs additional authorization to verify if users or roles have permissions to create tags. Therefore, you must grant explicit permissions to use the ecs:TagResource action. For more information, see Grant permission to tag resources on creation (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/supported-iam-actions-tagging.html) in the Amazon ECS Developer Guide.
#
# POST /
# operationId: PutAccountSetting
export def "put-account-setting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  name: string@name-completer # The Amazon ECS resource name for which to modify the account setting. If serviceLongArnFormat is specified, the ARN for your Amazon ECS services is affected. If taskLongArnFormat is specified, the ARN and resource ID for your Amazon ECS tasks is affected. If containerInstanceLongArnFormat is specified, the ARN and resource ID for your Amazon ECS container instances is affected. If awsvpcTrunking is specified, the elastic network interface (ENI) limit for your Amazon ECS container instances is affected. If containerInsights is specified, the default setting for Amazon Web Services CloudWatch Container Insights for your clusters is affected. If fargateFIPSMode is specified, Fargate FIPS 140 compliance is affected. If tagResourceAuthorization is specified, the opt-in option for tagging resources on creation is affected. For information about the opt-in timeline, see Tagging authorization timeline (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html#tag-resources) in the Amazon ECS Developer Guide.
  value: string # The account setting value for the specified principal ARN. Accepted values are enabled and disabled.
  --principal-arn: string # The ARN of the principal, which can be a user, role, or the root user. If you specify the root user, it modifies the account setting for all users, roles, and the root user of the account unless a user or role explicitly overrides these settings. If this field is omitted, the setting is changed only for the authenticated user. Federated users assume the account setting of the root user and can't have explicit account settings set for them.
]: any -> oneof<record<setting: record<name: string, value: string, principalArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.PutAccountSetting")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "value": $value, "principalArn": $principal_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies an account setting for all users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
#
# POST /
# operationId: PutAccountSettingDefault
export def "put-account-setting-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34 # required
  name: string@name-completer # The resource name for which to modify the account setting. If serviceLongArnFormat is specified, the ARN for your Amazon ECS services is affected. If taskLongArnFormat is specified, the ARN and resource ID for your Amazon ECS tasks is affected. If containerInstanceLongArnFormat is specified, the ARN and resource ID for your Amazon ECS container instances is affected. If awsvpcTrunking is specified, the ENI limit for your Amazon ECS container instances is affected. If containerInsights is specified, the default setting for Amazon Web Services CloudWatch Container Insights for your clusters is affected. If tagResourceAuthorization is specified, the opt-in option for tagging resources on creation is affected. For information about the opt-in timeline, see Tagging authorization timeline (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html#tag-resources) in the Amazon ECS Developer Guide. When you specify fargateFIPSMode for the name and enabled for the value, Fargate uses FIPS-140 compliant cryptographic algorithms on your tasks. For more information about FIPS-140 compliance with Fargate, see Amazon Web Services Fargate Federal Information Processing Standard (FIPS) 140-2 compliance (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-fips-compliance.html) in the Amazon Elastic Container Service Developer Guide.
  value: string # The account setting value for the specified principal ARN. Accepted values are enabled and disabled.
]: any -> oneof<record<setting: record<name: string, value: string, principalArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "value": $value} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create or update an attribute on an Amazon ECS resource. If the attribute doesn't exist, it's created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use DeleteAttributes. For more information, see Attributes (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: PutAttributes
export def "put-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that contains the resource to apply attributes. If you do not specify a cluster, the default cluster is assumed.
  attributes: list # The attributes to apply to your resource. You can specify up to 10 custom attributes for each resource. You can specify up to 10 attributes in a single call. — item shape: {name: string, value?: string, targetType?: "container-instance", targetId?: string}
]: any -> oneof<record<attributes: table<name: string, value: string, targetType: string, targetId: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.PutAttributes")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "attributes": $attributes} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the available capacity providers and the default capacity provider strategy for a cluster. You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers that are associated with a cluster that are omitted from a PutClusterCapacityProviders API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks. When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. We recommend that you define a default capacity provider strategy for your cluster. However, you must specify an empty array ([]) to bypass defining a default strategy.
#
# POST /
# operationId: PutClusterCapacityProviders
export def "put-cluster-capacity-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36 # required
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster to modify the capacity provider settings for. If you don't specify a cluster, the default cluster is assumed.
  capacity_providers: list<string> # The name of one or more capacity providers to associate with the cluster. If specifying a capacity provider that uses an Auto Scaling group, the capacity provider must already be created. New capacity providers can be created with the CreateCapacityProvider API operation. To use a Fargate capacity provider, specify either the FARGATE or FARGATE_SPOT capacity providers. The Fargate capacity providers are available to all accounts and only need to be associated with a cluster to be used.
  default_capacity_provider_strategy: list # The capacity provider strategy to use by default for the cluster. When creating a service or running a task on a cluster, if no capacity provider or launch type is specified then the default capacity provider strategy for the cluster is used. A capacity provider strategy consists of one or more capacity providers along with the base and weight to assign to them. A capacity provider must be associated with the cluster to be used in a capacity provider strategy. The PutClusterCapacityProviders API is used to associate a capacity provider with a cluster. Only capacity providers with an ACTIVE or UPDATING status can be used. If specifying a capacity provider that uses an Auto Scaling group, the capacity provider must already be created. New capacity providers can be created with the CreateCapacityProvider API operation. To use a Fargate capacity provider, specify either the FARGATE or FARGATE_SPOT capacity providers. The Fargate capacity providers are available to all accounts and only need to be associated with a cluster to be used. — item shape: {capacityProvider: string, weight?: int, base?: int}
]: any -> oneof<record<cluster: record<clusterArn: string, clusterName: string, configuration: record<executeCommandConfiguration: record>, status: string, registeredContainerInstancesCount: int, runningTasksCount: int, pendingTasksCount: int, activeServicesCount: int, statistics: list<record>, tags: list<record>, settings: list<record>, capacityProviders: list<string>, defaultCapacityProviderStrategy: list<record>, attachments: list<record>, attachmentsStatus: string, serviceConnectDefaults: record<namespace: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "capacityProviders": $capacity_providers, "defaultCapacityProviderStrategy": $default_capacity_provider_strategy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent. Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.
#
# POST /
# operationId: RegisterContainerInstance
export def "register-container-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster to register your container instance with. If you do not specify a cluster, the default cluster is assumed.
  --instance-identity-document: string # The instance identity document for the EC2 instance to register. This document can be found by running the following command from the instance: curl http://169.254.169.254/latest/dynamic/instance-identity/document/
  --instance-identity-document-signature: string # The instance identity document signature for the EC2 instance to register. This signature can be found by running the following command from the instance: curl http://169.254.169.254/latest/dynamic/instance-identity/signature/
  --total-resources: list # The resources available on the instance. — item shape: {name?: string, type?: string, doubleValue?: float, longValue?: int, integerValue?: int, stringSetValue?: list<string>}
  --version-info: record # The Docker and Amazon ECS container agent version information about a container instance. — shape: {agentVersion?: string, agentHash?: string, dockerVersion?: string}
  --container-instance-arn: string # The ARN of the container instance (if it was previously registered).
  --attributes: list # The container instance attributes that this container instance supports. — item shape: {name: string, value?: string, targetType?: "container-instance", targetId?: string}
  --platform-devices: list # The devices that are available on the container instance. The only supported device type is a GPU. — item shape: {id: string, type: "GPU"}
  --tags: list # The metadata that you apply to the container instance to help you categorize and organize them. Each tag consists of a key and an optional value. You define both. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
]: any -> oneof<record<containerInstance: record<containerInstanceArn: string, ec2InstanceId: string, capacityProviderName: string, version: int, versionInfo: record<agentVersion: string, agentHash: string, dockerVersion: string>, remainingResources: list<record>, registeredResources: list<record>, status: string, statusReason: string, agentConnected: bool, runningTasksCount: int, pendingTasksCount: int, agentUpdateStatus: string, attributes: list<record>, registeredAt: string, attachments: list<record>, tags: list<record>, healthStatus: record<overallStatus: string, details: list>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.RegisterContainerInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "instanceIdentityDocument": $instance_identity_document, "instanceIdentityDocumentSignature": $instance_identity_document_signature, "totalResources": $total_resources, "versionInfo": $version_info, "containerInstanceArn": $container_instance_arn, "attributes": $attributes, "platformDevices": $platform_devices, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Registers a new task definition from the supplied family and containerDefinitions. Optionally, you can add data volumes to your containers with the volumes parameter. For more information about task definition parameters and defaults, see Amazon ECS Task Definitions (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html) in the Amazon Elastic Container Service Developer Guide. You can specify a role for your task with the taskRoleArn parameter. When you specify a role for a task, its containers can then use the latest versions of the CLI or SDKs to make API requests to the Amazon Web Services services that are specified in the policy that's associated with the role. For more information, see IAM Roles for Tasks (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html) in the Amazon Elastic Container Service Developer Guide. You can specify a Docker networking mode for the containers in your task definition with the networkMode parameter. The available network modes correspond to those described in Network settings (https://docs.docker.com/engine/reference/run/#/network-settings) in the Docker run reference. If you specify the awsvpc network mode, the task is allocated an elastic network interface, and you must specify a NetworkConfiguration when you create a service or run a task with the task definition. For more information, see Task Networking (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: RegisterTaskDefinition
export def "register-task-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38 # required
  family: string # You must specify a family for a task definition. You can use it track multiple versions of the same task definition. The family is used as a name for your task definition. Up to 255 letters (uppercase and lowercase), numbers, underscores, and hyphens are allowed.
  --task-role-arn: string # The short name or full Amazon Resource Name (ARN) of the IAM role that containers in this task can assume. All containers in this task are granted the permissions that are specified in this role. For more information, see IAM Roles for Tasks (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html) in the Amazon Elastic Container Service Developer Guide.
  --execution-role-arn: string # The Amazon Resource Name (ARN) of the task execution role that grants the Amazon ECS container agent permission to make Amazon Web Services API calls on your behalf. The task execution IAM role is required depending on the requirements of your task. For more information, see Amazon ECS task execution IAM role (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html) in the Amazon Elastic Container Service Developer Guide.
  --network-mode: string@network-mode-completer # The Docker networking mode to use for the containers in the task. The valid values are none, bridge, awsvpc, and host. If no network mode is specified, the default is bridge. For Amazon ECS tasks on Fargate, the awsvpc network mode is required. For Amazon ECS tasks on Amazon EC2 Linux instances, any network mode can be used. For Amazon ECS tasks on Amazon EC2 Windows instances, <default> or awsvpc can be used. If the network mode is set to none, you cannot specify port mappings in your container definitions, and the tasks containers do not have external connectivity. The host and awsvpc network modes offer the highest networking performance for containers because they use the EC2 network stack instead of the virtualized network stack provided by the bridge mode. With the host and awsvpc network modes, exposed container ports are mapped directly to the corresponding host port (for the host network mode) or the attached elastic network interface port (for the awsvpc network mode), so you cannot take advantage of dynamic host port mappings. When using the host network mode, you should not run containers using the root user (UID 0). It is considered best practice to use a non-root user. If the network mode is awsvpc, the task is allocated an elastic network interface, and you must specify a NetworkConfiguration value when you create a service or run a task with the task definition. For more information, see Task Networking (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html) in the Amazon Elastic Container Service Developer Guide. If the network mode is host, you cannot run multiple instantiations of the same task on a single container instance when port mappings are used. For more information, see Network settings (https://docs.docker.com/engine/reference/run/#network-settings) in the Docker run reference.
  container_definitions: list # A list of container definitions in JSON format that describe the different containers that make up your task. — item shape: {name?: string, image?: string, repositoryCredentials?: record, cpu?: int, memory?: int, memoryReservation?: int, links?: list<string>, portMappings?: list, essential?: bool, entryPoint?: list<string>, command?: list<string>, environment?: list, environmentFiles?: list, mountPoints?: list, volumesFrom?: list, linuxParameters?: record, secrets?: list, dependsOn?: list, startTimeout?: int, stopTimeout?: int, hostname?: string, user?: string, workingDirectory?: string, disableNetworking?: bool, ... (15 more fields)}
  --volumes: list # A list of volume definitions in JSON format that containers in your task might use. — item shape: {name?: string, host?: record, dockerVolumeConfiguration?: record, efsVolumeConfiguration?: record, fsxWindowsFileServerVolumeConfiguration?: record}
  --placement-constraints: list # An array of placement constraint objects to use for the task. You can specify a maximum of 10 constraints for each task. This limit includes constraints in the task definition and those specified at runtime. — item shape: {type?: "memberOf", expression?: string}
  --requires-compatibilities: list<string> # The task launch type that Amazon ECS validates the task definition against. A client exception is returned if the task definition doesn't validate against the compatibilities specified. If no value is specified, the parameter is omitted from the response.
  --cpu: string # The number of CPU units used by the task. It can be expressed as an integer using CPU units (for example, 1024) or as a string using vCPUs (for example, 1 vCPU or 1 vcpu) in a task definition. String values are converted to an integer indicating the CPU units when the task definition is registered. Task-level CPU and memory parameters are ignored for Windows containers. We recommend specifying container-level resources for Windows containers. If you're using the EC2 launch type, this field is optional. Supported values are between 128 CPU units (0.125 vCPUs) and 10240 CPU units (10 vCPUs). If you do not specify a value, the parameter is ignored. If you're using the Fargate launch type, this field is required and you must use one of the following values, which determines your range of supported values for the memory parameter: The CPU units cannot be less than 1 vCPU when you use Windows containers on Fargate. 256 (.25 vCPU) - Available memory values: 512 (0.5 GB), 1024 (1 GB), 2048 (2 GB) 512 (.5 vCPU) - Available memory values: 1024 (1 GB), 2048 (2 GB), 3072 (3 GB), 4096 (4 GB) 1024 (1 vCPU) - Available memory values: 2048 (2 GB), 3072 (3 GB), 4096 (4 GB), 5120 (5 GB), 6144 (6 GB), 7168 (7 GB), 8192 (8 GB) 2048 (2 vCPU) - Available memory values: 4096 (4 GB) and 16384 (16 GB) in increments of 1024 (1 GB) 4096 (4 vCPU) - Available memory values: 8192 (8 GB) and 30720 (30 GB) in increments of 1024 (1 GB) 8192 (8 vCPU) - Available memory values: 16 GB and 60 GB in 4 GB increments This option requires Linux platform 1.4.0 or later. 16384 (16vCPU) - Available memory values: 32GB and 120 GB in 8 GB increments This option requires Linux platform 1.4.0 or later.
  --memory: string # The amount of memory (in MiB) used by the task. It can be expressed as an integer using MiB (for example ,1024) or as a string using GB (for example, 1GB or 1 GB) in a task definition. String values are converted to an integer indicating the MiB when the task definition is registered. Task-level CPU and memory parameters are ignored for Windows containers. We recommend specifying container-level resources for Windows containers. If using the EC2 launch type, this field is optional. If using the Fargate launch type, this field is required and you must use one of the following values. This determines your range of supported values for the cpu parameter. The CPU units cannot be less than 1 vCPU when you use Windows containers on Fargate. 512 (0.5 GB), 1024 (1 GB), 2048 (2 GB) - Available cpu values: 256 (.25 vCPU) 1024 (1 GB), 2048 (2 GB), 3072 (3 GB), 4096 (4 GB) - Available cpu values: 512 (.5 vCPU) 2048 (2 GB), 3072 (3 GB), 4096 (4 GB), 5120 (5 GB), 6144 (6 GB), 7168 (7 GB), 8192 (8 GB) - Available cpu values: 1024 (1 vCPU) Between 4096 (4 GB) and 16384 (16 GB) in increments of 1024 (1 GB) - Available cpu values: 2048 (2 vCPU) Between 8192 (8 GB) and 30720 (30 GB) in increments of 1024 (1 GB) - Available cpu values: 4096 (4 vCPU) Between 16 GB and 60 GB in 4 GB increments - Available cpu values: 8192 (8 vCPU) This option requires Linux platform 1.4.0 or later. Between 32GB and 120 GB in 8 GB increments - Available cpu values: 16384 (16 vCPU) This option requires Linux platform 1.4.0 or later.
  --tags: list # The metadata that you apply to the task definition to help you categorize and organize them. Each tag consists of a key and an optional value. You define both of them. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
  --pid-mode: string@pid-mode-completer # The process namespace to use for the containers in the task. The valid values are host or task. If host is specified, then all containers within the tasks that specified the host PID mode on the same container instance share the same process namespace with the host Amazon EC2 instance. If task is specified, all containers within the specified task share the same process namespace. If no value is specified, the default is a private namespace. For more information, see PID settings (https://docs.docker.com/engine/reference/run/#pid-settings---pid) in the Docker run reference. If the host PID mode is used, be aware that there is a heightened risk of undesired process namespace expose. For more information, see Docker security (https://docs.docker.com/engine/security/security/). This parameter is not supported for Windows containers or tasks run on Fargate.
  --ipc-mode: string@ipc-mode-completer # The IPC resource namespace to use for the containers in the task. The valid values are host, task, or none. If host is specified, then all containers within the tasks that specified the host IPC mode on the same container instance share the same IPC resources with the host Amazon EC2 instance. If task is specified, all containers within the specified task share the same IPC resources. If none is specified, then IPC resources within the containers of a task are private and not shared with other containers in a task or on the container instance. If no value is specified, then the IPC resource namespace sharing depends on the Docker daemon setting on the container instance. For more information, see IPC settings (https://docs.docker.com/engine/reference/run/#ipc-settings---ipc) in the Docker run reference. If the host IPC mode is used, be aware that there is a heightened risk of undesired IPC namespace expose. For more information, see Docker security (https://docs.docker.com/engine/security/security/). If you are setting namespaced kernel parameters using systemControls for the containers in the task, the following will apply to your IPC resource namespace. For more information, see System Controls (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html) in the Amazon Elastic Container Service Developer Guide. For tasks that use the host IPC mode, IPC namespace related systemControls are not supported. For tasks that use the task IPC mode, IPC namespace related systemControls will apply to all containers within a task. This parameter is not supported for Windows containers or tasks run on Fargate.
  --proxy-configuration: record # The configuration details for the App Mesh proxy. For tasks that use the EC2 launch type, the container instances require at least version 1.26.0 of the container agent and at least version 1.26.0-1 of the ecs-init package to use a proxy configuration. If your container instances are launched from the Amazon ECS optimized AMI version 20190301 or later, then they contain the required versions of the container agent and ecs-init. For more information, see Amazon ECS-optimized Linux AMI (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html) — shape: {type?: "APPMESH", containerName: string, properties?: any}
  --inference-accelerators: list # The Elastic Inference accelerators to use for the containers in the task. — item shape: {deviceName: string, deviceType: string}
  --ephemeral-storage: record # The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount, for tasks hosted on Fargate. For more information, see Fargate task storage (https://docs.aws.amazon.com/AmazonECS/latest/userguide/using_data_volumes.html) in the Amazon ECS User Guide for Fargate. For tasks using the Fargate launch type, the task requires the following platforms: Linux platform version 1.4.0 or later. Windows platform version 1.0.0 or later. — shape: {sizeInGiB: int}
  --runtime-platform: record # Information about the platform for the Amazon ECS service or task. For more information about RuntimePlatform, see RuntimePlatform (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform) in the Amazon Elastic Container Service Developer Guide. — shape: {cpuArchitecture?: "X86_64"|"ARM64", operatingSystemFamily?: "WINDOWS_SERVER_2019_FULL"|"WINDOWS_SERVER_2019_CORE"|"WINDOWS_SERVER_2016_FULL"|"WINDOWS_SERVER_2004_CORE"|"WINDOWS_SERVER_2022_CORE"|"WINDOWS_SERVER_2022_FULL"|"WINDOWS_SERVER_20H2_CORE"|"LINUX"}
]: any -> oneof<record<taskDefinition: record<taskDefinitionArn: string, containerDefinitions: list<record>, family: string, taskRoleArn: string, executionRoleArn: string, networkMode: string, revision: int, volumes: list<record>, status: string, requiresAttributes: list<record>, placementConstraints: list<record>, compatibilities: list<string>, runtimePlatform: record<cpuArchitecture: string, operatingSystemFamily: string>, requiresCompatibilities: list<string>, cpu: string, memory: string, inferenceAccelerators: list<record>, pidMode: string, ipcMode: string, proxyConfiguration: record<type: string, containerName: string, properties: any>, registeredAt: string, deregisteredAt: string, registeredBy: string, ephemeralStorage: record<sizeInGiB: int>>, tags: table<key: string, value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"family": $family, "taskRoleArn": $task_role_arn, "executionRoleArn": $execution_role_arn, "networkMode": $network_mode, "containerDefinitions": $container_definitions, "volumes": $volumes, "placementConstraints": $placement_constraints, "requiresCompatibilities": $requires_compatibilities, "cpu": $cpu, "memory": $memory, "tags": $tags, "pidMode": $pid_mode, "ipcMode": $ipc_mode, "proxyConfiguration": $proxy_configuration, "inferenceAccelerators": $inference_accelerators, "ephemeralStorage": $ephemeral_storage, "runtimePlatform": $runtime_platform} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Starts a new task using the specified task definition. You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see Scheduling Tasks (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html) in the Amazon Elastic Container Service Developer Guide. Alternatively, you can use StartTask to use your own scheduler or place tasks manually on specific container instances. Starting April 15, 2023, Amazon Web Services will not onboard new customers to Amazon Elastic Inference (EI), and will help current customers migrate their workloads to options that offer better price and performance. After April 15, 2023, new customers will not be able to launch instances with Amazon EI accelerators in Amazon SageMaker, Amazon ECS, or Amazon EC2. However, customers who have used Amazon EI at least once during the past 30-day period are considered current customers and will be able to continue using the service. The Amazon ECS API follows an eventual consistency model. This is because of the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command. To manage eventual consistency, you can do the following: Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time. Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.
#
# POST /
# operationId: RunTask
export def "run-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-39 # required
  --capacity-provider-strategy: list # The capacity provider strategy to use for the task. If a capacityProviderStrategy is specified, the launchType parameter must be omitted. If no capacityProviderStrategy or launchType is specified, the defaultCapacityProviderStrategy for the cluster is used. When you use cluster auto scaling, you must specify capacityProviderStrategy and not launchType. A capacity provider strategy may contain a maximum of 6 capacity providers. — item shape: {capacityProvider: string, weight?: int, base?: int}
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster to run your task on. If you do not specify a cluster, the default cluster is assumed.
  --count: int # The number of instantiations of the specified task to place on your cluster. You can specify up to 10 tasks for each call.
  --enable-ecs-managed-tags: oneof<nothing, bool> # Specifies whether to use Amazon ECS managed tags for the task. For more information, see Tagging Your Amazon ECS Resources (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-using-tags.html) in the Amazon Elastic Container Service Developer Guide.
  --enable-execute-command: oneof<nothing, bool> # Determines whether to use the execute command functionality for the containers in this task. If true, this enables execute command functionality on all containers in the task. If true, then the task definition must have a task role, or you must provide one as an override.
  --group: string # The name of the task group to associate with the task. The default value is the family name of the task definition (for example, family:my-family-name).
  --launch-type: string@launch-type-completer # The infrastructure to run your standalone task on. For more information, see Amazon ECS launch types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html) in the Amazon Elastic Container Service Developer Guide. The FARGATE launch type runs your tasks on Fargate On-Demand infrastructure. Fargate Spot infrastructure is available for use but a capacity provider strategy must be used. For more information, see Fargate capacity providers (https://docs.aws.amazon.com/AmazonECS/latest/userguide/fargate-capacity-providers.html) in the Amazon ECS User Guide for Fargate. The EC2 launch type runs your tasks on Amazon EC2 instances registered to your cluster. The EXTERNAL launch type runs your tasks on your on-premises server or virtual machine (VM) capacity registered to your cluster. A task can use either a launch type or a capacity provider strategy. If a launchType is specified, the capacityProviderStrategy parameter must be omitted. When you use cluster auto scaling, you must specify capacityProviderStrategy and not launchType.
  --network-configuration: record # The network configuration for a task or service. — shape: {awsvpcConfiguration?: record}
  --overrides: record # The overrides that are associated with a task. — shape: {containerOverrides?: list, cpu?: string, inferenceAcceleratorOverrides?: list, executionRoleArn?: string, memory?: string, taskRoleArn?: string, ephemeralStorage?: record}
  --placement-constraints: list # An array of placement constraint objects to use for the task. You can specify up to 10 constraints for each task (including constraints in the task definition and those specified at runtime). — item shape: {type?: "distinctInstance"|"memberOf", expression?: string}
  --placement-strategy: list # The placement strategy objects to use for the task. You can specify a maximum of 5 strategy rules for each task. — item shape: {type?: "random"|"spread"|"binpack", field?: string}
  --platform-version: string # The platform version the task uses. A platform version is only specified for tasks hosted on Fargate. If one isn't specified, the LATEST platform version is used. For more information, see Fargate platform versions (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html) in the Amazon Elastic Container Service Developer Guide.
  --propagate-tags: string@propagate-tags-completer # Specifies whether to propagate the tags from the task definition to the task. If no value is specified, the tags aren't propagated. Tags can only be propagated to the task during task creation. To add tags to a task after task creation, use the TagResource API action. An error will be received if you specify the SERVICE option when running a task.
  --reference-id: string # The reference ID to use for the task. The reference ID can have a maximum length of 1024 characters.
  --started-by: string # An optional tag specified when a task is started. For example, if you automatically trigger a task to run a batch process job, you could apply a unique identifier for that job to your task with the startedBy parameter. You can then identify which tasks belong to that job by filtering the results of a ListTasks call with the startedBy value. Up to 36 letters (uppercase and lowercase), numbers, hyphens (-), and underscores (_) are allowed. If a task is started by an Amazon ECS service, then the startedBy parameter contains the deployment ID of the service that starts it.
  --tags: list # The metadata that you apply to the task to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
  task_definition: string # The family and revision (family:revision) or full ARN of the task definition to run. If a revision isn't specified, the latest ACTIVE revision is used. When you create a policy for run-task, you can set the resource to be the latest task definition revision, or a specific revision. The full ARN value must match the value that you specified as the Resource of the principal's permissions policy. When you specify the policy resource as the latest task definition version (by setting the Resource in the policy to arn:aws:ecs:us-east-1:111122223333:task-definition/TaskFamilyName), then set this value to arn:aws:ecs:us-east-1:111122223333:task-definition/TaskFamilyName. When you specify the policy resource as a specific task definition version (by setting the Resource in the policy to arn:aws:ecs:us-east-1:111122223333:task-definition/TaskFamilyName:1 or arn:aws:ecs:us-east-1:111122223333:task-definition/TaskFamilyName:*), then set this value to arn:aws:ecs:us-east-1:111122223333:task-definition/TaskFamilyName:1. For more information, see Policy Resources for Amazon ECS (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security_iam_service-with-iam.html#security_iam_service-with-iam-id-based-policies-resources) in the Amazon Elastic Container Service developer Guide.
]: any -> oneof<record<tasks: table<attachments: list, attributes: list, availabilityZone: string, capacityProviderName: string, clusterArn: string, connectivity: string, connectivityAt: string, containerInstanceArn: string, containers: list, cpu: string, createdAt: string, desiredStatus: string, enableExecuteCommand: bool, executionStoppedAt: string, group: string, healthStatus: string, inferenceAccelerators: list, lastStatus: string, launchType: string, memory: string, overrides: record, platformVersion: string, platformFamily: string, pullStartedAt: string, pullStoppedAt: string, startedAt: string, startedBy: string, stopCode: string, stoppedAt: string, stoppedReason: string, stoppingAt: string, tags: list, taskArn: string, taskDefinitionArn: string, version: int, ephemeralStorage: record>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.RunTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"capacityProviderStrategy": $capacity_provider_strategy, "cluster": $cluster, "count": $count, "enableECSManagedTags": $enable_ecs_managed_tags, "enableExecuteCommand": $enable_execute_command, "group": $group, "launchType": $launch_type, "networkConfiguration": $network_configuration, "overrides": $overrides, "placementConstraints": $placement_constraints, "placementStrategy": $placement_strategy, "platformVersion": $platform_version, "propagateTags": $propagate_tags, "referenceId": $reference_id, "startedBy": $started_by, "tags": $tags, "taskDefinition": $task_definition} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Starts a new task from the specified task definition on the specified container instance or instances. Starting April 15, 2023, Amazon Web Services will not onboard new customers to Amazon Elastic Inference (EI), and will help current customers migrate their workloads to options that offer better price and performance. After April 15, 2023, new customers will not be able to launch instances with Amazon EI accelerators in Amazon SageMaker, Amazon ECS, or Amazon EC2. However, customers who have used Amazon EI at least once during the past 30-day period are considered current customers and will be able to continue using the service. Alternatively, you can use RunTask to place tasks for you. For more information, see Scheduling Tasks (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: StartTask
export def "start-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster where to start your task. If you do not specify a cluster, the default cluster is assumed.
  container_instances: list<string> # The container instance IDs or full ARN entries for the container instances where you would like to place your task. You can specify up to 10 container instances.
  --enable-ecs-managed-tags: oneof<nothing, bool> # Specifies whether to use Amazon ECS managed tags for the task. For more information, see Tagging Your Amazon ECS Resources (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-using-tags.html) in the Amazon Elastic Container Service Developer Guide.
  --enable-execute-command: oneof<nothing, bool> # Whether or not the execute command functionality is turned on for the task. If true, this turns on the execute command functionality on all containers in the task.
  --group: string # The name of the task group to associate with the task. The default value is the family name of the task definition (for example, family:my-family-name).
  --network-configuration: record # The network configuration for a task or service. — shape: {awsvpcConfiguration?: record}
  --overrides: record # The overrides that are associated with a task. — shape: {containerOverrides?: list, cpu?: string, inferenceAcceleratorOverrides?: list, executionRoleArn?: string, memory?: string, taskRoleArn?: string, ephemeralStorage?: record}
  --propagate-tags: string@propagate-tags-completer # Specifies whether to propagate the tags from the task definition or the service to the task. If no value is specified, the tags aren't propagated.
  --reference-id: string # The reference ID to use for the task.
  --started-by: string # An optional tag specified when a task is started. For example, if you automatically trigger a task to run a batch process job, you could apply a unique identifier for that job to your task with the startedBy parameter. You can then identify which tasks belong to that job by filtering the results of a ListTasks call with the startedBy value. Up to 36 letters (uppercase and lowercase), numbers, hyphens (-), and underscores (_) are allowed. If a task is started by an Amazon ECS service, the startedBy parameter contains the deployment ID of the service that starts it.
  --tags: list # The metadata that you apply to the task to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
  task_definition: string # The family and revision (family:revision) or full ARN of the task definition to start. If a revision isn't specified, the latest ACTIVE revision is used.
]: any -> oneof<record<tasks: table<attachments: list, attributes: list, availabilityZone: string, capacityProviderName: string, clusterArn: string, connectivity: string, connectivityAt: string, containerInstanceArn: string, containers: list, cpu: string, createdAt: string, desiredStatus: string, enableExecuteCommand: bool, executionStoppedAt: string, group: string, healthStatus: string, inferenceAccelerators: list, lastStatus: string, launchType: string, memory: string, overrides: record, platformVersion: string, platformFamily: string, pullStartedAt: string, pullStoppedAt: string, startedAt: string, startedBy: string, stopCode: string, stoppedAt: string, stoppedReason: string, stoppingAt: string, tags: list, taskArn: string, taskDefinitionArn: string, version: int, ephemeralStorage: record>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.StartTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "containerInstances": $container_instances, "enableECSManagedTags": $enable_ecs_managed_tags, "enableExecuteCommand": $enable_execute_command, "group": $group, "networkConfiguration": $network_configuration, "overrides": $overrides, "propagateTags": $propagate_tags, "referenceId": $reference_id, "startedBy": $started_by, "tags": $tags, "taskDefinition": $task_definition} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Stops a running task. Any tags associated with the task will be deleted. When StopTask is called on a task, the equivalent of docker stop is issued to the containers running in the task. This results in a SIGTERM value and a default 30-second timeout, after which the SIGKILL value is sent and the containers are forcibly stopped. If the container handles the SIGTERM value gracefully and exits within 30 seconds from receiving it, no SIGKILL value is sent. The default 30-second timeout can be configured on the Amazon ECS container agent with the ECS_CONTAINER_STOP_TIMEOUT variable. For more information, see Amazon ECS Container Agent Configuration (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: StopTask
export def "stop-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the task to stop. If you do not specify a cluster, the default cluster is assumed.
  task: string # The task ID of the task to stop.
  --reason: string # An optional message specified when a task is stopped. For example, if you're using a custom scheduler, you can use this parameter to specify the reason for stopping the task here, and the message appears in subsequent DescribeTasks API operations on this task. Up to 255 characters are allowed in this message.
]: any -> oneof<record<task: record<attachments: list<record>, attributes: list<record>, availabilityZone: string, capacityProviderName: string, clusterArn: string, connectivity: string, connectivityAt: string, containerInstanceArn: string, containers: list<record>, cpu: string, createdAt: string, desiredStatus: string, enableExecuteCommand: bool, executionStoppedAt: string, group: string, healthStatus: string, inferenceAccelerators: list<record>, lastStatus: string, launchType: string, memory: string, overrides: record<containerOverrides: list, cpu: string, inferenceAcceleratorOverrides: list, executionRoleArn: string, memory: string, taskRoleArn: string, ephemeralStorage: record>, platformVersion: string, platformFamily: string, pullStartedAt: string, pullStoppedAt: string, startedAt: string, startedBy: string, stopCode: string, stoppedAt: string, stoppedReason: string, stoppingAt: string, tags: list<record>, taskArn: string, taskDefinitionArn: string, version: int, ephemeralStorage: record<sizeInGiB: int>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.StopTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "task": $task, "reason": $reason} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent. Sent to acknowledge that an attachment changed states.
#
# POST /
# operationId: SubmitAttachmentStateChanges
export def "submit-attachment-state-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  --cluster: string # The short name or full ARN of the cluster that hosts the container instance the attachment belongs to.
  attachments: list # Any attachments associated with the state change request. — item shape: {attachmentArn: string, status: string}
]: any -> oneof<record<acknowledgment: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "attachments": $attachments} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent. Sent to acknowledge that a container changed states.
#
# POST /
# operationId: SubmitContainerStateChange
export def "submit-container-state-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  --cluster: string # The short name or full ARN of the cluster that hosts the container.
  --task: string # The task ID or full Amazon Resource Name (ARN) of the task that hosts the container.
  --container-name: string # The name of the container.
  --runtime-id: string # The ID of the Docker container.
  --status: string # The status of the state change request.
  --exit-code: int # The exit code that's returned for the state change request.
  --reason: string # The reason for the state change request.
  --network-bindings: list # The network bindings of the container. — item shape: {bindIP?: string, containerPort?: int, hostPort?: int, protocol?: "tcp"|"udp", containerPortRange?: string, hostPortRange?: string}
]: any -> oneof<record<acknowledgment: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "task": $task, "containerName": $container_name, "runtimeId": $runtime_id, "status": $status, "exitCode": $exit_code, "reason": $reason, "networkBindings": $network_bindings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent. Sent to acknowledge that a task changed states.
#
# POST /
# operationId: SubmitTaskStateChange
export def "submit-task-state-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the task.
  --task: string # The task ID or full ARN of the task in the state change request.
  --status: string # The status of the state change request.
  --reason: string # The reason for the state change request.
  --containers: list # Any containers that's associated with the state change request. — item shape: {containerName?: string, imageDigest?: string, runtimeId?: string, exitCode?: int, networkBindings?: list, reason?: string, status?: string}
  --attachments: list # Any attachments associated with the state change request. — item shape: {attachmentArn: string, status: string}
  --managed-agents: list # The details for the managed agent that's associated with the task. — item shape: {containerName: string, managedAgentName: "ExecuteCommandAgent", status: string, reason?: string}
  --pull-started-at: string # The Unix timestamp for the time when the container image pull started. (format: date-time)
  --pull-stopped-at: string # The Unix timestamp for the time when the container image pull completed. (format: date-time)
  --execution-stopped-at: string # The Unix timestamp for the time when the task execution stopped. (format: date-time)
]: any -> oneof<record<acknowledgment: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "task": $task, "status": $status, "reason": $reason, "containers": $containers, "attachments": $attachments, "managedAgents": $managed_agents, "pullStartedAt": $pull_started_at, "pullStoppedAt": $pull_stopped_at, "executionStoppedAt": $execution_stopped_at} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource aren't specified in the request parameters, they aren't changed. When a resource is deleted, the tags that are associated with that resource are deleted as well.
#
# POST /
# operationId: TagResource
export def "tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource to add tags to. Currently, the supported resources are Amazon ECS capacity providers, tasks, services, task definitions, clusters, and container instances.
  tags: list # The tags to add to the resource. A tag is an array of key-value pairs. The following basic restrictions apply to tags: Maximum number of tags per resource - 50 For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8 Maximum value length - 256 Unicode characters in UTF-8 If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case-sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for either keys or values as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys or values with this prefix. Tags with this prefix do not count against your tags per resource limit. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes specified tags from a resource.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource to delete tags from. Currently, the supported resources are Amazon ECS capacity providers, tasks, services, task definitions, clusters, and container instances.
  tag_keys: list<string> # The keys of the tags to be removed.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "tagKeys": $tag_keys} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters for a capacity provider.
#
# POST /
# operationId: UpdateCapacityProvider
export def "update-capacity-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  name: string # The name of the capacity provider to update.
  auto_scaling_group_provider: record # The details of the Auto Scaling group capacity provider to update. — shape: {managedScaling?: record, managedTerminationProtection?: "ENABLED"|"DISABLED"}
]: any -> oneof<record<capacityProvider: record<capacityProviderArn: string, name: string, status: string, autoScalingGroupProvider: record<autoScalingGroupArn: string, managedScaling: record, managedTerminationProtection: string>, updateStatus: string, updateStatusReason: string, tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateCapacityProvider")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "autoScalingGroupProvider": $auto_scaling_group_provider} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the cluster.
#
# POST /
# operationId: UpdateCluster
export def "update-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  cluster: string # The name of the cluster to modify the settings for.
  --settings: list # The cluster settings for your cluster. — item shape: {name?: "containerInsights", value?: string}
  --configuration: record # The execute command configuration for the cluster. — shape: {executeCommandConfiguration?: record}
  --service-connect-defaults: record # Use this parameter to set a default Service Connect namespace. After you set a default Service Connect namespace, any new services with Service Connect turned on that are created in the cluster are added as client services in the namespace. This setting only applies to new services that set the enabled parameter to true in the ServiceConnectConfiguration. You can set the namespace of each service individually in the ServiceConnectConfiguration to override this default parameter. Tasks that run in a namespace can use short names to connect to services in the namespace. Tasks can connect to services across all of the clusters in the namespace. Tasks connect through a managed proxy container that collects logs and metrics for increased visibility. Only the tasks that Amazon ECS services create are supported with Service Connect. For more information, see Service Connect (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html) in the Amazon Elastic Container Service Developer Guide. — shape: {namespace: string}
]: any -> oneof<record<cluster: record<clusterArn: string, clusterName: string, configuration: record<executeCommandConfiguration: record>, status: string, registeredContainerInstancesCount: int, runningTasksCount: int, pendingTasksCount: int, activeServicesCount: int, statistics: list<record>, tags: list<record>, settings: list<record>, capacityProviders: list<string>, defaultCapacityProviderStrategy: list<record>, attachments: list<record>, attachmentsStatus: string, serviceConnectDefaults: record<namespace: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateCluster")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "settings": $settings, "configuration": $configuration, "serviceConnectDefaults": $service_connect_defaults} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the settings to use for a cluster.
#
# POST /
# operationId: UpdateClusterSettings
export def "update-cluster-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49 # required
  cluster: string # The name of the cluster to modify the settings for.
  settings: list # The setting to use by default for a cluster. This parameter is used to turn on CloudWatch Container Insights for a cluster. If this value is specified, it overrides the containerInsights value set with PutAccountSetting or PutAccountSettingDefault. Currently, if you delete an existing cluster that does not have Container Insights turned on, and then create a new cluster with the same name with Container Insights tuned on, Container Insights will not actually be turned on. If you want to preserve the same name for your existing cluster and turn on Container Insights, you must wait 7 days before you can re-create it. — item shape: {name?: "containerInsights", value?: string}
]: any -> oneof<record<cluster: record<clusterArn: string, clusterName: string, configuration: record<executeCommandConfiguration: record>, status: string, registeredContainerInstancesCount: int, runningTasksCount: int, pendingTasksCount: int, activeServicesCount: int, statistics: list<record>, tags: list<record>, settings: list<record>, capacityProviders: list<string>, defaultCapacityProviderStrategy: list<record>, attachments: list<record>, attachmentsStatus: string, serviceConnectDefaults: record<namespace: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateClusterSettings")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "settings": $settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent doesn't interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system. The UpdateContainerAgent API isn't supported for container instances using the Amazon ECS-optimized Amazon Linux 2 (arm64) AMI. To update the container agent, you can update the ecs-init package. This updates the agent. For more information, see Updating the Amazon ECS container agent (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/agent-update-ecs-ami.html) in the Amazon Elastic Container Service Developer Guide. Agent updates with the UpdateContainerAgent API operation do not apply to Windows container instances. We recommend that you launch new container instances to update the agent version in your Windows clusters. The UpdateContainerAgent API requires an Amazon ECS-optimized AMI or Amazon Linux AMI with the ecs-init service installed and running. For help updating the Amazon ECS container agent on other operating systems, see Manually updating the Amazon ECS container agent (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: UpdateContainerAgent
export def "update-container-agent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that your container instance is running on. If you do not specify a cluster, the default cluster is assumed.
  container_instance: string # The container instance ID or full ARN entries for the container instance where you would like to update the Amazon ECS container agent.
]: any -> oneof<record<containerInstance: record<containerInstanceArn: string, ec2InstanceId: string, capacityProviderName: string, version: int, versionInfo: record<agentVersion: string, agentHash: string, dockerVersion: string>, remainingResources: list<record>, registeredResources: list<record>, status: string, statusReason: string, agentConnected: bool, runningTasksCount: int, pendingTasksCount: int, agentUpdateStatus: string, attributes: list<record>, registeredAt: string, attachments: list<record>, tags: list<record>, healthStatus: record<overallStatus: string, details: list>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateContainerAgent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "containerInstance": $container_instance} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the status of an Amazon ECS container instance. Once a container instance has reached an ACTIVE state, you can change the status of a container instance to DRAINING to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size. A container instance can't be changed to DRAINING until it has reached an ACTIVE status. If the instance is in any other status, an error will be received. When you set a container instance to DRAINING, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the PENDING state are stopped immediately. Service tasks on the container instance that are in the RUNNING state are stopped and replaced according to the service's deployment configuration parameters, minimumHealthyPercent and maximumPercent. You can change the deployment configuration of your service using UpdateService. If minimumHealthyPercent is below 100%, the scheduler can ignore desiredCount temporarily during task replacement. For example, desiredCount is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they're in the RUNNING state. Tasks for services that use a load balancer are considered healthy if they're in the RUNNING state and are reported as healthy by the load balancer. The maximumPercent parameter represents an upper limit on the number of running tasks during task replacement. You can use this to define the replacement batch size. For example, if desiredCount is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped. Any PENDING or RUNNING tasks that do not belong to a service aren't affected. You must wait for them to finish or stop them manually. A container instance has completed draining when it has no more RUNNING tasks. You can verify this using ListTasks. When a container instance has been drained, you can set a container instance to ACTIVE status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.
#
# POST /
# operationId: UpdateContainerInstancesState
export def "update-container-instances-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the container instance to update. If you do not specify a cluster, the default cluster is assumed.
  container_instances: list<string> # A list of up to 10 container instance IDs or full ARN entries.
  status: string@status-completer # The container instance state to update the container instance with. The only valid values for this action are ACTIVE and DRAINING. A container instance can only be updated to DRAINING status once it has reached an ACTIVE state. If a container instance is in REGISTERING, DEREGISTERING, or REGISTRATION_FAILED state you can describe the container instance but can't update the container instance state.
]: any -> oneof<record<containerInstances: table<containerInstanceArn: string, ec2InstanceId: string, capacityProviderName: string, version: int, versionInfo: record, remainingResources: list, registeredResources: list, status: string, statusReason: string, agentConnected: bool, runningTasksCount: int, pendingTasksCount: int, agentUpdateStatus: string, attributes: list, registeredAt: string, attachments: list, tags: list, healthStatus: record>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "containerInstances": $container_instances, "status": $status} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a service. For services using the rolling update (ECS) you can update the desired count, deployment configuration, network configuration, load balancers, service registries, enable ECS managed tags option, propagate tags option, task placement constraints and strategies, and task definition. When you update any of these parameters, Amazon ECS starts new tasks with the new configuration. For services using the blue/green (CODE_DEPLOY) deployment controller, only the desired count, deployment configuration, health check grace period, task placement constraints and strategies, enable ECS managed tags option, and propagate tags can be updated using this API. If the network configuration, platform version, task definition, or load balancer need to be updated, create a new CodeDeploy deployment. For more information, see CreateDeployment (https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html) in the CodeDeploy API Reference. For services using an external deployment controller, you can update only the desired count, task placement constraints and strategies, health check grace period, enable ECS managed tags option, and propagate tags option, using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, create a new task set For more information, see CreateTaskSet. You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new desiredCount parameter. If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy. If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, my_image:latest), you don't need to create a new revision of your task definition. You can update the service using the forceNewDeployment option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start. You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, minimumHealthyPercent and maximumPercent, to determine the deployment strategy. If minimumHealthyPercent is below 100%, the scheduler can ignore desiredCount temporarily during a deployment. For example, if desiredCount is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that don't use a load balancer are considered healthy if they're in the RUNNING state. Tasks for services that use a load balancer are considered healthy if they're in the RUNNING state and are reported as healthy by the load balancer. The maximumPercent parameter represents an upper limit on the number of running tasks during a deployment. You can use it to define the deployment batch size. For example, if desiredCount is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). When UpdateService stops a task during a deployment, the equivalent of docker stop is issued to the containers running in the task. This results in a SIGTERM and a 30-second timeout. After this, SIGKILL is sent and the containers are forcibly stopped. If the container handles the SIGTERM gracefully and exits within 30 seconds from receiving it, no SIGKILL is sent. When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic. Determine which of the container instances in your cluster can support your service's task definition. For example, they have the required CPU, memory, ports, and container instance attributes. By default, the service scheduler attempts to balance tasks across Availability Zones in this manner even though you can choose a different placement strategy. Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement. Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service. When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination. Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service. You must have a service-linked role when you update any of the following service properties. If you specified a custom role when you created the service, Amazon ECS automatically replaces the roleARN (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_Service.html#ECS-Type-Service-roleArn) associated with the service with the ARN of your service-linked role. For more information, see Service-linked roles (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html) in the Amazon Elastic Container Service Developer Guide. loadBalancers, serviceRegistries
#
# POST /
# operationId: UpdateService
export def "update-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-52 # required
  --cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that your service runs on. If you do not specify a cluster, the default cluster is assumed.
  service: string # The name of the service to update.
  --desired-count: int # The number of instantiations of the task to place and keep running in your service.
  --task-definition: string # The family and revision (family:revision) or full ARN of the task definition to run in your service. If a revision is not specified, the latest ACTIVE revision is used. If you modify the task definition with UpdateService, Amazon ECS spawns a task with the new version of the task definition and then stops an old task after the new version is running.
  --capacity-provider-strategy: list # The capacity provider strategy to update the service to use. if the service uses the default capacity provider strategy for the cluster, the service can be updated to use one or more capacity providers as opposed to the default capacity provider strategy. However, when a service is using a capacity provider strategy that's not the default capacity provider strategy, the service can't be updated to use the cluster's default capacity provider strategy. A capacity provider strategy consists of one or more capacity providers along with the base and weight to assign to them. A capacity provider must be associated with the cluster to be used in a capacity provider strategy. The PutClusterCapacityProviders API is used to associate a capacity provider with a cluster. Only capacity providers with an ACTIVE or UPDATING status can be used. If specifying a capacity provider that uses an Auto Scaling group, the capacity provider must already be created. New capacity providers can be created with the CreateCapacityProvider API operation. To use a Fargate capacity provider, specify either the FARGATE or FARGATE_SPOT capacity providers. The Fargate capacity providers are available to all accounts and only need to be associated with a cluster to be used. The PutClusterCapacityProviders API operation is used to update the list of available capacity providers for a cluster after the cluster is created. — item shape: {capacityProvider: string, weight?: int, base?: int}
  --deployment-configuration: record # Optional deployment parameters that control how many tasks run during a deployment and the ordering of stopping and starting tasks. — shape: {deploymentCircuitBreaker?: record, maximumPercent?: int, minimumHealthyPercent?: int, alarms?: record}
  --network-configuration: record # The network configuration for a task or service. — shape: {awsvpcConfiguration?: record}
  --placement-constraints: list # An array of task placement constraint objects to update the service to use. If no value is specified, the existing placement constraints for the service will remain unchanged. If this value is specified, it will override any existing placement constraints defined for the service. To remove all existing placement constraints, specify an empty array. You can specify a maximum of 10 constraints for each task. This limit includes constraints in the task definition and those specified at runtime. — item shape: {type?: "distinctInstance"|"memberOf", expression?: string}
  --placement-strategy: list # The task placement strategy objects to update the service to use. If no value is specified, the existing placement strategy for the service will remain unchanged. If this value is specified, it will override the existing placement strategy defined for the service. To remove an existing placement strategy, specify an empty object. You can specify a maximum of five strategy rules for each service. — item shape: {type?: "random"|"spread"|"binpack", field?: string}
  --platform-version: string # The platform version that your tasks in the service run on. A platform version is only specified for tasks using the Fargate launch type. If a platform version is not specified, the LATEST platform version is used. For more information, see Fargate Platform Versions (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html) in the Amazon Elastic Container Service Developer Guide.
  --force-new-deployment: oneof<nothing, bool> # Determines whether to force a new deployment of the service. By default, deployments aren't forced. You can use this option to start a new deployment with no service definition changes. For example, you can update a service's tasks to use a newer Docker image with the same image/tag combination (my_image:latest) or to roll Fargate tasks onto a newer platform version.
  --health-check-grace-period-seconds: int # The period of time, in seconds, that the Amazon ECS service scheduler ignores unhealthy Elastic Load Balancing target health checks after a task has first started. This is only valid if your service is configured to use a load balancer. If your service's tasks take a while to start and respond to Elastic Load Balancing health checks, you can specify a health check grace period of up to 2,147,483,647 seconds. During that time, the Amazon ECS service scheduler ignores the Elastic Load Balancing health check status. This grace period can prevent the ECS service scheduler from marking tasks as unhealthy and stopping them before they have time to come up.
  --enable-execute-command: oneof<nothing, bool> # If true, this enables execute command functionality on all task containers. If you do not want to override the value that was set when the service was created, you can set this to null when performing this action.
  --enable-ecs-managed-tags: oneof<nothing, bool> # Determines whether to turn on Amazon ECS managed tags for the tasks in the service. For more information, see Tagging Your Amazon ECS Resources (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-using-tags.html) in the Amazon Elastic Container Service Developer Guide. Only tasks launched after the update will reflect the update. To update the tags on all tasks, set forceNewDeployment to true, so that Amazon ECS starts new tasks with the updated tags.
  --load-balancers: list # A list of Elastic Load Balancing load balancer objects. It contains the load balancer name, the container name, and the container port to access from the load balancer. The container name is as it appears in a container definition. When you add, update, or remove a load balancer configuration, Amazon ECS starts new tasks with the updated Elastic Load Balancing configuration, and then stops the old tasks when the new tasks are running. For services that use rolling updates, you can add, update, or remove Elastic Load Balancing target groups. You can update from a single target group to multiple target groups and from multiple target groups to a single target group. For services that use blue/green deployments, you can update Elastic Load Balancing target groups by using CreateDeployment (https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html) through CodeDeploy. Note that multiple target groups are not supported for blue/green deployments. For more information see Register multiple target groups with a service (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/register-multiple-targetgroups.html) in the Amazon Elastic Container Service Developer Guide. For services that use the external deployment controller, you can add, update, or remove load balancers by using CreateTaskSet (https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CreateTaskSet.html). Note that multiple target groups are not supported for external deployments. For more information see Register multiple target groups with a service (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/register-multiple-targetgroups.html) in the Amazon Elastic Container Service Developer Guide. You can remove existing loadBalancers by passing an empty list. — item shape: {targetGroupArn?: string, loadBalancerName?: string, containerName?: string, containerPort?: int}
  --propagate-tags: string@propagate-tags-completer # Determines whether to propagate the tags from the task definition or the service to the task. If no value is specified, the tags aren't propagated. Only tasks launched after the update will reflect the update. To update the tags on all tasks, set forceNewDeployment to true, so that Amazon ECS starts new tasks with the updated tags.
  --service-registries: list # The details for the service discovery registries to assign to this service. For more information, see Service Discovery (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html). When you add, update, or remove the service registries configuration, Amazon ECS starts new tasks with the updated service registries configuration, and then stops the old tasks when the new tasks are running. You can remove existing serviceRegistries by passing an empty list. — item shape: {registryArn?: string, port?: int, containerName?: string, containerPort?: int}
  --service-connect-configuration: record # The Service Connect configuration of your Amazon ECS service. The configuration for this service to discover and connect to services, and be discovered by, and connected from, other services within a namespace. Tasks that run in a namespace can use short names to connect to services in the namespace. Tasks can connect to services across all of the clusters in the namespace. Tasks connect through a managed proxy container that collects logs and metrics for increased visibility. Only the tasks that Amazon ECS services create are supported with Service Connect. For more information, see Service Connect (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html) in the Amazon Elastic Container Service Developer Guide. — shape: {enabled: bool, namespace?: string, services?: list, logConfiguration?: record}
]: any -> oneof<record<service: record<serviceArn: string, serviceName: string, clusterArn: string, loadBalancers: list<record>, serviceRegistries: list<record>, status: string, desiredCount: int, runningCount: int, pendingCount: int, launchType: string, capacityProviderStrategy: list<record>, platformVersion: string, platformFamily: string, taskDefinition: string, deploymentConfiguration: record<deploymentCircuitBreaker: record, maximumPercent: int, minimumHealthyPercent: int, alarms: record>, taskSets: list<record>, deployments: list<record>, roleArn: string, events: list<record>, createdAt: string, placementConstraints: list<record>, placementStrategy: list<record>, networkConfiguration: record<awsvpcConfiguration: record>, healthCheckGracePeriodSeconds: int, schedulingStrategy: string, deploymentController: record<type: string>, tags: list<record>, createdBy: string, enableECSManagedTags: bool, propagateTags: string, enableExecuteCommand: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateService")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "service": $service, "desiredCount": $desired_count, "taskDefinition": $task_definition, "capacityProviderStrategy": $capacity_provider_strategy, "deploymentConfiguration": $deployment_configuration, "networkConfiguration": $network_configuration, "placementConstraints": $placement_constraints, "placementStrategy": $placement_strategy, "platformVersion": $platform_version, "forceNewDeployment": $force_new_deployment, "healthCheckGracePeriodSeconds": $health_check_grace_period_seconds, "enableExecuteCommand": $enable_execute_command, "enableECSManagedTags": $enable_ecs_managed_tags, "loadBalancers": $load_balancers, "propagateTags": $propagate_tags, "serviceRegistries": $service_registries, "serviceConnectConfiguration": $service_connect_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the EXTERNAL deployment controller type. For more information, see Amazon ECS Deployment Types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: UpdateServicePrimaryTaskSet
export def "update-service-primary-task-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53 # required
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the service that the task set exists in.
  service: string # The short name or full Amazon Resource Name (ARN) of the service that the task set exists in.
  primary_task_set: string # The short name or full Amazon Resource Name (ARN) of the task set to set as the primary task set in the deployment.
]: any -> oneof<record<taskSet: record<id: string, taskSetArn: string, serviceArn: string, clusterArn: string, startedBy: string, externalId: string, status: string, taskDefinition: string, computedDesiredCount: int, pendingCount: int, runningCount: int, createdAt: string, updatedAt: string, launchType: string, capacityProviderStrategy: list<record>, platformVersion: string, platformFamily: string, networkConfiguration: record<awsvpcConfiguration: record>, loadBalancers: list<record>, serviceRegistries: list<record>, scale: record<value: float, unit: string>, stabilityStatus: string, stabilityStatusAt: string, tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "service": $service, "primaryTaskSet": $primary_task_set} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the protection status of a task. You can set protectionEnabled to true to protect your task from termination during scale-in events from Service Autoscaling (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html) or deployments (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html). Task-protection, by default, expires after 2 hours at which point Amazon ECS clears the protectionEnabled property making the task eligible for termination by a subsequent scale-in event. You can specify a custom expiration period for task protection from 1 minute to up to 2,880 minutes (48 hours). To specify the custom expiration period, set the expiresInMinutes property. The expiresInMinutes property is always reset when you invoke this operation for a task that already has protectionEnabled set to true. You can keep extending the protection expiration period of a task by invoking this operation repeatedly. To learn more about Amazon ECS task protection, see Task scale-in protection (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-scale-in-protection.html) in the Amazon Elastic Container Service Developer Guide . This operation is only supported for tasks belonging to an Amazon ECS service. Invoking this operation for a standalone task will result in an TASK_NOT_VALID failure. For more information, see API failure reasons (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/api_failures_messages.html). If you prefer to set task protection from within the container, we recommend using the Task scale-in protection endpoint (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-scale-in-protection-endpoint.html).
#
# POST /
# operationId: UpdateTaskProtection
export def "update-task-protection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54 # required
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the service that the task sets exist in.
  tasks: list<string> # A list of up to 10 task IDs or full ARN entries.
  --protection-enabled: oneof<nothing, bool> # Specify true to mark a task for protection and false to unset protection, making it eligible for termination.
  --expires-in-minutes: int # If you set protectionEnabled to true, you can specify the duration for task protection in minutes. You can specify a value from 1 minute to up to 2,880 minutes (48 hours). During this time, your task will not be terminated by scale-in events from Service Auto Scaling or deployments. After this time period lapses, protectionEnabled will be reset to false. If you don’t specify the time, then the task is automatically protected for 120 minutes (2 hours).
]: any -> oneof<record<protectedTasks: table<taskArn: string, protectionEnabled: bool, expirationDate: string>, failures: table<arn: string, reason: string, detail: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateTaskProtection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "tasks": $tasks, "protectionEnabled": $protection_enabled, "expiresInMinutes": $expires_in_minutes} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "protectionEnabled") == null) { error make --unspanned { msg: "required body field 'protectionEnabled' missing: pass --protection-enabled or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies a task set. This is used when a service uses the EXTERNAL deployment controller type. For more information, see Amazon ECS Deployment Types (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html) in the Amazon Elastic Container Service Developer Guide.
#
# POST /
# operationId: UpdateTaskSet
export def "update-task-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55 # required
  cluster: string # The short name or full Amazon Resource Name (ARN) of the cluster that hosts the service that the task set is found in.
  service: string # The short name or full Amazon Resource Name (ARN) of the service that the task set is found in.
  task_set: string # The short name or full Amazon Resource Name (ARN) of the task set to update.
  scale: record # A floating-point percentage of the desired number of tasks to place and keep running in the task set. — shape: {value?: float, unit?: "PERCENT"}
]: any -> oneof<record<taskSet: record<id: string, taskSetArn: string, serviceArn: string, clusterArn: string, startedBy: string, externalId: string, status: string, taskDefinition: string, computedDesiredCount: int, pendingCount: int, runningCount: int, createdAt: string, updatedAt: string, launchType: string, capacityProviderStrategy: list<record>, platformVersion: string, platformFamily: string, networkConfiguration: record<awsvpcConfiguration: record>, loadBalancers: list<record>, serviceRegistries: list<record>, scale: record<value: float, unit: string>, stabilityStatus: string, stabilityStatusAt: string, tags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonEC2ContainerServiceV20141113.UpdateTaskSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"cluster": $cluster, "service": $service, "taskSet": $task_set, "scale": $scale} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
