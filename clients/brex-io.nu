# Auto-generated client for KYC API Documentation v2021.12
# Source: https://api.apis.guru/v2/specs/brex.io/2021.12/openapi.json
# Auth: --token flag or $env.KYC_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.kompany.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KYC_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "user_key" => { {scheme: $scheme, headers: {user_key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.kompany.com"] }
def auth-scheme-completer [] { ["user_key"] }

# Completers for enum parameters
def lang-completer [] { ["" "EN" "OG"] }
def lang-completer-1 [] { ["" "EN" "ES" "FR"] }
def accept-completer [] { ["application/json" "application/pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "company-announcement get" } } | get name | first)
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

# Retrieves announcement data
#
# GET /api/v1/company/announcement/{id}
# operationId: CompanyAnnouncement
export def "company-announcement get" [
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
]: nothing -> table<countryCode: string, id: string, registrationNumber: string, structured: string, text: string, time: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/company/announcement/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a list of stock exchange listings
#
# POST /api/v1/company/deepsearch/isin
# operationId: CompanyDeepsearchISIN
export def "company-deepsearch-isin create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --isin: string # A list of ISIN numbers seperated by comma (maximum) is 100
]: any -> table<isin: string, listings: list<record>, validIsin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/company/deepsearch/isin")
  let req_body = {"isin": $isin} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieves a list of companies
#
# GET /api/v1/company/deepsearch/lei/{number}
# operationId: CompanyDeepsearchLEI
export def "company-deepsearch-lei get" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination for the ISIN number results (1000 numbers per page) (format: int32, e.g. 1)
]: nothing -> record<company: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>, current_page: int, isins: list<string>, last_page: int, lei: string, next_page: string, total_num_isins: int, validLei: bool> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({number: (encode-path-segment $number)} | format pattern "/api/v1/company/deepsearch/lei/{number}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page} | compact), body: null}
}

