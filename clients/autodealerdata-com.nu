# Auto-generated client for CIS Automotive API v1.0
# Source: https://api.apis.guru/v2/specs/autodealerdata.com/1.0/openapi.json
# Auth: --token flag or $env.CIS_AUTOMOTIVE_API_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CIS_AUTOMOTIVE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "days-supply get" } } | get name | first)
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

# Days worth of supply left on dealer lots
#
# GET /daysSupply
# operationId: daysSupply_daysSupply_get
export def "days-supply get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/daysSupply" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact), body: null}
}

# Days a vehicle takes to sell
#
# GET /daysToSell
# operationId: daysToSell_daysToSell_get
export def "days-to-sell get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/daysToSell" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact), body: null}
}

# Get a list of brand names
#
# GET /getBrands
# operationId: getBrandNames_getBrands_get
export def "get-brands get-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: list<string>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getBrands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt} | compact), body: null}
}

# Premium. Dealers in a zip code.
#
# GET /getDealers
# operationId: getDealers_getDealers_get
export def "get-dealers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --zip-code: int
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<address: string, dealerName: string, ids: list, state: string, zipCode: int>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "zipCode" $zip_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getDealers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "zipCode": $zip_code} | compact), body: null}
}

# Premium. Dealers by ID
#
# GET /getDealersByID
# operationId: getDealers_getDealersByID_get
export def "get-dealers-by-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --dealer-id: int
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<address: string, dealerName: string, ids: list, state: string, zipCode: int>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "dealerID" $dealer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getDealersByID" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "dealerID": $dealer_id} | compact), body: null}
}

# Premium. Dealers in a region.
#
# GET /getDealersByRegion
# operationId: getDealers_getDealersByRegion_get
export def "get-dealers-by-region get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --region-name: string # default: REGION_STATE_CA
  --page: int # default: 1
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<dealers: list<record>, maxPages: int, page: int>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getDealersByRegion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "regionName": $region_name, "page": $page} | compact), body: null}
}

# Get a list of model names including discontinued models
#
# GET /getInactiveModels
# operationId: getModelNamesAll_getInactiveModels_get
export def "get-inactive-models list-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<modelName: string>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getInactiveModels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name} | compact), body: null}
}

# Get a list of model names
#
# GET /getModels
# operationId: getModelNames_getModels_get
export def "get-models get-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<modelName: string>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getModels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name} | compact), body: null}
}

# Market share of a brand in region
#
# GET /getRegionBrandMarketShare
# operationId: getRegionBrandMarketShare_getRegionBrandMarketShare_get
export def "get-region-brand-market-share get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getRegionBrandMarketShare" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact), body: null}
}

# Market share of all brands in region
#
# GET /getRegionMarketShare
# operationId: getRegionMarketShare_getRegionMarketShare_get
export def "get-region-market-share get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getRegionMarketShare" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "regionName": $region_name} | compact), body: null}
}

# Get a list of region names
#
# GET /getRegions
# operationId: getRegions_getRegions_get
export def "get-regions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: list<string>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getRegions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt} | compact), body: null}
}

# Get all Sub User Keys associated with your account.
#
# GET /getSubUserKeys
# operationId: getSubUserKeys_getSubUserKeys_get
export def "get-sub-user-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string
  --api-key: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getSubUserKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"apiID": $api_id, "apiKey": $api_key} | compact), body: null}
}

# Get a JWT from your API credentials
#
# GET /getToken
# operationId: makeToken_getToken_get
export def "get-token get-make" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string
  --api-key: string
]: nothing -> record<createdOn: int, expires: int, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getToken" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"apiID": $api_id, "apiKey": $api_key} | compact), body: null}
}

# Get a JWT from your API credentials
#
# POST /getToken
# operationId: makeToken_getToken_post
export def "get-token create-make" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string
  --api-key: string
]: nothing -> record<createdOn: int, expires: int, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getToken" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"apiID": $api_id, "apiKey": $api_key} | compact), body: null}
}

# Stats on ask price of new vehicles
#
# GET /listPrice
# operationId: getAvgListPrice_listPrice_get
export def "list-price get-avg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<average: float, median: float, name: string, pVariance: float, stdDev: float>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listPrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact), body: null}
}

# Listings by Dealer ID
#
# GET /listings
# operationId: getListingsByDealer_listings_get
export def "listings get-by-dealer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --dealer-id: int
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "dealerID" $dealer_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "dealerID": $dealer_id, "page": $page, "newCars": $new_cars} | compact), body: null}
}

