# Auto-generated client for AWS Database Migration Service v2016-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/dms/2016-01-01/openapi.json
# Auth: --token flag or $env.AWS_DATABASE_MIGRATION_SERVICE_TOKEN

const BASE_URL = "http://dms.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_DATABASE_MIGRATION_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://dms.us-east-1.amazonaws.com" "http://dms.us-east-2.amazonaws.com" "http://dms.us-west-1.amazonaws.com" "http://dms.us-west-2.amazonaws.com" "http://dms.us-gov-west-1.amazonaws.com" "http://dms.us-gov-east-1.amazonaws.com" "http://dms.ca-central-1.amazonaws.com" "http://dms.eu-north-1.amazonaws.com" "http://dms.eu-west-1.amazonaws.com" "http://dms.eu-west-2.amazonaws.com" "http://dms.eu-west-3.amazonaws.com" "http://dms.eu-central-1.amazonaws.com" "http://dms.eu-south-1.amazonaws.com" "http://dms.af-south-1.amazonaws.com" "http://dms.ap-northeast-1.amazonaws.com" "http://dms.ap-northeast-2.amazonaws.com" "http://dms.ap-northeast-3.amazonaws.com" "http://dms.ap-southeast-1.amazonaws.com" "http://dms.ap-southeast-2.amazonaws.com" "http://dms.ap-east-1.amazonaws.com" "http://dms.ap-south-1.amazonaws.com" "http://dms.sa-east-1.amazonaws.com" "http://dms.me-south-1.amazonaws.com" "https://dms.us-east-1.amazonaws.com" "https://dms.us-east-2.amazonaws.com" "https://dms.us-west-1.amazonaws.com" "https://dms.us-west-2.amazonaws.com" "https://dms.us-gov-west-1.amazonaws.com" "https://dms.us-gov-east-1.amazonaws.com" "https://dms.ca-central-1.amazonaws.com" "https://dms.eu-north-1.amazonaws.com" "https://dms.eu-west-1.amazonaws.com" "https://dms.eu-west-2.amazonaws.com" "https://dms.eu-west-3.amazonaws.com" "https://dms.eu-central-1.amazonaws.com" "https://dms.eu-south-1.amazonaws.com" "https://dms.af-south-1.amazonaws.com" "https://dms.ap-northeast-1.amazonaws.com" "https://dms.ap-northeast-2.amazonaws.com" "https://dms.ap-northeast-3.amazonaws.com" "https://dms.ap-southeast-1.amazonaws.com" "https://dms.ap-southeast-2.amazonaws.com" "https://dms.ap-east-1.amazonaws.com" "https://dms.ap-south-1.amazonaws.com" "https://dms.sa-east-1.amazonaws.com" "https://dms.me-south-1.amazonaws.com" "http://dms.cn-north-1.amazonaws.com.cn" "http://dms.cn-northwest-1.amazonaws.com.cn" "https://dms.cn-north-1.amazonaws.com.cn" "https://dms.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AmazonDMSv20160101.AddTagsToResource"] }
def x-amz-target-completer-1 [] { ["AmazonDMSv20160101.ApplyPendingMaintenanceAction"] }
def x-amz-target-completer-2 [] { ["AmazonDMSv20160101.BatchStartRecommendations"] }
def x-amz-target-completer-3 [] { ["AmazonDMSv20160101.CancelReplicationTaskAssessmentRun"] }
def endpoint-type-completer [] { ["source" "target"] }
def ssl-mode-completer [] { ["none" "require" "verify-ca" "verify-full"] }
def x-amz-target-completer-4 [] { ["AmazonDMSv20160101.CreateEndpoint"] }
def x-amz-target-completer-5 [] { ["AmazonDMSv20160101.CreateEventSubscription"] }
def x-amz-target-completer-6 [] { ["AmazonDMSv20160101.CreateFleetAdvisorCollector"] }
def x-amz-target-completer-7 [] { ["AmazonDMSv20160101.CreateReplicationInstance"] }
def x-amz-target-completer-8 [] { ["AmazonDMSv20160101.CreateReplicationSubnetGroup"] }
def migration-type-completer [] { ["cdc" "full-load" "full-load-and-cdc"] }
def x-amz-target-completer-9 [] { ["AmazonDMSv20160101.CreateReplicationTask"] }
def x-amz-target-completer-10 [] { ["AmazonDMSv20160101.DeleteCertificate"] }
def x-amz-target-completer-11 [] { ["AmazonDMSv20160101.DeleteConnection"] }
def x-amz-target-completer-12 [] { ["AmazonDMSv20160101.DeleteEndpoint"] }
def x-amz-target-completer-13 [] { ["AmazonDMSv20160101.DeleteEventSubscription"] }
def x-amz-target-completer-14 [] { ["AmazonDMSv20160101.DeleteFleetAdvisorCollector"] }
def x-amz-target-completer-15 [] { ["AmazonDMSv20160101.DeleteFleetAdvisorDatabases"] }
def x-amz-target-completer-16 [] { ["AmazonDMSv20160101.DeleteReplicationInstance"] }
def x-amz-target-completer-17 [] { ["AmazonDMSv20160101.DeleteReplicationSubnetGroup"] }
def x-amz-target-completer-18 [] { ["AmazonDMSv20160101.DeleteReplicationTask"] }
def x-amz-target-completer-19 [] { ["AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun"] }
def x-amz-target-completer-20 [] { ["AmazonDMSv20160101.DescribeAccountAttributes"] }
def x-amz-target-completer-21 [] { ["AmazonDMSv20160101.DescribeApplicableIndividualAssessments"] }
def x-amz-target-completer-22 [] { ["AmazonDMSv20160101.DescribeCertificates"] }
def x-amz-target-completer-23 [] { ["AmazonDMSv20160101.DescribeConnections"] }
def x-amz-target-completer-24 [] { ["AmazonDMSv20160101.DescribeEndpointSettings"] }
def x-amz-target-completer-25 [] { ["AmazonDMSv20160101.DescribeEndpointTypes"] }
def x-amz-target-completer-26 [] { ["AmazonDMSv20160101.DescribeEndpoints"] }
def x-amz-target-completer-27 [] { ["AmazonDMSv20160101.DescribeEventCategories"] }
def x-amz-target-completer-28 [] { ["AmazonDMSv20160101.DescribeEventSubscriptions"] }
def source-type-completer [] { ["replication-instance"] }
def x-amz-target-completer-29 [] { ["AmazonDMSv20160101.DescribeEvents"] }
def x-amz-target-completer-30 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorCollectors"] }
def x-amz-target-completer-31 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorDatabases"] }
def x-amz-target-completer-32 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis"] }
def x-amz-target-completer-33 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary"] }
def x-amz-target-completer-34 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorSchemas"] }
def x-amz-target-completer-35 [] { ["AmazonDMSv20160101.DescribeOrderableReplicationInstances"] }
def x-amz-target-completer-36 [] { ["AmazonDMSv20160101.DescribePendingMaintenanceActions"] }
def x-amz-target-completer-37 [] { ["AmazonDMSv20160101.DescribeRecommendationLimitations"] }
def x-amz-target-completer-38 [] { ["AmazonDMSv20160101.DescribeRecommendations"] }
def x-amz-target-completer-39 [] { ["AmazonDMSv20160101.DescribeRefreshSchemasStatus"] }
def x-amz-target-completer-40 [] { ["AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"] }
def x-amz-target-completer-41 [] { ["AmazonDMSv20160101.DescribeReplicationInstances"] }
def x-amz-target-completer-42 [] { ["AmazonDMSv20160101.DescribeReplicationSubnetGroups"] }
def x-amz-target-completer-43 [] { ["AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"] }
def x-amz-target-completer-44 [] { ["AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns"] }
def x-amz-target-completer-45 [] { ["AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments"] }
def x-amz-target-completer-46 [] { ["AmazonDMSv20160101.DescribeReplicationTasks"] }
def x-amz-target-completer-47 [] { ["AmazonDMSv20160101.DescribeSchemas"] }
def x-amz-target-completer-48 [] { ["AmazonDMSv20160101.DescribeTableStatistics"] }
def x-amz-target-completer-49 [] { ["AmazonDMSv20160101.ImportCertificate"] }
def x-amz-target-completer-50 [] { ["AmazonDMSv20160101.ListTagsForResource"] }
def x-amz-target-completer-51 [] { ["AmazonDMSv20160101.ModifyEndpoint"] }
def x-amz-target-completer-52 [] { ["AmazonDMSv20160101.ModifyEventSubscription"] }
def x-amz-target-completer-53 [] { ["AmazonDMSv20160101.ModifyReplicationInstance"] }
def x-amz-target-completer-54 [] { ["AmazonDMSv20160101.ModifyReplicationSubnetGroup"] }
def x-amz-target-completer-55 [] { ["AmazonDMSv20160101.ModifyReplicationTask"] }
def x-amz-target-completer-56 [] { ["AmazonDMSv20160101.MoveReplicationTask"] }
def x-amz-target-completer-57 [] { ["AmazonDMSv20160101.RebootReplicationInstance"] }
def x-amz-target-completer-58 [] { ["AmazonDMSv20160101.RefreshSchemas"] }
def reload-option-completer [] { ["data-reload" "validate-only"] }
def x-amz-target-completer-59 [] { ["AmazonDMSv20160101.ReloadTables"] }
def x-amz-target-completer-60 [] { ["AmazonDMSv20160101.RemoveTagsFromResource"] }
def x-amz-target-completer-61 [] { ["AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis"] }
def x-amz-target-completer-62 [] { ["AmazonDMSv20160101.StartRecommendations"] }
def start-replication-task-type-completer [] { ["reload-target" "resume-processing" "start-replication"] }
def x-amz-target-completer-63 [] { ["AmazonDMSv20160101.StartReplicationTask"] }
def x-amz-target-completer-64 [] { ["AmazonDMSv20160101.StartReplicationTaskAssessment"] }
def x-amz-target-completer-65 [] { ["AmazonDMSv20160101.StartReplicationTaskAssessmentRun"] }
def x-amz-target-completer-66 [] { ["AmazonDMSv20160101.StopReplicationTask"] }
def x-amz-target-completer-67 [] { ["AmazonDMSv20160101.TestConnection"] }
def x-amz-target-completer-68 [] { ["AmazonDMSv20160101.UpdateSubscriptionsToEventBridge"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags-to-resource" "apply-pending-maintenance-action" "batch-start-recommendations" "cancel-replication-task-assessment-run" "create-endpoint" "create-event-subscription" "create-fleet-advisor-collector" "create-replication-instance" "create-replication-subnet-group" "create-replication-task" "delete-certificate" "delete-connection" "delete-endpoint" "delete-event-subscription" "delete-fleet-advisor-collector" "delete-fleet-advisor-databases" "delete-replication-instance" "delete-replication-subnet-group" "delete-replication-task" "delete-replication-task-assessment-run" "describe-account-attributes" "describe-applicable-individual-assessments" "describe-certificates" "describe-connections" "describe-endpoint-settings" "describe-endpoint-types" "describe-endpoints" "describe-event-categories" "describe-event-subscriptions" "describe-events" "describe-fleet-advisor-collectors" "describe-fleet-advisor-databases" "describe-fleet-advisor-lsa-analysis" "describe-fleet-advisor-schema-object-summary" "describe-fleet-advisor-schemas" "describe-orderable-replication-instances" "describe-pending-maintenance-actions" "describe-recommendation-limitations" "describe-recommendations" "describe-refresh-schemas-status" "describe-replication-instance-task-logs" "describe-replication-instances" "describe-replication-subnet-groups" "describe-replication-task-assessment-results" "describe-replication-task-assessment-runs" "describe-replication-task-individual-assessments" "describe-replication-tasks" "describe-schemas" "describe-table-statistics" "import-certificate" "list-tags-for-resource" "modify-endpoint" "modify-event-subscription" "modify-replication-instance" "modify-replication-subnet-group" "modify-replication-task" "move-replication-task" "reboot-replication-instance" "refresh-schemas" "reload-tables" "remove-tags-from-resource" "run-fleet-advisor-lsa-analysis" "start-recommendations" "start-replication-task" "start-replication-task-assessment" "start-replication-task-assessment-run" "stop-replication-task" "test-connection" "update-subscriptions-to-event-bridge" "commands"] | sort) } | get name | first)
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

# Adds metadata tags to an DMS resource, including replication instance, endpoint, subnet group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
#
# POST /
# operationId: AddTagsToResource
export def "add-tags-to-resource" [
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
  resource_arn: string # Identifies the DMS resource to which tags should be added. The value for this parameter is an Amazon Resource Name (ARN). For DMS, you can tag a replication instance, an endpoint, or a replication task.
  tags: list # One or more tags to be assigned to the resource. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.AddTagsToResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
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

# Applies a pending maintenance action to a resource (for example, to a replication instance).
#
# POST /
# operationId: ApplyPendingMaintenanceAction
export def "apply-pending-maintenance-action" [
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
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the DMS resource that the pending maintenance action applies to.
  apply_action: string # The pending maintenance action to apply to this resource. Valid values: os-upgrade, system-update, db-upgrade
  opt_in_type: string # A value that specifies the type of opt-in request, or undoes an opt-in request. You can't undo an opt-in request of type immediate. Valid values: immediate - Apply the maintenance action immediately. next-maintenance - Apply the maintenance action during the next maintenance window for the resource. undo-opt-in - Cancel any existing next-maintenance opt-in requests.
]: any -> oneof<record<ResourcePendingMaintenanceActions: record<ResourceIdentifier: string, PendingMaintenanceActionDetails: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ApplyPendingMaintenanceAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "ApplyAction": $apply_action, "OptInType": $opt_in_type} | compact
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

# Starts the analysis of up to 20 source databases to recommend target engines for each source database. This is a batch version of StartRecommendations (https://docs.aws.amazon.com/dms/latest/APIReference/API_StartRecommendations.html). The result of analysis of each source database is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200.
#
# POST /
# operationId: BatchStartRecommendations
export def "batch-start-recommendations" [
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
  --data: list # Provides information about source databases to analyze. After this analysis, Fleet Advisor recommends target engines for each source database. — item shape: {DatabaseId: string, Settings: record}
]: any -> oneof<record<ErrorEntries: table<DatabaseId: string, Message: string, Code: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.BatchStartRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Data": $data} | compact
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

# Cancels a single premigration assessment run. This operation prevents any individual assessments from running if they haven't started running. It also attempts to cancel any individual assessments that are currently running.
#
# POST /
# operationId: CancelReplicationTaskAssessmentRun
export def "cancel-replication-task-assessment-run" [
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
  replication_task_assessment_run_arn: string # Amazon Resource Name (ARN) of the premigration assessment run to be canceled.
]: any -> oneof<record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.CancelReplicationTaskAssessmentRun")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskAssessmentRunArn": $replication_task_assessment_run_arn} | compact
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

# Creates an endpoint using the provided settings. For a MySQL source or target endpoint, don't explicitly specify the database using the DatabaseName request parameter on the CreateEndpoint API call. Specifying DatabaseName when you create a MySQL endpoint replicates all the task tables to this single database. For MySQL endpoints, you specify the database only when you specify the schema in the table-mapping rules of the DMS task.
#
# POST /
# operationId: CreateEndpoint
export def "create-endpoint" [
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
  endpoint_identifier: string # The database endpoint identifier. Identifiers must begin with a letter and must contain only ASCII letters, digits, and hyphens. They can't end with a hyphen, or contain two consecutive hyphens.
  endpoint_type: string@endpoint-type-completer # The type of endpoint. Valid values are source and target.
  engine_name: string # The type of engine for the endpoint. Valid values, depending on the EndpointType value, include "mysql", "oracle", "postgres", "mariadb", "aurora", "aurora-postgresql", "opensearch", "redshift", "s3", "db2", "db2-zos", "azuredb", "sybase", "dynamodb", "mongodb", "kinesis", "kafka", "elasticsearch", "docdb", "sqlserver", "neptune", and "babelfish".
  --username: string # The user name to be used to log in to the endpoint database.
  --password: string # The password to be used to log in to the endpoint database. (format: password)
  --server-name: string # The name of the server where the endpoint database resides.
  --port: int # The port used by the endpoint database.
  --database-name: string # The name of the endpoint database. For a MySQL source or target endpoint, do not specify DatabaseName. To migrate to a specific database, use this setting and targetDbType.
  --extra-connection-attributes: string # Additional attributes associated with the connection. Each attribute is specified as a name-value pair associated by an equal sign (=). Multiple attributes are separated by a semicolon (;) with no additional white space. For information on the attributes available for connecting your source or target endpoint, see Working with DMS Endpoints (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Endpoints.html) in the Database Migration Service User Guide.
  --kms-key-id: string # An KMS key identifier that is used to encrypt the connection parameters for the endpoint. If you don't specify a value for the KmsKeyId parameter, then DMS uses your default encryption key. KMS creates the default encryption key for your Amazon Web Services account. Your Amazon Web Services account has a different default encryption key for each Amazon Web Services Region.
  --tags: list # One or more tags to be assigned to the endpoint. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
  --certificate-arn: string # The Amazon Resource Name (ARN) for the certificate.
  --ssl-mode: string@ssl-mode-completer # The Secure Sockets Layer (SSL) mode to use for the SSL connection. The default is none
  --service-access-role-arn: string # The Amazon Resource Name (ARN) for the service access role that you want to use to create the endpoint. The role must allow the iam:PassRole action.
  --external-table-definition: string # The external table definition.
  --dynamo-db-settings: record # Provides the Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role used to define an Amazon DynamoDB target endpoint. — shape: {ServiceAccessRoleArn: string}
  --s3-settings: record # Settings for exporting data to Amazon S3. — shape: {ServiceAccessRoleArn?: string, ExternalTableDefinition?: string, CsvRowDelimiter?: string, CsvDelimiter?: string, BucketFolder?: string, BucketName?: string, CompressionType?: "none"|"gzip", EncryptionMode?: "sse-s3"|"sse-kms", ServerSideEncryptionKmsKeyId?: string, DataFormat?: "csv"|"parquet", EncodingType?: "plain"|"plain-dictionary"|"rle-dictionary", DictPageSizeLimit?: int, RowGroupLength?: int, DataPageSize?: int, ParquetVersion?: "parquet-1-0"|"parquet-2-0", EnableStatistics?: bool, ... (25 more fields)}
  --dms-transfer-settings: record # The settings in JSON format for the DMS Transfer type source endpoint. — shape: {ServiceAccessRoleArn?: string, BucketName?: string}
  --mongo-db-settings: record # Provides information that defines a MongoDB endpoint. — shape: {Username?: string, Password?: string, ServerName?: string, Port?: int, DatabaseName?: string, AuthType?: "no"|"password", AuthMechanism?: "default"|"mongodb_cr"|"scram_sha_1", NestingLevel?: "none"|"one", ExtractDocId?: string, DocsToInvestigate?: string, AuthSource?: string, KmsKeyId?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --kinesis-settings: record # Provides information that describes an Amazon Kinesis Data Stream endpoint. This information includes the output format of records applied to the endpoint and details of transaction and control table data information. — shape: {StreamArn?: string, MessageFormat?: "json"|"json-unformatted", ServiceAccessRoleArn?: string, IncludeTransactionDetails?: bool, IncludePartitionValue?: bool, PartitionIncludeSchemaTable?: bool, IncludeTableAlterOperations?: bool, IncludeControlDetails?: bool, IncludeNullAndEmpty?: bool, NoHexPrefix?: bool}
  --kafka-settings: record # Provides information that describes an Apache Kafka endpoint. This information includes the output format of records applied to the endpoint and details of transaction and control table data information. — shape: {Broker?: string, Topic?: string, MessageFormat?: "json"|"json-unformatted", IncludeTransactionDetails?: bool, IncludePartitionValue?: bool, PartitionIncludeSchemaTable?: bool, IncludeTableAlterOperations?: bool, IncludeControlDetails?: bool, MessageMaxBytes?: int, IncludeNullAndEmpty?: bool, SecurityProtocol?: "plaintext"|"ssl-authentication"|"ssl-encryption"|"sasl-ssl", SslClientCertificateArn?: string, SslClientKeyArn?: string, SslClientKeyPassword?: string, SslCaCertificateArn?: string, ... (4 more fields)}
  --elasticsearch-settings: record # Provides information that defines an OpenSearch endpoint. — shape: {ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage?: int, ErrorRetryDuration?: int, UseNewMappingType?: bool}
  --neptune-settings: record # Provides information that defines an Amazon Neptune endpoint. — shape: {ServiceAccessRoleArn?: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration?: int, MaxFileSize?: int, MaxRetryCount?: int, IamAuthEnabled?: bool}
  --redshift-settings: record # Provides information that defines an Amazon Redshift endpoint. — shape: {AcceptAnyDate?: bool, AfterConnectScript?: string, BucketFolder?: string, BucketName?: string, CaseSensitiveNames?: bool, CompUpdate?: bool, ConnectionTimeout?: int, DatabaseName?: string, DateFormat?: string, EmptyAsNull?: bool, EncryptionMode?: "sse-s3"|"sse-kms", ExplicitIds?: bool, FileTransferUploadStreams?: int, LoadTimeout?: int, MaxFileSize?: int, Password?: string, Port?: int, RemoveQuotes?: bool, ReplaceInvalidChars?: string, ReplaceChars?: string, ServerName?: string, ... (10 more fields)}
  --postgre-sql-settings: record # Provides information that defines a PostgreSQL endpoint. — shape: {AfterConnectScript?: string, CaptureDdls?: bool, MaxFileSize?: int, DatabaseName?: string, DdlArtifactsSchema?: string, ExecuteTimeout?: int, FailTasksOnLobTruncation?: bool, HeartbeatEnable?: bool, HeartbeatSchema?: string, HeartbeatFrequency?: int, Password?: string, Port?: int, ServerName?: string, Username?: string, SlotName?: string, PluginName?: "no-preference"|"test-decoding"|"pglogical", SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string, TrimSpaceInChar?: bool, ... (1 more fields)}
  --my-sql-settings: record # Provides information that defines a MySQL endpoint. — shape: {AfterConnectScript?: string, CleanSourceMetadataOnMismatch?: bool, DatabaseName?: string, EventsPollInterval?: int, TargetDbType?: "specific-database"|"multiple-databases", MaxFileSize?: int, ParallelLoadThreads?: int, Password?: string, Port?: int, ServerName?: string, ServerTimezone?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --oracle-settings: record # Provides information that defines an Oracle endpoint. — shape: {AddSupplementalLogging?: bool, ArchivedLogDestId?: int, AdditionalArchivedLogDestId?: int, ExtraArchivedLogDestIds?: list<int>, AllowSelectNestedTables?: bool, ParallelAsmReadThreads?: int, ReadAheadBlocks?: int, AccessAlternateDirectly?: bool, UseAlternateFolderForOnline?: bool, OraclePathPrefix?: string, UsePathPrefix?: string, ReplacePathPrefix?: bool, EnableHomogenousTablespace?: bool, DirectPathNoLog?: bool, ArchivedLogsOnly?: bool, AsmPassword?: string, AsmServer?: string, AsmUser?: string, ... (24 more fields)}
  --sybase-settings: record # Provides information that defines a SAP ASE endpoint. — shape: {DatabaseName?: string, Password?: string, Port?: int, ServerName?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --microsoft-sql-server-settings: record # Provides information that defines a Microsoft SQL Server endpoint. — shape: {Port?: int, BcpPacketSize?: int, DatabaseName?: string, ControlTablesFileGroup?: string, Password?: string, QuerySingleAlwaysOnNode?: bool, ReadBackupOnly?: bool, SafeguardPolicy?: "rely-on-sql-server-replication-agent"|"exclusive-automatic-truncation"|"shared-automatic-truncation", ServerName?: string, Username?: string, UseBcpFullLoad?: bool, UseThirdPartyBackupDevice?: bool, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string, TrimSpaceInChar?: bool, ... (2 more fields)}
  --ibm-db2-settings: record # Provides information that defines an IBM Db2 LUW endpoint. — shape: {DatabaseName?: string, Password?: string, Port?: int, ServerName?: string, SetDataCaptureChanges?: bool, CurrentLsn?: string, MaxKBytesPerRead?: int, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --resource-identifier: string # A friendly name for the resource identifier at the end of the EndpointArn response parameter that is returned in the created Endpoint object. The value for this parameter can have up to 31 characters. It can contain only ASCII letters, digits, and hyphen ('-'). Also, it can't end with a hyphen or contain two consecutive hyphens, and can only begin with a letter, such as Example-App-ARN1. For example, this value might result in the EndpointArn value arn:aws:dms:eu-west-1:012345678901:rep:Example-App-ARN1. If you don't specify a ResourceIdentifier value, DMS generates a default identifier value for the end of EndpointArn.
  --doc-db-settings: record # Provides information that defines a DocumentDB endpoint. — shape: {Username?: string, Password?: string, ServerName?: string, Port?: int, DatabaseName?: string, NestingLevel?: "none"|"one", ExtractDocId?: bool, DocsToInvestigate?: int, KmsKeyId?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --redis-settings: record # Provides information that defines a Redis target endpoint. — shape: {ServerName: string, Port: int, SslSecurityProtocol?: "plaintext"|"ssl-encryption", AuthType?: "none"|"auth-role"|"auth-token", AuthUserName?: string, AuthPassword?: string, SslCaCertificateArn?: string}
  --gcp-my-sql-settings: record # Settings in JSON format for the source GCP MySQL endpoint. — shape: {AfterConnectScript?: string, CleanSourceMetadataOnMismatch?: bool, DatabaseName?: string, EventsPollInterval?: int, TargetDbType?: "specific-database"|"multiple-databases", MaxFileSize?: int, ParallelLoadThreads?: int, Password?: string, Port?: int, ServerName?: string, ServerTimezone?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
]: any -> oneof<record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.CreateEndpoint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"EndpointIdentifier": $endpoint_identifier, "EndpointType": $endpoint_type, "EngineName": $engine_name, "Username": $username, "Password": $password, "ServerName": $server_name, "Port": $port, "DatabaseName": $database_name, "ExtraConnectionAttributes": $extra_connection_attributes, "KmsKeyId": $kms_key_id, "Tags": $tags, "CertificateArn": $certificate_arn, "SslMode": $ssl_mode, "ServiceAccessRoleArn": $service_access_role_arn, "ExternalTableDefinition": $external_table_definition, "DynamoDbSettings": $dynamo_db_settings, "S3Settings": $s3_settings, "DmsTransferSettings": $dms_transfer_settings, "MongoDbSettings": $mongo_db_settings, "KinesisSettings": $kinesis_settings, "KafkaSettings": $kafka_settings, "ElasticsearchSettings": $elasticsearch_settings, "NeptuneSettings": $neptune_settings, "RedshiftSettings": $redshift_settings, "PostgreSQLSettings": $postgre_sql_settings, "MySQLSettings": $my_sql_settings, "OracleSettings": $oracle_settings, "SybaseSettings": $sybase_settings, "MicrosoftSQLServerSettings": $microsoft_sql_server_settings, "IBMDb2Settings": $ibm_db2_settings, "ResourceIdentifier": $resource_identifier, "DocDbSettings": $doc_db_settings, "RedisSettings": $redis_settings, "GcpMySQLSettings": $gcp_my_sql_settings} | compact
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

