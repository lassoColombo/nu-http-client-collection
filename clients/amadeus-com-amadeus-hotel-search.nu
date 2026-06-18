# Auto-generated client for Hotel Search API v3.0.8
# Source: https://api.apis.guru/v2/specs/amadeus.com/amadeus-hotel-search/3.0.8/swagger.json
# Auth: --token flag or $env.HOTEL_SEARCH_API_TOKEN

const BASE_URL = "https://test.api.amadeus.com/v3"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HOTEL_SEARCH_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://test.api.amadeus.com/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def payment-policy-completer [] { ["DEPOSIT" "GUARANTEE" "NONE"] }
def board-type-completer [] { ["ALL_INCLUSIVE" "BREAKFAST" "FULL_BOARD" "HALF_BOARD" "ROOM_ONLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "shopping-hotel-offers get-multi" } } | get name | first)
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

# getMultiHotelOffers
#
# GET /shopping/hotel-offers
# operationId: getMultiHotelOffers
export def "shopping-hotel-offers get-multi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hotel-ids: list<string> # Amadeus property codes on 8 chars. Mandatory parameter for a search by predefined list of hotels. (e.g. [MCLONGHM])
  --adults: int # Number of adult guests (1-9) per room. (format: int32, default: 1, e.g. 1)
  --check-in-date: string # Check-in date of the stay (hotel local date). Format YYYY-MM-DD. The lowest accepted value is the present date (no dates in the past). If not present, the default value will be today's date in the GMT time zone. (format: date, e.g. 2023-11-22)
  --check-out-date: string # Check-out date of the stay (hotel local date). Format YYYY-MM-DD. The lowest accepted value is checkInDate+1. If not present, it will default to checkInDate +1. (format: date)
  --country-of-residence: string # Code of the country of residence of the traveler expressed using ISO 3166-1 format.
  --room-quantity: int # Number of rooms requested (1-9). (format: int32, default: 1)
  --price-range: string # Filter hotel offers by price per night interval (ex: 200-300 or -300 or 100). It is mandatory to include a currency when this field is set.
  --currency: string # Use this parameter to request a specific currency. ISO currency code (http://www.iso.org/iso/home/standards/currency_codes.htm). If a hotel does not support the requested currency, the prices for the hotel will be returned in the local currency of the hotel.
  --payment-policy: string@payment-policy-completer # Filter the response based on a specific payment type. NONE means all types (default). (default: NONE)
  --board-type: string@board-type-completer # Filter response based on available meals: * ROOM_ONLY = Room Only * BREAKFAST = Breakfast * HALF_BOARD = Diner & Breakfast (only for Aggregators) * FULL_BOARD = Full Board (only for Aggregators) * ALL_INCLUSIVE = All Inclusive (only for Aggregators)
  --include-closed: oneof<nothing, bool> # Show all properties (include sold out) or available only. For sold out properties, please check availability on other dates.
  --best-rate-only: oneof<nothing, bool> # Used to return only the cheapest offer per hotel or all available offers. (default: true)
  --lang: string # Requested language of descriptive texts. Examples: FR , fr , fr-FR. If a language is not available the text will be returned in english. ISO language code (https://www.iso.org/iso-639-language-codes.html).
]: nothing -> record<data: record<available: bool, hotel: record<brandCode: string, chainCode: string, cityCode: string, dupeId: string, hotelId: string, name: string>, offers: list<record>, self: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelIds" $hotel_ids "csv") (serialize-qp "adults" $adults "scalar") (serialize-qp "checkInDate" $check_in_date "scalar") (serialize-qp "checkOutDate" $check_out_date "scalar") (serialize-qp "countryOfResidence" $country_of_residence "scalar") (serialize-qp "roomQuantity" $room_quantity "scalar") (serialize-qp "priceRange" $price_range "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "paymentPolicy" $payment_policy "scalar") (serialize-qp "boardType" $board_type "scalar") (serialize-qp "includeClosed" $include_closed "scalar") (serialize-qp "bestRateOnly" $best_rate_only "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shopping/hotel-offers" $qp)
  let accept_val = "application/vnd.amadeus+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getOfferPricing
#
# GET /shopping/hotel-offers/{offerId}
# operationId: getOfferPricing
export def "shopping-hotel-offers get-pricing" [
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Requested language of descriptive texts. Examples: FR , fr , fr-FR. If a language is not available the text will be returned in english. ISO language code (https://www.iso.org/iso-639-language-codes.html).
]: nothing -> record<data: record<available: bool, hotel: record<brandCode: string, chainCode: string, cityCode: string, dupeId: string, hotelId: string, name: string>, offers: list<record>, self: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({offer_id: (encode-path-segment $offer_id)} | format pattern "/shopping/hotel-offers/{offer_id}") $qp)
  let accept_val = "application/vnd.amadeus+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
