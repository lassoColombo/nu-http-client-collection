# Auto-generated client for Instagram API v1.0.0
# Source: https://api.apis.guru/v2/specs/instagram.com/1.0.0/swagger.json
# Auth: --token flag or $env.INSTAGRAM_API_TOKEN

const BASE_URL = "https://api.instagram.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o INSTAGRAM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-access_token" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "access_token")=(encode-path-segment $token_val)", location: "query"} }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.instagram.com/v1"] }
def auth-scheme-completer [] { ["query-access_token" "bearer"] }

# Completers for enum parameters
def action-completer [] { ["approve" "block" "follow" "ignore" "unblock" "unfollow"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "geographies-media-recent get" } } | get name | first)
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

# Get recent media from a custom geo-id.
#
# GET /geographies/{geo-id}/media/recent
# DEPRECATED
@deprecated
export def "geographies-media-recent get" [
  geo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Max number of media to return. (format: int32)
  --min-id: string # Return media before this `min_id`.
]: nothing -> record<data: table<attribution: string, caption: record, comments: record, created_time: string, filter: string, id: string, images: record, likes: record, link: string, location: record, tags: list, type: string, user: record, user_has_liked: bool, users_in_photo: list, videos: record>, meta: record<code: int>, pagination: record<next_max_id: string, next_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($geo_id | is-empty) { error make --unspanned { msg: "path parameter 'geo-id' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geo_id: (encode-path-segment $geo_id)} | format pattern "/geographies/{geo_id}/media/recent") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for a location by geographic coordinate.
#
# GET /locations/search
export def "locations-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --distance: int # Default is 1000m (distance=1000), max distance is 5000. (format: int32)
  --facebook-places-id: string # Returns a location mapped off of a Facebook places id. If used, a Foursquare id and `lat`, `lng` are not required.
  --foursquare-id: string # Returns a location mapped off of a foursquare v1 api location id. If used, you are not required to use `lat` and `lng`. Note that this method is deprecated; you should use the new foursquare IDs with V2 of their API.
  --lat: float # Latitude of the center search coordinate. If used, `lng` is required. (format: double)
  --lng: float # Longitude of the center search coordinate. If used, `lat` is required. (format: double)
  --foursquare-v2-id: string # Returns a location mapped off of a foursquare v2 api location id. If used, you are not required to use `lat` and `lng`.
]: nothing -> record<data: table<id: string, latitude: float, longitude: float, name: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "distance" $distance "scalar") (serialize-qp "facebook_places_id" $facebook_places_id "scalar") (serialize-qp "foursquare_id" $foursquare_id "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "foursquare_v2_id" $foursquare_v2_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locations/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"distance": $distance, "facebook_places_id": $facebook_places_id, "foursquare_id": $foursquare_id, "lat": $lat, "lng": $lng, "foursquare_v2_id": $foursquare_v2_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get information about a location.
#
# GET /locations/{location-id}
export def "locations get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, latitude: float, longitude: float, name: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location-id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/locations/{location_id}") $auth.query)
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