# Creates an DMS event notification subscription. You can specify the type of source (SourceType) you want to be notified of, provide a list of DMS source IDs (SourceIds) that triggers the events, and provide a list of event categories (EventCategories) for events you want to be notified of. If you specify both the SourceType and SourceIds, such as SourceType = replication-instance and SourceIdentifier = my-replinstance, you will be notified of all the replication instance events for the specified source. If you specify a SourceType but don't specify a SourceIdentifier, you receive notice of the events for that source type for all your DMS sources. If you don't specify either SourceType nor SourceIdentifier, you will be notified of events generated from all DMS sources belonging to your customer account. For more information about DMS events, see Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /
# operationId: CreateEventSubscription
export def "create-event-subscription" [
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
  subscription_name: string # The name of the DMS event notification subscription. This name must be less than 255 characters.
  sns_topic_arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic created for event notification. The ARN is created by Amazon SNS when you create a topic and subscribe to it.
  --source-type: string # The type of DMS resource that generates the events. For example, if you want to be notified of events generated by a replication instance, you set this parameter to replication-instance. If this value isn't specified, all events are returned. Valid values: replication-instance | replication-task
  --event-categories: list<string> # A list of event categories for a source type that you want to subscribe to. For more information, see Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
  --source-ids: list<string> # A list of identifiers for which DMS provides notification events. If you don't specify a value, notifications are provided for all sources. If you specify multiple values, they must be of the same type. For example, if you specify a database instance ID, then all of the other values must be database instance IDs.
  --enabled: oneof<nothing, bool> # A Boolean value; set to true to activate the subscription, or set to false to create the subscription but not activate it.
  --tags: list # One or more tags to be assigned to the event subscription. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
]: any -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.CreateEventSubscription")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SubscriptionName": $subscription_name, "SnsTopicArn": $sns_topic_arn, "SourceType": $source_type, "EventCategories": $event_categories, "SourceIds": $source_ids, "Enabled": $enabled, "Tags": $tags} | compact
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

