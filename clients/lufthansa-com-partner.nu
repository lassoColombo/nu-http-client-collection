# Auto-generated client for LH Partner API v1.0
# Source: https://api.apis.guru/v2/specs/lufthansa.com/partner/1.0/openapi.json
# Auth: --token flag or $env.LH_PARTNER_API_TOKEN

const BASE_URL = "https://api.lufthansa.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LH_PARTNER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.lufthansa.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "baggage-baggagetripandcontact get-trip-and-contact" } } | get name | first)
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

# Baggage Trip and Contact
#
# GET /baggage/baggagetripandcontact/{searchID}
# operationId: Baggage Trip and Contact
export def "baggage-baggagetripandcontact get-trip-and-contact" [
  search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($search_id | is-empty) { error make --unspanned { msg: "path parameter 'searchID' must be non-empty" } }
  let full_url = (build-url $base ({search_id: (encode-path-segment $search_id)} | format pattern "/baggage/baggagetripandcontact/{search_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# All Fares
#
# GET /offers/fares/allfares
# operationId: All Fares
export def "offers-fares-allfares list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Specifies in which catalogue the fares need to be searched (e.g.'4U;OS').
  --origin: string # Enter journey origin (e.g 'FRA').
  --destination: string # Enter journey destination (e.g 'MAD').
  --travel-date: string # Enter journey travel-date (e.g 2016-10-20)
  --return-date: string # Enter journey return-date (e.g 2016-10-31)'.
  --cabin-class: string # Enter the required cabin class (e.g econonmy, business etc.). (Acceptable values are: "", "economy", "premium economy", "business", "first") (default: economy)
  --travelers: string # Specifies the type and number of travelers (e.g. '(adult=2;child=2;infant=1)') For LH only (adult=1) possible.
  --fare-family: string # Mandatory for 4U. Specifies, which fares to be returned, such as basic, smart, best, smartflex, bestflex . (Acceptable values are: "", "basic", "smart", "best", "smartflex", "bestflex") (default: smart)
  --trackingid: string # Austrian Airlines only - specify the web tracking id to be used in OS Deep link.
  --hdr-accept: string # Mandatory http header: application/xml or application/json
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "fare-family" $fare_family "scalar") (serialize-qp "trackingid" $trackingid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/allfares" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "return-date": $return_date, "cabin-class": $cabin_class, "travelers": $travelers, "fare-family": $fare_family, "trackingid": $trackingid} | compact), body: null}
}

# Best Fares
#
# GET /offers/fares/bestfares
# operationId: Best Fares
export def "offers-fares-bestfares get-best" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Search fares from these carriers' catalogues (e.g. '4U;OS;LH')
  --origin: string # Journey origin. 3-letter IATA airport code (e.g. 'FRA')
  --destination: string # Journey destination. 3-letter IATA airport code (e.g. 'MAD')
  --travel-date: string # Journey travel-date (YYYY-MM-DD)
  --trip-duration: string # Trip duration in days (e.g. '7')
  --range: string # Fare range: 'byday' or 'bymonth' (Acceptable values are: "byday", "bymonth")
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --country: string # Country code of requestor. 2-letter ISO 3166-1 country code (e.g. 'de')
  --trackingid: string # Austrian Airlines only - specify the web tracking id to be used in OS Deep link.
  --fare-family: string # Fare family: basic, smart, best, smartflex, bestflex - Germanwings only (Acceptable values are: "", "basic", "smart", "best", "smartflex", "bestflex")
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "trip-duration" $trip_duration "scalar") (serialize-qp "range" $range "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "trackingid" $trackingid "scalar") (serialize-qp "fare-family" $fare_family "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/bestfares" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "trip-duration": $trip_duration, "range": $range, "cabin-class": $cabin_class, "country": $country, "trackingid": $trackingid, "fare-family": $fare_family} | compact), body: null}
}

# Deep Links
#
# GET /offers/fares/deeplink
# operationId: Deep Links
export def "offers-fares-deeplink get-deep-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the deep link will be created (e.g. 'LH')
  --trackingid: string # Deep link tracking ID
  --country: string # 2-letter ISO 3166-1 country code
  --lang: string # 2-letter ISO 3166-1 language code
  --origin: string # Journey origin. 3-letter IATA airport or city code (e.g. 'FRA')
  --origin-name: string # Journey origin airport or city name (e.g. 'frankfurt')
  --destination: string # Journey destination. 3-letter IATA airport or city code (e.g. 'MAD')
  --destination-name: string # Journey destination airport or city name (e.g. 'madrid')
  --travel-date: string # Journey travel-date (YYYY-MM-DD)
  --return-date: string # Journey return-date (YYYY-MM-DD)
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --outbound-segments: string # Outbound flight segments in the sequence of travel (e.g. 'LH096;LH480')
  --return-segments: string # Flight segments in the sequence of travel (e.g. 'LH7465;LH431')
  --travelers: string # Type and number of travelers (e.g. '(adult=2;child=2;infant=1)')
  --fare: string # Travel fare (e.g. '1341.45')
  --net-fare: string # Travel net fare. Total fare less taxes and charges (e.g. '1140')
  --fare-currency: string # Fare currency (e.g. 'EUR')
  --partnerid: string # Deep link partner id (e.g. '1247')
  --encryption-key: string # Deep link encryption-key
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "trackingid" $trackingid "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "origin-name" $origin_name "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "destination-name" $destination_name "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "outbound-segments" $outbound_segments "scalar") (serialize-qp "return-segments" $return_segments "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "fare" $fare "scalar") (serialize-qp "net-fare" $net_fare "scalar") (serialize-qp "fare-currency" $fare_currency "scalar") (serialize-qp "partnerid" $partnerid "scalar") (serialize-qp "encryption-key" $encryption_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/deeplink" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "trackingid": $trackingid, "country": $country, "lang": $lang, "origin": $origin, "origin-name": $origin_name, "destination": $destination, "destination-name": $destination_name, "travel-date": $travel_date, "return-date": $return_date, "cabin-class": $cabin_class, "outbound-segments": $outbound_segments, "return-segments": $return_segments, "travelers": $travelers, "fare": $fare, "net-fare": $net_fare, "fare-currency": $fare_currency, "partnerid": $partnerid, "encryption-key": $encryption_key} | compact), body: null}
}

