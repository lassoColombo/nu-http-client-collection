# Auto-generated client for Cloud-RF API v2.0.0
# Source: https://api.apis.guru/v2/specs/cloudrf.com/2.0.0/openapi.json
# Auth: --token flag or $env.CLOUD_RF_API_TOKEN

const BASE_URL = "https://api.cloudrf.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_RF_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "key" => { {scheme: $scheme, headers: {key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.cloudrf.com"] }
def auth-scheme-completer [] { ["key"] }

# Completers for enum parameters
def fmt-completer [] { ["kml" "kml" "kmzppa" "shp" "tiff"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "archive-delete delete" } } | get name | first)
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

# Delete a calculation from the database.
#
# GET /archive/delete
# operationId: delete
export def "archive-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cid: int # Unique calculation ID number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cid" $cid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archive/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cid": $cid} | compact), body: null}
}

# Delete an entire network
#
# GET /archive/delete/network
# operationId: deleteNetwork
export def "archive-delete-network delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nid: string # Network name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nid" $nid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archive/delete/network" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nid": $nid} | compact), body: null}
}

# Export a calculation in a GIS file format
#
# GET /archive/export
# operationId: export
export def "archive-export export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # Calculation file name
  --fmt: string@fmt-completer # Raster/Vector file format: KML, KMZ, SHP, GeoTIFF
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar") (serialize-qp "fmt" $fmt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archive/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"file": $file, "fmt": $fmt} | compact), body: null}
}

# List calculations from your archive
#
# GET /archive/list
# operationId: list
export def "archive-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --n: float # North bounding box (format: float)
  --e: float # East bounding box (format: float)
  --s: float # South bounding box (format: float)
  --w: float # West bounding box (format: float)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "n" $n "scalar") (serialize-qp "e" $e "scalar") (serialize-qp "s" $s "scalar") (serialize-qp "w" $w "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archive/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"n": $n, "e": $e, "s": $s, "w": $w} | compact), body: null}
}

# Create a point-to-multipoint heatmap
#
# POST /area
# operationId: area
# --antenna shape: {ant?: int, azi?: int, hbw?: int, pol?: "h"|"v", tlt?: float, txg?: float, txl?: float, vbw?: int}
# --environment shape: {cll?: int, clm?: int, mat?: float}
# --model shape: {cli?: int, ked?: int, pe?: int, pm?: int, rel?: int, ter?: int}
# --output shape: {ber?: int, col?: string, mod?: int, nf?: int, out?: int, rad?: float, res?: int, units?: "metric"|"imperial"}
# --receiver shape: {alt?: float, lat?: float, lon?: float, rxg?: float, rxs?: float}
# --transmitter shape: {alt?: float, bwi?: float, frq?: float, lat?: float, lon?: float, txw?: float}
export def "area create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antenna: record # shape: {ant?: int, azi?: int, hbw?: int, pol?: "h"|"v", tlt?: float, txg?: float, txl?: float, vbw?: int}
  --environment: record # shape: {cll?: int, clm?: int, mat?: float}
  --model: record # shape: {cli?: int, ked?: int, pe?: int, pm?: int, rel?: int, ter?: int}
  --network: string # Network name/group (default: Testing)
  --output: record # shape: {ber?: int, col?: string, mod?: int, nf?: int, out?: int, rad?: float, res?: int, units?: "metric"|"imperial"}
  --receiver: record # shape: {alt?: float, lat?: float, lon?: float, rxg?: float, rxs?: float}
  --site: string # Site name (default: A1)
  --transmitter: record # shape: {alt?: float, bwi?: float, frq?: float, lat?: float, lon?: float, txw?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/area")
  let req_body = {"antenna": $antenna, "environment": $environment, "model": $model, "network": $network, "output": $output, "receiver": $receiver, "site": $site, "transmitter": $transmitter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Upload clutter data as GeoJSON
#
# POST /clutter/add
# operationId: addClutter
# --features item shape: {geometry?: string, properties?: string, type?: string}
export def "clutter-add create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --features: list # item shape: {geometry?: string, properties?: string, type?: string}
  --name: string # default: Clutter
  --type: string # default: FeatureCollection
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clutter/add")
  let req_body = {"features": $features, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find the best server for overlapping coverage
#
# GET /interference
# operationId: interference
export def "interference get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --network: string # Network name eg. Overlapping broadcast stations
  --name: string # Interference layer name eg. QRM_map
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "network" $network "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/interference" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"network": $network, "name": $name} | compact), body: null}
}

# Merge sites into a super layer.
#
# GET /mesh
# operationId: mesh
export def "mesh get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --network: string # Network name eg. 100_BLUE_repeaters_nationwide
  --name: string # Super layer name eg. National_map
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "network" $network "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mesh" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"network": $network, "name": $name} | compact), body: null}
}

