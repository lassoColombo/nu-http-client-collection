# Auto-generated client for Amazon Simple Workflow Service v2012-01-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/swf/2012-01-25/openapi.json
# Auth: --token flag or $env.AMAZON_SIMPLE_WORKFLOW_SERVICE_TOKEN

const BASE_URL = "http://swf.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SIMPLE_WORKFLOW_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://swf.us-east-1.amazonaws.com" "http://swf.us-east-2.amazonaws.com" "http://swf.us-west-1.amazonaws.com" "http://swf.us-west-2.amazonaws.com" "http://swf.us-gov-west-1.amazonaws.com" "http://swf.us-gov-east-1.amazonaws.com" "http://swf.ca-central-1.amazonaws.com" "http://swf.eu-north-1.amazonaws.com" "http://swf.eu-west-1.amazonaws.com" "http://swf.eu-west-2.amazonaws.com" "http://swf.eu-west-3.amazonaws.com" "http://swf.eu-central-1.amazonaws.com" "http://swf.eu-south-1.amazonaws.com" "http://swf.af-south-1.amazonaws.com" "http://swf.ap-northeast-1.amazonaws.com" "http://swf.ap-northeast-2.amazonaws.com" "http://swf.ap-northeast-3.amazonaws.com" "http://swf.ap-southeast-1.amazonaws.com" "http://swf.ap-southeast-2.amazonaws.com" "http://swf.ap-east-1.amazonaws.com" "http://swf.ap-south-1.amazonaws.com" "http://swf.sa-east-1.amazonaws.com" "http://swf.me-south-1.amazonaws.com" "https://swf.us-east-1.amazonaws.com" "https://swf.us-east-2.amazonaws.com" "https://swf.us-west-1.amazonaws.com" "https://swf.us-west-2.amazonaws.com" "https://swf.us-gov-west-1.amazonaws.com" "https://swf.us-gov-east-1.amazonaws.com" "https://swf.ca-central-1.amazonaws.com" "https://swf.eu-north-1.amazonaws.com" "https://swf.eu-west-1.amazonaws.com" "https://swf.eu-west-2.amazonaws.com" "https://swf.eu-west-3.amazonaws.com" "https://swf.eu-central-1.amazonaws.com" "https://swf.eu-south-1.amazonaws.com" "https://swf.af-south-1.amazonaws.com" "https://swf.ap-northeast-1.amazonaws.com" "https://swf.ap-northeast-2.amazonaws.com" "https://swf.ap-northeast-3.amazonaws.com" "https://swf.ap-southeast-1.amazonaws.com" "https://swf.ap-southeast-2.amazonaws.com" "https://swf.ap-east-1.amazonaws.com" "https://swf.ap-south-1.amazonaws.com" "https://swf.sa-east-1.amazonaws.com" "https://swf.me-south-1.amazonaws.com" "http://swf.cn-north-1.amazonaws.com.cn" "http://swf.cn-northwest-1.amazonaws.com.cn" "https://swf.cn-north-1.amazonaws.com.cn" "https://swf.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["SimpleWorkflowService.CountClosedWorkflowExecutions"] }
def x-amz-target-completer-1 [] { ["SimpleWorkflowService.CountOpenWorkflowExecutions"] }
def x-amz-target-completer-2 [] { ["SimpleWorkflowService.CountPendingActivityTasks"] }
def x-amz-target-completer-3 [] { ["SimpleWorkflowService.CountPendingDecisionTasks"] }
def x-amz-target-completer-4 [] { ["SimpleWorkflowService.DeprecateActivityType"] }
def x-amz-target-completer-5 [] { ["SimpleWorkflowService.DeprecateDomain"] }
def x-amz-target-completer-6 [] { ["SimpleWorkflowService.DeprecateWorkflowType"] }
def x-amz-target-completer-7 [] { ["SimpleWorkflowService.DescribeActivityType"] }
def x-amz-target-completer-8 [] { ["SimpleWorkflowService.DescribeDomain"] }
def x-amz-target-completer-9 [] { ["SimpleWorkflowService.DescribeWorkflowExecution"] }
def x-amz-target-completer-10 [] { ["SimpleWorkflowService.DescribeWorkflowType"] }
def x-amz-target-completer-11 [] { ["SimpleWorkflowService.GetWorkflowExecutionHistory"] }
def registration-status-completer [] { ["DEPRECATED" "REGISTERED"] }
def x-amz-target-completer-12 [] { ["SimpleWorkflowService.ListActivityTypes"] }
def x-amz-target-completer-13 [] { ["SimpleWorkflowService.ListClosedWorkflowExecutions"] }
def x-amz-target-completer-14 [] { ["SimpleWorkflowService.ListDomains"] }
def x-amz-target-completer-15 [] { ["SimpleWorkflowService.ListOpenWorkflowExecutions"] }
def x-amz-target-completer-16 [] { ["SimpleWorkflowService.ListTagsForResource"] }
def x-amz-target-completer-17 [] { ["SimpleWorkflowService.ListWorkflowTypes"] }
def x-amz-target-completer-18 [] { ["SimpleWorkflowService.PollForActivityTask"] }
def x-amz-target-completer-19 [] { ["SimpleWorkflowService.PollForDecisionTask"] }
def x-amz-target-completer-20 [] { ["SimpleWorkflowService.RecordActivityTaskHeartbeat"] }
def x-amz-target-completer-21 [] { ["SimpleWorkflowService.RegisterActivityType"] }
def x-amz-target-completer-22 [] { ["SimpleWorkflowService.RegisterDomain"] }
def default-child-policy-completer [] { ["ABANDON" "REQUEST_CANCEL" "TERMINATE"] }
def x-amz-target-completer-23 [] { ["SimpleWorkflowService.RegisterWorkflowType"] }
def x-amz-target-completer-24 [] { ["SimpleWorkflowService.RequestCancelWorkflowExecution"] }
def x-amz-target-completer-25 [] { ["SimpleWorkflowService.RespondActivityTaskCanceled"] }
def x-amz-target-completer-26 [] { ["SimpleWorkflowService.RespondActivityTaskCompleted"] }
def x-amz-target-completer-27 [] { ["SimpleWorkflowService.RespondActivityTaskFailed"] }
def x-amz-target-completer-28 [] { ["SimpleWorkflowService.RespondDecisionTaskCompleted"] }
def x-amz-target-completer-29 [] { ["SimpleWorkflowService.SignalWorkflowExecution"] }
def child-policy-completer [] { ["ABANDON" "REQUEST_CANCEL" "TERMINATE"] }
def x-amz-target-completer-30 [] { ["SimpleWorkflowService.StartWorkflowExecution"] }
def x-amz-target-completer-31 [] { ["SimpleWorkflowService.TagResource"] }
def x-amz-target-completer-32 [] { ["SimpleWorkflowService.TerminateWorkflowExecution"] }
def x-amz-target-completer-33 [] { ["SimpleWorkflowService.UndeprecateActivityType"] }
def x-amz-target-completer-34 [] { ["SimpleWorkflowService.UndeprecateDomain"] }
def x-amz-target-completer-35 [] { ["SimpleWorkflowService.UndeprecateWorkflowType"] }
def x-amz-target-completer-36 [] { ["SimpleWorkflowService.UntagResource"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["count-closed-workflow-executions" "count-open-workflow-executions" "count-pending-activity-tasks" "count-pending-decision-tasks" "deprecate-activity-type" "deprecate-domain" "deprecate-workflow-type" "describe-activity-type" "describe-domain" "describe-workflow-execution" "describe-workflow-type" "get-workflow-execution-history" "list-activity-types" "list-closed-workflow-executions" "list-domains" "list-open-workflow-executions" "list-tags-for-resource" "list-workflow-types" "poll-for-activity-task" "poll-for-decision-task" "record-activity-task-heartbeat" "register-activity-type" "register-domain" "register-workflow-type" "request-cancel-workflow-execution" "respond-activity-task-canceled" "respond-activity-task-completed" "respond-activity-task-failed" "respond-decision-task-completed" "signal-workflow-execution" "start-workflow-execution" "tag-resource" "terminate-workflow-execution" "undeprecate-activity-type" "undeprecate-domain" "undeprecate-workflow-type" "untag-resource" "commands"] | sort) } | get name | first)
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

