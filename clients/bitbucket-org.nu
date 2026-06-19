# Auto-generated client for Bitbucket API v2.0
# Source: https://api.apis.guru/v2/specs/bitbucket.org/2.0/openapi.json
# Auth: --token flag or $env.BITBUCKET_API_TOKEN

const BASE_URL = "https://api.bitbucket.org/2.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BITBUCKET_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.bitbucket.org/2.0"] }
def auth-scheme-completer [] { ["bearer" "basic" "basic-credentials"] }

# Completers for enum parameters
def state-completer [] { ["DECLINED" "MERGED" "OPEN" "SUPERSEDED"] }
def role-completer [] { ["admin" "contributor" "member" "owner"] }
def fork-policy-completer [] { ["allow_forks" "no_forks" "no_public_forks"] }
def scm-completer [] { ["git"] }
def report-type-completer [] { ["BUG" "COVERAGE" "SECURITY" "TEST"] }
def result-completer [] { ["FAILED" "PASSED" "PENDING"] }
def annotation-type-completer [] { ["BUG" "CODE_SMELL" "VULNERABILITY"] }
def result-completer-1 [] { ["FAILED" "IGNORED" "PASSED" "SKIPPED"] }
def severity-completer [] { ["CRITICAL" "HIGH" "LOW" "MEDIUM"] }
def state-completer-1 [] { ["FAILED" "INPROGRESS" "STOPPED" "SUCCESSFUL"] }
def kind-completer [] { ["bug" "enhancement" "proposal" "task"] }
def priority-completer [] { ["blocker" "critical" "major" "minor" "trivial"] }
def state-completer-2 [] { ["closed" "duplicate" "invalid" "new" "on hold" "open" "resolved" "wontfix"] }
def merge-strategy-completer [] { ["fast_forward" "merge_commit" "squash"] }
def format-completer [] { ["meta"] }
def format-completer-1 [] { ["meta" "rendered"] }
def role-completer-1 [] { ["contributor" "member" "owner"] }
def accept-completer [] { ["application/json" "multipart/form-data" "multipart/related"] }
def role-completer-2 [] { ["collaborator" "member" "owner"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addon delete" } } | get name | first)
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

# Delete an app
#
# DELETE /addon
export def "addon delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addon")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an installed app
#
# PUT /addon
export def "addon update" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addon")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List linkers for an app
#
# GET /addon/linkers
export def "addon-linkers list" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addon/linkers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a linker for an app
#
# GET /addon/linkers/{linker_key}
export def "addon-linkers get" [
  linker_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($linker_key | is-empty) { error make --unspanned { msg: "path parameter 'linker_key' must be non-empty" } }
  let full_url = (build-url $base ({linker_key: (encode-path-segment $linker_key)} | format pattern "/addon/linkers/{linker_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete all linker values
#
# DELETE /addon/linkers/{linker_key}/values
export def "addon-linkers-values delete-by-linker-key" [
  linker_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($linker_key | is-empty) { error make --unspanned { msg: "path parameter 'linker_key' must be non-empty" } }
  let full_url = (build-url $base ({linker_key: (encode-path-segment $linker_key)} | format pattern "/addon/linkers/{linker_key}/values"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List linker values for a linker
#
# GET /addon/linkers/{linker_key}/values
export def "addon-linkers-values list" [
  linker_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($linker_key | is-empty) { error make --unspanned { msg: "path parameter 'linker_key' must be non-empty" } }
  let full_url = (build-url $base ({linker_key: (encode-path-segment $linker_key)} | format pattern "/addon/linkers/{linker_key}/values"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a linker value
#
# POST /addon/linkers/{linker_key}/values
export def "addon-linkers-values create" [
  linker_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($linker_key | is-empty) { error make --unspanned { msg: "path parameter 'linker_key' must be non-empty" } }
  let full_url = (build-url $base ({linker_key: (encode-path-segment $linker_key)} | format pattern "/addon/linkers/{linker_key}/values"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a linker value
#
# PUT /addon/linkers/{linker_key}/values
export def "addon-linkers-values update" [
  linker_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($linker_key | is-empty) { error make --unspanned { msg: "path parameter 'linker_key' must be non-empty" } }
  let full_url = (build-url $base ({linker_key: (encode-path-segment $linker_key)} | format pattern "/addon/linkers/{linker_key}/values"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a linker value
#
# DELETE /addon/linkers/{linker_key}/values/{value_id}
export def "addon-linkers-values delete-by-linker-key-value-id" [
  linker_key: string
  value_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($linker_key | is-empty) { error make --unspanned { msg: "path parameter 'linker_key' must be non-empty" } }
  if ($value_id | is-empty) { error make --unspanned { msg: "path parameter 'value_id' must be non-empty" } }
  let full_url = (build-url $base ({linker_key: (encode-path-segment $linker_key), value_id: (encode-path-segment $value_id)} | format pattern "/addon/linkers/{linker_key}/values/{value_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a linker value
#
# GET /addon/linkers/{linker_key}/values/{value_id}
export def "addon-linkers-values get" [
  linker_key: string
  value_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($linker_key | is-empty) { error make --unspanned { msg: "path parameter 'linker_key' must be non-empty" } }
  if ($value_id | is-empty) { error make --unspanned { msg: "path parameter 'value_id' must be non-empty" } }
  let full_url = (build-url $base ({linker_key: (encode-path-segment $linker_key), value_id: (encode-path-segment $value_id)} | format pattern "/addon/linkers/{linker_key}/values/{value_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a webhook resource
#
# GET /hook_events
export def "hook-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<repository: record<events: record<href: string, name: string>>, workspace: record<events: record<href: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hook_events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List subscribable webhook types
#
# GET /hook_events/{subject_type}
export def "hook-events get" [
  subject_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<category: string, description: string, event: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subject_type | is-empty) { error make --unspanned { msg: "path parameter 'subject_type' must be non-empty" } }
  let full_url = (build-url $base ({subject_type: (encode-path-segment $subject_type)} | format pattern "/hook_events/{subject_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List pull requests for a user
#
# GET /pullrequests/{selected_user}
export def "pullrequests get" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Only return pull requests that are in this state. This parameter can be repeated.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user)} | format pattern "/pullrequests/{selected_user}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"state": $state} | compact), body: null}
}

# List public repositories
#
# GET /repositories
export def "repositories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Filter the results to include only repositories created on or after this [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) timestamp. Example: `YYYY-MM-DDTHH:mm:ss.sssZ`
  --role: string@role-completer # Filters the result based on the authenticated user's role on each repository. * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). `role` parameter must also be specified.
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"after": $after, "role": $role, "q": $q, "sort": $qp_sort} | compact), body: null}
}

# List repositories in a workspace
#
# GET /repositories/{workspace}
export def "repositories get-by-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # Filters the result based on the authenticated user's role on each repository. * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/repositories/{workspace}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"role": $role, "q": $q, "sort": $qp_sort} | compact), body: null}
}

# Delete a repository
#
# DELETE /repositories/{workspace}/{repo_slug}
export def "repositories delete" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect-to: string # If a repository has been moved to a new location, use this parameter to show users a friendly message in the Bitbucket UI that the repository has moved to a new location. However, a GET to this endpoint will still return a 404.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "redirect_to" $redirect_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"redirect_to": $redirect_to} | compact), body: null}
}

# Get a repository
#
# GET /repositories/{workspace}/{repo_slug}
export def "repositories get-by-workspace-repo-slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<links: record>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a repository
#
# POST /repositories/{workspace}/{repo_slug}
# --links shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
export def "repositories create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --fork-policy: string@fork-policy-completer # Controls the rules for forking this repository. * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot be made public later) * **no_forks**: deny all forking
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --has-issues: oneof<nothing, bool>
  --has-wiki: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --language: string
  --links: record # shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
  --mainbranch: any
  --name: string
  --owner: any
  --parent: any
  --project: any
  --scm: string@scm-completer
  --size: int
  --updated-on: string # format: date-time
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
]: any -> record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<links: record>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}"))
  let req_body = {"type": $type, "created_on": $created_on, "description": $description, "fork_policy": $fork_policy, "full_name": $full_name, "has_issues": $has_issues, "has_wiki": $has_wiki, "is_private": $is_private, "language": $language, "links": $links, "mainbranch": $mainbranch, "name": $name, "owner": $owner, "parent": $parent, "project": $project, "scm": $scm, "size": $size, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update a repository
#
# PUT /repositories/{workspace}/{repo_slug}
# --links shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
export def "repositories update" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --fork-policy: string@fork-policy-completer # Controls the rules for forking this repository. * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot be made public later) * **no_forks**: deny all forking
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --has-issues: oneof<nothing, bool>
  --has-wiki: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --language: string
  --links: record # shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
  --mainbranch: any
  --name: string
  --owner: any
  --parent: any
  --project: any
  --scm: string@scm-completer
  --size: int
  --updated-on: string # format: date-time
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
]: any -> record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<links: record>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}"))
  let req_body = {"type": $type, "created_on": $created_on, "description": $description, "fork_policy": $fork_policy, "full_name": $full_name, "has_issues": $has_issues, "has_wiki": $has_wiki, "is_private": $is_private, "language": $language, "links": $links, "mainbranch": $mainbranch, "name": $name, "owner": $owner, "parent": $parent, "project": $project, "scm": $scm, "size": $size, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List branch restrictions
#
# GET /repositories/{workspace}/{repo_slug}/branch-restrictions
export def "repositories-branch-restrictions list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string # Branch restrictions of this type
  --pattern: string # Branch restrictions applied to branches of this pattern
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, groups: list, users: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "kind" $kind "scalar") (serialize-qp "pattern" $pattern "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/branch-restrictions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"kind": $kind, "pattern": $pattern} | compact), body: null}
}

# Create a branch restriction rule
#
# POST /repositories/{workspace}/{repo_slug}/branch-restrictions
# --groups item shape: {type: string, full_slug?: string, links?: record, name?: string, owner?: any, slug?: string, workspace?: any}
# --users item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
export def "repositories-branch-restrictions create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --groups: list # item shape: {type: string, full_slug?: string, links?: record, name?: string, owner?: any, slug?: string, workspace?: any}
  --users: list # item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
]: any -> record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/branch-restrictions"))
  let req_body = {"type": $type, "groups": $groups, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a branch restriction rule
#
# DELETE /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
export def "repositories-branch-restrictions delete" [
  workspace: string
  repo_slug: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), id: (encode-path-segment $id)} | format pattern "/repositories/{workspace}/{repo_slug}/branch-restrictions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a branch restriction rule
#
# GET /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
export def "repositories-branch-restrictions get" [
  workspace: string
  repo_slug: string
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
]: nothing -> record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), id: (encode-path-segment $id)} | format pattern "/repositories/{workspace}/{repo_slug}/branch-restrictions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a branch restriction rule
#
# PUT /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
# --groups item shape: {type: string, full_slug?: string, links?: record, name?: string, owner?: any, slug?: string, workspace?: any}
# --users item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
export def "repositories-branch-restrictions update" [
  workspace: string
  repo_slug: string
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
  type: string
  --groups: list # item shape: {type: string, full_slug?: string, links?: record, name?: string, owner?: any, slug?: string, workspace?: any}
  --users: list # item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
]: any -> record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), id: (encode-path-segment $id)} | format pattern "/repositories/{workspace}/{repo_slug}/branch-restrictions/{id}"))
  let req_body = {"type": $type, "groups": $groups, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the branching model for a repository
#
# GET /repositories/{workspace}/{repo_slug}/branching-model
export def "repositories-branching-model get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, branch_types: table<kind: string, prefix: string>, development: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>, production: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/branching-model"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the branching model config for a repository
#
# GET /repositories/{workspace}/{repo_slug}/branching-model/settings
export def "repositories-branching-model-settings get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/branching-model/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the branching model config for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/branching-model/settings
export def "repositories-branching-model-settings update" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/branching-model/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}
export def "repositories-commit get" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: any, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Unapprove a commit
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/approve
export def "repositories-commit-approve delete" [
  workspace: string
  repo_slug: string
  commit: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/approve"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Approve a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/approve
export def "repositories-commit-approve create" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/approve"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List a commit's comments
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/comments
export def "repositories-commit-comments list" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<commit: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# Create comment for a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/comments
export def "repositories-commit-comments create" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-commit: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments"))
  let req_body = {"commit": $body_commit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a commit comment
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
export def "repositories-commit-comments delete" [
  workspace: string
  repo_slug: string
  commit: string
  comment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a commit comment
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
export def "repositories-commit-comments get" [
  workspace: string
  repo_slug: string
  commit: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commit: record<participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a commit comment
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
export def "repositories-commit-comments update" [
  workspace: string
  repo_slug: string
  commit: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-commit: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}"))
  let req_body = {"commit": $body_commit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a commit application property
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# operationId: deleteCommitHostedPropertyValue
export def "repositories-commit-properties delete-hosted-value" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a commit application property
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# operationId: getCommitHostedPropertyValue
export def "repositories-commit-properties get-hosted-value" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_attributes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a commit application property
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# operationId: updateCommitHostedPropertyValue
export def "repositories-commit-properties update-hosted-value" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}"))
  let req_body = {"_attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List pull requests that contain a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/pullrequests
# operationId: getPullrequestsForCommit
export def "repositories-commit-pullrequests get" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page to retrieve (format: int32, default: 1)
  --pagelen: int # How many pull requests to retrieve per page (format: int32, default: 30)
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/pullrequests") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pagelen": $pagelen} | compact), body: null}
}

# List reports
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports
# operationId: getReportsForCommit
export def "repositories-commit-reports list" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, data: list, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a report
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# operationId: deleteReport
export def "repositories-commit-reports delete" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), report_id: (encode-path-segment $report_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a report
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# operationId: getReport
export def "repositories-commit-reports get" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, data: table<title: string, type: string, value: record>, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), report_id: (encode-path-segment $report_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a report
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# operationId: createOrUpdateReport
# --data item shape: {title?: string, type?: "BOOLEAN"|"DATE"|"DURATION"|"LINK"|"NUMBER"|"PERCENTAGE"|"TEXT", value?: record}
export def "repositories-commit-reports create-or-update" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # The timestamp when the report was created. (format: date-time)
  --data: list # An array of data fields to display information on the report. Maximum 10. — item shape: {title?: string, type?: "BOOLEAN"|"DATE"|"DURATION"|"LINK"|"NUMBER"|"PERCENTAGE"|"TEXT", value?: record}
  --details: string # A string to describe the purpose of the report.
  --external-id: string # ID of the report provided by the report creator. It can be used to identify the report as an alternative to it's generated uuid. It is not used by Bitbucket, but only by the report creator for updating or deleting this specific report. Needs to be unique.
  --link: string # A URL linking to the results of the report in an external tool. (format: uri)
  --logo-url: string # A URL to the report logo. If none is provided, the default insights logo will be used. (format: uri)
  --remote-link-enabled: oneof<nothing, bool> # If enabled, a remote link is created in Jira for the issue associated with the commit the report belongs to.
  --report-type: string@report-type-completer # The type of the report.
  --reporter: string # A string to describe the tool or company who created the report.
  --result: string@result-completer # The state of the report. May be set to PENDING and later updated.
  --title: string # The title of the report.
  --updated-on: string # The timestamp when the report was updated. (format: date-time)
  --uuid: string # The UUID that can be used to identify the report.
]: any -> record<type: string, created_on: string, data: table<title: string, type: string, value: record>, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), report_id: (encode-path-segment $report_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{report_id}"))
  let req_body = {"type": $type, "created_on": $created_on, "data": $data, "details": $details, "external_id": $external_id, "link": $link, "logo_url": $logo_url, "remote_link_enabled": $remote_link_enabled, "report_type": $report_type, "reporter": $reporter, "result": $result, "title": $title, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List annotations
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations
# operationId: getAnnotationsForReport
export def "repositories-commit-reports-annotations list" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), report_id: (encode-path-segment $report_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{report_id}/annotations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Bulk create or update annotations
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations
# operationId: bulkCreateOrUpdateAnnotations
export def "repositories-commit-reports-annotations create-bulk-or-update" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), report_id: (encode-path-segment $report_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{report_id}/annotations"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an annotation
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# operationId: deleteAnnotation
export def "repositories-commit-reports-annotations delete" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  annotation_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  if ($annotation_id | is-empty) { error make --unspanned { msg: "path parameter 'annotationId' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), report_id: (encode-path-segment $report_id), annotation_id: (encode-path-segment $annotation_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{report_id}/annotations/{annotation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an annotation
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# operationId: getAnnotation
export def "repositories-commit-reports-annotations get" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  annotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  if ($annotation_id | is-empty) { error make --unspanned { msg: "path parameter 'annotationId' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), report_id: (encode-path-segment $report_id), annotation_id: (encode-path-segment $annotation_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{report_id}/annotations/{annotation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update an annotation
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# operationId: createOrUpdateAnnotation
export def "repositories-commit-reports-annotations create-or-update" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  annotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --annotation-type: string@annotation-type-completer # The type of the report.
  --created-on: string # The timestamp when the report was created. (format: date-time)
  --details: string # The details to show to users when clicking on the annotation.
  --external-id: string # ID of the annotation provided by the annotation creator. It can be used to identify the annotation as an alternative to it's generated uuid. It is not used by Bitbucket, but only by the annotation creator for updating or deleting this specific annotation. Needs to be unique.
  --line: int # The line number that the annotation should belong to. If no line number is provided, then it will default to 0 and in a pull request it will appear at the top of the file specified by the path field.
  --link: string # A URL linking to the annotation in an external tool. (format: uri)
  --path: string # The path of the file on which this annotation should be placed. This is the path of the file relative to the git repository. If no path is provided, then it will appear in the overview modal on all pull requests where the tip of the branch is the given commit, regardless of which files were modified.
  --result: string@result-completer-1 # The state of the report. May be set to PENDING and later updated.
  --severity: string@severity-completer # The severity of the annotation.
  --summary: string # The message to display to users.
  --updated-on: string # The timestamp when the report was updated. (format: date-time)
  --uuid: string # The UUID that can be used to identify the annotation.
]: any -> record<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  if ($annotation_id | is-empty) { error make --unspanned { msg: "path parameter 'annotationId' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), report_id: (encode-path-segment $report_id), annotation_id: (encode-path-segment $annotation_id)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{report_id}/annotations/{annotation_id}"))
  let req_body = {"type": $type, "annotation_type": $annotation_type, "created_on": $created_on, "details": $details, "external_id": $external_id, "line": $line, "link": $link, "path": $path, "result": $result, "severity": $severity, "summary": $summary, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List commit statuses for a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses
export def "repositories-commit-statuses get" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). Defaults to `created_on`.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, key: string, links: record, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/statuses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# Create a build status for a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build
# --links shape: {commit?: record, self?: record}
export def "repositories-commit-statuses-build create" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string # A description of the build (e.g. "Unit tests in Bamboo")
  --key: string # An identifier for the status that's unique to its type (current "build" is the only supported type) and the vendor, e.g. BB-DEPLOY
  --links: record # shape: {commit?: record, self?: record}
  --name: string # An identifier for the build itself, e.g. BB-DEPLOY-1
  --refname: string # The name of the ref that pointed to this commit at the time the status object was created. Note that this the ref may since have moved off of the commit. This optional field can be useful for build systems whose build triggers and configuration are branch-dependent (e.g. a Pipeline build). It is legitimate for this field to not be set, or even apply (e.g. a static linting job).
  --state: string@state-completer-1 # Provides some indication of the status of this commit
  --updated-on: string # format: date-time
  --url: string # A URL linking back to the vendor or build system, for providing more information about whatever process produced this status. Accepts context variables `repository` and `commit` that Bitbucket will evaluate at runtime whenever at runtime. For example, one could use https://foo.com/builds/{repository.full_name} which Bitbucket will turn into https://foo.com/builds/foo/bar at render time.
  --uuid: string # The commit status' id.
]: any -> record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build"))
  let req_body = {"type": $type, "created_on": $created_on, "description": $description, "key": $key, "links": $links, "name": $name, "refname": $refname, "state": $state, "updated_on": $updated_on, "url": $url, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a build status for a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}
export def "repositories-commit-statuses-build get" [
  workspace: string
  repo_slug: string
  commit: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), key: (encode-path-segment $key)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a build status for a commit
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}
# --links shape: {commit?: record, self?: record}
export def "repositories-commit-statuses-build update" [
  workspace: string
  repo_slug: string
  commit: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string # A description of the build (e.g. "Unit tests in Bamboo")
  --body-key: string # An identifier for the status that's unique to its type (current "build" is the only supported type) and the vendor, e.g. BB-DEPLOY
  --links: record # shape: {commit?: record, self?: record}
  --name: string # An identifier for the build itself, e.g. BB-DEPLOY-1
  --refname: string # The name of the ref that pointed to this commit at the time the status object was created. Note that this the ref may since have moved off of the commit. This optional field can be useful for build systems whose build triggers and configuration are branch-dependent (e.g. a Pipeline build). It is legitimate for this field to not be set, or even apply (e.g. a static linting job).
  --state: string@state-completer-1 # Provides some indication of the status of this commit
  --updated-on: string # format: date-time
  --url: string # A URL linking back to the vendor or build system, for providing more information about whatever process produced this status. Accepts context variables `repository` and `commit` that Bitbucket will evaluate at runtime whenever at runtime. For example, one could use https://foo.com/builds/{repository.full_name} which Bitbucket will turn into https://foo.com/builds/foo/bar at render time.
  --uuid: string # The commit status' id.
]: any -> record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), key: (encode-path-segment $key)} | format pattern "/repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}"))
  let req_body = {"type": $type, "created_on": $created_on, "description": $description, "key": $body_key, "links": $links, "name": $name, "refname": $refname, "state": $state, "updated_on": $updated_on, "url": $url, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List commits
#
# GET /repositories/{workspace}/{repo_slug}/commits
export def "repositories-commits list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/commits"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List commits with include/exclude
#
# POST /repositories/{workspace}/{repo_slug}/commits
export def "repositories-commits create-by-workspace-repo-slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/commits"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List commits for revision
#
# GET /repositories/{workspace}/{repo_slug}/commits/{revision}
export def "repositories-commits get" [
  workspace: string
  repo_slug: string
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
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($revision | is-empty) { error make --unspanned { msg: "path parameter 'revision' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), revision: (encode-path-segment $revision)} | format pattern "/repositories/{workspace}/{repo_slug}/commits/{revision}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List commits for revision using include/exclude
#
# POST /repositories/{workspace}/{repo_slug}/commits/{revision}
export def "repositories-commits create-by-workspace-repo-slug-revision" [
  workspace: string
  repo_slug: string
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
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($revision | is-empty) { error make --unspanned { msg: "path parameter 'revision' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), revision: (encode-path-segment $revision)} | format pattern "/repositories/{workspace}/{repo_slug}/commits/{revision}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List components
#
# GET /repositories/{workspace}/{repo_slug}/components
export def "repositories-components list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/components"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a component for issues
#
# GET /repositories/{workspace}/{repo_slug}/components/{component_id}
export def "repositories-components get" [
  workspace: string
  repo_slug: string
  component_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($component_id | is-empty) { error make --unspanned { msg: "path parameter 'component_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), component_id: (encode-path-segment $component_id)} | format pattern "/repositories/{workspace}/{repo_slug}/components/{component_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List default reviewers
#
# GET /repositories/{workspace}/{repo_slug}/default-reviewers
export def "repositories-default-reviewers list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/default-reviewers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a user from the default reviewers
#
# DELETE /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
export def "repositories-default-reviewers delete" [
  workspace: string
  repo_slug: string
  target_username: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($target_username | is-empty) { error make --unspanned { msg: "path parameter 'target_username' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), target_username: (encode-path-segment $target_username)} | format pattern "/repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a default reviewer
#
# GET /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
export def "repositories-default-reviewers get" [
  workspace: string
  repo_slug: string
  target_username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($target_username | is-empty) { error make --unspanned { msg: "path parameter 'target_username' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), target_username: (encode-path-segment $target_username)} | format pattern "/repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a user to the default reviewers
#
# PUT /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
export def "repositories-default-reviewers update" [
  workspace: string
  repo_slug: string
  target_username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($target_username | is-empty) { error make --unspanned { msg: "path parameter 'target_username' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), target_username: (encode-path-segment $target_username)} | format pattern "/repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List repository deploy keys
#
# GET /repositories/{workspace}/{repo_slug}/deploy-keys
export def "repositories-deploy-keys list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record, owner: record, repository: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/deploy-keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a repository deploy key
#
# POST /repositories/{workspace}/{repo_slug}/deploy-keys
export def "repositories-deploy-keys create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/deploy-keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a repository deploy key
#
# DELETE /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
export def "repositories-deploy-keys delete" [
  workspace: string
  repo_slug: string
  key_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), key_id: (encode-path-segment $key_id)} | format pattern "/repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a repository deploy key
#
# GET /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
export def "repositories-deploy-keys get" [
  workspace: string
  repo_slug: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), key_id: (encode-path-segment $key_id)} | format pattern "/repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a repository deploy key
#
# PUT /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
export def "repositories-deploy-keys update" [
  workspace: string
  repo_slug: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), key_id: (encode-path-segment $key_id)} | format pattern "/repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List deployments
#
# GET /repositories/{workspace}/{repo_slug}/deployments/
# operationId: getDeploymentsForRepository
export def "repositories-deployments list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, environment: record, release: record, state: record, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/deployments/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a deployment
#
# GET /repositories/{workspace}/{repo_slug}/deployments/{deployment_uuid}
# operationId: getDeploymentForRepository
export def "repositories-deployments get-for-repository" [
  workspace: string
  repo_slug: string
  deployment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, environment: record<type: string, name: string, uuid: string>, release: record<type: string, commit: record<participants: list, repository: record>, created_on: string, name: string, url: string, uuid: string>, state: record<type: string>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($deployment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'deployment_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), deployment_uuid: (encode-path-segment $deployment_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/deployments/{deployment_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List variables for an environment
#
# GET /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables
# operationId: getDeploymentVariables
export def "repositories-deployments-config-environments-variables get" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($environment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), environment_uuid: (encode-path-segment $environment_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a variable for an environment
#
# POST /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables
# operationId: createDeploymentVariable
export def "repositories-deployments-config-environments-variables create" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($environment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), environment_uuid: (encode-path-segment $environment_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a variable for an environment
#
# DELETE /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}
# operationId: deleteDeploymentVariable
export def "repositories-deployments-config-environments-variables delete" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  variable_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($environment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uuid' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), environment_uuid: (encode-path-segment $environment_uuid), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a variable for an environment
#
# PUT /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}
# operationId: updateDeploymentVariable
export def "repositories-deployments-config-environments-variables update" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($environment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uuid' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), environment_uuid: (encode-path-segment $environment_uuid), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Compare two commits
#
# GET /repositories/{workspace}/{repo_slug}/diff/{spec}
export def "repositories-diff get" [
  workspace: string
  repo_slug: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: int # Generate diffs with lines of context instead of the usual three.
  --path: string # Limit the diff to a particular file (this parameter can be repeated for multiple paths).
  --ignore-whitespace: oneof<nothing, bool> # Generate diffs that ignore whitespace.
  --binary: oneof<nothing, bool> # Generate diffs that include binary files, true if omitted.
  --renames: oneof<nothing, bool> # Whether to perform rename detection, true if omitted.
  --merge: oneof<nothing, bool> # This parameter is deprecated and will be removed at the end of 2022. The 'topic' parameter should be used instead. The 'merge' and 'topic' parameters cannot be both used at the same time. If true, the source commit is merged into the destination commit, and then a diff from the destination to the merge result is returned. If false, a simple 'two dot' diff between the source and destination is returned. True if omitted.
  --topic: oneof<nothing, bool> # If true, returns 2-way 'three-dot' diff. This is a diff between the source commit and the merge base of the source commit and the destination commit. If false, a simple 'two dot' diff between the source and destination is returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($spec | is-empty) { error make --unspanned { msg: "path parameter 'spec' must be non-empty" } }
  let qp = [(serialize-qp "context" $context "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "ignore_whitespace" $ignore_whitespace "scalar") (serialize-qp "binary" $binary "scalar") (serialize-qp "renames" $renames "scalar") (serialize-qp "merge" $merge "scalar") (serialize-qp "topic" $topic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), spec: (encode-path-segment $spec)} | format pattern "/repositories/{workspace}/{repo_slug}/diff/{spec}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"context": $context, "path": $path, "ignore_whitespace": $ignore_whitespace, "binary": $binary, "renames": $renames, "merge": $merge, "topic": $topic} | compact), body: null}
}

# Compare two commit diff stats
#
# GET /repositories/{workspace}/{repo_slug}/diffstat/{spec}
export def "repositories-diffstat get" [
  workspace: string
  repo_slug: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignore-whitespace: oneof<nothing, bool> # Generate diffs that ignore whitespace
  --merge: oneof<nothing, bool> # This parameter is deprecated and will be removed at the end of 2022. The 'topic' parameter should be used instead. The 'merge' and 'topic' parameters cannot be both used at the same time. If true, the source commit is merged into the destination commit, and then a diffstat from the destination to the merge result is returned. If false, a simple 'two dot' diffstat between the source and destination is returned. True if omitted.
  --path: string # Limit the diffstat to a particular file (this parameter can be repeated for multiple paths).
  --renames: oneof<nothing, bool> # Whether to perform rename detection, true if omitted.
  --topic: oneof<nothing, bool> # If true, returns 2-way 'three-dot' diff. This is a diff between the source commit and the merge base of the source commit and the destination commit. If false, a simple 'two dot' diff between the source and destination is returned.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<lines_added: int, lines_removed: int, new: record, old: record, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($spec | is-empty) { error make --unspanned { msg: "path parameter 'spec' must be non-empty" } }
  let qp = [(serialize-qp "ignore_whitespace" $ignore_whitespace "scalar") (serialize-qp "merge" $merge "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "renames" $renames "scalar") (serialize-qp "topic" $topic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), spec: (encode-path-segment $spec)} | format pattern "/repositories/{workspace}/{repo_slug}/diffstat/{spec}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ignore_whitespace": $ignore_whitespace, "merge": $merge, "path": $path, "renames": $renames, "topic": $topic} | compact), body: null}
}

# List download artifacts
#
# GET /repositories/{workspace}/{repo_slug}/downloads
export def "repositories-downloads list" [
  workspace: string
  repo_slug: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/downloads"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload a download artifact
#
# POST /repositories/{workspace}/{repo_slug}/downloads
export def "repositories-downloads create" [
  workspace: string
  repo_slug: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/downloads"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a download artifact
#
# DELETE /repositories/{workspace}/{repo_slug}/downloads/{filename}
export def "repositories-downloads delete" [
  workspace: string
  repo_slug: string
  filename: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), filename: (encode-path-segment $filename)} | format pattern "/repositories/{workspace}/{repo_slug}/downloads/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a download artifact link
#
# GET /repositories/{workspace}/{repo_slug}/downloads/{filename}
export def "repositories-downloads get" [
  workspace: string
  repo_slug: string
  filename: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), filename: (encode-path-segment $filename)} | format pattern "/repositories/{workspace}/{repo_slug}/downloads/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the effective, or currently applied, branching model for a repository
#
# GET /repositories/{workspace}/{repo_slug}/effective-branching-model
export def "repositories-effective-branching-model get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, branch_types: table<kind: string, prefix: string>, development: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>, production: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/effective-branching-model"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List effective default reviewers
#
# GET /repositories/{workspace}/{repo_slug}/effective-default-reviewers
export def "repositories-effective-default-reviewers get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<reviewer_type: string, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/effective-default-reviewers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List environments
#
# GET /repositories/{workspace}/{repo_slug}/environments/
# operationId: getEnvironmentsForRepository
export def "repositories-environments list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/environments/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an environment
#
# POST /repositories/{workspace}/{repo_slug}/environments/
# operationId: createEnvironment
export def "repositories-environments create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --name: string # The name of the environment.
  --uuid: string # The UUID identifying the environment.
]: any -> record<type: string, name: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/environments/"))
  let req_body = {"type": $type, "name": $name, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an environment
#
# DELETE /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}
# operationId: deleteEnvironmentForRepository
export def "repositories-environments delete-for-repository" [
  workspace: string
  repo_slug: string
  environment_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($environment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), environment_uuid: (encode-path-segment $environment_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/environments/{environment_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an environment
#
# GET /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}
# operationId: getEnvironmentForRepository
export def "repositories-environments get-for-repository" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, name: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($environment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), environment_uuid: (encode-path-segment $environment_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/environments/{environment_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an environment
#
# POST /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}/changes/
# operationId: updateEnvironmentForRepository
export def "repositories-environments-changes update-for-repository" [
  workspace: string
  repo_slug: string
  environment_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($environment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), environment_uuid: (encode-path-segment $environment_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/environments/{environment_uuid}/changes/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List commits that modified a file
#
# GET /repositories/{workspace}/{repo_slug}/filehistory/{commit}/{path}
export def "repositories-filehistory get" [
  workspace: string
  repo_slug: string
  commit: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --renames: string # When `true`, Bitbucket will follow the history of the file across renames (this is the default behavior). This can be turned off by specifying `false`.
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<attributes: string, commit: record, escaped_path: string, path: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let qp = [(serialize-qp "renames" $renames "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), path: (encode-path-segment $path)} | format pattern "/repositories/{workspace}/{repo_slug}/filehistory/{commit}/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"renames": $renames, "q": $q, "sort": $qp_sort} | compact), body: null}
}

# List repository forks
#
# GET /repositories/{workspace}/{repo_slug}/forks
export def "repositories-forks get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # Filters the result based on the authenticated user's role on each repository. * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/forks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"role": $role, "q": $q, "sort": $qp_sort} | compact), body: null}
}

# Fork a repository
#
# POST /repositories/{workspace}/{repo_slug}/forks
# --links shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
export def "repositories-forks create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --fork-policy: string@fork-policy-completer # Controls the rules for forking this repository. * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot be made public later) * **no_forks**: deny all forking
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --has-issues: oneof<nothing, bool>
  --has-wiki: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --language: string
  --links: record # shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
  --mainbranch: any
  --name: string
  --owner: any
  --parent: any
  --project: any
  --scm: string@scm-completer
  --size: int
  --updated-on: string # format: date-time
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
]: any -> record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<links: record>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/forks"))
  let req_body = {"type": $type, "created_on": $created_on, "description": $description, "fork_policy": $fork_policy, "full_name": $full_name, "has_issues": $has_issues, "has_wiki": $has_wiki, "is_private": $is_private, "language": $language, "links": $links, "mainbranch": $mainbranch, "name": $name, "owner": $owner, "parent": $parent, "project": $project, "scm": $scm, "size": $size, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List webhooks for a repository
#
# GET /repositories/{workspace}/{repo_slug}/hooks
export def "repositories-hooks list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, active: bool, created_at: string, description: string, events: list, subject: record, subject_type: string, url: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/hooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a webhook for a repository
#
# POST /repositories/{workspace}/{repo_slug}/hooks
export def "repositories-hooks create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/hooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a webhook for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/hooks/{uid}
export def "repositories-hooks delete" [
  workspace: string
  repo_slug: string
  uid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), uid: (encode-path-segment $uid)} | format pattern "/repositories/{workspace}/{repo_slug}/hooks/{uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a webhook for a repository
#
# GET /repositories/{workspace}/{repo_slug}/hooks/{uid}
export def "repositories-hooks get" [
  workspace: string
  repo_slug: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), uid: (encode-path-segment $uid)} | format pattern "/repositories/{workspace}/{repo_slug}/hooks/{uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a webhook for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/hooks/{uid}
export def "repositories-hooks update" [
  workspace: string
  repo_slug: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), uid: (encode-path-segment $uid)} | format pattern "/repositories/{workspace}/{repo_slug}/hooks/{uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List issues
#
# GET /repositories/{workspace}/{repo_slug}/issues
export def "repositories-issues list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, assignee: record, component: record, content: record, created_on: string, edited_on: string, id: int, kind: string, links: record, milestone: record, priority: string, reporter: record, repository: record, state: string, title: string, updated_on: string, version: record, votes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/issues"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues
# --content shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
# --links shape: {attachments?: record, comments?: record, html?: record, self?: record, vote?: record, watch?: record}
export def "repositories-issues create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --assignee: any
  --component: any
  --content: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --created-on: string # format: date-time
  --edited-on: string # format: date-time
  --id: int
  --kind: string@kind-completer
  --links: record # shape: {attachments?: record, comments?: record, html?: record, self?: record, vote?: record, watch?: record}
  --milestone: any
  --priority: string@priority-completer
  --reporter: any
  --repository: any
  --state: string@state-completer-2
  --title: string
  --updated-on: string # format: date-time
  --version: any
  --votes: int
]: any -> record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/issues"))
  let req_body = {"type": $type, "assignee": $assignee, "component": $component, "content": $content, "created_on": $created_on, "edited_on": $edited_on, "id": $id, "kind": $kind, "links": $links, "milestone": $milestone, "priority": $priority, "reporter": $reporter, "repository": $repository, "state": $state, "title": $title, "updated_on": $updated_on, "version": $version, "votes": $votes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Export issues
#
# POST /repositories/{workspace}/{repo_slug}/issues/export
export def "repositories-issues-export create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-attachments: oneof<nothing, bool>
  --project-key: string
  --project-name: string
  --send-email: oneof<nothing, bool>
  type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/export"))
  let req_body = {"include_attachments": $include_attachments, "project_key": $project_key, "project_name": $project_name, "send_email": $send_email, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Check issue export status
#
# GET /repositories/{workspace}/{repo_slug}/issues/export/{repo_name}-issues-{task_id}.zip
export def "repositories-issues-export get" [
  workspace: string
  repo_slug: string
  repo_name: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, pct: float, phase: string, status: string, total: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($repo_name | is-empty) { error make --unspanned { msg: "path parameter 'repo_name' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), repo_name: (encode-path-segment $repo_name), task_id: (encode-path-segment $task_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/export/{repo_name}-issues-{task_id}.zip"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check issue import status
#
# GET /repositories/{workspace}/{repo_slug}/issues/import
export def "repositories-issues-import get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, pct: float, phase: string, status: string, total: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/import"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Import issues
#
# POST /repositories/{workspace}/{repo_slug}/issues/import
export def "repositories-issues-import create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, pct: float, phase: string, status: string, total: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/import"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}
export def "repositories-issues delete" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}
export def "repositories-issues get" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}
export def "repositories-issues update" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List attachments for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments
export def "repositories-issues-attachments list" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload an attachment to an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments
export def "repositories-issues-attachments create" [
  workspace: string
  repo_slug: string
  issue_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete an attachment for an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}
export def "repositories-issues-attachments delete" [
  workspace: string
  repo_slug: string
  issue_id: string
  path: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id), path: (encode-path-segment $path)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get attachment for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}
export def "repositories-issues-attachments get" [
  workspace: string
  repo_slug: string
  issue_id: string
  path: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id), path: (encode-path-segment $path)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List changes on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes
export def "repositories-issues-changes list" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --qp-sort: string # Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<changes: record, created_on: string, issue: record, links: record, message: record, name: string, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# Modify the state of an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes
# --changes shape: {assignee?: record, component?: record, content?: record, kind?: record, milestone?: record, priority?: record, state?: record, title?: record, version?: record}
# --links shape: {issue?: record, self?: record}
# --message shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
export def "repositories-issues-changes create" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --changes: record # shape: {assignee?: record, component?: record, content?: record, kind?: record, milestone?: record, priority?: record, state?: record, title?: record, version?: record}
  --created-on: string # format: date-time
  --issue: any
  --links: record # shape: {issue?: record, self?: record}
  --message: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --name: string
  type: string
  --user: any
]: any -> record<changes: record<assignee: record<new: string, old: string>, component: record<new: string, old: string>, content: record<new: string, old: string>, kind: record<new: string, old: string>, milestone: record<new: string, old: string>, priority: record<new: string, old: string>, state: record<new: string, old: string>, title: record<new: string, old: string>, version: record<new: string, old: string>>, created_on: string, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>, links: record<issue: record<href: string, name: string>, self: record<href: string, name: string>>, message: record<html: string, markup: string, raw: string>, name: string, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes"))
  let req_body = {"changes": $changes, "created_on": $created_on, "issue": $issue, "links": $links, "message": $message, "name": $name, "type": $type, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get issue change object
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes/{change_id}
export def "repositories-issues-changes get" [
  workspace: string
  repo_slug: string
  issue_id: string
  change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: record<assignee: record<new: string, old: string>, component: record<new: string, old: string>, content: record<new: string, old: string>, kind: record<new: string, old: string>, milestone: record<new: string, old: string>, priority: record<new: string, old: string>, state: record<new: string, old: string>, title: record<new: string, old: string>, version: record<new: string, old: string>>, created_on: string, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>, links: record<issue: record<href: string, name: string>, self: record<href: string, name: string>>, message: record<html: string, markup: string, raw: string>, name: string, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  if ($change_id | is-empty) { error make --unspanned { msg: "path parameter 'change_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id), change_id: (encode-path-segment $change_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes/{change_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List comments on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments
export def "repositories-issues-comments list" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<issue: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create a comment on an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments
export def "repositories-issues-comments create" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --issue: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments"))
  let req_body = {"issue": $issue} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a comment on an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
export def "repositories-issues-comments delete" [
  workspace: string
  repo_slug: string
  issue_id: string
  comment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a comment on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
export def "repositories-issues-comments get" [
  workspace: string
  repo_slug: string
  issue_id: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a comment on an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
export def "repositories-issues-comments update" [
  workspace: string
  repo_slug: string
  issue_id: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --issue: any
]: any -> record<issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}"))
  let req_body = {"issue": $issue} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove vote for an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
export def "repositories-issues-vote delete" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<data: record, detail: string, message: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if current user voted for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
export def "repositories-issues-vote get" [
  workspace: string
  repo_slug: string
  issue_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Vote for an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
export def "repositories-issues-vote update" [
  workspace: string
  repo_slug: string
  issue_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stop watching an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
export def "repositories-issues-watch delete" [
  workspace: string
  repo_slug: string
  issue_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if current user is watching a issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
export def "repositories-issues-watch get" [
  workspace: string
  repo_slug: string
  issue_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Watch an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
export def "repositories-issues-watch update" [
  workspace: string
  repo_slug: string
  issue_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($issue_id | is-empty) { error make --unspanned { msg: "path parameter 'issue_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), issue_id: (encode-path-segment $issue_id)} | format pattern "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the common ancestor between two commits
#
# GET /repositories/{workspace}/{repo_slug}/merge-base/{revspec}
export def "repositories-merge-base get" [
  workspace: string
  repo_slug: string
  revspec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: any, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($revspec | is-empty) { error make --unspanned { msg: "path parameter 'revspec' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), revspec: (encode-path-segment $revspec)} | format pattern "/repositories/{workspace}/{repo_slug}/merge-base/{revspec}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List milestones
#
# GET /repositories/{workspace}/{repo_slug}/milestones
export def "repositories-milestones list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/milestones"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a milestone
#
# GET /repositories/{workspace}/{repo_slug}/milestones/{milestone_id}
export def "repositories-milestones get" [
  workspace: string
  repo_slug: string
  milestone_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($milestone_id | is-empty) { error make --unspanned { msg: "path parameter 'milestone_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), milestone_id: (encode-path-segment $milestone_id)} | format pattern "/repositories/{workspace}/{repo_slug}/milestones/{milestone_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve the inheritance state for repository settings
#
# GET /repositories/{workspace}/{repo_slug}/override-settings
export def "repositories-override-settings get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<override_settings: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/override-settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set the inheritance state for repository settings
#
# PUT /repositories/{workspace}/{repo_slug}/override-settings
export def "repositories-override-settings update" [
  workspace: string
  repo_slug: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/override-settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a patch for two commits
#
# GET /repositories/{workspace}/{repo_slug}/patch/{spec}
export def "repositories-patch get" [
  workspace: string
  repo_slug: string
  spec: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($spec | is-empty) { error make --unspanned { msg: "path parameter 'spec' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), spec: (encode-path-segment $spec)} | format pattern "/repositories/{workspace}/{repo_slug}/patch/{spec}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List explicit group permissions for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/groups
export def "repositories-permissions-config-groups list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<group: record, links: record, permission: string, repository: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/permissions-config/groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete an explicit group permission for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
export def "repositories-permissions-config-groups delete" [
  workspace: string
  repo_slug: string
  group_slug: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($group_slug | is-empty) { error make --unspanned { msg: "path parameter 'group_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), group_slug: (encode-path-segment $group_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an explicit group permission for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
export def "repositories-permissions-config-groups get" [
  workspace: string
  repo_slug: string
  group_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<group: record<type: string, full_slug: string, links: record<html: record, self: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, slug: string, workspace: record<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>>, links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($group_slug | is-empty) { error make --unspanned { msg: "path parameter 'group_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), group_slug: (encode-path-segment $group_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an explicit group permission for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
export def "repositories-permissions-config-groups update" [
  workspace: string
  repo_slug: string
  group_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<group: record<type: string, full_slug: string, links: record<html: record, self: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, slug: string, workspace: record<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>>, links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($group_slug | is-empty) { error make --unspanned { msg: "path parameter 'group_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), group_slug: (encode-path-segment $group_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List explicit user permissions for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/users
export def "repositories-permissions-config-users list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, permission: string, repository: record, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/permissions-config/users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete an explicit user permission for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
export def "repositories-permissions-config-users delete" [
  workspace: string
  repo_slug: string
  selected_user_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($selected_user_id | is-empty) { error make --unspanned { msg: "path parameter 'selected_user_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), selected_user_id: (encode-path-segment $selected_user_id)} | format pattern "/repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an explicit user permission for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
export def "repositories-permissions-config-users get" [
  workspace: string
  repo_slug: string
  selected_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string, user: record<account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, links: record<avatar: record, html: record, repositories: record, self: record>, nickname: string, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($selected_user_id | is-empty) { error make --unspanned { msg: "path parameter 'selected_user_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), selected_user_id: (encode-path-segment $selected_user_id)} | format pattern "/repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an explicit user permission for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
export def "repositories-permissions-config-users update" [
  workspace: string
  repo_slug: string
  selected_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string, user: record<account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, links: record<avatar: record, html: record, repositories: record, self: record>, nickname: string, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($selected_user_id | is-empty) { error make --unspanned { msg: "path parameter 'selected_user_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), selected_user_id: (encode-path-segment $selected_user_id)} | format pattern "/repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete caches
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines-config/caches
# operationId: deleteRepositoryPipelineCaches
export def "repositories-pipelines-config-caches delete-repository-by-workspace-repo-slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The cache name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines-config/caches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name} | compact), body: null}
}

# List caches
#
# GET /repositories/{workspace}/{repo_slug}/pipelines-config/caches/
# operationId: getRepositoryPipelineCaches
export def "repositories-pipelines-config-caches get-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, file_size_bytes: int, key_hash: string, name: string, path: string, pipeline_uuid: string, step_uuid: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines-config/caches/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a cache
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}
# operationId: deleteRepositoryPipelineCache
export def "repositories-pipelines-config-caches delete-repository-by-workspace-repo-slug-cache-uuid" [
  workspace: string
  repo_slug: string
  cache_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($cache_uuid | is-empty) { error make --unspanned { msg: "path parameter 'cache_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), cache_uuid: (encode-path-segment $cache_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get cache content URI
#
# GET /repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}/content-uri
# operationId: getRepositoryPipelineCacheContentURI
export def "repositories-pipelines-config-caches-content-uri get-repository" [
  workspace: string
  repo_slug: string
  cache_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($cache_uuid | is-empty) { error make --unspanned { msg: "path parameter 'cache_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), cache_uuid: (encode-path-segment $cache_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}/content-uri"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List pipelines
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/
# operationId: getPipelinesForRepository
export def "repositories-pipelines list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record, repository: record, state: record, target: record, trigger: record, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Run a pipeline
#
# POST /repositories/{workspace}/{repo_slug}/pipelines/
# operationId: createPipelineForRepository
export def "repositories-pipelines create-for-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --build-number: int # The build number of the pipeline.
  --build-seconds-used: int # The number of build seconds used by this pipeline.
  --completed-on: string # The timestamp when the Pipeline was completed. This is not set if the pipeline is still in progress. (format: date-time)
  --created-on: string # The timestamp when the pipeline was created. (format: date-time)
  --creator: any
  --repository: any
  --state: any
  --target: any
  --trigger: any
  --uuid: string # The UUID identifying the pipeline.
]: any -> record<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: record<type: string>, target: record<type: string>, trigger: record<type: string>, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/"))
  let req_body = {"type": $type, "build_number": $build_number, "build_seconds_used": $build_seconds_used, "completed_on": $completed_on, "created_on": $created_on, "creator": $creator, "repository": $repository, "state": $state, "target": $target, "trigger": $trigger, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}
# operationId: getPipelineForRepository
export def "repositories-pipelines get-for-repository" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: record<type: string>, target: record<type: string>, trigger: record<type: string>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List steps for a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/
# operationId: getPipelineStepsForRepository
export def "repositories-pipelines-steps list" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, completed_on: string, image: record, script_commands: list, setup_commands: list, started_on: string, state: record, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a step of a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}
# operationId: getPipelineStepForRepository
export def "repositories-pipelines-steps get-for-repository" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, completed_on: string, image: record<email: string, name: string, password: string, username: string>, script_commands: table<command: string, name: string>, setup_commands: table<command: string, name: string>, started_on: string, state: record<type: string>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  if ($step_uuid | is-empty) { error make --unspanned { msg: "path parameter 'step_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid), step_uuid: (encode-path-segment $step_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get log file for a step
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/log
# operationId: getPipelineStepLogForRepository
export def "repositories-pipelines-steps-log get-for-repository" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  if ($step_uuid | is-empty) { error make --unspanned { msg: "path parameter 'step_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid), step_uuid: (encode-path-segment $step_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/log"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the logs for the build container or a service container for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/logs/{log_uuid}
# operationId: getPipelineContainerLog
export def "repositories-pipelines-steps-logs get-container" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  log_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  if ($step_uuid | is-empty) { error make --unspanned { msg: "path parameter 'step_uuid' must be non-empty" } }
  if ($log_uuid | is-empty) { error make --unspanned { msg: "path parameter 'log_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid), step_uuid: (encode-path-segment $step_uuid), log_uuid: (encode-path-segment $log_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/logs/{log_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a summary of test reports for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports
# operationId: getPipelineTestReports
export def "repositories-pipelines-steps-test-reports get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  if ($step_uuid | is-empty) { error make --unspanned { msg: "path parameter 'step_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid), step_uuid: (encode-path-segment $step_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get test cases for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases
# operationId: getPipelineTestReportTestCases
export def "repositories-pipelines-steps-test-reports-test-cases get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  if ($step_uuid | is-empty) { error make --unspanned { msg: "path parameter 'step_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid), step_uuid: (encode-path-segment $step_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get test case reasons (output) for a given test case in a step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases/{test_case_uuid}/test_case_reasons
# operationId: getPipelineTestReportTestCaseReasons
export def "repositories-pipelines-steps-test-reports-test-cases-test-case-reasons get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  test_case_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  if ($step_uuid | is-empty) { error make --unspanned { msg: "path parameter 'step_uuid' must be non-empty" } }
  if ($test_case_uuid | is-empty) { error make --unspanned { msg: "path parameter 'test_case_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid), step_uuid: (encode-path-segment $step_uuid), test_case_uuid: (encode-path-segment $test_case_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases/{test_case_uuid}/test_case_reasons"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stop a pipeline
#
# POST /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/stopPipeline
# operationId: stopPipeline
export def "repositories-pipelines-stop-pipeline stop" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pipeline_uuid | is-empty) { error make --unspanned { msg: "path parameter 'pipeline_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pipeline_uuid: (encode-path-segment $pipeline_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/stopPipeline"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get configuration
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config
# operationId: getRepositoryPipelineConfig
export def "repositories-pipelines-config get-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, enabled: bool, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update configuration
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config
# operationId: updateRepositoryPipelineConfig
export def "repositories-pipelines-config update-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --enabled: oneof<nothing, bool> # Whether Pipelines is enabled for the repository.
  --repository: any
]: any -> record<type: string, enabled: bool, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config"))
  let req_body = {"type": $type, "enabled": $enabled, "repository": $repository} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update the next build number
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/build_number
# operationId: updateRepositoryBuildNumber
export def "repositories-pipelines-config-build-number update-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --next: int # The next number that will be used as build number.
]: any -> record<type: string, next: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/build_number"))
  let req_body = {"type": $type, "next": $next} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List schedules
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/
# operationId: getRepositoryPipelineSchedules
export def "repositories-pipelines-config-schedules list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record, target: record, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a schedule
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/
# operationId: createRepositoryPipelineSchedule
export def "repositories-pipelines-config-schedules create-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # The timestamp when the schedule was created. (format: date-time)
  --cron-pattern: string # The cron expression that the schedule applies.
  --enabled: oneof<nothing, bool> # Whether the schedule is enabled.
  --selector: any
  --target: any
  --updated-on: string # The timestamp when the schedule was updated. (format: date-time)
  --uuid: string # The UUID identifying the schedule.
]: any -> record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/"))
  let req_body = {"type": $type, "created_on": $created_on, "cron_pattern": $cron_pattern, "enabled": $enabled, "selector": $selector, "target": $target, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a schedule
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# operationId: deleteRepositoryPipelineSchedule
export def "repositories-pipelines-config-schedules delete-repository" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($schedule_uuid | is-empty) { error make --unspanned { msg: "path parameter 'schedule_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), schedule_uuid: (encode-path-segment $schedule_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a schedule
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# operationId: getRepositoryPipelineSchedule
export def "repositories-pipelines-config-schedules get-repository" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($schedule_uuid | is-empty) { error make --unspanned { msg: "path parameter 'schedule_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), schedule_uuid: (encode-path-segment $schedule_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a schedule
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# operationId: updateRepositoryPipelineSchedule
export def "repositories-pipelines-config-schedules update-repository" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # The timestamp when the schedule was created. (format: date-time)
  --cron-pattern: string # The cron expression that the schedule applies.
  --enabled: oneof<nothing, bool> # Whether the schedule is enabled.
  --selector: any
  --target: any
  --updated-on: string # The timestamp when the schedule was updated. (format: date-time)
  --uuid: string # The UUID identifying the schedule.
]: any -> record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($schedule_uuid | is-empty) { error make --unspanned { msg: "path parameter 'schedule_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), schedule_uuid: (encode-path-segment $schedule_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}"))
  let req_body = {"type": $type, "created_on": $created_on, "cron_pattern": $cron_pattern, "enabled": $enabled, "selector": $selector, "target": $target, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List executions of a schedule
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}/executions/
# operationId: getRepositoryPipelineScheduleExecutions
export def "repositories-pipelines-config-schedules-executions get-repository" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($schedule_uuid | is-empty) { error make --unspanned { msg: "path parameter 'schedule_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), schedule_uuid: (encode-path-segment $schedule_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}/executions/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete SSH key pair
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# operationId: deleteRepositoryPipelineKeyPair
export def "repositories-pipelines-config-ssh-key-pair delete-repository" [
  workspace: string
  repo_slug: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get SSH key pair
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# operationId: getRepositoryPipelineSshKeyPair
export def "repositories-pipelines-config-ssh-key-pair get-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, private_key: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update SSH key pair
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# operationId: updateRepositoryPipelineKeyPair
export def "repositories-pipelines-config-ssh-key-pair update-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --private-key: string # The SSH private key. This value will be empty when retrieving the SSH key pair.
  --public-key: string # The SSH public key.
]: any -> record<type: string, private_key: string, public_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair"))
  let req_body = {"type": $type, "private_key": $private_key, "public_key": $public_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List known hosts
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/
# operationId: getRepositoryPipelineKnownHosts
export def "repositories-pipelines-config-ssh-known-hosts list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, hostname: string, public_key: record, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a known host
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/
# operationId: createRepositoryPipelineKnownHost
export def "repositories-pipelines-config-ssh-known-hosts create-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --hostname: string # The hostname of the known host.
  --public-key: any
  --uuid: string # The UUID identifying the known host.
]: any -> record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/"))
  let req_body = {"type": $type, "hostname": $hostname, "public_key": $public_key, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a known host
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# operationId: deleteRepositoryPipelineKnownHost
export def "repositories-pipelines-config-ssh-known-hosts delete-repository" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($known_host_uuid | is-empty) { error make --unspanned { msg: "path parameter 'known_host_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), known_host_uuid: (encode-path-segment $known_host_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a known host
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# operationId: getRepositoryPipelineKnownHost
export def "repositories-pipelines-config-ssh-known-hosts get-repository" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($known_host_uuid | is-empty) { error make --unspanned { msg: "path parameter 'known_host_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), known_host_uuid: (encode-path-segment $known_host_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a known host
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# operationId: updateRepositoryPipelineKnownHost
export def "repositories-pipelines-config-ssh-known-hosts update-repository" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --hostname: string # The hostname of the known host.
  --public-key: any
  --uuid: string # The UUID identifying the known host.
]: any -> record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($known_host_uuid | is-empty) { error make --unspanned { msg: "path parameter 'known_host_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), known_host_uuid: (encode-path-segment $known_host_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}"))
  let req_body = {"type": $type, "hostname": $hostname, "public_key": $public_key, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List variables for a repository
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/variables/
# operationId: getRepositoryPipelineVariables
export def "repositories-pipelines-config-variables list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a variable for a repository
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/variables/
# operationId: createRepositoryPipelineVariable
export def "repositories-pipelines-config-variables create-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a variable for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# operationId: deleteRepositoryPipelineVariable
export def "repositories-pipelines-config-variables delete-repository" [
  workspace: string
  repo_slug: string
  variable_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a variable for a repository
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# operationId: getRepositoryPipelineVariable
export def "repositories-pipelines-config-variables get-repository" [
  workspace: string
  repo_slug: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a variable for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# operationId: updateRepositoryPipelineVariable
export def "repositories-pipelines-config-variables update-repository" [
  workspace: string
  repo_slug: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a repository application property
#
# DELETE /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# operationId: deleteRepositoryHostedPropertyValue
export def "repositories-properties delete-repository-hosted-value" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a repository application property
#
# GET /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# operationId: getRepositoryHostedPropertyValue
export def "repositories-properties get-repository-hosted-value" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_attributes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a repository application property
#
# PUT /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# operationId: updateRepositoryHostedPropertyValue
export def "repositories-properties update-repository-hosted-value" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}"))
  let req_body = {"_attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List pull requests
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests
export def "repositories-pullrequests list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Only return pull requests that are in this state. This parameter can be repeated.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"state": $state} | compact), body: null}
}

# Create a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests
# --destination shape: {branch?: record, commit?: record, repository?: any}
# --links shape: {activity?: record, approve?: record, comments?: record, commits?: record, decline?: record, diff?: record, diffstat?: record, html?: record, merge?: record, self?: record}
# --merge_commit shape: {hash?: string}
# --participants item shape: {type: string, approved?: bool, participated_on?: string, role?: "PARTICIPANT"|"REVIEWER", state?: "approved"|"changes_requested"|"", user?: any}
# --rendered shape: {description?: record, reason?: record, title?: record}
# --reviewers item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
# --source shape: {branch?: record, commit?: record, repository?: any}
# --summary shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
export def "repositories-pullrequests create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --author: any
  --close-source-branch: oneof<nothing, bool> # A boolean flag indicating if merging the pull request closes the source branch.
  --closed-by: any
  --comment-count: int # The number of comments for a specific pull request.
  --created-on: string # The ISO8601 timestamp the request was created. (format: date-time)
  --destination: record # shape: {branch?: record, commit?: record, repository?: any}
  --id: int # The pull request's unique ID. Note that pull request IDs are only unique within their associated repository.
  --links: record # shape: {activity?: record, approve?: record, comments?: record, commits?: record, decline?: record, diff?: record, diffstat?: record, html?: record, merge?: record, self?: record}
  --merge-commit: record # shape: {hash?: string}
  --participants: list # The list of users that are collaborating on this pull request. Collaborators are user that: * are added to the pull request as a reviewer (part of the reviewers list) * are not explicit reviewers, but have commented on the pull request * are not explicit reviewers, but have approved the pull request Each user is wrapped in an object that indicates the user's role and whether they have approved the pull request. For performance reasons, the API only returns this list when an API requests a pull request by id. — item shape: {type: string, approved?: bool, participated_on?: string, role?: "PARTICIPANT"|"REVIEWER", state?: "approved"|"changes_requested"|"", user?: any}
  --reason: string # Explains why a pull request was declined. This field is only applicable to pull requests in rejected state.
  --rendered: record # User provided pull request text, interpreted in a markup language and rendered in HTML — shape: {description?: record, reason?: record, title?: record}
  --reviewers: list # The list of users that were added as reviewers on this pull request when it was created. For performance reasons, the API only includes this list on a pull request's `self` URL. — item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --body-source: record # shape: {branch?: record, commit?: record, repository?: any}
  --state: string@state-completer # The pull request's current status.
  --summary: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --task-count: int # The number of open tasks for a specific pull request.
  --title: string # Title of the pull request.
  --updated-on: string # The ISO8601 timestamp the request was last updated. (format: date-time)
]: any -> record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests"))
  let req_body = {"type": $type, "author": $author, "close_source_branch": $close_source_branch, "closed_by": $closed_by, "comment_count": $comment_count, "created_on": $created_on, "destination": $destination, "id": $id, "links": $links, "merge_commit": $merge_commit, "participants": $participants, "reason": $reason, "rendered": $rendered, "reviewers": $reviewers, "source": $body_source, "state": $state, "summary": $summary, "task_count": $task_count, "title": $title, "updated_on": $updated_on} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List a pull request activity log
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/activity
export def "repositories-pullrequests-activity list" [
  workspace: string
  repo_slug: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/activity"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}
export def "repositories-pullrequests get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a pull request
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}
# --destination shape: {branch?: record, commit?: record, repository?: any}
# --links shape: {activity?: record, approve?: record, comments?: record, commits?: record, decline?: record, diff?: record, diffstat?: record, html?: record, merge?: record, self?: record}
# --merge_commit shape: {hash?: string}
# --participants item shape: {type: string, approved?: bool, participated_on?: string, role?: "PARTICIPANT"|"REVIEWER", state?: "approved"|"changes_requested"|"", user?: any}
# --rendered shape: {description?: record, reason?: record, title?: record}
# --reviewers item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
# --source shape: {branch?: record, commit?: record, repository?: any}
# --summary shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
export def "repositories-pullrequests update" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --author: any
  --close-source-branch: oneof<nothing, bool> # A boolean flag indicating if merging the pull request closes the source branch.
  --closed-by: any
  --comment-count: int # The number of comments for a specific pull request.
  --created-on: string # The ISO8601 timestamp the request was created. (format: date-time)
  --destination: record # shape: {branch?: record, commit?: record, repository?: any}
  --id: int # The pull request's unique ID. Note that pull request IDs are only unique within their associated repository.
  --links: record # shape: {activity?: record, approve?: record, comments?: record, commits?: record, decline?: record, diff?: record, diffstat?: record, html?: record, merge?: record, self?: record}
  --merge-commit: record # shape: {hash?: string}
  --participants: list # The list of users that are collaborating on this pull request. Collaborators are user that: * are added to the pull request as a reviewer (part of the reviewers list) * are not explicit reviewers, but have commented on the pull request * are not explicit reviewers, but have approved the pull request Each user is wrapped in an object that indicates the user's role and whether they have approved the pull request. For performance reasons, the API only returns this list when an API requests a pull request by id. — item shape: {type: string, approved?: bool, participated_on?: string, role?: "PARTICIPANT"|"REVIEWER", state?: "approved"|"changes_requested"|"", user?: any}
  --reason: string # Explains why a pull request was declined. This field is only applicable to pull requests in rejected state.
  --rendered: record # User provided pull request text, interpreted in a markup language and rendered in HTML — shape: {description?: record, reason?: record, title?: record}
  --reviewers: list # The list of users that were added as reviewers on this pull request when it was created. For performance reasons, the API only includes this list on a pull request's `self` URL. — item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --body-source: record # shape: {branch?: record, commit?: record, repository?: any}
  --state: string@state-completer # The pull request's current status.
  --summary: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --task-count: int # The number of open tasks for a specific pull request.
  --title: string # Title of the pull request.
  --updated-on: string # The ISO8601 timestamp the request was last updated. (format: date-time)
]: any -> record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}"))
  let req_body = {"type": $type, "author": $author, "close_source_branch": $close_source_branch, "closed_by": $closed_by, "comment_count": $comment_count, "created_on": $created_on, "destination": $destination, "id": $id, "links": $links, "merge_commit": $merge_commit, "participants": $participants, "reason": $reason, "rendered": $rendered, "reviewers": $reviewers, "source": $body_source, "state": $state, "summary": $summary, "task_count": $task_count, "title": $title, "updated_on": $updated_on} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List a pull request activity log
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/activity
export def "repositories-pullrequests-activity get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/activity"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Unapprove a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve
export def "repositories-pullrequests-approve delete" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Approve a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve
export def "repositories-pullrequests-approve create" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List comments on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
export def "repositories-pullrequests-comments list" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<pullrequest: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a comment on a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
export def "repositories-pullrequests-comments create" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pullrequest: any
]: any -> record<pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments"))
  let req_body = {"pullrequest": $pullrequest} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a comment on a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
export def "repositories-pullrequests-comments delete" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  comment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a comment on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
export def "repositories-pullrequests-comments get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a comment on a pull request
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
export def "repositories-pullrequests-comments update" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pullrequest: any
]: any -> record<pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}"))
  let req_body = {"pullrequest": $pullrequest} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List commits on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/commits
export def "repositories-pullrequests-commits get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/commits"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Decline a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/decline
export def "repositories-pullrequests-decline create" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/decline"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List changes in a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diff
export def "repositories-pullrequests-diff get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diff"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the diff stat for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diffstat
export def "repositories-pullrequests-diffstat get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diffstat"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Merge a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge
export def "repositories-pullrequests-merge create" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool> # Default value is false. When set to true, runs merge asynchronously and immediately returns a 202 with polling link to the task-status API in the Location header. When set to false, runs merge and waits for it to complete, returning 200 when it succeeds. If the duration of the merge exceeds a timeout threshold, the API returns a 202 with polling link to the task-status API in the Location header.
  --close-source-branch: oneof<nothing, bool> # Whether the source branch should be deleted. If this is not provided, we fallback to the value used when the pull request was created, which defaults to False
  --merge-strategy: string@merge-strategy-completer # The merge strategy that will be used to merge the pull request. (default: merge_commit)
  --message: string # The commit message that will be used on the resulting commit.
  type: string
]: any -> record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge") $qp)
  let req_body = {"close_source_branch": $close_source_branch, "merge_strategy": $merge_strategy, "message": $message, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"async": $async} | compact), body: $req_body}
}

# Get the merge task status for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge/task-status/{task_id}
export def "repositories-pullrequests-merge-task-status get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  task_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id), task_id: (encode-path-segment $task_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge/task-status/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the patch for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/patch
export def "repositories-pullrequests-patch get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/patch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove change request for a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes
export def "repositories-pullrequests-request-changes delete" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Request changes for a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes
export def "repositories-pullrequests-request-changes create" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List commit statuses for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/statuses
export def "repositories-pullrequests-statuses get" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). Defaults to `created_on`.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, key: string, links: record, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pull_request_id | is-empty) { error make --unspanned { msg: "path parameter 'pull_request_id' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pull_request_id: (encode-path-segment $pull_request_id)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/statuses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# Delete a pull request application property
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# operationId: deletePullRequestHostedPropertyValue
export def "repositories-pullrequests-properties delete-pull-request-hosted-value" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pullrequest_id | is-empty) { error make --unspanned { msg: "path parameter 'pullrequest_id' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pullrequest_id: (encode-path-segment $pullrequest_id), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a pull request application property
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# operationId: getPullRequestHostedPropertyValue
export def "repositories-pullrequests-properties get-pull-request-hosted-value" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_attributes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pullrequest_id | is-empty) { error make --unspanned { msg: "path parameter 'pullrequest_id' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pullrequest_id: (encode-path-segment $pullrequest_id), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a pull request application property
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# operationId: updatePullRequestHostedPropertyValue
export def "repositories-pullrequests-properties update-pull-request-hosted-value" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($pullrequest_id | is-empty) { error make --unspanned { msg: "path parameter 'pullrequest_id' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), pullrequest_id: (encode-path-segment $pullrequest_id), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}"))
  let req_body = {"_attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List branches and tags
#
# GET /repositories/{workspace}/{repo_slug}/refs
export def "repositories-refs get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for refs in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['1.1', '1.2', '1.10'] instead of ['1.1', '1.10', '1.2'].
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/refs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# List open branches
#
# GET /repositories/{workspace}/{repo_slug}/refs/branches
export def "repositories-refs-branches list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for branches in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['branch1', 'branch2', 'branch10'] instead of ['branch1', 'branch10', 'branch2'].
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/refs/branches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# Create a branch
#
# POST /repositories/{workspace}/{repo_slug}/refs/branches
export def "repositories-refs-branches create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: any, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, default_merge_strategy: string, merge_strategies: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/refs/branches"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a branch
#
# DELETE /repositories/{workspace}/{repo_slug}/refs/branches/{name}
export def "repositories-refs-branches delete" [
  workspace: string
  repo_slug: string
  name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), name: (encode-path-segment $name)} | format pattern "/repositories/{workspace}/{repo_slug}/refs/branches/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a branch
#
# GET /repositories/{workspace}/{repo_slug}/refs/branches/{name}
export def "repositories-refs-branches get" [
  workspace: string
  repo_slug: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: any, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, default_merge_strategy: string, merge_strategies: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), name: (encode-path-segment $name)} | format pattern "/repositories/{workspace}/{repo_slug}/refs/branches/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List tags
#
# GET /repositories/{workspace}/{repo_slug}/refs/tags
export def "repositories-refs-tags list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for tags in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['1.1', '1.2', '1.10'] instead of ['1.1', '1.10', '1.2'].
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string, date: string, message: string, tagger: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/refs/tags") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# Create a tag
#
# POST /repositories/{workspace}/{repo_slug}/refs/tags
# --links shape: {commits?: record, html?: record, self?: record}
export def "repositories-refs-tags create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {commits?: record, html?: record, self?: record}
  --name: string # The name of the ref.
  --target: any
  type: string
  --date: string # The date that the tag was created, if available (format: date-time)
  --message: string # The message associated with the tag, if available.
  --tagger: any
]: any -> record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, date: string, message: string, tagger: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/refs/tags"))
  let req_body = {"links": $links, "name": $name, "target": $target, "type": $type, "date": $date, "message": $message, "tagger": $tagger} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a tag
#
# DELETE /repositories/{workspace}/{repo_slug}/refs/tags/{name}
export def "repositories-refs-tags delete" [
  workspace: string
  repo_slug: string
  name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), name: (encode-path-segment $name)} | format pattern "/repositories/{workspace}/{repo_slug}/refs/tags/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a tag
#
# GET /repositories/{workspace}/{repo_slug}/refs/tags/{name}
export def "repositories-refs-tags get" [
  workspace: string
  repo_slug: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, date: string, message: string, tagger: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), name: (encode-path-segment $name)} | format pattern "/repositories/{workspace}/{repo_slug}/refs/tags/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the root directory of the main branch
#
# GET /repositories/{workspace}/{repo_slug}/src
export def "repositories-src get-by-workspace-repo-slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # Instead of returning the file's contents, return the (json) meta data for it.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<commit: record, path: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/src") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format} | compact), body: null}
}

# Create a commit by uploading a file
#
# POST /repositories/{workspace}/{repo_slug}/src
export def "repositories-src create" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # The commit message. When omitted, Bitbucket uses a canned string.
  --author: string # The raw string to be used as the new commit's author. This string follows the format `Erik van Zijst <evzijst@atlassian.com>`. When omitted, Bitbucket uses the authenticated user's full/display name and primary email address. Commits cannot be created anonymously.
  --parents: string # A comma-separated list of SHA1s of the commits that should be the parents of the newly created commit. When omitted, the new commit will inherit from and become a child of the main branch's tip/HEAD commit. When more than one SHA1 is provided, the first SHA1 identifies the commit from which the content will be inherited.".
  --files: string # Optional field that declares the files that the request is manipulating. When adding a new file to a repo, or when overwriting an existing file, the client can just upload the full contents of the file in a normal form field and the use of this `files` meta data field is redundant. However, when the `files` field contains a file path that does not have a corresponding, identically-named form field, then Bitbucket interprets that as the client wanting to replace the named file with the null set and the file is deleted instead. Paths in the repo that are referenced in neither files nor an individual file field, remain unchanged and carry over from the parent to the new commit. This API does not support renaming as an explicit feature. To rename a file, simply delete it and recreate it under the new name in the same commit.
  --branch: string # The name of the branch that the new commit should be created on. When omitted, the commit will be created on top of the main branch and will become the main branch's new head. When a branch name is provided that already exists in the repo, then the commit will be created on top of that branch. In this case, *if* a parent SHA1 was also provided, then it is asserted that the parent is the branch's tip/HEAD at the time the request is made. When this is not the case, a 409 is returned. When a new branch name is specified (that does not already exist in the repo), and no parent SHA1s are provided, then the new commit will inherit from the current main branch's tip/HEAD commit, but not advance the main branch. The new commit will be the new branch. When the request *also* specifies a parent SHA1, then the new commit and branch are created directly on top of the parent commit, regardless of the state of the main branch. When a branch name is not specified, but a parent SHA1 is provided, then Bitbucket asserts that it represents the main branch's current HEAD/tip, or a 409 is returned. When a branch name is not specified and the repo is empty, the new commit will become the repo's root commit and will be on the main branch. When a branch name is specified and the repo is empty, the new commit will become the repo's root commit and also define the repo's main branch going forward. This API cannot be used to create additional root commits in non-empty repos. The branch field cannot be repeated. As a side effect, this API can be used to create a new branch without modifying any files, by specifying a new branch name in this field, together with `parents`, but omitting the `files` fields, while not sending any files. This will create a new commit and branch with the same contents as the first parent. The diff of this commit against its first parent will be empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "message" $message "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "parents" $parents "scalar") (serialize-qp "files" $files "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/src") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"message": $message, "author": $author, "parents": $parents, "files": $files, "branch": $branch} | compact), body: null}
}

# Get file or directory contents
#
# GET /repositories/{workspace}/{repo_slug}/src/{commit}/{path}
export def "repositories-src get-by-workspace-repo-slug-commit-path" [
  workspace: string
  repo_slug: string
  commit: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1 # If 'meta' is provided, returns the (json) meta data for the contents of the file. If 'rendered' is provided, returns the contents of a non-binary file in HTML-formatted rendered markup. Since Git does not generally track what text encoding scheme is used, this endpoint attempts to detect the most appropriate character encoding. While usually correct, determining the character encoding can be ambiguous which in exceptional cases can lead to misinterpretation of the characters. As such, the raw element in the response object should not be treated as equivalent to the file's actual contents.
  --q: string # Optional filter expression as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Optional sorting parameter as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
  --max-depth: int # If provided, returns the contents of the repository and its subdirectories recursively until the specified max_depth of nested directories. When omitted, this defaults to 1.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<commit: record, path: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($commit | is-empty) { error make --unspanned { msg: "path parameter 'commit' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max_depth" $max_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), commit: (encode-path-segment $commit), path: (encode-path-segment $path)} | format pattern "/repositories/{workspace}/{repo_slug}/src/{commit}/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "q": $q, "sort": $qp_sort, "max_depth": $max_depth} | compact), body: null}
}

# List defined versions for issues
#
# GET /repositories/{workspace}/{repo_slug}/versions
export def "repositories-versions list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/versions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a defined version for issues
#
# GET /repositories/{workspace}/{repo_slug}/versions/{version_id}
export def "repositories-versions get" [
  workspace: string
  repo_slug: string
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'version_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug), version_id: (encode-path-segment $version_id)} | format pattern "/repositories/{workspace}/{repo_slug}/versions/{version_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List repositories watchers
#
# GET /repositories/{workspace}/{repo_slug}/watchers
export def "repositories-watchers get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/repositories/{workspace}/{repo_slug}/watchers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List snippets
#
# GET /snippets
export def "snippets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer-1 # Filter down the result based on the authenticated user's role (`owner`, `contributor`, or `member`).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, creator: record, id: int, is_private: bool, owner: record, scm: string, title: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/snippets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"role": $role} | compact), body: null}
}

# Create a snippet
#
# POST /snippets
export def "snippets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --creator: any
  --id: int
  --is-private: oneof<nothing, bool>
  --owner: any
  --scm: string@scm-completer # The DVCS used to store the snippet.
  --title: string
  --updated-on: string # format: date-time
]: any -> record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/snippets")
  let req_body = {"type": $type, "created_on": $created_on, "creator": $creator, "id": $id, "is_private": $is_private, "owner": $owner, "scm": $scm, "title": $title, "updated_on": $updated_on} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List snippets in a workspace
#
# GET /snippets/{workspace}
export def "snippets get-by-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer-1 # Filter down the result based on the authenticated user's role (`owner`, `contributor`, or `member`).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, creator: record, id: int, is_private: bool, owner: record, scm: string, title: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let qp = [(serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/snippets/{workspace}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"role": $role} | compact), body: null}
}

# Create a snippet for a workspace
#
# POST /snippets/{workspace}
export def "snippets create-by-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --creator: any
  --id: int
  --is-private: oneof<nothing, bool>
  --owner: any
  --scm: string@scm-completer # The DVCS used to store the snippet.
  --title: string
  --updated-on: string # format: date-time
]: any -> record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/snippets/{workspace}"))
  let req_body = {"type": $type, "created_on": $created_on, "creator": $creator, "id": $id, "is_private": $is_private, "owner": $owner, "scm": $scm, "title": $title, "updated_on": $updated_on} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}
export def "snippets delete-by-workspace-encoded-id" [
  workspace: string
  encoded_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a snippet
#
# GET /snippets/{workspace}/{encoded_id}
export def "snippets get-by-workspace-encoded-id" [
  workspace: string
  encoded_id: string
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
]: nothing -> record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a snippet
#
# PUT /snippets/{workspace}/{encoded_id}
export def "snippets update-by-workspace-encoded-id" [
  workspace: string
  encoded_id: string
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
]: nothing -> record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List comments on a snippet
#
# GET /snippets/{workspace}/{encoded_id}/comments
export def "snippets-comments list" [
  workspace: string
  encoded_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, snippet: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a comment on a snippet
#
# POST /snippets/{workspace}/{encoded_id}/comments
# --links shape: {html?: record, self?: record}
export def "snippets-comments create" [
  workspace: string
  encoded_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --links: record # shape: {html?: record, self?: record}
  --snippet: any
]: any -> record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}/comments"))
  let req_body = {"type": $type, "links": $links, "snippet": $snippet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a comment on a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/comments/{comment_id}
export def "snippets-comments delete" [
  workspace: string
  encoded_id: string
  comment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/snippets/{workspace}/{encoded_id}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a comment on a snippet
#
# GET /snippets/{workspace}/{encoded_id}/comments/{comment_id}
export def "snippets-comments get" [
  workspace: string
  encoded_id: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/snippets/{workspace}/{encoded_id}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a comment on a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/comments/{comment_id}
# --links shape: {html?: record, self?: record}
export def "snippets-comments update" [
  workspace: string
  encoded_id: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --links: record # shape: {html?: record, self?: record}
  --snippet: any
]: any -> record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/snippets/{workspace}/{encoded_id}/comments/{comment_id}"))
  let req_body = {"type": $type, "links": $links, "snippet": $snippet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List snippet changes
#
# GET /snippets/{workspace}/{encoded_id}/commits
export def "snippets-commits list" [
  workspace: string
  encoded_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, snippet: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}/commits"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a previous snippet change
#
# GET /snippets/{workspace}/{encoded_id}/commits/{revision}
export def "snippets-commits get" [
  workspace: string
  encoded_id: string
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
]: nothing -> record<links: record<diff: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($revision | is-empty) { error make --unspanned { msg: "path parameter 'revision' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), revision: (encode-path-segment $revision)} | format pattern "/snippets/{workspace}/{encoded_id}/commits/{revision}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a snippet's raw file at HEAD
#
# GET /snippets/{workspace}/{encoded_id}/files/{path}
export def "snippets-files list" [
  workspace: string
  encoded_id: string
  path: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), path: (encode-path-segment $path)} | format pattern "/snippets/{workspace}/{encoded_id}/files/{path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stop watching a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/watch
export def "snippets-watch delete" [
  workspace: string
  encoded_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}/watch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if the current user is watching a snippet
#
# GET /snippets/{workspace}/{encoded_id}/watch
export def "snippets-watch get" [
  workspace: string
  encoded_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}/watch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Watch a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/watch
export def "snippets-watch update" [
  workspace: string
  encoded_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}/watch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List users watching a snippet
#
# GET /snippets/{workspace}/{encoded_id}/watchers
# DEPRECATED
@deprecated
export def "snippets-watchers get" [
  workspace: string
  encoded_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id)} | format pattern "/snippets/{workspace}/{encoded_id}/watchers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a previous revision of a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/{node_id}
export def "snippets delete-by-workspace-encoded-id-node-id" [
  workspace: string
  encoded_id: string
  node_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), node_id: (encode-path-segment $node_id)} | format pattern "/snippets/{workspace}/{encoded_id}/{node_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a previous revision of a snippet
#
# GET /snippets/{workspace}/{encoded_id}/{node_id}
export def "snippets get-by-workspace-encoded-id-node-id" [
  workspace: string
  encoded_id: string
  node_id: string
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
]: nothing -> record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), node_id: (encode-path-segment $node_id)} | format pattern "/snippets/{workspace}/{encoded_id}/{node_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a previous revision of a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/{node_id}
export def "snippets update-by-workspace-encoded-id-node-id" [
  workspace: string
  encoded_id: string
  node_id: string
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
]: nothing -> record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), node_id: (encode-path-segment $node_id)} | format pattern "/snippets/{workspace}/{encoded_id}/{node_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a snippet's raw file
#
# GET /snippets/{workspace}/{encoded_id}/{node_id}/files/{path}
export def "snippets-files get" [
  workspace: string
  encoded_id: string
  node_id: string
  path: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), node_id: (encode-path-segment $node_id), path: (encode-path-segment $path)} | format pattern "/snippets/{workspace}/{encoded_id}/{node_id}/files/{path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get snippet changes between versions
#
# GET /snippets/{workspace}/{encoded_id}/{revision}/diff
export def "snippets-diff get" [
  workspace: string
  encoded_id: string
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
  --path: string # When used, only one the diff of the specified file will be returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($revision | is-empty) { error make --unspanned { msg: "path parameter 'revision' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), revision: (encode-path-segment $revision)} | format pattern "/snippets/{workspace}/{encoded_id}/{revision}/diff") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path} | compact), body: null}
}

# Get snippet patch between versions
#
# GET /snippets/{workspace}/{encoded_id}/{revision}/patch
export def "snippets-patch get" [
  workspace: string
  encoded_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($encoded_id | is-empty) { error make --unspanned { msg: "path parameter 'encoded_id' must be non-empty" } }
  if ($revision | is-empty) { error make --unspanned { msg: "path parameter 'revision' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), encoded_id: (encode-path-segment $encoded_id), revision: (encode-path-segment $revision)} | format pattern "/snippets/{workspace}/{encoded_id}/{revision}/patch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List variables for an account
#
# GET /teams/{username}/pipelines_config/variables/
# DEPRECATED
# operationId: getPipelineVariablesForTeam
@deprecated
export def "teams-pipelines-config-variables list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/teams/{username}/pipelines_config/variables/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a variable for a user
#
# POST /teams/{username}/pipelines_config/variables/
# DEPRECATED
# operationId: createPipelineVariableForTeam
@deprecated
export def "teams-pipelines-config-variables create" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/teams/{username}/pipelines_config/variables/"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a variable for a team
#
# DELETE /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: deletePipelineVariableForTeam
@deprecated
export def "teams-pipelines-config-variables delete" [
  username: string
  variable_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/teams/{username}/pipelines_config/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a variable for a team
#
# GET /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: getPipelineVariableForTeam
@deprecated
export def "teams-pipelines-config-variables get" [
  username: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/teams/{username}/pipelines_config/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a variable for a team
#
# PUT /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: updatePipelineVariableForTeam
@deprecated
export def "teams-pipelines-config-variables update" [
  username: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/teams/{username}/pipelines_config/variables/{variable_uuid}"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search for code in a team's repositories
#
# GET /teams/{username}/search/code
# operationId: searchTeam
export def "teams-search-code list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # The search query
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "search_query" $search_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/teams/{username}/search/code") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search_query": $search_query, "page": $page, "pagelen": $pagelen} | compact), body: null}
}

# Get current user
#
# GET /user
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List email addresses for current user
#
# GET /user/emails
export def "user-emails list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<data: record, detail: string, message: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an email address for current user
#
# GET /user/emails/{email}
export def "user-emails get" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<data: record, detail: string, message: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($email | is-empty) { error make --unspanned { msg: "path parameter 'email' must be non-empty" } }
  let full_url = (build-url $base ({email: (encode-path-segment $email)} | format pattern "/user/emails/{email}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List repository permissions for a user
#
# GET /user/permissions/repositories
export def "user-permissions-repositories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/permissions/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# List workspaces for the current user
#
# GET /user/permissions/workspaces
export def "user-permissions-workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --qp-sort: string # Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/permissions/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# Get a user
#
# GET /users/{selected_user}
export def "users get" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user)} | format pattern "/users/{selected_user}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List variables for a user
#
# GET /users/{selected_user}/pipelines_config/variables/
# DEPRECATED
# operationId: getPipelineVariablesForUser
@deprecated
export def "users-pipelines-config-variables list" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user)} | format pattern "/users/{selected_user}/pipelines_config/variables/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a variable for a user
#
# POST /users/{selected_user}/pipelines_config/variables/
# DEPRECATED
# operationId: createPipelineVariableForUser
@deprecated
export def "users-pipelines-config-variables create" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user)} | format pattern "/users/{selected_user}/pipelines_config/variables/"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a variable for a user
#
# DELETE /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: deletePipelineVariableForUser
@deprecated
export def "users-pipelines-config-variables delete" [
  selected_user: string
  variable_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/users/{selected_user}/pipelines_config/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a variable for a user
#
# GET /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: getPipelineVariableForUser
@deprecated
export def "users-pipelines-config-variables get" [
  selected_user: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/users/{selected_user}/pipelines_config/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a variable for a user
#
# PUT /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: updatePipelineVariableForUser
@deprecated
export def "users-pipelines-config-variables update" [
  selected_user: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/users/{selected_user}/pipelines_config/variables/{variable_uuid}"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a user application property
#
# DELETE /users/{selected_user}/properties/{app_key}/{property_name}
# operationId: deleteUserHostedPropertyValue
export def "users-properties delete-hosted-value" [
  selected_user: string
  app_key: string
  property_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/users/{selected_user}/properties/{app_key}/{property_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a user application property
#
# GET /users/{selected_user}/properties/{app_key}/{property_name}
# operationId: retrieveUserHostedPropertyValue
export def "users-properties get-hosted-value" [
  selected_user: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_attributes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/users/{selected_user}/properties/{app_key}/{property_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a user application property
#
# PUT /users/{selected_user}/properties/{app_key}/{property_name}
# operationId: updateUserHostedPropertyValue
export def "users-properties update-hosted-value" [
  selected_user: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($app_key | is-empty) { error make --unspanned { msg: "path parameter 'app_key' must be non-empty" } }
  if ($property_name | is-empty) { error make --unspanned { msg: "path parameter 'property_name' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), app_key: (encode-path-segment $app_key), property_name: (encode-path-segment $property_name)} | format pattern "/users/{selected_user}/properties/{app_key}/{property_name}"))
  let req_body = {"_attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search for code in a user's repositories
#
# GET /users/{selected_user}/search/code
# operationId: searchAccount
export def "users-search-code list-account" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # The search query
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let qp = [(serialize-qp "search_query" $search_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user)} | format pattern "/users/{selected_user}/search/code") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search_query": $search_query, "page": $page, "pagelen": $pagelen} | compact), body: null}
}

# List SSH keys
#
# GET /users/{selected_user}/ssh-keys
export def "users-ssh-keys list" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<owner: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user)} | format pattern "/users/{selected_user}/ssh-keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a new SSH key
#
# POST /users/{selected_user}/ssh-keys
export def "users-ssh-keys create" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: any
]: any -> record<owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user)} | format pattern "/users/{selected_user}/ssh-keys"))
  let req_body = {"owner": $owner} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a SSH key
#
# DELETE /users/{selected_user}/ssh-keys/{key_id}
export def "users-ssh-keys delete" [
  selected_user: string
  key_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), key_id: (encode-path-segment $key_id)} | format pattern "/users/{selected_user}/ssh-keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a SSH key
#
# GET /users/{selected_user}/ssh-keys/{key_id}
export def "users-ssh-keys get" [
  selected_user: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), key_id: (encode-path-segment $key_id)} | format pattern "/users/{selected_user}/ssh-keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a SSH key
#
# PUT /users/{selected_user}/ssh-keys/{key_id}
export def "users-ssh-keys update" [
  selected_user: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: any
]: any -> record<owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({selected_user: (encode-path-segment $selected_user), key_id: (encode-path-segment $key_id)} | format pattern "/users/{selected_user}/ssh-keys/{key_id}"))
  let req_body = {"owner": $owner} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List workspaces for user
#
# GET /workspaces
export def "workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer-2 # Filters the workspaces based on the authenticated user's role on each workspace. * **member**: returns a list of all the workspaces which the caller is a member of at least one workspace group or repository * **collaborator**: returns a list of workspaces which the caller has write access to at least one repository in the workspace * **owner**: returns a list of workspaces which the caller has administrator access
  --q: string # Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --qp-sort: string # Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"role": $role, "q": $q, "sort": $qp_sort} | compact), body: null}
}

# Get a workspace
#
# GET /workspaces/{workspace}
export def "workspaces get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, is_private: bool, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, members: record<href: string, name: string>, owners: record<href: string, name: string>, projects: record<href: string, name: string>, repositories: record<href: string, name: string>, self: record<href: string, name: string>, snippets: record<href: string, name: string>>, name: string, slug: string, updated_on: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List webhooks for a workspace
#
# GET /workspaces/{workspace}/hooks
export def "workspaces-hooks list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, active: bool, created_at: string, description: string, events: list, subject: record, subject_type: string, url: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/hooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a webhook for a workspace
#
# POST /workspaces/{workspace}/hooks
export def "workspaces-hooks create" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/hooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a webhook for a workspace
#
# DELETE /workspaces/{workspace}/hooks/{uid}
export def "workspaces-hooks delete" [
  workspace: string
  uid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), uid: (encode-path-segment $uid)} | format pattern "/workspaces/{workspace}/hooks/{uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a webhook for a workspace
#
# GET /workspaces/{workspace}/hooks/{uid}
export def "workspaces-hooks get" [
  workspace: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), uid: (encode-path-segment $uid)} | format pattern "/workspaces/{workspace}/hooks/{uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a webhook for a workspace
#
# PUT /workspaces/{workspace}/hooks/{uid}
export def "workspaces-hooks update" [
  workspace: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), uid: (encode-path-segment $uid)} | format pattern "/workspaces/{workspace}/hooks/{uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List users in a workspace
#
# GET /workspaces/{workspace}/members
export def "workspaces-members list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/members"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get user membership for a workspace
#
# GET /workspaces/{workspace}/members/{member}
export def "workspaces-members get" [
  workspace: string
  member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, workspace: record<type: string, created_on: string, is_private: bool, links: record<avatar: record, html: record, members: record, owners: record, projects: record, repositories: record, self: record, snippets: record>, name: string, slug: string, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($member | is-empty) { error make --unspanned { msg: "path parameter 'member' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), member: (encode-path-segment $member)} | format pattern "/workspaces/{workspace}/members/{member}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List user permissions in a workspace
#
# GET /workspaces/{workspace}/permissions
export def "workspaces-permissions get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# List all repository permissions for a workspace
#
# GET /workspaces/{workspace}/permissions/repositories
export def "workspaces-permissions-repositories list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/permissions/repositories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# List a repository permissions for a workspace
#
# GET /workspaces/{workspace}/permissions/repositories/{repo_slug}
export def "workspaces-permissions-repositories get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repo_slug' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/workspaces/{workspace}/permissions/repositories/{repo_slug}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort} | compact), body: null}
}

# Get OpenID configuration for OIDC in Pipelines
#
# GET /workspaces/{workspace}/pipelines-config/identity/oidc/.well-known/openid-configuration
# operationId: getOIDCConfiguration
export def "workspaces-pipelines-config-identity-oidc-well-known-openid-configuration get" [
  workspace: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/pipelines-config/identity/oidc/.well-known/openid-configuration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get keys for OIDC in Pipelines
#
# GET /workspaces/{workspace}/pipelines-config/identity/oidc/keys.json
# operationId: getOIDCKeys
export def "workspaces-pipelines-config-identity-oidc-keys-json get" [
  workspace: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/pipelines-config/identity/oidc/keys.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List variables for a workspace
#
# GET /workspaces/{workspace}/pipelines-config/variables
# operationId: getPipelineVariablesForWorkspace
export def "workspaces-pipelines-config-variables list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/pipelines-config/variables"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a variable for a workspace
#
# POST /workspaces/{workspace}/pipelines-config/variables
# operationId: createPipelineVariableForWorkspace
export def "workspaces-pipelines-config-variables create" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/pipelines-config/variables"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a variable for a workspace
#
# DELETE /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# operationId: deletePipelineVariableForWorkspace
export def "workspaces-pipelines-config-variables delete" [
  workspace: string
  variable_uuid: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/workspaces/{workspace}/pipelines-config/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get variable for a workspace
#
# GET /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# operationId: getPipelineVariableForWorkspace
export def "workspaces-pipelines-config-variables get" [
  workspace: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/workspaces/{workspace}/pipelines-config/variables/{variable_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update variable for a workspace
#
# PUT /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# operationId: updatePipelineVariableForWorkspace
export def "workspaces-pipelines-config-variables update" [
  workspace: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> record<type: string, key: string, secured: bool, uuid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($variable_uuid | is-empty) { error make --unspanned { msg: "path parameter 'variable_uuid' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), variable_uuid: (encode-path-segment $variable_uuid)} | format pattern "/workspaces/{workspace}/pipelines-config/variables/{variable_uuid}"))
  let req_body = {"type": $type, "key": $key, "secured": $secured, "uuid": $uuid, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List projects in a workspace
#
# GET /workspaces/{workspace}/projects
export def "workspaces-projects list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/projects"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a project in a workspace
#
# POST /workspaces/{workspace}/projects
# --links shape: {avatar?: record, html?: record}
export def "workspaces-projects create" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --has-publicly-visible-repos: oneof<nothing, bool> # Indicates whether the project contains publicly visible repositories. Note that private projects cannot contain public repositories.
  --is-private: oneof<nothing, bool> # Indicates whether the project is publicly accessible, or whether it is private to the team and consequently only visible to team members. Note that private projects cannot contain public repositories.
  --key: string # The project's key.
  --links: record # shape: {avatar?: record, html?: record}
  --name: string # The name of the project.
  --owner: any
  --updated-on: string # format: date-time
  --uuid: string # The project's immutable id.
]: any -> record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>>, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/projects"))
  let req_body = {"type": $type, "created_on": $created_on, "description": $description, "has_publicly_visible_repos": $has_publicly_visible_repos, "is_private": $is_private, "key": $key, "links": $links, "name": $name, "owner": $owner, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a project for a workspace
#
# DELETE /workspaces/{workspace}/projects/{project_key}
export def "workspaces-projects delete" [
  workspace: string
  project_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a project for a workspace
#
# GET /workspaces/{workspace}/projects/{project_key}
export def "workspaces-projects get" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>>, updated_on: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a project for a workspace
#
# PUT /workspaces/{workspace}/projects/{project_key}
# --links shape: {avatar?: record, html?: record}
export def "workspaces-projects update" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --has-publicly-visible-repos: oneof<nothing, bool> # Indicates whether the project contains publicly visible repositories. Note that private projects cannot contain public repositories.
  --is-private: oneof<nothing, bool> # Indicates whether the project is publicly accessible, or whether it is private to the team and consequently only visible to team members. Note that private projects cannot contain public repositories.
  --key: string # The project's key.
  --links: record # shape: {avatar?: record, html?: record}
  --name: string # The name of the project.
  --owner: any
  --updated-on: string # format: date-time
  --uuid: string # The project's immutable id.
]: any -> record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>>, updated_on: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}"))
  let req_body = {"type": $type, "created_on": $created_on, "description": $description, "has_publicly_visible_repos": $has_publicly_visible_repos, "is_private": $is_private, "key": $key, "links": $links, "name": $name, "owner": $owner, "updated_on": $updated_on, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the branching model for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/branching-model
export def "workspaces-projects-branching-model get" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, branch_types: table<kind: string, prefix: string>, development: record<name: string, use_mainbranch: bool>, production: record<name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}/branching-model"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the branching model config for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/branching-model/settings
export def "workspaces-projects-branching-model-settings get" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}/branching-model/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the branching model config for a project
#
# PUT /workspaces/{workspace}/projects/{project_key}/branching-model/settings
export def "workspaces-projects-branching-model-settings update" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}/branching-model/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List the default reviewers in a project
#
# GET /workspaces/{workspace}/projects/{project_key}/default-reviewers
export def "workspaces-projects-default-reviewers list" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<reviewer_type: string, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}/default-reviewers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove the specific user from the project's default reviewers
#
# DELETE /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
export def "workspaces-projects-default-reviewers delete" [
  workspace: string
  project_key: string
  selected_user: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key), selected_user: (encode-path-segment $selected_user)} | format pattern "/workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a default reviewer
#
# GET /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
export def "workspaces-projects-default-reviewers get" [
  workspace: string
  project_key: string
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, repositories: record<href: string, name: string>, self: record<href: string, name: string>>, nickname: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key), selected_user: (encode-path-segment $selected_user)} | format pattern "/workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add the specific user as a default reviewer for the project
#
# PUT /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
export def "workspaces-projects-default-reviewers update" [
  workspace: string
  project_key: string
  selected_user: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  if ($selected_user | is-empty) { error make --unspanned { msg: "path parameter 'selected_user' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key), selected_user: (encode-path-segment $selected_user)} | format pattern "/workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List project deploy keys
#
# GET /workspaces/{workspace}/projects/{project_key}/deploy-keys
export def "workspaces-projects-deploy-keys list" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, added_on: string, comment: string, created_by: record, key: string, label: string, last_used: string, links: record, project: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}/deploy-keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a project deploy key
#
# POST /workspaces/{workspace}/projects/{project_key}/deploy-keys
export def "workspaces-projects-deploy-keys create" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, added_on: string, comment: string, created_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<links: record>, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key)} | format pattern "/workspaces/{workspace}/projects/{project_key}/deploy-keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a deploy key from a project
#
# DELETE /workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}
export def "workspaces-projects-deploy-keys delete" [
  workspace: string
  project_key: string
  key_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key), key_id: (encode-path-segment $key_id)} | format pattern "/workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a project deploy key
#
# GET /workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}
export def "workspaces-projects-deploy-keys get" [
  workspace: string
  project_key: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, added_on: string, comment: string, created_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<links: record>, updated_on: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'project_key' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace), project_key: (encode-path-segment $project_key), key_id: (encode-path-segment $key_id)} | format pattern "/workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search for code in a workspace
#
# GET /workspaces/{workspace}/search/code
# operationId: searchWorkspace
export def "workspaces-search-code list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # The search query
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let qp = [(serialize-qp "search_query" $search_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace: (encode-path-segment $workspace)} | format pattern "/workspaces/{workspace}/search/code") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search_query": $search_query, "page": $page, "pagelen": $pagelen} | compact), body: null}
}
