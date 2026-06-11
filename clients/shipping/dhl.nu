# Auto-generated client for DHL Location Finder Unified API v1
# Source: https://raw.githubusercontent.com/api-evangelist/dhl/main/openapi/dhl-openapi.yml
# Auth: --token flag or $env.DHL_LOCATION_FINDER_UNIFIED_API_TOKEN

const BASE_URL = "https://api.dhl.com/location-finder/v1"
const DEFAULT_AUTH = "dhl-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DHL_LOCATION_FINDER_UNIFIED_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "dhl-api-key" => { {headers: {DHL-API-Key: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.dhl.com/location-finder/v1"] }
def auth-scheme-completer [] { ["dhl-api-key"] }

# Completers for enum parameters
def providerType-completer [] { ["express" "parcel"] }
def locationType-completer [] { ["locker" "pobox" "postbox" "postoffice" "servicepoint"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "find-by-address findByAddress" } } | get name | first)
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

# Find Service Points by address
#
# GET /find-by-address
# operationId: findByAddress
export def "find-by-address findByAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --countryCode: string
  --postalCode: string
  --addressLocality: string
  --streetAddress: string
  --providerType: string@providerType-completer
  --serviceType: string
  --locationType: string@locationType-completer
  --radius: int # default: 5000
  --limit: int
  --hideClosedShops: string@bool-completer
]: nothing -> record<url: string, locations: table<url: string, location: record, name: string, place: record>> {
  let auth = (build-auth $token ($auth_scheme | default "dhl-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "postalCode" $postalCode "scalar") (serialize-qp "addressLocality" $addressLocality "scalar") (serialize-qp "streetAddress" $streetAddress "scalar") (serialize-qp "providerType" $providerType "scalar") (serialize-qp "serviceType" $serviceType "scalar") (serialize-qp "locationType" $locationType "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "hideClosedShops" $hideClosedShops "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/find-by-address" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find Service Points by geographic coordinates
#
# GET /find-by-geo
# operationId: findByGeo
export def "find-by-geo findByGeo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --latitude: float # format: double
  --longitude: float # format: double
  --providerType: string@providerType-completer
  --serviceType: string
  --locationType: string@locationType-completer
  --radius: int # default: 5000
  --limit: int
  --hideClosedShops: string@bool-completer
  --countryCode: string
]: nothing -> record<url: string, locations: table<url: string, location: record, name: string, place: record>> {
  let auth = (build-auth $token ($auth_scheme | default "dhl-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "providerType" $providerType "scalar") (serialize-qp "serviceType" $serviceType "scalar") (serialize-qp "locationType" $locationType "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "hideClosedShops" $hideClosedShops "scalar") (serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/find-by-geo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find Service Point by location ID
#
# GET /find-by-location-id/{id}
# operationId: findByLocationId
export def "find-by-location-id findByLocationId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string, location: record, name: string, place: record> {
  let auth = (build-auth $token ($auth_scheme | default "dhl-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/find-by-location-id/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find Service Points by keyword ID
#
# GET /find-by-keyword-id/{keywordId}
# operationId: findByKeywordId
export def "find-by-keyword-id findByKeywordId" [
  keywordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --countryCode: string
  --postalCode: string
]: nothing -> record<url: string, locations: table<url: string, location: record, name: string, place: record>> {
  let auth = (build-auth $token ($auth_scheme | default "dhl-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "postalCode" $postalCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/find-by-keyword-id/($keywordId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
