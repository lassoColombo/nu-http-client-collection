# Auto-generated client for API Reference - Ideal Postcodes v3.7.0
# Source: https://api.apis.guru/v2/specs/ideal-postcodes.co.uk/3.7.0/openapi.json
# Auth: --token flag or $env.API_REFERENCE_IDEAL_POSTCODES_TOKEN

const BASE_URL = "https://api.ideal-postcodes.co.uk/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_REFERENCE_IDEAL_POSTCODES_TOKEN | default "" }
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
  let full_url = (build-url $base "/addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "query": $query, "limit": $limit, "page": $page, "filter": $filter, "lon": $lon, "lat": $lat, "postcode_outward": $postcode_outward, "postcode": $postcode, "postcode_area": $postcode_area, "postcode_sector": $postcode_sector, "post_town": $post_town, "uprn": $uprn, "country": $country, "postcode_type": $postcode_type, "su_organisation_indicator": $su_organisation_indicator, "box": $box, "bias_postcode_outward": $bias_postcode_outward, "bias_postcode": $bias_postcode, "bias_postcode_area": $bias_postcode_area, "bias_postcode_sector": $bias_postcode_sector, "bias_post_town": $bias_post_town, "bias_thoroughfare": $bias_thoroughfare, "bias_country": $bias_country, "bias_lonlat": $bias_lonlat} | compact), body: null}
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
  let full_url = (build-url $base "/autocomplete/addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "query": $query, "context": $context, "limit": $limit, "postcode_outward": $postcode_outward, "postcode": $postcode, "postcode_area": $postcode_area, "postcode_sector": $postcode_sector, "post_town": $post_town, "uprn": $uprn, "country": $country, "postcode_type": $postcode_type, "su_organisation_indicator": $su_organisation_indicator, "box": $box, "bias_postcode_outward": $bias_postcode_outward, "bias_postcode": $bias_postcode, "bias_postcode_area": $bias_postcode_area, "bias_postcode_sector": $bias_postcode_sector, "bias_post_town": $bias_post_town, "bias_thoroughfare": $bias_thoroughfare, "bias_country": $bias_country, "bias_lonlat": $bias_lonlat, "bias_ip": $bias_ip} | compact), body: null}
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
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/autocomplete/addresses/{address}/gbr") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key} | compact), body: null}
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
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/autocomplete/addresses/{address}/usa") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key} | compact), body: null}
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
  let full_url = (build-url $base "/cleanse/addresses" $qp)
  let req_body = {"query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api_key": $api_key} | compact), body: $req_body}
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
  let full_url = (build-url $base "/emails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "query": $query} | compact), body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/configs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_token": $user_token} | compact), body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/configs") $qp)
  let req_body = {"name": $name, "payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"user_token": $user_token} | compact), body: $req_body}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key), config: (encode-path-segment $config)} | format pattern "/keys/{key}/configs/{config}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_token": $user_token} | compact), body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key), config: (encode-path-segment $config)} | format pattern "/keys/{key}/configs/{config}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key), config: (encode-path-segment $config)} | format pattern "/keys/{key}/configs/{config}") $qp)
  let req_body = {"payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"user_token": $user_token} | compact), body: $req_body}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/details") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_token": $user_token} | compact), body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/licensees") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"starting_after": $starting_after, "user_token": $user_token, "limit": $limit, "query": $query} | compact), body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/licensees") $qp)
  let req_body = {"address": $address, "daily": $daily, "name": $name, "postcode": $postcode, "whitelist": $whitelist} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"user_token": $user_token} | compact), body: $req_body}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key), licensee: (encode-path-segment $licensee)} | format pattern "/keys/{key}/licensees/{licensee}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_token": $user_token} | compact), body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key), licensee: (encode-path-segment $licensee)} | format pattern "/keys/{key}/licensees/{licensee}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_token": $user_token} | compact), body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key), licensee: (encode-path-segment $licensee)} | format pattern "/keys/{key}/licensees/{licensee}") $qp)
  let req_body = {"address": $address, "daily": $daily, "name": $name, "postcode": $postcode, "whitelist": $whitelist} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"user_token": $user_token} | compact), body: $req_body}
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "licensee" $licensee "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/lookups") $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "licensee": $licensee} | compact), body: null}
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
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/keys/{key}/usage") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "end": $end, "tags": $tags, "licensee": $licensee} | compact), body: null}
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
  let full_url = (build-url $base "/phone_numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "query": $query} | compact), body: null}
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
  let full_url = (build-url $base "/places" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "query": $query, "country_iso": $country_iso, "bias_country_iso": $bias_country_iso, "bias_lonlat": $bias_lonlat, "bias_ip": $bias_ip} | compact), body: null}
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
  let full_url = (build-url $base ({place: (encode-path-segment $place)} | format pattern "/places/${place}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key} | compact), body: null}
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
  let full_url = (build-url $base ({postcode: (encode-path-segment $postcode)} | format pattern "/postcodes/{postcode}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "filter": $filter, "page": $page} | compact), body: null}
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
  let full_url = (build-url $base ({udprn: (encode-path-segment $udprn)} | format pattern "/udprn/{udprn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "filter": $filter} | compact), body: null}
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
  let full_url = (build-url $base ({umprn: (encode-path-segment $umprn)} | format pattern "/umprn/{umprn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "filter": $filter} | compact), body: null}
}
