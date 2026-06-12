# Auto-generated client for Karrio API v2026.1.31
# Source: https://raw.githubusercontent.com/karrioapi/karrio/main/schemas/openapi.yml
# Auth: --token flag or $env.KARRIO_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KARRIO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def resource-type-completer [] { ["document" "manifest" "order" "shipment" "template"] }
def format-completer [] { ["" "gif" "pdf" "png" "zpl"] }
def country-code-completer [] { ["AC" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AN" "AO" "AR" "AS" "AT" "AU" "AW" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BR" "BS" "BT" "BW" "BY" "BZ" "CA" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GT" "GU" "GW" "GY" "HK" "HN" "HR" "HT" "HU" "IC" "ID" "IE" "IL" "IM" "IN" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KV" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PR" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TG" "TH" "TJ" "TL" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WS" "XB" "XC" "XE" "XM" "XN" "XS" "XY" "YE" "YT" "ZA" "ZM" "ZW"] }
def resource-type-completer-1 [] { ["billing" "order" "shipment" "trackers"] }
def object-type-completer [] { ["shipment" "tracker"] }
def carrier-name-completer [] { ["aramex" "asendia" "asendia_us" "australiapost" "boxknight" "bpost" "canadapost" "canpar" "chronopost" "colissimo" "dhl_express" "dhl_parcel_de" "dhl_poland" "dhl_universal" "dicom" "dpd" "dpd_meta" "dtdc" "easypost" "easyship" "eshipper" "fedex" "freightcom" "generic" "geodis" "gls" "hay_post" "hermes" "landmark" "laposte" "locate2u" "mydhl" "nationex" "parcelone" "postat" "purolator" "roadie" "royalmail" "sapient" "seko" "sendle" "shipengine" "spring" "teleship" "tge" "tnt" "ups" "usps" "usps_international" "veho" "zoom2u"] }
def related-object-completer [] { ["order" "other" "shipment"] }
def weight-unit-completer [] { ["G" "KG" "LB" "OZ"] }
def dimension-unit-completer [] { ["" "CM" "IN"] }
def pickup-type-completer [] { ["daily" "one_time" "recurring"] }
def value-currency-completer [] { ["" "AED" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BZD" "CAD" "CDF" "CHF" "CLP" "CNY" "COP" "CRC" "CUC" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "GBP" "GEL" "GHS" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "IRR" "ISK" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LKR" "LRD" "LSL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRO" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SRD" "SSP" "STD" "SYP" "SZL" "THB" "TJS" "TND" "TOP" "TRY" "TTD" "TWD" "TZS" "UAH" "USD" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XCD" "XOF" "XPF" "YER" "ZAR"] }
def origin-country-completer [] { ["" "AC" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AN" "AO" "AR" "AS" "AT" "AU" "AW" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BR" "BS" "BT" "BW" "BY" "BZ" "CA" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GT" "GU" "GW" "GY" "HK" "HN" "HR" "HT" "HU" "IC" "ID" "IE" "IL" "IM" "IN" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KV" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PR" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TG" "TH" "TJ" "TL" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WS" "XB" "XC" "XE" "XM" "XN" "XS" "XY" "YE" "YT" "ZA" "ZM" "ZW"] }
def label-type-completer [] { ["PDF" "PNG" "ZPL"] }
def carrier-name-completer-1 [] { ["aramex" "asendia" "asendia_us" "australiapost" "boxknight" "bpost" "canadapost" "canpar" "chronopost" "colissimo" "dhl_express" "dhl_parcel_de" "dhl_poland" "dhl_universal" "dicom" "dpd" "dpd_meta" "dtdc" "fedex" "generic" "geodis" "gls" "hay_post" "hermes" "landmark" "laposte" "locate2u" "mydhl" "nationex" "postat" "purolator" "roadie" "royalmail" "seko" "sendle" "spring" "teleship" "tge" "tnt" "ups" "usps" "usps_international" "veho" "zoom2u"] }
def status-completer [] { ["" "cancelled" "delivered" "delivery_delayed" "delivery_failed" "in_transit" "on_hold" "out_for_delivery" "pending" "picked_up" "ready_for_pickup" "return_to_sender" "unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api ping" } } | get name | first)
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

# Instance Metadata
#
# GET /
# operationId: &&ping
export def "api ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Logout
#
# POST /api/logout
# operationId: &&logout
export def "logout logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logout")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Obtain auth token pair
#
# POST /api/token
# operationId: &&authenticate
export def "token authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string
  password: string
]: any -> record<access: string, refresh: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/token")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh auth token
#
# POST /api/token/refresh
# operationId: &&refresh_token
export def "token-refresh token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  refresh: string
]: any -> record<access: string, refresh: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/token/refresh")
  let body = {refresh: $refresh} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get verified JWT token
#
# POST /api/token/verified
# operationId: &&get_verified_token
export def "token-verified token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  refresh: string
  otp_token: string # The OTP (One Time Password) token received by the user from the         configured Two Factor Authentication method.         
]: any -> record<access: string, refresh: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/token/verified")
  let body = {refresh: $refresh, otp_token: $otp_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify token
#
# POST /api/token/verify
# operationId: &&verify_token
export def "token-verify token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/token/verify")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate resource access token
#
# POST /api/tokens
# operationId: &&generate_resource_token
export def "tokens token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resource_type: string@resource-type-completer # The type of resource to grant access to.
  resource_ids: list # List of resource IDs to grant access to.
  access: list # List of access permissions to grant.
  --format: string@format-completer # Document format (optional). (nullable)
  --expires-in: int # Token expiration time in seconds (60-3600, default: 300). (default: 300)
]: any -> record<token: string, expires_at: string, resource_urls: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tokens")
  let body = {resource_type: $resource_type, resource_ids: $resource_ids, access: $access, format: $format, expires_in: $expires_in} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all addresses
