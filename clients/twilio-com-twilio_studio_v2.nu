# Auto-generated client for Twilio - Studio v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_studio_v2/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_STUDIO_TOKEN

const BASE_URL = "https://studio.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TWILIO_STUDIO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://studio.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["draft" "published"] }
def status-completer-1 [] { ["active" "ended"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "flows list" } } | get name | first)
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

# Retrieve a list of all Flows.
#
# GET /v2/Flows
# operationId: ListFlow
export def "flows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<flows: table<account_sid: string, commit_message: string, date_created: string, date_updated: string, definition: any, errors: list, friendly_name: string, links: record, revision: int, sid: string, status: string, url: string, valid: bool, warnings: list, webhook_url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Flows" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Flow.
#
# POST /v2/Flows
# operationId: CreateFlow
export def "flows create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit-message: string # Description of change made in the revision.
  definition: any # JSON representation of flow definition.
  friendly_name: string # The string that you assigned to describe the Flow.
  status: string@status-completer
]: any -> record<account_sid: string, commit_message: string, date_created: string, date_updated: string, definition: any, errors: list<any>, friendly_name: string, links: record, revision: int, sid: string, status: string, url: string, valid: bool, warnings: list<any>, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  let full_url = (build-url $base "/v2/Flows" $auth.query)
  let req_body = {"CommitMessage": $commit_message, "Definition": $definition, "FriendlyName": $friendly_name, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Validate flow JSON definition
#
# POST /v2/Flows/Validate
# operationId: UpdateFlowValidate
export def "flows-validate update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit-message: string # Description of change made in the revision.
  definition: any # JSON representation of flow definition.
  friendly_name: string # The string that you assigned to describe the Flow.
  status: string@status-completer
]: any -> record<valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  let full_url = (build-url $base "/v2/Flows/Validate" $auth.query)
  let req_body = {"CommitMessage": $commit_message, "Definition": $definition, "FriendlyName": $friendly_name, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of all Executions for the Flow.
#
# GET /v2/Flows/{FlowSid}/Executions
# operationId: ListExecution
export def "flows-executions list" [
  flow_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created-from: string # Only show Execution resources starting on or after this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time, given as `YYYY-MM-DDThh:mm:ss-hh:mm`. (format: date-time)
  --date-created-to: string # Only show Execution resources starting before this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time, given as `YYYY-MM-DDThh:mm:ss-hh:mm`. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<executions: table<account_sid: string, contact_channel_address: string, context: any, date_created: string, date_updated: string, flow_sid: string, links: record, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  let qp = [(serialize-qp "DateCreatedFrom" $date_created_from "scalar") (serialize-qp "DateCreatedTo" $date_created_to "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid)} | format pattern "/v2/Flows/{flow_sid}/Executions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DateCreatedFrom": $date_created_from, "DateCreatedTo": $date_created_to, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Triggers a new Execution for the Flow
#
# POST /v2/Flows/{FlowSid}/Executions
# operationId: CreateExecution
export def "flows-executions create" [
  flow_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-from: string # The Twilio phone number to send messages or initiate calls from during the Flow's Execution. Available as variable `{{flow.channel.address}}`. For SMS, this can also be a Messaging Service SID. (format: phone-number)
  --parameters: any # JSON data that will be added to the Flow's context and that can be accessed as variables inside your Flow. For example, if you pass in `Parameters={"name":"Zeke"}`, a widget in your Flow can reference the variable `{{flow.data.name}}`, which returns "Zeke". Note: the JSON value must explicitly be passed as a string, not as a hash object. Depending on your particular HTTP library, you may need to add quotes or URL encode the JSON string.
  --body-to: string # The Contact phone number to start a Studio Flow Execution, available as variable `{{contact.channel.address}}`. (format: phone-number)
]: any -> record<account_sid: string, contact_channel_address: string, context: any, date_created: string, date_updated: string, flow_sid: string, links: record, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid)} | format pattern "/v2/Flows/{flow_sid}/Executions") $auth.query)
  let req_body = {"From": $body_from, "Parameters": $parameters, "To": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Retrieve the most recent context for an Execution.
#
# GET /v2/Flows/{FlowSid}/Executions/{ExecutionSid}/Context
# operationId: FetchExecutionContext
export def "flows-executions-context get" [
  flow_sid: string
  execution_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, context: any, execution_sid: string, flow_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  if ($execution_sid | is-empty) { error make --unspanned { msg: "path parameter 'ExecutionSid' must be non-empty" } }
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid), execution_sid: (encode-path-segment $execution_sid)} | format pattern "/v2/Flows/{flow_sid}/Executions/{execution_sid}/Context") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of all Steps for an Execution.
#
# GET /v2/Flows/{FlowSid}/Executions/{ExecutionSid}/Steps
# operationId: ListExecutionStep
export def "flows-executions-steps list" [
  flow_sid: string
  execution_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, steps: table<account_sid: string, context: any, date_created: string, date_updated: string, execution_sid: string, flow_sid: string, links: record, name: string, sid: string, transitioned_from: string, transitioned_to: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  if ($execution_sid | is-empty) { error make --unspanned { msg: "path parameter 'ExecutionSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid), execution_sid: (encode-path-segment $execution_sid)} | format pattern "/v2/Flows/{flow_sid}/Executions/{execution_sid}/Steps") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a Step.
#
# GET /v2/Flows/{FlowSid}/Executions/{ExecutionSid}/Steps/{Sid}
# operationId: FetchExecutionStep
export def "flows-executions-steps get" [
  flow_sid: string
  execution_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, context: any, date_created: string, date_updated: string, execution_sid: string, flow_sid: string, links: record, name: string, sid: string, transitioned_from: string, transitioned_to: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  if ($execution_sid | is-empty) { error make --unspanned { msg: "path parameter 'ExecutionSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid), execution_sid: (encode-path-segment $execution_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{flow_sid}/Executions/{execution_sid}/Steps/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the context for an Execution Step.
#
# GET /v2/Flows/{FlowSid}/Executions/{ExecutionSid}/Steps/{StepSid}/Context
# operationId: FetchExecutionStepContext
export def "flows-executions-steps-context get" [
  flow_sid: string
  execution_sid: string
  step_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, context: any, execution_sid: string, flow_sid: string, step_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  if ($execution_sid | is-empty) { error make --unspanned { msg: "path parameter 'ExecutionSid' must be non-empty" } }
  if ($step_sid | is-empty) { error make --unspanned { msg: "path parameter 'StepSid' must be non-empty" } }
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid), execution_sid: (encode-path-segment $execution_sid), step_sid: (encode-path-segment $step_sid)} | format pattern "/v2/Flows/{flow_sid}/Executions/{execution_sid}/Steps/{step_sid}/Context") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete the Execution and all Steps relating to it.
#
# DELETE /v2/Flows/{FlowSid}/Executions/{Sid}
# operationId: DeleteExecution
export def "flows-executions delete" [
  flow_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{flow_sid}/Executions/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Execution
#
# GET /v2/Flows/{FlowSid}/Executions/{Sid}
# operationId: FetchExecution
export def "flows-executions get" [
  flow_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, contact_channel_address: string, context: any, date_created: string, date_updated: string, flow_sid: string, links: record, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{flow_sid}/Executions/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the status of an Execution to `ended`.
#
# POST /v2/Flows/{FlowSid}/Executions/{Sid}
# operationId: UpdateExecution
export def "flows-executions update" [
  flow_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-1
]: any -> record<account_sid: string, contact_channel_address: string, context: any, date_created: string, date_updated: string, flow_sid: string, links: record, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($flow_sid | is-empty) { error make --unspanned { msg: "path parameter 'FlowSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({flow_sid: (encode-path-segment $flow_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{flow_sid}/Executions/{sid}") $auth.query)
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete a specific Flow.
#
# DELETE /v2/Flows/{Sid}
# operationId: DeleteFlow
export def "flows delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve a specific Flow.
#
# GET /v2/Flows/{Sid}
# operationId: FetchFlow
export def "flows get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, commit_message: string, date_created: string, date_updated: string, definition: any, errors: list<any>, friendly_name: string, links: record, revision: int, sid: string, status: string, url: string, valid: bool, warnings: list<any>, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Flow.
#
# POST /v2/Flows/{Sid}
# operationId: UpdateFlow
export def "flows update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit-message: string # Description of change made in the revision.
  --definition: any # JSON representation of flow definition.
  --friendly-name: string # The string that you assigned to describe the Flow.
  status: string@status-completer
]: any -> record<account_sid: string, commit_message: string, date_created: string, date_updated: string, definition: any, errors: list<any>, friendly_name: string, links: record, revision: int, sid: string, status: string, url: string, valid: bool, warnings: list<any>, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{sid}") $auth.query)
  let req_body = {"CommitMessage": $commit_message, "Definition": $definition, "FriendlyName": $friendly_name, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of all Flows revisions.
#
# GET /v2/Flows/{Sid}/Revisions
# operationId: ListFlowRevision
export def "flows-revisions list" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, revisions: table<account_sid: string, commit_message: string, date_created: string, date_updated: string, definition: any, errors: list, friendly_name: string, revision: int, sid: string, status: string, url: string, valid: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{sid}/Revisions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a specific Flow revision.
#
# GET /v2/Flows/{Sid}/Revisions/{Revision}
# operationId: FetchFlowRevision
export def "flows-revisions get" [
  sid: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, commit_message: string, date_created: string, date_updated: string, definition: any, errors: list<any>, friendly_name: string, revision: int, sid: string, status: string, url: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  if ($revision | is-empty) { error make --unspanned { msg: "path parameter 'Revision' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid), revision: (encode-path-segment $revision)} | format pattern "/v2/Flows/{sid}/Revisions/{revision}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetch flow test users
#
# GET /v2/Flows/{Sid}/TestUsers
# operationId: FetchTestUser
export def "flows-test-users get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sid: string, test_users: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{sid}/TestUsers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update flow test users
#
# POST /v2/Flows/{Sid}/TestUsers
# operationId: UpdateTestUser
export def "flows-test-users update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  test_users: list<string> # List of test user identities that can test draft versions of the flow.
]: any -> record<sid: string, test_users: list<string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://studio.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Flows/{sid}/TestUsers") $auth.query)
  let req_body = {"TestUsers": $test_users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}
