# Auto-generated client for Cambase.io v1.0
# Source: https://api.apis.guru/v2/specs/cambase.io/1.0/swagger.json
# Auth: --token flag or $env.CAMBASE_IO_TOKEN

const BASE_URL = "http://api.cambase.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CAMBASE_IO_TOKEN | default "" }
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

def base-url-completer [] { ["http://api.cambase.io"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "models-json get-index" } } | get name | first)
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

# Fetches all Models
#
# GET /api/v1/models.json
# operationId: Api::V1::Models#index
export def "models-json get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --order: string # Sort order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/models.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "order": $order} | compact), body: null}
}

# Creates a new Model
#
# POST /api/v1/models.json
# operationId: Api::V1::Models#create
export def "models-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  model_model: string # Model
  --model-shape: string # Shape
  --model-resolution: string # Resolution
  --model-onvif: string # ONVIF
  --model-psia: string # PSIA
  --model-ptz: string # PTZ
  --model-infrared: string # Infrared
  --model-varifocal: string # Varifocal
  --model-sd-card: string # SD Card
  --model-upnp: string # UPnP
  --model-audio-in: string # UPnP
  --model-audio-out: string # UPnP
  --model-default-username: string # Default Username
  --model-default-password: string # Default Password
  --model-jpeg-url: string # JPEG URL
  --model-h264-url: string # H264 URL
  --model-mjpeg-url: string # MJPEG URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/models.json")
  let req_body = {"vendor_id": $vendor_id, "model[model]": $model_model, "model[shape]": $model_shape, "model[resolution]": $model_resolution, "model[onvif]": $model_onvif, "model[psia]": $model_psia, "model[ptz]": $model_ptz, "model[infrared]": $model_infrared, "model[varifocal]": $model_varifocal, "model[sd_card]": $model_sd_card, "model[upnp]": $model_upnp, "model[audio_in]": $model_audio_in, "model[audio_out]": $model_audio_out, "model[default_username]": $model_default_username, "model[default_password]": $model_default_password, "model[jpeg_url]": $model_jpeg_url, "model[h264_url]": $model_h264_url, "model[mjpeg_url]": $model_mjpeg_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Searches all Models
#
# GET /api/v1/models/search.json
# operationId: Api::V1::Models#search
export def "models-search-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --q-model-cont: string # Model
  --q-manufacturer-name-cont: string # Vendor
  --q-shape-eq: string # Shape
  --q-resolution-eq: string # Resolution
  --q-onvif-true: string # ONVIF
  --q-psia-true: string # PSIA
  --q-ptz-true: string # PTZ
  --q-infrared-true: string # Infrared
  --q-varifocal-true: string # Varifocal
  --q-sd-card-true: string # SD Card
  --q-upnp-true: string # UPnP
  --q-audio-in-true: string # Audio In
  --q-audio-out-true: string # Audio Out
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "q[model_cont]" $q_model_cont "scalar") (serialize-qp "q[manufacturer_name_cont]" $q_manufacturer_name_cont "scalar") (serialize-qp "q[shape_eq]" $q_shape_eq "scalar") (serialize-qp "q[resolution_eq]" $q_resolution_eq "scalar") (serialize-qp "q[onvif_true]" $q_onvif_true "scalar") (serialize-qp "q[psia_true]" $q_psia_true "scalar") (serialize-qp "q[ptz_true]" $q_ptz_true "scalar") (serialize-qp "q[infrared_true]" $q_infrared_true "scalar") (serialize-qp "q[varifocal_true]" $q_varifocal_true "scalar") (serialize-qp "q[sd_card_true]" $q_sd_card_true "scalar") (serialize-qp "q[upnp_true]" $q_upnp_true "scalar") (serialize-qp "q[audio_in_true]" $q_audio_in_true "scalar") (serialize-qp "q[audio_out_true]" $q_audio_out_true "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/models/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "q[model_cont]": $q_model_cont, "q[manufacturer_name_cont]": $q_manufacturer_name_cont, "q[shape_eq]": $q_shape_eq, "q[resolution_eq]": $q_resolution_eq, "q[onvif_true]": $q_onvif_true, "q[psia_true]": $q_psia_true, "q[ptz_true]": $q_ptz_true, "q[infrared_true]": $q_infrared_true, "q[varifocal_true]": $q_varifocal_true, "q[sd_card_true]": $q_sd_card_true, "q[upnp_true]": $q_upnp_true, "q[audio_in_true]": $q_audio_in_true, "q[audio_out_true]": $q_audio_out_true} | compact), body: null}
}

