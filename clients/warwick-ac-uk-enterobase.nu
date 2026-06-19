# Auto-generated client for Enterobase-API vv2.0
# Source: https://api.apis.guru/v2/specs/warwick.ac.uk/enterobase/v2.0/openapi.json
# Auth: --token flag or $env.ENTEROBASE_API_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ENTEROBASE_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v2-0 get" } } | get name | first)
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

# Top level information about EnteroBase databases
#
# GET /api/v2.0
export def "v2-0 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string # Database prefix, e.g. SAL for Salmonella
  --name: string # Species database name (senterica, ecoli, yersinia, mcatarrhalis) for Salmonella, Escherichia, Yersinia, Moraxella respectively
  --description: string # Database description
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefix" $prefix "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2.0" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"prefix": $prefix, "name": $name, "description": $description} | compact), body: null}
}

# Login endpoint, refresh your API token
#
# GET /api/v2.0/login
export def "v2-0-login get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # EnteroBase username
  --password: string # EnteroBase Password
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2.0/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"username": $username, "password": $password} | compact), body: null}
}

# Generic endpoint for lookup list of barcodes
#
# GET /api/v2.0/lookup
export def "v2-0-lookup list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string # Unique barcode for Traces records, __ e.g. SAL_AA0001AA_ST
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "barcode" $barcode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2.0/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"barcode": $barcode} | compact), body: null}
}

