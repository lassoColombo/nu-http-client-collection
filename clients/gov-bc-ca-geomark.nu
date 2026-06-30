# Auto-generated client for GeoMark Web Service REST API v4.1.2
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/geomark/4.1.2/openapi.json
# Auth: --token flag or $env.GEOMARK_WEB_SERVICE_REST_API_TOKEN

const BASE_URL = "https://apps.gov.bc.ca/pub/geomark"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GEOMARK_WEB_SERVICE_REST_API_TOKEN | default "" }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/geomarks/copy" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"geomarkUrl": $geomark_url, "resultFormat": $result_format, "allowOverlap": $allow_overlap, "callback": $callback, "redirectUrl": $redirect_url, "failureRedirectUrl": $failure_redirect_url, "bufferMetres": $buffer_metres, "bufferJoin": $buffer_join, "bufferCap": $buffer_cap, "bufferMitreLimit": $buffer_mitre_limit, "bufferSegments": $buffer_segments} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 302]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/geomarks/new" $auth.query)
  let req_body = {"allowOverlap": $allow_overlap, "body": $body, "bufferCap": $buffer_cap, "bufferJoin": $buffer_join, "bufferMetres": $buffer_metres, "bufferMitreLimit": $buffer_mitre_limit, "bufferSegments": $buffer_segments, "callback": $callback, "failureRedirectUrl": $failure_redirect_url, "format": $format, "multiple": $multiple, "redirectUrl": $redirect_url, "resultFormat": $result_format, "srid": $srid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200 302]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($geomark_id | is-empty) { error make --unspanned { msg: "path parameter 'geomarkId' must be non-empty" } }
  if ($file_format_extension | is-empty) { error make --unspanned { msg: "path parameter 'fileFormatExtension' must be non-empty" } }
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}.{file_format_extension}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"srid": $srid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($geomark_id | is-empty) { error make --unspanned { msg: "path parameter 'geomarkId' must be non-empty" } }
  if ($file_format_extension | is-empty) { error make --unspanned { msg: "path parameter 'fileFormatExtension' must be non-empty" } }
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}/boundingBox.{file_format_extension}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"srid": $srid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($geomark_id | is-empty) { error make --unspanned { msg: "path parameter 'geomarkId' must be non-empty" } }
  if ($file_format_extension | is-empty) { error make --unspanned { msg: "path parameter 'fileFormatExtension' must be non-empty" } }
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}/feature.{file_format_extension}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"srid": $srid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($geomark_id | is-empty) { error make --unspanned { msg: "path parameter 'geomarkId' must be non-empty" } }
  if ($file_format_extension | is-empty) { error make --unspanned { msg: "path parameter 'fileFormatExtension' must be non-empty" } }
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}/parts.{file_format_extension}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"srid": $srid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --srid: int@srid-completer # The srid of the coordinate system the geometry should be converted to. (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($geomark_id | is-empty) { error make --unspanned { msg: "path parameter 'geomarkId' must be non-empty" } }
  if ($file_format_extension | is-empty) { error make --unspanned { msg: "path parameter 'fileFormatExtension' must be non-empty" } }
  let qp = [(serialize-qp "srid" $srid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geomark_id: (encode-path-segment $geomark_id), file_format_extension: (encode-path-segment $file_format_extension)} | format pattern "/geomarks/{geomark_id}/point.{file_format_extension}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"srid": $srid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
