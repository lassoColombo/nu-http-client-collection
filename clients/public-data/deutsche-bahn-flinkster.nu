# Auto-generated client for Flinkster_API_NG vv1
# Source: https://api.apis.guru/v2/specs/deutschebahn.com/flinkster/v1/swagger.json
# Auth: --token flag or $env.FLINKSTER_API_NG_TOKEN

const BASE_URL = "https://api.deutschebahn.com/flinkster-api-ng/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FLINKSTER_API_NG_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.deutschebahn.com/flinkster-api-ng/v1" "http://api.deutschebahn.com/flinkster-api-ng/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "areas listAreas" } } | get name | first)
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

# List Areas by Criteria.
#
# GET /areas
# operationId: listAreas
export def "areas listAreas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # format: double
  --lon: float # format: double
  --radius: int # format: int32
  --offset: int # format: int32
  --limit: int # format: int32
  --expand: string
  --type: string
  --provider: string
  --providernetwork: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, address: record<city: string, district: string, isoCountryCode: string, number: string, street: string, zip: string>, attributes: record, description: string, expand: string, geometry: record<centroid: record<bbox: list, coordinates: record, crs: record>, position: record<bbox: list, crs: record>>, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerAreaId: string, providerNetworkIds: list<int>, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "providernetwork" $providernetwork "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/areas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get area by UID.
#
# GET /areas/{areaUID}
# operationId: getArea
export def "areas get" [
  areaUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand Provider
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, address: record<city: string, district: string, isoCountryCode: string, number: string, street: string, zip: string>, attributes: record, description: string, expand: string, geometry: record<centroid: record<bbox: list, coordinates: record, crs: record>, position: record<bbox: list, crs: record>>, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerAreaId: string, providerNetworkIds: list<int>, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/areas/($areaUID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query for available RentalObjects of a specific view
#
# GET /bookingproposals
# operationId: listBookingProposals
export def "bookingproposals listBookingProposals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # format: double
  --lon: float # format: double
  --radius: int # format: int32
  --offset: int # format: int32
  --limit: int # format: int32
  --providernetwork: string
  --begin: string
  --end: string
  --expand: string
  --view: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "providernetwork" $providernetwork "scalar") (serialize-qp "begin" $begin "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bookingproposals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show index.
#
# GET /index
# operationId: getIndex
export def "index get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, href: string, items: table<_links: list, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, limit: int, offset: int, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/index")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all categories
#
# GET /providernetworks/{providernetworkUID}/categories
# operationId: listCategories
export def "providernetworks-categories listCategories" [
  providernetworkUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, description: string, expand: string, href: string, name: string, price: table<_links: list, attributes: record, currency: string, description: string, expand: string, grossamount: float, href: string, interval: int, name: string, preferredprice: bool, taxrate: float, type: string, uid: string>, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providernetworks/($providernetworkUID)/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Category by UID
#
# GET /providernetworks/{providernetworkUID}/categories/{categoryUID}
# operationId: getCategory
export def "providernetworks-categories get" [
  providernetworkUID: string
  categoryUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, description: string, expand: string, href: string, name: string, price: table<_links: list, attributes: record, currency: string, description: string, expand: string, grossamount: float, href: string, interval: int, name: string, preferredprice: bool, taxrate: float, type: string, uid: string>, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providernetworks/($providernetworkUID)/categories/($categoryUID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about the prices.
#
# GET /providernetworks/{providernetworkUID}/prices
# operationId: getPrices
export def "providernetworks-prices get" [
  providernetworkUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/providernetworks/($providernetworkUID)/prices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about the RentalObject.
#
# GET /providernetworks/{providernetworkUID}/rentalobjects/{rentalObjectUID}
# operationId: getRentalObject
export def "providernetworks-rentalobjects get" [
  rentalObjectUID: string
  providernetworkUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providernetworks/($providernetworkUID)/rentalobjects/($rentalObjectUID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about the ProviderNetworkResources.
#
# GET /providernetworks/{uid}
# operationId: getProviderNetwork
export def "providernetworks get" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/providernetworks/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about the ProviderResourceImpl.
#
# GET /providers/{uid}
# operationId: getProvider
export def "providers get" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/providers/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
