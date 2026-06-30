# Auto-generated client for Maps v1.0.0
# Source: https://api.apis.guru/v2/specs/tomtom.com/maps/1.0.0/openapi.json
# Auth: --token flag or $env.MAPS_TOKEN

const BASE_URL = "https://api.tomtom.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MAPS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://api.tomtom.com"] }
def auth-scheme-completer [] { ["query-key" "none"] }

# Completers for enum parameters
def layer-completer [] { ["basic" "hybrid" "labels"] }
def style-completer [] { ["main" "night"] }
def format-completer [] { ["jpeg" "jpg" "png"] }
def zoom-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "2" "20" "21" "22" "3" "4" "5" "6" "7" "8" "9"] }
def view-completer [] { ["IN" "Unified"] }
def view-completer-1 [] { ["IL" "IN" "Unified"] }
def tile-size-completer [] { ["256" "512"] }
def request-completer [] { ["GetMap"] }
def srs-completer [] { ["EPSG:3857" "EPSG:4326"] }
def format-completer-1 [] { ["image/jpeg" "image/png"] }
def layers-completer [] { ["basic"] }
def styles-completer [] { [""] }
def service-completer [] { ["WMS"] }
def version-completer [] { ["1.1.1"] }
def request-completer-1 [] { ["GetCapabilities"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "map-copyrights-format get" } } | get name | first)
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