# Returns the number of closed workflow executions within the given domain that meet the specified filtering criteria. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. tagFilter.tag: String constraint. The key is swf:tagFilter.tag. typeFilter.name: String constraint. The key is swf:typeFilter.name. typeFilter.version: String constraint. The key is swf:typeFilter.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: CountClosedWorkflowExecutions
export def "count-closed-workflow-executions" [
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
  domain: string # The name of the domain containing the workflow executions to count.
  --start-time-filter: record # Used to filter the workflow executions in visibility APIs by various time-based rules. Each parameter, if specified, defines a rule that must be satisfied by each returned query result. The parameter values are in the Unix Time format (https://en.wikipedia.org/wiki/Unix_time). For example: "oldestDate": 1325376070. — shape: {oldestDate: string, latestDate?: string}
  --close-time-filter: record # Used to filter the workflow executions in visibility APIs by various time-based rules. Each parameter, if specified, defines a rule that must be satisfied by each returned query result. The parameter values are in the Unix Time format (https://en.wikipedia.org/wiki/Unix_time). For example: "oldestDate": 1325376070. — shape: {oldestDate: string, latestDate?: string}
  --execution-filter: record # Used to filter the workflow executions in visibility APIs by their workflowId. — shape: {workflowId: string}
  --type-filter: record # Used to filter workflow execution query results by type. Each parameter, if specified, defines a rule that must be satisfied by each returned result. — shape: {name: string, version?: string}
  --tag-filter: record # Used to filter the workflow executions in visibility APIs based on a tag. — shape: {tag: string}
  --close-status-filter: record # Used to filter the closed workflow executions in visibility APIs by their close status. — shape: {status: "COMPLETED"|"FAILED"|"CANCELED"|"TERMINATED"|"CONTINUED_AS_NEW"|"TIMED_OUT"}
]: any -> oneof<record<count: int, truncated: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.CountClosedWorkflowExecutions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "startTimeFilter": $start_time_filter, "closeTimeFilter": $close_time_filter, "executionFilter": $execution_filter, "typeFilter": $type_filter, "tagFilter": $tag_filter, "closeStatusFilter": $close_status_filter} | compact
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

# Returns the number of open workflow executions within the given domain that meet the specified filtering criteria. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. tagFilter.tag: String constraint. The key is swf:tagFilter.tag. typeFilter.name: String constraint. The key is swf:typeFilter.name. typeFilter.version: String constraint. The key is swf:typeFilter.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: CountOpenWorkflowExecutions
export def "count-open-workflow-executions" [
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
  domain: string # The name of the domain containing the workflow executions to count.
  start_time_filter: record # Used to filter the workflow executions in visibility APIs by various time-based rules. Each parameter, if specified, defines a rule that must be satisfied by each returned query result. The parameter values are in the Unix Time format (https://en.wikipedia.org/wiki/Unix_time). For example: "oldestDate": 1325376070. — shape: {oldestDate: string, latestDate?: string}
  --type-filter: record # Used to filter workflow execution query results by type. Each parameter, if specified, defines a rule that must be satisfied by each returned result. — shape: {name: string, version?: string}
  --tag-filter: record # Used to filter the workflow executions in visibility APIs based on a tag. — shape: {tag: string}
  --execution-filter: record # Used to filter the workflow executions in visibility APIs by their workflowId. — shape: {workflowId: string}
]: any -> oneof<record<count: int, truncated: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.CountOpenWorkflowExecutions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "startTimeFilter": $start_time_filter, "typeFilter": $type_filter, "tagFilter": $tag_filter, "executionFilter": $execution_filter} | compact
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

# Returns the estimated number of activity tasks in the specified task list. The count returned is an approximation and isn't guaranteed to be exact. If you specify a task list that no activity task was ever scheduled in then 0 is returned. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the taskList.name parameter by using a Condition element with the swf:taskList.name key to allow the action to access only certain task lists. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: CountPendingActivityTasks
export def "count-pending-activity-tasks" [
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
  domain: string # The name of the domain that contains the task list.
  task_list: record # Represents a task list. — shape: {name: string}
]: any -> oneof<record<count: int, truncated: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.CountPendingActivityTasks")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "taskList": $task_list} | compact
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

# Returns the estimated number of decision tasks in the specified task list. The count returned is an approximation and isn't guaranteed to be exact. If you specify a task list that no decision task was ever scheduled in then 0 is returned. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the taskList.name parameter by using a Condition element with the swf:taskList.name key to allow the action to access only certain task lists. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: CountPendingDecisionTasks
export def "count-pending-decision-tasks" [
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
  domain: string # The name of the domain that contains the task list.
  task_list: record # Represents a task list. — shape: {name: string}
]: any -> oneof<record<count: int, truncated: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.CountPendingDecisionTasks")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "taskList": $task_list} | compact
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

# Deprecates the specified activity type. After an activity type has been deprecated, you cannot create new tasks of that activity type. Tasks of this type that were scheduled before the type was deprecated continue to run. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. activityType.name: String constraint. The key is swf:activityType.name. activityType.version: String constraint. The key is swf:activityType.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: DeprecateActivityType
export def "deprecate-activity-type" [
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
  domain: string # The name of the domain in which the activity type is registered.
  activity_type: record # Represents an activity type. — shape: {name: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.DeprecateActivityType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "activityType": $activity_type} | compact
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

# Deprecates the specified domain. After a domain has been deprecated it cannot be used to create new workflow executions or register new types. However, you can still use visibility actions on this domain. Deprecating a domain also deprecates all activity and workflow types registered in the domain. Executions that were started before the domain was deprecated continues to run. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: DeprecateDomain
export def "deprecate-domain" [
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
  name: string # The name of the domain to deprecate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.DeprecateDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
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

# Deprecates the specified workflow type. After a workflow type has been deprecated, you cannot create new executions of that type. Executions that were started before the type was deprecated continues to run. A deprecated workflow type may still be used when calling visibility actions. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. workflowType.name: String constraint. The key is swf:workflowType.name. workflowType.version: String constraint. The key is swf:workflowType.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: DeprecateWorkflowType
export def "deprecate-workflow-type" [
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
  domain: string # The name of the domain in which the workflow type is registered.
  workflow_type: record # Represents a workflow type. — shape: {name: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.DeprecateWorkflowType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "workflowType": $workflow_type} | compact
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

# Returns information about the specified activity type. This includes configuration settings provided when the type was registered and other general information about the type. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. activityType.name: String constraint. The key is swf:activityType.name. activityType.version: String constraint. The key is swf:activityType.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: DescribeActivityType
export def "describe-activity-type" [
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
  domain: string # The name of the domain in which the activity type is registered.
  activity_type: record # Represents an activity type. — shape: {name: string, version: string}
]: any -> oneof<record<typeInfo: record<activityType: record<name: string, version: string>, status: string, description: string, creationDate: string, deprecationDate: string>, configuration: record<defaultTaskStartToCloseTimeout: string, defaultTaskHeartbeatTimeout: string, defaultTaskList: record<name: string>, defaultTaskPriority: string, defaultTaskScheduleToStartTimeout: string, defaultTaskScheduleToCloseTimeout: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.DescribeActivityType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "activityType": $activity_type} | compact
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

# Returns information about the specified domain, including description and status. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: DescribeDomain
export def "describe-domain" [
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
  name: string # The name of the domain to describe.
]: any -> oneof<record<domainInfo: record<name: string, status: string, description: string, arn: string>, configuration: record<workflowExecutionRetentionPeriodInDays: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.DescribeDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
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

# Returns information about the specified workflow execution including its type and some statistics. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: DescribeWorkflowExecution
export def "describe-workflow-execution" [
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
  domain: string # The name of the domain containing the workflow execution.
  execution: record # Represents a workflow execution. — shape: {workflowId: string, runId: string}
]: any -> oneof<record<executionInfo: record<execution: record<workflowId: string, runId: string>, workflowType: record<name: string, version: string>, startTimestamp: string, closeTimestamp: string, executionStatus: string, closeStatus: string, parent: record<workflowId: string, runId: string>, tagList: list<string>, cancelRequested: bool>, executionConfiguration: record<taskStartToCloseTimeout: string, executionStartToCloseTimeout: string, taskList: record<name: string>, taskPriority: string, childPolicy: string, lambdaRole: string>, openCounts: record<openActivityTasks: int, openDecisionTasks: int, openTimers: int, openChildWorkflowExecutions: int, openLambdaFunctions: int>, latestActivityTaskTimestamp: string, latestExecutionContext: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.DescribeWorkflowExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "execution": $execution} | compact
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

# Returns information about the specified workflow type. This includes configuration settings specified when the type was registered and other information such as creation date, current status, etc. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. workflowType.name: String constraint. The key is swf:workflowType.name. workflowType.version: String constraint. The key is swf:workflowType.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: DescribeWorkflowType
export def "describe-workflow-type" [
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
  domain: string # The name of the domain in which this workflow type is registered.
  workflow_type: record # Represents a workflow type. — shape: {name: string, version: string}
]: any -> oneof<record<typeInfo: record<workflowType: record<name: string, version: string>, status: string, description: string, creationDate: string, deprecationDate: string>, configuration: record<defaultTaskStartToCloseTimeout: string, defaultExecutionStartToCloseTimeout: string, defaultTaskList: record<name: string>, defaultTaskPriority: string, defaultChildPolicy: string, defaultLambdaRole: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.DescribeWorkflowType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "workflowType": $workflow_type} | compact
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

