# Auto-generated client for Enterobase-API vv2.0
# Source: https://api.apis.guru/v2/specs/warwick.ac.uk/enterobase/v2.0/openapi.json
# Auth: --token flag or $env.ENTEROBASE_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ENTEROBASE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["basic"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v20 get" } } | get name | first)
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
export def "v20 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login endpoint, refresh your API token
#
# GET /api/v2.0/login
export def "v20-login get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generic endpoint for lookup list of barcodes
#
# GET /api/v2.0/lookup
export def "v20-lookup list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string # Unique barcode for Traces records, <database prefix>_<ID code>_<Table code> e.g. SAL_AA0001AA_ST
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "barcode" $barcode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2.0/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generic endpoint for lookup of barcodes
#
# GET /api/v2.0/lookup/{barcode}
export def "v20-lookup get" [
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2.0/lookup/($barcode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generic endpoint for lookup of barcodes
#
# POST /api/v2.0/lookup/{barcode}
export def "v20-lookup post" [
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2.0/lookup/($barcode)")
  let body = {barcode: $body_barcode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Genome assemblies
#
# GET /api/v2.0/{database}/assemblies
export def "v20-assemblies list" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --only-fields: list
  --barcode: list # Unique barcode for Traces records, <database prefix>_<ID code>_AS e.g. SAL_AA0001AA_AS
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
  let qp = [(serialize-qp "orderby" $orderby "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "barcode" $barcode "multi") (serialize-qp "n50" $n50 "scalar") (serialize-qp "top_species" $top_species "scalar") (serialize-qp "uberstrain" $uberstrain "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "assembly_status" $assembly_status "scalar") (serialize-qp "sortorder" $sortorder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/assemblies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Genome assemblies
#
# GET /api/v2.0/{database}/assemblies/{barcode}
export def "v20-assemblies get" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assembly-status: string
  --body-barcode: list
  --limit: int # format: int32, default: 50
  --n50: int # format: int32
  --offset: int # format: int32, default: 0
  --only-fields: list
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
  let full_url = (build-url $base $"/api/v2.0/($database)/assemblies/($barcode)")
  let body = {assembly_status: $assembly_status, barcode: $body_barcode, limit: $limit, n50: $n50, offset: $offset, only_fields: $only_fields, orderby: $orderby, reldate: $reldate, sortorder: $sortorder, top_species: $top_species, uberstrain: $uberstrain, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Genome assemblies
#
# POST /api/v2.0/{database}/assemblies/{barcode}
export def "v20-assemblies post" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assembly-status: string
  --body-barcode: list
  --limit: int # format: int32, default: 50
  --n50: int # format: int32
  --offset: int # format: int32, default: 0
  --only-fields: list
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
  let full_url = (build-url $base $"/api/v2.0/($database)/assemblies/($barcode)")
  let body = {assembly_status: $assembly_status, barcode: $body_barcode, limit: $limit, n50: $n50, offset: $offset, only_fields: $only_fields, orderby: $orderby, reldate: $reldate, sortorder: $sortorder, top_species: $top_species, uberstrain: $uberstrain, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Genome assemblies
#
# PUT /api/v2.0/{database}/assemblies/{barcode}
export def "v20-assemblies put" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assembly-status: string
  --body-barcode: list
  --limit: int # format: int32, default: 50
  --n50: int # format: int32
  --offset: int # format: int32, default: 0
  --only-fields: list
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
  let full_url = (build-url $base $"/api/v2.0/($database)/assemblies/($barcode)")
  let body = {assembly_status: $assembly_status, barcode: $body_barcode, limit: $limit, n50: $n50, offset: $offset, only_fields: $only_fields, orderby: $orderby, reldate: $reldate, sortorder: $sortorder, top_species: $top_species, uberstrain: $uberstrain, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Genotyping schemes
#
# GET /api/v2.0/{database}/schemes
export def "v20-schemes list" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --scheme-name: string
  --created: string # format: date-time
  --lastmodified: string # format: date-time
  --barcode: list # Unique barcode for Strain records, <database prefix>_<ID code> e.g. SAL_AA0001AA
  --label: string
  --only-fields: list
  --version: int # format: int32
  --limit: int # Number of results per page (format: int32, default: 50)
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderby" $orderby "scalar") (serialize-qp "scheme_name" $scheme_name "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "lastmodified" $lastmodified "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "label" $label "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "version" $version "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/schemes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Genotyping schemes
#
# GET /api/v2.0/{database}/schemes/{barcode}
export def "v20-schemes get" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list
  --created: string # format: date-time
  --label: string
  --lastmodified: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list
  --orderby: string # default: barcode
  --scheme-name: string
  --sortorder: string # default: asc
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2.0/($database)/schemes/($barcode)")
  let body = {barcode: $body_barcode, created: $created, label: $label, lastmodified: $lastmodified, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, scheme_name: $scheme_name, sortorder: $sortorder, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Genotyping schemes
#
# POST /api/v2.0/{database}/schemes/{barcode}
export def "v20-schemes post" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list
  --created: string # format: date-time
  --label: string
  --lastmodified: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list
  --orderby: string # default: barcode
  --scheme-name: string
  --sortorder: string # default: asc
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2.0/($database)/schemes/($barcode)")
  let body = {barcode: $body_barcode, created: $created, label: $label, lastmodified: $lastmodified, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, scheme_name: $scheme_name, sortorder: $sortorder, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Genotyping schemes
#
# PUT /api/v2.0/{database}/schemes/{barcode}
export def "v20-schemes put" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list
  --created: string # format: date-time
  --label: string
  --lastmodified: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list
  --orderby: string # default: barcode
  --scheme-name: string
  --sortorder: string # default: asc
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2.0/($database)/schemes/($barcode)")
  let body = {barcode: $body_barcode, created: $created, label: $label, lastmodified: $lastmodified, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, scheme_name: $scheme_name, sortorder: $sortorder, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Strain data
#
# GET /api/v2.0/{database}/straindata
export def "v20-straindata get" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --my-strains: oneof<nothing, bool>
  --offset: int # Cursor position in results (format: int32, default: 0)
  --serotype: string
  --n50: int # format: int32
  --county: string
  --only-fields: list
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
  --barcode: list # Unique barcode for Traces records, <database prefix>_<ID code>_AS e.g. SAL_AA0001AA_AS
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
  let qp = [(serialize-qp "comment" $comment "scalar") (serialize-qp "secondary_sample_accession" $secondary_sample_accession "scalar") (serialize-qp "my_strains" $my_strains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "serotype" $serotype "scalar") (serialize-qp "n50" $n50 "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "lab_contact" $lab_contact "scalar") (serialize-qp "substrains" $substrains "scalar") (serialize-qp "custom_fields" $custom_fields "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "strain_name" $strain_name "scalar") (serialize-qp "collection_date" $collection_date "scalar") (serialize-qp "collection_month" $collection_month "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "source_details" $source_details "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "source_niche" $source_niche "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "uberstrain" $uberstrain "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "collection_year" $collection_year "scalar") (serialize-qp "orderby" $orderby "scalar") (serialize-qp "assembly_status" $assembly_status "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "sample_accession" $sample_accession "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "top_species" $top_species "scalar") (serialize-qp "collection_time" $collection_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/straindata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Strain metadata
#
# GET /api/v2.0/{database}/strains
export def "v20-strains list" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --antigenic-formulas: string
  --my-strains: oneof<nothing, bool>
  --serotype: string
  --county: string
  --only-fields: list
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
  --barcode: list # Unique barcode for Strain records, <database prefix>_<ID code> e.g. SAL_AA0001AA
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
  let qp = [(serialize-qp "comment" $comment "scalar") (serialize-qp "secondary_sample_accession" $secondary_sample_accession "scalar") (serialize-qp "antigenic_formulas" $antigenic_formulas "scalar") (serialize-qp "my_strains" $my_strains "scalar") (serialize-qp "serotype" $serotype "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "lab_contact" $lab_contact "scalar") (serialize-qp "substrains" $substrains "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "strain_name" $strain_name "scalar") (serialize-qp "collection_date" $collection_date "scalar") (serialize-qp "collection_month" $collection_month "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "source_details" $source_details "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "assembly_barcode" $assembly_barcode "scalar") (serialize-qp "source_niche" $source_niche "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "uberstrain" $uberstrain "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "collection_year" $collection_year "scalar") (serialize-qp "orderby" $orderby "scalar") (serialize-qp "return_all" $return_all "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "sample_accession" $sample_accession "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "collection_time" $collection_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/strains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Strain metadata
#
# GET /api/v2.0/{database}/strains/{barcode}
export def "v20-strains get" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --antigenic-formulas: string
  --assembly-barcode: string
  --body-barcode: list
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
  --only-fields: list
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
  let full_url = (build-url $base $"/api/v2.0/($database)/strains/($barcode)")
  let body = {antigenic_formulas: $antigenic_formulas, assembly_barcode: $assembly_barcode, barcode: $body_barcode, city: $city, collection_date: $collection_date, collection_month: $collection_month, collection_time: $collection_time, collection_year: $collection_year, comment: $comment, continent: $continent, country: $country, county: $county, lab_contact: $lab_contact, latitude: $latitude, limit: $limit, longitude: $longitude, my_strains: $my_strains, offset: $offset, only_fields: $only_fields, orderby: $orderby, postcode: $postcode, region: $region, reldate: $reldate, return_all: $return_all, sample_accession: $sample_accession, secondary_sample_accession: $secondary_sample_accession, serotype: $serotype, sortorder: $sortorder, source_details: $source_details, source_niche: $source_niche, source_type: $source_type, strain_name: $strain_name, substrains: $substrains, uberstrain: $uberstrain, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Strain metadata
#
# POST /api/v2.0/{database}/strains/{barcode}
export def "v20-strains post" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --antigenic-formulas: string
  --assembly-barcode: string
  --body-barcode: list
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
  --only-fields: list
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
  let full_url = (build-url $base $"/api/v2.0/($database)/strains/($barcode)")
  let body = {antigenic_formulas: $antigenic_formulas, assembly_barcode: $assembly_barcode, barcode: $body_barcode, city: $city, collection_date: $collection_date, collection_month: $collection_month, collection_time: $collection_time, collection_year: $collection_year, comment: $comment, continent: $continent, country: $country, county: $county, lab_contact: $lab_contact, latitude: $latitude, limit: $limit, longitude: $longitude, my_strains: $my_strains, offset: $offset, only_fields: $only_fields, orderby: $orderby, postcode: $postcode, region: $region, reldate: $reldate, return_all: $return_all, sample_accession: $sample_accession, secondary_sample_accession: $secondary_sample_accession, serotype: $serotype, sortorder: $sortorder, source_details: $source_details, source_niche: $source_niche, source_type: $source_type, strain_name: $strain_name, substrains: $substrains, uberstrain: $uberstrain, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Strain metadata
#
# PUT /api/v2.0/{database}/strains/{barcode}
export def "v20-strains put" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --antigenic-formulas: string
  --assembly-barcode: string
  --body-barcode: list
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
  --only-fields: list
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
  let full_url = (build-url $base $"/api/v2.0/($database)/strains/($barcode)")
  let body = {antigenic_formulas: $antigenic_formulas, assembly_barcode: $assembly_barcode, barcode: $body_barcode, city: $city, collection_date: $collection_date, collection_month: $collection_month, collection_time: $collection_time, collection_year: $collection_year, comment: $comment, continent: $continent, country: $country, county: $county, lab_contact: $lab_contact, latitude: $latitude, limit: $limit, longitude: $longitude, my_strains: $my_strains, offset: $offset, only_fields: $only_fields, orderby: $orderby, postcode: $postcode, region: $region, reldate: $reldate, return_all: $return_all, sample_accession: $sample_accession, secondary_sample_accession: $secondary_sample_accession, serotype: $serotype, sortorder: $sortorder, source_details: $source_details, source_niche: $source_niche, source_type: $source_type, strain_name: $strain_name, substrains: $substrains, uberstrain: $uberstrain, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Strain previous metadata
#
# GET /api/v2.0/{database}/strainsversion
export def "v20-strainsversion get" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --antigenic-formulas: string
  --my-strains: oneof<nothing, bool>
  --serotype: string
  --county: string
  --only-fields: list
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
  --barcode: list # Unique barcode for Strain records, <database prefix>_<ID code> e.g. SAL_AA0001AA
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
  let qp = [(serialize-qp "comment" $comment "scalar") (serialize-qp "secondary_sample_accession" $secondary_sample_accession "scalar") (serialize-qp "antigenic_formulas" $antigenic_formulas "scalar") (serialize-qp "my_strains" $my_strains "scalar") (serialize-qp "serotype" $serotype "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "lab_contact" $lab_contact "scalar") (serialize-qp "substrains" $substrains "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "strain_name" $strain_name "scalar") (serialize-qp "collection_date" $collection_date "scalar") (serialize-qp "collection_month" $collection_month "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "source_details" $source_details "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "assembly_barcode" $assembly_barcode "scalar") (serialize-qp "source_niche" $source_niche "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "uberstrain" $uberstrain "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "collection_year" $collection_year "scalar") (serialize-qp "orderby" $orderby "scalar") (serialize-qp "return_all" $return_all "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "sample_accession" $sample_accession "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "collection_time" $collection_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/strainsversion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Traces (sequence-reads) metadata
#
# GET /api/v2.0/{database}/traces
export def "v20-traces list" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --barcode: list # Unique barcode for Traces records, <database prefix>_<ID code>_TR e.g. SAL_AA0001AA_TR
  --only-fields: list
  --limit: int # Number of results per page (format: int32, default: 50)
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderby" $orderby "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortorder" $sortorder "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/traces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Traces (sequence-reads) metadata
#
# GET /api/v2.0/{database}/traces/{barcode}
export def "v20-traces get" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list
  --orderby: string # default: barcode
  --sortorder: string # default: asc
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2.0/($database)/traces/($barcode)")
  let body = {barcode: $body_barcode, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, sortorder: $sortorder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Traces (sequence-reads) metadata
#
# POST /api/v2.0/{database}/traces/{barcode}
export def "v20-traces post" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list
  --orderby: string # default: barcode
  --sortorder: string # default: asc
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2.0/($database)/traces/($barcode)")
  let body = {barcode: $body_barcode, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, sortorder: $sortorder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Traces (sequence-reads) metadata
#
# PUT /api/v2.0/{database}/traces/{barcode}
export def "v20-traces put" [
  barcode: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list
  --orderby: string # default: barcode
  --sortorder: string # default: asc
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2.0/($database)/traces/($barcode)")
  let body = {barcode: $body_barcode, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, sortorder: $sortorder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Alleles  data 
#
# GET /api/v2.0/{database}/{scheme}/alleles
export def "v20-alleles get" [
  scheme: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allele-id: string
  --seq: string
  --barcode: list # Unique barcode for Strain records, <database prefix>_<ID code> e.g. SAL_AA0001AA
  --reldate: int # format: int32
  --locus: string
  --only-fields: list
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allele_id" $allele_id "scalar") (serialize-qp "seq" $seq "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "locus" $locus "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/($scheme)/alleles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Loci 
#
# GET /api/v2.0/{database}/{scheme}/loci
export def "v20-loci get" [
  scheme: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: list # Unique barcode for Strain records, <database prefix>_<ID code> e.g. SAL_AA0001AA
  --locus: string
  --only-fields: list
  --create-time: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --scheme: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "barcode" $barcode "multi") (serialize-qp "locus" $locus "scalar") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "create_time" $create_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "scheme" $scheme "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/($scheme)/loci" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ST profile data
#
# GET /api/v2.0/{database}/{scheme}/sts
export def "v20-sts get" [
  scheme: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --st-id: string
  --scheme: string
  --show-alleles: oneof<nothing, bool>
  --barcode: list # Unique barcode for Strain records, <database prefix>_<ID code> e.g. SAL_AA0001AA
  --only-fields: list
  --limit: int # format: int32, default: 50
  --reldate: int # format: int32
  --offset: int # format: int32, default: 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "st_id" $st_id "scalar") (serialize-qp "scheme" $scheme "scalar") (serialize-qp "show_alleles" $show_alleles "scalar") (serialize-qp "barcode" $barcode "multi") (serialize-qp "only_fields" $only_fields "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "reldate" $reldate "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2.0/($database)/($scheme)/sts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
