# Auto-generated client for elmah.io API vv3
# Source: https://api.apis.guru/v2/specs/elmah.io/v3/openapi.json
# Auth: --token flag or $env.ELMAH_IO_API_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ELMAH_IO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "deployments get-list" } } | get name | first)
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

# Fetch a list of deployments.
#
# GET /v3/deployments
# operationId: Deployments_GetAll
export def "deployments get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, createdBy: string, description: string, id: string, logId: string, userEmail: string, userName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/deployments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new deployment.
#
# POST /v3/deployments
# operationId: Deployments_Create
export def "deployments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --created: string # When was this deployment created in UTC. Defaults to current time if not specified. (format: date-time)
  --description: string # Optional description of this deployment. Can be markdown or clear text.
  --log-id: string # As default, deployments are attached all logs of the organization. If you want a deployment to attach to a single log only, set this to the ID of that log.
  --user-email: string # The email of the person responsible for creating this deployment. This can be the email taken from your deployment server (like Azure DevOps or Octopus). (format: email)
  --user-name: string # The name of the person responsible for creating this deployment. This can be the name taken from your deployment server (like Azure DevOps or Octopus).
  version: string # The version number of this deployment. The value of version can be a SemVer compliant string or any other syntax that you are using as your version numbering scheme.
]: any -> record<location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/deployments")
  let req_body = {"created": $created, "description": $description, "logId": $log_id, "userEmail": $user_email, "userName": $user_name, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a deployment by its ID.
#
# DELETE /v3/deployments/{id}
# operationId: Deployments_Delete
export def "deployments delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v3/deployments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a deployment by its ID.
#
# GET /v3/deployments/{id}
# operationId: Deployments_Get
export def "deployments get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<created: string, createdBy: string, description: string, id: string, logId: string, userEmail: string, userName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v3/deployments/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new heartbeat.
#
# POST /v3/heartbeats/{logId}/{id}
# operationId: Heartbeats_Create
export def "heartbeats create" [
  log_id: string
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
  --application: string # Optional string to identify which application logged this message. You can use this if you have multiple applications and services logging to the same log. If not set, the application name "Heartbeats" will be set on all log messages generated from this heartbeat.
  --reason: string # If result is "Degraded" or "Unhealthy" you can use this property to specify why.
  --result: string # The result of this heartbeat. Can be "Healthy, "Degraded", or "Unhealthy". Defaults to "Healthy"
  --took: int # Optional long for specifying how many milliseconds it took to execute the task resulting in this heartbeat. This can be used to get a better overview of how long a scheduled task or service is running or to figure out if the grace period should be increased. (format: int64)
  --version: string # Optional string to identify which version of your application logged this message. If not specified, any errors, warnings, or information messages will get the newest version number created through deployment tracking as with normal log messages.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id), id: (encode-path-segment $id)} | format pattern "/v3/heartbeats/{log_id}/{id}"))
  let req_body = {"application": $application, "reason": $reason, "result": $result, "took": $took, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fetch a list of logs.
#
# GET /v3/logs
# operationId: Logs_GetAll
export def "logs get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<color: string, disabled: bool, environmentName: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/logs")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new log.
#
# POST /v3/logs
# operationId: Logs_Create
export def "logs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # Name of the new log.
]: any -> record<location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/logs")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fetch a log by its ID.
#
# GET /v3/logs/{id}
# operationId: Logs_Get
export def "logs get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<color: string, disabled: bool, environmentName: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v3/logs/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Help diagnose logging problems.
#
# GET /v3/logs/{id}/_diagnose
# operationId: Logs_Diagnose
export def "logs-diagnose logs" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v3/logs/{id}/_diagnose"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Disable a log by its ID.
#
# POST /v3/logs/{id}/_disable
# operationId: Logs_Disable
export def "logs-disable logs" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v3/logs/{id}/_disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enable a log by its ID.
#
# POST /v3/logs/{id}/_enable
# operationId: Logs_Enable
export def "logs-enable logs" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v3/logs/{id}/_enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a list of messages by logid and query.
#
# DELETE /v3/messages/{logId}
# operationId: Messages_DeleteAll
export def "messages delete-list" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-from: string # Search from this date. (format: date-time)
  --query: string # Lucene query.
  --body-to: string # Search to this date. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id)} | format pattern "/v3/messages/{log_id}"))
  let req_body = {"from": $body_from, "query": $query, "to": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fetch messages from a log.
#
# GET /v3/messages/{logId}
# operationId: Messages_GetAll
export def "messages get-list" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-index: int # The page number of the result. (format: int32, default: 0)
  --page-size: int # The number of messages to load (max 100) or 15 if not set. (format: int32, default: 15)
  --query: string # A full-text or Lucene query to limit the messages by.
  --qp-from: string # A start date and time to search from (not included). (format: date-time)
  --qp-to: string # An end date and time to search to (not included). (format: date-time)
  --include-headers: oneof<nothing, bool> # Include headers like server variables and cookies in the result (slower). (default: false)
]: nothing -> record<messages: table<application: string, breadcrumbs: list, category: string, code: string, cookies: list, correlationId: string, data: list, dateTime: string, detail: string, form: list, hostname: string, id: string, method: string, queryString: list, serverVariables: list, severity: string, source: string, statusCode: int, title: string, titleTemplate: string, type: string, url: string, user: string, version: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  let qp = [(serialize-qp "pageIndex" $page_index "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "includeHeaders" $include_headers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id)} | format pattern "/v3/messages/{log_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageIndex": $page_index, "pageSize": $page_size, "query": $query, "from": $qp_from, "to": $qp_to, "includeHeaders": $include_headers} | compact), body: null}
}

# Create a new message.
#
# POST /v3/messages/{logId}
# operationId: Messages_Create
# --breadcrumbs item shape: {action?: string, dateTime?: string, message?: string, severity?: string}
# --cookies item shape: {key?: string, value?: string}
# --data item shape: {key?: string, value?: string}
# --form item shape: {key?: string, value?: string}
# --queryString item shape: {key?: string, value?: string}
# --serverVariables item shape: {key?: string, value?: string}
export def "messages create" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --application: string # Used to identify which application logged this message. You can use this if you have multiple applications and services logging to the same log
  --breadcrumbs: list # A list of breadcrumbs preceding this log message. — item shape: {action?: string, dateTime?: string, message?: string, severity?: string}
  --category: string # The log message category. Category can be a string of choice but typically contain a logging category set by a logging framework like NLog or Serilog. When logging through a logging framework, this field will be provided by the framework and not something that needs to be set manually.
  --code: string # Code can be used to include source code related to the log message. The code will typically span from a few lines before the line causing the log message to a few lines after. For now, all lines above 21 will be removed. This makes room for showing 10 lines before the logging line, the logging line, and 10 lines after the logging line. Don't include a very large string in this property since that will quickly make the entire messages exceed the max limit of 256 kb.
  --cookies: list # A key/value pair of cookies. This property only makes sense for logging messages related to web requests. — item shape: {key?: string, value?: string}
  --correlation-id: string # CorrelationId can be used to group similar log messages together into a single discoverable batch. A correlation ID could be a session ID from ASP.NET Core, a unique string spanning multiple microsservices handling the same request, or similar.
  --data: list # A key/value pair of user-defined fields and their values. When logging an exception, the Data dictionary of the exception is copied to this property. You can add additional key/value pairs, by modifying the Data dictionary on the exception or by supplying additional key/values to this API. — item shape: {key?: string, value?: string}
  --date-time: string # The date and time in UTC of the message. If you don't provide us with a value in dateTime, we will set the current date and time in UTC. (format: date-time)
  --detail: string # A longer description of the message. For errors this could be a stacktrace, but it's really up to you what to log in there.
  --form: list # A key/value pair of form fields and their values. This property makes sense if logging message related to users inputting data in a form. — item shape: {key?: string, value?: string}
  --hostname: string # The hostname of the server logging the message.
  --method: string # If message relates to a HTTP request, you may send the HTTP method of that request. If you don't provide us with a method, we will try to find a key named REQUEST_METHOD in serverVariables.
  --query-string: list # A key/value pair of query string parameters. This property makes sense if logging message related to a HTTP request. — item shape: {key?: string, value?: string}
  --server-variables: list # A key/value pair of server values. Server variables are typically related to handling requests in a webserver but could be used for other types of information as well. — item shape: {key?: string, value?: string}
  --severity: string # An enum value representing the severity of this message. The following values are allowed: Verbose, Debug, Information, Warning, Error, Fatal
  --body-source: string # The source of the code logging the message. This could be the assembly name.
  --status-code: int # If the message logged relates to a HTTP status code, you can put the code in this property. This would probably only be relevant for errors, but could be used for logging successful status codes as well. (format: int32)
  --title: string # The textual title or headline of the message to log.
  --title-template: string # The title template of the message to log. This property can be used from logging frameworks that supports structured logging like: "{user} says {quote}". In the example, titleTemplate will be this string and title will be "Gilfoyle says It's not magic. It's talent and sweat".
  --type: string # The type of message. If logging an error, the type of the exception would go into type but you can put anything in there, that makes sense for your domain.
  --url: string # If message relates to a HTTP request, you may send the URL of that request. If you don't provide us with an URL, we will try to find a key named URL in serverVariables.
  --user: string # An identification of the user triggering this message. You can put the users email address or your user key into this property.
  --version: string # Versions can be used to distinguish messages from different versions of your software. The value of version can be a SemVer compliant string or any other syntax that you are using as your version numbering scheme.
]: any -> record<location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id)} | format pattern "/v3/messages/{log_id}"))
  let req_body = {"application": $application, "breadcrumbs": $breadcrumbs, "category": $category, "code": $code, "cookies": $cookies, "correlationId": $correlation_id, "data": $data, "dateTime": $date_time, "detail": $detail, "form": $form, "hostname": $hostname, "method": $method, "queryString": $query_string, "serverVariables": $server_variables, "severity": $severity, "source": $body_source, "statusCode": $status_code, "title": $title, "titleTemplate": $title_template, "type": $type, "url": $url, "user": $user, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create one or more new messages.
#
# POST /v3/messages/{logId}/_bulk
# operationId: Messages_CreateBulk
export def "messages-bulk create" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: list
]: any -> table<location: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id)} | format pattern "/v3/messages/{log_id}/_bulk"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Mark a list of messages as fixed by logid and query.
#
# POST /v3/messages/{logId}/_fix
# operationId: Messages_FixAll
export def "messages-fix list" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-from: string # Search from this date. (format: date-time)
  --query: string # Lucene query.
  --body-to: string # Search to this date. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id)} | format pattern "/v3/messages/{log_id}/_fix"))
  let req_body = {"from": $body_from, "query": $query, "to": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a message by its ID.
#
# DELETE /v3/messages/{logId}/{id}
# operationId: Messages_Delete
export def "messages delete" [
  log_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id), id: (encode-path-segment $id)} | format pattern "/v3/messages/{log_id}/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a message by its ID.
