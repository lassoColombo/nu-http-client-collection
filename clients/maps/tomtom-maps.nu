# Auto-generated client for Maps v1.0.0
# Source: https://api.apis.guru/v2/specs/tomtom.com/maps/1.0.0/openapi.json
# Auth: --token flag or $env.MAPS_TOKEN

const BASE_URL = "https://api.tomtom.com"
const DEFAULT_AUTH = "query-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MAPS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-key" => { {headers: {}, query: $"key=($token_val)"} }
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

def base-url-completer [] { ["https://api.tomtom.com"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def layer-completer [] { ["basic" "hybrid" "labels"] }
def style-completer [] { ["main" "night"] }
def format-completer [] { ["jpeg" "jpg" "png"] }
def zoom-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "2" "20" "21" "22" "3" "4" "5" "6" "7" "8" "9"] }
def view-completer [] { ["IN" "Unified"] }
def view-completer-1 [] { ["IL" "IN" "Unified"] }
def tileSize-completer [] { ["256" "512"] }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  versionNumber: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callback: string # Specifies the jsonp callback method. Only used when format is jsonp
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/copyrights.($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Captions
#
# GET /map/{versionNumber}/copyrights/caption.{format}
export def "map-copyrights-caption-format get" [
  versionNumber: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callback: string # Specifies the jsonp callback method. Only used when format is jsonp
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/copyrights/caption.($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copyrights bounding box
#
# GET /map/{versionNumber}/copyrights/{minLon}/{minLat}/{maxLon}/{maxLat}.{format}
export def "map-copyrights get" [
  versionNumber: int
  format: string
  minLon: float
  minLat: float
  maxLon: float
  maxLat: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callback: string # Specifies the jsonp callback method. Only used when format is jsonp.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/copyrights/($minLon)/($minLat)/($maxLon)/($maxLat).($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copyrights tile
#
# GET /map/{versionNumber}/copyrights/{zoom}/{X}/{Y}.{format}
export def "map-copyrights list" [
  versionNumber: int
  format: string
  zoom: int
  X: int
  Y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callback: string # Specifies the jsonp callback method. Only used when format is jsonp.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/copyrights/($zoom)/($X)/($Y).($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Static Image
#
# GET /map/{versionNumber}/staticimage
export def "map-staticimage get" [
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --layer: string@layer-completer # Layer of image to be rendered. <em>Hybrid</em> and <em>labels</em> are intended for layering with other data and are only available in <em>png</em> format. (default: basic, e.g. basic)
  --style: string@style-completer # Map style to be returned (default: main, e.g. main)
  --format: string@format-completer # Image format to be returned (default: png, e.g. png)
  --zoom: int@zoom-completer # Zoom level of map image to be returned. (default: 12)
  --center: string # Coordinates for the center point of the image. Must be used with the <strong>width</strong> and <strong>height</strong> parameters; cannot be used with <strong>bbox</strong>. Uses EPSG:3857 projection (functionally equivalent to EPSG:900910). (e.g. 4.899886, 52.379031)
  --width: int # Width of the resulting image in pixels. Width must be a positive integer between 1 and 8192. (default: 512, e.g. 512)
  --height: int # Height of the resulting image in pixels. Height must be a positive integer between 1 and 8192. (default: 512, e.g. 512)
  --bbox: string # Bounding box for the image, using EPSG:3857 projection (functionally equivalent to EPSG:900910). Values <strong>must</strong> be in the order of minLon, minLat, maxLon, maxLat. MaxLat must be greater than minLat. Longitude values can be on both sides of the 180th meridian. Cannot be used with <strong>center</strong>, <strong>width</strong>, or <strong>height</strong> parameters.
  --view: string@view-completer # Geopolitical view. Determines rendering of disputed areas. See the <a href="/maps-api/maps-api-documentation-raster/raster-tile">documentation</a> for an explanation of how this works in live services. (e.g. Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "layer" $layer "scalar") (serialize-qp "style" $style "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "zoom" $zoom "scalar") (serialize-qp "center" $center "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/staticimage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tile
#
# GET /map/{versionNumber}/tile/{layer}/{style}/{zoom}/{X}/{Y}.pbf
export def "map-tile list" [
  versionNumber: int
  layer: string
  style: string
  zoom: int
  X: int
  Y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view: string@view-completer-1 # Geopolitical view. Determines rendering of disputed areas. See the <a href="/maps-api/maps-api-documentation-vector/tile">documentation</a> for an explanation of how this works in live services. (e.g. Unified)
  --language: string # Language to be used for labels in the response. The default is NGT: Neutral Ground Truth, which uses each place's local official language and script (where available). See the <a href="/maps-api/maps-api-documentation-vector/tile">documentation</a> for a full list of options. (default: NGT)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/tile/($layer)/($style)/($zoom)/($X)/($Y).pbf" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tile
#
# GET /map/{versionNumber}/tile/{layer}/{style}/{zoom}/{X}/{Y}.{format}
export def "map-tile get" [
  versionNumber: int
  layer: string
  style: string
  zoom: int
  X: int
  Y: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tileSize: int@tileSize-completer # Tile dimensions in pixels. <em>512</em> is only available for the <em>main</em> style and <em>basic</em> or <em>labels</em> layers. (default: 256)
  --view: string@view-completer # Geopolitical view. Determines rendering of disputed areas. See the <a href="/maps-sdk-web/functional-examples#geopolitical-views">documentation</a> for an explanation of how this works in live services. (e.g. Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tileSize" $tileSize "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/tile/($layer)/($style)/($zoom)/($X)/($Y).($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetMap
#
# GET /map/{versionNumber}/wms/
# operationId: GetMap
export def "map-wms GetMap" [
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request: string@request-completer # Request type
  --srs: string@srs-completer # Projection used in describing the <b>bbox</b> EPSG:3857 is recommended, particularly at higher zoom levels. (Note that EPSG:3857 is functionally equivalent to EPSG:900913/EPSG:3785) (e.g. EPSG:4326)
  --bbox: string # Bounding box in the projection stated in <b>srs</b> (minLon,minLat,maxLon,maxLat) (e.g. -0.489,51.28,0.236,51.686)
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
  let qp = [(serialize-qp "request" $request "scalar") (serialize-qp "srs" $srs "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "layers" $layers "scalar") (serialize-qp "styles" $styles "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/wms/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetCapabilities
#
# GET /map/{versionNumber}/wms//
# operationId: GetCapabilities
export def "map-wms GetCapabilities" [
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service: string@service-completer
  --request: string@request-completer-1
  --version: string@version-completer # WMS service version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "request" $request "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/map/($versionNumber)/wms//" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WMTS
#
# GET /map/{versionNumber}/wmts/{key}/{wmtsVersion}/WMTSCapabilities.xml
export def "map-wmts-wmts-capabilitiesxml get" [
  versionNumber: int
  key: string
  wmtsVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/map/($versionNumber)/wmts/($key)/($wmtsVersion)/WMTSCapabilities.xml")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