# Get a list of recent media objects from a given location.
#
# GET /locations/{location-id}/media/recent
export def "locations-media-recent get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-timestamp: int # Return media after this UNIX timestamp. (format: int64)
  --max-timestamp: int # Return media before this UNIX timestamp. (format: int64)
  --min-id: string # Return media before this `min_id`.
  --max-id: string # Return media after this `max_id`.
]: nothing -> record<data: table<attribution: string, caption: record, comments: record, created_time: string, filter: string, id: string, images: record, likes: record, link: string, location: record, tags: list, type: string, user: record, user_has_liked: bool, users_in_photo: list, videos: record>, meta: record<code: int>, pagination: record<next_max_id: string, next_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location-id' must be non-empty" } }
  let qp = [(serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "max_id" $max_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/locations/{location_id}/media/recent") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"min_timestamp": $min_timestamp, "max_timestamp": $max_timestamp, "min_id": $min_id, "max_id": $max_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of currently popular media.
#
# GET /media/popular
# DEPRECATED
@deprecated
export def "media-popular get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<attribution: string, caption: record, comments: record, created_time: string, filter: string, id: string, images: record, likes: record, link: string, location: record, tags: list, type: string, user: record, user_has_liked: bool, users_in_photo: list, videos: record>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/media/popular" $auth.query)
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

# Search for media in a given area.
#
# GET /media/search
export def "media-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # Latitude of the center search coordinate. If used, `lng` is required. (format: double)
  --lng: float # Longitude of the center search coordinate. If used, `lat` is required. (format: double)
  --min-timestamp: int # A unix timestamp. All media returned will be taken later than this timestamp. (format: int64)
  --max-timestamp: int # A unix timestamp. All media returned will be taken earlier than this timestamp. (format: int64)
  --distance: int # Default is 1km (distance=1000), max distance is 5km. (format: int32)
]: nothing -> record<data: table<attribution: string, caption: record, comments: record, created_time: string, filter: string, id: string, images: record, likes: record, link: string, location: record, tags: list, type: string, user: record, user_has_liked: bool, users_in_photo: list, videos: record>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar") (serialize-qp "distance" $distance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/media/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lat": $lat, "lng": $lng, "min_timestamp": $min_timestamp, "max_timestamp": $max_timestamp, "distance": $distance} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get information about a media object.
#
# GET /media/shortcode/{shortcode}
export def "media-shortcode get" [
  shortcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attribution: string, caption: record<created_time: string, from: record, id: string, text: string>, comments: record<count: int, data: list>, created_time: string, filter: string, id: string, images: record<low_resolution: record, standard_resolution: record, thumbnail: record>, likes: record<count: int, data: list>, link: string, location: record<id: string, latitude: float, longitude: float, name: string>, tags: list<string>, type: string, user: record<full_name: string, id: string, profile_picture: string, username: string>, user_has_liked: bool, users_in_photo: list<record>, videos: record<low_resolution: record, standard_resolution: record>>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($shortcode | is-empty) { error make --unspanned { msg: "path parameter 'shortcode' must be non-empty" } }
  let full_url = (build-url $base ({shortcode: (encode-path-segment $shortcode)} | format pattern "/media/shortcode/{shortcode}") $auth.query)
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

# Get information about a media object.
#
# GET /media/{media-id}
export def "media get" [
  media_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attribution: string, caption: record<created_time: string, from: record, id: string, text: string>, comments: record<count: int, data: list>, created_time: string, filter: string, id: string, images: record<low_resolution: record, standard_resolution: record, thumbnail: record>, likes: record<count: int, data: list>, link: string, location: record<id: string, latitude: float, longitude: float, name: string>, tags: list<string>, type: string, user: record<full_name: string, id: string, profile_picture: string, username: string>, user_has_liked: bool, users_in_photo: list<record>, videos: record<low_resolution: record, standard_resolution: record>>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media-id' must be non-empty" } }
  let full_url = (build-url $base ({media_id: (encode-path-segment $media_id)} | format pattern "/media/{media_id}") $auth.query)
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

# Get a list of recent comments on a media object.
#
# GET /media/{media-id}/comments
export def "media-comments get" [
  media_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created_time: string, from: record, id: string, text: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media-id' must be non-empty" } }
  let full_url = (build-url $base ({media_id: (encode-path-segment $media_id)} | format pattern "/media/{media_id}/comments") $auth.query)
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

# Create a comment on a media object.
#
# POST /media/{media-id}/comments
export def "media-comments create" [
  media_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Text to post as a comment on the media object as specified in `media-id`.
]: nothing -> record<data: string, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media-id' must be non-empty" } }
  let qp = [(serialize-qp "text" $text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({media_id: (encode-path-segment $media_id)} | format pattern "/media/{media_id}/comments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"text": $text} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Remove a comment.
#
# DELETE /media/{media-id}/comments/{comment-id}
export def "media-comments delete" [
  media_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: string, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media-id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment-id' must be non-empty" } }
  let full_url = (build-url $base ({media_id: (encode-path-segment $media_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/media/{media_id}/comments/{comment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Remove a like on this media by the current user.
#
# DELETE /media/{media-id}/likes
export def "media-likes delete" [
  media_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: string, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media-id' must be non-empty" } }
  let full_url = (build-url $base ({media_id: (encode-path-segment $media_id)} | format pattern "/media/{media_id}/likes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get a list of users who have liked this media.
#
# GET /media/{media-id}/likes
export def "media-likes get" [
  media_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<full_name: string, id: string, profile_picture: string, username: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media-id' must be non-empty" } }
  let full_url = (build-url $base ({media_id: (encode-path-segment $media_id)} | format pattern "/media/{media_id}/likes") $auth.query)
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

# Set a like on this media by the current user.
#
# POST /media/{media-id}/likes
export def "media-likes create" [
  media_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: string, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media-id' must be non-empty" } }
  let full_url = (build-url $base ({media_id: (encode-path-segment $media_id)} | format pattern "/media/{media_id}/likes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Search for tags by name.
#
# GET /tags/search
export def "tags-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A valid tag name without a leading \#. (eg. snowy, nofilter)
]: nothing -> record<data: table<media_count: int, name: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get information about a tag object.
#
# GET /tags/{tag-name}
export def "tags get" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<media_count: int, name: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag-name' must be non-empty" } }
  let full_url = (build-url $base ({tag_name: (encode-path-segment $tag_name)} | format pattern "/tags/{tag_name}") $auth.query)
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

# Get a list of recently tagged media.
#
# GET /tags/{tag-name}/media/recent
export def "tags-media-recent get" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Count of tagged media to return.
  --min-tag-id: string # Return media before this `min_tag_id`.
  --max-tag-id: string # Return media after this `max_tag_id`.
]: nothing -> record<data: table<attribution: string, caption: record, comments: record, created_time: string, filter: string, id: string, images: record, likes: record, link: string, location: record, tags: list, type: string, user: record, user_has_liked: bool, users_in_photo: list, videos: record>, meta: record<code: int>, pagination: record<deprecation_warning: string, min_tag_id: string, next_max_id: string, next_max_tag_id: string, next_min_id: string, next_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag-name' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "min_tag_id" $min_tag_id "scalar") (serialize-qp "max_tag_id" $max_tag_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag_name: (encode-path-segment $tag_name)} | format pattern "/tags/{tag_name}/media/recent") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "min_tag_id": $min_tag_id, "max_tag_id": $max_tag_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for a user by name.
#
# GET /users/search
export def "users-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A query string.
  --count: int # Number of users to return.
]: nothing -> record<data: table<full_name: string, id: string, profile_picture: string, username: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# See the authenticated user's feed.
#
# GET /users/self/feed
# DEPRECATED
@deprecated
export def "users-self-feed get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Count of media to return.
  --min-id: string # Return media later than this `min_id`.
  --max-id: string # Return media earlier than this `max_id`.
]: nothing -> record<data: table<attribution: string, caption: record, comments: record, created_time: string, filter: string, id: string, images: record, likes: record, link: string, location: record, tags: list, type: string, user: record, user_has_liked: bool, users_in_photo: list, videos: record>, meta: record<code: int>, pagination: record<next_max_id: string, next_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "max_id" $max_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/self/feed" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "min_id": $min_id, "max_id": $max_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# See the list of media liked by the authenticated user.
#
# GET /users/self/media/liked
export def "users-self-media-liked get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Count of media to return.
  --max-like-id: string # Return media liked before this id.
]: nothing -> record<data: table<attribution: string, caption: record, comments: record, created_time: string, filter: string, id: string, images: record, likes: record, link: string, location: record, tags: list, type: string, user: record, user_has_liked: bool, users_in_photo: list, videos: record>, meta: record<code: int>, pagination: record<next_max_id: string, next_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "max_like_id" $max_like_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/self/media/liked" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "max_like_id": $max_like_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List the users who have requested this user's permission to follow.
#
# GET /users/self/requested-by
export def "users-self-requested-by get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<full_name: string, id: string, profile_picture: string, username: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/self/requested-by" $auth.query)
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

# Get basic information about a user.
#
# GET /users/{user-id}
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<bio: string, counts: record<followed_by: int, follows: int, media: int>, full_name: string, id: string, profile_picture: string, username: string, website: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user-id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $auth.query)
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

# Get the list of users this user is followed by.
#
# GET /users/{user-id}/followed-by
export def "users-followed-by get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<full_name: string, id: string, profile_picture: string, username: string>, meta: record<code: int>, pagination: record<next_cursor: string, next_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user-id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/followed-by") $auth.query)
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

# Get the list of users this user follows.
#
# GET /users/{user-id}/follows
export def "users-follows get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<full_name: string, id: string, profile_picture: string, username: string>, meta: record<code: int>, pagination: record<next_cursor: string, next_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user-id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/follows") $auth.query)
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

# Get the most recent media published by a user.
#
# GET /users/{user-id}/media/recent
export def "users-media-recent get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Count of media to return.
  --max-timestamp: int # Return media before this UNIX timestamp. (format: int64)
  --min-timestamp: int # Return media after this UNIX timestamp. (format: int64)
  --min-id: string # Return media later than this `min_id`.
  --max-id: string # Return media earlier than this `max_id`.
]: nothing -> record<data: table<attribution: string, caption: record, comments: record, created_time: string, filter: string, id: string, images: record, likes: record, link: string, location: record, tags: list, type: string, user: record, user_has_liked: bool, users_in_photo: list, videos: record>, meta: record<code: int>, pagination: record<next_max_id: string, next_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user-id' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "max_timestamp" $max_timestamp "scalar") (serialize-qp "min_timestamp" $min_timestamp "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "max_id" $max_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/media/recent") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count, "max_timestamp": $max_timestamp, "min_timestamp": $min_timestamp, "min_id": $min_id, "max_id": $max_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get information about a relationship to another user.
#
# GET /users/{user-id}/relationship
export def "users-relationship get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<incoming_status: string, outgoing_status: string, target_user_is_private: bool>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user-id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/relationship") $auth.query)
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

# Modify the relationship between the current user and the target user.
#
# POST /users/{user-id}/relationship
export def "users-relationship create" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # Type of action to apply for relationship with the user.
]: nothing -> record<data: record<outgoing_status: string>, meta: record<code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user-id' must be non-empty" } }
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/relationship") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"action": $action} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}
