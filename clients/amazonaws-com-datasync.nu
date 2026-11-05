# Auto-generated client for AWS DataSync v2018-11-09
# Source: https://api.apis.guru/v2/specs/amazonaws.com/datasync/2018-11-09/openapi.json
# Auth: --token flag or $env.AWS_DATASYNC_TOKEN

const BASE_URL = "http://datasync.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_DATASYNC_TOKEN | default "" }
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
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://datasync.us-east-1.amazonaws.com" "http://datasync.us-east-2.amazonaws.com" "http://datasync.us-west-1.amazonaws.com" "http://datasync.us-west-2.amazonaws.com" "http://datasync.us-gov-west-1.amazonaws.com" "http://datasync.us-gov-east-1.amazonaws.com" "http://datasync.ca-central-1.amazonaws.com" "http://datasync.eu-north-1.amazonaws.com" "http://datasync.eu-west-1.amazonaws.com" "http://datasync.eu-west-2.amazonaws.com" "http://datasync.eu-west-3.amazonaws.com" "http://datasync.eu-central-1.amazonaws.com" "http://datasync.eu-south-1.amazonaws.com" "http://datasync.af-south-1.amazonaws.com" "http://datasync.ap-northeast-1.amazonaws.com" "http://datasync.ap-northeast-2.amazonaws.com" "http://datasync.ap-northeast-3.amazonaws.com" "http://datasync.ap-southeast-1.amazonaws.com" "http://datasync.ap-southeast-2.amazonaws.com" "http://datasync.ap-east-1.amazonaws.com" "http://datasync.ap-south-1.amazonaws.com" "http://datasync.sa-east-1.amazonaws.com" "http://datasync.me-south-1.amazonaws.com" "https://datasync.us-east-1.amazonaws.com" "https://datasync.us-east-2.amazonaws.com" "https://datasync.us-west-1.amazonaws.com" "https://datasync.us-west-2.amazonaws.com" "https://datasync.us-gov-west-1.amazonaws.com" "https://datasync.us-gov-east-1.amazonaws.com" "https://datasync.ca-central-1.amazonaws.com" "https://datasync.eu-north-1.amazonaws.com" "https://datasync.eu-west-1.amazonaws.com" "https://datasync.eu-west-2.amazonaws.com" "https://datasync.eu-west-3.amazonaws.com" "https://datasync.eu-central-1.amazonaws.com" "https://datasync.eu-south-1.amazonaws.com" "https://datasync.af-south-1.amazonaws.com" "https://datasync.ap-northeast-1.amazonaws.com" "https://datasync.ap-northeast-2.amazonaws.com" "https://datasync.ap-northeast-3.amazonaws.com" "https://datasync.ap-southeast-1.amazonaws.com" "https://datasync.ap-southeast-2.amazonaws.com" "https://datasync.ap-east-1.amazonaws.com" "https://datasync.ap-south-1.amazonaws.com" "https://datasync.sa-east-1.amazonaws.com" "https://datasync.me-south-1.amazonaws.com" "http://datasync.cn-north-1.amazonaws.com.cn" "http://datasync.cn-northwest-1.amazonaws.com.cn" "https://datasync.cn-north-1.amazonaws.com.cn" "https://datasync.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["FmrsService.CancelTaskExecution"] }
def x-amz-target-completer-1 [] { ["FmrsService.CreateAgent"] }
def in-transit-encryption-completer [] { ["NONE" "TLS1_2"] }
def x-amz-target-completer-2 [] { ["FmrsService.CreateLocationEfs"] }
def x-amz-target-completer-3 [] { ["FmrsService.CreateLocationFsxLustre"] }
def x-amz-target-completer-4 [] { ["FmrsService.CreateLocationFsxOntap"] }
def x-amz-target-completer-5 [] { ["FmrsService.CreateLocationFsxOpenZfs"] }
def x-amz-target-completer-6 [] { ["FmrsService.CreateLocationFsxWindows"] }
def authentication-type-completer [] { ["KERBEROS" "SIMPLE"] }
def x-amz-target-completer-7 [] { ["FmrsService.CreateLocationHdfs"] }
def x-amz-target-completer-8 [] { ["FmrsService.CreateLocationNfs"] }
def server-protocol-completer [] { ["HTTP" "HTTPS"] }
def x-amz-target-completer-9 [] { ["FmrsService.CreateLocationObjectStorage"] }
def s3-storage-class-completer [] { ["DEEP_ARCHIVE" "GLACIER" "GLACIER_INSTANT_RETRIEVAL" "INTELLIGENT_TIERING" "ONEZONE_IA" "OUTPOSTS" "STANDARD" "STANDARD_IA"] }
def x-amz-target-completer-10 [] { ["FmrsService.CreateLocationS3"] }
def x-amz-target-completer-11 [] { ["FmrsService.CreateLocationSmb"] }
def x-amz-target-completer-12 [] { ["FmrsService.CreateTask"] }
def x-amz-target-completer-13 [] { ["FmrsService.DeleteAgent"] }
def x-amz-target-completer-14 [] { ["FmrsService.DeleteLocation"] }
def x-amz-target-completer-15 [] { ["FmrsService.DeleteTask"] }
def x-amz-target-completer-16 [] { ["FmrsService.DescribeAgent"] }
def x-amz-target-completer-17 [] { ["FmrsService.DescribeLocationEfs"] }
def x-amz-target-completer-18 [] { ["FmrsService.DescribeLocationFsxLustre"] }
def x-amz-target-completer-19 [] { ["FmrsService.DescribeLocationFsxOntap"] }
def x-amz-target-completer-20 [] { ["FmrsService.DescribeLocationFsxOpenZfs"] }
def x-amz-target-completer-21 [] { ["FmrsService.DescribeLocationFsxWindows"] }
def x-amz-target-completer-22 [] { ["FmrsService.DescribeLocationHdfs"] }
def x-amz-target-completer-23 [] { ["FmrsService.DescribeLocationNfs"] }
def x-amz-target-completer-24 [] { ["FmrsService.DescribeLocationObjectStorage"] }
def x-amz-target-completer-25 [] { ["FmrsService.DescribeLocationS3"] }
def x-amz-target-completer-26 [] { ["FmrsService.DescribeLocationSmb"] }
def x-amz-target-completer-27 [] { ["FmrsService.DescribeTask"] }
def x-amz-target-completer-28 [] { ["FmrsService.DescribeTaskExecution"] }
def x-amz-target-completer-29 [] { ["FmrsService.ListAgents"] }
def x-amz-target-completer-30 [] { ["FmrsService.ListLocations"] }
def x-amz-target-completer-31 [] { ["FmrsService.ListTagsForResource"] }
def x-amz-target-completer-32 [] { ["FmrsService.ListTaskExecutions"] }
def x-amz-target-completer-33 [] { ["FmrsService.ListTasks"] }
def x-amz-target-completer-34 [] { ["FmrsService.StartTaskExecution"] }
def x-amz-target-completer-35 [] { ["FmrsService.TagResource"] }
def x-amz-target-completer-36 [] { ["FmrsService.UntagResource"] }
def x-amz-target-completer-37 [] { ["FmrsService.UpdateAgent"] }
def x-amz-target-completer-38 [] { ["FmrsService.UpdateLocationHdfs"] }
def x-amz-target-completer-39 [] { ["FmrsService.UpdateLocationNfs"] }
def x-amz-target-completer-40 [] { ["FmrsService.UpdateLocationObjectStorage"] }
def x-amz-target-completer-41 [] { ["FmrsService.UpdateLocationSmb"] }
def x-amz-target-completer-42 [] { ["FmrsService.UpdateTask"] }
def x-amz-target-completer-43 [] { ["FmrsService.UpdateTaskExecution"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-task-execution" "create-agent" "create-location-efs" "create-location-fsx-lustre" "create-location-fsx-ontap" "create-location-fsx-open-zfs" "create-location-fsx-windows" "create-location-hdfs" "create-location-nfs" "create-location-object-storage" "create-location-s3" "create-location-smb" "create-task" "delete-agent" "delete-location" "delete-task" "describe-agent" "describe-location-efs" "describe-location-fsx-lustre" "describe-location-fsx-ontap" "describe-location-fsx-open-zfs" "describe-location-fsx-windows" "describe-location-hdfs" "describe-location-nfs" "describe-location-object-storage" "describe-location-s3" "describe-location-smb" "describe-task" "describe-task-execution" "list-agents" "list-locations" "list-tags-for-resource" "list-task-executions" "list-tasks" "start-task-execution" "tag-resource" "untag-resource" "update-agent" "update-location-hdfs" "update-location-nfs" "update-location-object-storage" "update-location-smb" "update-task" "update-task-execution" "commands"] | sort) } | get name | first)
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

# Stops an DataSync task execution that's in progress. The transfer of some files are abruptly interrupted. File contents that're transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution using the same task and allow it to finish, file content on the destination will be complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, DataSync successfully completes the transfer when you start the next task execution.
#
# POST /
# operationId: CancelTaskExecution
export def "cancel-task-execution" [
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
  task_execution_arn: string # The Amazon Resource Name (ARN) of the task execution to stop.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CancelTaskExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TaskExecutionArn": $task_execution_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Activates an DataSync agent that you have deployed in your storage environment. The activation process associates your agent with your account. In the activation process, you specify information such as the Amazon Web Services Region that you want to activate the agent in. You activate the agent in the Amazon Web Services Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this Amazon Web Services Region. You can activate the agent in a VPC (virtual private cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public internet. You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. Agents are automatically updated by Amazon Web Services on a regular basis, using a mechanism that ensures minimal interruption to your tasks.
#
# POST /
# operationId: CreateAgent
export def "create-agent" [
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
  activation_key: string # Your agent activation key. You can get the activation key either by sending an HTTP GET request with redirects that enable you to get the agent IP address (port 80). Alternatively, you can get it from the DataSync console. The redirect URL returned in the response provides you the activation key for your agent in the query string parameter activationKey. It might also include other activation-related parameters; however, these are merely defaults. The arguments you pass to this API call determine the actual configuration of your agent. For more information, see Activating an Agent in the DataSync User Guide.
  --agent-name: string # The name you configured for your agent. This value is a text reference that is used to identify the agent in the console.
  --tags: list # The key-value pair that represents the tag that you want to associate with the agent. The value can be an empty string. This value helps you manage, filter, and search for your agents. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. — item shape: {Key: string, Value?: string}
  --vpc-endpoint-id: string # The ID of the VPC (virtual private cloud) endpoint that the agent has access to. This is the client-side VPC endpoint, also called a PrivateLink. If you don't have a PrivateLink VPC endpoint, see Creating a VPC Endpoint Service Configuration (https://docs.aws.amazon.com/vpc/latest/userguide/endpoint-service.html#create-endpoint-service) in the Amazon VPC User Guide. VPC endpoint ID looks like this: vpce-01234d5aff67890e1.
  --subnet-arns: list<string> # The Amazon Resource Names (ARNs) of the subnets in which DataSync will create elastic network interfaces for each data transfer task. The agent that runs a task must be private. When you start a task that is associated with an agent created in a VPC, or one that has access to an IP address in a VPC, then the task is also private. In this case, DataSync creates four network interfaces for each task in your subnet. For a data transfer to work, the agent must be able to route to all these four network interfaces.
  --security-group-arns: list<string> # The ARNs of the security groups used to protect your data transfer task subnets. See SecurityGroupArns (https://docs.aws.amazon.com/datasync/latest/userguide/API_Ec2Config.html#DataSync-Type-Ec2Config-SecurityGroupArns).
]: any -> oneof<record<AgentArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateAgent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ActivationKey": $activation_key, "AgentName": $agent_name, "Tags": $tags, "VpcEndpointId": $vpc_endpoint_id, "SubnetArns": $subnet_arns, "SecurityGroupArns": $security_group_arns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for an Amazon EFS file system that DataSync can access for a transfer. For more information, see Creating a location for Amazon EFS (https://docs.aws.amazon.com/datasync/latest/userguide/create-efs-location.html).
#
# POST /
# operationId: CreateLocationEfs
export def "create-location-efs" [
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
  --subdirectory: string # Specifies a mount path for your Amazon EFS file system. This is where DataSync reads or writes data (depending on if this is a source or destination location). By default, DataSync uses the root directory, but you can also include subdirectories. You must specify a value with forward slashes (for example, /path/to/folder).
  efs_filesystem_arn: string # Specifies the ARN for the Amazon EFS file system.
  ec2_config: record # The subnet and security groups that DataSync uses to access your Amazon EFS file system. — shape: {SubnetArn: string, SecurityGroupArns: list<string>}
  --tags: list # Specifies the key-value pair that represents a tag that you want to add to the resource. The value can be an empty string. This value helps you manage, filter, and search for your resources. We recommend that you create a name tag for your location. — item shape: {Key: string, Value?: string}
  --access-point-arn: string # Specifies the Amazon Resource Name (ARN) of the access point that DataSync uses to access the Amazon EFS file system.
  --file-system-access-role-arn: string # Specifies an Identity and Access Management (IAM) role that DataSync assumes when mounting the Amazon EFS file system.
  --in-transit-encryption: string@in-transit-encryption-completer # Specifies whether you want DataSync to use Transport Layer Security (TLS) 1.2 encryption when it copies data to or from the Amazon EFS file system. If you specify an access point using AccessPointArn or an IAM role using FileSystemAccessRoleArn, you must set this parameter to TLS1_2.
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationEfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Subdirectory": $subdirectory, "EfsFilesystemArn": $efs_filesystem_arn, "Ec2Config": $ec2_config, "Tags": $tags, "AccessPointArn": $access_point_arn, "FileSystemAccessRoleArn": $file_system_access_role_arn, "InTransitEncryption": $in_transit_encryption} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for an Amazon FSx for Lustre file system.
#
# POST /
# operationId: CreateLocationFsxLustre
export def "create-location-fsx-lustre" [
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
  fsx_filesystem_arn: string # The Amazon Resource Name (ARN) for the FSx for Lustre file system.
  security_group_arns: list<string> # The Amazon Resource Names (ARNs) of the security groups that are used to configure the FSx for Lustre file system.
  --subdirectory: string # A subdirectory in the location's path. This subdirectory in the FSx for Lustre file system is used to read data from the FSx for Lustre source location or write data to the FSx for Lustre destination.
  --tags: list # The key-value pair that represents a tag that you want to add to the resource. The value can be an empty string. This value helps you manage, filter, and search for your resources. We recommend that you create a name tag for your location. — item shape: {Key: string, Value?: string}
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationFsxLustre")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FsxFilesystemArn": $fsx_filesystem_arn, "SecurityGroupArns": $security_group_arns, "Subdirectory": $subdirectory, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for an Amazon FSx for NetApp ONTAP file system that DataSync can access for a transfer. For more information, see Creating a location for FSx for ONTAP (https://docs.aws.amazon.com/datasync/latest/userguide/create-ontap-location.html).
#
# POST /
# operationId: CreateLocationFsxOntap
export def "create-location-fsx-ontap" [
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
  protocol: record # Specifies the data transfer protocol that DataSync uses to access your Amazon FSx file system. — shape: {NFS?: record, SMB?: record}
  security_group_arns: list<string> # Specifies the Amazon EC2 security groups that provide access to your file system's preferred subnet. The security groups must allow outbound traffic on the following ports (depending on the protocol you use): Network File System (NFS): TCP ports 111, 635, and 2049 Server Message Block (SMB): TCP port 445 Your file system's security groups must also allow inbound traffic on the same ports.
  storage_virtual_machine_arn: string # Specifies the ARN of the storage virtual machine (SVM) in your file system where you want to copy data to or from.
  --subdirectory: string # Specifies a path to the file share in the SVM where you'll copy your data. You can specify a junction path (also known as a mount point), qtree path (for NFS file shares), or share name (for SMB file shares). For example, your mount path might be /vol1, /vol1/tree1, or /share1. Don't specify a junction path in the SVM's root volume. For more information, see Managing FSx for ONTAP storage virtual machines (https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/managing-svms.html) in the Amazon FSx for NetApp ONTAP User Guide.
  --tags: list # Specifies labels that help you categorize, filter, and search for your Amazon Web Services resources. We recommend creating at least a name tag for your location. — item shape: {Key: string, Value?: string}
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationFsxOntap")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Protocol": $protocol, "SecurityGroupArns": $security_group_arns, "StorageVirtualMachineArn": $storage_virtual_machine_arn, "Subdirectory": $subdirectory, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for an Amazon FSx for OpenZFS file system that DataSync can access for a transfer. For more information, see Creating a location for FSx for OpenZFS (https://docs.aws.amazon.com/datasync/latest/userguide/create-openzfs-location.html). Request parameters related to SMB aren't supported with the CreateLocationFsxOpenZfs operation.
#
# POST /
# operationId: CreateLocationFsxOpenZfs
export def "create-location-fsx-open-zfs" [
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
  fsx_filesystem_arn: string # The Amazon Resource Name (ARN) of the FSx for OpenZFS file system.
  protocol: record # Specifies the data transfer protocol that DataSync uses to access your Amazon FSx file system. — shape: {NFS?: record, SMB?: record}
  security_group_arns: list<string> # The ARNs of the security groups that are used to configure the FSx for OpenZFS file system.
  --subdirectory: string # A subdirectory in the location's path that must begin with /fsx. DataSync uses this subdirectory to read or write data (depending on whether the file system is a source or destination location).
  --tags: list # The key-value pair that represents a tag that you want to add to the resource. The value can be an empty string. This value helps you manage, filter, and search for your resources. We recommend that you create a name tag for your location. — item shape: {Key: string, Value?: string}
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationFsxOpenZfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FsxFilesystemArn": $fsx_filesystem_arn, "Protocol": $protocol, "SecurityGroupArns": $security_group_arns, "Subdirectory": $subdirectory, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for an Amazon FSx for Windows File Server file system.
#
# POST /
# operationId: CreateLocationFsxWindows
export def "create-location-fsx-windows" [
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
  --subdirectory: string # Specifies a mount path for your file system using forward slashes. This is where DataSync reads or writes data (depending on if this is a source or destination location).
  fsx_filesystem_arn: string # Specifies the Amazon Resource Name (ARN) for the FSx for Windows File Server file system.
  security_group_arns: list<string> # Specifies the ARNs of the security groups that provide access to your file system's preferred subnet. If you choose a security group that doesn't allow connections from within itself, do one of the following: Configure the security group to allow it to communicate within itself. Choose a different security group that can communicate with the mount target's security group.
  --tags: list # Specifies labels that help you categorize, filter, and search for your Amazon Web Services resources. We recommend creating at least a name tag for your location. — item shape: {Key: string, Value?: string}
  user: string # Specifies the user who has the permissions to access files and folders in the file system. For information about choosing a user name that ensures sufficient permissions to files, folders, and metadata, see user (create-fsx-location.html#FSxWuser).
  --domain: string # Specifies the name of the Windows domain that the FSx for Windows File Server belongs to.
  password: string # Specifies the password of the user who has the permissions to access files and folders in the file system. (format: password)
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationFsxWindows")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Subdirectory": $subdirectory, "FsxFilesystemArn": $fsx_filesystem_arn, "SecurityGroupArns": $security_group_arns, "Tags": $tags, "User": $user, "Domain": $domain, "Password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for a Hadoop Distributed File System (HDFS).
#
# POST /
# operationId: CreateLocationHdfs
export def "create-location-hdfs" [
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
  --subdirectory: string # A subdirectory in the HDFS cluster. This subdirectory is used to read data from or write data to the HDFS cluster. If the subdirectory isn't specified, it will default to /.
  name_nodes: list # The NameNode that manages the HDFS namespace. The NameNode performs operations such as opening, closing, and renaming files and directories. The NameNode contains the information to map blocks of data to the DataNodes. You can use only one NameNode. — item shape: {Hostname: string, Port: int}
  --block-size: int # The size of data blocks to write into the HDFS cluster. The block size must be a multiple of 512 bytes. The default block size is 128 mebibytes (MiB).
  --replication-factor: int # The number of DataNodes to replicate the data to when writing to the HDFS cluster. By default, data is replicated to three DataNodes.
  --kms-key-provider-uri: string # The URI of the HDFS cluster's Key Management Server (KMS).
  --qop-configuration: record # The Quality of Protection (QOP) configuration specifies the Remote Procedure Call (RPC) and data transfer privacy settings configured on the Hadoop Distributed File System (HDFS) cluster. — shape: {RpcProtection?: "DISABLED"|"AUTHENTICATION"|"INTEGRITY"|"PRIVACY", DataTransferProtection?: "DISABLED"|"AUTHENTICATION"|"INTEGRITY"|"PRIVACY"}
  authentication_type: string@authentication-type-completer # The type of authentication used to determine the identity of the user.
  --simple-user: string # The user name used to identify the client on the host operating system. If SIMPLE is specified for AuthenticationType, this parameter is required.
  --kerberos-principal: string # The Kerberos principal with access to the files and folders on the HDFS cluster. If KERBEROS is specified for AuthenticationType, this parameter is required.
  --kerberos-keytab: string # The Kerberos key table (keytab) that contains mappings between the defined Kerberos principal and the encrypted keys. You can load the keytab from a file by providing the file's address. If you're using the CLI, it performs base64 encoding for you. Otherwise, provide the base64-encoded text. If KERBEROS is specified for AuthenticationType, this parameter is required.
  --kerberos-krb5-conf: string # The krb5.conf file that contains the Kerberos configuration information. You can load the krb5.conf file by providing the file's address. If you're using the CLI, it performs the base64 encoding for you. Otherwise, provide the base64-encoded text. If KERBEROS is specified for AuthenticationType, this parameter is required.
  agent_arns: list<string> # The Amazon Resource Names (ARNs) of the agents that are used to connect to the HDFS cluster.
  --tags: list # The key-value pair that represents the tag that you want to add to the location. The value can be an empty string. We recommend using tags to name your resources. — item shape: {Key: string, Value?: string}
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationHdfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Subdirectory": $subdirectory, "NameNodes": $name_nodes, "BlockSize": $block_size, "ReplicationFactor": $replication_factor, "KmsKeyProviderUri": $kms_key_provider_uri, "QopConfiguration": $qop_configuration, "AuthenticationType": $authentication_type, "SimpleUser": $simple_user, "KerberosPrincipal": $kerberos_principal, "KerberosKeytab": $kerberos_keytab, "KerberosKrb5Conf": $kerberos_krb5_conf, "AgentArns": $agent_arns, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Defines a file system on a Network File System (NFS) server that can be read from or written to.
#
# POST /
# operationId: CreateLocationNfs
export def "create-location-nfs" [
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
  subdirectory: string # The subdirectory in the NFS file system that is used to read data from the NFS source location or write data to the NFS destination. The NFS path should be a path that's exported by the NFS server, or a subdirectory of that path. The path should be such that it can be mounted by other NFS clients in your network. To see all the paths exported by your NFS server, run "showmount -e nfs-server-name" from an NFS client that has access to your server. You can specify any directory that appears in the results, and any subdirectory of that directory. Ensure that the NFS export is accessible without Kerberos authentication. To transfer all the data in the folder you specified, DataSync needs to have permissions to read all the data. To ensure this, either configure the NFS export with no_root_squash, or ensure that the permissions for all of the files that you want DataSync allow read access for all users. Doing either enables the agent to read the files. For the agent to access directories, you must additionally enable all execute access. If you are copying data to or from your Snowcone device, see NFS Server on Snowcone (https://docs.aws.amazon.com/datasync/latest/userguide/create-nfs-location.html#nfs-on-snowcone) for more information. For information about NFS export configuration, see 18.7. The /etc/exports Configuration File in the Red Hat Enterprise Linux documentation.
  server_hostname: string # The name of the NFS server. This value is the IP address or Domain Name Service (DNS) name of the NFS server. An agent that is installed on-premises uses this hostname to mount the NFS server in a network. If you are copying data to or from your Snowcone device, see NFS Server on Snowcone (https://docs.aws.amazon.com/datasync/latest/userguide/create-nfs-location.html#nfs-on-snowcone) for more information. This name must either be DNS-compliant or must be an IP version 4 (IPv4) address.
  on_prem_config: record # A list of Amazon Resource Names (ARNs) of agents to use for a Network File System (NFS) location. — shape: {AgentArns: list<string>}
  --mount-options: record # Specifies how DataSync can access a location using the NFS protocol. — shape: {Version?: "AUTOMATIC"|"NFS3"|"NFS4_0"|"NFS4_1"}
  --tags: list # The key-value pair that represents the tag that you want to add to the location. The value can be an empty string. We recommend using tags to name your resources. — item shape: {Key: string, Value?: string}
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationNfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Subdirectory": $subdirectory, "ServerHostname": $server_hostname, "OnPremConfig": $on_prem_config, "MountOptions": $mount_options, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for an object storage system that DataSync can access for a transfer. For more information, see Creating a location for object storage (https://docs.aws.amazon.com/datasync/latest/userguide/create-object-location.html).
#
# POST /
# operationId: CreateLocationObjectStorage
export def "create-location-object-storage" [
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
  server_hostname: string # Specifies the domain name or IP address of the object storage server. A DataSync agent uses this hostname to mount the object storage server in a network.
  --server-port: int # Specifies the port that your object storage server accepts inbound network traffic on (for example, port 443).
  --server-protocol: string@server-protocol-completer # Specifies the protocol that your object storage server uses to communicate.
  --subdirectory: string # Specifies the object prefix for your object storage server. If this is a source location, DataSync only copies objects with this prefix. If this is a destination location, DataSync writes all objects with this prefix.
  bucket_name: string # Specifies the name of the object storage bucket involved in the transfer.
  --access-key: string # Specifies the access key (for example, a user name) if credentials are required to authenticate with the object storage server.
  --secret-key: string # Specifies the secret key (for example, a password) if credentials are required to authenticate with the object storage server. (format: password)
  agent_arns: list<string> # Specifies the Amazon Resource Names (ARNs) of the DataSync agents that can securely connect with your location.
  --tags: list # Specifies the key-value pair that represents a tag that you want to add to the resource. Tags can help you manage, filter, and search for your resources. We recommend creating a name tag for your location. — item shape: {Key: string, Value?: string}
  --server-certificate: string # Specifies a certificate to authenticate with an object storage system that uses a private or self-signed certificate authority (CA). You must specify a Base64-encoded .pem file (for example, file:///home/user/.ssh/storage_sys_certificate.pem). The certificate can be up to 32768 bytes (before Base64 encoding). To use this parameter, configure ServerProtocol to HTTPS.
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationObjectStorage")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServerHostname": $server_hostname, "ServerPort": $server_port, "ServerProtocol": $server_protocol, "Subdirectory": $subdirectory, "BucketName": $bucket_name, "AccessKey": $access_key, "SecretKey": $secret_key, "AgentArns": $agent_arns, "Tags": $tags, "ServerCertificate": $server_certificate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for an Amazon S3 bucket that DataSync can access for a transfer. For more information, see Create an Amazon S3 location (https://docs.aws.amazon.com/datasync/latest/userguide/create-locations-cli.html#create-location-s3-cli).
#
# POST /
# operationId: CreateLocationS3
export def "create-location-s3" [
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
  --subdirectory: string # A subdirectory in the Amazon S3 bucket. This subdirectory in Amazon S3 is used to read data from the S3 source location or write data to the S3 destination.
  s3_bucket_arn: string # The ARN of the Amazon S3 bucket. If the bucket is on an Amazon Web Services Outpost, this must be an access point ARN.
  --s3-storage-class: string@s3-storage-class-completer # The Amazon S3 storage class that you want to store your files in when this location is used as a task destination. For buckets in Amazon Web Services Regions, the storage class defaults to Standard. For buckets on Outposts, the storage class defaults to Amazon Web Services S3 Outposts. For more information about S3 storage classes, see Amazon S3 Storage Classes (http://aws.amazon.com/s3/storage-classes/). Some storage classes have behaviors that can affect your S3 storage cost. For detailed information, see Considerations when working with S3 storage classes in DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/create-s3-location.html#using-storage-classes).
  s3_config: record # The Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role used to access an Amazon S3 bucket. For detailed information about using such a role, see Creating a Location for Amazon S3 in the DataSync User Guide. — shape: {BucketAccessRoleArn: string}
  --agent-arns: list<string> # If you're using DataSync on an Amazon Web Services Outpost, specify the Amazon Resource Names (ARNs) of the DataSync agents deployed on your Outpost. For more information about launching a DataSync agent on an Amazon Web Services Outpost, see Deploy your DataSync agent on Outposts (https://docs.aws.amazon.com/datasync/latest/userguide/deploy-agents.html#outposts-agent).
  --tags: list # The key-value pair that represents the tag that you want to add to the location. The value can be an empty string. We recommend using tags to name your resources. — item shape: {Key: string, Value?: string}
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationS3")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Subdirectory": $subdirectory, "S3BucketArn": $s3_bucket_arn, "S3StorageClass": $s3_storage_class, "S3Config": $s3_config, "AgentArns": $agent_arns, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an endpoint for a Server Message Block (SMB) file server that DataSync can access for a transfer. For more information, see Creating an SMB location (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html).
#
# POST /
# operationId: CreateLocationSmb
export def "create-location-smb" [
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
  subdirectory: string # Specifies the name of the share exported by your SMB file server where DataSync will read or write data. You can include a subdirectory in the share path (for example, /path/to/subdirectory). Make sure that other SMB clients in your network can also mount this path. To copy all data in the specified subdirectory, DataSync must be able to mount the SMB share and access all of its data. For more information, see required permissions (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html#configuring-smb-permissions) for SMB locations.
  server_hostname: string # Specifies the Domain Name Service (DNS) name or IP address of the SMB file server that your DataSync agent will mount. You can't specify an IP version 6 (IPv6) address.
  user: string # Specifies the user name that can mount your SMB file server and has permission to access the files and folders involved in your transfer. For information about choosing a user with the right level of access for your transfer, see required permissions (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html#configuring-smb-permissions) for SMB locations.
  --domain: string # Specifies the Windows domain name that your SMB file server belongs to. For more information, see required permissions (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html#configuring-smb-permissions) for SMB locations.
  password: string # Specifies the password of the user who can mount your SMB file server and has permission to access the files and folders involved in your transfer. For more information, see required permissions (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html#configuring-smb-permissions) for SMB locations. (format: password)
  agent_arns: list<string> # Specifies the DataSync agent (or agents) which you want to connect to your SMB file server. You specify an agent by using its Amazon Resource Name (ARN).
  --mount-options: record # Specifies the version of the Server Message Block (SMB) protocol that DataSync uses to access an SMB file server. — shape: {Version?: "AUTOMATIC"|"SMB2"|"SMB3"|"SMB1"|"SMB2_0"}
  --tags: list # Specifies labels that help you categorize, filter, and search for your Amazon Web Services resources. We recommend creating at least a name tag for your location. — item shape: {Key: string, Value?: string}
]: any -> oneof<record<LocationArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateLocationSmb")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Subdirectory": $subdirectory, "ServerHostname": $server_hostname, "User": $user, "Domain": $domain, "Password": $password, "AgentArns": $agent_arns, "MountOptions": $mount_options, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Configures a task, which defines where and how DataSync transfers your data. A task includes a source location, a destination location, and the preferences for how and when you want to transfer your data (such as bandwidth limits, scheduling, among other options).
#
# POST /
# operationId: CreateTask
export def "create-task" [
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
  source_location_arn: string # The Amazon Resource Name (ARN) of the source location for the task.
  destination_location_arn: string # The Amazon Resource Name (ARN) of an Amazon Web Services storage resource's location.
  --cloud-watch-log-group-arn: string # The Amazon Resource Name (ARN) of the Amazon CloudWatch log group that is used to monitor and log events in the task.
  --name: string # The name of a task. This value is a text reference that is used to identify the task in the console.
  --options: record # Configures your DataSync task settings. These options include how DataSync handles files, objects, and their associated metadata. You also can specify how DataSync verifies data integrity, set bandwidth limits for your task, among other options. Each task setting has a default value. Unless you need to, you don't have to configure any of these Options before starting your task. — shape: {VerifyMode?: "POINT_IN_TIME_CONSISTENT"|"ONLY_FILES_TRANSFERRED"|"NONE", OverwriteMode?: "ALWAYS"|"NEVER", Atime?: "NONE"|"BEST_EFFORT", Mtime?: "NONE"|"PRESERVE", Uid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", Gid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", PreserveDeletedFiles?: "PRESERVE"|"REMOVE", PreserveDevices?: "NONE"|"PRESERVE", PosixPermissions?: "NONE"|"PRESERVE", BytesPerSecond?: int, TaskQueueing?: "ENABLED"|"DISABLED", LogLevel?: "OFF"|"BASIC"|"TRANSFER", TransferMode?: "CHANGED"|"ALL", ... (2 more fields)}
  --excludes: list # Specifies a list of filter rules that exclude specific data during your transfer. For more information and examples, see Filtering data transferred by DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/filtering.html). — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
  --schedule: record # Specifies the schedule you want your task to use for repeated executions. For more information, see Schedule Expressions for Rules (https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html). — shape: {ScheduleExpression: string}
  --tags: list # Specifies the tags that you want to apply to the Amazon Resource Name (ARN) representing the task. Tags are key-value pairs that help you manage, filter, and search for your DataSync resources. — item shape: {Key: string, Value?: string}
  --includes: list # Specifies a list of filter rules that include specific data during your transfer. For more information and examples, see Filtering data transferred by DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/filtering.html). — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
]: any -> oneof<record<TaskArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.CreateTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SourceLocationArn": $source_location_arn, "DestinationLocationArn": $destination_location_arn, "CloudWatchLogGroupArn": $cloud_watch_log_group_arn, "Name": $name, "Options": $options, "Excludes": $excludes, "Schedule": $schedule, "Tags": $tags, "Includes": $includes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your Amazon Web Services account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
#
# POST /
# operationId: DeleteAgent
export def "delete-agent" [
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
  agent_arn: string # The Amazon Resource Name (ARN) of the agent to delete. Use the ListAgents operation to return a list of agents for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DeleteAgent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AgentArn": $agent_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes the configuration of a location used by DataSync.
#
# POST /
# operationId: DeleteLocation
export def "delete-location" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the location to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DeleteLocation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes an DataSync task.
#
# POST /
# operationId: DeleteTask
export def "delete-task" [
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
  task_arn: string # Specifies the Amazon Resource Name (ARN) of the task that you want to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DeleteTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TaskArn": $task_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata about an DataSync agent, such as its name, endpoint type, and status.
#
# POST /
# operationId: DescribeAgent
export def "describe-agent" [
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
  agent_arn: string # Specifies the Amazon Resource Name (ARN) of the DataSync agent to describe.
]: any -> oneof<record<AgentArn: string, Name: string, Status: string, LastConnectionTime: string, CreationTime: string, EndpointType: string, PrivateLinkConfig: record<VpcEndpointId: string, PrivateLinkEndpoint: string, SubnetArns: list<string>, SecurityGroupArns: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeAgent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AgentArn": $agent_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata about your DataSync location for an Amazon EFS file system.
#
# POST /
# operationId: DescribeLocationEfs
export def "describe-location-efs" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the Amazon EFS file system location that you want information about.
]: any -> oneof<record<LocationArn: string, LocationUri: string, Ec2Config: record<SubnetArn: string, SecurityGroupArns: list<string>>, CreationTime: string, AccessPointArn: string, FileSystemAccessRoleArn: string, InTransitEncryption: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationEfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Provides details about how an DataSync location for an Amazon FSx for Lustre file system is configured.
#
# POST /
# operationId: DescribeLocationFsxLustre
export def "describe-location-fsx-lustre" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the FSx for Lustre location to describe.
]: any -> oneof<record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, CreationTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationFsxLustre")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Provides details about how an DataSync location for an Amazon FSx for NetApp ONTAP file system is configured. If your location uses SMB, the DescribeLocationFsxOntap operation doesn't actually return a Password.
#
# POST /
# operationId: DescribeLocationFsxOntap
export def "describe-location-fsx-ontap" [
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
  location_arn: string # Specifies the Amazon Resource Name (ARN) of the FSx for ONTAP file system location that you want information about.
]: any -> oneof<record<CreationTime: string, LocationArn: string, LocationUri: string, Protocol: record<NFS: record<MountOptions: record>, SMB: record<Domain: string, MountOptions: record, Password: string, User: string>>, SecurityGroupArns: list<string>, StorageVirtualMachineArn: string, FsxFilesystemArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationFsxOntap")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Provides details about how an DataSync location for an Amazon FSx for OpenZFS file system is configured. Response elements related to SMB aren't supported with the DescribeLocationFsxOpenZfs operation.
#
# POST /
# operationId: DescribeLocationFsxOpenZfs
export def "describe-location-fsx-open-zfs" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the FSx for OpenZFS location to describe.
]: any -> oneof<record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, Protocol: record<NFS: record<MountOptions: record>, SMB: record<Domain: string, MountOptions: record, Password: string, User: string>>, CreationTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationFsxOpenZfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata about an Amazon FSx for Windows File Server location, such as information about its path.
#
# POST /
# operationId: DescribeLocationFsxWindows
export def "describe-location-fsx-windows" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the FSx for Windows File Server location to describe.
]: any -> oneof<record<LocationArn: string, LocationUri: string, SecurityGroupArns: list<string>, CreationTime: string, User: string, Domain: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationFsxWindows")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata, such as the authentication information about the Hadoop Distributed File System (HDFS) location.
#
# POST /
# operationId: DescribeLocationHdfs
export def "describe-location-hdfs" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the HDFS cluster location to describe.
]: any -> oneof<record<LocationArn: string, LocationUri: string, NameNodes: table<Hostname: string, Port: int>, BlockSize: int, ReplicationFactor: int, KmsKeyProviderUri: string, QopConfiguration: record<RpcProtection: string, DataTransferProtection: string>, AuthenticationType: string, SimpleUser: string, KerberosPrincipal: string, AgentArns: list<string>, CreationTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationHdfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata, such as the path information, about an NFS location.
#
# POST /
# operationId: DescribeLocationNfs
export def "describe-location-nfs" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  location_arn: string # The Amazon Resource Name (ARN) of the NFS location to describe.
]: any -> oneof<record<LocationArn: string, LocationUri: string, OnPremConfig: record<AgentArns: list<string>>, MountOptions: record<Version: string>, CreationTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationNfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata about your DataSync location for an object storage system.
#
# POST /
# operationId: DescribeLocationObjectStorage
export def "describe-location-object-storage" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  location_arn: string # The Amazon Resource Name (ARN) of the object storage system location that you want information about.
]: any -> oneof<record<LocationArn: string, LocationUri: string, AccessKey: string, ServerPort: int, ServerProtocol: string, AgentArns: list<string>, CreationTime: string, ServerCertificate: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationObjectStorage")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata, such as bucket name, about an Amazon S3 bucket location.
#
# POST /
# operationId: DescribeLocationS3
export def "describe-location-s3" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  location_arn: string # The Amazon Resource Name (ARN) of the Amazon S3 bucket location to describe.
]: any -> oneof<record<LocationArn: string, LocationUri: string, S3StorageClass: string, S3Config: record<BucketAccessRoleArn: string>, AgentArns: list<string>, CreationTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationS3")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata, such as the path and user information about an SMB location.
#
# POST /
# operationId: DescribeLocationSmb
export def "describe-location-smb" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  location_arn: string # The Amazon Resource Name (ARN) of the SMB location to describe.
]: any -> oneof<record<LocationArn: string, LocationUri: string, AgentArns: list<string>, User: string, Domain: string, MountOptions: record<Version: string>, CreationTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeLocationSmb")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata about a task.
#
# POST /
# operationId: DescribeTask
export def "describe-task" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  task_arn: string # The Amazon Resource Name (ARN) of the task to describe.
]: any -> oneof<record<TaskArn: string, Status: string, Name: string, CurrentTaskExecutionArn: string, SourceLocationArn: string, DestinationLocationArn: string, CloudWatchLogGroupArn: string, SourceNetworkInterfaceArns: list<string>, DestinationNetworkInterfaceArns: list<string>, Options: record<VerifyMode: string, OverwriteMode: string, Atime: string, Mtime: string, Uid: string, Gid: string, PreserveDeletedFiles: string, PreserveDevices: string, PosixPermissions: string, BytesPerSecond: int, TaskQueueing: string, LogLevel: string, TransferMode: string, SecurityDescriptorCopyFlags: string, ObjectTags: string>, Excludes: table<FilterType: string, Value: string>, Schedule: record<ScheduleExpression: string>, ErrorCode: string, ErrorDetail: string, CreationTime: string, Includes: table<FilterType: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TaskArn": $task_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns detailed metadata about a task that is being executed.
#
# POST /
# operationId: DescribeTaskExecution
export def "describe-task-execution" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  task_execution_arn: string # The Amazon Resource Name (ARN) of the task that is being executed.
]: any -> oneof<record<TaskExecutionArn: string, Status: string, Options: record<VerifyMode: string, OverwriteMode: string, Atime: string, Mtime: string, Uid: string, Gid: string, PreserveDeletedFiles: string, PreserveDevices: string, PosixPermissions: string, BytesPerSecond: int, TaskQueueing: string, LogLevel: string, TransferMode: string, SecurityDescriptorCopyFlags: string, ObjectTags: string>, Excludes: table<FilterType: string, Value: string>, Includes: table<FilterType: string, Value: string>, StartTime: string, EstimatedFilesToTransfer: int, EstimatedBytesToTransfer: int, FilesTransferred: int, BytesWritten: int, BytesTransferred: int, Result: record<PrepareDuration: int, PrepareStatus: string, TotalDuration: int, TransferDuration: int, TransferStatus: string, VerifyDuration: int, VerifyStatus: string, ErrorCode: string, ErrorDetail: string>, BytesCompressed: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.DescribeTaskExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TaskExecutionArn": $task_execution_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns a list of DataSync agents that belong to an Amazon Web Services account in the Amazon Web Services Region specified in the request. With pagination, you can reduce the number of agents returned in a response. If you get a truncated list of agents in a response, the response contains a marker that you can specify in your next request to fetch the next page of agents. ListAgents is eventually consistent. This means the result of running the operation might not reflect that you just created or deleted an agent. For example, if you create an agent with CreateAgent (https://docs.aws.amazon.com/datasync/latest/userguide/API_CreateAgent.html) and then immediately run ListAgents, that agent might not show up in the list right away. In situations like this, you can always confirm whether an agent has been created (or deleted) by using DescribeAgent (https://docs.aws.amazon.com/datasync/latest/userguide/API_DescribeAgent.html).
#
# POST /
# operationId: ListAgents
export def "list-agents" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  --max-results-body: int # Specifies the maximum number of DataSync agents to list in a response. By default, a response shows a maximum of 100 agents. (body field)
  --next-token-body: string # Specifies an opaque string that indicates the position to begin the next list of results in the response. (body field)
]: any -> oneof<record<Agents: table<AgentArn: string, Name: string, Status: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.ListAgents")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of source and destination locations. If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.
#
# POST /
# operationId: ListLocations
export def "list-locations" [
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
  --max-results-body: int # The maximum number of locations to return. (body field)
  --next-token-body: string # An opaque string that indicates the position at which to begin the next list of locations. (body field)
  --filters: list # You can use API filters to narrow down the list of resources returned by ListLocations. For example, to retrieve all tasks on a specific source location, you can use ListLocations with filter name LocationType S3 and Operator Equals. — item shape: {Name: "LocationUri"|"LocationType"|"CreationTime", Values: list<string>, Operator: "Equals"|"NotEquals"|"In"|"LessThanOrEqual"|"LessThan"|"GreaterThanOrEqual"|"GreaterThan"|"Contains"|"NotContains"|"BeginsWith"}
]: any -> oneof<record<Locations: table<LocationArn: string, LocationUri: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.ListLocations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all the tags associated with an Amazon Web Services resource.
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
  resource_arn: string # Specifies the Amazon Resource Name (ARN) of the resource that you want tag information on.
  --max-results-body: int # Specifies how many results that you want in the response. (body field)
  --next-token-body: string # Specifies an opaque string that indicates the position to begin the next list of results in the response. (body field)
]: any -> oneof<record<Tags: table<Key: string, Value: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.ListTagsForResource")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of executed tasks.
#
# POST /
# operationId: ListTaskExecutions
export def "list-task-executions" [
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
  --task-arn: string # The Amazon Resource Name (ARN) of the task whose tasks you want to list.
  --max-results-body: int # The maximum number of executed tasks to list. (body field)
  --next-token-body: string # An opaque string that indicates the position at which to begin the next list of the executed tasks. (body field)
]: any -> oneof<record<TaskExecutions: table<TaskExecutionArn: string, Status: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.ListTaskExecutions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TaskArn": $task_arn, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of the DataSync tasks you created.
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  --max-results-body: int # The maximum number of tasks to return. (body field)
  --next-token-body: string # An opaque string that indicates the position at which to begin the next list of tasks. (body field)
  --filters: list # You can use API filters to narrow down the list of resources returned by ListTasks. For example, to retrieve all tasks on a specific source location, you can use ListTasks with filter name LocationId and Operator Equals with the ARN for the location. — item shape: {Name: "LocationId"|"CreationTime", Values: list<string>, Operator: "Equals"|"NotEquals"|"In"|"LessThanOrEqual"|"LessThan"|"GreaterThanOrEqual"|"GreaterThan"|"Contains"|"NotContains"|"BeginsWith"}
]: any -> oneof<record<Tasks: table<TaskArn: string, Status: string, Name: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.ListTasks")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Starts an DataSync task. For each task, you can only run one task execution at a time. There are several phases to a task execution. For more information, see Task execution statuses (https://docs.aws.amazon.com/datasync/latest/userguide/working-with-task-executions.html#understand-task-execution-statuses).
#
# POST /
# operationId: StartTaskExecution
export def "start-task-execution" [
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
  task_arn: string # Specifies the Amazon Resource Name (ARN) of the task that you want to start.
  --override-options: record # Configures your DataSync task settings. These options include how DataSync handles files, objects, and their associated metadata. You also can specify how DataSync verifies data integrity, set bandwidth limits for your task, among other options. Each task setting has a default value. Unless you need to, you don't have to configure any of these Options before starting your task. — shape: {VerifyMode?: "POINT_IN_TIME_CONSISTENT"|"ONLY_FILES_TRANSFERRED"|"NONE", OverwriteMode?: "ALWAYS"|"NEVER", Atime?: "NONE"|"BEST_EFFORT", Mtime?: "NONE"|"PRESERVE", Uid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", Gid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", PreserveDeletedFiles?: "PRESERVE"|"REMOVE", PreserveDevices?: "NONE"|"PRESERVE", PosixPermissions?: "NONE"|"PRESERVE", BytesPerSecond?: int, TaskQueueing?: "ENABLED"|"DISABLED", LogLevel?: "OFF"|"BASIC"|"TRANSFER", TransferMode?: "CHANGED"|"ALL", ... (2 more fields)}
  --includes: list # Specifies a list of filter rules that determines which files to include when running a task. The pattern should contain a single filter string that consists of the patterns to include. The patterns are delimited by "|" (that is, a pipe), for example, "/folder1|/folder2". — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
  --excludes: list # Specifies a list of filter rules that determines which files to exclude from a task. The list contains a single filter string that consists of the patterns to exclude. The patterns are delimited by "|" (that is, a pipe), for example, "/folder1|/folder2". — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
  --tags: list # Specifies the tags that you want to apply to the Amazon Resource Name (ARN) representing the task execution. Tags are key-value pairs that help you manage, filter, and search for your DataSync resources. — item shape: {Key: string, Value?: string}
]: any -> oneof<record<TaskExecutionArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.StartTaskExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TaskArn": $task_arn, "OverrideOptions": $override_options, "Includes": $includes, "Excludes": $excludes, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Applies a tag to an Amazon Web Services resource. Tags are key-value pairs that can help you manage, filter, and search for your resources. These include DataSync resources, such as locations, tasks, and task executions.
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  resource_arn: string # Specifies the Amazon Resource Name (ARN) of the resource to apply the tag to.
  tags: list # Specifies the tags that you want to apply to the resource. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Removes tags from an Amazon Web Services resource.
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  resource_arn: string # Specifies the Amazon Resource Name (ARN) of the resource to remove the tags from.
  keys: list<string> # Specifies the keys in the tags that you want to remove.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Keys": $keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the name of an agent.
#
# POST /
# operationId: UpdateAgent
export def "update-agent" [
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
  agent_arn: string # The Amazon Resource Name (ARN) of the agent to update.
  --name: string # The name that you want to use to configure the agent.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.UpdateAgent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AgentArn": $agent_arn, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates some parameters of a previously created location for a Hadoop Distributed File System cluster.
#
# POST /
# operationId: UpdateLocationHdfs
export def "update-location-hdfs" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the source HDFS cluster location.
  --subdirectory: string # A subdirectory in the HDFS cluster. This subdirectory is used to read data from or write data to the HDFS cluster.
  --name-nodes: list # The NameNode that manages the HDFS namespace. The NameNode performs operations such as opening, closing, and renaming files and directories. The NameNode contains the information to map blocks of data to the DataNodes. You can use only one NameNode. — item shape: {Hostname: string, Port: int}
  --block-size: int # The size of the data blocks to write into the HDFS cluster.
  --replication-factor: int # The number of DataNodes to replicate the data to when writing to the HDFS cluster.
  --kms-key-provider-uri: string # The URI of the HDFS cluster's Key Management Server (KMS).
  --qop-configuration: record # The Quality of Protection (QOP) configuration specifies the Remote Procedure Call (RPC) and data transfer privacy settings configured on the Hadoop Distributed File System (HDFS) cluster. — shape: {RpcProtection?: "DISABLED"|"AUTHENTICATION"|"INTEGRITY"|"PRIVACY", DataTransferProtection?: "DISABLED"|"AUTHENTICATION"|"INTEGRITY"|"PRIVACY"}
  --authentication-type: string@authentication-type-completer # The type of authentication used to determine the identity of the user.
  --simple-user: string # The user name used to identify the client on the host operating system.
  --kerberos-principal: string # The Kerberos principal with access to the files and folders on the HDFS cluster.
  --kerberos-keytab: string # The Kerberos key table (keytab) that contains mappings between the defined Kerberos principal and the encrypted keys. You can load the keytab from a file by providing the file's address. If you use the CLI, it performs base64 encoding for you. Otherwise, provide the base64-encoded text.
  --kerberos-krb5-conf: string # The krb5.conf file that contains the Kerberos configuration information. You can load the krb5.conf file by providing the file's address. If you're using the CLI, it performs the base64 encoding for you. Otherwise, provide the base64-encoded text.
  --agent-arns: list<string> # The ARNs of the agents that are used to connect to the HDFS cluster.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.UpdateLocationHdfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn, "Subdirectory": $subdirectory, "NameNodes": $name_nodes, "BlockSize": $block_size, "ReplicationFactor": $replication_factor, "KmsKeyProviderUri": $kms_key_provider_uri, "QopConfiguration": $qop_configuration, "AuthenticationType": $authentication_type, "SimpleUser": $simple_user, "KerberosPrincipal": $kerberos_principal, "KerberosKeytab": $kerberos_keytab, "KerberosKrb5Conf": $kerberos_krb5_conf, "AgentArns": $agent_arns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates some of the parameters of a previously created location for Network File System (NFS) access. For information about creating an NFS location, see Creating a location for NFS (https://docs.aws.amazon.com/datasync/latest/userguide/create-nfs-location.html).
#
# POST /
# operationId: UpdateLocationNfs
export def "update-location-nfs" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the NFS location to update.
  --subdirectory: string # The subdirectory in the NFS file system that is used to read data from the NFS source location or write data to the NFS destination. The NFS path should be a path that's exported by the NFS server, or a subdirectory of that path. The path should be such that it can be mounted by other NFS clients in your network. To see all the paths exported by your NFS server, run "showmount -e nfs-server-name" from an NFS client that has access to your server. You can specify any directory that appears in the results, and any subdirectory of that directory. Ensure that the NFS export is accessible without Kerberos authentication. To transfer all the data in the folder that you specified, DataSync must have permissions to read all the data. To ensure this, either configure the NFS export with no_root_squash, or ensure that the files you want DataSync to access have permissions that allow read access for all users. Doing either option enables the agent to read the files. For the agent to access directories, you must additionally enable all execute access. If you are copying data to or from your Snowcone device, see NFS Server on Snowcone (https://docs.aws.amazon.com/datasync/latest/userguide/create-nfs-location.html#nfs-on-snowcone) for more information. For information about NFS export configuration, see 18.7. The /etc/exports Configuration File in the Red Hat Enterprise Linux documentation.
  --on-prem-config: record # A list of Amazon Resource Names (ARNs) of agents to use for a Network File System (NFS) location. — shape: {AgentArns: list<string>}
  --mount-options: record # Specifies how DataSync can access a location using the NFS protocol. — shape: {Version?: "AUTOMATIC"|"NFS3"|"NFS4_0"|"NFS4_1"}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.UpdateLocationNfs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn, "Subdirectory": $subdirectory, "OnPremConfig": $on_prem_config, "MountOptions": $mount_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates some parameters of an existing object storage location that DataSync accesses for a transfer. For information about creating a self-managed object storage location, see Creating a location for object storage (https://docs.aws.amazon.com/datasync/latest/userguide/create-object-location.html).
#
# POST /
# operationId: UpdateLocationObjectStorage
export def "update-location-object-storage" [
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
  location_arn: string # Specifies the ARN of the object storage system location that you're updating.
  --server-port: int # Specifies the port that your object storage server accepts inbound network traffic on (for example, port 443).
  --server-protocol: string@server-protocol-completer # Specifies the protocol that your object storage server uses to communicate.
  --subdirectory: string # Specifies the object prefix for your object storage server. If this is a source location, DataSync only copies objects with this prefix. If this is a destination location, DataSync writes all objects with this prefix.
  --access-key: string # Specifies the access key (for example, a user name) if credentials are required to authenticate with the object storage server.
  --secret-key: string # Specifies the secret key (for example, a password) if credentials are required to authenticate with the object storage server. (format: password)
  --agent-arns: list<string> # Specifies the Amazon Resource Names (ARNs) of the DataSync agents that can securely connect with your location.
  --server-certificate: string # Specifies a certificate to authenticate with an object storage system that uses a private or self-signed certificate authority (CA). You must specify a Base64-encoded .pem file (for example, file:///home/user/.ssh/storage_sys_certificate.pem). The certificate can be up to 32768 bytes (before Base64 encoding). To use this parameter, configure ServerProtocol to HTTPS. Updating the certificate doesn't interfere with tasks that you have in progress.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.UpdateLocationObjectStorage")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn, "ServerPort": $server_port, "ServerProtocol": $server_protocol, "Subdirectory": $subdirectory, "AccessKey": $access_key, "SecretKey": $secret_key, "AgentArns": $agent_arns, "ServerCertificate": $server_certificate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates some of the parameters of a previously created location for Server Message Block (SMB) file system access. For information about creating an SMB location, see Creating a location for SMB (https://docs.aws.amazon.com/datasync/latest/userguide/create-smb-location.html).
#
# POST /
# operationId: UpdateLocationSmb
export def "update-location-smb" [
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
  location_arn: string # The Amazon Resource Name (ARN) of the SMB location to update.
  --subdirectory: string # The subdirectory in the SMB file system that is used to read data from the SMB source location or write data to the SMB destination. The SMB path should be a path that's exported by the SMB server, or a subdirectory of that path. The path should be such that it can be mounted by other SMB clients in your network. Subdirectory must be specified with forward slashes. For example, /path/to/folder. To transfer all the data in the folder that you specified, DataSync must have permissions to mount the SMB share and to access all the data in that share. To ensure this, do either of the following: Ensure that the user/password specified belongs to the user who can mount the share and who has the appropriate permissions for all of the files and directories that you want DataSync to access. Use credentials of a member of the Backup Operators group to mount the share. Doing either of these options enables the agent to access the data. For the agent to access directories, you must also enable all execute access.
  --user: string # The user who can mount the share has the permissions to access files and folders in the SMB share.
  --domain: string # The name of the Windows domain that the SMB server belongs to.
  --password: string # The password of the user who can mount the share has the permissions to access files and folders in the SMB share. (format: password)
  --agent-arns: list<string> # The Amazon Resource Names (ARNs) of agents to use for a Simple Message Block (SMB) location.
  --mount-options: record # Specifies the version of the Server Message Block (SMB) protocol that DataSync uses to access an SMB file server. — shape: {Version?: "AUTOMATIC"|"SMB2"|"SMB3"|"SMB1"|"SMB2_0"}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.UpdateLocationSmb")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationArn": $location_arn, "Subdirectory": $subdirectory, "User": $user, "Domain": $domain, "Password": $password, "AgentArns": $agent_arns, "MountOptions": $mount_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the metadata associated with a task.
#
# POST /
# operationId: UpdateTask
export def "update-task" [
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
  task_arn: string # The Amazon Resource Name (ARN) of the resource name of the task to update.
  --options: record # Configures your DataSync task settings. These options include how DataSync handles files, objects, and their associated metadata. You also can specify how DataSync verifies data integrity, set bandwidth limits for your task, among other options. Each task setting has a default value. Unless you need to, you don't have to configure any of these Options before starting your task. — shape: {VerifyMode?: "POINT_IN_TIME_CONSISTENT"|"ONLY_FILES_TRANSFERRED"|"NONE", OverwriteMode?: "ALWAYS"|"NEVER", Atime?: "NONE"|"BEST_EFFORT", Mtime?: "NONE"|"PRESERVE", Uid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", Gid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", PreserveDeletedFiles?: "PRESERVE"|"REMOVE", PreserveDevices?: "NONE"|"PRESERVE", PosixPermissions?: "NONE"|"PRESERVE", BytesPerSecond?: int, TaskQueueing?: "ENABLED"|"DISABLED", LogLevel?: "OFF"|"BASIC"|"TRANSFER", TransferMode?: "CHANGED"|"ALL", ... (2 more fields)}
  --excludes: list # Specifies a list of filter rules that exclude specific data during your transfer. For more information and examples, see Filtering data transferred by DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/filtering.html). — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
  --schedule: record # Specifies the schedule you want your task to use for repeated executions. For more information, see Schedule Expressions for Rules (https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html). — shape: {ScheduleExpression: string}
  --name: string # The name of the task to update.
  --cloud-watch-log-group-arn: string # The Amazon Resource Name (ARN) of the resource name of the Amazon CloudWatch log group.
  --includes: list # Specifies a list of filter rules that include specific data during your transfer. For more information and examples, see Filtering data transferred by DataSync (https://docs.aws.amazon.com/datasync/latest/userguide/filtering.html). — item shape: {FilterType?: "SIMPLE_PATTERN", Value?: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.UpdateTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TaskArn": $task_arn, "Options": $options, "Excludes": $excludes, "Schedule": $schedule, "Name": $name, "CloudWatchLogGroupArn": $cloud_watch_log_group_arn, "Includes": $includes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates execution of a task. You can modify bandwidth throttling for a task execution that is running or queued. For more information, see Adjusting Bandwidth Throttling for a Task Execution (https://docs.aws.amazon.com/datasync/latest/userguide/working-with-task-executions.html#adjust-bandwidth-throttling). The only Option that can be modified by UpdateTaskExecution is BytesPerSecond (https://docs.aws.amazon.com/datasync/latest/userguide/API_Options.html#DataSync-Type-Options-BytesPerSecond) .
#
# POST /
# operationId: UpdateTaskExecution
export def "update-task-execution" [
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
  task_execution_arn: string # The Amazon Resource Name (ARN) of the specific task execution that is being updated.
  options: record # Configures your DataSync task settings. These options include how DataSync handles files, objects, and their associated metadata. You also can specify how DataSync verifies data integrity, set bandwidth limits for your task, among other options. Each task setting has a default value. Unless you need to, you don't have to configure any of these Options before starting your task. — shape: {VerifyMode?: "POINT_IN_TIME_CONSISTENT"|"ONLY_FILES_TRANSFERRED"|"NONE", OverwriteMode?: "ALWAYS"|"NEVER", Atime?: "NONE"|"BEST_EFFORT", Mtime?: "NONE"|"PRESERVE", Uid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", Gid?: "NONE"|"INT_VALUE"|"NAME"|"BOTH", PreserveDeletedFiles?: "PRESERVE"|"REMOVE", PreserveDevices?: "NONE"|"PRESERVE", PosixPermissions?: "NONE"|"PRESERVE", BytesPerSecond?: int, TaskQueueing?: "ENABLED"|"DISABLED", LogLevel?: "OFF"|"BASIC"|"TRANSFER", TransferMode?: "CHANGED"|"ALL", ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "FmrsService.UpdateTaskExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TaskExecutionArn": $task_execution_arn, "Options": $options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
