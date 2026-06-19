# Auto-generated client for Groundwater Wells, Aquifers and Registry API vv1
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/gwells/v1/openapi.json
# Auth: --token flag or $env.GROUNDWATER_WELLS_AQUIFERS_AND_REGISTRY_API_TOKEN

const BASE_URL = "https://apps.nrs.gov.bc.ca/gwells/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GROUNDWATER_WELLS_AQUIFERS_AND_REGISTRY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "jwt" => { {scheme: $scheme, headers: {JWT: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://apps.nrs.gov.bc.ca/gwells/api/v1"] }
def auth-scheme-completer [] { ["jwt"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "aquifer-codes-demand list" } } | get name | first)
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

# return a list of aquifer demand codes
#
# GET /aquifer-codes/demand/
# operationId: aquifer-codes_demand_list
export def "aquifer-codes-demand list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<code: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifer-codes/demand/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# return a list of aquifer material codes
#
# GET /aquifer-codes/materials/
# operationId: aquifer-codes_materials_list
export def "aquifer-codes-materials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<code: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifer-codes/materials/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# return a list of aquifer productivity codes
#
# GET /aquifer-codes/productivity/
# operationId: aquifer-codes_productivity_list
export def "aquifer-codes-productivity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<code: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifer-codes/productivity/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# return a list of quality concern codes
#
# GET /aquifer-codes/quality-concerns/
# operationId: aquifer-codes_quality-concerns_list
export def "aquifer-codes-quality-concerns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<code: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifer-codes/quality-concerns/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# return a list of aquifer subtype codes
#
# GET /aquifer-codes/subtypes/
# operationId: aquifer-codes_subtypes_list
export def "aquifer-codes-subtypes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<code: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifer-codes/subtypes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# return a list of aquifer vulnerability codes
#
# GET /aquifer-codes/vulnerability/
# operationId: aquifer-codes_vulnerability_list
export def "aquifer-codes-vulnerability list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<code: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifer-codes/vulnerability/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# return a list of water use codes
#
# GET /aquifer-codes/water-use/
# operationId: aquifer-codes_water-use_list
export def "aquifer-codes-water-use list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<code: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifer-codes/water-use/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# return a list of aquifers
#
# GET /aquifers/
# operationId: aquifers_list
export def "aquifers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aquifer-id: float
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<aquifer_id: int, aquifer_name: string, area: string, demand: string, demand_description: string, known_water_use: string, known_water_use_description: string, litho_stratographic_unit: string, location_description: string, mapping_year: int, material: string, material_description: string, notes: string, productivity: string, productivity_description: string, quality_concern: string, quality_concern_description: string, subtype: string, subtype_description: string, vulnerability: string, vulnerability_description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aquifer_id" $aquifer_id "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"aquifer_id": $aquifer_id, "ordering": $ordering, "search": $search, "limit": $limit, "offset": $offset} | compact), body: null}
}

# List all aquifers in a simplified format
#
# GET /aquifers/names/
# operationId: aquifers_names_list
export def "aquifers-names list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A search term.
]: nothing -> table<aquifer_id: int, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aquifers/names/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search} | compact), body: null}
}