# LH Deep Links - FFP
#
# GET /offers/fares/deeplink/ffp
# operationId: LH Deep Links - FFP
export def "offers-fares-deeplink-ffp get-lh-deep-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the deep link will be created (e.g. 'LH')
  --origin: string # Journey origin. 3-letter IATA airport or city code (e.g. 'FRA')
  --destination: string # Journey destination. 3-letter IATA airport or city code (e.g. 'MAD')
  --travel-date: string # Journey travel-date (YYYY-MM-DD)
  --trackingid: string # Deep link tracking ID
  --country: string # 2-letter ISO 3166-1 country code
  --lang: string # 2-letter ISO 3166-1 language code
  --return-date: string # Journey return-date (YYYY-MM-DD)
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --travelers: string # Type and number of travelers (e.g. '(adult=2;child=2;infant=1)')
  --partnerid: string # Deep link partner id (e.g. '1247')
  --encryption-key: string # Deep link encryption-key
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "trackingid" $trackingid "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "partnerid" $partnerid "scalar") (serialize-qp "encryption-key" $encryption_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/deeplink/ffp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "trackingid": $trackingid, "country": $country, "lang": $lang, "return-date": $return_date, "cabin-class": $cabin_class, "travelers": $travelers, "partnerid": $partnerid, "encryption-key": $encryption_key} | compact), body: null}
}