# Generic endpoint for lookup of barcodes
#
# GET /api/v2.0/lookup/{barcode}
export def "v2-0-lookup get" [
  barcode: string
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
  let base = ($base_url | default $BASE_URL)
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/lookup/{barcode}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generic endpoint for lookup of barcodes
#
# POST /api/v2.0/lookup/{barcode}
export def "v2-0-lookup create" [
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/lookup/{barcode}"))
  let req_body = {"barcode": $body_barcode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Genome assemblies
#
# GET /api/v2.0/{database}/assemblies
export def "v2-0-assemblies list" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --only-fields: list<string>
  --barcode: list<string> # Unique barcode for Traces records, __AS e.g. SAL_AA0001AA_AS
  --n50: int # format: int32
  --top-species: string
  --uberstrain: string
  --version: int # format: int32
  --limit: int # Number of results per page (format: int32, default: 50)
  --reldate: int # format: int32
  --offset: int # Cursor position in results (format: int32, default: 0)
  --assembly-status: string
  --sortorder: string # Order of search results: asc or desc (default: asc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "orderby" $orderby "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "barcode" $barcode "multi") (serialize-qp "n50" $n50 "scalar") (serialize-qp "top_species" $top_species "scalar") (serialize-qp "uberstrain" $uberstrain "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "assembly_status" $assembly_status "scalar") (serialize-qp "sortorder" $sortorder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database)} | format pattern "/api/v2.0/{database}/assemblies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"orderby": $orderby, "only_fields": $only_fields, "barcode": $barcode, "n50": $n50, "top_species": $top_species, "uberstrain": $uberstrain, "version": $version, "limit": $limit, "reldate": $reldate, "offset": $offset, "assembly_status": $assembly_status, "sortorder": $sortorder} | compact), body: null}
}

# Genome assemblies
#
# GET /api/v2.0/{database}/assemblies/{barcode}
export def "v2-0-assemblies get" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assembly-status: string
  --body-barcode: list<string>
  --limit: int # format: int32, default: 50
  --n50: int # format: int32
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --reldate: int # format: int32
  --sortorder: string # default: asc
  --top-species: string
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/assemblies/{barcode}"))
  let req_body = {"assembly_status": $assembly_status, "barcode": $body_barcode, "limit": $limit, "n50": $n50, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "reldate": $reldate, "sortorder": $sortorder, "top_species": $top_species, "uberstrain": $uberstrain, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Genome assemblies
#
# POST /api/v2.0/{database}/assemblies/{barcode}
export def "v2-0-assemblies create" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assembly-status: string
  --body-barcode: list<string>
  --limit: int # format: int32, default: 50
  --n50: int # format: int32
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --reldate: int # format: int32
  --sortorder: string # default: asc
  --top-species: string
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/assemblies/{barcode}"))
  let req_body = {"assembly_status": $assembly_status, "barcode": $body_barcode, "limit": $limit, "n50": $n50, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "reldate": $reldate, "sortorder": $sortorder, "top_species": $top_species, "uberstrain": $uberstrain, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Genome assemblies
#
# PUT /api/v2.0/{database}/assemblies/{barcode}
export def "v2-0-assemblies update" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assembly-status: string
  --body-barcode: list<string>
  --limit: int # format: int32, default: 50
  --n50: int # format: int32
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --reldate: int # format: int32
  --sortorder: string # default: asc
  --top-species: string
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/assemblies/{barcode}"))
  let req_body = {"assembly_status": $assembly_status, "barcode": $body_barcode, "limit": $limit, "n50": $n50, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "reldate": $reldate, "sortorder": $sortorder, "top_species": $top_species, "uberstrain": $uberstrain, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Genotyping schemes
#
# GET /api/v2.0/{database}/schemes
export def "v2-0-schemes list" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --scheme-name: string
  --created: string # format: date-time
  --lastmodified: string # format: date-time
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --label: string
  --only-fields: list<string>
  --version: int # format: int32
  --limit: int # Number of results per page (format: int32, default: 50)
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "orderby" $orderby "scalar") (serialize-qp "scheme_name" $scheme_name "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "lastmodified" $lastmodified "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "label" $label "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "version" $version "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database)} | format pattern "/api/v2.0/{database}/schemes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"orderby": $orderby, "scheme_name": $scheme_name, "created": $created, "lastmodified": $lastmodified, "barcode": $barcode, "label": $label, "only_fields": $only_fields, "version": $version, "limit": $limit, "sortorder": $sortorder, "offset": $offset} | compact), body: null}
}

# Genotyping schemes
#
# GET /api/v2.0/{database}/schemes/{barcode}
export def "v2-0-schemes get" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string>
  --created: string # format: date-time
  --label: string
  --lastmodified: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --scheme-name: string
  --sortorder: string # default: asc
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/schemes/{barcode}"))
  let req_body = {"barcode": $body_barcode, "created": $created, "label": $label, "lastmodified": $lastmodified, "limit": $limit, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "scheme_name": $scheme_name, "sortorder": $sortorder, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Genotyping schemes
#
# POST /api/v2.0/{database}/schemes/{barcode}
export def "v2-0-schemes create" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string>
  --created: string # format: date-time
  --label: string
  --lastmodified: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --scheme-name: string
  --sortorder: string # default: asc
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/schemes/{barcode}"))
  let req_body = {"barcode": $body_barcode, "created": $created, "label": $label, "lastmodified": $lastmodified, "limit": $limit, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "scheme_name": $scheme_name, "sortorder": $sortorder, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Genotyping schemes
#
# PUT /api/v2.0/{database}/schemes/{barcode}
export def "v2-0-schemes update" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string>
  --created: string # format: date-time
  --label: string
  --lastmodified: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --scheme-name: string
  --sortorder: string # default: asc
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/schemes/{barcode}"))
  let req_body = {"barcode": $body_barcode, "created": $created, "label": $label, "lastmodified": $lastmodified, "limit": $limit, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "scheme_name": $scheme_name, "sortorder": $sortorder, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Strain data
#
# GET /api/v2.0/{database}/straindata
export def "v2-0-straindata get" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --my-strains: oneof<nothing, bool>
  --offset: int # Cursor position in results (format: int32, default: 0)
  --serotype: string
  --n50: int # format: int32
  --county: string
  --only-fields: list<string>
  --postcode: string
  --lab-contact: string
  --substrains: oneof<nothing, bool>
  --custom-fields: string
  --city: string
  --strain-name: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --reldate: int # format: int32
  --continent: string
  --source-details: string
  --version: int # format: int32
  --latitude: float # format: float
  --email: string
  --source-niche: string
  --barcode: list<string> # Unique barcode for Traces records, __AS e.g. SAL_AA0001AA_AS
  --uberstrain: string
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --collection-year: int # format: int32
  --orderby: string # Field to order by. Default: strain barcode
  --assembly-status: string
  --source-type: string
  --country: string
  --region: string
  --longitude: float # format: float
  --sample-accession: string
  --limit: int # Number of results per page (format: int32, default: 50)
  --top-species: string
  --collection-time: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "comment" $comment "scalar") (serialize-qp "secondary_sample_accession" $secondary_sample_accession "scalar") (serialize-qp "my_strains" $my_strains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "serotype" $serotype "scalar") (serialize-qp "n50" $n50 "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "lab_contact" $lab_contact "scalar") (serialize-qp "substrains" $substrains "scalar") (serialize-qp "custom_fields" $custom_fields "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "strain_name" $strain_name "scalar") (serialize-qp "collection_date" $collection_date "scalar") (serialize-qp "collection_month" $collection_month "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "source_details" $source_details "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "source_niche" $source_niche "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "uberstrain" $uberstrain "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "collection_year" $collection_year "scalar") (serialize-qp "orderby" $orderby "scalar") (serialize-qp "assembly_status" $assembly_status "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "sample_accession" $sample_accession "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "top_species" $top_species "scalar") (serialize-qp "collection_time" $collection_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database)} | format pattern "/api/v2.0/{database}/straindata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"comment": $comment, "secondary_sample_accession": $secondary_sample_accession, "my_strains": $my_strains, "offset": $offset, "serotype": $serotype, "n50": $n50, "county": $county, "only_fields": $only_fields, "postcode": $postcode, "lab_contact": $lab_contact, "substrains": $substrains, "custom_fields": $custom_fields, "city": $city, "strain_name": $strain_name, "collection_date": $collection_date, "collection_month": $collection_month, "reldate": $reldate, "continent": $continent, "source_details": $source_details, "version": $version, "latitude": $latitude, "email": $email, "source_niche": $source_niche, "barcode": $barcode, "uberstrain": $uberstrain, "sortorder": $sortorder, "collection_year": $collection_year, "orderby": $orderby, "assembly_status": $assembly_status, "source_type": $source_type, "country": $country, "region": $region, "longitude": $longitude, "sample_accession": $sample_accession, "limit": $limit, "top_species": $top_species, "collection_time": $collection_time} | compact), body: null}
}

# Strain metadata
#
# GET /api/v2.0/{database}/strains
export def "v2-0-strains list" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --antigenic-formulas: string
  --my-strains: oneof<nothing, bool>
  --serotype: string
  --county: string
  --only-fields: list<string>
  --postcode: string
  --lab-contact: string
  --substrains: oneof<nothing, bool>
  --city: string
  --strain-name: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --reldate: int # format: int32
  --continent: string
  --source-details: string
  --version: int # format: int32
  --latitude: float # format: float
  --assembly-barcode: string
  --source-niche: string
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --uberstrain: string
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
  --collection-year: int # format: int32
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --return-all: oneof<nothing, bool>
  --source-type: string
  --country: string
  --region: string
  --longitude: float # format: float
  --sample-accession: string
  --limit: int # Number of results per page (format: int32, default: 50)
  --collection-time: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "comment" $comment "scalar") (serialize-qp "secondary_sample_accession" $secondary_sample_accession "scalar") (serialize-qp "antigenic_formulas" $antigenic_formulas "scalar") (serialize-qp "my_strains" $my_strains "scalar") (serialize-qp "serotype" $serotype "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "lab_contact" $lab_contact "scalar") (serialize-qp "substrains" $substrains "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "strain_name" $strain_name "scalar") (serialize-qp "collection_date" $collection_date "scalar") (serialize-qp "collection_month" $collection_month "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "source_details" $source_details "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "assembly_barcode" $assembly_barcode "scalar") (serialize-qp "source_niche" $source_niche "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "uberstrain" $uberstrain "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "collection_year" $collection_year "scalar") (serialize-qp "orderby" $orderby "scalar") (serialize-qp "return_all" $return_all "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "sample_accession" $sample_accession "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "collection_time" $collection_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database)} | format pattern "/api/v2.0/{database}/strains") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"comment": $comment, "secondary_sample_accession": $secondary_sample_accession, "antigenic_formulas": $antigenic_formulas, "my_strains": $my_strains, "serotype": $serotype, "county": $county, "only_fields": $only_fields, "postcode": $postcode, "lab_contact": $lab_contact, "substrains": $substrains, "city": $city, "strain_name": $strain_name, "collection_date": $collection_date, "collection_month": $collection_month, "reldate": $reldate, "continent": $continent, "source_details": $source_details, "version": $version, "latitude": $latitude, "assembly_barcode": $assembly_barcode, "source_niche": $source_niche, "barcode": $barcode, "uberstrain": $uberstrain, "sortorder": $sortorder, "offset": $offset, "collection_year": $collection_year, "orderby": $orderby, "return_all": $return_all, "source_type": $source_type, "country": $country, "region": $region, "longitude": $longitude, "sample_accession": $sample_accession, "limit": $limit, "collection_time": $collection_time} | compact), body: null}
}

