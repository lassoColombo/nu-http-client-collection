# Auto-generated client for API Reference - Ideal Postcodes v3.7.0
# Source: https://api.apis.guru/v2/specs/ideal-postcodes.co.uk/3.7.0/openapi.json
# Auth: --token flag or $env.API_REFERENCE_IDEAL_POSTCODES_TOKEN

const BASE_URL = "https://api.ideal-postcodes.co.uk/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o API_REFERENCE_IDEAL_POSTCODES_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.ideal-postcodes.co.uk/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bias-ip-completer [] { ["true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addresses get" } } | get name | first)
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

# Extract Addresses
#
# GET /addresses
# operationId: Addresses
export def "addresses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --query: string # Specifies the address you wish to query. Query can be shortened to `q=`
  --limit: int # format: int32, default: 10, e.g. 5
  --page: int # format: int32, default: 0, e.g. 0
  --filter: string # e.g. line_1,line_2,line_3
  --lon: float # format: float, e.g. -0.12767
  --lat: float # format: float, e.g. 51.503541
  --postcode-outward: string # e.g. 1AA
  --postcode: string # e.g. SW1A 2AA
  --postcode-area: string # e.g. SW
  --postcode-sector: string # e.g. SW1A 2
  --post-town: string # e.g. London
  --uprn: int # e.g. 100023336956
  --country: string # e.g. England
  --postcode-type: string # e.g. L
  --su-organisation-indicator: string # e.g. Y
  --box: string # e.g. 2.095,57.15,-2.096,57.14
  --bias-postcode-outward: string
  --bias-postcode: string # e.g. /addresses?postcode=SW1A2AA&q=10
  --bias-postcode-area: string # e.g. The postcode area of SW1A 2AA and N1 6RT are SW and N respectively
  --bias-postcode-sector: string # e.g. SW1A 2AA is SW1A 2
  --bias-post-town: string
  --bias-thoroughfare: string
  --bias-country: string
  --bias-lonlat: string # e.g. -2.095,57.15,100
]: nothing -> record<code: int, message: string, result: record<hits: list<any>, limit: int, page: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "postcode_outward" $postcode_outward "scalar") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "postcode_area" $postcode_area "scalar") (serialize-qp "postcode_sector" $postcode_sector "scalar") (serialize-qp "post_town" $post_town "scalar") (serialize-qp "uprn" $uprn "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "postcode_type" $postcode_type "scalar") (serialize-qp "su_organisation_indicator" $su_organisation_indicator "scalar") (serialize-qp "box" $box "scalar") (serialize-qp "bias_postcode_outward" $bias_postcode_outward "scalar") (serialize-qp "bias_postcode" $bias_postcode "scalar") (serialize-qp "bias_postcode_area" $bias_postcode_area "scalar") (serialize-qp "bias_postcode_sector" $bias_postcode_sector "scalar") (serialize-qp "bias_post_town" $bias_post_town "scalar") (serialize-qp "bias_thoroughfare" $bias_thoroughfare "scalar") (serialize-qp "bias_country" $bias_country "scalar") (serialize-qp "bias_lonlat" $bias_lonlat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addresses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "query": $query, "limit": $limit, "page": $page, "filter": $filter, "lon": $lon, "lat": $lat, "postcode_outward": $postcode_outward, "postcode": $postcode, "postcode_area": $postcode_area, "postcode_sector": $postcode_sector, "post_town": $post_town, "uprn": $uprn, "country": $country, "postcode_type": $postcode_type, "su_organisation_indicator": $su_organisation_indicator, "box": $box, "bias_postcode_outward": $bias_postcode_outward, "bias_postcode": $bias_postcode, "bias_postcode_area": $bias_postcode_area, "bias_postcode_sector": $bias_postcode_sector, "bias_post_town": $bias_post_town, "bias_thoroughfare": $bias_thoroughfare, "bias_country": $bias_country, "bias_lonlat": $bias_lonlat} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find Address
#
# GET /autocomplete/addresses
# operationId: AddressAutocomplete
export def "autocomplete-addresses get-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --query: string # Specifies the address you wish to query. Query can be shortened to `q=`
  --context: string
  --limit: int # Limits number of address suggestions unless a postcode is detected. In this instance entire list of addreses for that postcode is returned. (format: int32, default: 10, e.g. 5)
  --postcode-outward: string # e.g. 1AA
  --postcode: string # e.g. SW1A 2AA
  --postcode-area: string # e.g. SW
  --postcode-sector: string # e.g. SW1A 2
  --post-town: string # e.g. London
  --uprn: int # e.g. 100023336956
  --country: string # e.g. England
  --postcode-type: string # e.g. L
  --su-organisation-indicator: string # e.g. Y
  --box: string # e.g. 2.095,57.15,-2.096,57.14
  --bias-postcode-outward: string
  --bias-postcode: string # e.g. /addresses?postcode=SW1A2AA&q=10
  --bias-postcode-area: string # e.g. The postcode area of SW1A 2AA and N1 6RT are SW and N respectively
  --bias-postcode-sector: string # e.g. SW1A 2AA is SW1A 2
  --bias-post-town: string
  --bias-thoroughfare: string
  --bias-country: string
  --bias-lonlat: string # e.g. -2.095,57.15,100
  --bias-ip: string@bias-ip-completer # e.g. true
]: nothing -> record<code: int, message: string, result: record<hits: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "postcode_outward" $postcode_outward "scalar") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "postcode_area" $postcode_area "scalar") (serialize-qp "postcode_sector" $postcode_sector "scalar") (serialize-qp "post_town" $post_town "scalar") (serialize-qp "uprn" $uprn "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "postcode_type" $postcode_type "scalar") (serialize-qp "su_organisation_indicator" $su_organisation_indicator "scalar") (serialize-qp "box" $box "scalar") (serialize-qp "bias_postcode_outward" $bias_postcode_outward "scalar") (serialize-qp "bias_postcode" $bias_postcode "scalar") (serialize-qp "bias_postcode_area" $bias_postcode_area "scalar") (serialize-qp "bias_postcode_sector" $bias_postcode_sector "scalar") (serialize-qp "bias_post_town" $bias_post_town "scalar") (serialize-qp "bias_thoroughfare" $bias_thoroughfare "scalar") (serialize-qp "bias_country" $bias_country "scalar") (serialize-qp "bias_lonlat" $bias_lonlat "scalar") (serialize-qp "bias_ip" $bias_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/autocomplete/addresses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "query": $query, "context": $context, "limit": $limit, "postcode_outward": $postcode_outward, "postcode": $postcode, "postcode_area": $postcode_area, "postcode_sector": $postcode_sector, "post_town": $post_town, "uprn": $uprn, "country": $country, "postcode_type": $postcode_type, "su_organisation_indicator": $su_organisation_indicator, "box": $box, "bias_postcode_outward": $bias_postcode_outward, "bias_postcode": $bias_postcode, "bias_postcode_area": $bias_postcode_area, "bias_postcode_sector": $bias_postcode_sector, "bias_post_town": $bias_post_town, "bias_thoroughfare": $bias_thoroughfare, "bias_country": $bias_country, "bias_lonlat": $bias_lonlat, "bias_ip": $bias_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Resolve Address (GBR)
#
# GET /autocomplete/addresses/{address}/gbr
# operationId: Resolve
export def "autocomplete-addresses-gbr get-resolve" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/autocomplete/addresses/{address}/gbr") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Resolve Address (USA)
#
# GET /autocomplete/addresses/{address}/usa
# operationId: ResolveUsa
export def "autocomplete-addresses-usa get-resolve" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/autocomplete/addresses/{address}/usa") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Cleanse
#
# POST /cleanse/addresses
# operationId: AddressCleanse
export def "cleanse-addresses create-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  query: string # Freeform address input to cleanse (e.g. 10 Downing Street, London, SW2A 2BN)
]: any -> record<code: int, message: string, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cleanse/addresses" $qp $auth.query)
  let req_body = {"query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Email Validation
#
# GET /emails
# operationId: EmailValidation
export def "emails get-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --query: string # Specifies the email address to validate
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/emails" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Availability
#
# GET /keys/{key}
# operationId: KeyAvailability
export def "keys get-availability" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, result: record<available: bool, context: any, contexts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# List
#
# GET /keys/{key}/configs
# operationId: ListConfigs
export def "keys-configs list" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<configs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/configs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create
#
# POST /keys/{key}/configs
# operationId: CreateConfig
export def "keys-configs create" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  name: string # A unique name to identify the configuration payload (e.g. woocommerce)
  payload: string # A serialised payload of up to `4096` characters (e.g. {   "removeOrganisation": false } )
]: any -> record<code: int, message: string, result: record<createdAt: string, name: string, payload: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/configs") $qp $auth.query)
  let req_body = {"name": $name, "payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete
#
# DELETE /keys/{key}/configs/{config}
# operationId: DeleteConfig
export def "keys-configs delete" [
  key: string
  config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<deleted: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($config | is-empty) { error make --unspanned { msg: "path parameter 'config' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key), config: (encode-path-segment $config)} | format pattern "/keys/{key}/configs/{config}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve
#
# GET /keys/{key}/configs/{config}
# operationId: RetrieveConfig
export def "keys-configs get" [
  key: string
  config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, result: record<createdAt: string, name: string, payload: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($config | is-empty) { error make --unspanned { msg: "path parameter 'config' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key), config: (encode-path-segment $config)} | format pattern "/keys/{key}/configs/{config}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Update
#
# POST /keys/{key}/configs/{config}
# operationId: UpdateConfig
export def "keys-configs update" [
  key: string
  config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  --payload: string # A serialised payload of up to `4096` characters (e.g. {   "removeOrganisation": false } )
]: any -> record<code: int, message: string, result: record<createdAt: string, name: string, payload: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($config | is-empty) { error make --unspanned { msg: "path parameter 'config' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key), config: (encode-path-segment $config)} | format pattern "/keys/{key}/configs/{config}") $qp $auth.query)
  let req_body = {"payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Details
#
# GET /keys/{key}/details
# operationId: KeyDetails
export def "keys-details get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<allowed_urls: list<string>, automated_topups: record<enabled: bool>, current_purchases: list<record>, daily_limit: record<consumed: int, limit: int>, datasets: record<ecad: bool, ecaf: bool, herewe: bool, mr: bool, nyb: bool, paf: bool, pafa: bool, pafw: bool, usps: bool>, individual_limit: record<limit: int>, lookups_remaining: int, notifications: record<emails: list, enabled: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/details") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List
#
# GET /keys/{key}/licensees
# operationId: ListLicensees
export def "keys-licensees list" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --starting-after: int # Specify ID of the licensee after which you would like to list results (format: int32)
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  --limit: int # Specify the maximum number of results to return per page. Default and maximum is `100`. (format: int32, default: 10, e.g. 5)
  --query: string # Filter result by licensee name. Query can be shortened to `q=`
]: nothing -> record<code: int, message: string, result: record<hasMore: bool, licensees: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "user_token" $user_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/licensees") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"starting_after": $starting_after, "user_token": $user_token, "limit": $limit, "query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create
#
# POST /keys/{key}/licensees
# operationId: CreateLicensee
# --daily shape: {limit?: float}
export def "keys-licensees create" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  --address: string # Licensee's first, second and third line address as well as post town concatenated by commas (e.g. 12 High Street, Manchester)
  --daily: record # shape: {limit?: float}
  --name: string # Licensee individual or organisation name (e.g. Qwerty Widgets Limited)
  --postcode: string # Licensee's postcode (e.g. ID1 1QD)
  --whitelist: list<string> # A list of allowed URLs. An empty list means that whitelisting is disabled
]: any -> record<code: int, message: string, result: record<address: string, daily: record<count: float, updatedAt: string>, name: string, postcode: string, whitelist: list<string>, createdAt: string, id: string, key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/licensees") $qp $auth.query)
  let req_body = {"address": $address, "daily": $daily, "name": $name, "postcode": $postcode, "whitelist": $whitelist} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancel
#
# DELETE /keys/{key}/licensees/{licensee}
# operationId: DeleteLicensee
export def "keys-licensees delete" [
  key: string
  licensee: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<deleted: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($licensee | is-empty) { error make --unspanned { msg: "path parameter 'licensee' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key), licensee: (encode-path-segment $licensee)} | format pattern "/keys/{key}/licensees/{licensee}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve
#
# GET /keys/{key}/licensees/{licensee}
# operationId: RetrieveLicensee
export def "keys-licensees get" [
  key: string
  licensee: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<address: string, daily: record<count: float, updatedAt: string>, name: string, postcode: string, whitelist: list<string>, createdAt: string, id: string, key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($licensee | is-empty) { error make --unspanned { msg: "path parameter 'licensee' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key), licensee: (encode-path-segment $licensee)} | format pattern "/keys/{key}/licensees/{licensee}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update
#
# PUT /keys/{key}/licensees/{licensee}
# operationId: UpdateLicensee
# --daily shape: {limit?: float}
export def "keys-licensees update" [
  key: string
  licensee: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  --address: string # Licensee's first, second and third line address as well as post town concatenated by commas (e.g. 12 High Street, Manchester)
  --daily: record # shape: {limit?: float}
  --name: string # Licensee individual or organisation name (e.g. Qwerty Widgets Limited)
  --postcode: string # Licensee's postcode (e.g. ID1 1QD)
  --whitelist: list<string> # A list of allowed URLs. An empty list means that whitelisting is disabled
]: any -> record<code: int, message: string, result: record<address: string, daily: record<count: float, updatedAt: string>, name: string, postcode: string, whitelist: list<string>, createdAt: string, id: string, key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($licensee | is-empty) { error make --unspanned { msg: "path parameter 'licensee' must be non-empty" } }
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key), licensee: (encode-path-segment $licensee)} | format pattern "/keys/{key}/licensees/{licensee}") $qp $auth.query)
  let req_body = {"address": $address, "daily": $daily, "name": $name, "postcode": $postcode, "whitelist": $whitelist} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"user_token": $user_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Logs (CSV)
#
# GET /keys/{key}/lookups
# operationId: KeyLogs
export def "keys-lookups logs" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # An start date/time in the form of a UNIX Timestamp in milliseconds, e.g. `1418556452651`. If no start time is provided, the start time will be assigned to a time 21 days prior to the end time. (format: int32, e.g. 1418556452651)
  --end: int # An end date/time in the form of a UNIX Timestamp in milliseconds, e.g. `1418556452651`. If no end time is provided, the current time will be used. (format: int32, e.g. 1418556477882)
  --licensee: string # Sublicensed keys only. This will restrict the analysed dataset to a specific licensee. (e.g. sk_hk71kco54zGSGvF9eXXrvvnMOLLNh)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "licensee" $licensee "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/lookups") $qp $auth.query)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "licensee": $licensee} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Usage Stats
#
# GET /keys/{key}/usage
# operationId: KeyUsage
export def "keys-usage get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # A start date/time in the form of a UNIX Timestamp in milliseconds, e.g. `1418556452651`. If no start time is provided, the start time will be assigned to a time 21 days prior to the end time. (format: int32, e.g. 1418556452651)
  --end: int # An end date/time in the form of a UNIX Timestamp in milliseconds, e.g. `1418556452651`. If no end time is provided, the current time will be used. (format: int32, e.g. 1418556477882)
  --tags: string # e.g. foo,bar
  --licensee: string # Sublicensed keys only. This will restrict the analysed dataset to a specific licensee. (e.g. sk_hk71kco54zGSGvF9eXXrvvnMOLLNh)
]: nothing -> record<code: int, message: string, result: record<dailyCount: list<record>, end: string, start: string, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "licensee" $licensee "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/usage") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "tags": $tags, "licensee": $licensee} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Phone Number Validation
#
# GET /phone_numbers
# operationId: PhoneNumberValidation
export def "phone-numbers get-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --query: string # Specifies the phone number to validate. Phone number must include a country code in acceptable format. For instance, UK phone numbers should be suffixed `+44`, `44` or `0044`.
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_numbers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find Place
#
# GET /places
# operationId: FindPlace
export def "places find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --query: string # Specifies the place you wish to query. Query can be shortened to `q=`
  --country-iso: string # e.g. GBR
  --bias-country-iso: string # e.g. GBR
  --bias-lonlat: string # e.g. -2.095,57.15,100
  --bias-ip: string@bias-ip-completer # e.g. true
]: nothing -> record<code: int, message: string, result: record<hits: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "country_iso" $country_iso "scalar") (serialize-qp "bias_country_iso" $bias_country_iso "scalar") (serialize-qp "bias_lonlat" $bias_lonlat "scalar") (serialize-qp "bias_ip" $bias_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "query": $query, "country_iso": $country_iso, "bias_country_iso": $bias_country_iso, "bias_lonlat": $bias_lonlat, "bias_ip": $bias_ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Resolve Place
#
# GET /places/${place}
# operationId: ResolvePlace
export def "places-place get-resolve" [
  place: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($place | is-empty) { error make --unspanned { msg: "path parameter 'place' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({place: (encode-path-segment $place)} | format pattern "/places/${place}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lookup Postcode
#
# GET /postcodes/{postcode}
# operationId: Postcodes
export def "post-codes create" [
  postcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --filter: string # e.g. line_1,line_2,line_3
  --page: int # format: int32, default: 0, e.g. 0
]: nothing -> record<code: int, message: string, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($postcode | is-empty) { error make --unspanned { msg: "path parameter 'postcode' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postcode: (encode-path-segment $postcode)} | format pattern "/postcodes/{postcode}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "filter": $filter, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve by UDPRN
#
# GET /udprn/{udprn}
# operationId: UDPRN
export def "udprn get" [
  udprn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --filter: string # e.g. line_1,line_2,line_3
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($udprn | is-empty) { error make --unspanned { msg: "path parameter 'udprn' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({udprn: (encode-path-segment $udprn)} | format pattern "/udprn/{udprn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve by UMPRN
#
# GET /umprn/{umprn}
# operationId: UMPRN
export def "umprn get" [
  umprn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --filter: string # e.g. line_1,line_2,line_3
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($umprn | is-empty) { error make --unspanned { msg: "path parameter 'umprn' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({umprn: (encode-path-segment $umprn)} | format pattern "/umprn/{umprn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