# Returns the history of the specified workflow execution. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: GetWorkflowExecutionHistory
export def "get-workflow-execution-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximum-page-size: string # Pagination limit
  --next-page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11 # required
  domain: string # The name of the domain containing the workflow execution.
  execution: record # Represents a workflow execution. — shape: {workflowId: string, runId: string}
  --body-next-page-token: string # If NextPageToken is returned there are more results available. The value of NextPageToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 60 seconds. Using an expired pagination token will return a 400 error: "Specified token has exceeded its maximum lifetime". The configured maximumPageSize determines how many results can be returned in a single call. (spec name: nextPageToken)
  --body-maximum-page-size: int # The maximum number of results that are returned per call. Use nextPageToken to obtain further pages of results. (spec name: maximumPageSize)
  --reverse-order: oneof<nothing, bool> # When set to true, returns the events in reverse order. By default the results are returned in ascending order of the eventTimeStamp of the events.
]: any -> oneof<record<events: table<eventTimestamp: string, eventType: string, eventId: int, workflowExecutionStartedEventAttributes: record, workflowExecutionCompletedEventAttributes: record, completeWorkflowExecutionFailedEventAttributes: record, workflowExecutionFailedEventAttributes: record, failWorkflowExecutionFailedEventAttributes: record, workflowExecutionTimedOutEventAttributes: record, workflowExecutionCanceledEventAttributes: record, cancelWorkflowExecutionFailedEventAttributes: record, workflowExecutionContinuedAsNewEventAttributes: record, continueAsNewWorkflowExecutionFailedEventAttributes: record, workflowExecutionTerminatedEventAttributes: record, workflowExecutionCancelRequestedEventAttributes: record, decisionTaskScheduledEventAttributes: record, decisionTaskStartedEventAttributes: record, decisionTaskCompletedEventAttributes: record, decisionTaskTimedOutEventAttributes: record, activityTaskScheduledEventAttributes: record, activityTaskStartedEventAttributes: record, activityTaskCompletedEventAttributes: record, activityTaskFailedEventAttributes: record, activityTaskTimedOutEventAttributes: record, activityTaskCanceledEventAttributes: record, activityTaskCancelRequestedEventAttributes: record, workflowExecutionSignaledEventAttributes: record, markerRecordedEventAttributes: record, recordMarkerFailedEventAttributes: record, timerStartedEventAttributes: record, timerFiredEventAttributes: record, timerCanceledEventAttributes: record, startChildWorkflowExecutionInitiatedEventAttributes: record, childWorkflowExecutionStartedEventAttributes: record, childWorkflowExecutionCompletedEventAttributes: record, childWorkflowExecutionFailedEventAttributes: record, childWorkflowExecutionTimedOutEventAttributes: record, childWorkflowExecutionCanceledEventAttributes: record, childWorkflowExecutionTerminatedEventAttributes: record, signalExternalWorkflowExecutionInitiatedEventAttributes: record, externalWorkflowExecutionSignaledEventAttributes: record, signalExternalWorkflowExecutionFailedEventAttributes: record, externalWorkflowExecutionCancelRequestedEventAttributes: record, requestCancelExternalWorkflowExecutionInitiatedEventAttributes: record, requestCancelExternalWorkflowExecutionFailedEventAttributes: record, scheduleActivityTaskFailedEventAttributes: record, requestCancelActivityTaskFailedEventAttributes: record, startTimerFailedEventAttributes: record, cancelTimerFailedEventAttributes: record, startChildWorkflowExecutionFailedEventAttributes: record, lambdaFunctionScheduledEventAttributes: record, lambdaFunctionStartedEventAttributes: record, lambdaFunctionCompletedEventAttributes: record, lambdaFunctionFailedEventAttributes: record, lambdaFunctionTimedOutEventAttributes: record, scheduleLambdaFunctionFailedEventAttributes: record, startLambdaFunctionFailedEventAttributes: record>, nextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.GetWorkflowExecutionHistory")
  let qp = [(serialize-qp "maximumPageSize" $maximum_page_size "scalar") (serialize-qp "nextPageToken" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"domain": $domain, "execution": $execution, "nextPageToken": $body_next_page_token, "maximumPageSize": $body_maximum_page_size, "reverseOrder": $reverse_order} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maximumPageSize": $maximum_page_size, "nextPageToken": $next_page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about all activities registered in the specified domain that match the specified name and registration status. The result includes information like creation date, current status of the activity, etc. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: ListActivityTypes
export def "list-activity-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximum-page-size: string # Pagination limit
  --next-page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12 # required
  domain: string # The name of the domain in which the activity types have been registered.
  --name: string # If specified, only lists the activity types that have this name.
  registration_status: string@registration-status-completer # Specifies the registration status of the activity types to list.
  --body-next-page-token: string # If NextPageToken is returned there are more results available. The value of NextPageToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 60 seconds. Using an expired pagination token will return a 400 error: "Specified token has exceeded its maximum lifetime". The configured maximumPageSize determines how many results can be returned in a single call. (spec name: nextPageToken)
  --body-maximum-page-size: int # The maximum number of results that are returned per call. Use nextPageToken to obtain further pages of results. (spec name: maximumPageSize)
  --reverse-order: oneof<nothing, bool> # When set to true, returns the results in reverse order. By default, the results are returned in ascending alphabetical order by name of the activity types.
]: any -> oneof<record<typeInfos: table<activityType: record, status: string, description: string, creationDate: string, deprecationDate: string>, nextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.ListActivityTypes")
  let qp = [(serialize-qp "maximumPageSize" $maximum_page_size "scalar") (serialize-qp "nextPageToken" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"domain": $domain, "name": $name, "registrationStatus": $registration_status, "nextPageToken": $body_next_page_token, "maximumPageSize": $body_maximum_page_size, "reverseOrder": $reverse_order} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maximumPageSize": $maximum_page_size, "nextPageToken": $next_page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of closed workflow executions in the specified domain that meet the filtering criteria. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. tagFilter.tag: String constraint. The key is swf:tagFilter.tag. typeFilter.name: String constraint. The key is swf:typeFilter.name. typeFilter.version: String constraint. The key is swf:typeFilter.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: ListClosedWorkflowExecutions
export def "list-closed-workflow-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximum-page-size: string # Pagination limit
  --next-page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13 # required
  domain: string # The name of the domain that contains the workflow executions to list.
  --start-time-filter: record # Used to filter the workflow executions in visibility APIs by various time-based rules. Each parameter, if specified, defines a rule that must be satisfied by each returned query result. The parameter values are in the Unix Time format (https://en.wikipedia.org/wiki/Unix_time). For example: "oldestDate": 1325376070. — shape: {oldestDate: string, latestDate?: string}
  --close-time-filter: record # Used to filter the workflow executions in visibility APIs by various time-based rules. Each parameter, if specified, defines a rule that must be satisfied by each returned query result. The parameter values are in the Unix Time format (https://en.wikipedia.org/wiki/Unix_time). For example: "oldestDate": 1325376070. — shape: {oldestDate: string, latestDate?: string}
  --execution-filter: record # Used to filter the workflow executions in visibility APIs by their workflowId. — shape: {workflowId: string}
  --close-status-filter: record # Used to filter the closed workflow executions in visibility APIs by their close status. — shape: {status: "COMPLETED"|"FAILED"|"CANCELED"|"TERMINATED"|"CONTINUED_AS_NEW"|"TIMED_OUT"}
  --type-filter: record # Used to filter workflow execution query results by type. Each parameter, if specified, defines a rule that must be satisfied by each returned result. — shape: {name: string, version?: string}
  --tag-filter: record # Used to filter the workflow executions in visibility APIs based on a tag. — shape: {tag: string}
  --body-next-page-token: string # If NextPageToken is returned there are more results available. The value of NextPageToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 60 seconds. Using an expired pagination token will return a 400 error: "Specified token has exceeded its maximum lifetime". The configured maximumPageSize determines how many results can be returned in a single call. (spec name: nextPageToken)
  --body-maximum-page-size: int # The maximum number of results that are returned per call. Use nextPageToken to obtain further pages of results. (spec name: maximumPageSize)
  --reverse-order: oneof<nothing, bool> # When set to true, returns the results in reverse order. By default the results are returned in descending order of the start or the close time of the executions.
]: any -> oneof<record<executionInfos: table<execution: record, workflowType: record, startTimestamp: string, closeTimestamp: string, executionStatus: string, closeStatus: string, parent: record, tagList: list, cancelRequested: bool>, nextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.ListClosedWorkflowExecutions")
  let qp = [(serialize-qp "maximumPageSize" $maximum_page_size "scalar") (serialize-qp "nextPageToken" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"domain": $domain, "startTimeFilter": $start_time_filter, "closeTimeFilter": $close_time_filter, "executionFilter": $execution_filter, "closeStatusFilter": $close_status_filter, "typeFilter": $type_filter, "tagFilter": $tag_filter, "nextPageToken": $body_next_page_token, "maximumPageSize": $body_maximum_page_size, "reverseOrder": $reverse_order} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maximumPageSize": $maximum_page_size, "nextPageToken": $next_page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the list of domains registered in the account. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. The element must be set to arn:aws:swf::AccountID:domain/*, where AccountID is the account ID, with no dashes. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: ListDomains
export def "list-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximum-page-size: string # Pagination limit
  --next-page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14 # required
  --body-next-page-token: string # If NextPageToken is returned there are more results available. The value of NextPageToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 60 seconds. Using an expired pagination token will return a 400 error: "Specified token has exceeded its maximum lifetime". The configured maximumPageSize determines how many results can be returned in a single call. (spec name: nextPageToken)
  registration_status: string@registration-status-completer # Specifies the registration status of the domains to list.
  --body-maximum-page-size: int # The maximum number of results that are returned per call. Use nextPageToken to obtain further pages of results. (spec name: maximumPageSize)
  --reverse-order: oneof<nothing, bool> # When set to true, returns the results in reverse order. By default, the results are returned in ascending alphabetical order by name of the domains.
]: any -> oneof<record<domainInfos: table<name: string, status: string, description: string, arn: string>, nextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.ListDomains")
  let qp = [(serialize-qp "maximumPageSize" $maximum_page_size "scalar") (serialize-qp "nextPageToken" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextPageToken": $body_next_page_token, "registrationStatus": $registration_status, "maximumPageSize": $body_maximum_page_size, "reverseOrder": $reverse_order} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maximumPageSize": $maximum_page_size, "nextPageToken": $next_page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of open workflow executions in the specified domain that meet the filtering criteria. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. tagFilter.tag: String constraint. The key is swf:tagFilter.tag. typeFilter.name: String constraint. The key is swf:typeFilter.name. typeFilter.version: String constraint. The key is swf:typeFilter.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: ListOpenWorkflowExecutions
export def "list-open-workflow-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximum-page-size: string # Pagination limit
  --next-page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15 # required
  domain: string # The name of the domain that contains the workflow executions to list.
  start_time_filter: record # Used to filter the workflow executions in visibility APIs by various time-based rules. Each parameter, if specified, defines a rule that must be satisfied by each returned query result. The parameter values are in the Unix Time format (https://en.wikipedia.org/wiki/Unix_time). For example: "oldestDate": 1325376070. — shape: {oldestDate: string, latestDate?: string}
  --type-filter: record # Used to filter workflow execution query results by type. Each parameter, if specified, defines a rule that must be satisfied by each returned result. — shape: {name: string, version?: string}
  --tag-filter: record # Used to filter the workflow executions in visibility APIs based on a tag. — shape: {tag: string}
  --body-next-page-token: string # If NextPageToken is returned there are more results available. The value of NextPageToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 60 seconds. Using an expired pagination token will return a 400 error: "Specified token has exceeded its maximum lifetime". The configured maximumPageSize determines how many results can be returned in a single call. (spec name: nextPageToken)
  --body-maximum-page-size: int # The maximum number of results that are returned per call. Use nextPageToken to obtain further pages of results. (spec name: maximumPageSize)
  --reverse-order: oneof<nothing, bool> # When set to true, returns the results in reverse order. By default the results are returned in descending order of the start time of the executions.
  --execution-filter: record # Used to filter the workflow executions in visibility APIs by their workflowId. — shape: {workflowId: string}
]: any -> oneof<record<executionInfos: table<execution: record, workflowType: record, startTimestamp: string, closeTimestamp: string, executionStatus: string, closeStatus: string, parent: record, tagList: list, cancelRequested: bool>, nextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.ListOpenWorkflowExecutions")
  let qp = [(serialize-qp "maximumPageSize" $maximum_page_size "scalar") (serialize-qp "nextPageToken" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"domain": $domain, "startTimeFilter": $start_time_filter, "typeFilter": $type_filter, "tagFilter": $tag_filter, "nextPageToken": $body_next_page_token, "maximumPageSize": $body_maximum_page_size, "reverseOrder": $reverse_order, "executionFilter": $execution_filter} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maximumPageSize": $maximum_page_size, "nextPageToken": $next_page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List tags for a given domain.
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  resource_arn: string # The Amazon Resource Name (ARN) for the Amazon SWF domain.
]: any -> oneof<record<tags: table<key: string, value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.ListTagsForResource")
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

# Returns information about workflow types in the specified domain. The results may be split into multiple pages that can be retrieved by making the call repeatedly. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: ListWorkflowTypes
export def "list-workflow-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximum-page-size: string # Pagination limit
  --next-page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  domain: string # The name of the domain in which the workflow types have been registered.
  --name: string # If specified, lists the workflow type with this name.
  registration_status: string@registration-status-completer # Specifies the registration status of the workflow types to list.
  --body-next-page-token: string # If NextPageToken is returned there are more results available. The value of NextPageToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 60 seconds. Using an expired pagination token will return a 400 error: "Specified token has exceeded its maximum lifetime". The configured maximumPageSize determines how many results can be returned in a single call. (spec name: nextPageToken)
  --body-maximum-page-size: int # The maximum number of results that are returned per call. Use nextPageToken to obtain further pages of results. (spec name: maximumPageSize)
  --reverse-order: oneof<nothing, bool> # When set to true, returns the results in reverse order. By default the results are returned in ascending alphabetical order of the name of the workflow types.
]: any -> oneof<record<typeInfos: table<workflowType: record, status: string, description: string, creationDate: string, deprecationDate: string>, nextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.ListWorkflowTypes")
  let qp = [(serialize-qp "maximumPageSize" $maximum_page_size "scalar") (serialize-qp "nextPageToken" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"domain": $domain, "name": $name, "registrationStatus": $registration_status, "nextPageToken": $body_next_page_token, "maximumPageSize": $body_maximum_page_size, "reverseOrder": $reverse_order} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maximumPageSize": $maximum_page_size, "nextPageToken": $next_page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Used by workers to get an ActivityTask from the specified activity taskList. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available. The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns an empty result. An empty result, in this context, means that an ActivityTask is returned, but that the value of taskToken is an empty string. If a task is returned, the worker should use its type to identify and process it correctly. Workers should set their client side socket timeout to at least 70 seconds (10 seconds higher than the maximum time service may hold the poll request). Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the taskList.name parameter by using a Condition element with the swf:taskList.name key to allow the action to access only certain task lists. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: PollForActivityTask
export def "poll-for-activity-task" [
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
  domain: string # The name of the domain that contains the task lists being polled.
  task_list: record # Represents a task list. — shape: {name: string}
  --identity: string # Identity of the worker making the request, recorded in the ActivityTaskStarted event in the workflow history. This enables diagnostic tracing when problems arise. The form of this identity is user defined.
]: any -> oneof<record<taskToken: string, activityId: string, startedEventId: int, workflowExecution: record<workflowId: string, runId: string>, activityType: record<name: string, version: string>, input: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.PollForActivityTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "taskList": $task_list, "identity": $identity} | compact
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