# Strain metadata
#
# GET /api/v2.0/{database}/strains/{barcode}
export def "v2-0-strains get" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antigenic-formulas: string
  --assembly-barcode: string
  --body-barcode: list<string>
  --city: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --collection-time: string
  --collection-year: int # format: int32
  --comment: string
  --continent: string
  --country: string
  --county: string
  --lab-contact: string
  --latitude: float # format: float
  --limit: int # format: int32, default: 50
  --longitude: float # format: float
  --my-strains: oneof<nothing, bool>
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --postcode: string
  --region: string
  --reldate: int # format: int32
  --return-all: oneof<nothing, bool>
  --sample-accession: string
  --secondary-sample-accession: string
  --serotype: string
  --sortorder: string # default: asc
  --source-details: string
  --source-niche: string
  --source-type: string
  --strain-name: string
  --substrains: oneof<nothing, bool>
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/strains/{barcode}"))
  let req_body = {"antigenic_formulas": $antigenic_formulas, "assembly_barcode": $assembly_barcode, "barcode": $body_barcode, "city": $city, "collection_date": $collection_date, "collection_month": $collection_month, "collection_time": $collection_time, "collection_year": $collection_year, "comment": $comment, "continent": $continent, "country": $country, "county": $county, "lab_contact": $lab_contact, "latitude": $latitude, "limit": $limit, "longitude": $longitude, "my_strains": $my_strains, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "postcode": $postcode, "region": $region, "reldate": $reldate, "return_all": $return_all, "sample_accession": $sample_accession, "secondary_sample_accession": $secondary_sample_accession, "serotype": $serotype, "sortorder": $sortorder, "source_details": $source_details, "source_niche": $source_niche, "source_type": $source_type, "strain_name": $strain_name, "substrains": $substrains, "uberstrain": $uberstrain, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Strain metadata
#
# POST /api/v2.0/{database}/strains/{barcode}
export def "v2-0-strains create" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antigenic-formulas: string
  --assembly-barcode: string
  --body-barcode: list<string>
  --city: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --collection-time: string
  --collection-year: int # format: int32
  --comment: string
  --continent: string
  --country: string
  --county: string
  --lab-contact: string
  --latitude: float # format: float
  --limit: int # format: int32, default: 50
  --longitude: float # format: float
  --my-strains: oneof<nothing, bool>
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --postcode: string
  --region: string
  --reldate: int # format: int32
  --return-all: oneof<nothing, bool>
  --sample-accession: string
  --secondary-sample-accession: string
  --serotype: string
  --sortorder: string # default: asc
  --source-details: string
  --source-niche: string
  --source-type: string
  --strain-name: string
  --substrains: oneof<nothing, bool>
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/strains/{barcode}"))
  let req_body = {"antigenic_formulas": $antigenic_formulas, "assembly_barcode": $assembly_barcode, "barcode": $body_barcode, "city": $city, "collection_date": $collection_date, "collection_month": $collection_month, "collection_time": $collection_time, "collection_year": $collection_year, "comment": $comment, "continent": $continent, "country": $country, "county": $county, "lab_contact": $lab_contact, "latitude": $latitude, "limit": $limit, "longitude": $longitude, "my_strains": $my_strains, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "postcode": $postcode, "region": $region, "reldate": $reldate, "return_all": $return_all, "sample_accession": $sample_accession, "secondary_sample_accession": $secondary_sample_accession, "serotype": $serotype, "sortorder": $sortorder, "source_details": $source_details, "source_niche": $source_niche, "source_type": $source_type, "strain_name": $strain_name, "substrains": $substrains, "uberstrain": $uberstrain, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Strain metadata
#
# PUT /api/v2.0/{database}/strains/{barcode}
export def "v2-0-strains update" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antigenic-formulas: string
  --assembly-barcode: string
  --body-barcode: list<string>
  --city: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --collection-time: string
  --collection-year: int # format: int32
  --comment: string
  --continent: string
  --country: string
  --county: string
  --lab-contact: string
  --latitude: float # format: float
  --limit: int # format: int32, default: 50
  --longitude: float # format: float
  --my-strains: oneof<nothing, bool>
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --postcode: string
  --region: string
  --reldate: int # format: int32
  --return-all: oneof<nothing, bool>
  --sample-accession: string
  --secondary-sample-accession: string
  --serotype: string
  --sortorder: string # default: asc
  --source-details: string
  --source-niche: string
  --source-type: string
  --strain-name: string
  --substrains: oneof<nothing, bool>
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/strains/{barcode}"))
  let req_body = {"antigenic_formulas": $antigenic_formulas, "assembly_barcode": $assembly_barcode, "barcode": $body_barcode, "city": $city, "collection_date": $collection_date, "collection_month": $collection_month, "collection_time": $collection_time, "collection_year": $collection_year, "comment": $comment, "continent": $continent, "country": $country, "county": $county, "lab_contact": $lab_contact, "latitude": $latitude, "limit": $limit, "longitude": $longitude, "my_strains": $my_strains, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "postcode": $postcode, "region": $region, "reldate": $reldate, "return_all": $return_all, "sample_accession": $sample_accession, "secondary_sample_accession": $secondary_sample_accession, "serotype": $serotype, "sortorder": $sortorder, "source_details": $source_details, "source_niche": $source_niche, "source_type": $source_type, "strain_name": $strain_name, "substrains": $substrains, "uberstrain": $uberstrain, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Strain previous metadata
#
# GET /api/v2.0/{database}/strainsversion
export def "v2-0-strainsversion get" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --antigenic-formulas: string
  --my-strains: oneof<nothing, bool>
  --serotype: string
  --county: string
  --only-fields: list<string>
  --postcode: string
  --lab-contact: string
  --substrains: oneof<nothing, bool>
  --city: string
  --strain-name: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --reldate: int # format: int32
  --continent: string
  --source-details: string
  --version: int # format: int32
  --latitude: float # format: float
  --assembly-barcode: string
  --source-niche: string
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --uberstrain: string
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
  --collection-year: int # format: int32
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --return-all: oneof<nothing, bool>
  --source-type: string
  --country: string
  --region: string
  --longitude: float # format: float
  --sample-accession: string
  --limit: int # Number of results per page (format: int32, default: 50)
  --collection-time: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "comment" $comment "scalar") (serialize-qp "secondary_sample_accession" $secondary_sample_accession "scalar") (serialize-qp "antigenic_formulas" $antigenic_formulas "scalar") (serialize-qp "my_strains" $my_strains "scalar") (serialize-qp "serotype" $serotype "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "lab_contact" $lab_contact "scalar") (serialize-qp "substrains" $substrains "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "strain_name" $strain_name "scalar") (serialize-qp "collection_date" $collection_date "scalar") (serialize-qp "collection_month" $collection_month "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "source_details" $source_details "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "assembly_barcode" $assembly_barcode "scalar") (serialize-qp "source_niche" $source_niche "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "uberstrain" $uberstrain "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "collection_year" $collection_year "scalar") (serialize-qp "orderby" $orderby "scalar") (serialize-qp "return_all" $return_all "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "sample_accession" $sample_accession "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "collection_time" $collection_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database)} | format pattern "/api/v2.0/{database}/strainsversion") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"comment": $comment, "secondary_sample_accession": $secondary_sample_accession, "antigenic_formulas": $antigenic_formulas, "my_strains": $my_strains, "serotype": $serotype, "county": $county, "only_fields": $only_fields, "postcode": $postcode, "lab_contact": $lab_contact, "substrains": $substrains, "city": $city, "strain_name": $strain_name, "collection_date": $collection_date, "collection_month": $collection_month, "reldate": $reldate, "continent": $continent, "source_details": $source_details, "version": $version, "latitude": $latitude, "assembly_barcode": $assembly_barcode, "source_niche": $source_niche, "barcode": $barcode, "uberstrain": $uberstrain, "sortorder": $sortorder, "offset": $offset, "collection_year": $collection_year, "orderby": $orderby, "return_all": $return_all, "source_type": $source_type, "country": $country, "region": $region, "longitude": $longitude, "sample_accession": $sample_accession, "limit": $limit, "collection_time": $collection_time} | compact), body: null}
}