# Creates a Fleet Advisor collector using the specified parameters.
#
# POST /
# operationId: CreateFleetAdvisorCollector
export def "create-fleet-advisor-collector" [
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
  collector_name: string # The name of your Fleet Advisor collector (for example, sample-collector).
  --description: string # A summary description of your Fleet Advisor collector.
  service_access_role_arn: string # The IAM role that grants permissions to access the specified Amazon S3 bucket.
  s3_bucket_name: string # The Amazon S3 bucket that the Fleet Advisor collector uses to store inventory metadata.
]: any -> oneof<record<CollectorReferencedId: string, CollectorName: string, Description: string, ServiceAccessRoleArn: string, S3BucketName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.CreateFleetAdvisorCollector")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CollectorName": $collector_name, "Description": $description, "ServiceAccessRoleArn": $service_access_role_arn, "S3BucketName": $s3_bucket_name} | compact
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

# Creates the replication instance using the specified parameters. DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see Creating the IAM Roles to Use With the CLI and DMS API (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole). For information on the required permissions, see IAM Permissions Needed to Use DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.IAMPermissions).
#
# POST /
# operationId: CreateReplicationInstance
export def "create-replication-instance" [
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
  replication_instance_identifier: string # The replication instance identifier. This parameter is stored as a lowercase string. Constraints: Must contain 1-63 alphanumeric characters or hyphens. First character must be a letter. Can't end with a hyphen or contain two consecutive hyphens. Example: myrepinstance
  --allocated-storage: int # The amount of storage (in gigabytes) to be initially allocated for the replication instance.
  replication_instance_class: string # The compute and memory capacity of the replication instance as defined for the specified replication instance class. For example to specify the instance class dms.c4.large, set this parameter to "dms.c4.large". For more information on the settings and capacities for the available replication instance classes, see Selecting the right DMS replication instance for your migration (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_ReplicationInstance.html#CHAP_ReplicationInstance.InDepth).
  --vpc-security-group-ids: list<string> # Specifies the VPC security group to be used with the replication instance. The VPC security group must work with the VPC containing the replication instance.
  --availability-zone: string # The Availability Zone where the replication instance will be created. The default value is a random, system-chosen Availability Zone in the endpoint's Amazon Web Services Region, for example: us-east-1d
  --replication-subnet-group-identifier: string # A subnet group to associate with the replication instance.
  --preferred-maintenance-window: string # The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC). Format: ddd:hh24:mi-ddd:hh24:mi Default: A 30-minute window selected at random from an 8-hour block of time per Amazon Web Services Region, occurring on a random day of the week. Valid Days: Mon, Tue, Wed, Thu, Fri, Sat, Sun Constraints: Minimum 30-minute window.
  --multi-az: oneof<nothing, bool> # Specifies whether the replication instance is a Multi-AZ deployment. You can't set the AvailabilityZone parameter if the Multi-AZ parameter is set to true.
  --engine-version: string # The engine version number of the replication instance. If an engine version number is not specified when a replication instance is created, the default is the latest engine version available.
  --auto-minor-version-upgrade: oneof<nothing, bool> # A value that indicates whether minor engine upgrades are applied automatically to the replication instance during the maintenance window. This parameter defaults to true. Default: true When AutoMinorVersionUpgrade is enabled, DMS uses the current default engine version when you create a replication instance. For example, if you set EngineVersion to a lower version number than the current default version, DMS uses the default version. If AutoMinorVersionUpgrade isn’t enabled when you create a replication instance, DMS uses the engine version specified by the EngineVersion parameter.
  --tags: list # One or more tags to be assigned to the replication instance. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
  --kms-key-id: string # An KMS key identifier that is used to encrypt the data on the replication instance. If you don't specify a value for the KmsKeyId parameter, then DMS uses your default encryption key. KMS creates the default encryption key for your Amazon Web Services account. Your Amazon Web Services account has a different default encryption key for each Amazon Web Services Region.
  --publicly-accessible: oneof<nothing, bool> # Specifies the accessibility options for the replication instance. A value of true represents an instance with a public IP address. A value of false represents an instance with a private IP address. The default value is true.
  --dns-name-servers: string # A list of custom DNS name servers supported for the replication instance to access your on-premise source or target database. This list overrides the default name servers supported by the replication instance. You can specify a comma-separated list of internet addresses for up to four on-premise DNS name servers. For example: "1.1.1.1,2.2.2.2,3.3.3.3,4.4.4.4"
  --resource-identifier: string # A friendly name for the resource identifier at the end of the EndpointArn response parameter that is returned in the created Endpoint object. The value for this parameter can have up to 31 characters. It can contain only ASCII letters, digits, and hyphen ('-'). Also, it can't end with a hyphen or contain two consecutive hyphens, and can only begin with a letter, such as Example-App-ARN1. For example, this value might result in the EndpointArn value arn:aws:dms:eu-west-1:012345678901:rep:Example-App-ARN1. If you don't specify a ResourceIdentifier value, DMS generates a default identifier value for the end of EndpointArn.
  --network-type: string # The type of IP address protocol used by a replication instance, such as IPv4 only or Dual-stack that supports both IPv4 and IPv6 addressing. IPv6 only is not yet supported.
]: any -> oneof<record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.CreateReplicationInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationInstanceIdentifier": $replication_instance_identifier, "AllocatedStorage": $allocated_storage, "ReplicationInstanceClass": $replication_instance_class, "VpcSecurityGroupIds": $vpc_security_group_ids, "AvailabilityZone": $availability_zone, "ReplicationSubnetGroupIdentifier": $replication_subnet_group_identifier, "PreferredMaintenanceWindow": $preferred_maintenance_window, "MultiAZ": $multi_az, "EngineVersion": $engine_version, "AutoMinorVersionUpgrade": $auto_minor_version_upgrade, "Tags": $tags, "KmsKeyId": $kms_key_id, "PubliclyAccessible": $publicly_accessible, "DnsNameServers": $dns_name_servers, "ResourceIdentifier": $resource_identifier, "NetworkType": $network_type} | compact
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