# Copyrights whole world
#
# GET /map/{versionNumber}/copyrights.{format}
export def "map-copyrights-format get" [
  version_number: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Specifies the jsonp callback method. Only used when format is jsonp
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), format: (encode-path-segment $format)} | format pattern "/map/{version_number}/copyrights.{format}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"callback": $callback} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Captions
#
# GET /map/{versionNumber}/copyrights/caption.{format}
export def "map-copyrights-caption-format get" [
  version_number: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Specifies the jsonp callback method. Only used when format is jsonp
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), format: (encode-path-segment $format)} | format pattern "/map/{version_number}/copyrights/caption.{format}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"callback": $callback} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Copyrights bounding box
#
# GET /map/{versionNumber}/copyrights/{minLon}/{minLat}/{maxLon}/{maxLat}.{format}
export def "map-copyrights get" [
  version_number: int
  min_lon: float
  min_lat: float
  max_lon: float
  max_lat: float
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Specifies the jsonp callback method. Only used when format is jsonp.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  if ($min_lon | is-empty) { error make --unspanned { msg: "path parameter 'minLon' must be non-empty" } }
  if ($min_lat | is-empty) { error make --unspanned { msg: "path parameter 'minLat' must be non-empty" } }
  if ($max_lon | is-empty) { error make --unspanned { msg: "path parameter 'maxLon' must be non-empty" } }
  if ($max_lat | is-empty) { error make --unspanned { msg: "path parameter 'maxLat' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), min_lon: (encode-path-segment $min_lon), min_lat: (encode-path-segment $min_lat), max_lon: (encode-path-segment $max_lon), max_lat: (encode-path-segment $max_lat), format: (encode-path-segment $format)} | format pattern "/map/{version_number}/copyrights/{min_lon}/{min_lat}/{max_lon}/{max_lat}.{format}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"callback": $callback} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Copyrights tile
#
# GET /map/{versionNumber}/copyrights/{zoom}/{X}/{Y}.{format}
export def "map-copyrights list" [
  version_number: int
  zoom: int
  x: int
  y: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Specifies the jsonp callback method. Only used when format is jsonp.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  if ($zoom | is-empty) { error make --unspanned { msg: "path parameter 'zoom' must be non-empty" } }
  if ($x | is-empty) { error make --unspanned { msg: "path parameter 'X' must be non-empty" } }
  if ($y | is-empty) { error make --unspanned { msg: "path parameter 'Y' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), zoom: (encode-path-segment $zoom), x: (encode-path-segment $x), y: (encode-path-segment $y), format: (encode-path-segment $format)} | format pattern "/map/{version_number}/copyrights/{zoom}/{x}/{y}.{format}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"callback": $callback} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Static Image
#
# GET /map/{versionNumber}/staticimage
export def "map-staticimage get" [
  version_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --layer: string@layer-completer # Layer of image to be rendered. Hybrid and labels are intended for layering with other data and are only available in png format. (default: basic, e.g. basic)
  --style: string@style-completer # Map style to be returned (default: main, e.g. main)
  --format: string@format-completer # Image format to be returned (default: png, e.g. png)
  --zoom: int@zoom-completer # Zoom level of map image to be returned. (default: 12)
  --center: string # Coordinates for the center point of the image. Must be used with the width and height parameters; cannot be used with bbox. Uses EPSG:3857 projection (functionally equivalent to EPSG:900910). (e.g. 4.899886, 52.379031)
  --width: int # Width of the resulting image in pixels. Width must be a positive integer between 1 and 8192. (default: 512, e.g. 512)
  --height: int # Height of the resulting image in pixels. Height must be a positive integer between 1 and 8192. (default: 512, e.g. 512)
  --bbox: string # Bounding box for the image, using EPSG:3857 projection (functionally equivalent to EPSG:900910). Values must be in the order of minLon, minLat, maxLon, maxLat. MaxLat must be greater than minLat. Longitude values can be on both sides of the 180th meridian. Cannot be used with center, width, or height parameters.
  --view: string@view-completer # Geopolitical view. Determines rendering of disputed areas. See the documentation (/maps-api/maps-api-documentation-raster/raster-tile) for an explanation of how this works in live services. (e.g. Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  let qp = [(serialize-qp "layer" $layer "scalar") (serialize-qp "style" $style "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "zoom" $zoom "scalar") (serialize-qp "center" $center "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number)} | format pattern "/map/{version_number}/staticimage") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"layer": $layer, "style": $style, "format": $format, "zoom": $zoom, "center": $center, "width": $width, "height": $height, "bbox": $bbox, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Tile
#
# GET /map/{versionNumber}/tile/{layer}/{style}/{zoom}/{X}/{Y}.pbf
export def "map-tile list" [
  version_number: int
  layer: string
  style: string
  zoom: int
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: string@view-completer-1 # Geopolitical view. Determines rendering of disputed areas. See the documentation (/maps-api/maps-api-documentation-vector/tile) for an explanation of how this works in live services. (e.g. Unified)
  --language: string # Language to be used for labels in the response. The default is NGT: Neutral Ground Truth, which uses each place's local official language and script (where available). See the documentation (/maps-api/maps-api-documentation-vector/tile) for a full list of options. (default: NGT)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  if ($layer | is-empty) { error make --unspanned { msg: "path parameter 'layer' must be non-empty" } }
  if ($style | is-empty) { error make --unspanned { msg: "path parameter 'style' must be non-empty" } }
  if ($zoom | is-empty) { error make --unspanned { msg: "path parameter 'zoom' must be non-empty" } }
  if ($x | is-empty) { error make --unspanned { msg: "path parameter 'X' must be non-empty" } }
  if ($y | is-empty) { error make --unspanned { msg: "path parameter 'Y' must be non-empty" } }
  let qp = [(serialize-qp "view" $view "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), layer: (encode-path-segment $layer), style: (encode-path-segment $style), zoom: (encode-path-segment $zoom), x: (encode-path-segment $x), y: (encode-path-segment $y)} | format pattern "/map/{version_number}/tile/{layer}/{style}/{zoom}/{x}/{y}.pbf") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"view": $view, "language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Tile
#
# GET /map/{versionNumber}/tile/{layer}/{style}/{zoom}/{X}/{Y}.{format}
export def "map-tile get" [
  version_number: int
  layer: string
  style: string
  zoom: int
  x: int
  y: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tile-size: int@tile-size-completer # Tile dimensions in pixels. 512 is only available for the main style and basic or labels layers. (default: 256)
  --view: string@view-completer # Geopolitical view. Determines rendering of disputed areas. See the documentation (/maps-sdk-web/functional-examples#geopolitical-views) for an explanation of how this works in live services. (e.g. Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  if ($layer | is-empty) { error make --unspanned { msg: "path parameter 'layer' must be non-empty" } }
  if ($style | is-empty) { error make --unspanned { msg: "path parameter 'style' must be non-empty" } }
  if ($zoom | is-empty) { error make --unspanned { msg: "path parameter 'zoom' must be non-empty" } }
  if ($x | is-empty) { error make --unspanned { msg: "path parameter 'X' must be non-empty" } }
  if ($y | is-empty) { error make --unspanned { msg: "path parameter 'Y' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "tileSize" $tile_size "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), layer: (encode-path-segment $layer), style: (encode-path-segment $style), zoom: (encode-path-segment $zoom), x: (encode-path-segment $x), y: (encode-path-segment $y), format: (encode-path-segment $format)} | format pattern "/map/{version_number}/tile/{layer}/{style}/{zoom}/{x}/{y}.{format}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tileSize": $tile_size, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 302]
}

# GetMap
#
# GET /map/{versionNumber}/wms/
# operationId: GetMap
export def "map-wms get" [
  version_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request: string@request-completer # Request type
  --srs: string@srs-completer # Projection used in describing the bbox EPSG:3857 is recommended, particularly at higher zoom levels. (Note that EPSG:3857 is functionally equivalent to EPSG:900913/EPSG:3785) (e.g. EPSG:4326)
  --bbox: string # Bounding box in the projection stated in srs (minLon,minLat,maxLon,maxLat) (e.g. -0.489,51.28,0.236,51.686)
  --width: int # Width of the resulting image, in pixels Maximum value is 2048 (e.g. 512)
  --height: int # Height of the resulting image, in pixels Maximum value is 2048 (e.g. 512)
  --format: string@format-completer-1 # Image format to be returned (e.g. image/png)
  --layers: string@layers-completer # Map layers requested Currently only the basic layer is available
  --styles: string@styles-completer # Map styles to be returned. Currently, no styles are available. This parameter is present for forward compatibility; it must be used and left blank. (allows empty value)
  --service: string@service-completer # Service type
  --version: string@version-completer # WMS service version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  let qp = [(serialize-qp "request" $request "scalar") (serialize-qp "srs" $srs "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "layers" $layers "scalar") (serialize-qp "styles" $styles "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number)} | format pattern "/map/{version_number}/wms/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"request": $request, "srs": $srs, "bbox": $bbox, "width": $width, "height": $height, "format": $format, "layers": $layers, "styles": $styles, "service": $service, "version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# GetCapabilities
#
# GET /map/{versionNumber}/wms//
# operationId: GetCapabilities
export def "map-wms get-capabilities" [
  version_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string@service-completer
  --request: string@request-completer-1
  --version: string@version-completer # WMS service version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "request" $request "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number)} | format pattern "/map/{version_number}/wms//") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"service": $service, "request": $request, "version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# WMTS
#
# GET /map/{versionNumber}/wmts/{key}/{wmtsVersion}/WMTSCapabilities.xml
export def "map-wmts-wmts-capabilities-xml get" [
  version_number: int
  key: string
  wmts_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($version_number | is-empty) { error make --unspanned { msg: "path parameter 'versionNumber' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($wmts_version | is-empty) { error make --unspanned { msg: "path parameter 'wmtsVersion' must be non-empty" } }
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), key: (encode-path-segment $key), wmts_version: (encode-path-segment $wmts_version)} | format pattern "/map/{version_number}/wmts/{key}/{wmts_version}/WMTSCapabilities.xml") $auth.query)
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