# Flexible Listing Search
#
# GET /listings2
# operationId: getListings2_listings2_get
export def "listings2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --dealer-id: int # default: 0
  --zip-code: int # default: 0
  --latitude: float # default: 0
  --longitude: float # default: 0
  --radius: float # default: 0
  --region-name: string
  --brand-name: string
  --model-name: string
  --model-year: int # default: 0
  --mileage-low: int # default: 0
  --mileage-high: int # default: 0
  --start-date: string # format: date
  --end-date: string # format: date
  --days-back: int # default: 45
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
  --extended-search: oneof<nothing, bool> # default: false
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "dealerID" $dealer_id "scalar") (serialize-qp "zipCode" $zip_code "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "modelYear" $model_year "scalar") (serialize-qp "mileageLow" $mileage_low "scalar") (serialize-qp "mileageHigh" $mileage_high "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "daysBack" $days_back "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar") (serialize-qp "extendedSearch" $extended_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listings2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "dealerID": $dealer_id, "zipCode": $zip_code, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "regionName": $region_name, "brandName": $brand_name, "modelName": $model_name, "modelYear": $model_year, "mileageLow": $mileage_low, "mileageHigh": $mileage_high, "startDate": $start_date, "endDate": $end_date, "daysBack": $days_back, "page": $page, "newCars": $new_cars, "extendedSearch": $extended_search} | compact), body: null}
}

# Listings by Dealer ID and Date
#
# GET /listingsByDate
# operationId: getListingsByDealer_listingsByDate_get
export def "listings-by-date get-dealer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --dealer-id: int
  --start-date: string # format: date
  --end-date: string # format: date
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "dealerID" $dealer_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByDate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "dealerID": $dealer_id, "startDate": $start_date, "endDate": $end_date, "page": $page, "newCars": $new_cars} | compact), body: null}
}

# Listings by Region
#
# GET /listingsByRegion
# operationId: getListingsByRegion_listingsByRegion_get
export def "listings-by-region get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --region-name: string
  --model-name: string
  --days-back: int # default: 10
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "daysBack" $days_back "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByRegion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "regionName": $region_name, "modelName": $model_name, "daysBack": $days_back, "page": $page, "newCars": $new_cars} | compact), body: null}
}

# Listings by Region and Date
#
# GET /listingsByRegionAndDate
# operationId: getListingsByRegionAndDate_listingsByRegionAndDate_get
export def "listings-by-region-and-date get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --region-name: string
  --model-name: string
  --start-date: string # format: date
  --end-date: string # format: date
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByRegionAndDate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "regionName": $region_name, "modelName": $model_name, "startDate": $start_date, "endDate": $end_date, "page": $page, "newCars": $new_cars} | compact), body: null}
}

# Listings by ZipCode
#
# GET /listingsByZipCode
# operationId: listingsByZipCode_listingsByZipCode_get
export def "listings-by-zip-code get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --zip-code: int
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
  --model-name: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "zipCode" $zip_code "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar") (serialize-qp "modelName" $model_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByZipCode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "zipCode": $zip_code, "page": $page, "newCars": $new_cars, "modelName": $model_name} | compact), body: null}
}

# Listings by ZipCode and Date
#
# GET /listingsByZipCodeAndDate
# operationId: listingsByZipCodeAndDate_listingsByZipCodeAndDate_get
export def "listings-by-zip-code-and-date get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --zip-code: int
  --start-date: string # format: date
  --end-date: string # format: date
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
  --model-name: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "zipCode" $zip_code "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar") (serialize-qp "modelName" $model_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByZipCodeAndDate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "zipCode": $zip_code, "startDate": $start_date, "endDate": $end_date, "page": $page, "newCars": $new_cars, "modelName": $model_name} | compact), body: null}
}

# Generate a Sub User Key that can be used by your users to make API calls in frontend applications.
#
# POST /makeSubUserKey
# operationId: makeSubUserKey_makeSubUserKey_post
export def "make-sub-user-key create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string
  --api-key: string
  --site-name: string # default: localhost
  --end-points: list<string> # default: [*]
]: any -> record<createdOn: int, domain: string, endPoints: list<string>, expires: int, token: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar") (serialize-qp "siteName" $site_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/makeSubUserKey" $qp)
  let req_body = {"endPoints": $end_points} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"apiID": $api_id, "apiKey": $api_key, "siteName": $site_name} | compact), body: $req_body}
}

# Used market share of model year by model
#
# GET /modelYearDist
# operationId: getModelUsedDist_modelYearDist_get
export def "model-year-dist get-used" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --model-name: string
  --brand-name: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<brandName: string, modelName: string, percentOfMarket: float, year: int>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/modelYearDist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "modelName": $model_name, "brandName": $brand_name, "regionName": $region_name} | compact), body: null}
}

# Brand sales by region and Day
#
# GET /regionDailySales
# operationId: getDealerSales_regionDailySales_get
export def "region-daily-sales get-dealer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
  --region-name: string
  --day: string # format: date
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "day" $day "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/regionDailySales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name, "day": $day} | compact), body: null}
}

# Premium. Brand sales by region and month
#
# GET /regionSales
# operationId: getDealerSales_regionSales_get
export def "region-sales get-dealer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
  --region-name: string
  --month: string # format: date
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "month" $month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/regionSales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name, "month": $month} | compact), body: null}
}