# Traces (sequence-reads) metadata
#
# GET /api/v2.0/{database}/traces
export def "v2-0-traces list" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --barcode: list<string> # Unique barcode for Traces records, __TR e.g. SAL_AA0001AA_TR
  --only-fields: list<string>
  --limit: int # Number of results per page (format: int32, default: 50)
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "orderby" $orderby "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database)} | format pattern "/api/v2.0/{database}/traces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"orderby": $orderby, "barcode": $barcode, "only_fields": $only_fields, "limit": $limit, "sortorder": $sortorder, "offset": $offset} | compact), body: null}
}

# Traces (sequence-reads) metadata
#
# GET /api/v2.0/{database}/traces/{barcode}
export def "v2-0-traces get" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string>
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --sortorder: string # default: asc
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/traces/{barcode}"))
  let req_body = {"barcode": $body_barcode, "limit": $limit, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "sortorder": $sortorder} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Traces (sequence-reads) metadata
#
# POST /api/v2.0/{database}/traces/{barcode}
export def "v2-0-traces create" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string>
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --sortorder: string # default: asc
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/traces/{barcode}"))
  let req_body = {"barcode": $body_barcode, "limit": $limit, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "sortorder": $sortorder} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Traces (sequence-reads) metadata
#
# PUT /api/v2.0/{database}/traces/{barcode}
export def "v2-0-traces update" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string>
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --sortorder: string # default: asc
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($barcode | is-empty) { error make --unspanned { msg: "path parameter 'barcode' must be non-empty" } }
  let full_url = (build-url $base ({database: (encode-path-segment $database), barcode: (encode-path-segment $barcode)} | format pattern "/api/v2.0/{database}/traces/{barcode}"))
  let req_body = {"barcode": $body_barcode, "limit": $limit, "offset": $offset, "only_fields": $only_fields, "orderby": $orderby, "sortorder": $sortorder} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Alleles data