# return details of aquifers
#
# GET /aquifers/{aquifer_id}/
# operationId: aquifers_read
export def "aquifers get" [
  aquifer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aquifer_id: int, aquifer_name: string, area: string, demand: string, demand_description: string, known_water_use: string, known_water_use_description: string, litho_stratographic_unit: string, location_description: string, mapping_year: int, material: string, material_description: string, notes: string, productivity: string, productivity_description: string, quality_concern: string, quality_concern_description: string, subtype: string, subtype_description: string, vulnerability: string, vulnerability_description: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($aquifer_id | is-empty) { error make --unspanned { msg: "path parameter 'aquifer_id' must be non-empty" } }
  let full_url = (build-url $base ({aquifer_id: (encode-path-segment $aquifer_id)} | format pattern "/aquifers/{aquifer_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# list files found for the aquifer identified in the uri
#
# GET /aquifers/{aquifer_id}/files
# operationId: aquifers_files_list
export def "aquifers-files list" [
  aquifer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<private: table<name: string, url: string>, public: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($aquifer_id | is-empty) { error make --unspanned { msg: "path parameter 'aquifer_id' must be non-empty" } }
  let full_url = (build-url $base ({aquifer_id: (encode-path-segment $aquifer_id)} | format pattern "/aquifers/{aquifer_id}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# returns a list of cities with a qualified, registered operator (driller or installer)
#
# GET /cities/drillers/
# operationId: cities_drillers_list
export def "cities-drillers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<organization: record<city: string, email: string, fax_tel: string, main_tel: string, name: string, org_guid: string, org_verbose_name: string, postal_code: string, province_state: string, street_address: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cities/drillers/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# returns a list of cities with a qualified, registered operator (driller or installer)
#
# GET /cities/installers/
# operationId: cities_installers_list
export def "cities-installers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<organization: record<city: string, email: string, fax_tel: string, main_tel: string, name: string, org_guid: string, org_verbose_name: string, postal_code: string, province_state: string, street_address: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cities/installers/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# serves general configuration
#
# GET /config
# operationId: config_list
export def "config list" [
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
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of all person records
#
# GET /drillers/
# operationId: drillers_list
export def "drillers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A search term.
  --ordering: string # Which field to use when ordering the results.
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> table<contact_cell: string, contact_email: string, contact_tel: string, first_name: string, person_guid: string, registrations: list<record>, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drillers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "ordering": $ordering, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Search for a person in the Register
#
# GET /drillers/names/
# operationId: drillers_names_list
export def "drillers-names list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A search term.
]: nothing -> table<name: string, person_guid: string, registrations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drillers/names/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search} | compact), body: null}
}

# list files found for the aquifer identified in the uri
#
# GET /drillers/{person_guid}/files/
# operationId: drillers_files_list
export def "drillers-files list" [
  person_guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<private: table<name: string, url: string>, public: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($person_guid | is-empty) { error make --unspanned { msg: "path parameter 'person_guid' must be non-empty" } }
  let full_url = (build-url $base ({person_guid: (encode-path-segment $person_guid)} | format pattern "/drillers/{person_guid}/files/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# serves keycloak config
#
# GET /keycloak
# operationId: keycloak_list
export def "keycloak list" [
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
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keycloak")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Options required for submitting activity report forms
#
# GET /submissions/options/
# operationId: submissions_options_list
export def "submissions-options list" [
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
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submissions/options/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# returns a list of active surveys
#
# GET /surveys/
# operationId: surveys_list
export def "surveys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<survey_guid: string, survey_introduction_text: string, survey_link: string, survey_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/surveys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# returns a list of wells
#
# GET /wells/
# operationId: wells_list
export def "wells list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<alteration_end_date: string, alternative_specs_submitted: bool, analytic_solution_type: string, aquifer: int, aquifer_vulnerability_index: string, artesian_flow: string, artesian_pressure: string, backfill_depth: string, backfill_material: string, backfill_type: string, bcgs_id: int, bedrock_depth: string, boundary_effect: string, city: string, comments: string, construction_end_date: string, construction_start_date: string, coordinate_acquisition_code: string, decommission_details: string, decommission_end_date: string, decommission_method: string, decommission_reason: string, decommission_start_date: string, development_hours: string, development_method: string, development_notes: string, diameter: string, drawdown: string, drilling_company: string, drilling_method: string, ems: string, filter_pack_from: string, filter_pack_material: string, filter_pack_material_size: string, filter_pack_thickness: string, filter_pack_to: string, final_casing_stick_up: string, finished_well_depth: string, ground_elevation: string, ground_elevation_method: string, hydraulic_conductivity: string, hydro_fracturing_performed: bool, hydro_fracturing_yield_increase: string, id_plate_attached_by: string, identification_plate_number: int, intended_water_use: string, land_district: string, latitude: string, legal_block: string, legal_district_lot: string, legal_lot: string, legal_pid: int, legal_plan: string, legal_range: string, legal_section: string, legal_township: string, licenced_status: string, liner_diameter: string, liner_from: string, liner_material: string, liner_thickness: string, liner_to: string, longitude: string, observation_well_number: string, observation_well_status: string, other_drilling_method: string, other_screen_bottom: string, other_screen_material: string, owner_full_name: string, recommended_pump_depth: string, recommended_pump_rate: string, screen_bottom: string, screen_information: string, screen_intake_method: string, screen_material: string, screen_opening: string, screen_type: string, sealant_material: string, specific_storage: string, specific_yield: string, static_level_before_test: string, static_water_level: string, storativity: string, street_address: string, surface_seal_depth: string, surface_seal_length: string, surface_seal_material: string, surface_seal_method: string, surface_seal_thickness: string, testing_duration: int, testing_method: string, total_depth_drilled: string, transmissivity: string, utm_easting: int, utm_northing: int, utm_zone_code: string, water_quality_characteristics: list, water_quality_colour: string, water_quality_odour: string, water_supply_system_name: string, water_supply_system_well_name: string, well_cap_type: string, well_class: string, well_disinfected: bool, well_guid: string, well_identification_plate_attached: string, well_location_description: string, well_orientation: bool, well_status: string, well_subclass: string, well_tag_number: int, well_yield: string, well_yield_unit: string, yield_estimation_duration: string, yield_estimation_method: string, yield_estimation_rate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wells/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# seach for wells by tag or owner
#
# GET /wells/tags/
# operationId: wells_tags_list
export def "wells-tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A search term.
  --ordering: string # Which field to use when ordering the results.
]: nothing -> table<owner_full_name: string, well_tag_number: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wells/tags/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "ordering": $ordering} | compact), body: null}
}

# list files found for the well identified in the uri
#
# GET /wells/{tag}/files
# operationId: wells_files_list
export def "wells-files list" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<private: table<name: string, url: string>, public: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({tag: (encode-path-segment $tag)} | format pattern "/wells/{tag}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return well detail. This view is open to all, and has no permissions.
#
# GET /wells/{well_tag_number}
# operationId: wells_read
export def "wells get" [
  well_tag_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alteration_end_date: string, alternative_specs_submitted: bool, analytic_solution_type: string, aquifer: int, aquifer_vulnerability_index: string, artesian_flow: string, artesian_pressure: string, backfill_depth: string, backfill_material: string, backfill_type: string, bcgs_id: int, bedrock_depth: string, boundary_effect: string, casing_set: table<casing_code: string, casing_material: string, diameter: string, drive_shoe: bool, end: string, start: string, wall_thickness: string>, city: string, comments: string, company_of_person_responsible: record<name: string, org_guid: string, org_verbose_name: string>, construction_end_date: string, construction_start_date: string, coordinate_acquisition_code: string, decommission_description_set: table<end: string, material: string, observations: string, start: string>, decommission_details: string, decommission_end_date: string, decommission_method: string, decommission_reason: string, decommission_start_date: string, development_hours: string, development_method: string, development_notes: string, diameter: string, drawdown: string, drilling_company: string, drilling_method: string, ems: string, filter_pack_from: string, filter_pack_material: string, filter_pack_material_size: string, filter_pack_thickness: string, filter_pack_to: string, final_casing_stick_up: string, finished_well_depth: string, ground_elevation: string, ground_elevation_method: string, hydraulic_conductivity: string, hydro_fracturing_performed: bool, hydro_fracturing_yield_increase: string, id_plate_attached_by: string, identification_plate_number: int, intended_water_use: string, land_district: string, latitude: string, legal_block: string, legal_district_lot: string, legal_lot: string, legal_pid: int, legal_plan: string, legal_range: string, legal_section: string, legal_township: string, licenced_status: string, liner_diameter: string, liner_from: string, liner_material: string, liner_thickness: string, liner_to: string, linerperforation_set: table<end: string, start: string>, lithologydescription_set: table<lithology_colour: string, lithology_from: string, lithology_hardness: string, lithology_moisture: string, lithology_raw_data: string, lithology_to: string, water_bearing_estimated_flow: string>, longitude: string, observation_well_number: string, observation_well_status: string, other_drilling_method: string, other_screen_bottom: string, other_screen_material: string, owner_full_name: string, person_responsible: record<name: string, person_guid: string>, recommended_pump_depth: string, recommended_pump_rate: string, screen_bottom: string, screen_information: string, screen_intake_method: string, screen_material: string, screen_opening: string, screen_set: table<assembly_type: string, end: string, internal_diameter: string, slot_size: string, start: string>, screen_type: string, sealant_material: string, specific_storage: string, specific_yield: string, static_level_before_test: string, static_water_level: string, storativity: string, street_address: string, surface_seal_depth: string, surface_seal_length: string, surface_seal_material: string, surface_seal_method: string, surface_seal_thickness: string, testing_duration: int, testing_method: string, total_depth_drilled: string, transmissivity: string, utm_easting: int, utm_northing: int, utm_zone_code: string, water_quality_characteristics: list<string>, water_quality_colour: string, water_quality_odour: string, water_supply_system_name: string, water_supply_system_well_name: string, well: int, well_cap_type: string, well_class: string, well_disinfected: bool, well_guid: string, well_identification_plate_attached: string, well_location_description: string, well_orientation: bool, well_status: string, well_subclass: string, well_tag_number: int, well_yield: string, well_yield_unit: string, yield_estimation_duration: string, yield_estimation_method: string, yield_estimation_rate: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($well_tag_number | is-empty) { error make --unspanned { msg: "path parameter 'well_tag_number' must be non-empty" } }
  let full_url = (build-url $base ({well_tag_number: (encode-path-segment $well_tag_number)} | format pattern "/wells/{well_tag_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