# Retrieves a list of companies from the official business register
#
# GET /api/v1/company/deepsearch/name/{country}/{name}
# operationId: CompanyDeepsearchName
export def "company-deepsearch-name get" [
  country: string
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country), name: (encode-path-segment $name)} | format pattern "/api/v1/company/deepsearch/name/{country}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a list of companies from the official business register
#
# GET /api/v1/company/deepsearch/number/{country}/{number}
# operationId: CompanyDeepsearchNumber
export def "company-deepsearch-number get" [
  country: string
  number: string
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country), number: (encode-path-segment $number)} | format pattern "/api/v1/company/deepsearch/number/{country}/{number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get available ChangeTypes
#
# GET /api/v1/company/monitoring/changeTypes
# operationId: CompanyMonitorChangeTypesList
export def "company-monitoring-change-types list-monitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/company/monitoring/changeTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a list of registered monitors
#
# GET /api/v1/company/monitoring/list
# operationId: CompanyMonitorList
export def "company-monitoring-list list-monitor" [
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/company/monitoring/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get monitor status for specific company id
#
# GET /api/v1/company/monitoring/list/{id}
# operationId: CompanyMonitorId
export def "company-monitoring-list get-monitor" [
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/company/monitoring/list/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Register a Company for monitoring
#
# POST /api/v1/company/monitoring/register/{id}
# operationId: CompanyMonitorRegister
export def "company-monitoring-register create-monitor" [
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
  callback_url: string # Callback URL
  change_type: string # ChangeType to monitor
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/company/monitoring/register/{id}"))
  let req_body = {"callbackUrl": $callback_url, "changeType": $change_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Deactivates an active notification
#
# POST /api/v1/company/monitoring/unregister/{id}
# operationId: CompanyMonitorUnregister
export def "company-monitoring-unregister delete-monitor" [
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/company/monitoring/unregister/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a list of registered notifications
#
# GET /api/v1/company/notification/list
# operationId: CompanyNotificationList
export def "company-notification-list list" [
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/company/notification/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a list of registered notifications
#
# GET /api/v1/company/notification/list/{id}
# operationId: CompanyNotificationId
export def "company-notification-list get" [
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
]: nothing -> table<callbackCount: int, callbackUrl: string, created: any, monitorStatus: string, notificationId: string, subjectId: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/company/notification/list/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new notification
#
# POST /api/v1/company/notification/register/{id}
# operationId: CompanyNotificationRegister
export def "company-notification-register create" [
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
  callback_url: string # Callback URL
]: any -> record<monitorStatus: string, notificationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/company/notification/register/{id}"))
  let req_body = {"callbackUrl": $callback_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Unregister a company from Monitoring
#
# POST /api/v1/company/notification/unregister/{id}
# operationId: CompanyNotificationUnregister
export def "company-notification-unregister delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/company/notification/unregister/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a list of companies from the KYC API company index
#
# GET /api/v1/company/search/name/{country}/{name}
# operationId: CompanySearchName
export def "company-search-name list" [
  country: string
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
  --limit: int # number of search results (format: int64)
]: nothing -> table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country: (encode-path-segment $country), name: (encode-path-segment $name)} | format pattern "/api/v1/company/search/name/{country}/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit} | compact), body: null}
}

# Retrieves a list of companies from the KYC API company index
#
# GET /api/v1/company/search/number/{country}/{number}
# operationId: CompanySearchNumber
export def "company-search-number list" [
  country: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # number of search results (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country: (encode-path-segment $country), number: (encode-path-segment $number)} | format pattern "/api/v1/company/search/number/{country}/{number}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit} | compact), body: null}
}

# Retrieves a list of companies from the KYC API company index
#
# POST /api/v1/company/search/{country}
# operationId: CompanyAlternativeSearch
export def "company-search list-alternative" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Company address (or address partial)
  --name: string # Company name
  --number: string # Company registration number
  --phone: string # Company contact phone number
  --url: string # Company url
  --vat: string # Company VAT number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/api/v1/company/search/{country}"))
  let req_body = {"address": $address, "name": $name, "number": $number, "phone": $phone, "url": $url, "vat": $vat} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieves company announcements
#
# GET /api/v1/company/{id}/announcements
# operationId: CompanyIdAnnouncements
export def "company-announcements get" [
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
  --limit: int # limit of announcements in response (default 10) (format: int32)
  --offset: int # to paginate through results (default 0) (format: int32)
  --data: oneof<nothing, bool> # If this parameter is set to false, you will only receive ids, and no additional data about announcements and no hits to the metric will be counted. (and potentially minimizing your costs) (format: )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/company/{id}/announcements") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "data": $data} | compact), body: null}
}

# Retrieves structured data extracted from a company document
#
# GET /api/v1/company/{id}/super/{country}
# operationId: CompanyIdSuper
export def "company-super get" [
  id: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Optional data translation (only available in limited jurisdictions) (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), country: (encode-path-segment $country)} | format pattern "/api/v1/company/{id}/super/{country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang} | compact), body: null}
}

# Retrieves company details
#
# GET /api/v1/company/{id}/{dataset}
# operationId: CompanyIdDataset
export def "company get" [
  id: string
  dataset: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-stock-listing: oneof<nothing, bool> # Try to retrieve additional stock information for this company. (Only available on refresh)
  --lang: string@lang-completer-1 # Optional data translation (only available in limited jurisdictions) (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($dataset | is-empty) { error make --unspanned { msg: "path parameter 'dataset' must be non-empty" } }
  let qp = [(serialize-qp "check_stock_listing" $check_stock_listing "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), dataset: (encode-path-segment $dataset)} | format pattern "/api/v1/company/{id}/{dataset}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"check_stock_listing": $check_stock_listing, "lang": $lang} | compact), body: null}
}

# Verifies an EIN number
#
# GET /api/v1/ein-verification/basic-check
# operationId: EinVerificationBasic
export def "ein-verification-basic-check get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ein: string # Nine letter EIN number with or without hyphens (format: string)
]: nothing -> record<confidence_score: string, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, irs_score: string, irs_score_explanation: string, timestamp: float, validationStatus: bool> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ein" $ein "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/ein-verification/basic-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ein": $ein} | compact), body: null}
}

# Verifies EIN number and retrieves company data
#
# GET /api/v1/ein-verification/comprehensive-check
# operationId: EinVerificationComprehensive
export def "ein-verification-comprehensive-check get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ein: string # Nine letter EIN number with or without hyphens (format: string)
]: nothing -> record<ein: string, matched_ein_companies: table<address: list, company_score: float, company_score_explanation: string, confidence_score: float, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, formattedAddress: list, irs_score: string, irs_score_explanation: string, name: string, provided_status: string, provided_status_explanation: string>, timestamp: float, validationStatus: bool> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ein" $ein "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/ein-verification/comprehensive-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ein": $ein} | compact), body: null}
}