# Creates a replication subnet group given a list of the subnet IDs in a VPC. The VPC needs to have at least one subnet in at least two availability zones in the Amazon Web Services Region, otherwise the service will throw a ReplicationSubnetGroupDoesNotCoverEnoughAZs exception.
#
# POST /
# operationId: CreateReplicationSubnetGroup
export def "create-replication-subnet-group" [
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
  replication_subnet_group_identifier: string # The name for the replication subnet group. This value is stored as a lowercase string. Constraints: Must contain no more than 255 alphanumeric characters, periods, spaces, underscores, or hyphens. Must not be "default". Example: mySubnetgroup
  replication_subnet_group_description: string # The description for the subnet group.
  subnet_ids: list<string> # One or more subnet IDs to be assigned to the subnet group.
  --tags: list # One or more tags to be assigned to the subnet group. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
]: any -> oneof<record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, SupportedNetworkTypes: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.CreateReplicationSubnetGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationSubnetGroupIdentifier": $replication_subnet_group_identifier, "ReplicationSubnetGroupDescription": $replication_subnet_group_description, "SubnetIds": $subnet_ids, "Tags": $tags} | compact
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

# Creates a replication task using the specified parameters.
#
# POST /
# operationId: CreateReplicationTask
export def "create-replication-task" [
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
  replication_task_identifier: string # An identifier for the replication task. Constraints: Must contain 1-255 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  source_endpoint_arn: string # An Amazon Resource Name (ARN) that uniquely identifies the source endpoint.
  target_endpoint_arn: string # An Amazon Resource Name (ARN) that uniquely identifies the target endpoint.
  replication_instance_arn: string # The Amazon Resource Name (ARN) of a replication instance.
  migration_type: string@migration-type-completer # The migration type. Valid values: full-load | cdc | full-load-and-cdc
  table_mappings: string # The table mappings for the task, in JSON format. For more information, see Using Table Mapping to Specify Task Settings (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TableMapping.html) in the Database Migration Service User Guide.
  --replication-task-settings: string # Overall settings for the task, in JSON format. For more information, see Specifying Task Settings for Database Migration Service Tasks (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TaskSettings.html) in the Database Migration Service User Guide.
  --cdc-start-time: string # Indicates the start time for a change data capture (CDC) operation. Use either CdcStartTime or CdcStartPosition to specify when you want a CDC operation to start. Specifying both values results in an error. Timestamp Example: --cdc-start-time “2018-03-08T12:12:12” (format: date-time)
  --cdc-start-position: string # Indicates when you want a change data capture (CDC) operation to start. Use either CdcStartPosition or CdcStartTime to specify when you want a CDC operation to start. Specifying both values results in an error. The value can be in date, checkpoint, or LSN/SCN format. Date Example: --cdc-start-position “2018-03-08T12:12:12” Checkpoint Example: --cdc-start-position "checkpoint:V1#27#mysql-bin-changelog.157832:1975:-1:2002:677883278264080:mysql-bin-changelog.157832:1876#0#0#*#0#93" LSN Example: --cdc-start-position “mysql-bin-changelog.000024:373” When you use this task setting with a source PostgreSQL database, a logical replication slot should already be created and associated with the source endpoint. You can verify this by setting the slotName extra connection attribute to the name of this logical replication slot. For more information, see Extra Connection Attributes When Using PostgreSQL as a Source for DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.ConnectionAttrib).
  --cdc-stop-position: string # Indicates when you want a change data capture (CDC) operation to stop. The value can be either server time or commit time. Server time example: --cdc-stop-position “server_time:2018-02-09T12:12:12” Commit time example: --cdc-stop-position “commit_time: 2018-02-09T12:12:12“
  --tags: list # One or more tags to be assigned to the replication task. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
  --task-data: string # Supplemental information that the task requires to migrate the data for certain source and target endpoints. For more information, see Specifying Supplemental Data for Task Settings (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.TaskData.html) in the Database Migration Service User Guide.
  --resource-identifier: string # A friendly name for the resource identifier at the end of the EndpointArn response parameter that is returned in the created Endpoint object. The value for this parameter can have up to 31 characters. It can contain only ASCII letters, digits, and hyphen ('-'). Also, it can't end with a hyphen or contain two consecutive hyphens, and can only begin with a letter, such as Example-App-ARN1. For example, this value might result in the EndpointArn value arn:aws:dms:eu-west-1:012345678901:rep:Example-App-ARN1. If you don't specify a ResourceIdentifier value, DMS generates a default identifier value for the end of EndpointArn.
]: any -> oneof<record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.CreateReplicationTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskIdentifier": $replication_task_identifier, "SourceEndpointArn": $source_endpoint_arn, "TargetEndpointArn": $target_endpoint_arn, "ReplicationInstanceArn": $replication_instance_arn, "MigrationType": $migration_type, "TableMappings": $table_mappings, "ReplicationTaskSettings": $replication_task_settings, "CdcStartTime": $cdc_start_time, "CdcStartPosition": $cdc_start_position, "CdcStopPosition": $cdc_stop_position, "Tags": $tags, "TaskData": $task_data, "ResourceIdentifier": $resource_identifier} | compact
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

# Deletes the specified certificate.
#
# POST /
# operationId: DeleteCertificate
export def "delete-certificate" [
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
  certificate_arn: string # The Amazon Resource Name (ARN) of the certificate.
]: any -> oneof<record<Certificate: record<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteCertificate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateArn": $certificate_arn} | compact
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

# Deletes the connection between a replication instance and an endpoint.
#
# POST /
# operationId: DeleteConnection
export def "delete-connection" [
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
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
]: any -> oneof<record<Connection: record<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"EndpointArn": $endpoint_arn, "ReplicationInstanceArn": $replication_instance_arn} | compact
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

# Deletes the specified endpoint. All tasks associated with the endpoint must be deleted before you can delete the endpoint.
#
# POST /
# operationId: DeleteEndpoint
export def "delete-endpoint" [
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
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
]: any -> oneof<record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteEndpoint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"EndpointArn": $endpoint_arn} | compact
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

# Deletes an DMS event subscription.
#
# POST /
# operationId: DeleteEventSubscription
export def "delete-event-subscription" [
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
  subscription_name: string # The name of the DMS event notification subscription to be deleted.
]: any -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteEventSubscription")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SubscriptionName": $subscription_name} | compact
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

# Deletes the specified Fleet Advisor collector.
#
# POST /
# operationId: DeleteFleetAdvisorCollector
export def "delete-fleet-advisor-collector" [
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
  collector_referenced_id: string # The reference ID of the Fleet Advisor collector to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteFleetAdvisorCollector")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CollectorReferencedId": $collector_referenced_id} | compact
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

# Deletes the specified Fleet Advisor collector databases.
#
# POST /
# operationId: DeleteFleetAdvisorDatabases
export def "delete-fleet-advisor-databases" [
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
  database_ids: list<string> # The IDs of the Fleet Advisor collector databases to delete.
]: any -> oneof<record<DatabaseIds: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteFleetAdvisorDatabases")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DatabaseIds": $database_ids} | compact
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

# Deletes the specified replication instance. You must delete any migration tasks that are associated with the replication instance before you can delete it.
#
# POST /
# operationId: DeleteReplicationInstance
export def "delete-replication-instance" [
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
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance to be deleted.
]: any -> oneof<record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteReplicationInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn} | compact
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

# Deletes a subnet group.
#
# POST /
# operationId: DeleteReplicationSubnetGroup
export def "delete-replication-subnet-group" [
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
  replication_subnet_group_identifier: string # The subnet group name of the replication instance.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteReplicationSubnetGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationSubnetGroupIdentifier": $replication_subnet_group_identifier} | compact
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

# Deletes the specified replication task.
#
# POST /
# operationId: DeleteReplicationTask
export def "delete-replication-task" [
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
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task to be deleted.
]: any -> oneof<record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteReplicationTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn} | compact
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

# Deletes the record of a single premigration assessment run. This operation removes all metadata that DMS maintains about this assessment run. However, the operation leaves untouched all information about this assessment run that is stored in your Amazon S3 bucket.
#
# POST /
# operationId: DeleteReplicationTaskAssessmentRun
export def "delete-replication-task-assessment-run" [
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
  replication_task_assessment_run_arn: string # Amazon Resource Name (ARN) of the premigration assessment run to be deleted.
]: any -> oneof<record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskAssessmentRunArn": $replication_task_assessment_run_arn} | compact
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

# Lists all of the DMS attributes for a customer account. These attributes include DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region. This command does not take any parameters.
#
# POST /
# operationId: DescribeAccountAttributes
export def "describe-account-attributes" [
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
  --body: record
]: any -> oneof<record<AccountQuotas: table<AccountQuotaName: string, Used: int, Max: int>, UniqueAccountIdentifier: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeAccountAttributes")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
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

# Provides a list of individual assessments that you can specify for a new premigration assessment run, given one or more parameters. If you specify an existing migration task, this operation provides the default individual assessments you can specify for that task. Otherwise, the specified parameters model elements of a possible migration task on which to base a premigration assessment run. To use these migration task modeling parameters, you must specify an existing replication instance, a source database engine, a target database engine, and a migration type. This combination of parameters potentially limits the default individual assessments available for an assessment run created for a corresponding migration task. If you specify no parameters, this operation provides a list of all possible individual assessments that you can specify for an assessment run. If you specify any one of the task modeling parameters, you must specify all of them or the operation cannot provide a list of individual assessments. The only parameter that you can specify alone is for an existing migration task. The specified task definition then determines the default list of individual assessments that you can specify in an assessment run for the task.
#
# POST /
# operationId: DescribeApplicableIndividualAssessments
export def "describe-applicable-individual-assessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  --replication-task-arn: string # Amazon Resource Name (ARN) of a migration task on which you want to base the default list of individual assessments.
  --replication-instance-arn: string # ARN of a replication instance on which you want to base the default list of individual assessments.
  --source-engine-name: string # Name of a database engine that the specified replication instance supports as a source.
  --target-engine-name: string # Name of a database engine that the specified replication instance supports as a target.
  --migration-type: string@migration-type-completer # Name of the migration type that each provided individual assessment must support.
  --body-max-records: int # Maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. (spec name: MaxRecords)
  --body-marker: string # Optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<IndividualAssessmentNames: list<string>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeApplicableIndividualAssessments")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "ReplicationInstanceArn": $replication_instance_arn, "SourceEngineName": $source_engine_name, "TargetEngineName": $target_engine_name, "MigrationType": $migration_type, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides a description of the certificate.
#
# POST /
# operationId: DescribeCertificates
export def "describe-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  --filters: list # Filters applied to the certificates described in the form of key-value pairs. Valid values are certificate-arn and certificate-id. — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 10 (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, Certificates: table<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeCertificates")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
#
# POST /
# operationId: DescribeConnections
export def "describe-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  --filters: list # The filters applied to the connection. Valid filter names: endpoint-arn | replication-instance-arn — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, Connections: table<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeConnections")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about the possible endpoint settings available when you create an endpoint for a specific database engine.
#
# POST /
# operationId: DescribeEndpointSettings
export def "describe-endpoint-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  engine_name: string # The databse engine used for your source or target endpoint.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, EndpointSettings: table<Name: string, Type: string, EnumValues: list, Sensitive: bool, Units: string, Applicability: string, IntValueMin: int, IntValueMax: int, DefaultValue: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeEndpointSettings")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"EngineName": $engine_name, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about the type of endpoints available.
#
# POST /
# operationId: DescribeEndpointTypes
export def "describe-endpoint-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  --filters: list # Filters applied to the endpoint types. Valid filter names: engine-name | endpoint-type — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, SupportedEndpointTypes: table<EngineName: string, SupportsCDC: bool, EndpointType: string, ReplicationInstanceEngineMinimumVersion: string, EngineDisplayName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeEndpointTypes")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about the endpoints for your account in the current region.
#
# POST /
# operationId: DescribeEndpoints
export def "describe-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  --filters: list # Filters applied to the endpoints. Valid filter names: endpoint-arn | endpoint-type | endpoint-id | engine-name — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, Endpoints: table<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record, S3Settings: record, DmsTransferSettings: record, MongoDbSettings: record, KinesisSettings: record, KafkaSettings: record, ElasticsearchSettings: record, NeptuneSettings: record, RedshiftSettings: record, PostgreSQLSettings: record, MySQLSettings: record, OracleSettings: record, SybaseSettings: record, MicrosoftSQLServerSettings: record, IBMDb2Settings: record, DocDbSettings: record, RedisSettings: record, GcpMySQLSettings: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeEndpoints")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /
# operationId: DescribeEventCategories
export def "describe-event-categories" [
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
  --source-type: string # The type of DMS resource that generates events. Valid values: replication-instance | replication-task
  --filters: list # Filters applied to the event categories. — item shape: {Name: string, Values: list<string>}
]: any -> oneof<record<EventCategoryGroupList: table<SourceType: string, EventCategories: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeEventCategories")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SourceType": $source_type, "Filters": $filters} | compact
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