# Revoke a Sub User Key associated with your account.
#
# PUT /revokeSubUserKey
# operationId: revokeSubUserKey_revokeSubUserKey_put
export def "revoke-sub-user-key update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string
  --api-key: string
  --sub-user-key-uuid: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar") (serialize-qp "subUserKeyUUID" $sub_user_key_uuid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/revokeSubUserKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"apiID": $api_id, "apiKey": $api_key, "subUserKeyUUID": $sub_user_key_uuid} | compact), body: null}
}

# Stats on sale price of new vehicles
#
# GET /salePrice
# operationId: getAvgSalePrice_salePrice_get
export def "sale-price get-avg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --brand-name: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<average: float, median: float, name: string, pVariance: float, stdDev: float>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/salePrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact), body: null}
}

# Histogram of sales price of new vehicles by model
#
# GET /salePriceHistogram
# operationId: getModelSaleBuckets_salePriceHistogram_get
export def "sale-price-histogram get-model-buckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --model-name: string
  --brand-name: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<bucket: float, modelName: string, percentOfMarket: float>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/salePriceHistogram" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "modelName": $model_name, "brandName": $brand_name, "regionName": $region_name} | compact), body: null}
}

# Premium. Simple Vehicle Market Report
#
# GET /similarSalePrice
# operationId: getMarket3_similarSalePrice_get
export def "similar-sale-price get-market3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --vin: string
  --region-name: string # default: REGION_STATE_CA
  --days-back: int # default: 45
  --same-year: oneof<nothing, bool> # default: false
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<daysBack: int, mileCount: int, milesAvg: float, milesStdDev: float, newCount: int, newSaleAvg: float, newSaleStdDev: float, usedCount: int, usedSaleAvg: float, usedSaleStdDev: float>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "daysBack" $days_back "scalar") (serialize-qp "sameYear" $same_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/similarSalePrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "vin": $vin, "regionName": $region_name, "daysBack": $days_back, "sameYear": $same_year} | compact), body: null}
}

# Top models in a given region
#
# GET /topModels
# operationId: getTopModels_topModels_get
export def "top-models get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --region-name: string # default: REGION_STATE_CA
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: table<brandMarketShare: float, brandName: string, modelName: string, percentOfBrandSales: float, percentOfTopSales: float>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/topModels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "regionName": $region_name} | compact), body: null}
}

# Premium. Simple Vehicle Market Report Over Arbitrary Locations and Vehicles.
#
# GET /valuation
# operationId: getMarket4_valuation_get
export def "valuation get-market4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --vin: string
  --dealer-id: int # default: 0
  --zip-code: int # default: 0
  --latitude: float # default: 0
  --longitude: float # default: 0
  --radius: float # default: 0
  --region-name: string
  --mileage-low: int # default: 0
  --mileage-high: int # default: 0
  --start-date: string # format: date
  --end-date: string # format: date
  --days-back: int # default: 45
  --new-cars: oneof<nothing, bool> # default: false
  --extended-search: oneof<nothing, bool> # default: false
  --same-year: oneof<nothing, bool> # default: false
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<daysBack: int, mileCount: int, milesAvg: float, milesStdDev: float, newCount: int, newSaleAvg: float, newSaleStdDev: float, usedCount: int, usedSaleAvg: float, usedSaleStdDev: float>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "dealerID" $dealer_id "scalar") (serialize-qp "zipCode" $zip_code "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "mileageLow" $mileage_low "scalar") (serialize-qp "mileageHigh" $mileage_high "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "daysBack" $days_back "scalar") (serialize-qp "newCars" $new_cars "scalar") (serialize-qp "extendedSearch" $extended_search "scalar") (serialize-qp "sameYear" $same_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/valuation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "vin": $vin, "dealerID": $dealer_id, "zipCode": $zip_code, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "regionName": $region_name, "mileageLow": $mileage_low, "mileageHigh": $mileage_high, "startDate": $start_date, "endDate": $end_date, "daysBack": $days_back, "newCars": $new_cars, "extendedSearch": $extended_search, "sameYear": $same_year} | compact), body: null}
}

# Premium. Simple Vehicle History Report
#
# GET /vehicleHistory
# operationId: getHistory2_vehicleHistory_get
export def "vehicle-history get-history2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --vin: string
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: record<data: list<record>, vin: string>, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vehicleHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "vin": $vin} | compact), body: null}
}

# Checks if a VIN appeared on the market on or after a given date.
#
# GET /vehicleSeen
# operationId: getVehicleSeen_vehicleSeen_get
export def "vehicle-seen get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --vin: string
  --after-date: string # format: date
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: bool, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "afterDate" $after_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vehicleSeen" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "vin": $vin, "afterDate": $after_date} | compact), body: null}
}

# Vin decoder and Recall Info
#
# GET /vinDecode
# operationId: vinDecode_vinDecode_get
export def "vin-decode get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
  --vin: string
  --pass-empty: oneof<nothing, bool> # default: false
  --include-recall: oneof<nothing, bool> # default: true
]: nothing -> record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "passEmpty" $pass_empty "scalar") (serialize-qp "includeRecall" $include_recall "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vinDecode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jwt": $jwt, "vin": $vin, "passEmpty": $pass_empty, "includeRecall": $include_recall} | compact), body: null}
}