#
# GET /v3/messages/{logId}/{id}
# operationId: Messages_Get
export def "messages get" [
  log_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<application: string, breadcrumbs: table<action: string, dateTime: string, message: string, severity: string>, category: string, code: string, cookies: table<key: string, value: string>, correlationId: string, data: table<key: string, value: string>, dateTime: string, detail: string, form: table<key: string, value: string>, hostname: string, id: string, method: string, queryString: table<key: string, value: string>, serverVariables: table<key: string, value: string>, severity: string, source: string, statusCode: int, title: string, titleTemplate: string, type: string, url: string, user: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id), id: (encode-path-segment $id)} | format pattern "/v3/messages/{log_id}/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fix a message by its ID.
#
# POST /v3/messages/{logId}/{id}/_fix
# operationId: Messages_Fix
export def "messages-fix create" [
  log_id: string
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
  --mark-all-as-fixed: oneof<nothing, bool> # If set to true, all instances of the log message are set to fixed. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "markAllAsFixed" $mark_all_as_fixed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id), id: (encode-path-segment $id)} | format pattern "/v3/messages/{log_id}/{id}/_fix") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"markAllAsFixed": $mark_all_as_fixed} | compact), body: null}
}

# Hide a message by its ID.
#
# POST /v3/messages/{logId}/{id}/_hide
# operationId: Messages_Hide
export def "messages-hide create" [
  log_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id), id: (encode-path-segment $id)} | format pattern "/v3/messages/{log_id}/{id}/_hide"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a translation between a minified JavaScript path to the minified JavaScript and source map files.
#
# POST /v3/sourcemaps/{logId}
# operationId: SourceMaps_CreateOrUpdate
export def "sourcemaps create-source-maps-or-update" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  minified_java_script: string # The minified JavaScript file. Only files with an extension of .js and content type of text/javascript will be accepted. (format: binary)
  path: string # An URL to the online minified JavaScript file. The URL can be absolute or relative but will always be converted to a relative path (no protocol, domain, and query parameters). elmah.io uses this path to lookup any lines in a JS stack trace that will need de-minification. (format: uri)
  source_map: string # The source map file. Only files with an extension of .map and content type of application/json will be accepted. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'logId' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id)} | format pattern "/v3/sourcemaps/{log_id}"))
  let req_body = {"MinifiedJavaScript": $minified_java_script, "Path": $path, "SourceMap": $source_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["MinifiedJavaScript" "SourceMap"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Fetch a list of uptime checks. Currently in closed beta. Get in contact to get access to this endpoint.
#
# GET /v3/uptimechecks
# operationId: UptimeChecks_GetAll
export def "uptimechecks get-uptime-checks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: string, name: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/uptimechecks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
