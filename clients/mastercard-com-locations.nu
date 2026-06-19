# Auto-generated client for Locations API v1.0.0
# Source: https://api.apis.guru/v2/specs/mastercard.com/Locations/1.0.0/swagger.json
# Auth: --token flag or $env.LOCATIONS_API_TOKEN

const BASE_URL = "https://api.mastercard.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LOCATIONS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.mastercard.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "atms-atm get" } } | get name | first)
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

# Returns detailed information about an ATM location. This information can be used to display ATMs on a map, provide driving directions, or show special ATM features.
#
# GET /atms/v1/atm
export def "atms-atm get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-offset: int # Zero-based offset where the response will start. The actual start position is this value +1. An offset of 10 starts at item 11. Combined with the PageLength option this allows pagination to be supported through the service requests. (e.g. 0)
  --page-length: int # Maximum number of items to retrieve within the current "page" of results. (e.g. 5)
  --address-line1: string # Line 1 of the street address for the merchant location. Usually includes the street number and name. This parameter is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter and either City parameter or PostalCode parameter. (e.g. 114 Fifth Avenue)
  --address-line2: string # Line 2 of the street address usually an apartment number or suite number. This parameter is used rarely and is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter and either City parameter or PostalCode parameter. (e.g. Apartment 1)
  --city: string # The name of the city for a merchant location. This parameter is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter. (e.g. New York City)
  --country-subdivision: string # The state or province for a merchant location (only supported for US and Canada locations). This parameter is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter. (e.g. NY)
  --postal-code: string # The zip code or postal code for a merchant location. This parameter is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter. (e.g. 11101)
  --country: string # Any three digit country code for an ATM location. Valid values are Three digit alpha country code as defined in ISO 3166-1. This parameter is ignored if latitude and longitude are provided. This parameter is required if any other address information is provided including AddressLine1 AddressLine2 City PostalCode or CountrySubdivision. (e.g. USA)
  --latitude: float # The latitude of a merchant location. If latitude is provided longitude must also be provided. (format: double, e.g. 38.76006576913497)
  --longitude: float # The longitude of a merchant location. If longitude is provided latitude must also be provided. (format: double, e.g. -90.74615107952418)
  --distance-unit: string # Indicates the unit for the radius as well as the units of the distance of each location from the basepoint in the response. (e.g. MILE)
  --radius: int # This is the radius from the search point in the distance unit you set. For example if you want to search for locations within 50 miles of a certain point you would set DistanceUnit=mile and Radius=50. This parameter is ignored in non-geocoded countries. (e.g. 25)
  --support-emv: int # This indicates whether the ATM should have the ability to read chip cards or not. (e.g. 1)
  --international-maestro-accepted: int # This field will provide ATM Terminals which can still process Maestro transactions but are not yet EMV chip reader enabled. Information available only for USA and Argentina till October 2014. (e.g. 1)
]: nothing -> record<Atms: record<Atm: list<record>, PageOffset: string, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageOffset" $page_offset "scalar") (serialize-qp "PageLength" $page_length "scalar") (serialize-qp "AddressLine1" $address_line1 "scalar") (serialize-qp "AddressLine2" $address_line2 "scalar") (serialize-qp "City" $city "scalar") (serialize-qp "CountrySubdivision" $country_subdivision "scalar") (serialize-qp "PostalCode" $postal_code "scalar") (serialize-qp "Country" $country "scalar") (serialize-qp "Latitude" $latitude "scalar") (serialize-qp "Longitude" $longitude "scalar") (serialize-qp "DistanceUnit" $distance_unit "scalar") (serialize-qp "Radius" $radius "scalar") (serialize-qp "SupportEMV" $support_emv "scalar") (serialize-qp "InternationalMaestroAccepted" $international_maestro_accepted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/atms/v1/atm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageOffset": $page_offset, "PageLength": $page_length, "AddressLine1": $address_line1, "AddressLine2": $address_line2, "City": $city, "CountrySubdivision": $country_subdivision, "PostalCode": $postal_code, "Country": $country, "Latitude": $latitude, "Longitude": $longitude, "DistanceUnit": $distance_unit, "Radius": $radius, "SupportEMV": $support_emv, "InternationalMaestroAccepted": $international_maestro_accepted} | compact), body: null}
}

# Returns countries with valid ATM locations.
#
# GET /atms/v1/country
export def "atms-country get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Countries: record<Country: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/atms/v1/country")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns country subdivisions that have ATM locations. A country subdivision is a segment within a country (ex state or province). Country subdivisions are only available for the US and Canada.
#
# GET /atms/v1/countrysubdivision
export def "atms-countrysubdivision get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Any three digit country code as defined in ISO 3166-1. "USA" or "CAN" (e.g. USA)
]: nothing -> record<CountrySubdivisions: record<CountrySubdivision: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/atms/v1/countrysubdivision" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Country": $country} | compact), body: null}
}

# Returns a list of all merchant categories for contactless and cash back merchants (example: Airline, Retail, etc.).
#
# GET /merchants/v1/category
export def "merchants-category get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Categories: record<Category: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/merchants/v1/category")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns countries that have Merchants offering the following services: accept contactless-enabled cards and devices, allow customers to add money to an eligible MasterCard or Maestro prepaid card, issue MasterCard Prepaid Travel cards, offer cash at checkout when paying with a Debit MasterCard or Maestro Card.
#
# GET /merchants/v1/country
export def "merchants-country get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: string # This is the type of merchant location. Options "acceptance.paypass" "topup.repower" "products.prepaidtravelcard" and "offers.easysavings" (e.g. acceptance.paypass)
]: nothing -> record<Countries: record<Country: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/merchants/v1/country" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"details": $details} | compact), body: null}
}