# Fetches a single Model
#
# GET /api/v1/models/{id}.json
# operationId: Api::V1::Models#show
export def "models get-show" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/models/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing Model
#
# PATCH /api/v1/models/{id}.json
export def "models update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  --model-model: string # Model
  --model-shape: string # Shape
  --model-resolution: string # Resolution
  --model-onvif: string # ONVIF
  --model-psia: string # PSIA
  --model-ptz: string # PTZ
  --model-infrared: string # Infrared
  --model-varifocal: string # Varifocal
  --model-sd-card: string # SD Card
  --model-upnp: string # UPnP
  --model-audio-in: string # Audio In
  --model-audio-out: string # Audio Out
  --model-default-username: string # Default Username
  --model-default-password: string # Default Password
  --model-jpeg-url: string # JPEG URL
  --model-h264-url: string # H264 URL
  --model-mjpeg-url: string # MJPEG URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/models/{id}.json"))
  let req_body = {"vendor_id": $vendor_id, "model[model]": $model_model, "model[shape]": $model_shape, "model[resolution]": $model_resolution, "model[onvif]": $model_onvif, "model[psia]": $model_psia, "model[ptz]": $model_ptz, "model[infrared]": $model_infrared, "model[varifocal]": $model_varifocal, "model[sd_card]": $model_sd_card, "model[upnp]": $model_upnp, "model[audio_in]": $model_audio_in, "model[audio_out]": $model_audio_out, "model[default_username]": $model_default_username, "model[default_password]": $model_default_password, "model[jpeg_url]": $model_jpeg_url, "model[h264_url]": $model_h264_url, "model[mjpeg_url]": $model_mjpeg_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Updates an existing Model
#
# PUT /api/v1/models/{id}.json
export def "models update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  --model-model: string # Model
  --model-shape: string # Shape
  --model-resolution: string # Resolution
  --model-onvif: string # ONVIF
  --model-psia: string # PSIA
  --model-ptz: string # PTZ
  --model-infrared: string # Infrared
  --model-varifocal: string # Varifocal
  --model-sd-card: string # SD Card
  --model-upnp: string # UPnP
  --model-audio-in: string # Audio In
  --model-audio-out: string # Audio Out
  --model-default-username: string # Default Username
  --model-default-password: string # Default Password
  --model-jpeg-url: string # JPEG URL
  --model-h264-url: string # H264 URL
  --model-mjpeg-url: string # MJPEG URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/models/{id}.json"))
  let req_body = {"vendor_id": $vendor_id, "model[model]": $model_model, "model[shape]": $model_shape, "model[resolution]": $model_resolution, "model[onvif]": $model_onvif, "model[psia]": $model_psia, "model[ptz]": $model_ptz, "model[infrared]": $model_infrared, "model[varifocal]": $model_varifocal, "model[sd_card]": $model_sd_card, "model[upnp]": $model_upnp, "model[audio_in]": $model_audio_in, "model[audio_out]": $model_audio_out, "model[default_username]": $model_default_username, "model[default_password]": $model_default_password, "model[jpeg_url]": $model_jpeg_url, "model[h264_url]": $model_h264_url, "model[mjpeg_url]": $model_mjpeg_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetches all Recorders
#
# GET /api/v1/recorders.json
# operationId: Api::V1::Recorders#index
export def "recorders-json get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --order: string # Sort order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/recorders.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "order": $order} | compact), body: null}
}

# Creates a new Recorder
#
# POST /api/v1/recorders.json
# operationId: Api::V1::Recorders#create
export def "recorders-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  recorder_model: string # Model
  recorder_name: string # Name
  recorder_recorder_type: string # Type
  --recorder-resolution: string # Resolution
  --recorder-onvif: string # ONVIF
  --recorder-psia: string # PSIA
  --recorder-ptz: string # PTZ
  --recorder-discontinued: string # Discontinued
  --recorder-support-3rdparty: string # 3rd pparty Camera Support
  --recorder-sd-card: string # SD Card
  --recorder-upnp: string # UPnP
  --recorder-hot-swap: string # Hot Swap
  --recorder-hdmi: string # HDMI Support
  --recorder-digital-io: string # Digital I/O
  --recorder-audio-in: string # Audio In
  --recorder-audio-out: string # Audio Out
  --recorder-input-channels: string # Input Channels
  --recorder-playback-channels: string # Playback Channels
  --recorder-usb: string # USB Ports
  --recorder-sdhc: string # SD Card (GB)
  --recorder-mobile-access: string # Mobile Access
  --recorder-alarms: string # Alarms
  --recorder-raid-support: string # Raid Support
  --recorder-storage: string # Internal Storage
  --recorder-additional-information: string # Additional Information
  --recorder-default-username: string # Default Username
  --recorder-default-password: string # Default Password
  --recorder-jpeg-url: string # JPEG URL
  --recorder-h264-url: string # H264 URL
  --recorder-mjpeg-url: string # MJPEG URL
  --recorder-official-url: string # Official URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/recorders.json")
  let req_body = {"vendor_id": $vendor_id, "recorder[model]": $recorder_model, "recorder[name]": $recorder_name, "recorder[recorder_type]": $recorder_recorder_type, "recorder[resolution]": $recorder_resolution, "recorder[onvif]": $recorder_onvif, "recorder[psia]": $recorder_psia, "recorder[ptz]": $recorder_ptz, "recorder[discontinued]": $recorder_discontinued, "recorder[support_3rdparty]": $recorder_support_3rdparty, "recorder[sd_card]": $recorder_sd_card, "recorder[upnp]": $recorder_upnp, "recorder[hot_swap]": $recorder_hot_swap, "recorder[hdmi]": $recorder_hdmi, "recorder[digital_io]": $recorder_digital_io, "recorder[audio_in]": $recorder_audio_in, "recorder[audio_out]": $recorder_audio_out, "recorder[input_channels]": $recorder_input_channels, "recorder[playback_channels]": $recorder_playback_channels, "recorder[usb]": $recorder_usb, "recorder[sdhc]": $recorder_sdhc, "recorder[mobile_access]": $recorder_mobile_access, "recorder[alarms]": $recorder_alarms, "recorder[raid_support]": $recorder_raid_support, "recorder[storage]": $recorder_storage, "recorder[additional_information]": $recorder_additional_information, "recorder[default_username]": $recorder_default_username, "recorder[default_password]": $recorder_default_password, "recorder[jpeg_url]": $recorder_jpeg_url, "recorder[h264_url]": $recorder_h264_url, "recorder[mjpeg_url]": $recorder_mjpeg_url, "recorder[official_url]": $recorder_official_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Searches all Recorders
#
# GET /api/v1/recorders/search.json
# operationId: Api::V1::Recorders#search
export def "recorders-search-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --q-model-cont: string # Model
  --q-vendor-name-cont: string # Vendor
  --q-sdhc-eq: string # SD Card (GB)
  --q-type-eq: string # Type
  --q-resolution-eq: string # Resolution
  --q-input-channels-eq: string # Input Channels
  --q-playback-channels-eq: string # Playback Channels
  --q-onvif-true: string # ONVIF
  --q-psia-true: string # PSIA
  --q-ptz-true: string # PTZ
  --q-sd-card-true: string # SD Card
  --q-upnp-true: string # UPnP
  --q-audio-in-true: string # Audio In
  --q-audio-out-true: string # Audio Out
  --q-hdmi-true: string # HDMI Support
  --q-hot-swap-true: string # Hot Swap
  --q-support-3rdparty-true: string # 3rd pparty Camera Support
  --q-digital-io-true: string # Digital I/O
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "q[model_cont]" $q_model_cont "scalar") (serialize-qp "q[vendor_name_cont]" $q_vendor_name_cont "scalar") (serialize-qp "q[sdhc_eq]" $q_sdhc_eq "scalar") (serialize-qp "q[type_eq]" $q_type_eq "scalar") (serialize-qp "q[resolution_eq]" $q_resolution_eq "scalar") (serialize-qp "q[input_channels_eq]" $q_input_channels_eq "scalar") (serialize-qp "q[playback_channels_eq]" $q_playback_channels_eq "scalar") (serialize-qp "q[onvif_true]" $q_onvif_true "scalar") (serialize-qp "q[psia_true]" $q_psia_true "scalar") (serialize-qp "q[ptz_true]" $q_ptz_true "scalar") (serialize-qp "q[sd_card_true]" $q_sd_card_true "scalar") (serialize-qp "q[upnp_true]" $q_upnp_true "scalar") (serialize-qp "q[audio_in_true]" $q_audio_in_true "scalar") (serialize-qp "q[audio_out_true]" $q_audio_out_true "scalar") (serialize-qp "q[hdmi_true]" $q_hdmi_true "scalar") (serialize-qp "q[hot_swap_true]" $q_hot_swap_true "scalar") (serialize-qp "q[support_3rdparty_true]" $q_support_3rdparty_true "scalar") (serialize-qp "q[digital_io_true]" $q_digital_io_true "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/recorders/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "q[model_cont]": $q_model_cont, "q[vendor_name_cont]": $q_vendor_name_cont, "q[sdhc_eq]": $q_sdhc_eq, "q[type_eq]": $q_type_eq, "q[resolution_eq]": $q_resolution_eq, "q[input_channels_eq]": $q_input_channels_eq, "q[playback_channels_eq]": $q_playback_channels_eq, "q[onvif_true]": $q_onvif_true, "q[psia_true]": $q_psia_true, "q[ptz_true]": $q_ptz_true, "q[sd_card_true]": $q_sd_card_true, "q[upnp_true]": $q_upnp_true, "q[audio_in_true]": $q_audio_in_true, "q[audio_out_true]": $q_audio_out_true, "q[hdmi_true]": $q_hdmi_true, "q[hot_swap_true]": $q_hot_swap_true, "q[support_3rdparty_true]": $q_support_3rdparty_true, "q[digital_io_true]": $q_digital_io_true} | compact), body: null}
}

# Fetches a single Recorder
#
# GET /api/v1/recorders/{id}.json
# operationId: Api::V1::Recorders#show
export def "recorders get-show" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/recorders/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing Recorder
#
# PATCH /api/v1/recorders/{id}.json
export def "recorders update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  recorder_model: string # Model
  recorder_name: string # Name
  recorder_recorder_type: string # Type
  --recorder-resolution: string # Resolution
  --recorder-onvif: string # ONVIF
  --recorder-psia: string # PSIA
  --recorder-ptz: string # PTZ
  --recorder-discontinued: string # Discontinued
  --recorder-support-3rdparty: string # 3rd pparty Camera Support
  --recorder-sd-card: string # SD Card
  --recorder-upnp: string # UPnP
  --recorder-hot-swap: string # Hot Swap
  --recorder-hdmi: string # HDMI Support
  --recorder-digital-io: string # Digital I/O
  --recorder-audio-in: string # Audio In
  --recorder-audio-out: string # Audio Out
  --recorder-input-channels: string # Input Channels
  --recorder-playback-channels: string # Playback Channels
  --recorder-usb: string # USB Ports
  --recorder-sdhc: string # SD Card (GB)
  --recorder-mobile-access: string # Mobile Access
  --recorder-alarms: string # Alarms
  --recorder-raid-support: string # Raid Support
  --recorder-storage: string # Internal Storage
  --recorder-additional-information: string # Additional Information
  --recorder-default-username: string # Default Username
  --recorder-default-password: string # Default Password
  --recorder-jpeg-url: string # JPEG URL
  --recorder-h264-url: string # H264 URL
  --recorder-mjpeg-url: string # MJPEG URL
  --recorder-official-url: string # Official URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/recorders/{id}.json"))
  let req_body = {"vendor_id": $vendor_id, "recorder[model]": $recorder_model, "recorder[name]": $recorder_name, "recorder[recorder_type]": $recorder_recorder_type, "recorder[resolution]": $recorder_resolution, "recorder[onvif]": $recorder_onvif, "recorder[psia]": $recorder_psia, "recorder[ptz]": $recorder_ptz, "recorder[discontinued]": $recorder_discontinued, "recorder[support_3rdparty]": $recorder_support_3rdparty, "recorder[sd_card]": $recorder_sd_card, "recorder[upnp]": $recorder_upnp, "recorder[hot_swap]": $recorder_hot_swap, "recorder[hdmi]": $recorder_hdmi, "recorder[digital_io]": $recorder_digital_io, "recorder[audio_in]": $recorder_audio_in, "recorder[audio_out]": $recorder_audio_out, "recorder[input_channels]": $recorder_input_channels, "recorder[playback_channels]": $recorder_playback_channels, "recorder[usb]": $recorder_usb, "recorder[sdhc]": $recorder_sdhc, "recorder[mobile_access]": $recorder_mobile_access, "recorder[alarms]": $recorder_alarms, "recorder[raid_support]": $recorder_raid_support, "recorder[storage]": $recorder_storage, "recorder[additional_information]": $recorder_additional_information, "recorder[default_username]": $recorder_default_username, "recorder[default_password]": $recorder_default_password, "recorder[jpeg_url]": $recorder_jpeg_url, "recorder[h264_url]": $recorder_h264_url, "recorder[mjpeg_url]": $recorder_mjpeg_url, "recorder[official_url]": $recorder_official_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Updates an existing Recorder
#
# PUT /api/v1/recorders/{id}.json
export def "recorders update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  recorder_model: string # Model
  recorder_name: string # Name
  recorder_recorder_type: string # Type
  --recorder-resolution: string # Resolution
  --recorder-onvif: string # ONVIF
  --recorder-psia: string # PSIA
  --recorder-ptz: string # PTZ
  --recorder-discontinued: string # Discontinued
  --recorder-support-3rdparty: string # 3rd pparty Camera Support
  --recorder-sd-card: string # SD Card
  --recorder-upnp: string # UPnP
  --recorder-hot-swap: string # Hot Swap
  --recorder-hdmi: string # HDMI Support
  --recorder-digital-io: string # Digital I/O
  --recorder-audio-in: string # Audio In
  --recorder-audio-out: string # Audio Out
  --recorder-input-channels: string # Input Channels
  --recorder-playback-channels: string # Playback Channels
  --recorder-usb: string # USB Ports
  --recorder-sdhc: string # SD Card (GB)
  --recorder-mobile-access: string # Mobile Access
  --recorder-alarms: string # Alarms
  --recorder-raid-support: string # Raid Support
  --recorder-storage: string # Internal Storage
  --recorder-additional-information: string # Additional Information
  --recorder-default-username: string # Default Username
  --recorder-default-password: string # Default Password
  --recorder-jpeg-url: string # JPEG URL
  --recorder-h264-url: string # H264 URL
  --recorder-mjpeg-url: string # MJPEG URL
  --recorder-official-url: string # Official URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/recorders/{id}.json"))
  let req_body = {"vendor_id": $vendor_id, "recorder[model]": $recorder_model, "recorder[name]": $recorder_name, "recorder[recorder_type]": $recorder_recorder_type, "recorder[resolution]": $recorder_resolution, "recorder[onvif]": $recorder_onvif, "recorder[psia]": $recorder_psia, "recorder[ptz]": $recorder_ptz, "recorder[discontinued]": $recorder_discontinued, "recorder[support_3rdparty]": $recorder_support_3rdparty, "recorder[sd_card]": $recorder_sd_card, "recorder[upnp]": $recorder_upnp, "recorder[hot_swap]": $recorder_hot_swap, "recorder[hdmi]": $recorder_hdmi, "recorder[digital_io]": $recorder_digital_io, "recorder[audio_in]": $recorder_audio_in, "recorder[audio_out]": $recorder_audio_out, "recorder[input_channels]": $recorder_input_channels, "recorder[playback_channels]": $recorder_playback_channels, "recorder[usb]": $recorder_usb, "recorder[sdhc]": $recorder_sdhc, "recorder[mobile_access]": $recorder_mobile_access, "recorder[alarms]": $recorder_alarms, "recorder[raid_support]": $recorder_raid_support, "recorder[storage]": $recorder_storage, "recorder[additional_information]": $recorder_additional_information, "recorder[default_username]": $recorder_default_username, "recorder[default_password]": $recorder_default_password, "recorder[jpeg_url]": $recorder_jpeg_url, "recorder[h264_url]": $recorder_h264_url, "recorder[mjpeg_url]": $recorder_mjpeg_url, "recorder[official_url]": $recorder_official_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetches all Vendors
#
# GET /api/v1/vendors.json
# operationId: Api::V1::Vendors#index
export def "vendors-json get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --order: string # Sort order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/vendors.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "order": $order} | compact), body: null}
}

# Creates a new Vendor
#
# POST /api/v1/vendors.json
# operationId: Api::V1::Vendors#create
export def "vendors-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_name: string # Name
  --vendor-info: string # Info.
  --vendor-url: string # Website
  --vendor-mac: string # MAC
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/vendors.json")
  let req_body = {"vendor[name]": $vendor_name, "vendor[info]": $vendor_info, "vendor[url]": $vendor_url, "vendor[mac]": $vendor_mac} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetches a single Vendor
#
# GET /api/v1/vendors/{id}.json
# operationId: Api::V1::Vendors#show
export def "vendors get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # Sort order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/vendors/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"order": $order} | compact), body: null}
}

# Updates an existing Vendor
#
# PATCH /api/v1/vendors/{id}.json
export def "vendors update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vendor-name: string # Name
  --vendor-info: string # Info.
  --vendor-url: string # Website
  --vendor-mac: string # MAC
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/vendors/{id}.json"))
  let req_body = {"vendor[name]": $vendor_name, "vendor[info]": $vendor_info, "vendor[url]": $vendor_url, "vendor[mac]": $vendor_mac} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Updates an existing Vendor
#
# PUT /api/v1/vendors/{id}.json
export def "vendors update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vendor-name: string # Name
  --vendor-info: string # Info.
  --vendor-url: string # Website
  --vendor-mac: string # MAC
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/vendors/{id}.json"))
  let req_body = {"vendor[name]": $vendor_name, "vendor[info]": $vendor_info, "vendor[url]": $vendor_url, "vendor[mac]": $vendor_mac} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
