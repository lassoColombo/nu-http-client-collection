# Auto-generated client for OpenAQ v2.0.0
# Source: https://api.apis.guru/v2/specs/openaq.local/2.0.0/openapi.json
# Auth: --token flag or $env.OPENAQ_TOKEN

const BASE_URL = "http://openaq.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENAQ_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://openaq.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def entity-completer [] { ["community" "government" "research"] }
def sensor-type-completer [] { ["low-cost sensor" "reference grade"] }
def spatial-completer [] { ["country" "location" "project" "total"] }
def temporal-completer [] { ["day" "dow" "hod" "hour" "month" "moy" "year"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "favicon-ico get-favico" } } | get name | first)
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

# Favico
#
# GET /favicon.ico
# operationId: favico_favicon_ico_get
export def "favicon-ico get-favico" [
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
  let full_url = (build-url $base "/favicon.ico")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Pong
#
# GET /ping
# operationId: pong_ping_get
export def "ping get-pong" [
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
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Provides a simple listing of cities within the platform
#
# GET /v1/cities
# operationId: cities_getv1_v1_cities_get
export def "cities get-getv1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --order-by: string # Order by a field (default: city)
  --entity: string
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<city: string, count: int, country: string, firstUpdated: string, lastUpdated: string, locations: int, parameters: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "entity" $entity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/cities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Countries Getv1
#
# GET /v1/countries
# operationId: countries_getv1_v1_countries_get
export def "countries get-getv1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 200
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --order-by: string # default: country
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Countries Get
#
# GET /v1/countries/{country_id}
# operationId: countries_get_v1_countries__country_id__get
export def "countries get-get-by-country_id" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 200
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --order-by: string # default: country
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "country" $country "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id)} | format pattern "/v1/countries/{country_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Latest V1 Get
#
# GET /v1/latest
# operationId: latest_v1_get_v1_latest_get
export def "latest get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string # Source entity type.
  --sensor-type: string # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "modelName" $model_name "multi") (serialize-qp "manufacturerName" $manufacturer_name "multi") (serialize-qp "dumpRaw" $dump_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Latest V1 Get
#
# GET /v1/latest/{location_id}
# operationId: latest_v1_get_v1_latest__location_id__get
export def "latest get-get-by-location_id" [
  location_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location: list
  --order-by: string # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string # Source entity type.
  --sensor-type: string # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "modelName" $model_name "multi") (serialize-qp "manufacturerName" $manufacturer_name "multi") (serialize-qp "dumpRaw" $dump_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v1/latest/{location_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Locationsv1 Get
#
# GET /v1/locations
# operationId: locationsv1_get_v1_locations_get
export def "locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string # Source entity type.
  --sensor-type: string # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "modelName" $model_name "multi") (serialize-qp "manufacturerName" $manufacturer_name "multi") (serialize-qp "dumpRaw" $dump_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Locationsv1 Get
#
# GET /v1/locations/{location_id}
# operationId: locationsv1_get_v1_locations__location_id__get
export def "locations get-locationsv1-get" [
  location_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location: list
  --order-by: string # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string # Source entity type.
  --sensor-type: string # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "modelName" $model_name "multi") (serialize-qp "manufacturerName" $manufacturer_name "multi") (serialize-qp "dumpRaw" $dump_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v1/locations/{location_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Measurements Get V1
#
# GET /v1/measurements
# operationId: measurements_get_v1_v1_measurements_get
export def "measurements get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --date-from: string # default: 2000-01-01T00:00:00+00:00
  --date-to: string # default: 2021-08-23T09:48:00+00:00
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # default: desc
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string # default: datetime
  --is-mobile: oneof<nothing, bool>
  --is-analysis: oneof<nothing, bool>
  --project: int
  --entity: string@entity-completer
  --sensor-type: string@sensor-type-completer
  --value-from: float
  --value-to: float
  --include-fields: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "value_from" $value_from "scalar") (serialize-qp "value_to" $value_to "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/measurements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Parameters Getv1
#
# GET /v1/parameters
# operationId: parameters_getv1_v1_parameters_get
export def "parameters get-getv1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --source-name: list<string>
  --source-id: list<int>
  --source-slug: list<string>
  --order-by: string # default: id
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<description: string, displayName: string, id: int, isCore: bool, maxColorValue: float, name: string, preferredUnit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "sourceId" $source_id "multi") (serialize-qp "sourceSlug" $source_slug "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/parameters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Sources V1 Get
#
# GET /v1/sources
# operationId: sources_v1_get_v1_sources_get
export def "sources get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --name: string
  --order-by: string # default: name
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Averages V2 Get
#
# GET /v2/averages
# operationId: averages_v2_get_v2_averages_get
export def "averages get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # default: 2000-01-01T00:00:00+00:00
  --date-to: string # default: 2021-08-23T09:48:00+00:00
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --project-id: int
  --project: list
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: desc)
  --spatial: string@spatial-completer
  --temporal: string@temporal-completer
  --location: list<string>
  --group: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "project" $project "multi") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "spatial" $spatial "scalar") (serialize-qp "temporal" $temporal "scalar") (serialize-qp "location" $location "multi") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/averages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Provides a simple listing of cities within the platform
#
# GET /v2/cities
# operationId: cities_get_v2_cities_get
export def "cities get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --order-by: string # Order by a field (default: city)
  --entity: string
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<city: string, count: int, country: string, firstUpdated: string, lastUpdated: string, locations: int, parameters: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "entity" $entity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Countries Get
#
# GET /v2/countries
# operationId: countries_get_v2_countries_get
export def "countries get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 200
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --order-by: string # default: country
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Countries Get
#
# GET /v2/countries/{country_id}
# operationId: countries_get_v2_countries__country_id__get
export def "countries get-get-by-country_id-1" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 200
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --order-by: string # default: country
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<cities: int, code: string, count: int, firstUpdated: string, lastUpdated: string, locations: int, name: string, parameters: list, sources: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "country" $country "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id)} | format pattern "/v2/countries/{country_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Latest Get
#
# GET /v2/latest
# operationId: latest_get_v2_latest_get
export def "latest get-get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string # Source entity type.
  --sensor-type: string # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "modelName" $model_name "multi") (serialize-qp "manufacturerName" $manufacturer_name "multi") (serialize-qp "dumpRaw" $dump_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Latest Get
#
# GET /v2/latest/{location_id}
# operationId: latest_get_v2_latest__location_id__get
export def "latest get-get-by-location_id-1" [
  location_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location: list
  --order-by: string # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string # Source entity type.
  --sensor-type: string # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "modelName" $model_name "multi") (serialize-qp "manufacturerName" $manufacturer_name "multi") (serialize-qp "dumpRaw" $dump_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v2/latest/{location_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Locations Get
#
# GET /v2/locations
# operationId: locations_get_v2_locations_get
export def "locations list-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string # Source entity type.
  --sensor-type: string # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "modelName" $model_name "multi") (serialize-qp "manufacturerName" $manufacturer_name "multi") (serialize-qp "dumpRaw" $dump_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Mobilegentilejson
#
# GET /v2/locations/tiles/mobile-generalized/tiles.json
# operationId: mobilegentilejson_v2_locations_tiles_mobile_generalized_tiles_json_get
export def "locations-tiles-mobile-generalized-tiles-json get-mobilegentilejson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations/tiles/mobile-generalized/tiles.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Mobilegentile
#
# GET /v2/locations/tiles/mobile-generalized/{z}/{x}/{y}.pbf
# operationId: get_mobilegentile_v2_locations_tiles_mobile_generalized__z___x___y__pbf_get
export def "locations-tiles-mobile-generalized get-mobilegentile-pbf-get" [
  z: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter: string
  --location: list<int> # limit data to location id
  --last-updated-from: string
  --last-updated-to: string
  --is-mobile: oneof<nothing, bool>
  --project: int
  --is-analysis: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameter" $parameter "scalar") (serialize-qp "location" $location "multi") (serialize-qp "lastUpdatedFrom" $last_updated_from "scalar") (serialize-qp "lastUpdatedTo" $last_updated_to "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({z: (encode-path-segment $z), x: (encode-path-segment $x), y: (encode-path-segment $y)} | format pattern "/v2/locations/tiles/mobile-generalized/{z}/{x}/{y}.pbf") $qp)
  let accept_val = "application/x-protobuf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Mobiletilejson
#
# GET /v2/locations/tiles/mobile/tiles.json
# operationId: mobiletilejson_v2_locations_tiles_mobile_tiles_json_get
export def "locations-tiles-mobile-tiles-json get-mobiletilejson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations/tiles/mobile/tiles.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Mobiletile
#
# GET /v2/locations/tiles/mobile/{z}/{x}/{y}.pbf
# operationId: get_mobiletile_v2_locations_tiles_mobile__z___x___y__pbf_get
export def "locations-tiles-mobile get-mobiletile-pbf-get" [
  z: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string
  --date-to: string
  --parameter: string
  --location: list<int> # limit data to location id
  --last-updated-from: string
  --last-updated-to: string
  --is-mobile: oneof<nothing, bool>
  --project: int
  --is-analysis: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "parameter" $parameter "scalar") (serialize-qp "location" $location "multi") (serialize-qp "lastUpdatedFrom" $last_updated_from "scalar") (serialize-qp "lastUpdatedTo" $last_updated_to "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({z: (encode-path-segment $z), x: (encode-path-segment $x), y: (encode-path-segment $y)} | format pattern "/v2/locations/tiles/mobile/{z}/{x}/{y}.pbf") $qp)
  let accept_val = "application/x-protobuf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Tilejson
#
# GET /v2/locations/tiles/tiles.json
# operationId: tilejson_v2_locations_tiles_tiles_json_get
export def "locations-tiles-tiles-json get-tilejson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attribution: string, bounds: list<float>, data: list<string>, description: string, grids: list<string>, legend: string, maxzoom: int, minzoom: int, name: string, scheme: string, template: string, tilejson: string, tiles: list<string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations/tiles/tiles.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Demo
#
# GET /v2/locations/tiles/viewer
# operationId: demo_v2_locations_tiles_viewer_get
export def "locations-tiles-viewer get-demo" [
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
  let full_url = (build-url $base "/v2/locations/tiles/viewer")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Tile
#
# GET /v2/locations/tiles/{z}/{x}/{y}.pbf
# operationId: get_tile_v2_locations_tiles__z___x___y__pbf_get
export def "locations-tiles get-pbf-get" [
  z: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter: string
  --location: list<int> # limit data to location id
  --last-updated-from: string
  --last-updated-to: string
  --is-mobile: oneof<nothing, bool>
  --project: int
  --is-analysis: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameter" $parameter "scalar") (serialize-qp "location" $location "multi") (serialize-qp "lastUpdatedFrom" $last_updated_from "scalar") (serialize-qp "lastUpdatedTo" $last_updated_to "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({z: (encode-path-segment $z), x: (encode-path-segment $x), y: (encode-path-segment $y)} | format pattern "/v2/locations/tiles/{z}/{x}/{y}.pbf") $qp)
  let accept_val = "application/x-protobuf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Locations Get
#
# GET /v2/locations/{location_id}
# operationId: locations_get_v2_locations__location_id__get
export def "locations get-get" [
  location_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Sort Direction (default: desc)
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location: list
  --order-by: string # Order by a field (default: lastUpdated)
  --is-mobile: oneof<nothing, bool> # Location is mobile
  --is-analysis: oneof<nothing, bool> # Data is the product of a previous analysis/aggregation and not raw measurements
  --source-name: list<string> # Name of the data source
  --entity: string # Source entity type.
  --sensor-type: string # Type of Sensor
  --model-name: list<string> # Model Name of Sensor
  --manufacturer-name: list<string> # Manufacturer of Sensor
  --dump-raw: oneof<nothing, bool> # default: false
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "modelName" $model_name "multi") (serialize-qp "manufacturerName" $manufacturer_name "multi") (serialize-qp "dumpRaw" $dump_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/v2/locations/{location_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Mfr Get
#
# GET /v2/manufacturers
# operationId: mfr_get_v2_manufacturers_get
export def "manufacturers get-mfr-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/manufacturers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Measurements Get
#
# GET /v2/measurements
# operationId: measurements_get_v2_measurements_get
export def "measurements get-get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --date-from: string # default: 2000-01-01T00:00:00+00:00
  --date-to: string # default: 2021-08-23T09:48:00+00:00
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # default: desc
  --has-geo: oneof<nothing, bool>
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --coordinates: string
  --radius: int # default: 1000
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --city: list<string> # Limit results by a certain city or cities. (ex. ?city=Chicago or ?city=Chicago&city=Boston)
  --location-id: int
  --location: list
  --order-by: string # default: datetime
  --is-mobile: oneof<nothing, bool>
  --is-analysis: oneof<nothing, bool>
  --project: int
  --entity: string@entity-completer
  --sensor-type: string@sensor-type-completer
  --value-from: float
  --value-to: float
  --include-fields: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "city" $city "multi") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "location" $location "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "value_from" $value_from "scalar") (serialize-qp "value_to" $value_to "scalar") (serialize-qp "include_fields" $include_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/measurements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Model Get
#
# GET /v2/models
# operationId: model_get_v2_models_get
export def "models get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Parameters Get
#
# GET /v2/parameters
# operationId: parameters_get_v2_parameters_get
export def "parameters get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --source-name: list<string>
  --source-id: list<int>
  --source-slug: list<string>
  --order-by: string # default: id
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<description: string, displayName: string, id: int, isCore: bool, maxColorValue: float, name: string, preferredUnit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "sourceId" $source_id "multi") (serialize-qp "sourceSlug" $source_slug "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/parameters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Projects Get
#
# GET /v2/projects
# operationId: projects_get_v2_projects_get
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --project-id: int
  --project: list
  --order-by: string # default: lastUpdated
  --is-mobile: oneof<nothing, bool>
  --is-analysis: oneof<nothing, bool>
  --entity: string
  --sensor-type: string
  --source-name: list<string>
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<bbox: list, countries: list, entity: string, firstUpdated: string, id: int, isAnalysis: bool, isMobile: bool, lastUpdated: string, locationIds: list, locations: int, measurements: int, name: string, parameters: list, sensorType: string, sources: list, subtitle: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "project" $project "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "sourceName" $source_name "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Projects Get
#
# GET /v2/projects/{project_id}
# operationId: projects_get_v2_projects__project_id__get
export def "projects get-get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # Limit results by a certain country using two letter country code. (ex. /US)
  --country: list<string> # Limit results by a certain country using two letter country code. (ex. ?country=US or ?country=US&country=MX)
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --parameter-id: int
  --parameter: list
  --unit: list<string>
  --project: list
  --order-by: string # default: lastUpdated
  --is-mobile: oneof<nothing, bool>
  --is-analysis: oneof<nothing, bool>
  --entity: string
  --sensor-type: string
  --source-name: list<string>
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: table<bbox: list, countries: list, entity: string, firstUpdated: string, id: int, isAnalysis: bool, isMobile: bool, lastUpdated: string, locationIds: list, locations: int, measurements: int, name: string, parameters: list, sensorType: string, sources: list, subtitle: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country_id" $country_id "scalar") (serialize-qp "country" $country "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "parameter_id" $parameter_id "scalar") (serialize-qp "parameter" $parameter "multi") (serialize-qp "unit" $unit "multi") (serialize-qp "project" $project "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "isMobile" $is_mobile "scalar") (serialize-qp "isAnalysis" $is_analysis "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "sensorType" $sensor_type "scalar") (serialize-qp "sourceName" $source_name "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Sources Get
#
# GET /v2/sources
# operationId: sources_get_v2_sources_get
export def "sources get-get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned. (default: 100)
  --page: int # Paginate through results. (default: 1)
  --offset: int # default: 0
  --qp-sort: string # Define sort order. (default: asc)
  --source-name: list<string>
  --source-id: list<int>
  --source-slug: list<string>
  --order-by: string # default: sourceName
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sourceName" $source_name "multi") (serialize-qp "sourceId" $source_id "multi") (serialize-qp "sourceSlug" $source_slug "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Readme Get
#
# GET /v2/sources/readme/{slug}
# operationId: readme_get_v2_sources_readme__slug__get
export def "sources-readme get-get" [
  slug: string
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
  let full_url = (build-url $base ({slug: (encode-path-segment $slug)} | format pattern "/v2/sources/readme/{slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Summary Get
#
# GET /v2/summary
# operationId: summary_get_v2_summary_get
export def "summary get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<found: int, license: string, limit: int, name: string, page: int, website: string>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