# Retrieves a list of EIN numbers
#
# GET /api/v1/ein-verification/lookup
# operationId: EinVerificationLookup
export def "ein-verification-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Business name of the company (format: string)
  --state: string # Optional state parameter to improve results. (Two letter code for example CA or US-CA for California) (format: string)
  --zip: string # Optional zip code parameter to improve results. (Zip is preferred over state) (format: string)
  --tight: oneof<nothing, bool> # Optional parameter to do tight matching. (Only the best match will be returned rather then the top 5)
]: nothing -> record<matched_ein_companies: table<address: list, company_score: float, company_score_explanation: string, confidence_score: float, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, formattedAddress: list, irs_score: string, irs_score_explanation: string, name: string, provided_status: string, provided_status_explanation: string>, searchterm_name: string, searchterm_state: string, searchterm_zip: string, tight_search: bool, timestamp: float> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "tight" $tight "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/ein-verification/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "state": $state, "zip": $zip, "tight": $tight} | compact), body: null}
}

# Checks validity of an IBAN number
#
# POST /api/v1/iban-verification/check-iban
# operationId: IbanBasic
export def "iban-verification-check-iban create-basic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  iban_number: string # IBAN number to validate (e.g. AT483200000012345864)
]: any -> record<valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/iban-verification/check-iban")
  let req_body = {"ibanNumber": $iban_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Checks validity of an IBAN number
#
# POST /api/v1/iban-verification/comprehensive-check-iban
# operationId: IbanComprehensive
export def "iban-verification-comprehensive-check-iban create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  iban_number: string # IBAN number to validate (e.g. AT483200000012345864)
]: any -> record<valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/iban-verification/comprehensive-check-iban")
  let req_body = {"ibanNumber": $iban_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Verifies a NIF number
#
# POST /api/v1/nif-verification/basic-check/{country}
# operationId: NifBasic
export def "nif-verification-basic-check create" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-address: string # company address lines
  --company-name: string # Company name
  nif_number: string # NIF number to validate
]: any -> record<companyName: string, confidenceScore: float, nifNumber: float, validationStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/api/v1/nif-verification/basic-check/{country}"))
  let req_body = {"companyAddress": $company_address, "companyName": $company_name, "nifNumber": $nif_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Verifies a NIF number and retrieves company data
#
# POST /api/v1/nif-verification/comprehensive-check/{country}
# operationId: NifComprehensive
export def "nif-verification-comprehensive-check create" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-address: string # company address lines
  --company-name: string # Company name
  nif_number: string # NIF number to validate
]: any -> record<activity: record, address: string, capital: float, companyName: string, confidenceScore: float, currency: string, email: string, fax: string, geo: string, legalType: string, nifNumber: float, phone: string, status: record, validationStatus: bool, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/api/v1/nif-verification/comprehensive-check/{country}"))
  let req_body = {"companyAddress": $company_address, "companyName": $company_name, "nifNumber": $nif_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieves a list of monitor entries
#
# GET /api/v1/pepsanction/monitor/list
# operationId: PepMonitorList
export def "pepsanction-monitor-list list-pep" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: bool, caseId: string, created: any, identifier: string, structured: string, updated: string, webhook: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/pepsanction/monitor/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deactive a pep sanction monitor
#
# POST /api/v1/pepsanction/monitor/unregister/{id}
# operationId: PepMonitorUnregister
export def "pepsanction-monitor-unregister delete-pep" [
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/pepsanction/monitor/unregister/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update details of active Pep Sanction monitor
#
# POST /api/v1/pepsanction/monitor/update/{id}
# operationId: PepMonitorUpdate
export def "pepsanction-monitor-update update-pep" [
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
  --webhook: string # If Monitoring is enabled this parameter is required. This is where updates will be sent to (e.g. null)
]: any -> record<active: bool, caseId: string, created: any, identifier: string, structured: string, updated: string, webhook: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/pepsanction/monitor/update/{id}"))
  let req_body = {"Webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Orders a new Pep Sanction Check Report
#
# POST /api/v1/pepsanction/order/{type}/{search}
# operationId: PepOrder
export def "pepsanction-order create-pep" [
  type: string
  search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: string # Optional parameter for declaring alias names when doing a person search (seperated by commas) (e.g. null)
  --country: string # Optional name of Country to assist in identifying matches based upon location/geography. (e.g. null)
  --dob: string # Optional parameter for date of birth name when doing a person search (e.g. null)
  --family-name: string # Optional parameter for last name when doing a person search (e.g. null)
  --filters: string # Optional parameter for restricting search when doing a person search (seperated by commas) (e.g. null)
  --given-name: string # Optional parameter for first name when doing a person search (e.g. null)
  --lei: string # Optional Legal Entity Identifier for additional business identifier verification. (e.g. null)
  --locale: string # Optional name of City or Locale to assist in identifying matches based upon location/geography. (e.g. null)
  --medialists: string # Optional parameter for selecting only specific media lists. By default all lists are queried (e.g. NMEDIA)
  --middle-name: string # Optional parameter for middle name when doing a person search (e.g. null)
  --monitoring: oneof<nothing, bool> # If this Pep Sanction Check should be continuesly monitored. (e.g. false)
  --peplists: string # Optional parameter for selecting only specific pep lists. By default all lists are queried (e.g. GOV,PEPD,SOE)
  --region: string # Optional name of Region or State to assist in identifying matches based upon location/geography. (e.g. null)
  --smart-match: oneof<nothing, bool> # Optional parameter for enabling SmartMatch to retrieve more results (e.g. false)
  --watchlists: string # Optional parameter for selecting only specific watch lists. By default all lists are queried (e.g. SANCTIONS,FINANCE,TERRORISM,CRIME,SMAGOV,OFAC,MEDICAL)
  --webhook: string # If Monitoring is enabled this parameter is required. This is where updates will be sent to (e.g. null)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($search | is-empty) { error make --unspanned { msg: "path parameter 'search' must be non-empty" } }
  let full_url = (build-url $base ({type: (encode-path-segment $type), search: (encode-path-segment $search)} | format pattern "/api/v1/pepsanction/order/{type}/{search}"))
  let req_body = {"Aliases": $aliases, "Country": $country, "DOB": $dob, "FamilyName": $family_name, "Filters": $filters, "GivenName": $given_name, "LEI": $lei, "Locale": $locale, "Medialists": $medialists, "MiddleName": $middle_name, "Monitoring": $monitoring, "Peplists": $peplists, "Region": $region, "SmartMatch": $smart_match, "Watchlists": $watchlists, "Webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Returns a json or pdf report
#
# GET /api/v1/pepsanction/retrieve/{id}
# operationId: PepRetrieve
export def "pepsanction-retrieve get-pep" [
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
  --hdr-accept: string@accept-completer # The type (pdf or json) in which the check should be returned
]: nothing -> record<listsChecked: string, results: record<Excerpts: string, ResultsURL: string, SearchType: string, SourceAgency: string, SourceEntity: string, SourceID: int, SourceName: string, SourceType: string>, search: string, status: string, timestamp: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/pepsanction/retrieve/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a document availability result
#
# GET /api/v1/product/availability/{sku}/{subjectId}
# operationId: ProductAvailability
export def "product-availability get" [
  sku: string
  subject_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sku | is-empty) { error make --unspanned { msg: "path parameter 'sku' must be non-empty" } }
  if ($subject_id | is-empty) { error make --unspanned { msg: "path parameter 'subjectId' must be non-empty" } }
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), subject_id: (encode-path-segment $subject_id)} | format pattern "/api/v1/product/availability/{sku}/{subject_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a catalog of products
#
# GET /api/v1/product/catalog/{country}
# operationId: ProductCatalog
export def "product-catalog get" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countryCode: string, description: string, form: string, method: string, name: string, price: float, sku: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/api/v1/product/catalog/{country}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns metadata for a notifier
#
# GET /api/v1/product/notifier/{notifierId}
# operationId: ProductNotifier
export def "product-notifier get" [
  notifier_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($notifier_id | is-empty) { error make --unspanned { msg: "path parameter 'notifierId' must be non-empty" } }
  let full_url = (build-url $base ({notifier_id: (encode-path-segment $notifier_id)} | format pattern "/api/v1/product/notifier/{notifier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a notifier for an order
#
# POST /api/v1/product/notifier/{orderId}/{type}/{uri}
# operationId: ProductNotifierCreate
export def "product-notifier create" [
  order_id: string
  type: string
  uri: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callback: string, identity: string, lastCallTime: any, lastResponseCode: int, notifierType: string, productOrderIdentity: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($uri | is-empty) { error make --unspanned { msg: "path parameter 'uri' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id), type: (encode-path-segment $type), uri: (encode-path-segment $uri)} | format pattern "/api/v1/product/notifier/{order_id}/{type}/{uri}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Places a concierge order
#
# POST /api/v1/product/order/concierge
# operationId: ProductOrderConcierge
export def "product-order-concierge create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-name: string # Name of the company for which a document should be ordered. (Not required if subjectId is given) (e.g. null)
  --contact-email: string # Contact E-Mail, will be contacted if concierge costs are exceeding the threshhold configured on your plan (e.g. null)
  --contact-phone: string # Contact phone, will be contacted if concierge costs are exceeding the threshhold configured on your plan (e.g. null)
  --cost-confirmation: oneof<nothing, bool> # If the concierge cost should require additional confirmation if a threshold is reached (configured on your plan) (e.g. false)
  --country: string # Two letter ISO code of the country of the company (e.g. null)
  --financial-data: oneof<nothing, bool> # If you want financial data of the company to be retrieved (e.g. false)
  --historic-information: oneof<nothing, bool> # If you want historical data of the company to be retrieved (e.g. false)
  --information-requirements: string # Requirements on what document or information should be provided. Please be very precise (e.g. null)
  --location-investigation: oneof<nothing, bool> # If the companies residency should be investigated (e.g. false)
  --priority: string # Priority of order: standard/express are allowed (e.g. standard)
  --register-data: oneof<nothing, bool> # If you want register data of the company to be retrieved (e.g. false)
  --register-number: string # Registration number of the company for which a document should be ordered. (Not required if subjectId is given) (e.g. null)
  --subject-id: string # Kompanyid of the company you want to place the order for (e.g. null)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/product/order/concierge")
  let req_body = {"companyName": $company_name, "contactEmail": $contact_email, "contactPhone": $contact_phone, "costConfirmation": $cost_confirmation, "country": $country, "financialData": $financial_data, "historicInformation": $historic_information, "informationRequirements": $information_requirements, "locationInvestigation": $location_investigation, "priority": $priority, "registerData": $register_data, "registerNumber": $register_number, "subjectId": $subject_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Places a UBO order
#
# POST /api/v1/product/order/ubo
# operationId: ProductOrderUbo
export def "product-order-ubo create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # An optional callback URL to which updates about the order will be sent (for instance if credits are exceeded) (e.g. null)
  --credits: float # Specify a maximum amount of credits which should be used. To disable use -1 (e.g. -1)
  --include-docs: oneof<nothing, bool> # Include purchase of register document to ubo report (e.g. false)
  --levels: string # Define a threshold for different levels of crawling (e.g. 25,50)
  --strategy: string # Choose a matching strategy. Available options (FULL,LEVELS) (e.g. FULL)
  subject_id: string # KYC API Id (32 byte hexid) of the company you want to place the order for (e.g. null)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/product/order/ubo")
  let req_body = {"callbackUrl": $callback_url, "credits": $credits, "includeDocs": $include_docs, "levels": $levels, "strategy": $strategy, "subjectId": $subject_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Places a product order
#
# POST /api/v1/product/order/{sku}/{option}/{subjectId}
# operationId: ProductOrderWithOption
export def "product-order create-by-sku-option-subject-id" [
  sku: string
  option: string
  subject_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sku | is-empty) { error make --unspanned { msg: "path parameter 'sku' must be non-empty" } }
  if ($option | is-empty) { error make --unspanned { msg: "path parameter 'option' must be non-empty" } }
  if ($subject_id | is-empty) { error make --unspanned { msg: "path parameter 'subjectId' must be non-empty" } }
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), option: (encode-path-segment $option), subject_id: (encode-path-segment $subject_id)} | format pattern "/api/v1/product/order/{sku}/{option}/{subject_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Places a product order
#
# POST /api/v1/product/order/{sku}/{subjectId}
# operationId: ProductOrder
export def "product-order create-by-sku-subject-id" [
  sku: string
  subject_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<identity: string, option: string, ordered: any, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($sku | is-empty) { error make --unspanned { msg: "path parameter 'sku' must be non-empty" } }
  if ($subject_id | is-empty) { error make --unspanned { msg: "path parameter 'subjectId' must be non-empty" } }
  let full_url = (build-url $base ({sku: (encode-path-segment $sku), subject_id: (encode-path-segment $subject_id)} | format pattern "/api/v1/product/order/{sku}/{subject_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of products
#
# GET /api/v1/product/search/{subjectId}
# operationId: ProductSearch
export def "product-search list" [
  subject_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($subject_id | is-empty) { error make --unspanned { msg: "path parameter 'subjectId' must be non-empty" } }
  let full_url = (build-url $base ({subject_id: (encode-path-segment $subject_id)} | format pattern "/api/v1/product/search/{subject_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns metadata for a order
#
# GET /api/v1/product/status/{orderId}
# operationId: ProductStatus
export def "product-status get" [
  order_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/v1/product/status/{order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates metadata of an order
#
# POST /api/v1/product/update/{action}/{orderId}
# operationId: ProductUpdateAction
export def "product-update update" [
  action: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --credits: float # Specify an amount of credits which should be added to the order (e.g. 100)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($action | is-empty) { error make --unspanned { msg: "path parameter 'action' must be non-empty" } }
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({action: (encode-path-segment $action), order_id: (encode-path-segment $order_id)} | format pattern "/api/v1/product/update/{action}/{order_id}"))
  let req_body = {"credits": $credits} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieves the result of an order
#
# GET /api/v1/product/{orderId}
# operationId: ProductRetrieve
export def "product get" [
  order_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/v1/product/{order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of countries
#
# GET /api/v1/system/countries
# operationId: SystemCountries
export def "system-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<country_code: string, country_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the health information for the official business registers based on usage.
#
# GET /api/v1/system/health
# operationId: HealthCheck
export def "system-health check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of products with prices
#
# GET /api/v1/system/pricelist
# operationId: SystemPricelist
export def "system-pricelist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<cost_per_unit: string, max: string, metric_id: string, min: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/pricelist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Verifies a TIN number
#
# GET /api/v1/tin-verification/basic-check
# operationId: TinVerificationBasicCheck
export def "tin-verification-basic-check check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tin: string # Nine letter TIN number with or without hyphens (format: string)
  --name: string # Company Name (format: string)
]: nothing -> record<matchStatus: string, name: string, possibleMatch: string, tin: string, validationStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tin" $tin "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tin-verification/basic-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tin": $tin, "name": $name} | compact), body: null}
}

# EIN Name Lookup with TIN number and retrieves company data
#
# GET /api/v1/tin-verification/comprehensive-check
# operationId: TinVerificationComprehensiveCheck
export def "tin-verification-comprehensive-check check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tin: string # Nine letter TIN number with or without hyphens (format: string)
  --name: string # Company Name (format: string)
  --threshold: int # The percentage of minimum similarity threshold for company matching (optional, default: 70%) (format: int64)
]: nothing -> record<einResult: string, matchedCompanies: any, tinResult: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tin" $tin "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "threshold" $threshold "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tin-verification/comprehensive-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tin": $tin, "name": $name, "threshold": $threshold} | compact), body: null}
}

# EIN Name Lookup with TIN number
#
# GET /api/v1/tin-verification/name-lookup
# operationId: TinVerificationNameLookup
export def "tin-verification-name-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tin: string # Nine letter TIN number with or without hyphens (format: string)
]: nothing -> record<matchStatus: string, possibleMatch: string, tin: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tin" $tin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tin-verification/name-lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tin": $tin} | compact), body: null}
}

# Returns a verification result
#
# POST /api/v1/vat-verification/basic-check/{country}
# operationId: VatBasic
export def "vat-verification-basic-check create" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-address: string # company address lines
  --company-name: string # Company name
  --company-number: string # official company number
  vat_number: string # VAT number to validate
]: any -> record<candidate: list<any>, company: any, confidenceScore: float, validationStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/api/v1/vat-verification/basic-check/{country}"))
  let req_body = {"companyAddress": $company_address, "companyName": $company_name, "companyNumber": $company_number, "vatNumber": $vat_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Returns a verification result and company data
#
# POST /api/v1/vat-verification/comprehensive-check/{country}
# operationId: VatComprehensive
export def "vat-verification-comprehensive-check create" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-address: string # company address lines
  --company-name: string # Company name
  --company-number: string # official company number
  vat_number: string # VAT number to validate
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/api/v1/vat-verification/comprehensive-check/{country}"))
  let req_body = {"companyAddress": $company_address, "companyName": $company_name, "companyNumber": $company_number, "vatNumber": $vat_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Returns a level two verification result
#
# POST /api/v1/vat-verification/leveltwo-check/{country}
# operationId: VatLevelTwo
export def "vat-verification-leveltwo-check create-level-two" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirmation: oneof<nothing, bool> # If a confirmation document should be ordered
  vat_number: string # VAT number to validate
]: any -> record<address: string, confirmation: string, level: string, name: string, validationStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/api/v1/vat-verification/leveltwo-check/{country}"))
  let req_body = {"confirmation": $confirmation, "vatNumber": $vat_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Returns a list of vat numbers with additional data
#
# POST /api/v1/vat-verification/lookup/{country}
# operationId: VatLookup
export def "vat-verification-lookup create" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Company address (e.g. null)
  name: string # Company name (e.g. null)
]: any -> record<matches: table<company: any, vat: string>, searchterm_address: string, searchterm_country: string, searchterm_name: string, timestamp: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/api/v1/vat-verification/lookup/{country}"))
  let req_body = {"address": $address, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
