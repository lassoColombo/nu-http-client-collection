# Auto-generated client for Cloud-RF API v2.0.0
# Source: https://api.apis.guru/v2/specs/cloudrf.com/2.0.0/openapi.json
# Auth: --token flag or $env.CLOUD_RF_API_TOKEN

const BASE_URL = "https://api.cloudrf.com"
const DEFAULT_AUTH = "key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_RF_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "key" => { {headers: {key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.cloudrf.com"] }
def auth-scheme-completer [] { ["key"] }

# Completers for enum parameters
def fmt-completer [] { ["kml" "kml" "kmzppa" "shp" "tiff"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --cid: int # Unique calculation ID number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cid" $cid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archive/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --nid: string # Network name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nid" $nid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archive/delete/network" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
export def "area post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"antenna": $antenna, "environment": $environment, "model": $model, "network": $network, "output": $output, "receiver": $receiver, "site": $site, "transmitter": $transmitter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --features: list # item shape: {geometry?: string, properties?: string, type?: string}
  --name: string # default: Clutter
  --type: string # default: FeatureCollection
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clutter/add")
  let body = {"features": $features, "name": $name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
export def "path post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"antenna": $antenna, "environment": $environment, "model": $model, "network": $network, "output": $output, "receiver": $receiver, "site": $site, "transmitter": $transmitter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "points post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"antenna": $antenna, "environment": $environment, "model": $model, "network": $network, "output": $output, "points": $points, "receiver": $receiver, "site": $site, "transmitter": $transmitter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
