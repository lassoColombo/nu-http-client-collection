# Auto-generated client for Neutrino API v3.6.3
# Source: https://api.apis.guru/v2/specs/neutrinoapi.net/3.6.3/openapi.json
# Auth: --token flag or $env.NEUTRINO_API_TOKEN

const BASE_URL = "https://neutrinoapi.net"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NEUTRINO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {api-key: $token_val}, query: ""} }
    "user-id" => { {headers: {user-id: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://neutrinoapi.net"] }
def auth-scheme-completer [] { ["api-key" "user-id"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bad-word-filter create" } } | get name | first)
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

# Bad Word Filter
#
# POST /bad-word-filter
# operationId: BadWordFilter
export def "bad-word-filter create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog: string # Which catalog of bad words to use, we currently maintain two bad word catalogs: strict - the largest database of bad words which includes profanity, obscenity, sexual, rude, cuss, dirty, swear and objectionable words and phrases. This catalog is suitable for environments of all ages including educational or children's content obscene - like the strict catalog but does not include any mild profanities, idiomatic phrases or words which are considered formal terminology. This catalog is suitable for adult environments where certain types of bad words are considered OK (default: strict)
  --censor-character: string # The character to use to censor out the bad words found
  content: string # The content to scan. This can be either a URL to load from, a file upload (multipart/form-data) or an HTML content string
]: any -> record<bad_words_list: list<string>, bad_words_total: int, censored_content: string, is_bad: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bad-word-filter")
  let req_body = {"catalog": $catalog, "censor-character": $censor_character, "content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# BIN List Download
#
# GET /bin-list-download
# operationId: BINListDownload
export def "bin-list-download list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-iso3: oneof<nothing, bool> # Include ISO 3-letter country codes and ISO 3-letter currency codes in the data. These will be added to columns 10 and 11 respectively (default: false)
  --include-8digit: oneof<nothing, bool> # Include 8-digit and higher BIN codes. This option includes all 6-digit BINs and all 8-digit and higher BINs (including some 9, 10 and 11 digit BINs where available) (default: false)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include-iso3" $include_iso3 "scalar") (serialize-qp "include-8digit" $include_8digit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bin-list-download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# BIN Lookup
#
# GET /bin-lookup
# operationId: BINLookup
export def "bin-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bin-number: string # The BIN or IIN number. This is the first 6, 8 or 10 digits of a card number, use 8 (or more) digits for the highest level of accuracy
  --customer-ip: string # Pass in the customers IP address and we will return some extra information about them
]: nothing -> record<bin_number: string, card_brand: string, card_category: string, card_type: string, country: string, country_code: string, country_code3: string, currency_code: string, ip_blocklisted: bool, ip_blocklists: list<string>, ip_city: string, ip_country: string, ip_country_code: string, ip_country_code3: string, ip_matches_bin: bool, ip_region: string, is_commercial: bool, is_prepaid: bool, issuer: string, issuer_phone: string, issuer_website: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bin-number" $bin_number "scalar") (serialize-qp "customer-ip" $customer_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bin-lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Browser Bot
#
# POST /browser-bot
# operationId: BrowserBot
export def "browser-bot create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delay: int # Delay in seconds to wait before capturing any page data, executing selectors or JavaScript (format: int32, default: 3)
  --exec: list<string> # Execute JavaScript on the website. This parameter accepts JavaScript as either a string containing JavaScript or for sending multiple separate statements a JSON array or POST array can also be used. If a statement returns any value it will be returned in the 'exec-results' response. You can also use the following specially defined user interaction functions: sleep(seconds); Just wait/sleep for the specified number of seconds. click('selector'); Click on the first element matching the given selector. focus('selector'); Focus on the first element matching the given selector. keys('characters'); Send the specified keyboard characters. Use click() or focus() first to send keys to a specific element. enter(); Send the Enter key. tab(); Send the Tab key. (default: [])
  --ignore-certificate-errors: oneof<nothing, bool> # Ignore any TLS/SSL certificate errors and load the page anyway (default: false)
  --selector: string # Extract content from the page DOM using this selector. Commonly known as a CSS selector, you can find a good reference here (https://www.w3schools.com/cssref/css_selectors.asp)
  --timeout: int # Timeout in seconds. Give up if still trying to load the page after this number of seconds (format: int32, default: 30)
  url: string # The URL to load
  --user-agent: string # Override the browsers default user-agent string with this one
]: any -> record<content: string, elements: list<string>, error_message: string, exec_results: list<string>, http_redirect_url: string, http_status_code: int, http_status_message: string, is_error: bool, is_http_ok: bool, is_http_redirect: bool, is_secure: bool, is_timeout: bool, language_code: string, load_time: float, mime_type: string, response_headers: record, security_details: record, server_ip: string, title: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/browser-bot")
  let req_body = {"delay": $delay, "exec": $exec, "ignore-certificate-errors": $ignore_certificate_errors, "selector": $selector, "timeout": $timeout, "url": $url, "user-agent": $user_agent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Convert
#
# GET /convert
# operationId: Convert
export def "convert get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-value: string # The value to convert from (e.g. 10.95)
  --from-type: string # The type of the value to convert from (e.g. USD)
  --to-type: string # The type to convert to (e.g. EUR)
]: nothing -> record<from_type: string, from_value: string, result: string, result_float: float, to_type: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from-value" $from_value "scalar") (serialize-qp "from-type" $from_type "scalar") (serialize-qp "to-type" $to_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/convert" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Email Validate
#
# GET /email-validate
# operationId: EmailValidate
export def "email-validate validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # An email address
  --fix-typos: oneof<nothing, bool> # Automatically attempt to fix typos in the address (default: false)
]: nothing -> record<domain: string, domain_error: bool, email: string, is_disposable: bool, is_freemail: bool, is_personal: bool, provider: string, syntax_error: bool, typos_fixed: bool, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "fix-typos" $fix_typos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email-validate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Email Verify
#
# GET /email-verify
# operationId: EmailVerify
export def "email-verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # An email address
  --fix-typos: oneof<nothing, bool> # Automatically attempt to fix typos in the address (default: false)
]: nothing -> record<domain: string, domain_error: bool, email: string, is_catch_all: bool, is_deferred: bool, is_disposable: bool, is_freemail: bool, is_personal: bool, provider: string, smtp_response: string, smtp_status: string, syntax_error: bool, typos_fixed: bool, valid: bool, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "fix-typos" $fix_typos "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email-verify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Geocode Address
#
# GET /geocode-address
# operationId: GeocodeAddress
export def "geocode-address get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The full address, partial address or name of a place to try and locate. Comma separated address components are preferred.
  --house-number: string # The house/building number to locate
  --street: string # The street/road name to locate
  --city: string # The city/town name to locate
  --county: string # The county/region name to locate
  --state: string # The state name to locate
  --postal-code: string # The postal code to locate
  --country-code: string # Limit result to this country (the default is no country bias)
  --language-code: string # The language to display results in, available languages are: de, en, es, fr, it, pt, ru, zh (default: en)
  --fuzzy-search: oneof<nothing, bool> # If no matches are found for the given address, start performing a recursive fuzzy search until a geolocation is found. This option is recommended for processing user input or implementing auto-complete. We use a combination of approximate string matching and data cleansing to find possible location matches (default: false)
]: nothing -> record<found: int, locations: table<address: string, address_components: record, city: string, country: string, country_code: string, country_code3: string, currency_code: string, latitude: float, location_tags: list, location_type: string, longitude: float, postal_address: string, postal_code: string, region_code: string, state: string, timezone: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "house-number" $house_number "scalar") (serialize-qp "street" $street "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "postal-code" $postal_code "scalar") (serialize-qp "country-code" $country_code "scalar") (serialize-qp "language-code" $language_code "scalar") (serialize-qp "fuzzy-search" $fuzzy_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocode-address" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Geocode Reverse
#
# GET /geocode-reverse
# operationId: GeocodeReverse
export def "geocode-reverse get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: string # The location latitude in decimal degrees format
  --longitude: string # The location longitude in decimal degrees format
  --language-code: string # The language to display results in, available languages are: de, en, es, fr, it, pt, ru (default: en)
  --zoom: string # The zoom level to respond with: address - the most precise address available street - the street level city - the city level state - the state level country - the country level (default: address)
]: nothing -> record<address: string, address_components: record, city: string, country: string, country_code: string, country_code3: string, currency_code: string, found: bool, latitude: float, location_tags: list<string>, location_type: string, longitude: float, postal_address: string, postal_code: string, region_code: string, state: string, timezone: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "language-code" $language_code "scalar") (serialize-qp "zoom" $zoom "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocode-reverse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# HLR Lookup
#
# GET /hlr-lookup
# operationId: HLRLookup
export def "hlr-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: string # A phone number
  --country-code: string # ISO 2-letter country code, assume numbers are based in this country. If not set numbers are assumed to be in international format (with or without the leading + sign)
]: nothing -> record<country: string, country_code: string, country_code3: string, currency_code: string, current_network: string, hlr_status: string, hlr_valid: bool, imsi: string, international_calling_code: string, international_number: string, is_mobile: bool, is_ported: bool, is_roaming: bool, local_number: string, location: string, mcc: string, mnc: string, msc: string, msin: string, number_type: string, number_valid: bool, origin_network: string, ported_network: string, roaming_country_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "country-code" $country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hlr-lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Host Reputation
#
# GET /host-reputation
# operationId: HostReputation
export def "host-reputation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string # An IP address, domain name, FQDN or URL. If you supply a domain/URL it will be checked against the URI DNSBL lists
  --list-rating: int # Only check lists with this rating or better (format: int32, default: 3)
  --zones: string # Only check these DNSBL zones/hosts. Multiple zones can be supplied as comma-separated values
]: nothing -> record<host: string, is_listed: bool, list_count: int, lists: table<is_listed: bool, list_host: string, list_name: string, list_rating: int, response_time: int, return_code: string, txt_record: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host" $host "scalar") (serialize-qp "list-rating" $list_rating "scalar") (serialize-qp "zones" $zones "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/host-reputation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# HTML Clean
#
# POST /html-clean
# operationId: HTMLClean
export def "html-clean create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The HTML content. This can be either a URL to load from, a file upload (multipart/form-data) or an HTML content string
  output_type: string # The level of sanitization, possible values are: plain-text: reduce the content to plain text only (no HTML tags at all) simple-text: allow only very basic text formatting tags like b, em, i, strong, u basic-html: allow advanced text formatting and hyper links basic-html-with-images: same as basic html but also allows image tags advanced-html: same as basic html with images but also allows many more common HTML tags like table, ul, dl, pre
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/html-clean")
  let req_body = {"content": $content, "output-type": $output_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# HTML Render
#
# POST /html-render
# operationId: HTMLRender
export def "html-render create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The HTML content. This can be either a URL to load from, a file upload (multipart/form-data) or an HTML content string
  --css: string # Inject custom CSS into the HTML. e.g. 'body { background-color: red;}'
  --delay: int # Number of seconds to wait before rendering the page (can be useful for pages with animations etc) (format: int32, default: 0)
  --footer: string # The footer HTML to insert into each page. The following dynamic tags are supported: {date}, {title}, {url}, {pageNumber}, {totalPages}
  --format: string # Which format to output, available options are: PDF, PNG, JPG (default: PDF)
  --grayscale: oneof<nothing, bool> # Render the final document in grayscale (default: false)
  --header: string # The header HTML to insert into each page. The following dynamic tags are supported: {date}, {title}, {url}, {pageNumber}, {totalPages}
  --ignore-certificate-errors: oneof<nothing, bool> # Ignore any TLS/SSL certificate errors (default: false)
  --image-height: int # If rendering to an image format (PNG or JPG) use this image height (in pixels). The default is automatic which dynamically sets the image height based on the content (format: int32)
  --image-width: int # If rendering to an image format (PNG or JPG) use this image width (in pixels) (format: int32, default: 1024)
  --landscape: oneof<nothing, bool> # Set the document to landscape orientation (default: false)
  --margin: float # The document margin (in mm) (format: double, default: 0)
  --margin-bottom: float # The document bottom margin (in mm) (format: double, default: 0)
  --margin-left: float # The document left margin (in mm) (format: double, default: 0)
  --margin-right: float # The document right margin (in mm) (format: double, default: 0)
  --margin-top: float # The document top margin (in mm) (format: double, default: 0)
  --page-height: float # Set the PDF page height explicitly (in mm) (format: double)
  --page-size: string # Set the document page size, can be one of: A0 - A9, B0 - B10, Comm10E, DLE or Letter (default: A4)
  --page-width: float # Set the PDF page width explicitly (in mm) (format: double)
  --timeout: int # Timeout in seconds. Give up if still trying to load the HTML content after this number of seconds (format: int32, default: 300)
  --title: string # The document title
  --zoom: float # Set the zoom factor when rendering the page (2.0 for double size, 0.5 for half size) (format: double, default: 1)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/html-render")
  let req_body = {"content": $content, "css": $css, "delay": $delay, "footer": $footer, "format": $format, "grayscale": $grayscale, "header": $header, "ignore-certificate-errors": $ignore_certificate_errors, "image-height": $image_height, "image-width": $image_width, "landscape": $landscape, "margin": $margin, "margin-bottom": $margin_bottom, "margin-left": $margin_left, "margin-right": $margin_right, "margin-top": $margin_top, "page-height": $page_height, "page-size": $page_size, "page-width": $page_width, "timeout": $timeout, "title": $title, "zoom": $zoom} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Image Resize
#
# POST /image-resize
# operationId: ImageResize
export def "image-resize resize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bg-color: string # The image background color in hexadecimal notation (e.g. #0000ff). For PNG output the special value of 'transparent' can also be used. For JPG output the default is black (#000000) (default: transparent)
  --format: string # The output image format, can be either png or jpg (default: png)
  --height: int # The height to resize to (in px). If you don't set this field then the height will be automatic based on the requested width and image aspect ratio (format: int32)
  image_url: string # The URL or Base64 encoded Data URL for the source image. You can also upload an image file directly using multipart/form-data
  --resize-mode: string # The resize mode to use, we support 3 main resizing modes: scaleResize to within the width and height specified while preserving aspect ratio. In this mode the width or height will be automatically adjusted to fit the aspect ratio padResize to exactly the width and height specified while preserving aspect ratio and pad any space left over. Any padded space will be filled in with the 'bg-color' value cropResize to exactly the width and height specified while preserving aspect ratio and crop any space which fall outside the area. The cropping window is centered on the original image (default: scale)
  width: int # The width to resize to (in px) (format: int32)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/image-resize")
  let req_body = {"bg-color": $bg_color, "format": $format, "height": $height, "image-url": $image_url, "resize-mode": $resize_mode, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Image Watermark
#
# POST /image-watermark
# operationId: ImageWatermark
export def "image-watermark create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bg-color: string # The image background color in hexadecimal notation (e.g. #0000ff). For PNG output the special value of 'transparent' can also be used. For JPG output the default is black (#000000) (default: transparent)
  --format: string # The output image format, can be either png or jpg (default: png)
  --height: int # If set resize the resulting image to this height (in px) (format: int32)
  image_url: string # The URL or Base64 encoded Data URL for the source image. You can also upload an image file directly using multipart/form-data
  --opacity: int # The opacity of the watermark (0 to 100) (format: int32, default: 50)
  --position: string # The position of the watermark image, possible values are: center, top-left, top-center, top-right, bottom-left, bottom-center, bottom-right (default: center)
  --resize-mode: string # The resize mode to use, we support 3 main resizing modes: scaleResize to within the width and height specified while preserving aspect ratio. In this mode the width or height will be automatically adjusted to fit the aspect ratio padResize to exactly the width and height specified while preserving aspect ratio and pad any space left over. Any padded space will be filled in with the 'bg-color' value cropResize to exactly the width and height specified while preserving aspect ratio and crop any space which fall outside the area. The cropping window is centered on the original image (default: scale)
  watermark_url: string # The URL or Base64 encoded Data URL for the watermark image. You can also upload an image file directly using multipart/form-data
  --width: int # If set resize the resulting image to this width (in px) (format: int32)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/image-watermark")
  let req_body = {"bg-color": $bg_color, "format": $format, "height": $height, "image-url": $image_url, "opacity": $opacity, "position": $position, "resize-mode": $resize_mode, "watermark-url": $watermark_url, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# IP Blocklist
#
# GET /ip-blocklist
# operationId: IPBlocklist
export def "ip-blocklist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # An IPv4 or IPv6 address. Accepts standard IP notation (with or without port number), CIDR notation and IPv6 compressed notation. If multiple IPs are passed using comma-separated values the first non-bogon address on the list will be checked
  --vpn-lookup: oneof<nothing, bool> # Include public VPN provider IP addresses. NOTE: For more advanced VPN detection including the ability to identify private and stealth VPNs use the IP Probe API (https://www.neutrinoapi.com/api/ip-probe/) (default: false)
]: nothing -> record<blocklists: list<string>, cidr: string, ip: string, is_bot: bool, is_dshield: bool, is_exploit_bot: bool, is_hijacked: bool, is_listed: bool, is_malware: bool, is_proxy: bool, is_spam_bot: bool, is_spider: bool, is_spyware: bool, is_tor: bool, is_vpn: bool, last_seen: int, list_count: int, sensors: table<blocklist: string, description: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar") (serialize-qp "vpn-lookup" $vpn_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip-blocklist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# IP Blocklist Download
#
# GET /ip-blocklist-download
# operationId: IPBlocklistDownload
export def "ip-blocklist-download download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # The data format. Can be either CSV or TXT (default: csv)
  --include-vpn: oneof<nothing, bool> # Include public VPN provider addresses, this option is only available for Tier 3 or higher accounts. Adds any IPs which are solely listed as VPN providers, IPs that are listed on multiple sensors will still be included without enabling this option. WARNING: This adds at least an additional 8 million IP addresses to the download if not using CIDR notation (default: false)
  --cidr: oneof<nothing, bool> # Output IPs using CIDR notation. This option should be preferred but is off by default for backwards compatibility (default: false)
  --ip6: oneof<nothing, bool> # Output the IPv6 version of the blocklist, the default is to output IPv4 only. Note that this option enables CIDR notation too as this is the only notation currently supported for IPv6 (default: false)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "include-vpn" $include_vpn "scalar") (serialize-qp "cidr" $cidr "scalar") (serialize-qp "ip6" $ip6 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip-blocklist-download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# IP Info
#
# GET /ip-info
# operationId: IPInfo
export def "ip-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # IPv4 or IPv6 address
  --reverse-lookup: oneof<nothing, bool> # Do a reverse DNS (PTR) lookup. This option can add extra delay to the request so only use it if you need it (default: false)
]: nothing -> record<city: string, continent_code: string, country: string, country_code: string, country_code3: string, currency_code: string, host_domain: string, hostname: string, ip: string, is_bogon: bool, is_v4_mapped: bool, is_v6: bool, latitude: float, longitude: float, region: string, region_code: string, timezone: record, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar") (serialize-qp "reverse-lookup" $reverse_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# IP Probe
#
# GET /ip-probe
# operationId: IPProbe
export def "ip-probe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # IPv4 or IPv6 address
]: nothing -> record<as_age: int, as_cidr: string, as_country_code: string, as_country_code3: string, as_description: string, as_domains: list<string>, asn: string, city: string, continent_code: string, country: string, country_code: string, country_code3: string, currency_code: string, host_domain: string, hostname: string, ip: string, is_bogon: bool, is_hosting: bool, is_isp: bool, is_proxy: bool, is_v4_mapped: bool, is_v6: bool, is_vpn: bool, provider_description: string, provider_domain: string, provider_type: string, provider_website: string, region: string, region_code: string, valid: bool, vpn_domain: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip-probe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Phone Playback
#
# POST /phone-playback
# operationId: PhonePlayback
export def "phone-playback create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  audio_url: string # A URL to a valid audio file. Accepted audio formats are: MP3 WAV OGG You can use the following MP3 URL for testing: https://www.neutrinoapi.com/test-files/test1.mp3
  --limit: int # Limit the total number of calls allowed to the supplied phone number, if the limit is reached within the TTL then error code 14 will be returned (format: int32, default: 3)
  --limit-ttl: int # Set the TTL in number of days that the 'limit' option will remember a phone number (the default is 1 day and the maximum is 365 days) (format: int32, default: 1)
  number: string # The phone number to call. Must be in valid international format
]: any -> record<calling: bool, number_valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone-playback")
  let req_body = {"audio-url": $audio_url, "limit": $limit, "limit-ttl": $limit_ttl, "number": $number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Phone Validate
#
# GET /phone-validate
# operationId: PhoneValidate
export def "phone-validate validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: string # A phone number. This can be in international format (E.164) or local format. If passing local format you must also set either the 'country-code' OR 'ip' options as well
  --country-code: string # ISO 2-letter country code, assume numbers are based in this country. If not set numbers are assumed to be in international format (with or without the leading + sign)
  --ip: string # Pass in a users IP address and we will assume numbers are based in the country of the IP address
]: nothing -> record<country: string, country_code: string, country_code3: string, currency_code: string, international_calling_code: string, international_number: string, is_mobile: bool, local_number: string, location: string, prefix_network: string, type: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "country-code" $country_code "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone-validate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Phone Verify
#
# POST /phone-verify
# operationId: PhoneVerify
export def "phone-verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code-length: int # The number of digits to use in the security code (between 4 and 12) (format: int32, default: 6)
  --country-code: string # ISO 2-letter country code, assume numbers are based in this country. If not set numbers are assumed to be in international format (with or without the leading + sign)
  --language-code: string # The language to playback the verification code in, available languages are: de - German en - English es - Spanish fr - French it - Italian pt - Portuguese ru - Russian (default: en)
  --limit: int # Limit the total number of calls allowed to the supplied phone number, if the limit is reached within the TTL then error code 14 will be returned (format: int32, default: 3)
  --limit-ttl: int # Set the TTL in number of days that the 'limit' option will remember a phone number (the default is 1 day and the maximum is 365 days) (format: int32, default: 1)
  number: string # The phone number to send the verification code to
  --playback-delay: int # The delay in milliseconds between the playback of each security code (format: int32, default: 800)
  --security-code: int # Pass in your own security code. This is useful if you have implemented TOTP or similar 2FA methods. If not set then we will generate a secure random code (format: int32)
]: any -> record<calling: bool, number_valid: bool, security_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone-verify")
  let req_body = {"code-length": $code_length, "country-code": $country_code, "language-code": $language_code, "limit": $limit, "limit-ttl": $limit_ttl, "number": $number, "playback-delay": $playback_delay, "security-code": $security_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# QR Code
#
# POST /qr-code
# operationId: QRCode
export def "qr-code create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bg-color: string # The QR code background color (default: #ffffff)
  content: string # The content to encode into the QR code (e.g. a URL or a phone number)
  --fg-color: string # The QR code foreground color (default: #000000)
  --height: int # The height of the QR code (in px) (format: int32, default: 256)
  --width: int # The width of the QR code (in px) (format: int32, default: 256)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qr-code")
  let req_body = {"bg-color": $bg_color, "content": $content, "fg-color": $fg_color, "height": $height, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# SMS Verify
#
# POST /sms-verify
# operationId: SMSVerify
export def "sms-verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code-length: int # The number of digits to use in the security code (must be between 4 and 12) (format: int32, default: 5)
  --country-code: string # ISO 2-letter country code, assume numbers are based in this country. If not set numbers are assumed to be in international format (with or without the leading + sign)
  --language-code: string # The language to send the verification code in, available languages are: de - German en - English es - Spanish fr - French it - Italian pt - Portuguese ru - Russian (default: en)
  --limit: int # Limit the total number of SMS allowed to the supplied phone number, if the limit is reached within the TTL then error code 14 will be returned (format: int32, default: 10)
  --limit-ttl: int # Set the TTL in number of days that the 'limit' option will remember a phone number (the default is 1 day and the maximum is 365 days) (format: int32, default: 1)
  number: string # The phone number to send a verification code to
  --security-code: int # Pass in your own security code. This is useful if you have implemented TOTP or similar 2FA methods. If not set then we will generate a secure random code (format: int32)
]: any -> record<number_valid: bool, security_code: string, sent: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sms-verify")
  let req_body = {"code-length": $code_length, "country-code": $country_code, "language-code": $language_code, "limit": $limit, "limit-ttl": $limit_ttl, "number": $number, "security-code": $security_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# UA Lookup
#
# GET /ua-lookup
# operationId: UALookup
export def "ua-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ua: string # The user-agent string to lookup. For client hints use the 'UA' header or the JSON data directly from 'navigator.userAgentData.brands' or 'navigator.userAgentData.getHighEntropyValues()'
  --ua-version: string # For client hints this corresponds to the 'UA-Full-Version' header or 'uaFullVersion' from NavigatorUAData
  --ua-platform: string # For client hints this corresponds to the 'UA-Platform' header or 'platform' from NavigatorUAData
  --ua-platform-version: string # For client hints this corresponds to the 'UA-Platform-Version' header or 'platformVersion' from NavigatorUAData
  --ua-mobile: string # For client hints this corresponds to the 'UA-Mobile' header or 'mobile' from NavigatorUAData
  --device-model: string # For client hints this corresponds to the 'UA-Model' header or 'model' from NavigatorUAData. You can also use this parameter to lookup a device directly by its model name, model code or hardware code, on android you can get the model name from: https://developer.android.com/reference/android/os/Build.html#MODEL
  --device-brand: string # This parameter is only used in combination with 'device-model' when doing direct device lookups without any user-agent data. Set this to the brand or manufacturer name, this is required for accurate device detection with ambiguous model names. On android you can get the device brand from: https://developer.android.com/reference/android/os/Build#MANUFACTURER
]: nothing -> record<browser_engine: string, browser_release: string, device_brand: string, device_height_px: float, device_model: string, device_model_code: string, device_pixel_ratio: float, device_ppi: float, device_price: float, device_release: string, device_resolution: string, device_width_px: float, is_mobile: bool, is_webview: bool, name: string, os: string, os_family: string, os_version: string, os_version_major: string, type: string, ua: string, version: string, version_major: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ua" $ua "scalar") (serialize-qp "ua-version" $ua_version "scalar") (serialize-qp "ua-platform" $ua_platform "scalar") (serialize-qp "ua-platform-version" $ua_platform_version "scalar") (serialize-qp "ua-mobile" $ua_mobile "scalar") (serialize-qp "device-model" $device_model "scalar") (serialize-qp "device-brand" $device_brand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ua-lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# URL Info
#
# GET /url-info
# operationId: URLInfo
export def "url-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # The URL to probe
  --fetch-content: oneof<nothing, bool> # If this URL responds with html, text, json or xml then return the response. This option is useful if you want to perform further processing on the URL content (e.g. with the HTML Extract or HTML Clean APIs) (default: false)
  --ignore-certificate-errors: oneof<nothing, bool> # Ignore any TLS/SSL certificate errors and load the URL anyway (default: false)
  --timeout: int # Timeout in seconds. Give up if still trying to load the URL after this number of seconds (format: int32, default: 60)
  --retry: int # If the request fails for any reason try again this many times (format: int32, default: 0)
]: nothing -> record<content: string, content_encoding: string, content_size: int, content_type: string, http_ok: bool, http_redirect: bool, http_status: int, http_status_message: int, is_error: bool, is_timeout: bool, language_code: string, load_time: float, query: record, real: bool, server_city: string, server_country: string, server_country_code: string, server_hostname: string, server_ip: string, server_name: string, server_region: string, title: string, url: string, url_path: string, url_port: int, url_protocol: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "fetch-content" $fetch_content "scalar") (serialize-qp "ignore-certificate-errors" $ignore_certificate_errors "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "retry" $retry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/url-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Verify Security Code
#
# GET /verify-security-code
# operationId: VerifySecurityCode
export def "verify-security-code verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --security-code: string # The security code to verify
  --limit-by: string # If set then enable additional brute-force protection by limiting the number of attempts by the supplied value. This can be set to any unique identifier you would like to limit by, for example a hash of the users email, phone number or IP address. Requests to this API will be ignored after approximately 10 failed verification attempts
]: nothing -> record<verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "security-code" $security_code "scalar") (serialize-qp "limit-by" $limit_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verify-security-code" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