# Lists all the event subscriptions for a customer account. The description of a subscription includes SubscriptionName, SNSTopicARN, CustomerID, SourceType, SourceID, CreationTime, and Status. If you specify SubscriptionName, this action lists the description for that subscription.
#
# POST /
# operationId: DescribeEventSubscriptions
export def "describe-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  --subscription-name: string # The name of the DMS event subscription to be described.
  --filters: list # Filters applied to event subscriptions. Valid filter names: event-subscription-arn | event-subscription-id — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, EventSubscriptionsList: table<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list, EventCategoriesList: list, Enabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeEventSubscriptions")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"SubscriptionName": $subscription_name, "Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on DMS events, see Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /
# operationId: DescribeEvents
export def "describe-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  --source-identifier: string # The identifier of an event source.
  --source-type: string@source-type-completer # The type of DMS resource that generates events. Valid values: replication-instance | replication-task
  --start-time: string # The start time for the events to be listed. (format: date-time)
  --end-time: string # The end time for the events to be listed. (format: date-time)
  --duration: int # The duration of the events to be listed.
  --event-categories: list<string> # A list of event categories for the source type that you've chosen.
  --filters: list # Filters applied to events. The only valid filter is replication-instance-id. — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, Events: table<SourceIdentifier: string, SourceType: string, Message: string, EventCategories: list, Date: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeEvents")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"SourceIdentifier": $source_identifier, "SourceType": $source_type, "StartTime": $start_time, "EndTime": $end_time, "Duration": $duration, "EventCategories": $event_categories, "Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of the Fleet Advisor collectors in your account.
#
# POST /
# operationId: DescribeFleetAdvisorCollectors
export def "describe-fleet-advisor-collectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  --filters: list # If you specify any of the following filters, the output includes information for only those collectors that meet the filter criteria: collector-referenced-id – The ID of the collector agent, for example d4610ac5-e323-4ad9-bc50-eaf7249dfe9d. collector-name – The name of the collector agent. An example is: describe-fleet-advisor-collectors --filter Name="collector-referenced-id",Values="d4610ac5-e323-4ad9-bc50-eaf7249dfe9d" — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record<Collectors: table<CollectorReferencedId: string, CollectorName: string, CollectorVersion: string, VersionStatus: string, Description: string, S3BucketName: string, ServiceAccessRoleArn: string, CollectorHealthCheck: record, LastDataReceived: string, RegisteredDate: string, CreatedDate: string, ModifiedDate: string, InventoryData: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeFleetAdvisorCollectors")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of Fleet Advisor databases in your account.
#
# POST /
# operationId: DescribeFleetAdvisorDatabases
export def "describe-fleet-advisor-databases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  --filters: list # If you specify any of the following filters, the output includes information for only those databases that meet the filter criteria: database-id – The ID of the database. database-name – The name of the database. database-engine – The name of the database engine. server-ip-address – The IP address of the database server. database-ip-address – The IP address of the database. collector-name – The name of the associated Fleet Advisor collector. An example is: describe-fleet-advisor-databases --filter Name="database-id",Values="45" — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record<Databases: table<DatabaseId: string, DatabaseName: string, IpAddress: string, NumberOfSchemas: int, Server: record, SoftwareDetails: record, Collectors: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeFleetAdvisorDatabases")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides descriptions of large-scale assessment (LSA) analyses produced by your Fleet Advisor collectors.
#
# POST /
# operationId: DescribeFleetAdvisorLsaAnalysis
export def "describe-fleet-advisor-lsa-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32 # required
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record<Analysis: table<LsaAnalysisId: string, Status: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxRecords": $body_max_records, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides descriptions of the schemas discovered by your Fleet Advisor collectors.
#
# POST /
# operationId: DescribeFleetAdvisorSchemaObjectSummary
export def "describe-fleet-advisor-schema-object-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  --filters: list # If you specify any of the following filters, the output includes information for only those schema objects that meet the filter criteria: schema-id – The ID of the schema, for example d4610ac5-e323-4ad9-bc50-eaf7249dfe9d. Example: describe-fleet-advisor-schema-object-summary --filter Name="schema-id",Values="50" — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record<FleetAdvisorSchemaObjects: table<SchemaId: string, ObjectType: string, NumberOfObjects: int, CodeLineCount: int, CodeSize: int>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of schemas detected by Fleet Advisor Collectors in your account.
#
# POST /
# operationId: DescribeFleetAdvisorSchemas
export def "describe-fleet-advisor-schemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34 # required
  --filters: list # If you specify any of the following filters, the output includes information for only those schemas that meet the filter criteria: complexity – The schema's complexity, for example Simple. database-id – The ID of the schema's database. database-ip-address – The IP address of the schema's database. database-name – The name of the schema's database. database-engine – The name of the schema database's engine. original-schema-name – The name of the schema's database's main schema. schema-id – The ID of the schema, for example 15. schema-name – The name of the schema. server-ip-address – The IP address of the schema database's server. An example is: describe-fleet-advisor-schemas --filter Name="schema-id",Values="50" — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record<FleetAdvisorSchemas: table<CodeLineCount: int, CodeSize: int, Complexity: string, Server: record, DatabaseInstance: record, SchemaId: string, SchemaName: string, OriginalSchema: record, Similarity: float>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeFleetAdvisorSchemas")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about the replication instance types that can be created in the specified region.
#
# POST /
# operationId: DescribeOrderableReplicationInstances
export def "describe-orderable-replication-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35 # required
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<OrderableReplicationInstances: table<EngineVersion: string, ReplicationInstanceClass: string, StorageType: string, MinAllocatedStorage: int, MaxAllocatedStorage: int, DefaultAllocatedStorage: int, IncludedAllocatedStorage: int, AvailabilityZones: list, ReleaseStatus: string>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeOrderableReplicationInstances")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# For internal use only
#
# POST /
# operationId: DescribePendingMaintenanceActions
export def "describe-pending-maintenance-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36 # required
  --replication-instance-arn: string # The Amazon Resource Name (ARN) of the replication instance.
  --filters: list # item shape: {Name: string, Values: list<string>}
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
]: any -> oneof<record<PendingMaintenanceActions: table<ResourceIdentifier: string, PendingMaintenanceActionDetails: list>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribePendingMaintenanceActions")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "Filters": $filters, "Marker": $body_marker, "MaxRecords": $body_max_records} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a paginated list of limitations for recommendations of target Amazon Web Services engines.
#
# POST /
# operationId: DescribeRecommendationLimitations
export def "describe-recommendation-limitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  --filters: list # Filters applied to the limitations described in the form of key-value pairs. — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, Fleet Advisor includes a pagination token in the response so that you can retrieve the remaining results. (spec name: MaxRecords)
  --body-next-token: string # Specifies the unique pagination token that makes it possible to display the next page of results. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record<NextToken: string, Limitations: table<DatabaseId: string, EngineName: string, Name: string, Description: string, Impact: string, Type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeRecommendationLimitations")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a paginated list of target engine recommendations for your source databases.
#
# POST /
# operationId: DescribeRecommendations
export def "describe-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38 # required
  --filters: list # Filters applied to the target engine recommendations described in the form of key-value pairs. — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, Fleet Advisor includes a pagination token in the response so that you can retrieve the remaining results. (spec name: MaxRecords)
  --body-next-token: string # Specifies the unique pagination token that makes it possible to display the next page of results. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record<NextToken: string, Recommendations: table<DatabaseId: string, EngineName: string, CreatedDate: string, Status: string, Preferred: bool, Settings: record, Data: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeRecommendations")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the status of the RefreshSchemas operation.
#
# POST /
# operationId: DescribeRefreshSchemasStatus
export def "describe-refresh-schemas-status" [
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
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
]: any -> oneof<record<RefreshSchemasStatus: record<EndpointArn: string, ReplicationInstanceArn: string, Status: string, LastRefreshDate: string, LastFailureMessage: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeRefreshSchemasStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"EndpointArn": $endpoint_arn} | compact
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

# Returns information about the task logs for the specified task.
#
# POST /
# operationId: DescribeReplicationInstanceTaskLogs
export def "describe-replication-instance-task-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<ReplicationInstanceArn: string, ReplicationInstanceTaskLogs: table<ReplicationTaskName: string, ReplicationTaskArn: string, ReplicationInstanceTaskLogSize: int>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about replication instances for your account in the current region.
#
# POST /
# operationId: DescribeReplicationInstances
export def "describe-replication-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41 # required
  --filters: list # Filters applied to replication instances. Valid filter names: replication-instance-arn | replication-instance-id | replication-instance-class | engine-version — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, ReplicationInstances: table<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list, AvailabilityZone: string, ReplicationSubnetGroup: record, PreferredMaintenanceWindow: string, PendingModifiedValues: record, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list, ReplicationInstancePrivateIpAddresses: list, ReplicationInstanceIpv6Addresses: list, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeReplicationInstances")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about the replication subnet groups.
