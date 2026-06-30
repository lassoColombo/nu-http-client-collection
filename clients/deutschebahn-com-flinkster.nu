# Auto-generated client for Flinkster_API_NG vv1
# Source: https://api.apis.guru/v2/specs/deutschebahn.com/flinkster/v1/swagger.json
# Auth: --token flag or $env.FLINKSTER_API_NG_TOKEN

const BASE_URL = "https://api.deutschebahn.com/flinkster-api-ng/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o FLINKSTER_API_NG_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.deutschebahn.com/flinkster-api-ng/v1" "http://api.deutschebahn.com/flinkster-api-ng/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "areas list" } } | get name | first)
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

# List Areas by Criteria.
#
# GET /areas
# operationId: listAreas
export def "areas list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # format: double
  --lon: float # format: double
  --radius: int # format: int32
  --offset: int # format: int32
  --limit: int # format: int32
  --expand: string
  --type: string
  --provider: string
  --providernetwork: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, address: record<city: string, district: string, isoCountryCode: string, number: string, street: string, zip: string>, attributes: record, description: string, expand: string, geometry: record<centroid: record<bbox: list, coordinates: record, crs: record>, position: record<bbox: list, crs: record>>, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerAreaId: string, providerNetworkIds: list<int>, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "providernetwork" $providernetwork "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/areas" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lat": $lat, "lon": $lon, "radius": $radius, "offset": $offset, "limit": $limit, "expand": $expand, "type": $type, "provider": $provider, "providernetwork": $providernetwork} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get area by UID.
#
# GET /areas/{areaUID}
# operationId: getArea
export def "areas get" [
  area_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand Provider
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, address: record<city: string, district: string, isoCountryCode: string, number: string, street: string, zip: string>, attributes: record, description: string, expand: string, geometry: record<centroid: record<bbox: list, coordinates: record, crs: record>, position: record<bbox: list, crs: record>>, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerAreaId: string, providerNetworkIds: list<int>, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($area_uid | is-empty) { error make --unspanned { msg: "path parameter 'areaUID' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({area_uid: (encode-path-segment $area_uid)} | format pattern "/areas/{area_uid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Query for available RentalObjects of a specific view
#
# GET /bookingproposals
# operationId: listBookingProposals
export def "bookingproposals list-booking-proposals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # format: double
  --lon: float # format: double
  --radius: int # format: int32
  --offset: int # format: int32
  --limit: int # format: int32
  --providernetwork: string
  --begin: string
  --end: string
  --expand: string
  --view: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "providernetwork" $providernetwork "scalar") (serialize-qp "begin" $begin "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bookingproposals" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lat": $lat, "lon": $lon, "radius": $radius, "offset": $offset, "limit": $limit, "providernetwork": $providernetwork, "begin": $begin, "end": $end, "expand": $expand, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Show index.
#
# GET /index
# operationId: getIndex
export def "index get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, href: string, items: table<_links: list, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, limit: int, offset: int, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/index" $auth.query)
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

# Lists all categories
#
# GET /providernetworks/{providernetworkUID}/categories
# operationId: listCategories
export def "providernetworks-categories list" [
  providernetwork_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, description: string, expand: string, href: string, name: string, price: table<_links: list, attributes: record, currency: string, description: string, expand: string, grossamount: float, href: string, interval: int, name: string, preferredprice: bool, taxrate: float, type: string, uid: string>, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($providernetwork_uid | is-empty) { error make --unspanned { msg: "path parameter 'providernetworkUID' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({providernetwork_uid: (encode-path-segment $providernetwork_uid)} | format pattern "/providernetworks/{providernetwork_uid}/categories") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Category by UID
#
# GET /providernetworks/{providernetworkUID}/categories/{categoryUID}
# operationId: getCategory
export def "providernetworks-categories get-category" [
  providernetwork_uid: string
  category_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, description: string, expand: string, href: string, name: string, price: table<_links: list, attributes: record, currency: string, description: string, expand: string, grossamount: float, href: string, interval: int, name: string, preferredprice: bool, taxrate: float, type: string, uid: string>, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($providernetwork_uid | is-empty) { error make --unspanned { msg: "path parameter 'providernetworkUID' must be non-empty" } }
  if ($category_uid | is-empty) { error make --unspanned { msg: "path parameter 'categoryUID' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({providernetwork_uid: (encode-path-segment $providernetwork_uid), category_uid: (encode-path-segment $category_uid)} | format pattern "/providernetworks/{providernetwork_uid}/categories/{category_uid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get information about the prices.
#
# GET /providernetworks/{providernetworkUID}/prices
# operationId: getPrices
export def "providernetworks-prices get" [
  providernetwork_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($providernetwork_uid | is-empty) { error make --unspanned { msg: "path parameter 'providernetworkUID' must be non-empty" } }
  let full_url = (build-url $base ({providernetwork_uid: (encode-path-segment $providernetwork_uid)} | format pattern "/providernetworks/{providernetwork_uid}/prices") $auth.query)
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

# Get information about the RentalObject.
#
# GET /providernetworks/{providernetworkUID}/rentalobjects/{rentalObjectUID}
# operationId: getRentalObject
export def "providernetworks-rentalobjects get-rental-object" [
  providernetwork_uid: string
  rental_object_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($providernetwork_uid | is-empty) { error make --unspanned { msg: "path parameter 'providernetworkUID' must be non-empty" } }
  if ($rental_object_uid | is-empty) { error make --unspanned { msg: "path parameter 'rentalObjectUID' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({providernetwork_uid: (encode-path-segment $providernetwork_uid), rental_object_uid: (encode-path-segment $rental_object_uid)} | format pattern "/providernetworks/{providernetwork_uid}/rentalobjects/{rental_object_uid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get information about the ProviderNetworkResources.
#
# GET /providernetworks/{uid}
# operationId: getProviderNetwork
export def "providernetworks get-provider-network" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({uid: (encode-path-segment $uid)} | format pattern "/providernetworks/{uid}") $auth.query)
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

# Get information about the ProviderResourceImpl.
#
# GET /providers/{uid}
# operationId: getProvider
export def "providers get" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: table<href: string, rel: string, verb: string>, attributes: record, category: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, price: list<record>, uid: string>, description: string, expand: string, href: string, name: string, provider: record<_links: list<record>, attributes: record, description: string, expand: string, href: string, name: string, uid: string>, providerNetworkIds: list<int>, providerRentalObjectId: string, rentalModel: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({uid: (encode-path-segment $uid)} | format pattern "/providers/{uid}") $auth.query)
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