#
# GET /api/v2.0/{database}/{scheme}/alleles
export def "v2-0-alleles get" [
  database: string
  scheme: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allele-id: string
  --seq: string
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --reldate: int # format: int32
  --locus: string
  --only-fields: list<string>
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($scheme | is-empty) { error make --unspanned { msg: "path parameter 'scheme' must be non-empty" } }
  let qp = [(serialize-qp "allele_id" $allele_id "scalar") (serialize-qp "seq" $seq "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "locus" $locus "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database), scheme: (encode-path-segment $scheme)} | format pattern "/api/v2.0/{database}/{scheme}/alleles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"allele_id": $allele_id, "seq": $seq, "barcode": $barcode, "reldate": $reldate, "locus": $locus, "only_fields": $only_fields, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Loci
#
# GET /api/v2.0/{database}/{scheme}/loci
export def "v2-0-loci get" [
  database: string
  scheme: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --locus: string
  --only-fields: list<string>
  --create-time: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --scheme: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($scheme | is-empty) { error make --unspanned { msg: "path parameter 'scheme' must be non-empty" } }
  let qp = [(serialize-qp "barcode" $barcode "multi") (serialize-qp "locus" $locus "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "create_time" $create_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "scheme" $scheme "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database), scheme: (encode-path-segment $scheme)} | format pattern "/api/v2.0/{database}/{scheme}/loci") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"barcode": $barcode, "locus": $locus, "only_fields": $only_fields, "create_time": $create_time, "limit": $limit, "offset": $offset, "scheme": $scheme} | compact), body: null}
}

# ST profile data
#
# GET /api/v2.0/{database}/{scheme}/sts
export def "v2-0-sts get" [
  database: string
  scheme: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --st-id: string
  --scheme: string
  --show-alleles: oneof<nothing, bool>
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --only-fields: list<string>
  --limit: int # format: int32, default: 50
  --reldate: int # format: int32
  --offset: int # format: int32, default: 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  if ($scheme | is-empty) { error make --unspanned { msg: "path parameter 'scheme' must be non-empty" } }
  let qp = [(serialize-qp "st_id" $st_id "scalar") (serialize-qp "scheme" $scheme "scalar") (serialize-qp "show_alleles" $show_alleles "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database: (encode-path-segment $database), scheme: (encode-path-segment $scheme)} | format pattern "/api/v2.0/{database}/{scheme}/sts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"st_id": $st_id, "scheme": $scheme, "show_alleles": $show_alleles, "barcode": $barcode, "only_fields": $only_fields, "limit": $limit, "reldate": $reldate, "offset": $offset} | compact), body: null}
}