# Find the best server for somewhere
#
# GET /network
# operationId: network
export def "network get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --net: string # Network name
  --nam: string # Super layer name
  --lat: float # Latitude in decimal degrees (format: float)
  --lon: float # Longitude in decimal degrees (format: float)
  --alt: int # Height above ground level in metres (format: int32)
  --rxg: float # Receiver gain in dBi (format: float)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "net" $net "scalar") (serialize-qp "nam" $nam "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "rxg" $rxg "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"net": $net, "nam": $nam, "lat": $lat, "lon": $lon, "alt": $alt, "rxg": $rxg} | compact), body: null}
}

# Point-to-point path profile analysis (Tx to Rx)
#
# POST /path
# operationId: path
# --antenna shape: {ant?: int, azi?: int, hbw?: int, pol?: "h"|"v", tlt?: float, txg?: float, txl?: float, vbw?: int}
# --environment shape: {cll?: int, clm?: int, mat?: float}
# --model shape: {cli?: int, ked?: int, pe?: int, pm?: int, rel?: int, ter?: int}
# --output shape: {ber?: int, col?: string, mod?: int, nf?: int, out?: int, rad?: float, res?: int, units?: "metric"|"imperial"}
# --receiver shape: {alt?: float, lat?: float, lon?: float, rxg?: float, rxs?: float}
# --transmitter shape: {alt?: float, bwi?: float, frq?: float, lat?: float, lon?: float, txw?: float}
export def "path create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antenna: record # shape: {ant?: int, azi?: int, hbw?: int, pol?: "h"|"v", tlt?: float, txg?: float, txl?: float, vbw?: int}
  --environment: record # shape: {cll?: int, clm?: int, mat?: float}
  --model: record # shape: {cli?: int, ked?: int, pe?: int, pm?: int, rel?: int, ter?: int}
  --network: string # Network name/group (default: Testing)
  --output: record # shape: {ber?: int, col?: string, mod?: int, nf?: int, out?: int, rad?: float, res?: int, units?: "metric"|"imperial"}
  --receiver: record # shape: {alt?: float, lat?: float, lon?: float, rxg?: float, rxs?: float}
  --site: string # Site name (default: Link)
  --transmitter: record # shape: {alt?: float, bwi?: float, frq?: float, lat?: float, lon?: float, txw?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/path")
  let req_body = {"antenna": $antenna, "environment": $environment, "model": $model, "network": $network, "output": $output, "receiver": $receiver, "site": $site, "transmitter": $transmitter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Point-to-multipoint path profile analysis (Many Tx, one Rx)
#
# POST /points
# operationId: points
# --antenna shape: {ant?: int, azi?: int, hbw?: int, pol?: "h"|"v", tlt?: float, txg?: float, txl?: float, vbw?: int}
# --environment shape: {cll?: int, clm?: int, mat?: float}
# --model shape: {cli?: int, ked?: int, pe?: int, pm?: int, rel?: int, ter?: int}
# --output shape: {ber?: int, col?: string, mod?: int, nf?: int, out?: int, rad?: float, res?: int, units?: "metric"|"imperial"}
# --points item shape: {alt?: float, lat?: float, lon?: float}
# --receiver shape: {alt?: float, lat?: float, lon?: float, rxg?: float, rxs?: float}
# --transmitter shape: {alt?: float, bwi?: float, frq?: float, lat?: float, lon?: float, txw?: float}
export def "points create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antenna: record # shape: {ant?: int, azi?: int, hbw?: int, pol?: "h"|"v", tlt?: float, txg?: float, txl?: float, vbw?: int}
  --environment: record # shape: {cll?: int, clm?: int, mat?: float}
  --model: record # shape: {cli?: int, ked?: int, pe?: int, pm?: int, rel?: int, ter?: int}
  --network: string # Network name/group (default: Testing)
  --output: record # shape: {ber?: int, col?: string, mod?: int, nf?: int, out?: int, rad?: float, res?: int, units?: "metric"|"imperial"}
  --points: list # item shape: {alt?: float, lat?: float, lon?: float}
  --receiver: record # shape: {alt?: float, lat?: float, lon?: float, rxg?: float, rxs?: float}
  --site: string # Site name (default: Points)
  --transmitter: record # shape: {alt?: float, bwi?: float, frq?: float, lat?: float, lon?: float, txw?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/points")
  let req_body = {"antenna": $antenna, "environment": $environment, "model": $model, "network": $network, "output": $output, "points": $points, "receiver": $receiver, "site": $site, "transmitter": $transmitter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