#
# GET /v1/addresses
# operationId: $list
export def "addresses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/addresses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an address
#
# POST /v1/addresses
# operationId: $create
export def "addresses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # A unique identifier for the address (used in JSON embedded data) (nullable)
  --postal-code: string # The address postal code         **(required for shipment purchase)**          (nullable)
  --city: string # The address city.         **(required for shipment purchase)**          (nullable)
  --federal-tax-id: string # The party frederal tax id (nullable)
  --state-tax-id: string # The party state id (nullable)
  --person-name: string # Attention to         **(required for shipment purchase)**          (nullable)
  --company-name: string # The company name if the party is a company (nullable)
  country_code: string@country-code-completer # The address country code
  --email: string # The party email (nullable)
  --phone-number: string # The party phone number. (nullable)
  --state-code: string # The address state code (nullable)
  --residential: oneof<nothing, bool> # Indicate if the address is residential or commercial (enterprise) (nullable, default: false)
  --street-number: string # The address street number (nullable)
  --address-line1: string # The address line with street number <br/>         **(required for shipment purchase)**          (nullable)
  --address-line2: string # The address line with suite number (nullable)
  --validate-location: oneof<nothing, bool> # Indicate if the address should be validated (nullable, default: false)
  --meta: record # Template metadata for template identification.         Structure: {"label": "Warehouse A", "is_default": true, "usage": ["sender", "return"]}          (nullable)
]: any -> record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/addresses")
  let body = {id: $id, postal_code: $postal_code, city: $city, federal_tax_id: $federal_tax_id, state_tax_id: $state_tax_id, person_name: $person_name, company_name: $company_name, country_code: $country_code, email: $email, phone_number: $phone_number, state_code: $state_code, residential: $residential, street_number: $street_number, address_line1: $address_line1, address_line2: $address_line2, validate_location: $validate_location, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an address
#
# GET /v1/addresses/{id}
# operationId: $retrieve
export def "addresses retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/addresses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an address
#
# PATCH /v1/addresses/{id}
# operationId: $update
export def "addresses update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: string # A unique identifier for the address (used in JSON embedded data) (nullable)
  --postal-code: string # The address postal code         **(required for shipment purchase)**          (nullable)
  --city: string # The address city.         **(required for shipment purchase)**          (nullable)
  --federal-tax-id: string # The party frederal tax id (nullable)
  --state-tax-id: string # The party state id (nullable)
  --person-name: string # Attention to         **(required for shipment purchase)**          (nullable)
  --company-name: string # The company name if the party is a company (nullable)
  --country-code: string@country-code-completer # The address country code
  --email: string # The party email (nullable)
  --phone-number: string # The party phone number. (nullable)
  --state-code: string # The address state code (nullable)
  --residential: oneof<nothing, bool> # Indicate if the address is residential or commercial (enterprise) (nullable, default: false)
  --street-number: string # The address street number (nullable)
  --address-line1: string # The address line with street number <br/>         **(required for shipment purchase)**          (nullable)
  --address-line2: string # The address line with suite number (nullable)
  --validate-location: oneof<nothing, bool> # Indicate if the address should be validated (nullable, default: false)
  --meta: record # Template metadata for template identification.         Structure: {"label": "Warehouse A", "is_default": true, "usage": ["sender", "return"]}          (nullable)
]: any -> record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/addresses/($id)")
  let body = {id: $body_id, postal_code: $postal_code, city: $city, federal_tax_id: $federal_tax_id, state_tax_id: $state_tax_id, person_name: $person_name, company_name: $company_name, country_code: $country_code, email: $email, phone_number: $phone_number, state_code: $state_code, residential: $residential, street_number: $street_number, address_line1: $address_line1, address_line2: $address_line2, validate_location: $validate_location, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Discard an address
#
# DELETE /v1/addresses/{id}
# operationId: $discard
export def "addresses discard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/addresses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export data files
#
# GET /v1/batches/data/export/{resource_type}.{export_format}
# operationId: &&&&$export_file
export def "batches-data-export file" [
  export_format: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data-template: string # A data template slug to use for the import.<br/>         **When nothing is specified, the system default headers are expected.**         
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data_template" $data_template "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/batches/data/export/($resource_type).($export_format)" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import data files
#
# POST /v1/batches/data/import
# operationId: &&&&$import_file
export def "batches-data-import file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data-file: string # format: binary
  --data-template: string # A data template slug to use for the import.<br/>         **When nothing is specified, the system default headers are expected.**         
  --resource-type: string@resource-type-completer-1 # The type of the resource to import
  --resource-type: string
  --data-template: string
  --data-file: string # format: binary
]: any -> record<id: string, status: string, resource_type: string, resources: table<id: string, status: string, errors: record>, created_at: string, updated_at: string, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data_file" $data_file "scalar") (serialize-qp "data_template" $data_template "scalar") (serialize-qp "resource_type" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/batches/data/import" $qp)
  let body = {resource_type: $resource_type, data_template: $data_template, data_file: $data_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List all batch operations
#
# GET /v1/batches/operations
# operationId: &&&&$list
export def "batches-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, status: string, resource_type: string, resources: list, created_at: string, updated_at: string, test_mode: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches/operations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a batch operation
#
# GET /v1/batches/operations/{id}
# operationId: &&&&$retrieve
export def "batches-operations retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, resource_type: string, resources: table<id: string, status: string, errors: record>, created_at: string, updated_at: string, test_mode: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/operations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create order batch
#
# POST /v1/batches/orders
# operationId: &&&&$create_orders
# --orders item shape: {order_id: string, order_date?: string, source?: string, shipping_to: any, shipping_from?: any, billing_address?: any, line_items: list, options?: record, metadata?: record}
export def "batches-orders orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  orders: list # The list of orders to process. — item shape: {order_id: string, order_date?: string, source?: string, shipping_to: any, shipping_from?: any, billing_address?: any, line_items: list, options?: record, metadata?: record}
]: any -> record<id: string, status: string, resource_type: string, resources: table<id: string, status: string, errors: record>, created_at: string, updated_at: string, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches/orders")
  let body = {orders: $orders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create shipment batch
#
# POST /v1/batches/shipments
# operationId: &&&&$create_shipments
# --shipments item shape: {recipient: any, shipper: any, return_address?: any, billing_address?: any, parcels: list, options?: record, payment?: any, customs?: any, reference?: string, order_id?: string, label_type?: "PDF"|"ZPL"|"PNG", is_return?: bool, service?: string, services?: list, carrier_ids?: list, metadata?: record, id?: string}
export def "batches-shipments shipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shipments: list # The list of shipments to process. — item shape: {recipient: any, shipper: any, return_address?: any, billing_address?: any, parcels: list, options?: record, payment?: any, customs?: any, reference?: string, order_id?: string, label_type?: "PDF"|"ZPL"|"PNG", is_return?: bool, service?: string, services?: list, carrier_ids?: list, metadata?: record, id?: string}
]: any -> record<id: string, status: string, resource_type: string, resources: table<id: string, status: string, errors: record>, created_at: string, updated_at: string, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches/shipments")
  let body = {shipments: $shipments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create tracker batch
#
# POST /v1/batches/trackers
# operationId: &&&&$create_trackers
# --trackers item shape: {tracking_number: string, carrier_name: "aramex"|"asendia"|"asendia_us"|"australiapost"|"boxknight"|"bpost"|"canadapost"|"canpar"|"chronopost"|"colissimo"|"dhl_express"|"dhl_parcel_de"|"dhl_poland"|"dhl_universal"|"dicom"|"dpd"|"dpd_meta"|"dtdc"|"fedex"|"generic"|"geodis"|"gls"|"hay_post"|"hermes"|"landmark"|"laposte"|"locate2u"|"mydhl"|"nationex"|"postat"|"purolator"|"roadie"|"royalmail"|"seko"|"sendle"|"spring"|"teleship"|"tge"|"tnt"|"ups"|"usps"|"usps_international"|"veho"|"zoom2u", account_number?: string, reference?: string, info?: any, metadata?: record}
export def "batches-trackers trackers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  trackers: list # The list of tracking info to process. — item shape: {tracking_number: string, carrier_name: "aramex"|"asendia"|"asendia_us"|"australiapost"|"boxknight"|"bpost"|"canadapost"|"canpar"|"chronopost"|"colissimo"|"dhl_express"|"dhl_parcel_de"|"dhl_poland"|"dhl_universal"|"dicom"|"dpd"|"dpd_meta"|"dtdc"|"fedex"|"generic"|"geodis"|"gls"|"hay_post"|"hermes"|"landmark"|"laposte"|"locate2u"|"mydhl"|"nationex"|"postat"|"purolator"|"roadie"|"royalmail"|"seko"|"sendle"|"spring"|"teleship"|"tge"|"tnt"|"ups"|"usps"|"usps_international"|"veho"|"zoom2u", account_number?: string, reference?: string, info?: any, metadata?: record}
]: any -> record<id: string, status: string, resource_type: string, resources: table<id: string, status: string, errors: record>, created_at: string, updated_at: string, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches/trackers")
  let body = {trackers: $trackers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resend webhooks
#
# POST /v1/batches/webhooks
# operationId: $$$$$$$$resend_webhooks
export def "batches-webhooks webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entity_ids: list
  --object-type: string@object-type-completer # default: tracker
  --webhook-id: string
]: any -> record<object_type: string, resources: table<id: string, status: string, error: string>, count: int, test_mode: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches/webhooks")
  let body = {entity_ids: $entity_ids, object_type: $object_type, webhook_id: $webhook_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all carriers
#
# GET /v1/carriers
# operationId: &&list
export def "carriers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<carrier_name: string, display_name: string, integration_status: string, capabilities: list<string>, connection_fields: record, config_fields: record, shipping_services: record, shipping_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/carriers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get carrier details
#
# GET /v1/carriers/{carrier_name}
# operationId: &&get_details
export def "carriers details" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<carrier_name: string, display_name: string, integration_status: string, capabilities: list<string>, connection_fields: record, config_fields: record, shipping_services: record, shipping_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get carrier options
#
# GET /v1/carriers/{carrier_name}/options
# operationId: &&get_options
export def "carriers-options options" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_name)/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get carrier services
#
# GET /v1/carriers/{carrier_name}/services
# operationId: &&get_services
export def "carriers-services services" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_name)/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List carrier connections
#
# GET /v1/connections
# operationId: &&&list
export def "connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool>
  --carrier-name: string # The unique carrier slug. <br/>Values: `aramex`, `asendia`, `asendia_us`, `australiapost`, `boxknight`, `bpost`, `canadapost`, `canpar`, `chronopost`, `colissimo`, `dhl_express`, `dhl_parcel_de`, `dhl_poland`, `dhl_universal`, `dicom`, `dpd`, `dpd_meta`, `dtdc`, `easypost`, `easyship`, `eshipper`, `fedex`, `freightcom`, `generic`, `geodis`, `gls`, `hay_post`, `hermes`, `landmark`, `laposte`, `locate2u`, `mydhl`, `nationex`, `parcelone`, `postat`, `purolator`, `roadie`, `royalmail`, `sapient`, `seko`, `sendle`, `shipengine`, `spring`, `teleship`, `tge`, `tnt`, `ups`, `usps`, `usps_international`, `veho`, `zoom2u`
  --metadata-key: string
  --metadata-value: string
  --system-only: oneof<nothing, bool>
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, object_type: string, carrier_name: string, display_name: string, carrier_id: string, capabilities: list, config: record, metadata: record, is_system: bool, active: bool, test_mode: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "carrier_name" $carrier_name "scalar") (serialize-qp "metadata_key" $metadata_key "scalar") (serialize-qp "metadata_value" $metadata_value "scalar") (serialize-qp "system_only" $system_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a carrier connection
#
# POST /v1/connections
# operationId: &&&add
export def "connections add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  carrier_name: string@carrier-name-completer # A carrier connection type.
  carrier_id: string # A carrier connection friendly name.
  credentials: any # Carrier connection credentials.
  --capabilities: list # The carrier enabled capabilities. (nullable)
  --config: record # Carrier connection custom config. (default: {})
  --metadata: record # User metadata for the carrier. (default: {})
  --active: oneof<nothing, bool> # The active flag indicates whether the carrier account is active or not. (default: true)
]: any -> record<id: string, object_type: string, carrier_name: string, display_name: string, carrier_id: string, capabilities: list<string>, config: record, metadata: record, is_system: bool, active: bool, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections")
  let body = {carrier_name: $carrier_name, carrier_id: $carrier_id, credentials: $credentials, capabilities: $capabilities, config: $config, metadata: $metadata, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a connection
#
# GET /v1/connections/{id}
# operationId: &&&retrieve
export def "connections retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, carrier_name: string, display_name: string, carrier_id: string, capabilities: list<string>, config: record, metadata: record, is_system: bool, active: bool, test_mode: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a connection
#
# PATCH /v1/connections/{id}
# operationId: &&&update
export def "connections update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier-name: string@carrier-name-completer # A carrier connection type.
  --carrier-id: string # A carrier connection friendly name.
  --credentials: any # Carrier connection credentials.
  --capabilities: list # The carrier enabled capabilities. (nullable)
  --config: record # Carrier connection custom config. (default: {})
  --metadata: record # User metadata for the carrier. (default: {})
  --active: oneof<nothing, bool> # The active flag indicates whether the carrier account is active or not. (default: true)
]: any -> record<id: string, object_type: string, carrier_name: string, display_name: string, carrier_id: string, capabilities: list<string>, config: record, metadata: record, is_system: bool, active: bool, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connections/($id)")
  let body = {carrier_name: $carrier_name, carrier_id: $carrier_id, credentials: $credentials, capabilities: $capabilities, config: $config, metadata: $metadata, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a carrier connection
#
# DELETE /v1/connections/{id}
# operationId: &&&remove
export def "connections remove" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, carrier_name: string, display_name: string, carrier_id: string, capabilities: list<string>, config: record, metadata: record, is_system: bool, active: bool, test_mode: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a document
#
# POST /v1/documents/generate
# operationId: &&&&$$generateDocument
export def "documents-generate generateDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template-id: string # The template name. **Required if template is not provided.**
  --template: string # The template content. **Required if template_id is not provided.**
  --doc-format: string # The format of the document
  --doc-name: string # The file name
  --data: record # The template data (default: {})
  --options: record # The template rendering options
]: any -> record<template_id: string, doc_format: string, doc_name: string, doc_file: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/documents/generate")
  let body = {template_id: $template_id, template: $template, doc_format: $doc_format, doc_name: $doc_name, data: $data, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all templates
#
# GET /v1/documents/templates
# operationId: &&&&$$list
export def "documents-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, name: string, slug: string, template: string, active: bool, description: string, metadata: record, options: record, related_object: string, object_type: string, preview_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/documents/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a template
#
# POST /v1/documents/templates
# operationId: &&&&$$create
export def "documents-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The template name
  slug: string # The template slug
  template: string # The template content
  --active: oneof<nothing, bool> # disable template flag. (default: true)
  --description: string # The template description
  --metadata: record # The template metadata
  --options: record # The template rendering options
  --related-object: string@related-object-completer # The template related object (default: other)
]: any -> record<id: string, name: string, slug: string, template: string, active: bool, description: string, metadata: record, options: record, related_object: string, object_type: string, preview_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/documents/templates")
  let body = {name: $name, slug: $slug, template: $template, active: $active, description: $description, metadata: $metadata, options: $options, related_object: $related_object} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a template
#
# GET /v1/documents/templates/{id}
# operationId: &&&&$$retrieve
export def "documents-templates retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, slug: string, template: string, active: bool, description: string, metadata: record, options: record, related_object: string, object_type: string, preview_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/documents/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a template
#
# PATCH /v1/documents/templates/{id}
# operationId: &&&&$$update
export def "documents-templates update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The template name
  --slug: string # The template slug
  --template: string # The template content
  --active: oneof<nothing, bool> # disable template flag. (default: true)
  --description: string # The template description
  --metadata: record # The template metadata
  --options: record # The template rendering options
  --related-object: string@related-object-completer # The template related object (default: other)
]: any -> record<id: string, name: string, slug: string, template: string, active: bool, description: string, metadata: record, options: record, related_object: string, object_type: string, preview_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/documents/templates/($id)")
  let body = {name: $name, slug: $slug, template: $template, active: $active, description: $description, metadata: $metadata, options: $options, related_object: $related_object} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a template