#
# POST /
# operationId: DescribeReplicationSubnetGroups
export def "describe-replication-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  --filters: list # Filters applied to replication subnet groups. Valid filter names: replication-subnet-group-id — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, ReplicationSubnetGroups: table<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeReplicationSubnetGroups")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the task assessment results from the Amazon S3 bucket that DMS creates in your Amazon Web Services account. This action always returns the latest results. For more information about DMS task assessments, see Creating a task assessment report (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.AssessmentReport.html) in the Database Migration Service User Guide.
#
# POST /
# operationId: DescribeReplicationTaskAssessmentResults
export def "describe-replication-task-assessment-results" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  --replication-task-arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the task. When this input parameter is specified, the API returns only one result and ignore the values of the MaxRecords and Marker parameters.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, BucketName: string, ReplicationTaskAssessmentResults: table<ReplicationTaskIdentifier: string, ReplicationTaskArn: string, ReplicationTaskLastAssessmentDate: string, AssessmentStatus: string, AssessmentResultsFile: string, AssessmentResults: string, S3ObjectUrl: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a paginated list of premigration assessment runs based on filter settings. These filter settings can specify a combination of premigration assessment runs, migration tasks, replication instances, and assessment run status values. This operation doesn't return information about individual assessments. For this information, see the DescribeReplicationTaskIndividualAssessments operation.
#
# POST /
# operationId: DescribeReplicationTaskAssessmentRuns
export def "describe-replication-task-assessment-runs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  --filters: list # Filters applied to the premigration assessment runs described in the form of key-value pairs. Valid filter names: replication-task-assessment-run-arn, replication-task-arn, replication-instance-arn, status — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, ReplicationTaskAssessmentRuns: table<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a paginated list of individual assessments based on filter settings. These filter settings can specify a combination of premigration assessment runs, migration tasks, and assessment status values.
#
# POST /
# operationId: DescribeReplicationTaskIndividualAssessments
export def "describe-replication-task-individual-assessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  --filters: list # Filters applied to the individual assessments described in the form of key-value pairs. Valid filter names: replication-task-assessment-run-arn, replication-task-arn, status — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, ReplicationTaskIndividualAssessments: table<ReplicationTaskIndividualAssessmentArn: string, ReplicationTaskAssessmentRunArn: string, IndividualAssessmentName: string, Status: string, ReplicationTaskIndividualAssessmentStartDate: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about replication tasks for your account in the current region.
#
# POST /
# operationId: DescribeReplicationTasks
export def "describe-replication-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  --filters: list # Filters applied to replication tasks. Valid filter names: replication-task-arn | replication-task-id | migration-type | endpoint-arn | replication-instance-arn — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
  --without-settings: oneof<nothing, bool> # An option to set to avoid returning information about settings. Use this to reduce overhead when setting information is too large. To use this option, choose true; otherwise, choose false (the default).
]: any -> oneof<record<Marker: string, ReplicationTasks: table<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record, TaskData: string, TargetReplicationInstanceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeReplicationTasks")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxRecords": $body_max_records, "Marker": $body_marker, "WithoutSettings": $without_settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about the schema for the specified endpoint.
#
# POST /
# operationId: DescribeSchemas
export def "describe-schemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record<Marker: string, Schemas: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeSchemas")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"EndpointArn": $endpoint_arn, "MaxRecords": $body_max_records, "Marker": $body_marker} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted. Note that the "last updated" column the DMS console only indicates the time that DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.
#
# POST /
# operationId: DescribeTableStatistics
export def "describe-table-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 500. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
  --filters: list # Filters applied to table statistics. Valid filter names: schema-name | table-name | table-state A combination of filters creates an AND condition where each record matches all specified filters. — item shape: {Name: string, Values: list<string>}
]: any -> oneof<record<ReplicationTaskArn: string, TableStatistics: table<SchemaName: string, TableName: string, Inserts: int, Deletes: int, Updates: int, Ddls: int, AppliedInserts: int, AppliedDeletes: int, AppliedUpdates: int, AppliedDdls: int, FullLoadRows: int, FullLoadCondtnlChkFailedRows: int, FullLoadErrorRows: int, FullLoadStartTime: string, FullLoadEndTime: string, FullLoadReloaded: bool, LastUpdateTime: string, TableState: string, ValidationPendingRecords: int, ValidationFailedRecords: int, ValidationSuspendedRecords: int, ValidationState: string, ValidationStateDetails: string>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.DescribeTableStatistics")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "MaxRecords": $body_max_records, "Marker": $body_marker, "Filters": $filters} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Uploads the specified certificate.
#
# POST /
# operationId: ImportCertificate
export def "import-certificate" [
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
  certificate_identifier: string # A customer-assigned name for the certificate. Identifiers must begin with a letter and must contain only ASCII letters, digits, and hyphens. They can't end with a hyphen or contain two consecutive hyphens.
  --certificate-pem: string # The contents of a .pem file, which contains an X.509 certificate. (format: password)
  --certificate-wallet: string # The location of an imported Oracle Wallet certificate for use with SSL. Provide the name of a .sso file using the fileb:// prefix. You can't provide the certificate inline. Example: filebase64("${path.root}/rds-ca-2019-root.sso")
  --tags: list # The tags associated with the certificate. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
]: any -> oneof<record<Certificate: record<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ImportCertificate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CertificateIdentifier": $certificate_identifier, "CertificatePem": $certificate_pem, "CertificateWallet": $certificate_wallet, "Tags": $tags} | compact
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

# Lists all metadata tags attached to an DMS resource, including replication instance, endpoint, subnet group, and migration task. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --resource-arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the DMS resource to list tags for. This returns a list of keys (names of tags) created for the resource and their associated tag values.
  --resource-arn-list: list<string> # List of ARNs that identify multiple DMS resources that you want to list tags for. This returns a list of keys (tag names) and their associated tag values. It also returns each tag's associated ResourceArn value, which is the ARN of the resource for which each listed tag is created.
]: any -> oneof<record<TagList: table<Key: string, Value: string, ResourceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "ResourceArnList": $resource_arn_list} | compact
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

# Modifies the specified endpoint. For a MySQL source or target endpoint, don't explicitly specify the database using the DatabaseName request parameter on the ModifyEndpoint API call. Specifying DatabaseName when you modify a MySQL endpoint replicates all the task tables to this single database. For MySQL endpoints, you specify the database only when you specify the schema in the table-mapping rules of the DMS task.
#
# POST /
# operationId: ModifyEndpoint
export def "modify-endpoint" [
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
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
  --endpoint-identifier: string # The database endpoint identifier. Identifiers must begin with a letter and must contain only ASCII letters, digits, and hyphens. They can't end with a hyphen or contain two consecutive hyphens.
  --endpoint-type: string@endpoint-type-completer # The type of endpoint. Valid values are source and target.
  --engine-name: string # The database engine name. Valid values, depending on the EndpointType, include "mysql", "oracle", "postgres", "mariadb", "aurora", "aurora-postgresql", "redshift", "s3", "db2", "db2-zos", "azuredb", "sybase", "dynamodb", "mongodb", "kinesis", "kafka", "elasticsearch", "documentdb", "sqlserver", "neptune", and "babelfish".
  --username: string # The user name to be used to login to the endpoint database.
  --password: string # The password to be used to login to the endpoint database. (format: password)
  --server-name: string # The name of the server where the endpoint database resides.
  --port: int # The port used by the endpoint database.
  --database-name: string # The name of the endpoint database. For a MySQL source or target endpoint, do not specify DatabaseName.
  --extra-connection-attributes: string # Additional attributes associated with the connection. To reset this parameter, pass the empty string ("") as an argument.
  --certificate-arn: string # The Amazon Resource Name (ARN) of the certificate used for SSL connection.
  --ssl-mode: string@ssl-mode-completer # The SSL mode used to connect to the endpoint. The default value is none.
  --service-access-role-arn: string # The Amazon Resource Name (ARN) for the IAM role you want to use to modify the endpoint. The role must allow the iam:PassRole action.
  --external-table-definition: string # The external table definition.
  --dynamo-db-settings: record # Provides the Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role used to define an Amazon DynamoDB target endpoint. — shape: {ServiceAccessRoleArn: string}
  --s3-settings: record # Settings for exporting data to Amazon S3. — shape: {ServiceAccessRoleArn?: string, ExternalTableDefinition?: string, CsvRowDelimiter?: string, CsvDelimiter?: string, BucketFolder?: string, BucketName?: string, CompressionType?: "none"|"gzip", EncryptionMode?: "sse-s3"|"sse-kms", ServerSideEncryptionKmsKeyId?: string, DataFormat?: "csv"|"parquet", EncodingType?: "plain"|"plain-dictionary"|"rle-dictionary", DictPageSizeLimit?: int, RowGroupLength?: int, DataPageSize?: int, ParquetVersion?: "parquet-1-0"|"parquet-2-0", EnableStatistics?: bool, ... (25 more fields)}
  --dms-transfer-settings: record # The settings in JSON format for the DMS Transfer type source endpoint. — shape: {ServiceAccessRoleArn?: string, BucketName?: string}
  --mongo-db-settings: record # Provides information that defines a MongoDB endpoint. — shape: {Username?: string, Password?: string, ServerName?: string, Port?: int, DatabaseName?: string, AuthType?: "no"|"password", AuthMechanism?: "default"|"mongodb_cr"|"scram_sha_1", NestingLevel?: "none"|"one", ExtractDocId?: string, DocsToInvestigate?: string, AuthSource?: string, KmsKeyId?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --kinesis-settings: record # Provides information that describes an Amazon Kinesis Data Stream endpoint. This information includes the output format of records applied to the endpoint and details of transaction and control table data information. — shape: {StreamArn?: string, MessageFormat?: "json"|"json-unformatted", ServiceAccessRoleArn?: string, IncludeTransactionDetails?: bool, IncludePartitionValue?: bool, PartitionIncludeSchemaTable?: bool, IncludeTableAlterOperations?: bool, IncludeControlDetails?: bool, IncludeNullAndEmpty?: bool, NoHexPrefix?: bool}
  --kafka-settings: record # Provides information that describes an Apache Kafka endpoint. This information includes the output format of records applied to the endpoint and details of transaction and control table data information. — shape: {Broker?: string, Topic?: string, MessageFormat?: "json"|"json-unformatted", IncludeTransactionDetails?: bool, IncludePartitionValue?: bool, PartitionIncludeSchemaTable?: bool, IncludeTableAlterOperations?: bool, IncludeControlDetails?: bool, MessageMaxBytes?: int, IncludeNullAndEmpty?: bool, SecurityProtocol?: "plaintext"|"ssl-authentication"|"ssl-encryption"|"sasl-ssl", SslClientCertificateArn?: string, SslClientKeyArn?: string, SslClientKeyPassword?: string, SslCaCertificateArn?: string, ... (4 more fields)}
  --elasticsearch-settings: record # Provides information that defines an OpenSearch endpoint. — shape: {ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage?: int, ErrorRetryDuration?: int, UseNewMappingType?: bool}
  --neptune-settings: record # Provides information that defines an Amazon Neptune endpoint. — shape: {ServiceAccessRoleArn?: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration?: int, MaxFileSize?: int, MaxRetryCount?: int, IamAuthEnabled?: bool}
  --redshift-settings: record # Provides information that defines an Amazon Redshift endpoint. — shape: {AcceptAnyDate?: bool, AfterConnectScript?: string, BucketFolder?: string, BucketName?: string, CaseSensitiveNames?: bool, CompUpdate?: bool, ConnectionTimeout?: int, DatabaseName?: string, DateFormat?: string, EmptyAsNull?: bool, EncryptionMode?: "sse-s3"|"sse-kms", ExplicitIds?: bool, FileTransferUploadStreams?: int, LoadTimeout?: int, MaxFileSize?: int, Password?: string, Port?: int, RemoveQuotes?: bool, ReplaceInvalidChars?: string, ReplaceChars?: string, ServerName?: string, ... (10 more fields)}
  --postgre-sql-settings: record # Provides information that defines a PostgreSQL endpoint. — shape: {AfterConnectScript?: string, CaptureDdls?: bool, MaxFileSize?: int, DatabaseName?: string, DdlArtifactsSchema?: string, ExecuteTimeout?: int, FailTasksOnLobTruncation?: bool, HeartbeatEnable?: bool, HeartbeatSchema?: string, HeartbeatFrequency?: int, Password?: string, Port?: int, ServerName?: string, Username?: string, SlotName?: string, PluginName?: "no-preference"|"test-decoding"|"pglogical", SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string, TrimSpaceInChar?: bool, ... (1 more fields)}
  --my-sql-settings: record # Provides information that defines a MySQL endpoint. — shape: {AfterConnectScript?: string, CleanSourceMetadataOnMismatch?: bool, DatabaseName?: string, EventsPollInterval?: int, TargetDbType?: "specific-database"|"multiple-databases", MaxFileSize?: int, ParallelLoadThreads?: int, Password?: string, Port?: int, ServerName?: string, ServerTimezone?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --oracle-settings: record # Provides information that defines an Oracle endpoint. — shape: {AddSupplementalLogging?: bool, ArchivedLogDestId?: int, AdditionalArchivedLogDestId?: int, ExtraArchivedLogDestIds?: list<int>, AllowSelectNestedTables?: bool, ParallelAsmReadThreads?: int, ReadAheadBlocks?: int, AccessAlternateDirectly?: bool, UseAlternateFolderForOnline?: bool, OraclePathPrefix?: string, UsePathPrefix?: string, ReplacePathPrefix?: bool, EnableHomogenousTablespace?: bool, DirectPathNoLog?: bool, ArchivedLogsOnly?: bool, AsmPassword?: string, AsmServer?: string, AsmUser?: string, ... (24 more fields)}
  --sybase-settings: record # Provides information that defines a SAP ASE endpoint. — shape: {DatabaseName?: string, Password?: string, Port?: int, ServerName?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --microsoft-sql-server-settings: record # Provides information that defines a Microsoft SQL Server endpoint. — shape: {Port?: int, BcpPacketSize?: int, DatabaseName?: string, ControlTablesFileGroup?: string, Password?: string, QuerySingleAlwaysOnNode?: bool, ReadBackupOnly?: bool, SafeguardPolicy?: "rely-on-sql-server-replication-agent"|"exclusive-automatic-truncation"|"shared-automatic-truncation", ServerName?: string, Username?: string, UseBcpFullLoad?: bool, UseThirdPartyBackupDevice?: bool, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string, TrimSpaceInChar?: bool, ... (2 more fields)}
  --ibm-db2-settings: record # Provides information that defines an IBM Db2 LUW endpoint. — shape: {DatabaseName?: string, Password?: string, Port?: int, ServerName?: string, SetDataCaptureChanges?: bool, CurrentLsn?: string, MaxKBytesPerRead?: int, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --doc-db-settings: record # Provides information that defines a DocumentDB endpoint. — shape: {Username?: string, Password?: string, ServerName?: string, Port?: int, DatabaseName?: string, NestingLevel?: "none"|"one", ExtractDocId?: bool, DocsToInvestigate?: int, KmsKeyId?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --redis-settings: record # Provides information that defines a Redis target endpoint. — shape: {ServerName: string, Port: int, SslSecurityProtocol?: "plaintext"|"ssl-encryption", AuthType?: "none"|"auth-role"|"auth-token", AuthUserName?: string, AuthPassword?: string, SslCaCertificateArn?: string}
  --exact-settings: oneof<nothing, bool> # If this attribute is Y, the current call to ModifyEndpoint replaces all existing endpoint settings with the exact settings that you specify in this call. If this attribute is N, the current call to ModifyEndpoint does two things: It replaces any endpoint settings that already exist with new values, for settings with the same names. It creates new endpoint settings that you specify in the call, for settings with different names. For example, if you call create-endpoint ... --endpoint-settings '{"a":1}' ..., the endpoint has the following endpoint settings: '{"a":1}'. If you then call modify-endpoint ... --endpoint-settings '{"b":2}' ... for the same endpoint, the endpoint has the following settings: '{"a":1,"b":2}'. However, suppose that you follow this with a call to modify-endpoint ... --endpoint-settings '{"b":2}' --exact-settings ... for that same endpoint again. Then the endpoint has the following settings: '{"b":2}'. All existing settings are replaced with the exact settings that you specify.
  --gcp-my-sql-settings: record # Settings in JSON format for the source GCP MySQL endpoint. — shape: {AfterConnectScript?: string, CleanSourceMetadataOnMismatch?: bool, DatabaseName?: string, EventsPollInterval?: int, TargetDbType?: "specific-database"|"multiple-databases", MaxFileSize?: int, ParallelLoadThreads?: int, Password?: string, Port?: int, ServerName?: string, ServerTimezone?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
]: any -> oneof<record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ModifyEndpoint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"EndpointArn": $endpoint_arn, "EndpointIdentifier": $endpoint_identifier, "EndpointType": $endpoint_type, "EngineName": $engine_name, "Username": $username, "Password": $password, "ServerName": $server_name, "Port": $port, "DatabaseName": $database_name, "ExtraConnectionAttributes": $extra_connection_attributes, "CertificateArn": $certificate_arn, "SslMode": $ssl_mode, "ServiceAccessRoleArn": $service_access_role_arn, "ExternalTableDefinition": $external_table_definition, "DynamoDbSettings": $dynamo_db_settings, "S3Settings": $s3_settings, "DmsTransferSettings": $dms_transfer_settings, "MongoDbSettings": $mongo_db_settings, "KinesisSettings": $kinesis_settings, "KafkaSettings": $kafka_settings, "ElasticsearchSettings": $elasticsearch_settings, "NeptuneSettings": $neptune_settings, "RedshiftSettings": $redshift_settings, "PostgreSQLSettings": $postgre_sql_settings, "MySQLSettings": $my_sql_settings, "OracleSettings": $oracle_settings, "SybaseSettings": $sybase_settings, "MicrosoftSQLServerSettings": $microsoft_sql_server_settings, "IBMDb2Settings": $ibm_db2_settings, "DocDbSettings": $doc_db_settings, "RedisSettings": $redis_settings, "ExactSettings": $exact_settings, "GcpMySQLSettings": $gcp_my_sql_settings} | compact
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

