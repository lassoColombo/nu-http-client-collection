# Auto-generated client for GeoMark Web Service REST API v4.1.2
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/geomark/4.1.2/openapi.json
# Auth: --token flag or $env.GEOMARK_WEB_SERVICE_REST_API_TOKEN

const BASE_URL = "https://apps.gov.bc.ca/pub/geomark"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GEOMARK_WEB_SERVICE_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://apps.gov.bc.ca/pub/geomark" "https://test.apps.gov.bc.ca/pub/geomark" "https://delivery.apps.gov.bc.ca/pub/geomark"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def result-format-completer [] { ["geojson" "gml" "gpkg" "json" "kml" "kmz" "shp" "shpz" "wkt" "xml"] }
def allow-overlap-completer [] { ["false" "true"] }
def buffer-join-completer [] { ["BEVEL" "MITRE" "ROUND"] }
def buffer-cap-completer [] { ["FLAT" "ROUND" "SQUARE"] }
def format-completer [] { ["geojson" "gml" "gpkg" "json" "kml" "kmz" "shp" "shpz" "wkt" "xml"] }
def multiple-completer [] { ["false" "true"] }
def srid-completer [] { ["26907" "26908" "26909" "26910" "26911" "3005" "3857" "4326"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "geomarks-copy create" } } | get name | first)
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

# Create a new geomark by copying the geometries from one or more existing geomarks from the current server.
#
# POST /geomarks/copy
export def "geomarks-copy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --geomark-url: string # One or more geomark URLs or identifiers to create the new geomark from. (e.g. https://apps.gov.bc.ca/pub/geomark/geomarks/gm-abcdefghijklmnopqrstuv0bcislands)
  --result-format: string@result-format-completer # The file format the geomark info resource should be returned using. (e.g. json)
  --allow-overlap: oneof<nothing, bool> # Select this option to allow overlapping geometries (default: false)
  --callback: string # The callback function a JSON result format would be wrapped in to support Ajax requests.
  --redirect-url: string # The optional external URL to redirect the user to when the geomark is created rather than showing the geomark info page. The geomarkId and geomarkUrl query string parameters will be added to the redirectUrl so that the target application gets a reference to the geomark.
  --failure-redirect-url: string # The url to redirect if the geomark could not be created. The URL will include a _Error parameter with the error message for the field that caused the error.
  --buffer-metres: int # The amount to buffer the geometry in metres, must only contain numerical digits (e.g 10). Leave blank and no buffer will be added to input geometries. If blank then any Point, LineString, MultiPoint and MultiLineString geometries will be ignored.
  --buffer-join: string@buffer-join-completer # If bufferMetres is specified, The style of buffer to use for joins between the line segments for lines and polygons. (default: ROUND)
  --buffer-cap: string@buffer-cap-completer # If bufferMetres is specified, The style of buffer to use at the ends of a buffered line. (default: ROUND)
  --buffer-mitre-limit: int # If bufferMetres is specified, the maximum ratio of distance from the original geometry to a mitre buffer point and the buffer amount. If the ratio is greater than this a bevel will be used instead. This prevents infinite distances when the angle between the two lines at a join is small. Must be > 0. (default: 5)
  --buffer-segments: int # If bufferMetres is specified, the number of line segments used in each quadrant to approximate the curve for round end-cap and join styles. Must be > 0. (default: 8)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geomarkUrl" $geomark_url "scalar") (serialize-qp "resultFormat" $result_format "scalar") (serialize-qp "allowOverlap" $allow_overlap "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "redirectUrl" $redirect_url "scalar") (serialize-qp "failureRedirectUrl" $failure_redirect_url "scalar") (serialize-qp "bufferMetres" $buffer_metres "scalar") (serialize-qp "bufferJoin" $buffer_join "scalar") (serialize-qp "bufferCap" $buffer_cap "scalar") (serialize-qp "bufferMitreLimit" $buffer_mitre_limit "scalar") (serialize-qp "bufferSegments" $buffer_segments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geomarks/copy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new geomark