#
# DELETE /v1/documents/templates/{id}
# operationId: &&&&$$discard
export def "documents-templates discard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, slug: string, template: string, active: bool, description: string, metadata: record, options: record, related_object: string, object_type: string, preview_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/documents/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all upload records
#
# GET /v1/documents/uploads
# operationId: $$$$$&uploads
export def "documents-uploads uploads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-after: string # format: date-time
  --created-before: string # format: date-time
  --shipment-id: string
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, carrier_name: string, carrier_id: string, documents: list, meta: record, reference: string, messages: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "shipment_id" $shipment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/documents/uploads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload documents
#
# POST /v1/documents/uploads
# operationId: $$$$$&upload
# --document_files item shape: {doc_file: string, doc_name: string, doc_format?: string, doc_type?: string}
export def "documents-uploads upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shipment_id: string # The documents related shipment.
  document_files: list # Shipping document files — item shape: {doc_file: string, doc_name: string, doc_format?: string, doc_type?: string}
  --reference: string # Shipping document file reference (nullable)
]: any -> record<id: string, carrier_name: string, carrier_id: string, documents: table<doc_id: string, file_name: string>, meta: record, reference: string, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/documents/uploads")
  let body = {shipment_id: $shipment_id, document_files: $document_files, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve upload record
#
# GET /v1/documents/uploads/{id}
# operationId: $$$$$&retrieve_upload
export def "documents-uploads upload-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, carrier_name: string, carrier_id: string, documents: table<doc_id: string, file_name: string>, meta: record, reference: string, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/documents/uploads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List manifests
#
# GET /v1/manifests
# operationId: $$$$&&list
export def "manifests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier-name: string # The unique carrier slug. <br/>Values: `aramex`, `asendia`, `asendia_us`, `australiapost`, `boxknight`, `bpost`, `canadapost`, `canpar`, `chronopost`, `colissimo`, `dhl_express`, `dhl_parcel_de`, `dhl_poland`, `dhl_universal`, `dicom`, `dpd`, `dpd_meta`, `dtdc`, `easypost`, `easyship`, `eshipper`, `fedex`, `freightcom`, `generic`, `geodis`, `gls`, `hay_post`, `hermes`, `landmark`, `laposte`, `locate2u`, `mydhl`, `nationex`, `parcelone`, `postat`, `purolator`, `roadie`, `royalmail`, `sapient`, `seko`, `sendle`, `shipengine`, `spring`, `teleship`, `tge`, `tnt`, `ups`, `usps`, `usps_international`, `veho`, `zoom2u`
  --created-after: string # format: date-time
  --created-before: string # format: date-time
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, object_type: string, carrier_name: string, carrier_id: string, meta: record, test_mode: bool, address: record, options: record, reference: string, shipment_identifiers: list, metadata: record, manifest_url: string, messages: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_name" $carrier_name "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/manifests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a manifest
#
# POST /v1/manifests
# operationId: $$$$&&create
export def "manifests create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  carrier_name: string # The manifest's carrier
  address: any # The address of the warehouse or location where the shipments originate.
  --options: record # <details>         <summary>The options available for the manifest.</summary>          {             "shipments": [                 {                     "tracking_number": "123456789",                     ...                     "meta": {...}                 }             ]         }         </details>          (default: {})
  --reference: string # The manifest reference (nullable)
  shipment_ids: list # The list of existing shipment object ids with label purchased.
]: any -> record<id: string, object_type: string, carrier_name: string, carrier_id: string, meta: record, test_mode: bool, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, options: record, reference: string, shipment_identifiers: list<string>, metadata: record, manifest_url: string, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/manifests")
  let body = {carrier_name: $carrier_name, address: $address, options: $options, reference: $reference, shipment_ids: $shipment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a manifest
#
# GET /v1/manifests/{id}
# operationId: $$$$&&retrieve
export def "manifests retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, carrier_name: string, carrier_id: string, meta: record, test_mode: bool, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, options: record, reference: string, shipment_identifiers: list<string>, metadata: record, manifest_url: string, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/manifests/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a manifest document
#
# POST /v1/manifests/{id}/document
# operationId: $$$$&&document
export def "manifests-document document" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<category: string, format: string, print_format: string, url: string, base64: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/manifests/($id)/document")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all orders
#
# GET /v1/orders
# operationId: &&&&list
export def "orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, object_type: string, order_id: string, order_date: string, source: string, status: string, shipping_to: record, shipping_from: record, billing_address: record, line_items: list, options: record, meta: record, metadata: record, shipments: list, test_mode: bool, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/orders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an order
#
# POST /v1/orders
# operationId: &&&&create
# --line_items item shape: {weight: float, weight_unit: "KG"|"LB"|"OZ"|"G", title?: string, description?: string, quantity?: int, sku?: string, hs_code?: string, value_amount?: float, value_currency?: "EUR"|"AED"|"USD"|"XCD"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"XOF"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"XAF"|"CHF"|"NZD"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"FJD"|"GBP"|"GEL"|"GHS"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"XPF"|"NGN"|"NIO"|"NOK"|"NPR"|"OMR"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"YER"|"ZAR"|"", origin_country?: "AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AN"|"AO"|"AR"|"AS"|"AT"|"AU"|"AW"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BM"|"BN"|"BO"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IN"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KV"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PR"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SY"|"SZ"|"TC"|"TD"|"TG"|"TH"|"TJ"|"TL"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WS"|"XB"|"XC"|"XE"|"XM"|"XN"|"XS"|"XY"|"YE"|"YT"|"ZA"|"ZM"|"ZW"|"EH"|"IM"|"BL"|"MF"|"SX"|"", product_url?: string, image_url?: string, product_id?: string, variant_id?: string, parent_id?: string, metadata?: record, meta?: record}
export def "orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  order_id: string # The source' order id.
  --order-date: string # The order date. format: `YYYY-MM-DD` (nullable)
  --body-source: string # The order's source.<br/>         e.g. API, POS, ERP, Shopify, Woocommerce, etc.          (default: API)
  shipping_to: any # The customer or recipient address for the order.
  --shipping-from: any # The origin or warehouse address of the order items. (nullable)
  --billing-address: any # The customer' or shipping billing address. (nullable)
  line_items: list # The order line items. — item shape: {weight: float, weight_unit: "KG"|"LB"|"OZ"|"G", title?: string, description?: string, quantity?: int, sku?: string, hs_code?: string, value_amount?: float, value_currency?: "EUR"|"AED"|"USD"|"XCD"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"XOF"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"XAF"|"CHF"|"NZD"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"FJD"|"GBP"|"GEL"|"GHS"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"XPF"|"NGN"|"NIO"|"NOK"|"NPR"|"OMR"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"YER"|"ZAR"|"", origin_country?: "AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AN"|"AO"|"AR"|"AS"|"AT"|"AU"|"AW"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BM"|"BN"|"BO"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IN"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KV"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PR"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SY"|"SZ"|"TC"|"TD"|"TG"|"TH"|"TJ"|"TL"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WS"|"XB"|"XC"|"XE"|"XM"|"XN"|"XS"|"XY"|"YE"|"YT"|"ZA"|"ZM"|"ZW"|"EH"|"IM"|"BL"|"MF"|"SX"|"", product_url?: string, image_url?: string, product_id?: string, variant_id?: string, parent_id?: string, metadata?: record, meta?: record}
  --options: record # <details>         <summary>The options available for the order shipments.</summary>          {             "currency": "USD",             "paid_by": "third_party",             "payment_account_number": "123456789",             "duty_paid_by": "third_party",             "duty_account_number": "123456789",             "invoice_number": "123456789",             "invoice_date": "2020-01-01",             "single_item_per_parcel": true,             "carrier_ids": ["canadapost-test"],             "preferred_service": "fedex_express_saver",         }         </details>          (nullable)
  --metadata: record # User metadata for the order. (default: {})
]: any -> record<id: string, object_type: string, order_id: string, order_date: string, source: string, status: string, shipping_to: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, shipping_from: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, line_items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string, unfulfilled_quantity: int>, options: record, meta: record, metadata: record, shipments: table<id: string, object_type: string, tracking_url: string, shipper: record, recipient: record, return_address: record, billing_address: record, parcels: list, services: list, options: record, payment: record, customs: record, rates: list, reference: string, order_id: string, label_type: string, carrier_ids: list, tracker_id: string, created_at: string, metadata: record, messages: list, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: list>, test_mode: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/orders")
  let body = {order_id: $order_id, order_date: $order_date, source: $body_source, shipping_to: $shipping_to, shipping_from: $shipping_from, billing_address: $billing_address, line_items: $line_items, options: $options, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an order
#
# GET /v1/orders/{id}
# operationId: &&&&retrieve
export def "orders retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, order_id: string, order_date: string, source: string, status: string, shipping_to: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, shipping_from: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, line_items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string, unfulfilled_quantity: int>, options: record, meta: record, metadata: record, shipments: table<id: string, object_type: string, tracking_url: string, shipper: record, recipient: record, return_address: record, billing_address: record, parcels: list, services: list, options: record, payment: record, customs: record, rates: list, reference: string, order_id: string, label_type: string, carrier_ids: list, tracker_id: string, created_at: string, metadata: record, messages: list, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: list>, test_mode: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/orders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an order
#
# PUT /v1/orders/{id}
# operationId: &&&&update
export def "orders update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --options: record # <details>         <summary>The options available for the order shipments.</summary>          {             "currency": "USD",             "paid_by": "third_party",             "payment_account_number": "123456789",             "duty_paid_by": "recipient",             "duty_account_number": "123456789",             "invoice_number": "123456789",             "invoice_date": "2020-01-01",             "single_item_per_parcel": true,             "carrier_ids": ["canadapost-test"],         }         </details>          (nullable)
  --metadata: record # User metadata for the shipment
]: any -> record<id: string, object_type: string, order_id: string, order_date: string, source: string, status: string, shipping_to: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, shipping_from: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, line_items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string, unfulfilled_quantity: int>, options: record, meta: record, metadata: record, shipments: table<id: string, object_type: string, tracking_url: string, shipper: record, recipient: record, return_address: record, billing_address: record, parcels: list, services: list, options: record, payment: record, customs: record, rates: list, reference: string, order_id: string, label_type: string, carrier_ids: list, tracker_id: string, created_at: string, metadata: record, messages: list, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: list>, test_mode: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/orders/($id)")
  let body = {options: $options, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Dismiss an order
#
# DELETE /v1/orders/{id}
# DEPRECATED
# operationId: &&&&dismiss
@deprecated
export def "orders dismiss" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, order_id: string, order_date: string, source: string, status: string, shipping_to: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, shipping_from: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, line_items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string, unfulfilled_quantity: int>, options: record, meta: record, metadata: record, shipments: table<id: string, object_type: string, tracking_url: string, shipper: record, recipient: record, return_address: record, billing_address: record, parcels: list, services: list, options: record, payment: record, customs: record, rates: list, reference: string, order_id: string, label_type: string, carrier_ids: list, tracker_id: string, created_at: string, metadata: record, messages: list, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: list>, test_mode: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/orders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an order
#
# POST /v1/orders/{id}/cancel
# operationId: &&&&cancel
export def "orders-cancel cancel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, order_id: string, order_date: string, source: string, status: string, shipping_to: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, shipping_from: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, line_items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string, unfulfilled_quantity: int>, options: record, meta: record, metadata: record, shipments: table<id: string, object_type: string, tracking_url: string, shipper: record, recipient: record, return_address: record, billing_address: record, parcels: list, services: list, options: record, payment: record, customs: record, rates: list, reference: string, order_id: string, label_type: string, carrier_ids: list, tracker_id: string, created_at: string, metadata: record, messages: list, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: list>, test_mode: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/orders/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all parcels
#
# GET /v1/parcels
# operationId: $$$list
export def "parcels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/parcels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a parcel
#
# POST /v1/parcels
# operationId: $$$create
# --items item shape: {weight: float, weight_unit: "KG"|"LB"|"OZ"|"G", title?: string, description?: string, quantity?: int, sku?: string, hs_code?: string, value_amount?: float, value_currency?: "EUR"|"AED"|"USD"|"XCD"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"XOF"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"XAF"|"CHF"|"NZD"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"FJD"|"GBP"|"GEL"|"GHS"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"XPF"|"NGN"|"NIO"|"NOK"|"NPR"|"OMR"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"YER"|"ZAR"|"", origin_country?: "AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AN"|"AO"|"AR"|"AS"|"AT"|"AU"|"AW"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BM"|"BN"|"BO"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IN"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KV"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PR"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SY"|"SZ"|"TC"|"TD"|"TG"|"TH"|"TJ"|"TL"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WS"|"XB"|"XC"|"XE"|"XM"|"XN"|"XS"|"XY"|"YE"|"YT"|"ZA"|"ZM"|"ZW"|"EH"|"IM"|"BL"|"MF"|"SX"|"", product_url?: string, image_url?: string, product_id?: string, variant_id?: string, parent_id?: string, metadata?: record, meta?: record}
export def "parcels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  weight: float # The parcel's weight (format: double)
  --width: float # The parcel's width (nullable, format: double)
  --height: float # The parcel's height (nullable, format: double)
  --length: float # The parcel's length (nullable, format: double)
  --packaging-type: string # The parcel's packaging type.<br/>         **Note that the packaging is optional when using a package preset.**<br/>         values: <br/>         `envelope` `pak` `tube` `pallet` `small_box` `medium_box` `your_packaging`<br/>         For carrier specific packaging types, please consult the reference.          (nullable)
  --package-preset: string # The parcel's package preset.<br/>         For carrier specific package presets, please consult the reference.          (nullable)
  --description: string # The parcel's description (nullable)
  --content: string # The parcel's content description (nullable)
  --is-document: oneof<nothing, bool> # Indicates if the parcel is composed of documents only (nullable, default: false)
  weight_unit: string@weight-unit-completer # The parcel's weight unit
  --dimension-unit: string@dimension-unit-completer # The parcel's dimension unit (nullable)
  --items: list # The parcel items. — item shape: {weight: float, weight_unit: "KG"|"LB"|"OZ"|"G", title?: string, description?: string, quantity?: int, sku?: string, hs_code?: string, value_amount?: float, value_currency?: "EUR"|"AED"|"USD"|"XCD"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"XOF"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"XAF"|"CHF"|"NZD"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"FJD"|"GBP"|"GEL"|"GHS"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"XPF"|"NGN"|"NIO"|"NOK"|"NPR"|"OMR"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"YER"|"ZAR"|"", origin_country?: "AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AN"|"AO"|"AR"|"AS"|"AT"|"AU"|"AW"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BM"|"BN"|"BO"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IN"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KV"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PR"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SY"|"SZ"|"TC"|"TD"|"TG"|"TH"|"TJ"|"TL"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WS"|"XB"|"XC"|"XE"|"XM"|"XN"|"XS"|"XY"|"YE"|"YT"|"ZA"|"ZM"|"ZW"|"EH"|"IM"|"BL"|"MF"|"SX"|"", product_url?: string, image_url?: string, product_id?: string, variant_id?: string, parent_id?: string, metadata?: record, meta?: record}
  --reference-number: string # The parcel reference number.<br/>         (can be used as tracking number for custom carriers)          (nullable)
  --freight-class: string # The parcel's freight class for pallet and freight shipments. (nullable)
  --options: record # <details>         <summary>Parcel specific options.</summary>          {             "insurance": "100.00",             "insured_by": "carrier",         }         </details>          (default: {})
  --meta: record # Template metadata for template identification.         Structure: {"label": "Standard Box", "is_default": true}          (nullable)
]: any -> record<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string>, reference_number: string, freight_class: string, options: record, meta: record, object_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/parcels")
  let body = {weight: $weight, width: $width, height: $height, length: $length, packaging_type: $packaging_type, package_preset: $package_preset, description: $description, content: $content, is_document: $is_document, weight_unit: $weight_unit, dimension_unit: $dimension_unit, items: $items, reference_number: $reference_number, freight_class: $freight_class, options: $options, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a parcel
#
# GET /v1/parcels/{id}
# operationId: $$$retrieve
export def "parcels retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string>, reference_number: string, freight_class: string, options: record, meta: record, object_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parcels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a parcel
#
# PATCH /v1/parcels/{id}
# operationId: $$$update
# --items item shape: {weight: float, weight_unit: "KG"|"LB"|"OZ"|"G", title?: string, description?: string, quantity?: int, sku?: string, hs_code?: string, value_amount?: float, value_currency?: "EUR"|"AED"|"USD"|"XCD"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"XOF"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"XAF"|"CHF"|"NZD"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"FJD"|"GBP"|"GEL"|"GHS"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"XPF"|"NGN"|"NIO"|"NOK"|"NPR"|"OMR"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"YER"|"ZAR"|"", origin_country?: "AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AN"|"AO"|"AR"|"AS"|"AT"|"AU"|"AW"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BM"|"BN"|"BO"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IN"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KV"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PR"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SY"|"SZ"|"TC"|"TD"|"TG"|"TH"|"TJ"|"TL"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WS"|"XB"|"XC"|"XE"|"XM"|"XN"|"XS"|"XY"|"YE"|"YT"|"ZA"|"ZM"|"ZW"|"EH"|"IM"|"BL"|"MF"|"SX"|"", product_url?: string, image_url?: string, product_id?: string, variant_id?: string, parent_id?: string, metadata?: record, meta?: record}
export def "parcels update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --weight: float # The parcel's weight (format: double)
  --width: float # The parcel's width (nullable, format: double)
  --height: float # The parcel's height (nullable, format: double)
  --length: float # The parcel's length (nullable, format: double)
  --packaging-type: string # The parcel's packaging type.<br/>         **Note that the packaging is optional when using a package preset.**<br/>         values: <br/>         `envelope` `pak` `tube` `pallet` `small_box` `medium_box` `your_packaging`<br/>         For carrier specific packaging types, please consult the reference.          (nullable)
  --package-preset: string # The parcel's package preset.<br/>         For carrier specific package presets, please consult the reference.          (nullable)
  --description: string # The parcel's description (nullable)
  --content: string # The parcel's content description (nullable)
  --is-document: oneof<nothing, bool> # Indicates if the parcel is composed of documents only (nullable, default: false)
  --weight-unit: string@weight-unit-completer # The parcel's weight unit
  --dimension-unit: string@dimension-unit-completer # The parcel's dimension unit (nullable)
  --items: list # The parcel items. — item shape: {weight: float, weight_unit: "KG"|"LB"|"OZ"|"G", title?: string, description?: string, quantity?: int, sku?: string, hs_code?: string, value_amount?: float, value_currency?: "EUR"|"AED"|"USD"|"XCD"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"XOF"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"XAF"|"CHF"|"NZD"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"FJD"|"GBP"|"GEL"|"GHS"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"XPF"|"NGN"|"NIO"|"NOK"|"NPR"|"OMR"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"YER"|"ZAR"|"", origin_country?: "AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AN"|"AO"|"AR"|"AS"|"AT"|"AU"|"AW"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BM"|"BN"|"BO"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IN"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KV"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PR"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SY"|"SZ"|"TC"|"TD"|"TG"|"TH"|"TJ"|"TL"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WS"|"XB"|"XC"|"XE"|"XM"|"XN"|"XS"|"XY"|"YE"|"YT"|"ZA"|"ZM"|"ZW"|"EH"|"IM"|"BL"|"MF"|"SX"|"", product_url?: string, image_url?: string, product_id?: string, variant_id?: string, parent_id?: string, metadata?: record, meta?: record}
  --reference-number: string # The parcel reference number.<br/>         (can be used as tracking number for custom carriers)          (nullable)
  --freight-class: string # The parcel's freight class for pallet and freight shipments. (nullable)
  --options: record # <details>         <summary>Parcel specific options.</summary>          {             "insurance": "100.00",             "insured_by": "carrier",         }         </details>          (default: {})
  --meta: record # Template metadata for template identification.         Structure: {"label": "Standard Box", "is_default": true}          (nullable)
]: any -> record<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string>, reference_number: string, freight_class: string, options: record, meta: record, object_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parcels/($id)")
  let body = {weight: $weight, width: $width, height: $height, length: $length, packaging_type: $packaging_type, package_preset: $package_preset, description: $description, content: $content, is_document: $is_document, weight_unit: $weight_unit, dimension_unit: $dimension_unit, items: $items, reference_number: $reference_number, freight_class: $freight_class, options: $options, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a parcel
#
# DELETE /v1/parcels/{id}
# operationId: $$$discard
export def "parcels discard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string>, reference_number: string, freight_class: string, options: record, meta: record, object_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parcels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List shipment pickups
#
# GET /v1/pickups
# operationId: $$$$list
export def "pickups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string
  --carrier-name: string # The unique carrier slug. <br/>Values: `aramex`, `asendia`, `asendia_us`, `australiapost`, `boxknight`, `bpost`, `canadapost`, `canpar`, `chronopost`, `colissimo`, `dhl_express`, `dhl_parcel_de`, `dhl_poland`, `dhl_universal`, `dicom`, `dpd`, `dpd_meta`, `dtdc`, `easypost`, `easyship`, `eshipper`, `fedex`, `freightcom`, `generic`, `geodis`, `gls`, `hay_post`, `hermes`, `landmark`, `laposte`, `locate2u`, `mydhl`, `nationex`, `parcelone`, `postat`, `purolator`, `roadie`, `royalmail`, `sapient`, `seko`, `sendle`, `shipengine`, `spring`, `teleship`, `tge`, `tnt`, `ups`, `usps`, `usps_international`, `veho`, `zoom2u`
  --confirmation-number: string
  --created-after: string # format: date-time
  --created-before: string # format: date-time
  --keyword: string
  --pickup-date-after: string # format: date
  --pickup-date-before: string # format: date
  --request-id: string
  --status: string # The pickup status. <br/>Values: `scheduled`, `picked_up`, `cancelled`, `closed`
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, object_type: string, carrier_name: string, carrier_id: string, confirmation_number: string, status: string, pickup_date: string, pickup_charge: record, ready_time: string, closing_time: string, pickup_type: string, recurrence: record, metadata: record, meta: record, carrier_code: string, address: record, parcels: list, parcels_count: int, instruction: string, package_location: string, options: record, test_mode: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "carrier_name" $carrier_name "scalar") (serialize-qp "confirmation_number" $confirmation_number "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "pickup_date_after" $pickup_date_after "scalar") (serialize-qp "pickup_date_before" $pickup_date_before "scalar") (serialize-qp "request_id" $request_id "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/pickups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule a pickup
#
# POST /v1/pickups
# operationId: $$$$create
export def "pickups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier-code: string # The carrier code for the pickup (e.g., 'canadapost', 'fedex').<br/>         Required when using `POST /v1/pickups`. (nullable)
  pickup_date: string # The expected pickup date.<br/>         Date Format: `YYYY-MM-DD`         
  --address: any # The pickup address
  --parcels-count: int # The number of parcels to be picked up (alternative to linking shipments) (nullable)
  ready_time: string # The ready time for pickup.<br/>         Time Format: `HH:MM`         
  closing_time: string # The closing or late time of the pickup.<br/>         Time Format: `HH:MM`         
  --instruction: string # The pickup instruction.<br/>         eg: Handle with care.          (nullable)
  --package-location: string # The package(s) location.<br/>         eg: Behind the entrance door.          (nullable)
  --pickup-type: string@pickup-type-completer # The pickup scheduling type.<br/>         - one_time: Single pickup on a specific date<br/>         - daily: Recurring pickup every business day<br/>         - recurring: Custom recurring schedule          (default: one_time)
  --recurrence: record # Recurrence configuration for recurring pickups.<br/>         Example: {"frequency": "weekly", "days_of_week": ["monday", "wednesday", "friday"], "end_date": "2024-12-31"}          (nullable)
  --options: record # Advanced carrier specific pickup options (nullable)
  --tracking-numbers: list # The list of shipments to be picked up (optional if parcels_count provided)
  --metadata: record # User metadata for the pickup (default: {})
]: any -> record<id: string, object_type: string, carrier_name: string, carrier_id: string, confirmation_number: string, status: string, pickup_date: string, pickup_charge: record<name: string, amount: float, currency: string, id: string>, ready_time: string, closing_time: string, pickup_type: string, recurrence: record, metadata: record, meta: record, carrier_code: string, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, parcels_count: int, instruction: string, package_location: string, options: record, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pickups")
  let body = {carrier_code: $carrier_code, pickup_date: $pickup_date, address: $address, parcels_count: $parcels_count, ready_time: $ready_time, closing_time: $closing_time, instruction: $instruction, package_location: $package_location, pickup_type: $pickup_type, recurrence: $recurrence, options: $options, tracking_numbers: $tracking_numbers, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule a pickup (deprecated)
#
# POST /v1/pickups/{carrier_name}/schedule
# DEPRECATED
# operationId: $$$$schedule
@deprecated
export def "pickups-schedule schedule" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier-code: string # The carrier code for the pickup (e.g., 'canadapost', 'fedex').<br/>         Required when using `POST /v1/pickups`. (nullable)
  pickup_date: string # The expected pickup date.<br/>         Date Format: `YYYY-MM-DD`         
  --address: any # The pickup address
  --parcels-count: int # The number of parcels to be picked up (alternative to linking shipments) (nullable)
  ready_time: string # The ready time for pickup.<br/>         Time Format: `HH:MM`         
  closing_time: string # The closing or late time of the pickup.<br/>         Time Format: `HH:MM`         
  --instruction: string # The pickup instruction.<br/>         eg: Handle with care.          (nullable)
  --package-location: string # The package(s) location.<br/>         eg: Behind the entrance door.          (nullable)
  --pickup-type: string@pickup-type-completer # The pickup scheduling type.<br/>         - one_time: Single pickup on a specific date<br/>         - daily: Recurring pickup every business day<br/>         - recurring: Custom recurring schedule          (default: one_time)
  --recurrence: record # Recurrence configuration for recurring pickups.<br/>         Example: {"frequency": "weekly", "days_of_week": ["monday", "wednesday", "friday"], "end_date": "2024-12-31"}          (nullable)
  --options: record # Advanced carrier specific pickup options (nullable)
  --tracking-numbers: list # The list of shipments to be picked up (optional if parcels_count provided)
  --metadata: record # User metadata for the pickup (default: {})
]: any -> record<id: string, object_type: string, carrier_name: string, carrier_id: string, confirmation_number: string, status: string, pickup_date: string, pickup_charge: record<name: string, amount: float, currency: string, id: string>, ready_time: string, closing_time: string, pickup_type: string, recurrence: record, metadata: record, meta: record, carrier_code: string, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, parcels_count: int, instruction: string, package_location: string, options: record, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pickups/($carrier_name)/schedule")
  let body = {carrier_code: $carrier_code, pickup_date: $pickup_date, address: $address, parcels_count: $parcels_count, ready_time: $ready_time, closing_time: $closing_time, instruction: $instruction, package_location: $package_location, pickup_type: $pickup_type, recurrence: $recurrence, options: $options, tracking_numbers: $tracking_numbers, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a pickup
#
# GET /v1/pickups/{id}
# operationId: $$$$retrieve
export def "pickups retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, carrier_name: string, carrier_id: string, confirmation_number: string, status: string, pickup_date: string, pickup_charge: record<name: string, amount: float, currency: string, id: string>, ready_time: string, closing_time: string, pickup_type: string, recurrence: record, metadata: record, meta: record, carrier_code: string, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, parcels_count: int, instruction: string, package_location: string, options: record, test_mode: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pickups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a pickup
#
# POST /v1/pickups/{id}
# operationId: $$$$update
export def "pickups update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier-code: string # The carrier code for the pickup (e.g., 'canadapost', 'fedex').<br/>         Required when using `POST /v1/pickups`. (nullable)
  --pickup-date: string # The expected pickup date.<br/>         Date Format: YYYY-MM-DD         
  --address: any # The pickup address
  --parcels-count: int # The number of parcels to be picked up (alternative to linking shipments) (nullable)
  --ready-time: string # The ready time for pickup. (nullable)
  --closing-time: string # The closing or late time of the pickup (nullable)
  --instruction: string # The pickup instruction.<br/>         eg: Handle with care.          (nullable)
  --package-location: string # The package(s) location.<br/>         eg: Behind the entrance door.          (nullable)
  --pickup-type: string@pickup-type-completer # The pickup scheduling type.<br/>         - one_time: Single pickup on a specific date<br/>         - daily: Recurring pickup every business day<br/>         - recurring: Custom recurring schedule          (default: one_time)
  --recurrence: record # Recurrence configuration for recurring pickups.<br/>         Example: {"frequency": "weekly", "days_of_week": ["monday", "wednesday", "friday"], "end_date": "2024-12-31"}          (nullable)
  --options: record # Advanced carrier specific pickup options (nullable)
  --tracking-numbers: list # The list of shipments to be picked up
  --metadata: record # User metadata for the pickup (default: {})
  confirmation_number: string # pickup identification number
]: any -> record<id: string, object_type: string, carrier_name: string, carrier_id: string, confirmation_number: string, status: string, pickup_date: string, pickup_charge: record<name: string, amount: float, currency: string, id: string>, ready_time: string, closing_time: string, pickup_type: string, recurrence: record, metadata: record, meta: record, carrier_code: string, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, parcels_count: int, instruction: string, package_location: string, options: record, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pickups/($id)")
  let body = {carrier_code: $carrier_code, pickup_date: $pickup_date, address: $address, parcels_count: $parcels_count, ready_time: $ready_time, closing_time: $closing_time, instruction: $instruction, package_location: $package_location, pickup_type: $pickup_type, recurrence: $recurrence, options: $options, tracking_numbers: $tracking_numbers, metadata: $metadata, confirmation_number: $confirmation_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a pickup
#
# POST /v1/pickups/{id}/cancel
# operationId: $$$$cancel
export def "pickups-cancel cancel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # The reason of the pickup cancellation
]: any -> record<id: string, object_type: string, carrier_name: string, carrier_id: string, confirmation_number: string, status: string, pickup_date: string, pickup_charge: record<name: string, amount: float, currency: string, id: string>, ready_time: string, closing_time: string, pickup_type: string, recurrence: record, metadata: record, meta: record, carrier_code: string, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, parcels_count: int, instruction: string, package_location: string, options: record, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pickups/($id)/cancel")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all products
#
# GET /v1/products
# operationId: $&list
export def "products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a product
#
# POST /v1/products
# operationId: $&create
export def "products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  weight: float # The commodity's weight (format: double)
  weight_unit: string@weight-unit-completer # The commodity's weight unit
  --title: string # A description of the commodity (nullable)
  --description: string # A description of the commodity (nullable)
  --quantity: int # The commodity's quantity (number or item) (default: 1)
  --sku: string # The commodity's sku number (nullable)
  --hs-code: string # The commodity's hs_code number (nullable)
  --value-amount: float # The monetary value of the commodity (nullable, format: double)
  --value-currency: string@value-currency-completer # The currency of the commodity value amount (nullable)
  --origin-country: string@origin-country-completer # The origin or manufacture country (nullable)
  --product-url: string # The product url (nullable)
  --image-url: string # The image url (nullable)
  --product-id: string # The product id (nullable)
  --variant-id: string # The variant id (nullable)
  --parent-id: string # The id of the related order line item. (nullable)
  --metadata: record # <details>         <summary>Commodity user references metadata.</summary>          {             "part_number": "5218487281",             "reference1": "# ref 1",             "reference2": "# ref 2",             "reference3": "# ref 3",             ...         }         </details>          (nullable)
  --meta: record # Template metadata for template identification.         Structure: {"label": "Widget Pro", "is_default": false}          (nullable)
]: any -> record<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products")
  let body = {weight: $weight, weight_unit: $weight_unit, title: $title, description: $description, quantity: $quantity, sku: $sku, hs_code: $hs_code, value_amount: $value_amount, value_currency: $value_currency, origin_country: $origin_country, product_url: $product_url, image_url: $image_url, product_id: $product_id, variant_id: $variant_id, parent_id: $parent_id, metadata: $metadata, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a product
#
# GET /v1/products/{id}
# operationId: $&retrieve
export def "products retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a product
#
# PATCH /v1/products/{id}
# operationId: $&update
export def "products update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --weight: float # The commodity's weight (format: double)
  --weight-unit: string@weight-unit-completer # The commodity's weight unit
  --title: string # A description of the commodity (nullable)
  --description: string # A description of the commodity (nullable)
  --quantity: int # The commodity's quantity (number or item) (default: 1)
  --sku: string # The commodity's sku number (nullable)
  --hs-code: string # The commodity's hs_code number (nullable)
  --value-amount: float # The monetary value of the commodity (nullable, format: double)
  --value-currency: string@value-currency-completer # The currency of the commodity value amount (nullable)
  --origin-country: string@origin-country-completer # The origin or manufacture country (nullable)
  --product-url: string # The product url (nullable)
  --image-url: string # The image url (nullable)
  --product-id: string # The product id (nullable)
  --variant-id: string # The variant id (nullable)
  --parent-id: string # The id of the related order line item. (nullable)
  --metadata: record # <details>         <summary>Commodity user references metadata.</summary>          {             "part_number": "5218487281",             "reference1": "# ref 1",             "reference2": "# ref 2",             "reference3": "# ref 3",             ...         }         </details>          (nullable)
  --meta: record # Template metadata for template identification.         Structure: {"label": "Widget Pro", "is_default": false}          (nullable)
]: any -> record<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($id)")
  let body = {weight: $weight, weight_unit: $weight_unit, title: $title, description: $description, quantity: $quantity, sku: $sku, hs_code: $hs_code, value_amount: $value_amount, value_currency: $value_currency, origin_country: $origin_country, product_url: $product_url, image_url: $image_url, product_id: $product_id, variant_id: $variant_id, parent_id: $parent_id, metadata: $metadata, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a product
#
# DELETE /v1/products/{id}
# operationId: $&discard
export def "products discard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, weight: float, weight_unit: string, title: string, description: string, quantity: int, sku: string, hs_code: string, value_amount: float, value_currency: string, origin_country: string, product_url: string, image_url: string, product_id: string, variant_id: string, parent_id: string, metadata: record, meta: record, object_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a manifest
#
# POST /v1/proxy/manifest
# operationId: @@@$generate_manifest
export def "proxy-manifest manifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  carrier_name: string # The manifest's carrier
  address: any # The address of the warehouse or location where the shipments originate.
  --options: record # <details>         <summary>The options available for the manifest.</summary>          {             "shipments": [                 {                     "tracking_number": "123456789",                     ...                     "meta": {...}                 }             ]         }         </details>          (default: {})
  --reference: string # The manifest reference (nullable)
  shipment_identifiers: list # The list of shipment identifiers you want to add to your manifest.<br/>         shipment_identifier is often a tracking_number or shipment_id returned when you purchase a label.         
]: any -> record<messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, manifest: record<id: string, object_type: string, carrier_name: string, carrier_id: string, doc: record<manifest: string>, meta: record, test_mode: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/proxy/manifest")
  let body = {carrier_name: $carrier_name, address: $address, options: $options, reference: $reference, shipment_identifiers: $shipment_identifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule a pickup
#
# POST /v1/proxy/pickups/{carrier_name}
# operationId: @schedule_pickup
# --parcels item shape: {weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record}
export def "proxy-pickups pickup" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier-code: string # The carrier code for the pickup (e.g., 'canadapost', 'fedex').<br/>         Required when using `POST /v1/pickups`. (nullable)
  pickup_date: string # The expected pickup date.<br/>         Date Format: `YYYY-MM-DD`         
  --address: any # The pickup address
  --parcels: list # The shipment parcels to pickup. — item shape: {weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record}
  --parcels-count: int # The number of parcels to be picked up (alternative to providing parcels array) (nullable)
  ready_time: string # The ready time for pickup.<br/>         Time Format: `HH:MM`         
  closing_time: string # The closing or late time of the pickup.<br/>         Time Format: `HH:MM`         
  --instruction: string # The pickup instruction.<br/>         eg: Handle with care.          (nullable)
  --package-location: string # The package(s) location.<br/>         eg: Behind the entrance door.          (nullable)
  --pickup-type: string@pickup-type-completer # The pickup scheduling type.<br/>         - one_time: Single pickup on a specific date<br/>         - daily: Recurring pickup every business day<br/>         - recurring: Custom recurring schedule          (default: one_time)
  --recurrence: record # Recurrence configuration for recurring pickups.<br/>         Example: {"frequency": "weekly", "days_of_week": ["monday", "wednesday", "friday"], "end_date": "2024-12-31"}          (nullable)
  --options: record # Advanced carrier specific pickup options (nullable)
]: any -> record<messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, pickup: record<id: string, object_type: string, carrier_name: string, carrier_id: string, confirmation_number: string, status: string, pickup_date: string, pickup_charge: record<name: string, amount: float, currency: string, id: string>, ready_time: string, closing_time: string, pickup_type: string, recurrence: record, metadata: record, meta: record, carrier_code: string, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record>, parcels: list<record>, parcels_count: int, instruction: string, package_location: string, options: record, test_mode: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/proxy/pickups/($carrier_name)")
  let body = {carrier_code: $carrier_code, pickup_date: $pickup_date, address: $address, parcels: $parcels, parcels_count: $parcels_count, ready_time: $ready_time, closing_time: $closing_time, instruction: $instruction, package_location: $package_location, pickup_type: $pickup_type, recurrence: $recurrence, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a pickup
#
# POST /v1/proxy/pickups/{carrier_name}/cancel
# operationId: @cancel_pickup
export def "proxy-pickups-cancel pickup" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  confirmation_number: string # The pickup confirmation identifier
  --address: any # The pickup address
  --pickup-date: string # The pickup date.<br/>         Date Format: `YYYY-MM-DD`          (nullable)
  --reason: string # The reason of the pickup cancellation
]: any -> record<messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, confirmation: record<operation: string, success: bool, carrier_name: string, carrier_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/proxy/pickups/($carrier_name)/cancel")
  let body = {confirmation_number: $confirmation_number, address: $address, pickup_date: $pickup_date, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a pickup
#
# POST /v1/proxy/pickups/{carrier_name}/update
# operationId: @update_pickup
# --parcels item shape: {id?: string, weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record, object_type?: string}
export def "proxy-pickups-update pickup" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pickup_date: string # The expected pickup date.<br/>         Date Format: `YYYY-MM-DD`         
  address: any # The pickup address
  parcels: list # The shipment parcels to pickup. — item shape: {id?: string, weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record, object_type?: string}
  confirmation_number: string # pickup identification number
  ready_time: string # The ready time for pickup.         Time Format: `HH:MM`         
  closing_time: string # The closing or late time of the pickup.<br/>         Time Format: `HH:MM`         
  --instruction: string # The pickup instruction.<br/>         eg: Handle with care.          (nullable)
  --package-location: string # The package(s) location.<br/>         eg: Behind the entrance door.          (nullable)
  --pickup-type: string@pickup-type-completer # The pickup scheduling type.<br/>         - one_time: Single pickup on a specific date<br/>         - daily: Recurring pickup every business day<br/>         - recurring: Custom recurring schedule          (default: one_time)
  --recurrence: record # Recurrence configuration for recurring pickups.<br/>         Example: {"frequency": "weekly", "days_of_week": ["monday", "wednesday", "friday"], "end_date": "2024-12-31"}          (nullable)
  --options: record # Advanced carrier specific pickup options (nullable)
]: any -> record<messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, pickup: record<id: string, object_type: string, carrier_name: string, carrier_id: string, confirmation_number: string, status: string, pickup_date: string, pickup_charge: record<name: string, amount: float, currency: string, id: string>, ready_time: string, closing_time: string, pickup_type: string, recurrence: record, metadata: record, meta: record, carrier_code: string, address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record>, parcels: list<record>, parcels_count: int, instruction: string, package_location: string, options: record, test_mode: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/proxy/pickups/($carrier_name)/update")
  let body = {pickup_date: $pickup_date, address: $address, parcels: $parcels, confirmation_number: $confirmation_number, ready_time: $ready_time, closing_time: $closing_time, instruction: $instruction, package_location: $package_location, pickup_type: $pickup_type, recurrence: $recurrence, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch shipment rates
#
# POST /v1/proxy/rates
# operationId: @@fetch_rates
# --parcels item shape: {weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record}
export def "proxy-rates rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shipper: any # The address of the party<br/>         Origin address (ship from) for the **shipper**<br/>         Destination address (ship to) for the **recipient**         
  recipient: any # The address of the party<br/>         Origin address (ship from) for the **shipper**<br/>         Destination address (ship to) for the **recipient**         
  parcels: list # The shipment's parcels — item shape: {weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record}
  --services: list # The requested carrier service for the shipment.<br/>         Please consult the reference for specific carriers services.<br/>         Note that this is a list because on a Multi-carrier rate request you could specify a service per carrier.          (nullable, default: [])
  --options: record # <details>         <summary>The options available for the shipment.</summary>          {             "currency": "USD",             "insurance": 100.00,             "insured_by": "carrier",             "cash_on_delivery": 30.00,             "dangerous_good": true,             "declared_value": 150.00,             "sms_notification": true,             "email_notification": true,             "email_notification_to": "shipper@mail.com",             "hold_at_location": true,             "paperless_trade": true,             "preferred_service": "fedex_express_saver",             "shipment_date": "2020-01-01",  # TODO: deprecate             "shipping_date": "2020-01-01T00:00",             "shipment_note": "This is a shipment note",             "signature_confirmation": true,             "saturday_delivery": true,             "shipper_instructions": "This is a shipper instruction",             "recipient_instructions": "This is a recipient instruction",             "doc_files": [                 {                     "doc_type": "commercial_invoice",                     "doc_file": "base64 encoded file",                     "doc_name": "commercial_invoice.pdf",                     "doc_format": "pdf",                 }             ],             "doc_references": [                 {                     "doc_id": "123456789",                     "doc_type": "commercial_invoice",                 }             ],         }         </details>          (default: {})
  --reference: string # The shipment reference (nullable)
  --payment: any # The payment details (nullable)
  --customs: any # The customs details.<br/>         **Note that this is required for international shipments.**          (nullable)
  --return-address: any # The return address for this shipment. Defaults to the shipper address. (nullable)
  --billing-address: any # The billing address for this shipment. (nullable)
  --carrier-ids: list # The list of configured carriers you wish to get rates from. (nullable, default: [])
]: any -> record<messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/proxy/rates")
  let body = {shipper: $shipper, recipient: $recipient, parcels: $parcels, services: $services, options: $options, reference: $reference, payment: $payment, customs: $customs, return_address: $return_address, billing_address: $billing_address, carrier_ids: $carrier_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Buy a shipment label
#
# POST /v1/proxy/shipping
# operationId: @@@buy_label
# --parcels item shape: {weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record}
# --rates item shape: {id?: string, object_type?: string, carrier_name: string, carrier_id: string, currency?: string, service?: string, total_charge?: float, transit_days?: int, extra_charges?: list, estimated_delivery?: string, meta?: record, test_mode: bool}
export def "proxy-shipping label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  recipient: any # The address of the party.<br/>         Origin address (ship from) for the **shipper**<br/>         Destination address (ship to) for the **recipient**         
  shipper: any # The address of the party.<br/>         Origin address (ship from) for the **shipper**<br/>         Destination address (ship to) for the **recipient**         
  --return-address: any # The return address for this shipment. Defaults to the shipper address. (nullable)
  --billing-address: any # The payor address. (nullable)
  parcels: list # The shipment's parcels — item shape: {weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record}
  --options: record # <details>         <summary>The options available for the shipment.</summary>          {             "currency": "USD",             "insurance": 100.00,             "cash_on_delivery": 30.00,             "dangerous_good": true,             "declared_value": 150.00,             "sms_notification": true,             "email_notification": true,             "email_notification_to": "shipper@mail.com",             "hold_at_location": true,             "paperless_trade": true,             "preferred_service": "fedex_express_saver",             "shipment_date": "2020-01-01",  # TODO: deprecate             "shipping_date": "2020-01-01T00:00",             "shipment_note": "This is a shipment note",             "signature_confirmation": true,             "saturday_delivery": true,             "shipper_instructions": "This is a shipper instruction",             "recipient_instructions": "This is a recipient instruction",             "doc_files": [                 {                     "doc_type": "commercial_invoice",                     "doc_file": "base64 encoded file",                     "doc_name": "commercial_invoice.pdf",                     "doc_format": "pdf",                 }             ],             "doc_references": [                 {                     "doc_id": "123456789",                     "doc_type": "commercial_invoice",                 }             ],         }         </details>          (default: {})
  --payment: any # The payment details (default: {paid_by: sender, currency: , account_number: })
  --customs: any # The customs details.<br/>         **Note that this is required for the shipment of an international Dutiable parcel.**          (nullable)
  --reference: string # The shipment reference (nullable)
  --order-id: string # The order identifier associated with this shipment (nullable)
  --label-type: string@label-type-completer # The shipment label file type. (default: PDF)
  --is-return: oneof<nothing, bool> # Indicates whether this shipment is a return shipment. When true, addresses are auto-swapped and the request is routed to the carrier's return shipment API. (default: false)
  selected_rate_id: string # The shipment selected rate.
  rates: list # The list for shipment rates fetched previously — item shape: {id?: string, object_type?: string, carrier_name: string, carrier_id: string, currency?: string, service?: string, total_charge?: float, transit_days?: int, extra_charges?: list, estimated_delivery?: string, meta?: record, test_mode: bool}
]: any -> record<id: string, object_type: string, tracking_url: string, shipper: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, recipient: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, return_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, services: list<string>, options: record, payment: record<paid_by: string, currency: string, account_number: string>, customs: record<commodities: list<record>, duty: record<paid_by: string, currency: string, declared_value: float, account_number: string>, duty_billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, content_type: string, content_description: string, incoterm: string, invoice: string, invoice_date: string, commercial_invoice: bool, certify: bool, signer: string, options: record>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>, reference: string, order_id: string, label_type: string, carrier_ids: list<string>, tracker_id: string, created_at: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list<record>, estimated_delivery: string, meta: record, test_mode: bool>, docs: record<label: string, invoice: string, extra_documents: list<record>>, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/proxy/shipping")
  let body = {recipient: $recipient, shipper: $shipper, return_address: $return_address, billing_address: $billing_address, parcels: $parcels, options: $options, payment: $payment, customs: $customs, reference: $reference, order_id: $order_id, label_type: $label_type, is_return: $is_return, selected_rate_id: $selected_rate_id, rates: $rates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Void a shipment label
#
# POST /v1/proxy/shipping/{carrier_name}/cancel
# operationId: @@@void_label
export def "proxy-shipping-cancel label" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shipment_identifier: string # The shipment identifier returned during creation.
  --service: string # The selected shipment service (nullable)
  --carrier-id: string # The shipment carrier_id for specific connection selection.
  --options: record # Advanced carrier specific cancellation options. (default: {})
]: any -> record<messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, confirmation: record<operation: string, success: bool, carrier_name: string, carrier_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/proxy/shipping/($carrier_name)/cancel")
  let body = {shipment_identifier: $shipment_identifier, service: $service, carrier_id: $carrier_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tracking details
#
# POST /v1/proxy/tracking
# operationId: @@@@get_tracking
export def "proxy-tracking tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hub: string
  tracking_number: string # The package tracking number
  carrier_name: string@carrier-name-completer-1 # The tracking carrier
  --account-number: string # The shipper account number (nullable)
  --reference: string # The shipment reference (nullable)
  --info: any # The package and shipment tracking details (nullable)
  --metadata: record # The carrier user metadata. (default: {})
]: any -> record<messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, tracking: record<id: string, carrier_name: string, carrier_id: string, tracking_number: string, info: record<carrier_tracking_link: string, customer_name: string, expected_delivery: string, note: string, order_date: string, order_id: string, package_weight: string, package_weight_unit: string, shipment_package_count: string, shipment_pickup_date: string, shipment_delivery_date: string, shipment_service: string, shipment_origin_country: string, shipment_origin_postal_code: string, shipment_destination_country: string, shipment_destination_postal_code: string, shipping_date: string, signed_by: string, source: string>, events: list<record>, delivered: bool, test_mode: bool, status: string, estimated_delivery: string, meta: record, images: record<delivery_image: string, signature_image: string>, object_type: string, metadata: record, messages: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hub" $hub "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/proxy/tracking" $qp)
  let body = {tracking_number: $tracking_number, carrier_name: $carrier_name, account_number: $account_number, reference: $reference, info: $info, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track a shipment
#
# GET /v1/proxy/tracking/{carrier_name}/{tracking_number}
# DEPRECATED
# operationId: @@@@track_shipment
@deprecated
export def "proxy-tracking shipment" [
  carrier_name: string
  tracking_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hub: string
]: nothing -> record<messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, tracking: record<id: string, carrier_name: string, carrier_id: string, tracking_number: string, info: record<carrier_tracking_link: string, customer_name: string, expected_delivery: string, note: string, order_date: string, order_id: string, package_weight: string, package_weight_unit: string, shipment_package_count: string, shipment_pickup_date: string, shipment_delivery_date: string, shipment_service: string, shipment_origin_country: string, shipment_origin_postal_code: string, shipment_destination_country: string, shipment_destination_postal_code: string, shipping_date: string, signed_by: string, source: string>, events: list<record>, delivered: bool, test_mode: bool, status: string, estimated_delivery: string, meta: record, images: record<delivery_image: string, signature_image: string>, object_type: string, metadata: record, messages: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hub" $hub "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/proxy/tracking/($carrier_name)/($tracking_number)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Data References
#
# GET /v1/references
# operationId: &&data
export def "references data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/references")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all shipments
#
# GET /v1/shipments
# operationId: $$$$$list
export def "shipments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string
  --carrier-name: string # The unique carrier slug. <br/>Values: `aramex`, `asendia`, `asendia_us`, `australiapost`, `boxknight`, `bpost`, `canadapost`, `canpar`, `chronopost`, `colissimo`, `dhl_express`, `dhl_parcel_de`, `dhl_poland`, `dhl_universal`, `dicom`, `dpd`, `dpd_meta`, `dtdc`, `easypost`, `easyship`, `eshipper`, `fedex`, `freightcom`, `generic`, `geodis`, `gls`, `hay_post`, `hermes`, `landmark`, `laposte`, `locate2u`, `mydhl`, `nationex`, `parcelone`, `postat`, `purolator`, `roadie`, `royalmail`, `sapient`, `seko`, `sendle`, `shipengine`, `spring`, `teleship`, `tge`, `tnt`, `ups`, `usps`, `usps_international`, `veho`, `zoom2u`
  --created-after: string # format: date-time
  --created-before: string # format: date-time
  --has-manifest: oneof<nothing, bool>
  --has-tracker: oneof<nothing, bool>
  --id: string
  --is-return: oneof<nothing, bool>
  --keyword: string
  --meta-key: string
  --meta-value: string
  --metadata-key: string
  --metadata-value: string
  --option-key: string
  --option-value: string
  --order-id: string
  --reference: string
  --request-id: string
  --service: string
  --status: string # Valid shipment status. <br/>Values: `draft`, `created`, `cancelled`, `shipped`, `in_transit`, `delivered`, `needs_attention`, `out_for_delivery`, `delivery_failed`
  --tracking-number: string
]: nothing -> record<id: string, object_type: string, tracking_url: string, shipper: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, recipient: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, return_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, services: list<string>, options: record, payment: record<paid_by: string, currency: string, account_number: string>, customs: record<commodities: list<record>, duty: record<paid_by: string, currency: string, declared_value: float, account_number: string>, duty_billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, content_type: string, content_description: string, incoterm: string, invoice: string, invoice_date: string, commercial_invoice: bool, certify: bool, signer: string, options: record>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>, reference: string, order_id: string, label_type: string, carrier_ids: list<string>, tracker_id: string, created_at: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list<record>, estimated_delivery: string, meta: record, test_mode: bool>, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: table<category: string, format: string, print_format: string, url: string, base64: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "carrier_name" $carrier_name "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "has_manifest" $has_manifest "scalar") (serialize-qp "has_tracker" $has_tracker "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "is_return" $is_return "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "meta_key" $meta_key "scalar") (serialize-qp "meta_value" $meta_value "scalar") (serialize-qp "metadata_key" $metadata_key "scalar") (serialize-qp "metadata_value" $metadata_value "scalar") (serialize-qp "option_key" $option_key "scalar") (serialize-qp "option_value" $option_value "scalar") (serialize-qp "order_id" $order_id "scalar") (serialize-qp "reference" $reference "scalar") (serialize-qp "request_id" $request_id "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tracking_number" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/shipments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a shipment
#
# POST /v1/shipments
# operationId: $$$$$create
# --parcels item shape: {weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record}
export def "shipments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  recipient: any # The address of the party.<br/>         Origin address (ship from) for the **shipper**<br/>         Destination address (ship to) for the **recipient**         
  shipper: any # The address of the party.<br/>         Origin address (ship from) for the **shipper**<br/>         Destination address (ship to) for the **recipient**         
  --return-address: any # The return address for this shipment. Defaults to the shipper address. (nullable)
  --billing-address: any # The payor address. (nullable)
  parcels: list # The shipment's parcels — item shape: {weight: float, width?: float, height?: float, length?: float, packaging_type?: string, package_preset?: string, description?: string, content?: string, is_document?: bool, weight_unit: "KG"|"LB"|"OZ"|"G", dimension_unit?: "CM"|"IN"|"", items?: list, reference_number?: string, freight_class?: string, options?: record, meta?: record}
  --options: record # <details>         <summary>The options available for the shipment.</summary>          {             "currency": "USD",             "insurance": 100.00,             "cash_on_delivery": 30.00,             "dangerous_good": true,             "declared_value": 150.00,             "sms_notification": true,             "email_notification": true,             "email_notification_to": "shipper@mail.com",             "hold_at_location": true,             "paperless_trade": true,             "preferred_service": "fedex_express_saver",             "shipment_date": "2020-01-01",  # TODO: deprecate             "shipping_date": "2020-01-01T00:00",             "shipment_note": "This is a shipment note",             "signature_confirmation": true,             "saturday_delivery": true,             "shipper_instructions": "This is a shipper instruction",             "recipient_instructions": "This is a recipient instruction",             "doc_files": [                 {                     "doc_type": "commercial_invoice",                     "doc_file": "base64 encoded file",                     "doc_name": "commercial_invoice.pdf",                     "doc_format": "pdf",                 }             ],             "doc_references": [                 {                     "doc_id": "123456789",                     "doc_type": "commercial_invoice",                 }             ],         }         </details>          (default: {})
  --payment: any # The payment details (default: {paid_by: sender, currency: , account_number: })
  --customs: any # The customs details.<br/>         **Note that this is required for the shipment of an international Dutiable parcel.**          (nullable)
  --reference: string # The shipment reference (nullable)
  --order-id: string # The order identifier associated with this shipment (nullable)
  --label-type: string@label-type-completer # The shipment label file type. (default: PDF)
  --is-return: oneof<nothing, bool> # Indicates whether this shipment is a return shipment. When true, addresses are auto-swapped and the request is routed to the carrier's return shipment API. (default: false)
  --service: string # **Specify a service to Buy a label in one call without rating.**
  --services: list # The requested carrier service for the shipment.<br/>         Please consult the reference for specific carriers services.<br/>         **Note that this is a list because on a Multi-carrier rate request         you could specify a service per carrier.**          (nullable, default: [])
  --carrier-ids: list # The list of configured carriers you wish to get rates from.<br/>         **Note that the request will be sent to all carriers in nothing is specified**          (nullable, default: [])
  --metadata: record # User metadata for the shipment (default: {})
]: any -> record<id: string, object_type: string, tracking_url: string, shipper: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, recipient: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, return_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, services: list<string>, options: record, payment: record<paid_by: string, currency: string, account_number: string>, customs: record<commodities: list<record>, duty: record<paid_by: string, currency: string, declared_value: float, account_number: string>, duty_billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, content_type: string, content_description: string, incoterm: string, invoice: string, invoice_date: string, commercial_invoice: bool, certify: bool, signer: string, options: record>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>, reference: string, order_id: string, label_type: string, carrier_ids: list<string>, tracker_id: string, created_at: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list<record>, estimated_delivery: string, meta: record, test_mode: bool>, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: table<category: string, format: string, print_format: string, url: string, base64: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/shipments")
  let body = {recipient: $recipient, shipper: $shipper, return_address: $return_address, billing_address: $billing_address, parcels: $parcels, options: $options, payment: $payment, customs: $customs, reference: $reference, order_id: $order_id, label_type: $label_type, is_return: $is_return, service: $service, services: $services, carrier_ids: $carrier_ids, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a shipment
#
# GET /v1/shipments/{id}
# operationId: $$$$$retrieve
export def "shipments retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, tracking_url: string, shipper: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, recipient: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, return_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, services: list<string>, options: record, payment: record<paid_by: string, currency: string, account_number: string>, customs: record<commodities: list<record>, duty: record<paid_by: string, currency: string, declared_value: float, account_number: string>, duty_billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, content_type: string, content_description: string, incoterm: string, invoice: string, invoice_date: string, commercial_invoice: bool, certify: bool, signer: string, options: record>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>, reference: string, order_id: string, label_type: string, carrier_ids: list<string>, tracker_id: string, created_at: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list<record>, estimated_delivery: string, meta: record, test_mode: bool>, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: table<category: string, format: string, print_format: string, url: string, base64: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a shipment
#
# PUT /v1/shipments/{id}
# operationId: $$$$$update
export def "shipments update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --label-type: string@label-type-completer # The shipment label file type. (default: PDF)
  --payment: any # The payment details
  --options: record # <details>         <summary>The options available for the shipment.</summary>          {             "currency": "USD",             "insurance": 100.00,             "cash_on_delivery": 30.00,             "dangerous_good": true,             "declared_value": 150.00,             "sms_notification": true,             "email_notification": true,             "email_notification_to": "shipper@mail.com",             "hold_at_location": true,             "paperless_trade": true,             "preferred_service": "fedex_express_saver",             "shipment_date": "2020-01-01",  # TODO: deprecate             "shipping_date": "2020-01-01T00:00",             "shipment_note": "This is a shipment note",             "signature_confirmation": true,             "saturday_delivery": true,             "shipping_charges": 10.00,             "doc_files": [                 {                     "doc_type": "commercial_invoice",                     "doc_file": "base64 encoded file",                     "doc_name": "commercial_invoice.pdf",                     "doc_format": "pdf",                 }             ],             "doc_references": [                 {                     "doc_id": "123456789",                     "doc_type": "commercial_invoice",                 }             ],         }         </details>          (default: {})
  --reference: string # The shipment reference (nullable)
  --order-id: string # The order identifier associated with this shipment (nullable)
  --metadata: record # User metadata for the shipment
]: any -> record<id: string, object_type: string, tracking_url: string, shipper: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, recipient: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, return_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, services: list<string>, options: record, payment: record<paid_by: string, currency: string, account_number: string>, customs: record<commodities: list<record>, duty: record<paid_by: string, currency: string, declared_value: float, account_number: string>, duty_billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, content_type: string, content_description: string, incoterm: string, invoice: string, invoice_date: string, commercial_invoice: bool, certify: bool, signer: string, options: record>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>, reference: string, order_id: string, label_type: string, carrier_ids: list<string>, tracker_id: string, created_at: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list<record>, estimated_delivery: string, meta: record, test_mode: bool>, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: table<category: string, format: string, print_format: string, url: string, base64: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($id)")
  let body = {label_type: $label_type, payment: $payment, options: $options, reference: $reference, order_id: $order_id, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a shipment
#
# POST /v1/shipments/{id}/cancel
# operationId: $$$$$cancel
export def "shipments-cancel cancel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object_type: string, tracking_url: string, shipper: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, recipient: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, return_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, services: list<string>, options: record, payment: record<paid_by: string, currency: string, account_number: string>, customs: record<commodities: list<record>, duty: record<paid_by: string, currency: string, declared_value: float, account_number: string>, duty_billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, content_type: string, content_description: string, incoterm: string, invoice: string, invoice_date: string, commercial_invoice: bool, certify: bool, signer: string, options: record>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>, reference: string, order_id: string, label_type: string, carrier_ids: list<string>, tracker_id: string, created_at: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list<record>, estimated_delivery: string, meta: record, test_mode: bool>, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: table<category: string, format: string, print_format: string, url: string, base64: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a shipment document
#
# POST /v1/shipments/{id}/documents/{doc}
# operationId: $$$$$document
export def "shipments-documents document" [
  doc: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<category: string, format: string, print_format: string, url: string, base64: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($id)/documents/($doc)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Buy a shipment label
#
# POST /v1/shipments/{id}/purchase
# operationId: $$$$$purchase
export def "shipments-purchase purchase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --selected-rate-id: string # The shipment selected rate. (nullable)
  --service: string # The carrier service to use for the shipment (alternative to selected_rate_id). (nullable)
  --label-type: string@label-type-completer # The shipment label file type. (default: PDF)
  --payment: any # The payment details
  --reference: string # The shipment reference (nullable)
  --metadata: record # User metadata for the shipment
]: any -> record<id: string, object_type: string, tracking_url: string, shipper: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, recipient: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, return_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, services: list<string>, options: record, payment: record<paid_by: string, currency: string, account_number: string>, customs: record<commodities: list<record>, duty: record<paid_by: string, currency: string, declared_value: float, account_number: string>, duty_billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, content_type: string, content_description: string, incoterm: string, invoice: string, invoice_date: string, commercial_invoice: bool, certify: bool, signer: string, options: record>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>, reference: string, order_id: string, label_type: string, carrier_ids: list<string>, tracker_id: string, created_at: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list<record>, estimated_delivery: string, meta: record, test_mode: bool>, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: table<category: string, format: string, print_format: string, url: string, base64: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($id)/purchase")
  let body = {selected_rate_id: $selected_rate_id, service: $service, label_type: $label_type, payment: $payment, reference: $reference, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch new shipment rates
#
# POST /v1/shipments/{id}/rates
# operationId: $$$$$rates
export def "shipments-rates rates" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --services: list # The requested carrier service for the shipment.<br/>         Please consult [the reference](#operation/references) for specific carriers services.<br/>         **Note that this is a list because on a Multi-carrier rate request you could         specify a service per carrier.**          (nullable)
  --carrier-ids: list # The list of configured carriers you wish to get rates from.<br/>         **Note that the request will be sent to all carriers in nothing is specified**          (nullable)
  --options: record # <details>         <summary>The options available for the shipment.</summary>          {             "currency": "USD",             "insurance": 100.00,             "insured_by": "carrier",             "cash_on_delivery": 30.00,             "dangerous_good": true,             "declared_value": 150.00,             "sms_notification": true,             "email_notification": true,             "email_notification_to": "shipper@mail.com",             "hold_at_location": true,             "locker_id": "123456789",             "paperless_trade": true,             "preferred_service": "fedex_express_saver",             "shipment_date": "2020-01-01",  # TODO: deprecate             "shipping_date": "2020-01-01T00:00",             "shipment_note": "This is a shipment note",             "signature_confirmation": true,             "saturday_delivery": true,             "shipping_charges": 10.00,             "doc_files": [                 {                     "doc_type": "commercial_invoice",                     "doc_file": "base64 encoded file",                     "doc_name": "commercial_invoice.pdf",                     "doc_format": "pdf",                 }             ],             "doc_references": [                 {                     "doc_id": "123456789",                     "doc_type": "commercial_invoice",                 }             ],         }         </details>          (default: {})
  --reference: string # The shipment reference (nullable)
  --metadata: record # User metadata for the shipment
]: any -> record<id: string, object_type: string, tracking_url: string, shipper: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, recipient: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, return_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record, object_type: string, validation: record<success: bool, meta: record>>, parcels: table<id: string, weight: float, width: float, height: float, length: float, packaging_type: string, package_preset: string, description: string, content: string, is_document: bool, weight_unit: string, dimension_unit: string, items: list, reference_number: string, freight_class: string, options: record, meta: record, object_type: string>, services: list<string>, options: record, payment: record<paid_by: string, currency: string, account_number: string>, customs: record<commodities: list<record>, duty: record<paid_by: string, currency: string, declared_value: float, account_number: string>, duty_billing_address: record<id: string, postal_code: string, city: string, federal_tax_id: string, state_tax_id: string, person_name: string, company_name: string, country_code: string, email: string, phone_number: string, state_code: string, residential: bool, street_number: string, address_line1: string, address_line2: string, validate_location: bool, meta: record>, content_type: string, content_description: string, incoterm: string, invoice: string, invoice_date: string, commercial_invoice: bool, certify: bool, signer: string, options: record>, rates: table<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list, estimated_delivery: string, meta: record, test_mode: bool>, reference: string, order_id: string, label_type: string, carrier_ids: list<string>, tracker_id: string, created_at: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, status: string, carrier_name: string, carrier_id: string, tracking_number: string, shipment_identifier: string, selected_rate: record<id: string, object_type: string, carrier_name: string, carrier_id: string, currency: string, service: string, total_charge: float, transit_days: int, extra_charges: list<record>, estimated_delivery: string, meta: record, test_mode: bool>, meta: record, return_shipment: record, service: string, selected_rate_id: string, test_mode: bool, is_return: bool, label_url: string, invoice_url: string, shipping_documents: table<category: string, format: string, print_format: string, url: string, base64: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($id)/rates")
  let body = {services: $services, carrier_ids: $carrier_ids, options: $options, reference: $reference, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all package trackers
#
# GET /v1/trackers
# operationId: $$$$$$list
export def "trackers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier-name: string # The unique carrier slug. <br/>Values: `aramex`, `asendia`, `asendia_us`, `australiapost`, `boxknight`, `bpost`, `canadapost`, `canpar`, `chronopost`, `colissimo`, `dhl_express`, `dhl_parcel_de`, `dhl_poland`, `dhl_universal`, `dicom`, `dpd`, `dpd_meta`, `dtdc`, `easypost`, `easyship`, `eshipper`, `fedex`, `freightcom`, `generic`, `geodis`, `gls`, `hay_post`, `hermes`, `landmark`, `laposte`, `locate2u`, `mydhl`, `nationex`, `parcelone`, `postat`, `purolator`, `roadie`, `royalmail`, `sapient`, `seko`, `sendle`, `shipengine`, `spring`, `teleship`, `tge`, `tnt`, `ups`, `usps`, `usps_international`, `veho`, `zoom2u`
  --created-after: string # format: date-time
  --created-before: string # format: date-time
  --keyword: string
  --request-id: string
  --status: string # Valid tracker status. <br/>Values: `pending`, `picked_up`, `unknown`, `on_hold`, `cancelled`, `delivered`, `in_transit`, `delivery_delayed`, `out_for_delivery`, `ready_for_pickup`, `delivery_failed`, `return_to_sender`
  --tracking-number: string
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, carrier_name: string, carrier_id: string, tracking_number: string, info: record, events: list, delivered: bool, test_mode: bool, status: string, estimated_delivery: string, meta: record, object_type: string, metadata: record, messages: list, delivery_image_url: string, signature_image_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_name" $carrier_name "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "request_id" $request_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tracking_number" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/trackers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a package tracker
#
# POST /v1/trackers
# operationId: $$$$$$add
export def "trackers add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hub: string
  --pending-pickup: oneof<nothing, bool> # Add this flag to add the tracker whether the tracking info exist or not.When the package is eventually picked up, the tracker with capture real time updates.
  tracking_number: string # The package tracking number
  carrier_name: string@carrier-name-completer-1 # The tracking carrier
  --account-number: string # The shipper account number (nullable)
  --reference: string # The shipment reference (nullable)
  --info: any # The package and shipment tracking details (nullable)
  --metadata: record # The carrier user metadata. (default: {})
]: any -> record<id: string, carrier_name: string, carrier_id: string, tracking_number: string, info: record<carrier_tracking_link: string, customer_name: string, expected_delivery: string, note: string, order_date: string, order_id: string, package_weight: string, package_weight_unit: string, shipment_package_count: string, shipment_pickup_date: string, shipment_delivery_date: string, shipment_service: string, shipment_origin_country: string, shipment_origin_postal_code: string, shipment_destination_country: string, shipment_destination_postal_code: string, shipping_date: string, signed_by: string, source: string>, events: table<date: string, time: string, timestamp: string, status: string, code: string, reason: string, description: string, location: string, latitude: float, longitude: float>, delivered: bool, test_mode: bool, status: string, estimated_delivery: string, meta: record, object_type: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, delivery_image_url: string, signature_image_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hub" $hub "scalar") (serialize-qp "pending_pickup" $pending_pickup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/trackers" $qp)
  let body = {tracking_number: $tracking_number, carrier_name: $carrier_name, account_number: $account_number, reference: $reference, info: $info, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a package tracker
#
# GET /v1/trackers/{carrier_name}/{tracking_number}
# DEPRECATED
# operationId: $$$$$$create
@deprecated
export def "trackers create" [
  carrier_name: string
  tracking_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --carrier-name: string@carrier-name-completer-1
  --hub: string
]: nothing -> record<id: string, carrier_name: string, carrier_id: string, tracking_number: string, info: record<carrier_tracking_link: string, customer_name: string, expected_delivery: string, note: string, order_date: string, order_id: string, package_weight: string, package_weight_unit: string, shipment_package_count: string, shipment_pickup_date: string, shipment_delivery_date: string, shipment_service: string, shipment_origin_country: string, shipment_origin_postal_code: string, shipment_destination_country: string, shipment_destination_postal_code: string, shipping_date: string, signed_by: string, source: string>, events: table<date: string, time: string, timestamp: string, status: string, code: string, reason: string, description: string, location: string, latitude: float, longitude: float>, delivered: bool, test_mode: bool, status: string, estimated_delivery: string, meta: record, object_type: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, delivery_image_url: string, signature_image_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_name" $carrier_name "scalar") (serialize-qp "hub" $hub "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/trackers/($carrier_name)/($tracking_number)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a package tracker
#
# GET /v1/trackers/{id_or_tracking_number}
# operationId: $$$$$$retrieve
export def "trackers retrieve" [
  id_or_tracking_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, carrier_name: string, carrier_id: string, tracking_number: string, info: record<carrier_tracking_link: string, customer_name: string, expected_delivery: string, note: string, order_date: string, order_id: string, package_weight: string, package_weight_unit: string, shipment_package_count: string, shipment_pickup_date: string, shipment_delivery_date: string, shipment_service: string, shipment_origin_country: string, shipment_origin_postal_code: string, shipment_destination_country: string, shipment_destination_postal_code: string, shipping_date: string, signed_by: string, source: string>, events: table<date: string, time: string, timestamp: string, status: string, code: string, reason: string, description: string, location: string, latitude: float, longitude: float>, delivered: bool, test_mode: bool, status: string, estimated_delivery: string, meta: record, object_type: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, delivery_image_url: string, signature_image_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trackers/($id_or_tracking_number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tracker data
#
# PUT /v1/trackers/{id_or_tracking_number}
# operationId: $$$$$$update
export def "trackers update" [
  id_or_tracking_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --info: any # The package and shipment tracking details (nullable)
  --metadata: record # User metadata for the tracker
]: any -> record<id: string, carrier_name: string, carrier_id: string, tracking_number: string, info: record<carrier_tracking_link: string, customer_name: string, expected_delivery: string, note: string, order_date: string, order_id: string, package_weight: string, package_weight_unit: string, shipment_package_count: string, shipment_pickup_date: string, shipment_delivery_date: string, shipment_service: string, shipment_origin_country: string, shipment_origin_postal_code: string, shipment_destination_country: string, shipment_destination_postal_code: string, shipping_date: string, signed_by: string, source: string>, events: table<date: string, time: string, timestamp: string, status: string, code: string, reason: string, description: string, location: string, latitude: float, longitude: float>, delivered: bool, test_mode: bool, status: string, estimated_delivery: string, meta: record, object_type: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, delivery_image_url: string, signature_image_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trackers/($id_or_tracking_number)")
  let body = {info: $info, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Discard a package tracker
#
# DELETE /v1/trackers/{id_or_tracking_number}
# operationId: $$$$$$remove
export def "trackers remove" [
  id_or_tracking_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, carrier_name: string, carrier_id: string, tracking_number: string, info: record<carrier_tracking_link: string, customer_name: string, expected_delivery: string, note: string, order_date: string, order_id: string, package_weight: string, package_weight_unit: string, shipment_package_count: string, shipment_pickup_date: string, shipment_delivery_date: string, shipment_service: string, shipment_origin_country: string, shipment_origin_postal_code: string, shipment_destination_country: string, shipment_destination_postal_code: string, shipping_date: string, signed_by: string, source: string>, events: table<date: string, time: string, timestamp: string, status: string, code: string, reason: string, description: string, location: string, latitude: float, longitude: float>, delivered: bool, test_mode: bool, status: string, estimated_delivery: string, meta: record, object_type: string, metadata: record, messages: table<message: string, code: string, level: string, details: record, carrier_name: string, carrier_id: string>, delivery_image_url: string, signature_image_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trackers/($id_or_tracking_number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inject tracking events
#
# POST /v1/trackers/{tracker_id}/inject-events
# operationId: $$$$$$inject
# --events item shape: {date?: string, time?: string, timestamp?: string, status?: "pending"|"picked_up"|"unknown"|"on_hold"|"cancelled"|"delivered"|"in_transit"|"delivery_delayed"|"out_for_delivery"|"ready_for_pickup"|"delivery_failed"|"return_to_sender"|""|"", code?: string, reason?: "carrier_damaged_parcel"|"carrier_sorting_error"|"carrier_address_not_found"|"carrier_parcel_lost"|"carrier_not_enough_time"|"carrier_vehicle_issue"|"carrier_capacity_exceeded"|"carrier_mechanical_delay"|"retailer_cancelled"|"retailer_incorrect_data"|"retailer_not_ready"|"retailer_incorrect_parcel"|"retailer_incorrect_dimensions"|"retailer_packaging_issue"|"consignee_refused"|"consignee_business_closed"|"consignee_not_available"|"consignee_not_home"|"consignee_cancelled"|"consignee_verification_failed"|"consignee_incorrect_address"|"consignee_access_restricted"|"consignee_safe_place_unavailable"|"customs_delay"|"customs_documentation"|"customs_duties_unpaid"|"customs_prohibited"|"customs_inspection"|"weather_delay"|"natural_disaster"|"force_majeure"|"parcel_being_researched"|"security_issue"|"regulatory_hold"|"unknown"|""|"", description?: string, location?: string, latitude?: float, longitude?: float}
export def "trackers-inject-events inject" [
  tracker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list # List of tracking events to inject into the tracker — item shape: {date?: string, time?: string, timestamp?: string, status?: "pending"|"picked_up"|"unknown"|"on_hold"|"cancelled"|"delivered"|"in_transit"|"delivery_delayed"|"out_for_delivery"|"ready_for_pickup"|"delivery_failed"|"return_to_sender"|""|"", code?: string, reason?: "carrier_damaged_parcel"|"carrier_sorting_error"|"carrier_address_not_found"|"carrier_parcel_lost"|"carrier_not_enough_time"|"carrier_vehicle_issue"|"carrier_capacity_exceeded"|"carrier_mechanical_delay"|"retailer_cancelled"|"retailer_incorrect_data"|"retailer_not_ready"|"retailer_incorrect_parcel"|"retailer_incorrect_dimensions"|"retailer_packaging_issue"|"consignee_refused"|"consignee_business_closed"|"consignee_not_available"|"consignee_not_home"|"consignee_cancelled"|"consignee_verification_failed"|"consignee_incorrect_address"|"consignee_access_restricted"|"consignee_safe_place_unavailable"|"customs_delay"|"customs_documentation"|"customs_duties_unpaid"|"customs_prohibited"|"customs_inspection"|"weather_delay"|"natural_disaster"|"force_majeure"|"parcel_being_researched"|"security_issue"|"regulatory_hold"|"unknown"|""|"", description?: string, location?: string, latitude?: float, longitude?: float}
  --status: string@status-completer # Optional: Override the tracker status (nullable)
  --delivered: oneof<nothing, bool> # Optional: Mark the tracker as delivered (default: false)
  --estimated-delivery: string # Optional: Set the estimated delivery date (nullable, format: date)
]: any -> record<operation: string, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trackers/($tracker_id)/inject-events")
  let body = {events: $events, status: $status, delivered: $delivered, estimated_delivery: $estimated_delivery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all webhooks
#
# GET /v1/webhooks
# operationId: $$$$$$$list
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, url: string, description: string, enabled_events: list, disabled: bool, object_type: string, last_event_at: string, secret: string, test_mode: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /v1/webhooks
# operationId: $$$$$$$create
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The URL of the webhook endpoint. (format: uri)
  --description: string # An optional description of what the webhook is used for. (nullable)
  enabled_events: list # The list of events to enable for this endpoint.
  --disabled: oneof<nothing, bool> # Indicates that the webhook is disabled (nullable)
]: any -> record<id: string, url: string, description: string, enabled_events: list<string>, disabled: bool, object_type: string, last_event_at: string, secret: string, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webhooks")
  let body = {url: $body_url, description: $description, enabled_events: $enabled_events, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a webhook
#
# GET /v1/webhooks/{id}
# operationId: $$$$$$$retrieve
export def "webhooks retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, url: string, description: string, enabled_events: list<string>, disabled: bool, object_type: string, last_event_at: string, secret: string, test_mode: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /v1/webhooks/{id}
# operationId: $$$$$$$update
export def "webhooks update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The URL of the webhook endpoint. (format: uri)
  --description: string # An optional description of what the webhook is used for. (nullable)
  --enabled-events: list # The list of events to enable for this endpoint.
  --disabled: oneof<nothing, bool> # Indicates that the webhook is disabled (nullable)
]: any -> record<id: string, url: string, description: string, enabled_events: list<string>, disabled: bool, object_type: string, last_event_at: string, secret: string, test_mode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($id)")
  let body = {url: $body_url, description: $description, enabled_events: $enabled_events, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a webhook
#
# DELETE /v1/webhooks/{id}
# operationId: $$$$$$$remove
export def "webhooks remove" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<operation: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test a webhook
#
# POST /v1/webhooks/{id}/test
# operationId: $$$$$$$test
export def "webhooks-test test" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payload: record
  --event-id: string
]: any -> record<operation: string, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($id)/test")
  let body = {payload: $payload, event_id: $event_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