# Used by deciders to get a DecisionTask from the specified decision taskList. A decision task may be returned for any open workflow execution that is using the specified task list. The task includes a paginated view of the history of the workflow execution. The decider should use the workflow type and the history to determine how to properly handle the task. This action initiates a long poll, where the service holds the HTTP connection open and responds as soon a task becomes available. If no decision task is available in the specified task list before the timeout of 60 seconds expires, an empty result is returned. An empty result, in this context, means that a DecisionTask is returned, but that the value of taskToken is an empty string. Deciders should set their client side socket timeout to at least 70 seconds (10 seconds higher than the timeout). Because the number of workflow history events for a single workflow execution might be very large, the result returned might be split up across a number of pages. To retrieve subsequent pages, make additional calls to PollForDecisionTask using the nextPageToken returned by the initial call. Note that you do not call GetWorkflowExecutionHistory with this nextPageToken. Instead, call PollForDecisionTask again. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the taskList.name parameter by using a Condition element with the swf:taskList.name key to allow the action to access only certain task lists. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: PollForDecisionTask
export def "poll-for-decision-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximum-page-size: string # Pagination limit
  --next-page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  domain: string # The name of the domain containing the task lists to poll.
  task_list: record # Represents a task list. — shape: {name: string}
  --identity: string # Identity of the decider making the request, which is recorded in the DecisionTaskStarted event in the workflow history. This enables diagnostic tracing when problems arise. The form of this identity is user defined.
  --body-next-page-token: string # If NextPageToken is returned there are more results available. The value of NextPageToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 60 seconds. Using an expired pagination token will return a 400 error: "Specified token has exceeded its maximum lifetime". The configured maximumPageSize determines how many results can be returned in a single call. The nextPageToken returned by this action cannot be used with GetWorkflowExecutionHistory to get the next page. You must call PollForDecisionTask again (with the nextPageToken) to retrieve the next page of history records. Calling PollForDecisionTask with a nextPageToken doesn't return a new decision task. (spec name: nextPageToken)
  --body-maximum-page-size: int # The maximum number of results that are returned per call. Use nextPageToken to obtain further pages of results. This is an upper limit only; the actual number of results returned per call may be fewer than the specified maximum. (spec name: maximumPageSize)
  --reverse-order: oneof<nothing, bool> # When set to true, returns the events in reverse order. By default the results are returned in ascending order of the eventTimestamp of the events.
]: any -> oneof<record<taskToken: string, startedEventId: int, workflowExecution: record<workflowId: string, runId: string>, workflowType: record<name: string, version: string>, events: table<eventTimestamp: string, eventType: string, eventId: int, workflowExecutionStartedEventAttributes: record, workflowExecutionCompletedEventAttributes: record, completeWorkflowExecutionFailedEventAttributes: record, workflowExecutionFailedEventAttributes: record, failWorkflowExecutionFailedEventAttributes: record, workflowExecutionTimedOutEventAttributes: record, workflowExecutionCanceledEventAttributes: record, cancelWorkflowExecutionFailedEventAttributes: record, workflowExecutionContinuedAsNewEventAttributes: record, continueAsNewWorkflowExecutionFailedEventAttributes: record, workflowExecutionTerminatedEventAttributes: record, workflowExecutionCancelRequestedEventAttributes: record, decisionTaskScheduledEventAttributes: record, decisionTaskStartedEventAttributes: record, decisionTaskCompletedEventAttributes: record, decisionTaskTimedOutEventAttributes: record, activityTaskScheduledEventAttributes: record, activityTaskStartedEventAttributes: record, activityTaskCompletedEventAttributes: record, activityTaskFailedEventAttributes: record, activityTaskTimedOutEventAttributes: record, activityTaskCanceledEventAttributes: record, activityTaskCancelRequestedEventAttributes: record, workflowExecutionSignaledEventAttributes: record, markerRecordedEventAttributes: record, recordMarkerFailedEventAttributes: record, timerStartedEventAttributes: record, timerFiredEventAttributes: record, timerCanceledEventAttributes: record, startChildWorkflowExecutionInitiatedEventAttributes: record, childWorkflowExecutionStartedEventAttributes: record, childWorkflowExecutionCompletedEventAttributes: record, childWorkflowExecutionFailedEventAttributes: record, childWorkflowExecutionTimedOutEventAttributes: record, childWorkflowExecutionCanceledEventAttributes: record, childWorkflowExecutionTerminatedEventAttributes: record, signalExternalWorkflowExecutionInitiatedEventAttributes: record, externalWorkflowExecutionSignaledEventAttributes: record, signalExternalWorkflowExecutionFailedEventAttributes: record, externalWorkflowExecutionCancelRequestedEventAttributes: record, requestCancelExternalWorkflowExecutionInitiatedEventAttributes: record, requestCancelExternalWorkflowExecutionFailedEventAttributes: record, scheduleActivityTaskFailedEventAttributes: record, requestCancelActivityTaskFailedEventAttributes: record, startTimerFailedEventAttributes: record, cancelTimerFailedEventAttributes: record, startChildWorkflowExecutionFailedEventAttributes: record, lambdaFunctionScheduledEventAttributes: record, lambdaFunctionStartedEventAttributes: record, lambdaFunctionCompletedEventAttributes: record, lambdaFunctionFailedEventAttributes: record, lambdaFunctionTimedOutEventAttributes: record, scheduleLambdaFunctionFailedEventAttributes: record, startLambdaFunctionFailedEventAttributes: record>, nextPageToken: string, previousStartedEventId: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.PollForDecisionTask")
  let qp = [(serialize-qp "maximumPageSize" $maximum_page_size "scalar") (serialize-qp "nextPageToken" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"domain": $domain, "taskList": $task_list, "identity": $identity, "nextPageToken": $body_next_page_token, "maximumPageSize": $body_maximum_page_size, "reverseOrder": $reverse_order} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maximumPageSize": $maximum_page_size, "nextPageToken": $next_page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Used by activity workers to report to the service that the ActivityTask represented by the specified taskToken is still making progress. The worker can also specify details of the progress, for example percent complete, using the details parameter. This action can also be used by the worker as a mechanism to check if cancellation is being requested for the activity task. If a cancellation is being attempted for the specified task, then the boolean cancelRequested flag returned by the service is set to true. This action resets the taskHeartbeatTimeout clock. The taskHeartbeatTimeout is specified in RegisterActivityType. This action doesn't in itself create an event in the workflow execution history. However, if the task times out, the workflow execution history contains a ActivityTaskTimedOut event that contains the information from the last heartbeat generated by the activity worker. The taskStartToCloseTimeout of an activity type is the maximum duration of an activity task, regardless of the number of RecordActivityTaskHeartbeat requests received. The taskStartToCloseTimeout is also specified in RegisterActivityType. This operation is only useful for long-lived activities to report liveliness of the task and to determine if a cancellation is being attempted. If the cancelRequested flag returns true, a cancellation is being attempted. If the worker can cancel the activity, it should respond with RespondActivityTaskCanceled. Otherwise, it should ignore the cancellation request. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RecordActivityTaskHeartbeat
export def "record-activity-task-heartbeat" [
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
  task_token: string # The taskToken of the ActivityTask. taskToken is generated by the service and should be treated as an opaque value. If the task is passed to another process, its taskToken must also be passed. This enables it to provide its progress and respond with results.
  --details: string # If specified, contains details about the progress of the task.
]: any -> oneof<record<cancelRequested: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RecordActivityTaskHeartbeat")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"taskToken": $task_token, "details": $details} | compact
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

# Registers a new activity type along with its configuration settings in the specified domain. A TypeAlreadyExists fault is returned if the type already exists in the domain. You cannot change any configuration settings of the type after its registration, and it must be registered as a new version. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. defaultTaskList.name: String constraint. The key is swf:defaultTaskList.name. name: String constraint. The key is swf:name. version: String constraint. The key is swf:version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RegisterActivityType
export def "register-activity-type" [
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
  domain: string # The name of the domain in which this activity is to be registered.
  name: string # The name of the activity type within the domain. The specified string must not start or end with whitespace. It must not contain a : (colon), / (slash), | (vertical bar), or any control characters (\u0000-\u001f | \u007f-\u009f). Also, it must not be the literal string arn.
  version: string # The version of the activity type. The activity type consists of the name and version, the combination of which must be unique within the domain. The specified string must not start or end with whitespace. It must not contain a : (colon), / (slash), | (vertical bar), or any control characters (\u0000-\u001f | \u007f-\u009f). Also, it must not be the literal string arn.
  --description: string # A textual description of the activity type.
  --default-task-start-to-close-timeout: string # If set, specifies the default maximum duration that a worker can take to process tasks of this activity type. This default can be overridden when scheduling an activity task using the ScheduleActivityTask Decision. The duration is specified in seconds, an integer greater than or equal to 0. You can use NONE to specify unlimited duration.
  --default-task-heartbeat-timeout: string # If set, specifies the default maximum time before which a worker processing a task of this type must report progress by calling RecordActivityTaskHeartbeat. If the timeout is exceeded, the activity task is automatically timed out. This default can be overridden when scheduling an activity task using the ScheduleActivityTask Decision. If the activity worker subsequently attempts to record a heartbeat or returns a result, the activity worker receives an UnknownResource fault. In this case, Amazon SWF no longer considers the activity task to be valid; the activity worker should clean up the activity task. The duration is specified in seconds, an integer greater than or equal to 0. You can use NONE to specify unlimited duration.
  --default-task-list: record # Represents a task list. — shape: {name: string}
  --default-task-priority: string # The default task priority to assign to the activity type. If not assigned, then 0 is used. Valid values are integers that range from Java's Integer.MIN_VALUE (-2147483648) to Integer.MAX_VALUE (2147483647). Higher numbers indicate higher priority. For more information about setting task priority, see Setting Task Priority (https://docs.aws.amazon.com/amazonswf/latest/developerguide/programming-priority.html) in the in the Amazon SWF Developer Guide..
  --default-task-schedule-to-start-timeout: string # If set, specifies the default maximum duration that a task of this activity type can wait before being assigned to a worker. This default can be overridden when scheduling an activity task using the ScheduleActivityTask Decision. The duration is specified in seconds, an integer greater than or equal to 0. You can use NONE to specify unlimited duration.
  --default-task-schedule-to-close-timeout: string # If set, specifies the default maximum duration for a task of this activity type. This default can be overridden when scheduling an activity task using the ScheduleActivityTask Decision. The duration is specified in seconds, an integer greater than or equal to 0. You can use NONE to specify unlimited duration.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RegisterActivityType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "name": $name, "version": $version, "description": $description, "defaultTaskStartToCloseTimeout": $default_task_start_to_close_timeout, "defaultTaskHeartbeatTimeout": $default_task_heartbeat_timeout, "defaultTaskList": $default_task_list, "defaultTaskPriority": $default_task_priority, "defaultTaskScheduleToStartTimeout": $default_task_schedule_to_start_timeout, "defaultTaskScheduleToCloseTimeout": $default_task_schedule_to_close_timeout} | compact
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

# Registers a new domain. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: You cannot use an IAM policy to control domain access for this action. The name of the domain being registered is available as the resource of this action. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RegisterDomain
export def "register-domain" [
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
  name: string # Name of the domain to register. The name must be unique in the region that the domain is registered in. The specified string must not start or end with whitespace. It must not contain a : (colon), / (slash), | (vertical bar), or any control characters (\u0000-\u001f | \u007f-\u009f). Also, it must not be the literal string arn.
  --description: string # A text description of the domain.
  workflow_execution_retention_period_in_days: string # The duration (in days) that records and histories of workflow executions on the domain should be kept by the service. After the retention period, the workflow execution isn't available in the results of visibility calls. If you pass the value NONE or 0 (zero), then the workflow execution history isn't retained. As soon as the workflow execution completes, the execution record and its history are deleted. The maximum workflow execution retention period is 90 days. For more information about Amazon SWF service limits, see: Amazon SWF Service Limits (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-limits.html) in the Amazon SWF Developer Guide.
  --tags: list # Tags to be added when registering a domain. Tags may only contain unicode letters, digits, whitespace, or these symbols: _ . : / = + - @. — item shape: {key: string, value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RegisterDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "description": $description, "workflowExecutionRetentionPeriodInDays": $workflow_execution_retention_period_in_days, "tags": $tags} | compact
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

# Registers a new workflow type and its configuration settings in the specified domain. The retention period for the workflow history is set by the RegisterDomain action. If the type already exists, then a TypeAlreadyExists fault is returned. You cannot change the configuration settings of a workflow type once it is registered and it must be registered as a new version. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. defaultTaskList.name: String constraint. The key is swf:defaultTaskList.name. name: String constraint. The key is swf:name. version: String constraint. The key is swf:version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RegisterWorkflowType
export def "register-workflow-type" [
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
  domain: string # The name of the domain in which to register the workflow type.
  name: string # The name of the workflow type. The specified string must not start or end with whitespace. It must not contain a : (colon), / (slash), | (vertical bar), or any control characters (\u0000-\u001f | \u007f-\u009f). Also, it must not be the literal string arn.
  version: string # The version of the workflow type. The workflow type consists of the name and version, the combination of which must be unique within the domain. To get a list of all currently registered workflow types, use the ListWorkflowTypes action. The specified string must not start or end with whitespace. It must not contain a : (colon), / (slash), | (vertical bar), or any control characters (\u0000-\u001f | \u007f-\u009f). Also, it must not be the literal string arn.
  --description: string # Textual description of the workflow type.
  --default-task-start-to-close-timeout: string # If set, specifies the default maximum duration of decision tasks for this workflow type. This default can be overridden when starting a workflow execution using the StartWorkflowExecution action or the StartChildWorkflowExecution Decision. The duration is specified in seconds, an integer greater than or equal to 0. You can use NONE to specify unlimited duration.
  --default-execution-start-to-close-timeout: string # If set, specifies the default maximum duration for executions of this workflow type. You can override this default when starting an execution through the StartWorkflowExecution Action or StartChildWorkflowExecution Decision. The duration is specified in seconds; an integer greater than or equal to 0. Unlike some of the other timeout parameters in Amazon SWF, you cannot specify a value of "NONE" for defaultExecutionStartToCloseTimeout; there is a one-year max limit on the time that a workflow execution can run. Exceeding this limit always causes the workflow execution to time out.
  --default-task-list: record # Represents a task list. — shape: {name: string}
  --default-task-priority: string # The default task priority to assign to the workflow type. If not assigned, then 0 is used. Valid values are integers that range from Java's Integer.MIN_VALUE (-2147483648) to Integer.MAX_VALUE (2147483647). Higher numbers indicate higher priority. For more information about setting task priority, see Setting Task Priority (https://docs.aws.amazon.com/amazonswf/latest/developerguide/programming-priority.html) in the Amazon SWF Developer Guide.
  --default-child-policy: string@default-child-policy-completer # If set, specifies the default policy to use for the child workflow executions when a workflow execution of this type is terminated, by calling the TerminateWorkflowExecution action explicitly or due to an expired timeout. This default can be overridden when starting a workflow execution using the StartWorkflowExecution action or the StartChildWorkflowExecution Decision. The supported child policies are: TERMINATE – The child executions are terminated. REQUEST_CANCEL – A request to cancel is attempted for each child execution by recording a WorkflowExecutionCancelRequested event in its history. It is up to the decider to take appropriate actions when it receives an execution history with this event. ABANDON – No action is taken. The child executions continue to run.
  --default-lambda-role: string # The default IAM role attached to this workflow type. Executions of this workflow type need IAM roles to invoke Lambda functions. If you don't specify an IAM role when you start this workflow type, the default Lambda role is attached to the execution. For more information, see https://docs.aws.amazon.com/amazonswf/latest/developerguide/lambda-task.html (https://docs.aws.amazon.com/amazonswf/latest/developerguide/lambda-task.html) in the Amazon SWF Developer Guide.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RegisterWorkflowType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "name": $name, "version": $version, "description": $description, "defaultTaskStartToCloseTimeout": $default_task_start_to_close_timeout, "defaultExecutionStartToCloseTimeout": $default_execution_start_to_close_timeout, "defaultTaskList": $default_task_list, "defaultTaskPriority": $default_task_priority, "defaultChildPolicy": $default_child_policy, "defaultLambdaRole": $default_lambda_role} | compact
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

# Records a WorkflowExecutionCancelRequested event in the currently running workflow execution identified by the given domain, workflowId, and runId. This logically requests the cancellation of the workflow execution as a whole. It is up to the decider to take appropriate actions when it receives an execution history with this event. If the runId isn't specified, the WorkflowExecutionCancelRequested event is recorded in the history of the current open workflow execution with the specified workflowId in the domain. Because this action allows the workflow to properly clean up and gracefully close, it should be used instead of TerminateWorkflowExecution when possible. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RequestCancelWorkflowExecution
export def "request-cancel-workflow-execution" [
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
  domain: string # The name of the domain containing the workflow execution to cancel.
  workflow_id: string # The workflowId of the workflow execution to cancel.
  --run-id: string # The runId of the workflow execution to cancel.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RequestCancelWorkflowExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "workflowId": $workflow_id, "runId": $run_id} | compact
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

# Used by workers to tell the service that the ActivityTask identified by the taskToken was successfully canceled. Additional details can be provided using the details argument. These details (if provided) appear in the ActivityTaskCanceled event added to the workflow history. Only use this operation if the canceled flag of a RecordActivityTaskHeartbeat request returns true and if the activity can be safely undone or abandoned. A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to RespondActivityTaskCompleted, RespondActivityTaskCanceled, RespondActivityTaskFailed, or the task has timed out (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types). Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RespondActivityTaskCanceled
export def "respond-activity-task-canceled" [
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
  task_token: string # The taskToken of the ActivityTask. taskToken is generated by the service and should be treated as an opaque value. If the task is passed to another process, its taskToken must also be passed. This enables it to provide its progress and respond with results.
  --details: string # Information about the cancellation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RespondActivityTaskCanceled")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"taskToken": $task_token, "details": $details} | compact
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

# Used by workers to tell the service that the ActivityTask identified by the taskToken completed successfully with a result (if provided). The result appears in the ActivityTaskCompleted event in the workflow history. If the requested task doesn't complete successfully, use RespondActivityTaskFailed instead. If the worker finds that the task is canceled through the canceled flag returned by RecordActivityTaskHeartbeat, it should cancel the task, clean up and then call RespondActivityTaskCanceled. A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to RespondActivityTaskCompleted, RespondActivityTaskCanceled, RespondActivityTaskFailed, or the task has timed out (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types). Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RespondActivityTaskCompleted
export def "respond-activity-task-completed" [
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
  task_token: string # The taskToken of the ActivityTask. taskToken is generated by the service and should be treated as an opaque value. If the task is passed to another process, its taskToken must also be passed. This enables it to provide its progress and respond with results.
  --result: string # The result of the activity task. It is a free form string that is implementation specific.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RespondActivityTaskCompleted")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"taskToken": $task_token, "result": $result} | compact
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

# Used by workers to tell the service that the ActivityTask identified by the taskToken has failed with reason (if specified). The reason and details appear in the ActivityTaskFailed event added to the workflow history. A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to RespondActivityTaskCompleted, RespondActivityTaskCanceled, RespondActivityTaskFailed, or the task has timed out (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types). Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RespondActivityTaskFailed
export def "respond-activity-task-failed" [
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
  task_token: string # The taskToken of the ActivityTask. taskToken is generated by the service and should be treated as an opaque value. If the task is passed to another process, its taskToken must also be passed. This enables it to provide its progress and respond with results.
  --reason: string # Description of the error that may assist in diagnostics.
  --details: string # Detailed information about the failure.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RespondActivityTaskFailed")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"taskToken": $task_token, "reason": $reason, "details": $details} | compact
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

# Used by deciders to tell the service that the DecisionTask identified by the taskToken has successfully completed. The decisions argument specifies the list of decisions made while processing the task. A DecisionTaskCompleted event is added to the workflow history. The executionContext specified is attached to the event in the workflow execution history. Access Control If an IAM policy grants permission to use RespondDecisionTaskCompleted, it can express permissions for the list of decisions in the decisions parameter. Each of the decisions has one or more parameters, much like a regular API call. To allow for policies to be as readable as possible, you can express permissions on decisions as if they were actual API calls, including applying conditions to some parameters. For more information, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: RespondDecisionTaskCompleted
export def "respond-decision-task-completed" [
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
  task_token: string # The taskToken from the DecisionTask. taskToken is generated by the service and should be treated as an opaque value. If the task is passed to another process, its taskToken must also be passed. This enables it to provide its progress and respond with results.
  --decisions: list # The list of decisions (possibly empty) made by the decider while processing this decision task. See the docs for the Decision structure for details. — item shape: {decisionType: "ScheduleActivityTask"|"RequestCancelActivityTask"|"CompleteWorkflowExecution"|"FailWorkflowExecution"|"CancelWorkflowExecution"|"ContinueAsNewWorkflowExecution"|"RecordMarker"|"StartTimer"|"CancelTimer"|"SignalExternalWorkflowExecution"|"RequestCancelExternalWorkflowExecution"|"StartChildWorkflowExecution"|"ScheduleLambdaFunction", scheduleActivityTaskDecisionAttributes?: record, requestCancelActivityTaskDecisionAttributes?: record, ... (11 more fields)}
  --execution-context: string # User defined context to add to workflow execution.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.RespondDecisionTaskCompleted")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"taskToken": $task_token, "decisions": $decisions, "executionContext": $execution_context} | compact
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

# Records a WorkflowExecutionSignaled event in the workflow execution history and creates a decision task for the workflow execution identified by the given domain, workflowId and runId. The event is recorded with the specified user defined signalName and input (if provided). If a runId isn't specified, then the WorkflowExecutionSignaled event is recorded in the history of the current open workflow with the matching workflowId in the domain. If the specified workflow execution isn't open, this method fails with UnknownResource. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: SignalWorkflowExecution
export def "signal-workflow-execution" [
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
  domain: string # The name of the domain containing the workflow execution to signal.
  workflow_id: string # The workflowId of the workflow execution to signal.
  --run-id: string # The runId of the workflow execution to signal.
  signal_name: string # The name of the signal. This name must be meaningful to the target workflow.
  --body-input: string # Data to attach to the WorkflowExecutionSignaled event in the target workflow execution's history. (spec name: input)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.SignalWorkflowExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "workflowId": $workflow_id, "runId": $run_id, "signalName": $signal_name, "input": $body_input} | compact
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

# Starts an execution of the workflow type in the specified domain using the provided workflowId and input data. This action returns the newly started workflow execution. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. tagList.member.0: The key is swf:tagList.member.0. tagList.member.1: The key is swf:tagList.member.1. tagList.member.2: The key is swf:tagList.member.2. tagList.member.3: The key is swf:tagList.member.3. tagList.member.4: The key is swf:tagList.member.4. taskList: String constraint. The key is swf:taskList.name. workflowType.name: String constraint. The key is swf:workflowType.name. workflowType.version: String constraint. The key is swf:workflowType.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: StartWorkflowExecution
export def "start-workflow-execution" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  domain: string # The name of the domain in which the workflow execution is created.
  workflow_id: string # The user defined identifier associated with the workflow execution. You can use this to associate a custom identifier with the workflow execution. You may specify the same identifier if a workflow execution is logically a restart of a previous execution. You cannot have two open workflow executions with the same workflowId at the same time within the same domain. The specified string must not start or end with whitespace. It must not contain a : (colon), / (slash), | (vertical bar), or any control characters (\u0000-\u001f | \u007f-\u009f). Also, it must not be the literal string arn.
  workflow_type: record # Represents a workflow type. — shape: {name: string, version: string}
  --task-list: record # Represents a task list. — shape: {name: string}
  --task-priority: string # The task priority to use for this workflow execution. This overrides any default priority that was assigned when the workflow type was registered. If not set, then the default task priority for the workflow type is used. Valid values are integers that range from Java's Integer.MIN_VALUE (-2147483648) to Integer.MAX_VALUE (2147483647). Higher numbers indicate higher priority. For more information about setting task priority, see Setting Task Priority (https://docs.aws.amazon.com/amazonswf/latest/developerguide/programming-priority.html) in the Amazon SWF Developer Guide.
  --body-input: string # The input for the workflow execution. This is a free form string which should be meaningful to the workflow you are starting. This input is made available to the new workflow execution in the WorkflowExecutionStarted history event. (spec name: input)
  --execution-start-to-close-timeout: string # The total duration for this workflow execution. This overrides the defaultExecutionStartToCloseTimeout specified when registering the workflow type. The duration is specified in seconds; an integer greater than or equal to 0. Exceeding this limit causes the workflow execution to time out. Unlike some of the other timeout parameters in Amazon SWF, you cannot specify a value of "NONE" for this timeout; there is a one-year max limit on the time that a workflow execution can run. An execution start-to-close timeout must be specified either through this parameter or as a default when the workflow type is registered. If neither this parameter nor a default execution start-to-close timeout is specified, a fault is returned.
  --tag-list: list<string> # The list of tags to associate with the workflow execution. You can specify a maximum of 5 tags. You can list workflow executions with a specific tag by calling ListOpenWorkflowExecutions or ListClosedWorkflowExecutions and specifying a TagFilter.
  --task-start-to-close-timeout: string # Specifies the maximum duration of decision tasks for this workflow execution. This parameter overrides the defaultTaskStartToCloseTimout specified when registering the workflow type using RegisterWorkflowType. The duration is specified in seconds, an integer greater than or equal to 0. You can use NONE to specify unlimited duration. A task start-to-close timeout for this workflow execution must be specified either as a default for the workflow type or through this parameter. If neither this parameter is set nor a default task start-to-close timeout was specified at registration time then a fault is returned.
  --child-policy: string@child-policy-completer # If set, specifies the policy to use for the child workflow executions of this workflow execution if it is terminated, by calling the TerminateWorkflowExecution action explicitly or due to an expired timeout. This policy overrides the default child policy specified when registering the workflow type using RegisterWorkflowType. The supported child policies are: TERMINATE – The child executions are terminated. REQUEST_CANCEL – A request to cancel is attempted for each child execution by recording a WorkflowExecutionCancelRequested event in its history. It is up to the decider to take appropriate actions when it receives an execution history with this event. ABANDON – No action is taken. The child executions continue to run. A child policy for this workflow execution must be specified either as a default for the workflow type or through this parameter. If neither this parameter is set nor a default child policy was specified at registration time then a fault is returned.
  --lambda-role: string # The IAM role to attach to this workflow execution. Executions of this workflow type need IAM roles to invoke Lambda functions. If you don't attach an IAM role, any attempt to schedule a Lambda task fails. This results in a ScheduleLambdaFunctionFailed history event. For more information, see https://docs.aws.amazon.com/amazonswf/latest/developerguide/lambda-task.html (https://docs.aws.amazon.com/amazonswf/latest/developerguide/lambda-task.html) in the Amazon SWF Developer Guide.
]: any -> oneof<record<runId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.StartWorkflowExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "workflowId": $workflow_id, "workflowType": $workflow_type, "taskList": $task_list, "taskPriority": $task_priority, "input": $body_input, "executionStartToCloseTimeout": $execution_start_to_close_timeout, "tagList": $tag_list, "taskStartToCloseTimeout": $task_start_to_close_timeout, "childPolicy": $child_policy, "lambdaRole": $lambda_role} | compact
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

# Add a tag to a Amazon SWF domain. Amazon SWF supports a maximum of 50 tags per resource.
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  resource_arn: string # The Amazon Resource Name (ARN) for the Amazon SWF domain.
  tags: list # The list of tags to add to a domain. Tags may only contain unicode letters, digits, whitespace, or these symbols: _ . : / = + - @. — item shape: {key: string, value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.TagResource")
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

# Records a WorkflowExecutionTerminated event and forces closure of the workflow execution identified by the given domain, runId, and workflowId. The child policy, registered with the workflow type or specified when starting this execution, is applied to any open child workflow executions of this workflow execution. If the identified workflow execution was in progress, it is terminated immediately. If a runId isn't specified, then the WorkflowExecutionTerminated event is recorded in the history of the current open workflow with the matching workflowId in the domain. You should consider using RequestCancelWorkflowExecution action instead because it allows the workflow to gracefully close while TerminateWorkflowExecution doesn't. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: TerminateWorkflowExecution
export def "terminate-workflow-execution" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  domain: string # The domain of the workflow execution to terminate.
  workflow_id: string # The workflowId of the workflow execution to terminate.
  --run-id: string # The runId of the workflow execution to terminate.
  --reason: string # A descriptive reason for terminating the workflow execution.
  --details: string # Details for terminating the workflow execution.
  --child-policy: string@child-policy-completer # If set, specifies the policy to use for the child workflow executions of the workflow execution being terminated. This policy overrides the child policy specified for the workflow execution at registration time or when starting the execution. The supported child policies are: TERMINATE – The child executions are terminated. REQUEST_CANCEL – A request to cancel is attempted for each child execution by recording a WorkflowExecutionCancelRequested event in its history. It is up to the decider to take appropriate actions when it receives an execution history with this event. ABANDON – No action is taken. The child executions continue to run. A child policy for this workflow execution must be specified either as a default for the workflow type or through this parameter. If neither this parameter is set nor a default child policy was specified at registration time then a fault is returned.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.TerminateWorkflowExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "workflowId": $workflow_id, "runId": $run_id, "reason": $reason, "details": $details, "childPolicy": $child_policy} | compact
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

# Undeprecates a previously deprecated activity type. After an activity type has been undeprecated, you can create new tasks of that activity type. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. activityType.name: String constraint. The key is swf:activityType.name. activityType.version: String constraint. The key is swf:activityType.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: UndeprecateActivityType
export def "undeprecate-activity-type" [
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
  domain: string # The name of the domain of the deprecated activity type.
  activity_type: record # Represents an activity type. — shape: {name: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.UndeprecateActivityType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "activityType": $activity_type} | compact
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

# Undeprecates a previously deprecated domain. After a domain has been undeprecated it can be used to create new workflow executions or register new types. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. You cannot use an IAM policy to constrain this action's parameters. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: UndeprecateDomain
export def "undeprecate-domain" [
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
  name: string # The name of the domain of the deprecated workflow type.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.UndeprecateDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
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

# Undeprecates a previously deprecated workflow type. After a workflow type has been undeprecated, you can create new executions of that type. This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes. Access Control You can use IAM policies to control this action's access to Amazon SWF resources as follows: Use a Resource element with the domain name to limit the action to only specified domains. Use an Action element to allow or deny permission to call this action. Constrain the following parameters by using a Condition element with the appropriate keys. workflowType.name: String constraint. The key is swf:workflowType.name. workflowType.version: String constraint. The key is swf:workflowType.version. If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's cause parameter is set to OPERATION_NOT_PERMITTED. For details and example IAM policies, see Using IAM to Manage Access to Amazon SWF Workflows (https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html) in the Amazon SWF Developer Guide.
#
# POST /
# operationId: UndeprecateWorkflowType
export def "undeprecate-workflow-type" [
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
  domain: string # The name of the domain of the deprecated workflow type.
  workflow_type: record # Represents a workflow type. — shape: {name: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.UndeprecateWorkflowType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domain": $domain, "workflowType": $workflow_type} | compact
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

# Remove a tag from a Amazon SWF domain.
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
  resource_arn: string # The Amazon Resource Name (ARN) for the Amazon SWF domain.
  tag_keys: list<string> # The list of tags to remove from the Amazon SWF domain.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "SimpleWorkflowService.UntagResource")
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
