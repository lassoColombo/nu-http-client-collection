# Auto-generated client for Cloud Debugger API vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/clouddebugger/v2/openapi.json
# Auth: --token flag or $env.CLOUD_DEBUGGER_API_TOKEN

const BASE_URL = "https://clouddebugger.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_DEBUGGER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://clouddebugger.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def action-value-completer [] { ["CAPTURE" "LOG"] }
def canary-option-completer [] { ["CANARY_OPTION_TRY_DISABLE" "CANARY_OPTION_TRY_ENABLE" "CANARY_OPTION_UNSPECIFIED"] }
def action-completer [] { ["CAPTURE" "LOG"] }
def log-level-completer [] { ["ERROR" "INFO" "WARNING"] }
def state-completer [] { ["STATE_CANARY_ACTIVE" "STATE_CANARY_PENDING_AGENTS" "STATE_IS_FINAL" "STATE_ROLLING_TO_ALL" "STATE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "controller-debuggees-register create" } } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name not-in [$mod_name "commands"] | get decl_id)
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

# Registers the debuggee with the controller service. All agents attached to the same application must call this method with exactly the same request content to get back the same stable `debuggee_id`. Agents should call this method again whenever `google.rpc.Code.NOT_FOUND` is returned from any controller method. This protocol allows the controller service to disable debuggees, recover from data loss, or change the `debuggee_id` format. Agents must handle `debuggee_id` value changing upon re-registration.
#
# POST /v2/controller/debuggees/register
# operationId: clouddebugger.controller.debuggees.register
# --debuggee shape: {agentVersion?: string, canaryMode?: "CANARY_MODE_UNSPECIFIED"|"CANARY_MODE_ALWAYS_ENABLED"|"CANARY_MODE_ALWAYS_DISABLED"|"CANARY_MODE_DEFAULT_ENABLED"|"CANARY_MODE_DEFAULT_DISABLED", description?: string, extSourceContexts?: list, id?: string, isDisabled?: bool, isInactive?: bool, labels?: record, project?: string, sourceContexts?: list, status?: record, uniquifier?: string}
export def "controller-debuggees-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --debuggee: record # Represents the debugged application. The application may include one or more replicated processes executing the same code. Each of these processes is attached with a debugger agent, carrying out the debugging commands. Agents attached to the same debuggee identify themselves as such by using exactly the same Debuggee message value when registering. — shape: {agentVersion?: string, canaryMode?: "CANARY_MODE_UNSPECIFIED"|"CANARY_MODE_ALWAYS_ENABLED"|"CANARY_MODE_ALWAYS_DISABLED"|"CANARY_MODE_DEFAULT_ENABLED"|"CANARY_MODE_DEFAULT_DISABLED", description?: string, extSourceContexts?: list, id?: string, isDisabled?: bool, isInactive?: bool, labels?: record, project?: string, sourceContexts?: list, status?: record, uniquifier?: string}
]: any -> record<agentId: string, debuggee: record<agentVersion: string, canaryMode: string, description: string, extSourceContexts: list<record>, id: string, isDisabled: bool, isInactive: bool, labels: record, project: string, sourceContexts: list<record>, status: record<description: record, isError: bool, refersTo: string>, uniquifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/controller/debuggees/register" $qp)
  let req_body = {"debuggee": $debuggee} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns the list of all active breakpoints for the debuggee. The breakpoint specification (`location`, `condition`, and `expressions` fields) is semantically immutable, although the field values may change. For example, an agent may update the location line number to reflect the actual line where the breakpoint was set, but this doesn't change the breakpoint semantics. This means that an agent does not need to check if a breakpoint has changed when it encounters the same breakpoint on a successive call. Moreover, an agent should remember the breakpoints that are completed until the controller removes them from the active list to avoid setting those breakpoints again.
#
# GET /v2/controller/debuggees/{debuggeeId}/breakpoints
# operationId: clouddebugger.controller.debuggees.breakpoints.list
export def "controller-debuggees-breakpoints list" [
  debuggee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --agent-id: string # Identifies the agent. This is the ID returned in the RegisterDebuggee response.
  --success-on-timeout: oneof<nothing, bool> # If set to `true` (recommended), returns `google.rpc.Code.OK` status and sets the `wait_expired` response field to `true` when the server-selected timeout has expired. If set to `false` (deprecated), returns `google.rpc.Code.ABORTED` status when the server-selected timeout has expired.
  --wait-token: string # A token that, if specified, blocks the method call until the list of active breakpoints has changed, or a server-selected timeout has expired. The value should be set from the `next_wait_token` field in the last response. The initial value should be set to `"init"`.
]: nothing -> record<breakpoints: table<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list, expressions: list, finalTime: string, id: string, isFinalState: bool, labels: record, location: record, logLevel: string, logMessageFormat: string, stackFrames: list, state: string, status: record, userEmail: string, variableTable: list>, nextWaitToken: string, waitExpired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "agentId" $agent_id "scalar") (serialize-qp "successOnTimeout" $success_on_timeout "scalar") (serialize-qp "waitToken" $wait_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({debuggee_id: (encode-path-segment $debuggee_id)} | format pattern "/v2/controller/debuggees/{debuggee_id}/breakpoints") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the breakpoint state or mutable fields. The entire Breakpoint message must be sent back to the controller service. Updates to active breakpoint fields are only allowed if the new value does not change the breakpoint specification. Updates to the `location`, `condition` and `expressions` fields should not alter the breakpoint semantics. These may only make changes such as canonicalizing a value or snapping the location to the correct line of code.
#
# PUT /v2/controller/debuggees/{debuggeeId}/breakpoints/{id}
# operationId: clouddebugger.controller.debuggees.breakpoints.update
# --breakpoint shape: {action?: "CAPTURE"|"LOG", canaryExpireTime?: string, condition?: string, createTime?: string, evaluatedExpressions?: list, expressions?: list<string>, finalTime?: string, id?: string, isFinalState?: bool, labels?: record, location?: record, logLevel?: "INFO"|"WARNING"|"ERROR", logMessageFormat?: string, stackFrames?: list, state?: "STATE_UNSPECIFIED"|"STATE_CANARY_PENDING_AGENTS"|"STATE_CANARY_ACTIVE"|"STATE_ROLLING_TO_ALL"|"STATE_IS_FINAL", status?: record, userEmail?: string, ... (1 more fields)}
export def "controller-debuggees-breakpoints update" [
  debuggee_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --breakpoint: record # ------------------------------------------------------------------------------ ## Breakpoint (the resource) Represents the breakpoint specification, status and results. — shape: {action?: "CAPTURE"|"LOG", canaryExpireTime?: string, condition?: string, createTime?: string, evaluatedExpressions?: list, expressions?: list<string>, finalTime?: string, id?: string, isFinalState?: bool, labels?: record, location?: record, logLevel?: "INFO"|"WARNING"|"ERROR", logMessageFormat?: string, stackFrames?: list, state?: "STATE_UNSPECIFIED"|"STATE_CANARY_PENDING_AGENTS"|"STATE_CANARY_ACTIVE"|"STATE_ROLLING_TO_ALL"|"STATE_IS_FINAL", status?: record, userEmail?: string, ... (1 more fields)}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({debuggee_id: (encode-path-segment $debuggee_id), id: (encode-path-segment $id)} | format pattern "/v2/controller/debuggees/{debuggee_id}/breakpoints/{id}") $qp)
  let req_body = {"breakpoint": $breakpoint} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all the debuggees that the user has access to.
#
# GET /v2/debugger/debuggees
# operationId: clouddebugger.debugger.debuggees.list
export def "debugger-debuggees list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
  --include-inactive: oneof<nothing, bool> # When set to `true`, the result includes all debuggees. Otherwise, the result includes only debuggees that are active.
  --project: string # Required. Project number of a Google Cloud project whose debuggees to list.
]: nothing -> record<debuggees: table<agentVersion: string, canaryMode: string, description: string, extSourceContexts: list, id: string, isDisabled: bool, isInactive: bool, labels: record, project: string, sourceContexts: list, status: record, uniquifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientVersion" $client_version "scalar") (serialize-qp "includeInactive" $include_inactive "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/debugger/debuggees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all breakpoints for the debuggee.
#
# GET /v2/debugger/debuggees/{debuggeeId}/breakpoints
# operationId: clouddebugger.debugger.debuggees.breakpoints.list
export def "debugger-debuggees-breakpoints list" [
  debuggee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --action-value: string@action-value-completer # Only breakpoints with the specified action will pass the filter.
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
  --include-all-users: oneof<nothing, bool> # When set to `true`, the response includes the list of breakpoints set by any user. Otherwise, it includes only breakpoints set by the caller.
  --include-inactive: oneof<nothing, bool> # When set to `true`, the response includes active and inactive breakpoints. Otherwise, it includes only active breakpoints.
  --strip-results: oneof<nothing, bool> # This field is deprecated. The following fields are always stripped out of the result: `stack_frames`, `evaluated_expressions` and `variable_table`.
  --wait-token: string # A wait token that, if specified, blocks the call until the breakpoints list has changed, or a server selected timeout has expired. The value should be set from the last response. The error code `google.rpc.Code.ABORTED` (RPC) is returned on wait timeout, which should be called again with the same `wait_token`.
]: nothing -> record<breakpoints: table<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list, expressions: list, finalTime: string, id: string, isFinalState: bool, labels: record, location: record, logLevel: string, logMessageFormat: string, stackFrames: list, state: string, status: record, userEmail: string, variableTable: list>, nextWaitToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "action.value" $action_value "scalar") (serialize-qp "clientVersion" $client_version "scalar") (serialize-qp "includeAllUsers" $include_all_users "scalar") (serialize-qp "includeInactive" $include_inactive "scalar") (serialize-qp "stripResults" $strip_results "scalar") (serialize-qp "waitToken" $wait_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({debuggee_id: (encode-path-segment $debuggee_id)} | format pattern "/v2/debugger/debuggees/{debuggee_id}/breakpoints") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Sets the breakpoint to the debuggee.
#
# POST /v2/debugger/debuggees/{debuggeeId}/breakpoints/set
# operationId: clouddebugger.debugger.debuggees.breakpoints.set
# --evaluatedExpressions item shape: {members?: list, name?: string, status?: record, type?: string, value?: string, varTableIndex?: int}
# --location shape: {column?: int, line?: int, path?: string}
# --stackFrames item shape: {arguments?: list, function?: string, locals?: list, location?: record}
# --status shape: {description?: record, isError?: bool, refersTo?: "UNSPECIFIED"|"BREAKPOINT_SOURCE_LOCATION"|"BREAKPOINT_CONDITION"|"BREAKPOINT_EXPRESSION"|"BREAKPOINT_AGE"|"BREAKPOINT_CANARY_FAILED"|"VARIABLE_NAME"|"VARIABLE_VALUE"}
# --variableTable item shape: {members?: list, name?: string, status?: record, type?: string, value?: string, varTableIndex?: int}
export def "debugger-debuggees-breakpoints-set update" [
  debuggee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --canary-option: string@canary-option-completer # The canary option set by the user upon setting breakpoint.
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
  --action: string@action-completer # Action that the agent should perform when the code at the breakpoint location is hit.
  --canary-expire-time: string # The deadline for the breakpoint to stay in CANARY_ACTIVE state. The value is meaningless when the breakpoint is not in CANARY_ACTIVE state. (format: google-datetime)
  --condition: string # Condition that triggers the breakpoint. The condition is a compound boolean expression composed using expressions in a programming language at the source location.
  --create-time: string # Time this breakpoint was created by the server in seconds resolution. (format: google-datetime)
  --evaluated-expressions: list # Values of evaluated expressions at breakpoint time. The evaluated expressions appear in exactly the same order they are listed in the `expressions` field. The `name` field holds the original expression text, the `value` or `members` field holds the result of the evaluated expression. If the expression cannot be evaluated, the `status` inside the `Variable` will indicate an error and contain the error text. — item shape: {members?: list, name?: string, status?: record, type?: string, value?: string, varTableIndex?: int}
  --expressions: list<string> # List of read-only expressions to evaluate at the breakpoint location. The expressions are composed using expressions in the programming language at the source location. If the breakpoint action is `LOG`, the evaluated expressions are included in log statements.
  --final-time: string # Time this breakpoint was finalized as seen by the server in seconds resolution. (format: google-datetime)
  --id: string # Breakpoint identifier, unique in the scope of the debuggee.
  --is-final-state: oneof<nothing, bool> # When true, indicates that this is a final result and the breakpoint state will not change from here on.
  --labels: record # A set of custom breakpoint properties, populated by the agent, to be displayed to the user.
  --location: record # Represents a location in the source code. — shape: {column?: int, line?: int, path?: string}
  --log-level: string@log-level-completer # Indicates the severity of the log. Only relevant when action is `LOG`.
  --log-message-format: string # Only relevant when action is `LOG`. Defines the message to log when the breakpoint hits. The message may include parameter placeholders `$0`, `$1`, etc. These placeholders are replaced with the evaluated value of the appropriate expression. Expressions not referenced in `log_message_format` are not logged. Example: `Message received, id = $0, count = $1` with `expressions` = `[ message.id, message.count ]`.
  --stack-frames: list # The stack at breakpoint time, where stack_frames[0] represents the most recently entered function. — item shape: {arguments?: list, function?: string, locals?: list, location?: record}
  --state: string@state-completer # The current state of the breakpoint.
  --status: record # Represents a contextual status message. The message can indicate an error or informational status, and refer to specific parts of the containing object. For example, the `Breakpoint.status` field can indicate an error referring to the `BREAKPOINT_SOURCE_LOCATION` with the message `Location not found`. — shape: {description?: record, isError?: bool, refersTo?: "UNSPECIFIED"|"BREAKPOINT_SOURCE_LOCATION"|"BREAKPOINT_CONDITION"|"BREAKPOINT_EXPRESSION"|"BREAKPOINT_AGE"|"BREAKPOINT_CANARY_FAILED"|"VARIABLE_NAME"|"VARIABLE_VALUE"}
  --user-email: string # E-mail address of the user that created this breakpoint
  --variable-table: list # The `variable_table` exists to aid with computation, memory and network traffic optimization. It enables storing a variable once and reference it from multiple variables, including variables stored in the `variable_table` itself. For example, the same `this` object, which may appear at many levels of the stack, can have all of its data stored once in this table. The stack frame variables then would hold only a reference to it. The variable `var_table_index` field is an index into this repeated field. The stored objects are nameless and get their name from the referencing variable. The effective variable is a merge of the referencing variable and the referenced variable. — item shape: {members?: list, name?: string, status?: record, type?: string, value?: string, varTableIndex?: int}
]: any -> record<breakpoint: record<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list<record>, expressions: list<string>, finalTime: string, id: string, isFinalState: bool, labels: record, location: record<column: int, line: int, path: string>, logLevel: string, logMessageFormat: string, stackFrames: list<record>, state: string, status: record<description: record, isError: bool, refersTo: string>, userEmail: string, variableTable: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "canaryOption" $canary_option "scalar") (serialize-qp "clientVersion" $client_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({debuggee_id: (encode-path-segment $debuggee_id)} | format pattern "/v2/debugger/debuggees/{debuggee_id}/breakpoints/set") $qp)
  let req_body = {"action": $action, "canaryExpireTime": $canary_expire_time, "condition": $condition, "createTime": $create_time, "evaluatedExpressions": $evaluated_expressions, "expressions": $expressions, "finalTime": $final_time, "id": $id, "isFinalState": $is_final_state, "labels": $labels, "location": $location, "logLevel": $log_level, "logMessageFormat": $log_message_format, "stackFrames": $stack_frames, "state": $state, "status": $status, "userEmail": $user_email, "variableTable": $variable_table} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the breakpoint from the debuggee.
