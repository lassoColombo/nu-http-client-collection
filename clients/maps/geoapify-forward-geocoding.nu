# Auto-generated client for Geocoding API v1.0.0
# Source: https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/geocoding/forward_geocoding.yaml
# Auth: --token flag or $env.GEOCODING_API_TOKEN

const BASE_URL = "https://api.geoapify.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GEOCODING_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.geoapify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["amenity" "city" "country" "postcode" "state" "street"] }
def format-completer [] { ["geojson" "json" "xml"] }
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "geocode-search geocodeSearch" } } | get name | first)
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

# Search for an address using a free-form string or structured address components
#
# GET /geocode/search
# operationId: geocodeSearch
export def "geocode-search geocodeSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --apiKey: string # Your Geoapify API key to authenticate the request. You can sign up and obtain an API key for free at [https://myprojects.geoapify.com/](https://myprojects.geoapify.com/). The Free plan includes up to 3,000 requests per day. (e.g. YOUR_API_KEY)
  --text: string # Free-form address to search (e.g. Hannoverstr. 8, 80997 Munich)
  --name: string # Amenity or place name.
  --housenumber: string # House number.
  --street: string # Street name.
  --postcode: string # Postcode or ZIP code.
  --city: string # City name.
  --state: string # State name.
  --country: string # Country name.
  --type: string@type-completer # Defines the location type to be searched. Available types include:  - `country`: Search for countries. - `state`: Search for states or regions. - `city`: Search for cities or towns. - `postcode`: Search for postal codes. - `street`: Search for specific streets. - `amenity`: Search for points of interest (e.g., schools, parks, etc.). - `locality`: Search for administrative areas, which can include postcodes, districts, cities, counties, and states.
  --lang: string # Result language in [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format (e.g., 'en' for English). (e.g. en)
  --limit: int # Max number of results (default: 5).
  --filter: string # Allows you to refine your search results based on specific geographic criteria. You can use the following location filters to make the results more relevant: - **By circle**:   Format: `circle:lon,lat,radiusMeters`   Description: Search for places within a defined circle based on longitude, latitude, and radius in meters.   Example: `filter=circle:-87.770231,41.878968,5000`  - **By rectangle**:   Format: `rect:lon1,lat1,lon2,lat2`   Description: Search for places within a rectangular area defined by two longitude and latitude points (representing the southwest and northeast corners).   Example: `filter=rect:-89.097540,39.668983,-88.399274,40.383412`  - **By country**:   Format: Comma-separated ISO 3166-1 Alpha-2 country codes (in lowercase). Use `'auto'` to detect the country by IP address. Use `'none'` to skip country filtering (default value).   Description: Search for places within specified countries.   Example: `filter=countrycode:de,es,fr`  - **By place**:   Format: `place:placeId`   Description: Search within a specific boundary, such as a city, district, or postcode, using a `place_id` returned by the Geocoding, Reverse Geocoding, Places, or Boundaries APIs.   Example: `filter=place:51f07665660fc4024059dc0a96dfac6c...`
  --bias: string # Allows you to prioritize search results based on proximity to a specific point, radius, bounding box, or country without restricting the search to that area. This can be useful for displaying nearby results first while still allowing for global search.  - **By circle**:     Format: `circle:lon,lat,radiusMeters`     Description: Prioritize search results from within a defined circle (based on longitude, latitude, and radius in meters), and then search worldwide.     Example: `bias=circle:-87.770231,41.878968,5000`  - **By rectangle**:     Format: `rect:lon1,lat1,lon2,lat2`     Description: Prioritize results from within a defined rectangular area (using two longitude and latitude points representing the southwest and northeast corners), and then search worldwide.     Example: `bias=rect:-89.097540,39.668983,-88.399274,40.383412`  - **By country**:     Format: Comma-separated ISO 3166-1 Alpha-2 country codes (in lowercase). Use `'auto'` to detect the country by IP address. Use `'none'` to skip country bias (default value).     Description: Prioritize results from the specified countries first, and then search globally.     Example: `bias=countrycode:de,es,fr`  - **By location**:     Format: `proximity:lon,lat`     Description: Prioritize results based on distance from a specific longitude and latitude.     Example: `bias=proximity:41.2257145,52.971411`
  --format: string@format-completer # Response format (default is `geojson`). Other options: `json`, `xml`. (e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $apiKey "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "housenumber" $housenumber "scalar") (serialize-qp "street" $street "scalar") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "bias" $bias "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocode/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