# Modifies an existing DMS event notification subscription.
#
# POST /
# operationId: ModifyEventSubscription
export def "modify-event-subscription" [
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
  subscription_name: string # The name of the DMS event notification subscription to be modified.
  --sns-topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic created for event notification. The ARN is created by Amazon SNS when you create a topic and subscribe to it.
  --source-type: string # The type of DMS resource that generates the events you want to subscribe to. Valid values: replication-instance | replication-task
  --event-categories: list<string> # A list of event categories for a source type that you want to subscribe to. Use the DescribeEventCategories action to see a list of event categories.
  --enabled: oneof<nothing, bool> # A Boolean value; set to true to activate the subscription.
]: any -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ModifyEventSubscription")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SubscriptionName": $subscription_name, "SnsTopicArn": $sns_topic_arn, "SourceType": $source_type, "EventCategories": $event_categories, "Enabled": $enabled} | compact
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

# Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request. Some settings are applied during the maintenance window.
#
# POST /
# operationId: ModifyReplicationInstance
export def "modify-replication-instance" [
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
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
  --allocated-storage: int # The amount of storage (in gigabytes) to be allocated for the replication instance.
  --apply-immediately: oneof<nothing, bool> # Indicates whether the changes should be applied immediately or during the next maintenance window.
  --replication-instance-class: string # The compute and memory capacity of the replication instance as defined for the specified replication instance class. For example to specify the instance class dms.c4.large, set this parameter to "dms.c4.large". For more information on the settings and capacities for the available replication instance classes, see Selecting the right DMS replication instance for your migration (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_ReplicationInstance.html#CHAP_ReplicationInstance.InDepth).
  --vpc-security-group-ids: list<string> # Specifies the VPC security group to be used with the replication instance. The VPC security group must work with the VPC containing the replication instance.
  --preferred-maintenance-window: string # The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter does not result in an outage, except in the following situation, and the change is asynchronously applied as soon as possible. If moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure pending changes are applied. Default: Uses existing setting Format: ddd:hh24:mi-ddd:hh24:mi Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun Constraints: Must be at least 30 minutes
  --multi-az: oneof<nothing, bool> # Specifies whether the replication instance is a Multi-AZ deployment. You can't set the AvailabilityZone parameter if the Multi-AZ parameter is set to true.
  --engine-version: string # The engine version number of the replication instance. When modifying a major engine version of an instance, also set AllowMajorVersionUpgrade to true.
  --allow-major-version-upgrade: oneof<nothing, bool> # Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage, and the change is asynchronously applied as soon as possible. This parameter must be set to true when specifying a value for the EngineVersion parameter that is a different major version than the replication instance's current version.
  --auto-minor-version-upgrade: oneof<nothing, bool> # A value that indicates that minor version upgrades are applied automatically to the replication instance during the maintenance window. Changing this parameter doesn't result in an outage, except in the case described following. The change is asynchronously applied as soon as possible. An outage does result if these factors apply: This parameter is set to true during the maintenance window. A newer minor version is available. DMS has enabled automatic patching for the given engine version. When AutoMinorVersionUpgrade is enabled, DMS uses the current default engine version when you modify a replication instance. For example, if you set EngineVersion to a lower version number than the current default version, DMS uses the default version. If AutoMinorVersionUpgrade isn’t enabled when you modify a replication instance, DMS uses the engine version specified by the EngineVersion parameter.
  --replication-instance-identifier: string # The replication instance identifier. This parameter is stored as a lowercase string.
  --network-type: string # The type of IP address protocol used by a replication instance, such as IPv4 only or Dual-stack that supports both IPv4 and IPv6 addressing. IPv6 only is not yet supported.
]: any -> oneof<record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ModifyReplicationInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "AllocatedStorage": $allocated_storage, "ApplyImmediately": $apply_immediately, "ReplicationInstanceClass": $replication_instance_class, "VpcSecurityGroupIds": $vpc_security_group_ids, "PreferredMaintenanceWindow": $preferred_maintenance_window, "MultiAZ": $multi_az, "EngineVersion": $engine_version, "AllowMajorVersionUpgrade": $allow_major_version_upgrade, "AutoMinorVersionUpgrade": $auto_minor_version_upgrade, "ReplicationInstanceIdentifier": $replication_instance_identifier, "NetworkType": $network_type} | compact
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

# Modifies the settings for the specified replication subnet group.
#
# POST /
# operationId: ModifyReplicationSubnetGroup
export def "modify-replication-subnet-group" [
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
  replication_subnet_group_identifier: string # The name of the replication instance subnet group.
  --replication-subnet-group-description: string # A description for the replication instance subnet group.
  subnet_ids: list<string> # A list of subnet IDs.
]: any -> oneof<record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, SupportedNetworkTypes: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ModifyReplicationSubnetGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationSubnetGroupIdentifier": $replication_subnet_group_identifier, "ReplicationSubnetGroupDescription": $replication_subnet_group_description, "SubnetIds": $subnet_ids} | compact
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

# Modifies the specified replication task. You can't modify the task endpoints. The task must be stopped before you can modify it. For more information about DMS tasks, see Working with Migration Tasks (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html) in the Database Migration Service User Guide.
#
# POST /
# operationId: ModifyReplicationTask
export def "modify-replication-task" [
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
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task.
  --replication-task-identifier: string # The replication task identifier. Constraints: Must contain 1-255 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  --migration-type: string@migration-type-completer # The migration type. Valid values: full-load | cdc | full-load-and-cdc
  --table-mappings: string # When using the CLI or boto3, provide the path of the JSON file that contains the table mappings. Precede the path with file://. For example, --table-mappings file://mappingfile.json. When working with the DMS API, provide the JSON as the parameter value.
  --replication-task-settings: string # JSON file that contains settings for the task, such as task metadata settings.
  --cdc-start-time: string # Indicates the start time for a change data capture (CDC) operation. Use either CdcStartTime or CdcStartPosition to specify when you want a CDC operation to start. Specifying both values results in an error. Timestamp Example: --cdc-start-time “2018-03-08T12:12:12” (format: date-time)
  --cdc-start-position: string # Indicates when you want a change data capture (CDC) operation to start. Use either CdcStartPosition or CdcStartTime to specify when you want a CDC operation to start. Specifying both values results in an error. The value can be in date, checkpoint, or LSN/SCN format. Date Example: --cdc-start-position “2018-03-08T12:12:12” Checkpoint Example: --cdc-start-position "checkpoint:V1#27#mysql-bin-changelog.157832:1975:-1:2002:677883278264080:mysql-bin-changelog.157832:1876#0#0#*#0#93" LSN Example: --cdc-start-position “mysql-bin-changelog.000024:373” When you use this task setting with a source PostgreSQL database, a logical replication slot should already be created and associated with the source endpoint. You can verify this by setting the slotName extra connection attribute to the name of this logical replication slot. For more information, see Extra Connection Attributes When Using PostgreSQL as a Source for DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.ConnectionAttrib).
  --cdc-stop-position: string # Indicates when you want a change data capture (CDC) operation to stop. The value can be either server time or commit time. Server time example: --cdc-stop-position “server_time:2018-02-09T12:12:12” Commit time example: --cdc-stop-position “commit_time: 2018-02-09T12:12:12“
  --task-data: string # Supplemental information that the task requires to migrate the data for certain source and target endpoints. For more information, see Specifying Supplemental Data for Task Settings (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.TaskData.html) in the Database Migration Service User Guide.
]: any -> oneof<record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ModifyReplicationTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "ReplicationTaskIdentifier": $replication_task_identifier, "MigrationType": $migration_type, "TableMappings": $table_mappings, "ReplicationTaskSettings": $replication_task_settings, "CdcStartTime": $cdc_start_time, "CdcStartPosition": $cdc_start_position, "CdcStopPosition": $cdc_stop_position, "TaskData": $task_data} | compact
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