# LH Deep Links - ITCO
#
# GET /offers/fares/deeplink/itco
# operationId: LH Deep Links - ITCO
export def "offers-fares-deeplink-itco get-lh-deep-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the deep link will be created (e.g. 'LH')
  --origin: string # Journey origin. 3-letter IATA airport or city code (e.g. 'FRA')
  --destination: string # Journey destination. 3-letter IATA airport or city code (e.g. 'MAD')
  --travel-date: string # Journey travel-date (YYYY-MM-DD)
  --outbound-segments: string # Outbound flight segments in the sequence of travel (e.g. 'LH096;LH480')
  --fare: string # Travel fare (e.g. '1341.45')
  --fare-currency: string # Fare currency (e.g. 'EUR')
  --trackingid: string # Deep link tracking ID
  --country: string # 2-letter ISO 3166-1 country code
  --lang: string # 2-letter ISO 3166-1 language code
  --return-date: string # Journey return-date (YYYY-MM-DD)
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --return-segments: string # Flight segments in the sequence of travel (e.g. 'LH7465;LH431')
  --travelers: string # Type and number of travelers (e.g. '(adult=2;child=2;infant=1)')
  --net-fare: string # Travel net fare. Total fare less taxes and charges (e.g. '1140')
  --partnerid: string # Deep link partner id (e.g. '1247')
  --encryption-key: string # Deep link encryption-key
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "outbound-segments" $outbound_segments "scalar") (serialize-qp "fare" $fare "scalar") (serialize-qp "fare-currency" $fare_currency "scalar") (serialize-qp "trackingid" $trackingid "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "return-segments" $return_segments "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "net-fare" $net_fare "scalar") (serialize-qp "partnerid" $partnerid "scalar") (serialize-qp "encryption-key" $encryption_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/deeplink/itco" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "outbound-segments": $outbound_segments, "fare": $fare, "fare-currency": $fare_currency, "trackingid": $trackingid, "country": $country, "lang": $lang, "return-date": $return_date, "cabin-class": $cabin_class, "return-segments": $return_segments, "travelers": $travelers, "net-fare": $net_fare, "partnerid": $partnerid, "encryption-key": $encryption_key} | compact), body: null}
}

# Fares
#
# GET /offers/fares/fares
# operationId: Fares
export def "offers-fares-fares get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Search fares from these carriers' catalogues - currently active for Germanwings only (4U)
  --segments: string # Journey details e.g. (origin=TXL;destination=CGN;travel-date=2016-12-15;return-date=2016-12-20;cabin=Economy)
  --carriers: string # Include fares for these carriers e.g. ('4U;LH')
  --travelers: string # Type and number of travelers e.g. (adult=1;child=1;infant=1)
  --fare-types: string # Fares family: basic,smart, best, smartflex, bestflex - Germanwings only (Acceptable values are: "", "basic", "smart", "best", "smartflex", "bestflex") (default: basic)
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "segments" $segments "scalar") (serialize-qp "carriers" $carriers "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "fare-types" $fare_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/fares" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "segments": $segments, "carriers": $carriers, "travelers": $travelers, "fare-types": $fare_types} | compact), body: null}
}

# Lowest Fares
#
# GET /offers/fares/lowestfares
# operationId: Lowest Fares
export def "offers-fares-lowestfares get-lowest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Search fares from these carriers' catalogues e.g. '4U;OS;LH'
  --origin: string # Journey origin. 3-letter IATA aiport code e.g. 'FRA'
  --destination: string # Journey destination. 3-letter IATA airport code e.g. 'MAD'
  --travel-date: string # Journey travel-date YYYY-MM-DD
  --return-date: string # Journey return-date - mandatory for OS and LH searches YYYY-MM-DD
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --travelers: string # Type and number of travelers e.g. '(adult=2;child=2;infant=1)'. For LH only (adult=1) possible
  --fare-family: string # Fare family: basic, smart, best, smartflex, bestflex - Germanwings only (Acceptable values are: "", "basic", "smart", "best", "smartflex", "bestflex") (default: basic)
  --country: string # Country code of requestor. 2-letter ISO 3166-1 country code (e.g. 'de')
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "fare-family" $fare_family "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/lowestfares" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "return-date": $return_date, "cabin-class": $cabin_class, "travelers": $travelers, "fare-family": $fare_family, "country": $country} | compact), body: null}
}

# Fares Subscriptions
#
# GET /offers/fares/subscriptions
# operationId: Fares Subscriptions
export def "offers-fares-subscriptions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --origin: string # Journey origin. 3-leter IATA airport code (e.g. 'FRA')
  --destination: string # Journey destination. 3-letter IATA airport code (e.g. 'MAD')
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --trip-duration: string # Trip duration in days (e.g. '7')
  --email: string # Email Address')
  --lang: string # 2-letter ISO 3166-1 language code
  --country: string # 2-letter ISO 3166-1 country code
  --trackingid: string # Tracking parameter
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "trip-duration" $trip_duration "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "trackingid" $trackingid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"origin": $origin, "destination": $destination, "cabin-class": $cabin_class, "trip-duration": $trip_duration, "email": $email, "lang": $lang, "country": $country, "trackingid": $trackingid} | compact), body: null}
}