#
# POST /geomarks/new
export def "geomarks-new create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-overlap: oneof<nothing, bool> # When multiple=true select this option to allow overlapping geometries (default: false)
  --body: string # The binary or character content representing the geometry or geometries
  --buffer-cap: string@buffer-cap-completer # If bufferMetres is specified, The style of buffer to use at the ends of a buffered line. (default: ROUND)
  --buffer-join: string@buffer-join-completer # If bufferMetres is specified, The style of buffer to use for joins between the line segments for lines and polygons. (default: ROUND)
  --buffer-metres: int # The amount to buffer the geometry in metres, must only contain numerical digits (e.g 10). Leave blank and no buffer will be added to input geometries. If blank then any Point, LineString, MultiPoint and MultiLineString geometries will be ignored.
  --buffer-mitre-limit: int # If bufferMetres is specified, the maximum ratio of distance from the original geometry to a mitre buffer point and the buffer amount. If the ratio is greater than this a bevel will be used instead. This prevents infinite distances when the angle between the two lines at a join is small. Must be > 0. (default: 5)
  --buffer-segments: int # If bufferMetres is specified, the number of line segments used in each quadrant to approximate the curve for round end-cap and join styles. Must be > 0. (default: 8)
  --callback: string # The callback function a JSON result format would be wrapped in to support Ajax requests.
  --failure-redirect-url: string # The url to redirect if the geomark could not be created. The URL will include a _Error parameter with the error message for the field that caused the error.
  --format: string@format-completer # The file format name extension of the input geometry.
  --multiple: oneof<nothing, bool> # Boolean flag indicating if multiple geometries are to be used for the geomark (true) or only a single geometry from the first geometry (false). (default: false)
  --redirect-url: string # The optional external URL to redirect the user to when the geomark is created rather than showing the geomark info page. The geomarkId and geomarkUrl query string parameters will be added to the redirectUrl so that the target application gets a reference to the geomark.
  --result-format: string@result-format-completer # The file format the geomark info resource should be returned using.
  --srid: int@srid-completer # The srid of the coordinate system the input geometries are in. If the file includes a coordinate system definition that will be used. (default: 4326)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geomarks/new")
  let req_body = {"allowOverlap": $allow_overlap, "body": $body, "bufferCap": $buffer_cap, "bufferJoin": $buffer_join, "bufferMetres": $buffer_metres, "bufferMitreLimit": $buffer_mitre_limit, "bufferSegments": $buffer_segments, "callback": $callback, "failureRedirectUrl": $failure_redirect_url, "format": $format, "multiple": $multiple, "redirectUrl": $redirect_url, "resultFormat": $result_format, "srid": $srid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Get information about a particular geomark
#
# GET /geomarks/{geomarkId}.{fileFormatExtension}
export def "geomarks get" [
  geomark_id: string
  file_format_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}.{file_format_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the bounding box of the geomark
#
# GET /geomarks/{geomarkId}/boundingBox.{fileFormatExtension}
export def "geomarks-bounding-box-file-format-extension get" [
  geomark_id: string
  file_format_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}/boundingBox.{file_format_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the feature and attribution of the geomark
#
# GET /geomarks/{geomarkId}/feature.{fileFormatExtension}
export def "geomarks-feature-file-format-extension get" [
  geomark_id: string
  file_format_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}/feature.{file_format_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the individual geometries within a multi-part geometry
#
# GET /geomarks/{geomarkId}/parts.{fileFormatExtension}
export def "geomarks-parts-file-format-extension get" [
  geomark_id: string
  file_format_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}/parts.{file_format_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a single spatial point representative of the geomark.
#
# GET /geomarks/{geomarkId}/point.{fileFormatExtension}
export def "geomarks-point-file-format-extension get" [
  geomark_id: string
  file_format_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}/point.{file_format_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