# Moves a replication task from its current replication instance to a different target replication instance using the specified parameters. The target replication instance must be created with the same or later DMS version as the current replication instance.
#
# POST /
# operationId: MoveReplicationTask
export def "move-replication-task" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the task that you want to move.
  target_replication_instance_arn: string # The ARN of the replication instance where you want to move the task to.
]: any -> oneof<record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.MoveReplicationTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "TargetReplicationInstanceArn": $target_replication_instance_arn} | compact
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

# Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
#
# POST /
# operationId: RebootReplicationInstance
export def "reboot-replication-instance" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
  --force-failover: oneof<nothing, bool> # If this parameter is true, the reboot is conducted through a Multi-AZ failover. If the instance isn't configured for Multi-AZ, then you can't specify true. ( --force-planned-failover and --force-failover can't both be set to true.)
  --force-planned-failover: oneof<nothing, bool> # If this parameter is true, the reboot is conducted through a planned Multi-AZ failover where resources are released and cleaned up prior to conducting the failover. If the instance isn''t configured for Multi-AZ, then you can't specify true. ( --force-planned-failover and --force-failover can't both be set to true.)
]: any -> oneof<record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.RebootReplicationInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "ForceFailover": $force_failover, "ForcePlannedFailover": $force_planned_failover} | compact
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

# Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
#
# POST /
# operationId: RefreshSchemas
export def "refresh-schemas" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
]: any -> oneof<record<RefreshSchemasStatus: record<EndpointArn: string, ReplicationInstanceArn: string, Status: string, LastRefreshDate: string, LastFailureMessage: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.RefreshSchemas")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"EndpointArn": $endpoint_arn, "ReplicationInstanceArn": $replication_instance_arn} | compact
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

# Reloads the target database table with the source data. You can only use this operation with a task in the RUNNING state, otherwise the service will throw an InvalidResourceStateFault exception.
#
# POST /
# operationId: ReloadTables
export def "reload-tables" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task.
  tables_to_reload: list # The name and schema of the table to be reloaded. — item shape: {SchemaName: string, TableName: string}
  --reload-option: string@reload-option-completer # Options for reload. Specify data-reload to reload the data and re-validate it if validation is enabled. Specify validate-only to re-validate the table. This option applies only when validation is enabled for the task. Valid values: data-reload, validate-only Default value is data-reload.
]: any -> oneof<record<ReplicationTaskArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.ReloadTables")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "TablesToReload": $tables_to_reload, "ReloadOption": $reload_option} | compact
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

# Removes metadata tags from an DMS resource, including replication instance, endpoint, subnet group, and migration task. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
#
# POST /
# operationId: RemoveTagsFromResource
export def "remove-tags-from-resource" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  resource_arn: string # An DMS resource from which you want to remove tag(s). The value for this parameter is an Amazon Resource Name (ARN).
  tag_keys: list<string> # The tag key (name) of the tag to be removed.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.RemoveTagsFromResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
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

# Runs large-scale assessment (LSA) analysis on every Fleet Advisor collector in your account.
#
# POST /
# operationId: RunFleetAdvisorLsaAnalysis
export def "run-fleet-advisor-lsa-analysis" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
]: nothing -> oneof<record<LsaAnalysisId: string, Status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis")
  let full_url = (build-url $base "/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Starts the analysis of your source database to provide recommendations of target engines. You can create recommendations for multiple source databases using BatchStartRecommendations (https://docs.aws.amazon.com/dms/latest/APIReference/API_BatchStartRecommendations.html).
#
# POST /
# operationId: StartRecommendations
export def "start-recommendations" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  database_id: string # The identifier of the source database to analyze and provide recommendations for.
  settings: record # Provides information about the required target engine settings. — shape: {InstanceSizingType: string, WorkloadType: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.StartRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DatabaseId": $database_id, "Settings": $settings} | compact
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

# Starts the replication task. For more information about DMS tasks, see Working with Migration Tasks (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html) in the Database Migration Service User Guide.
#
# POST /
# operationId: StartReplicationTask
export def "start-replication-task" [
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task to be started.
  start_replication_task_type: string@start-replication-task-type-completer # The type of replication task to start. When the migration type is full-load or full-load-and-cdc, the only valid value for the first run of the task is start-replication. This option will start the migration. You can also use ReloadTables to reload specific tables that failed during migration instead of restarting the task. The resume-processing option isn't applicable for a full-load task, because you can't resume partially loaded tables during the full load phase. For a full-load-and-cdc task, DMS migrates table data, and then applies data changes that occur on the source. To load all the tables again, and start capturing source changes, use reload-target. Otherwise use resume-processing, to replicate the changes from the last stop position.
  --cdc-start-time: string # Indicates the start time for a change data capture (CDC) operation. Use either CdcStartTime or CdcStartPosition to specify when you want a CDC operation to start. Specifying both values results in an error. Timestamp Example: --cdc-start-time “2018-03-08T12:12:12” (format: date-time)
  --cdc-start-position: string # Indicates when you want a change data capture (CDC) operation to start. Use either CdcStartPosition or CdcStartTime to specify when you want a CDC operation to start. Specifying both values results in an error. The value can be in date, checkpoint, or LSN/SCN format. Date Example: --cdc-start-position “2018-03-08T12:12:12” Checkpoint Example: --cdc-start-position "checkpoint:V1#27#mysql-bin-changelog.157832:1975:-1:2002:677883278264080:mysql-bin-changelog.157832:1876#0#0#*#0#93" LSN Example: --cdc-start-position “mysql-bin-changelog.000024:373” When you use this task setting with a source PostgreSQL database, a logical replication slot should already be created and associated with the source endpoint. You can verify this by setting the slotName extra connection attribute to the name of this logical replication slot. For more information, see Extra Connection Attributes When Using PostgreSQL as a Source for DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.ConnectionAttrib).
  --cdc-stop-position: string # Indicates when you want a change data capture (CDC) operation to stop. The value can be either server time or commit time. Server time example: --cdc-stop-position “server_time:2018-02-09T12:12:12” Commit time example: --cdc-stop-position “commit_time: 2018-02-09T12:12:12“
]: any -> oneof<record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.StartReplicationTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "StartReplicationTaskType": $start_replication_task_type, "CdcStartTime": $cdc_start_time, "CdcStartPosition": $cdc_start_position, "CdcStopPosition": $cdc_stop_position} | compact
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

# Starts the replication task assessment for unsupported data types in the source database. You can only use this operation for a task if the following conditions are true: The task must be in the stopped state. The task must have successful connections to the source and target. If either of these conditions are not met, an InvalidResourceStateFault error will result. For information about DMS task assessments, see Creating a task assessment report (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.AssessmentReport.html) in the Database Migration Service User Guide.
#
# POST /
# operationId: StartReplicationTaskAssessment
export def "start-replication-task-assessment" [
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task.
]: any -> oneof<record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.StartReplicationTaskAssessment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn} | compact
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

# Starts a new premigration assessment run for one or more individual assessments of a migration task. The assessments that you can specify depend on the source and target database engine and the migration type defined for the given task. To run this operation, your migration task must already be created. After you run this operation, you can review the status of each individual assessment. You can also run the migration task manually after the assessment run and its individual assessments complete.
#
# POST /
# operationId: StartReplicationTaskAssessmentRun
export def "start-replication-task-assessment-run" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  replication_task_arn: string # Amazon Resource Name (ARN) of the migration task associated with the premigration assessment run that you want to start.
  service_access_role_arn: string # ARN of the service role needed to start the assessment run. The role must allow the iam:PassRole action.
  result_location_bucket: string # Amazon S3 bucket where you want DMS to store the results of this assessment run.
  --result-location-folder: string # Folder within an Amazon S3 bucket where you want DMS to store the results of this assessment run.
  --result-encryption-mode: string # Encryption mode that you can specify to encrypt the results of this assessment run. If you don't specify this request parameter, DMS stores the assessment run results without encryption. You can specify one of the options following: "SSE_S3" – The server-side encryption provided as a default by Amazon S3. "SSE_KMS" – Key Management Service (KMS) encryption. This encryption can use either a custom KMS encryption key that you specify or the default KMS encryption key that DMS provides.
  --result-kms-key-arn: string # ARN of a custom KMS encryption key that you specify when you set ResultEncryptionMode to "SSE_KMS".
  assessment_run_name: string # Unique name to identify the assessment run.
  --include-only: list<string> # Space-separated list of names for specific individual assessments that you want to include. These names come from the default list of individual assessments that DMS supports for the associated migration task. This task is specified by ReplicationTaskArn. You can't set a value for IncludeOnly if you also set a value for Exclude in the API operation. To identify the names of the default individual assessments that DMS supports for the associated migration task, run the DescribeApplicableIndividualAssessments operation using its own ReplicationTaskArn request parameter.
  --exclude: list<string> # Space-separated list of names for specific individual assessments that you want to exclude. These names come from the default list of individual assessments that DMS supports for the associated migration task. This task is specified by ReplicationTaskArn. You can't set a value for Exclude if you also set a value for IncludeOnly in the API operation. To identify the names of the default individual assessments that DMS supports for the associated migration task, run the DescribeApplicableIndividualAssessments operation using its own ReplicationTaskArn request parameter.
]: any -> oneof<record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.StartReplicationTaskAssessmentRun")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "ServiceAccessRoleArn": $service_access_role_arn, "ResultLocationBucket": $result_location_bucket, "ResultLocationFolder": $result_location_folder, "ResultEncryptionMode": $result_encryption_mode, "ResultKmsKeyArn": $result_kms_key_arn, "AssessmentRunName": $assessment_run_name, "IncludeOnly": $include_only, "Exclude": $exclude} | compact
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

# Stops the replication task.
#
# POST /
# operationId: StopReplicationTask
export def "stop-replication-task" [
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  replication_task_arn: string # The Amazon Resource Name(ARN) of the replication task to be stopped.
]: any -> oneof<record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.StopReplicationTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationTaskArn": $replication_task_arn} | compact
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

# Tests the connection between the replication instance and the endpoint.
#
# POST /
# operationId: TestConnection
export def "test-connection" [
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
]: any -> oneof<record<Connection: record<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.TestConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "EndpointArn": $endpoint_arn} | compact
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

# Migrates 10 active and enabled Amazon SNS subscriptions at a time and converts them to corresponding Amazon EventBridge rules. By default, this operation migrates subscriptions only when all your replication instance versions are 3.4.6 or higher. If any replication instances are from versions earlier than 3.4.6, the operation raises an error and tells you to upgrade these instances to version 3.4.6 or higher. To enable migration regardless of version, set the Force option to true. However, if you don't upgrade instances earlier than version 3.4.6, some types of events might not be available when you use Amazon EventBridge. To call this operation, make sure that you have certain permissions added to your user account. For more information, see Migrating event subscriptions to Amazon EventBridge (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html#CHAP_Events-migrate-to-eventbridge) in the Amazon Web Services Database Migration Service User Guide.
#
# POST /
# operationId: UpdateSubscriptionsToEventBridge
export def "update-subscriptions-to-event-bridge" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  --force-move: oneof<nothing, bool> # When set to true, this operation migrates DMS subscriptions for Amazon SNS notifications no matter what your replication instance version is. If not set or set to false, this operation runs only when all your replication instances are from DMS version 3.4.6 or higher.
]: any -> oneof<record<Result: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonDMSv20160101.UpdateSubscriptionsToEventBridge")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ForceMove": $force_move} | compact
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