# Returns country subdivisions that have Merchants offering the following services: accept contactless-enabled cards and devices, allow customers to add money to an eligible MasterCard or Maestro prepaid card, issue MasterCard Prepaid Travel cards, offer cash at checkout when paying with a Debit MasterCard or Maestro Card. A country subdivision is a segment within a country (ex state or province). Please note country subdivisions are only available for the US and Canada.
#
# GET /merchants/v1/countrysubdivision
export def "merchants-countrysubdivision get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: string # This is the type of merchant location. Options "acceptance.paypass" "topup.repower" "products.prepaidtravelcard" and "offers.easysavings" (e.g. topup.repower)
  --country: string # Any three digit country code as defined in ISO 3166-1. For example "USA or "CAN" (e.g. USA)
]: nothing -> record<CountrySubdivisions: record<CountrySubdivision: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/merchants/v1/countrysubdivision" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"details": $details, "country": $country} | compact), body: null}
}

# Returns merchant location information for merchants offering the following services: accept contactless-enabled cards and devices, allow customers to add money to an eligible MasterCard or Maestro prepaid card, issue MasterCard Prepaid Travel cards, participate in the MasterCard Easy Savings program, and offer cash at checkout when paying with a Debit MasterCard or Maestro Card.
#
# GET /merchants/v1/merchant
export def "merchants-merchant get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: string # Type of merchant location. Options are "acceptance.paypass" "topup.repower" "products.prepaidtravelcard" "offers.easysavings" and "features.cashback". Cash Back is currently only available in the US. (e.g. acceptance.paypass)
  --page-offset: int # Zero-based offset where the response will start. The actual start position is this value +1. An offset of 10 starts at item 11. Combined with the PageLength option this allows pagination to be supported through the service requests. (e.g. 0)
  --page-length: int # Maximum number of items to retrieve within the current "page" of results. (e.g. 5)
  --category: string # Category of the merchant location. See the Categories (Merchant) resource for a list of valid categories. This parameter is only valid for merchant queries with Details = "acceptance.paypass" or "features.cashback". (e.g. features.cashback)
  --address-line1: string # Line 1 of the street address for the merchant location. Usually includes the street number and name. This parameter is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter and either City parameter or PostalCode parameter. (e.g. 42 Elm Street)
  --address-line2: string # Line 2 of the street address usually an apartment number or suite number. This parameter is used rarely and is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter and either City parameter or PostalCode parameter. (e.g. Suite 101)
  --city: string # Name of the city for a merchant location. This parameter is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter. (e.g. New York)
  --country-subdivision: string # State or province for a merchant location (only supported for US and Canada locations). This parameter is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter. (e.g. NY)
  --postal-code: string # Zip code or postal code for a merchant location. This parameter is ignored if latitude and longitude are provided. If you provide this parameter you must also provide the Country parameter. (e.g. 11001)
  --country: string # Any three digit country code for an ATM location. Valid values are Three digit alpha country code as defined in ISO 3166-1. This parameter is ignored if latitude and longitude are provided. This parameter is required if any other address information is provided including AddressLine1 AddressLine2 City PostalCode or CountrySubdivision. By default we supply ATM location data for United States ATMs for up to twenty-five records per request. (e.g. USA)
  --latitude: float # Latitude of a merchant location. If latitude is provided longitude must also be provided. (format: double, e.g. 38.53463)
  --longitude: float # Longitude of a merchant location. If longitude is provided latitude must also be provided. (format: double, e.g. -90.286781)
  --distance-unit: string # Indicates the unit for the radius as well as the units of the distance of each location from the basepoint in the response. (e.g. MILE)
  --radius: int # This is the radius from the search point in the distance unit you set. For example if you want to search for locations within 50 miles of a certain point you would set DistanceUnit=mile and Radius=50. This parameter is ignored in non-geocoded countries. (e.g. 25)
  --offer-merchant-id: string # Unique identifier that represents the merhcant sponsor of an offer. Any valid merchant ID. (e.g. 34760)
]: nothing -> record<Merchants: record<Merchant: list<record>, PageOffset: string, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Details" $details "scalar") (serialize-qp "PageOffset" $page_offset "scalar") (serialize-qp "PageLength" $page_length "scalar") (serialize-qp "Category" $category "scalar") (serialize-qp "AddressLine1" $address_line1 "scalar") (serialize-qp "AddressLine2" $address_line2 "scalar") (serialize-qp "City" $city "scalar") (serialize-qp "CountrySubdivision" $country_subdivision "scalar") (serialize-qp "PostalCode" $postal_code "scalar") (serialize-qp "Country" $country "scalar") (serialize-qp "Latitude" $latitude "scalar") (serialize-qp "Longitude" $longitude "scalar") (serialize-qp "DistanceUnit" $distance_unit "scalar") (serialize-qp "Radius" $radius "scalar") (serialize-qp "OfferMerchantID" $offer_merchant_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/merchants/v1/merchant" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Details": $details, "PageOffset": $page_offset, "PageLength": $page_length, "Category": $category, "AddressLine1": $address_line1, "AddressLine2": $address_line2, "City": $city, "CountrySubdivision": $country_subdivision, "PostalCode": $postal_code, "Country": $country, "Latitude": $latitude, "Longitude": $longitude, "DistanceUnit": $distance_unit, "Radius": $radius, "OfferMerchantID": $offer_merchant_id} | compact), body: null}
}