# OND Route
#
# GET /offers/ond/route/{origin}/{destination}
# operationId: OND Route
export def "offers-ond-route get" [
  origin: string
  destination: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the OND will be retrieved (e.g. 'LH') (default: LH)
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken)
  --offset: string # Number of records skipped. Defaults to 0
  --hdr-accept: string # Mandatory http header: application/xml or application/json
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($destination | is-empty) { error make --unspanned { msg: "path parameter 'destination' must be non-empty" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({origin: (encode-path-segment $origin), destination: (encode-path-segment $destination)} | format pattern "/offers/ond/route/{origin}/{destination}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "limit": $limit, "offset": $offset} | compact), body: null}
}

# OND Status
#
# GET /offers/ond/status
# operationId: OND Status
export def "offers-ond-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the OND will be retrieved (e.g. 'LH') (default: LH)
  --new-routes: string # Enter if newly added routes should be returned in the response. (Acceptable values are: "", "true", "false")
  --old-routes: string # Enter if old (deleted) routes should be returned in the response. (Acceptable values are: "", "true", "false")
  --hdr-accept: string # Mandatory http header: application/xml or application/json
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "new-routes" $new_routes "scalar") (serialize-qp "old-routes" $old_routes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/ond/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "new-routes": $new_routes, "old-routes": $old_routes} | compact), body: null}
}

# Top OND
#
# GET /offers/ond/top
# operationId: Top OND
export def "offers-ond-top top" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the OND will be retrieved (e.g. 'LH') (default: LH)
  --origin: string # Enter the origin country code (e.g. 'DE'). Leave empty to search Top OND across all countries
  --hdr-accept: string # Mandatory http header: application/xml or application/json
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/ond/top" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"catalogues": $catalogues, "origin": $origin} | compact), body: null}
}

# Orders
#
# GET /orders/orders/{orderID}/{name}
# operationId: Orders
export def "orders-orders get" [
  order_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderID' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id), name: (encode-path-segment $name)} | format pattern "/orders/orders/{order_id}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Auto Check-In
#
# PUT /preflight/autocheckin/{ticketnumber}
# operationId: Auto Check-In
export def "preflight-autocheckin check-auto" [
  ticketnumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-address: string # Email address
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticketnumber | is-empty) { error make --unspanned { msg: "path parameter 'ticketnumber' must be non-empty" } }
  let qp = [(serialize-qp "emailAddress" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ticketnumber: (encode-path-segment $ticketnumber)} | format pattern "/preflight/autocheckin/{ticketnumber}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"emailAddress": $email_address} | compact), body: null}
}

# Price Offers
#
# GET /promotions/priceoffers/flights/ond/{origin}/{destination}
# operationId: Price Offers
export def "promotions-priceoffers-flights-ond get-price-offers" [
  origin: string
  destination: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --departure-date: string # Departure date in local time (YYYY-MM-DD)
  --return-date: string # Return date in local time (YYYY-MM-DD)
  --service: string # Optional parameter. (default: amadeusBestPrice)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($destination | is-empty) { error make --unspanned { msg: "path parameter 'destination' must be non-empty" } }
  let qp = [(serialize-qp "departureDate" $departure_date "scalar") (serialize-qp "returnDate" $return_date "scalar") (serialize-qp "service" $service "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({origin: (encode-path-segment $origin), destination: (encode-path-segment $destination)} | format pattern "/promotions/priceoffers/flights/ond/{origin}/{destination}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"departureDate": $departure_date, "returnDate": $return_date, "service": $service} | compact), body: null}
}

# Seat Details
#
# GET /references/seatdetails/{aircraftCode}/{cabinCode}
# operationId: Seat Details
export def "references-seatdetails get-seat-details" [
  aircraft_code: string
  cabin_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # 2-letter ISO 3166-1 language code
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($aircraft_code | is-empty) { error make --unspanned { msg: "path parameter 'aircraftCode' must be non-empty" } }
  if ($cabin_code | is-empty) { error make --unspanned { msg: "path parameter 'cabinCode' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aircraft_code: (encode-path-segment $aircraft_code), cabin_code: (encode-path-segment $cabin_code)} | format pattern "/references/seatdetails/{aircraft_code}/{cabin_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang} | compact), body: null}
}