#
# DELETE /v2/debugger/debuggees/{debuggeeId}/breakpoints/{breakpointId}
# operationId: clouddebugger.debugger.debuggees.breakpoints.delete
export def "debugger-debuggees-breakpoints delete" [
  debuggee_id: string
  breakpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientVersion" $client_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({debuggee_id: (encode-path-segment $debuggee_id), breakpoint_id: (encode-path-segment $breakpoint_id)} | format pattern "/v2/debugger/debuggees/{debuggee_id}/breakpoints/{breakpoint_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets breakpoint information.
#
# GET /v2/debugger/debuggees/{debuggeeId}/breakpoints/{breakpointId}
# operationId: clouddebugger.debugger.debuggees.breakpoints.get
export def "debugger-debuggees-breakpoints get" [
  debuggee_id: string
  breakpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
]: nothing -> record<breakpoint: record<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list<record>, expressions: list<string>, finalTime: string, id: string, isFinalState: bool, labels: record, location: record<column: int, line: int, path: string>, logLevel: string, logMessageFormat: string, stackFrames: list<record>, state: string, status: record<description: record, isError: bool, refersTo: string>, userEmail: string, variableTable: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientVersion" $client_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({debuggee_id: (encode-path-segment $debuggee_id), breakpoint_id: (encode-path-segment $breakpoint_id)} | format pattern "/v2/debugger/debuggees/{debuggee_id}/breakpoints/{breakpoint_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
