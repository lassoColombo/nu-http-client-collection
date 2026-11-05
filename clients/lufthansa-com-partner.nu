# Auto-generated client for LH Partner API v1.0
# Source: https://api.apis.guru/v2/specs/lufthansa.com/partner/1.0/openapi.json
# Auth: --token flag or $env.LH_PARTNER_API_TOKEN

const BASE_URL = "https://api.lufthansa.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LH_PARTNER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.lufthansa.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["baggage-trip-and-contact" "all-fares" "best-fares" "deep-links" "lh-deep-links-ffp" "lh-deep-links-itco" "fares" "lowest-fares" "fares-subscriptions" "ond-route" "ond-status" "top-ond" "orders" "auto-check-in" "price-offers" "seat-details" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "baggage-trip-and-contact" [
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
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($search_id | is-empty) { error make --unspanned { msg: "path parameter 'searchID' must be non-empty" } }
  let full_url = (build-url $base ({search_id: (encode-path-segment $search_id)} | format pattern "/baggage/baggagetripandcontact/{search_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# All Fares
#
# GET /offers/fares/allfares
# operationId: All Fares
export def "all-fares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Specifies in which catalogue the fares need to be searched (e.g.'4U;OS'). (required)
  --origin: string # Enter journey origin (e.g 'FRA'). (required)
  --destination: string # Enter journey destination (e.g 'MAD'). (required)
  --travel-date: string # Enter journey travel-date (e.g 2016-10-20) (required)
  --return-date: string # Enter journey return-date (e.g 2016-10-31)'.
  --cabin-class: string # Enter the required cabin class (e.g econonmy, business etc.). (Acceptable values are: "", "economy", "premium economy", "business", "first") (default: economy)
  --travelers: string # Specifies the type and number of travelers (e.g. '(adult=2;child=2;infant=1)') For LH only (adult=1) possible.
  --fare-family: string # Mandatory for 4U. Specifies, which fares to be returned, such as basic, smart, best, smartflex, bestflex . (Acceptable values are: "", "basic", "smart", "best", "smartflex", "bestflex") (default: smart)
  --trackingid: string # Austrian Airlines only - specify the web tracking id to be used in OS Deep link.
  --hdr-accept: string # Mandatory http header: application/xml or application/json (default: application/json)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogues == null) { error make --unspanned { msg: "required query parameter 'catalogues' missing: pass --catalogues" } }
  if ($origin == null) { error make --unspanned { msg: "required query parameter 'origin' missing: pass --origin" } }
  if ($destination == null) { error make --unspanned { msg: "required query parameter 'destination' missing: pass --destination" } }
  if ($travel_date == null) { error make --unspanned { msg: "required query parameter 'travel-date' missing: pass --travel-date" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "fare-family" $fare_family "scalar") (serialize-qp "trackingid" $trackingid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/allfares" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "return-date": $return_date, "cabin-class": $cabin_class, "travelers": $travelers, "fare-family": $fare_family, "trackingid": $trackingid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Best Fares
#
# GET /offers/fares/bestfares
# operationId: Best Fares
export def "best-fares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Search fares from these carriers' catalogues (e.g. '4U;OS;LH') (required)
  --origin: string # Journey origin. 3-letter IATA airport code (e.g. 'FRA') (required)
  --destination: string # Journey destination. 3-letter IATA airport code (e.g. 'MAD') (required)
  --travel-date: string # Journey travel-date (YYYY-MM-DD) (required)
  --trip-duration: string # Trip duration in days (e.g. '7') (required)
  --range: string # Fare range: 'byday' or 'bymonth' (Acceptable values are: "byday", "bymonth") (required)
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --country: string # Country code of requestor. 2-letter ISO 3166-1 country code (e.g. 'de')
  --trackingid: string # Austrian Airlines only - specify the web tracking id to be used in OS Deep link.
  --fare-family: string # Fare family: basic, smart, best, smartflex, bestflex - Germanwings only (Acceptable values are: "", "basic", "smart", "best", "smartflex", "bestflex")
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogues == null) { error make --unspanned { msg: "required query parameter 'catalogues' missing: pass --catalogues" } }
  if ($origin == null) { error make --unspanned { msg: "required query parameter 'origin' missing: pass --origin" } }
  if ($destination == null) { error make --unspanned { msg: "required query parameter 'destination' missing: pass --destination" } }
  if ($travel_date == null) { error make --unspanned { msg: "required query parameter 'travel-date' missing: pass --travel-date" } }
  if ($trip_duration == null) { error make --unspanned { msg: "required query parameter 'trip-duration' missing: pass --trip-duration" } }
  if ($range == null) { error make --unspanned { msg: "required query parameter 'range' missing: pass --range" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "trip-duration" $trip_duration "scalar") (serialize-qp "range" $range "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "trackingid" $trackingid "scalar") (serialize-qp "fare-family" $fare_family "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/bestfares" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "trip-duration": $trip_duration, "range": $range, "cabin-class": $cabin_class, "country": $country, "trackingid": $trackingid, "fare-family": $fare_family} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deep Links
#
# GET /offers/fares/deeplink
# operationId: Deep Links
export def "deep-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the deep link will be created (e.g. 'LH') (required)
  --trackingid: string # Deep link tracking ID (required)
  --country: string # 2-letter ISO 3166-1 country code (required)
  --lang: string # 2-letter ISO 3166-1 language code (required)
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
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogues == null) { error make --unspanned { msg: "required query parameter 'catalogues' missing: pass --catalogues" } }
  if ($trackingid == null) { error make --unspanned { msg: "required query parameter 'trackingid' missing: pass --trackingid" } }
  if ($country == null) { error make --unspanned { msg: "required query parameter 'country' missing: pass --country" } }
  if ($lang == null) { error make --unspanned { msg: "required query parameter 'lang' missing: pass --lang" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "trackingid" $trackingid "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "origin-name" $origin_name "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "destination-name" $destination_name "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "outbound-segments" $outbound_segments "scalar") (serialize-qp "return-segments" $return_segments "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "fare" $fare "scalar") (serialize-qp "net-fare" $net_fare "scalar") (serialize-qp "fare-currency" $fare_currency "scalar") (serialize-qp "partnerid" $partnerid "scalar") (serialize-qp "encryption-key" $encryption_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/deeplink" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "trackingid": $trackingid, "country": $country, "lang": $lang, "origin": $origin, "origin-name": $origin_name, "destination": $destination, "destination-name": $destination_name, "travel-date": $travel_date, "return-date": $return_date, "cabin-class": $cabin_class, "outbound-segments": $outbound_segments, "return-segments": $return_segments, "travelers": $travelers, "fare": $fare, "net-fare": $net_fare, "fare-currency": $fare_currency, "partnerid": $partnerid, "encryption-key": $encryption_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# LH Deep Links - FFP
#
# GET /offers/fares/deeplink/ffp
# operationId: LH Deep Links - FFP
export def "lh-deep-links-ffp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the deep link will be created (e.g. 'LH') (required)
  --origin: string # Journey origin. 3-letter IATA airport or city code (e.g. 'FRA') (required)
  --destination: string # Journey destination. 3-letter IATA airport or city code (e.g. 'MAD') (required)
  --travel-date: string # Journey travel-date (YYYY-MM-DD) (required)
  --trackingid: string # Deep link tracking ID (required)
  --country: string # 2-letter ISO 3166-1 country code (required)
  --lang: string # 2-letter ISO 3166-1 language code (required)
  --return-date: string # Journey return-date (YYYY-MM-DD)
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --travelers: string # Type and number of travelers (e.g. '(adult=2;child=2;infant=1)')
  --partnerid: string # Deep link partner id (e.g. '1247')
  --encryption-key: string # Deep link encryption-key
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogues == null) { error make --unspanned { msg: "required query parameter 'catalogues' missing: pass --catalogues" } }
  if ($origin == null) { error make --unspanned { msg: "required query parameter 'origin' missing: pass --origin" } }
  if ($destination == null) { error make --unspanned { msg: "required query parameter 'destination' missing: pass --destination" } }
  if ($travel_date == null) { error make --unspanned { msg: "required query parameter 'travel-date' missing: pass --travel-date" } }
  if ($trackingid == null) { error make --unspanned { msg: "required query parameter 'trackingid' missing: pass --trackingid" } }
  if ($country == null) { error make --unspanned { msg: "required query parameter 'country' missing: pass --country" } }
  if ($lang == null) { error make --unspanned { msg: "required query parameter 'lang' missing: pass --lang" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "trackingid" $trackingid "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "partnerid" $partnerid "scalar") (serialize-qp "encryption-key" $encryption_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/deeplink/ffp" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "trackingid": $trackingid, "country": $country, "lang": $lang, "return-date": $return_date, "cabin-class": $cabin_class, "travelers": $travelers, "partnerid": $partnerid, "encryption-key": $encryption_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# LH Deep Links - ITCO
#
# GET /offers/fares/deeplink/itco
# operationId: LH Deep Links - ITCO
export def "lh-deep-links-itco" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Carrier for which the deep link will be created (e.g. 'LH') (required)
  --origin: string # Journey origin. 3-letter IATA airport or city code (e.g. 'FRA') (required)
  --destination: string # Journey destination. 3-letter IATA airport or city code (e.g. 'MAD') (required)
  --travel-date: string # Journey travel-date (YYYY-MM-DD) (required)
  --outbound-segments: string # Outbound flight segments in the sequence of travel (e.g. 'LH096;LH480') (required)
  --fare: string # Travel fare (e.g. '1341.45') (required)
  --fare-currency: string # Fare currency (e.g. 'EUR') (required)
  --trackingid: string # Deep link tracking ID (required)
  --country: string # 2-letter ISO 3166-1 country code (required)
  --lang: string # 2-letter ISO 3166-1 language code (required)
  --return-date: string # Journey return-date (YYYY-MM-DD)
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --return-segments: string # Flight segments in the sequence of travel (e.g. 'LH7465;LH431')
  --travelers: string # Type and number of travelers (e.g. '(adult=2;child=2;infant=1)')
  --net-fare: string # Travel net fare. Total fare less taxes and charges (e.g. '1140')
  --partnerid: string # Deep link partner id (e.g. '1247')
  --encryption-key: string # Deep link encryption-key
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogues == null) { error make --unspanned { msg: "required query parameter 'catalogues' missing: pass --catalogues" } }
  if ($origin == null) { error make --unspanned { msg: "required query parameter 'origin' missing: pass --origin" } }
  if ($destination == null) { error make --unspanned { msg: "required query parameter 'destination' missing: pass --destination" } }
  if ($travel_date == null) { error make --unspanned { msg: "required query parameter 'travel-date' missing: pass --travel-date" } }
  if ($outbound_segments == null) { error make --unspanned { msg: "required query parameter 'outbound-segments' missing: pass --outbound-segments" } }
  if ($fare == null) { error make --unspanned { msg: "required query parameter 'fare' missing: pass --fare" } }
  if ($fare_currency == null) { error make --unspanned { msg: "required query parameter 'fare-currency' missing: pass --fare-currency" } }
  if ($trackingid == null) { error make --unspanned { msg: "required query parameter 'trackingid' missing: pass --trackingid" } }
  if ($country == null) { error make --unspanned { msg: "required query parameter 'country' missing: pass --country" } }
  if ($lang == null) { error make --unspanned { msg: "required query parameter 'lang' missing: pass --lang" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "outbound-segments" $outbound_segments "scalar") (serialize-qp "fare" $fare "scalar") (serialize-qp "fare-currency" $fare_currency "scalar") (serialize-qp "trackingid" $trackingid "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "return-segments" $return_segments "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "net-fare" $net_fare "scalar") (serialize-qp "partnerid" $partnerid "scalar") (serialize-qp "encryption-key" $encryption_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/deeplink/itco" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "outbound-segments": $outbound_segments, "fare": $fare, "fare-currency": $fare_currency, "trackingid": $trackingid, "country": $country, "lang": $lang, "return-date": $return_date, "cabin-class": $cabin_class, "return-segments": $return_segments, "travelers": $travelers, "net-fare": $net_fare, "partnerid": $partnerid, "encryption-key": $encryption_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fares
#
# GET /offers/fares/fares
# operationId: Fares
export def "fares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Search fares from these carriers' catalogues - currently active for Germanwings only (4U) (required)
  --segments: string # Journey details e.g. (origin=TXL;destination=CGN;travel-date=2016-12-15;return-date=2016-12-20;cabin=Economy) (required)
  --carriers: string # Include fares for these carriers e.g. ('4U;LH') (required)
  --travelers: string # Type and number of travelers e.g. (adult=1;child=1;infant=1)
  --fare-types: string # Fares family: basic,smart, best, smartflex, bestflex - Germanwings only (Acceptable values are: "", "basic", "smart", "best", "smartflex", "bestflex") (default: basic)
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogues == null) { error make --unspanned { msg: "required query parameter 'catalogues' missing: pass --catalogues" } }
  if ($segments == null) { error make --unspanned { msg: "required query parameter 'segments' missing: pass --segments" } }
  if ($carriers == null) { error make --unspanned { msg: "required query parameter 'carriers' missing: pass --carriers" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "segments" $segments "scalar") (serialize-qp "carriers" $carriers "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "fare-types" $fare_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/fares" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "segments": $segments, "carriers": $carriers, "travelers": $travelers, "fare-types": $fare_types} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lowest Fares
#
# GET /offers/fares/lowestfares
# operationId: Lowest Fares
export def "lowest-fares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogues: string # Search fares from these carriers' catalogues e.g. '4U;OS;LH' (required)
  --origin: string # Journey origin. 3-letter IATA aiport code e.g. 'FRA' (required)
  --destination: string # Journey destination. 3-letter IATA airport code e.g. 'MAD' (required)
  --travel-date: string # Journey travel-date YYYY-MM-DD (required)
  --return-date: string # Journey return-date - mandatory for OS and LH searches YYYY-MM-DD
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first")
  --travelers: string # Type and number of travelers e.g. '(adult=2;child=2;infant=1)'. For LH only (adult=1) possible
  --fare-family: string # Fare family: basic, smart, best, smartflex, bestflex - Germanwings only (Acceptable values are: "", "basic", "smart", "best", "smartflex", "bestflex") (default: basic)
  --country: string # Country code of requestor. 2-letter ISO 3166-1 country code (e.g. 'de')
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogues == null) { error make --unspanned { msg: "required query parameter 'catalogues' missing: pass --catalogues" } }
  if ($origin == null) { error make --unspanned { msg: "required query parameter 'origin' missing: pass --origin" } }
  if ($destination == null) { error make --unspanned { msg: "required query parameter 'destination' missing: pass --destination" } }
  if ($travel_date == null) { error make --unspanned { msg: "required query parameter 'travel-date' missing: pass --travel-date" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "travel-date" $travel_date "scalar") (serialize-qp "return-date" $return_date "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "travelers" $travelers "scalar") (serialize-qp "fare-family" $fare_family "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/lowestfares" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "origin": $origin, "destination": $destination, "travel-date": $travel_date, "return-date": $return_date, "cabin-class": $cabin_class, "travelers": $travelers, "fare-family": $fare_family, "country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fares Subscriptions
#
# GET /offers/fares/subscriptions
# operationId: Fares Subscriptions
export def "fares-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --origin: string # Journey origin. 3-leter IATA airport code (e.g. 'FRA') (required)
  --destination: string # Journey destination. 3-letter IATA airport code (e.g. 'MAD') (required)
  --cabin-class: string # Cabin class: 'economy', 'premium_economy', 'business', 'first' (Acceptable values are: "", "economy", "premium_economy", "business", "first") (required)
  --trip-duration: string # Trip duration in days (e.g. '7') (required)
  --email: string # Email Address') (required)
  --lang: string # 2-letter ISO 3166-1 language code (required)
  --country: string # 2-letter ISO 3166-1 country code
  --trackingid: string # Tracking parameter
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($origin == null) { error make --unspanned { msg: "required query parameter 'origin' missing: pass --origin" } }
  if ($destination == null) { error make --unspanned { msg: "required query parameter 'destination' missing: pass --destination" } }
  if ($cabin_class == null) { error make --unspanned { msg: "required query parameter 'cabin-class' missing: pass --cabin-class" } }
  if ($trip_duration == null) { error make --unspanned { msg: "required query parameter 'trip-duration' missing: pass --trip-duration" } }
  if ($email == null) { error make --unspanned { msg: "required query parameter 'email' missing: pass --email" } }
  if ($lang == null) { error make --unspanned { msg: "required query parameter 'lang' missing: pass --lang" } }
  let qp = [(serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "cabin-class" $cabin_class "scalar") (serialize-qp "trip-duration" $trip_duration "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "trackingid" $trackingid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/fares/subscriptions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"origin": $origin, "destination": $destination, "cabin-class": $cabin_class, "trip-duration": $trip_duration, "email": $email, "lang": $lang, "country": $country, "trackingid": $trackingid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# OND Route
#
# GET /offers/ond/route/{origin}/{destination}
# operationId: OND Route
export def "ond-route" [
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
  --hdr-accept: string # Mandatory http header: application/xml or application/json (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($destination | is-empty) { error make --unspanned { msg: "path parameter 'destination' must be non-empty" } }
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({origin: (encode-path-segment $origin), destination: (encode-path-segment $destination)} | format pattern "/offers/ond/route/{origin}/{destination}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# OND Status
#
# GET /offers/ond/status
# operationId: OND Status
export def "ond-status" [
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
  --hdr-accept: string # Mandatory http header: application/xml or application/json (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "new-routes" $new_routes "scalar") (serialize-qp "old-routes" $old_routes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/ond/status" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "new-routes": $new_routes, "old-routes": $old_routes} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Top OND
#
# GET /offers/ond/top
# operationId: Top OND
export def "top-ond" [
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
  --hdr-accept: string # Mandatory http header: application/xml or application/json (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalogues" $catalogues "scalar") (serialize-qp "origin" $origin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offers/ond/top" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"catalogues": $catalogues, "origin": $origin} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Orders
#
# GET /orders/orders/{orderID}/{name}
# operationId: Orders
export def "orders" [
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
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderID' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id), name: (encode-path-segment $name)} | format pattern "/orders/orders/{order_id}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Auto Check-In
#
# PUT /preflight/autocheckin/{ticketnumber}
# operationId: Auto Check-In
export def "auto-check-in" [
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
  --email-address: string # Email address (required)
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticketnumber | is-empty) { error make --unspanned { msg: "path parameter 'ticketnumber' must be non-empty" } }
  if ($email_address == null) { error make --unspanned { msg: "required query parameter 'emailAddress' missing: pass --email-address" } }
  let qp = [(serialize-qp "emailAddress" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ticketnumber: (encode-path-segment $ticketnumber)} | format pattern "/preflight/autocheckin/{ticketnumber}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"emailAddress": $email_address} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Price Offers
#
# GET /promotions/priceoffers/flights/ond/{origin}/{destination}
# operationId: Price Offers
export def "price-offers" [
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
  --departure-date: string # Departure date in local time (YYYY-MM-DD) (required)
  --return-date: string # Return date in local time (YYYY-MM-DD) (required)
  --service: string # Optional parameter. (default: amadeusBestPrice)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($destination | is-empty) { error make --unspanned { msg: "path parameter 'destination' must be non-empty" } }
  if ($departure_date == null) { error make --unspanned { msg: "required query parameter 'departureDate' missing: pass --departure-date" } }
  if ($return_date == null) { error make --unspanned { msg: "required query parameter 'returnDate' missing: pass --return-date" } }
  let qp = [(serialize-qp "departureDate" $departure_date "scalar") (serialize-qp "returnDate" $return_date "scalar") (serialize-qp "service" $service "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({origin: (encode-path-segment $origin), destination: (encode-path-segment $destination)} | format pattern "/promotions/priceoffers/flights/ond/{origin}/{destination}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"departureDate": $departure_date, "returnDate": $return_date, "service": $service} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Seat Details
#
# GET /references/seatdetails/{aircraftCode}/{cabinCode}
# operationId: Seat Details
export def "seat-details" [
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
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml") (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($aircraft_code | is-empty) { error make --unspanned { msg: "path parameter 'aircraftCode' must be non-empty" } }
  if ($cabin_code | is-empty) { error make --unspanned { msg: "path parameter 'cabinCode' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aircraft_code: (encode-path-segment $aircraft_code), cabin_code: (encode-path-segment $cabin_code)} | format pattern "/references/seatdetails/{aircraft_code}/{cabin_code}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
