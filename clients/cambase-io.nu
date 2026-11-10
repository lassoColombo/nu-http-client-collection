# Auto-generated client for Cambase.io v1.0
# Source: https://api.apis.guru/v2/specs/cambase.io/1.0/swagger.json
# Auth: --token flag or $env.CAMBASE_IO_TOKEN

const BASE_URL = "http://api.cambase.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CAMBASE_IO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://api.cambase.io"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["api-v1-modelsindex" "api-v1-modelscreate" "api-v1-modelssearch" "api-v1-modelsshow" "patch-api-v1-models-id-json" "put-api-v1-models-id-json" "api-v1-recordersindex" "api-v1-recorderscreate" "api-v1-recorderssearch" "api-v1-recordersshow" "patch-api-v1-recorders-id-json" "put-api-v1-recorders-id-json" "api-v1-vendorsindex" "api-v1-vendorscreate" "api-v1-vendorsshow" "patch-api-v1-vendors-id-json" "put-api-v1-vendors-id-json" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "api-v1-modelsindex" [
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
  let full_url = (build-url $base "/api/v1/models.json" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "order": $order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Model
#
# POST /api/v1/models.json
# operationId: Api::V1::Models#create
export def "api-v1-modelscreate" [
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
  let full_url = (build-url $base "/api/v1/models.json" $auth.query)
  let req_body = {"vendor_id": $vendor_id, "model[model]": $model_model, "model[shape]": $model_shape, "model[resolution]": $model_resolution, "model[onvif]": $model_onvif, "model[psia]": $model_psia, "model[ptz]": $model_ptz, "model[infrared]": $model_infrared, "model[varifocal]": $model_varifocal, "model[sd_card]": $model_sd_card, "model[upnp]": $model_upnp, "model[audio_in]": $model_audio_in, "model[audio_out]": $model_audio_out, "model[default_username]": $model_default_username, "model[default_password]": $model_default_password, "model[jpeg_url]": $model_jpeg_url, "model[h264_url]": $model_h264_url, "model[mjpeg_url]": $model_mjpeg_url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
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
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Searches all Models
#
# GET /api/v1/models/search.json
# operationId: Api::V1::Models#search
export def "api-v1-modelssearch" [
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
  let full_url = (build-url $base "/api/v1/models/search.json" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "q[model_cont]": $q_model_cont, "q[manufacturer_name_cont]": $q_manufacturer_name_cont, "q[shape_eq]": $q_shape_eq, "q[resolution_eq]": $q_resolution_eq, "q[onvif_true]": $q_onvif_true, "q[psia_true]": $q_psia_true, "q[ptz_true]": $q_ptz_true, "q[infrared_true]": $q_infrared_true, "q[varifocal_true]": $q_varifocal_true, "q[sd_card_true]": $q_sd_card_true, "q[upnp_true]": $q_upnp_true, "q[audio_in_true]": $q_audio_in_true, "q[audio_out_true]": $q_audio_out_true} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetches a single Model
#
# GET /api/v1/models/{id}.json
# operationId: Api::V1::Models#show
export def "api-v1-modelsshow" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/models/{id}.json") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Updates an existing Model
#
# PATCH /api/v1/models/{id}.json
export def "patch-api-v1-models-id-json" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/models/{id}.json") $auth.query)
  let req_body = {"vendor_id": $vendor_id, "model[model]": $model_model, "model[shape]": $model_shape, "model[resolution]": $model_resolution, "model[onvif]": $model_onvif, "model[psia]": $model_psia, "model[ptz]": $model_ptz, "model[infrared]": $model_infrared, "model[varifocal]": $model_varifocal, "model[sd_card]": $model_sd_card, "model[upnp]": $model_upnp, "model[audio_in]": $model_audio_in, "model[audio_out]": $model_audio_out, "model[default_username]": $model_default_username, "model[default_password]": $model_default_password, "model[jpeg_url]": $model_jpeg_url, "model[h264_url]": $model_h264_url, "model[mjpeg_url]": $model_mjpeg_url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Updates an existing Model
#
# PUT /api/v1/models/{id}.json
export def "put-api-v1-models-id-json" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/models/{id}.json") $auth.query)
  let req_body = {"vendor_id": $vendor_id, "model[model]": $model_model, "model[shape]": $model_shape, "model[resolution]": $model_resolution, "model[onvif]": $model_onvif, "model[psia]": $model_psia, "model[ptz]": $model_ptz, "model[infrared]": $model_infrared, "model[varifocal]": $model_varifocal, "model[sd_card]": $model_sd_card, "model[upnp]": $model_upnp, "model[audio_in]": $model_audio_in, "model[audio_out]": $model_audio_out, "model[default_username]": $model_default_username, "model[default_password]": $model_default_password, "model[jpeg_url]": $model_jpeg_url, "model[h264_url]": $model_h264_url, "model[mjpeg_url]": $model_mjpeg_url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Fetches all Recorders
#
# GET /api/v1/recorders.json
# operationId: Api::V1::Recorders#index
export def "api-v1-recordersindex" [
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
  let full_url = (build-url $base "/api/v1/recorders.json" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "order": $order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Recorder
#
# POST /api/v1/recorders.json
# operationId: Api::V1::Recorders#create
export def "api-v1-recorderscreate" [
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
  let full_url = (build-url $base "/api/v1/recorders.json" $auth.query)
  let req_body = {"vendor_id": $vendor_id, "recorder[model]": $recorder_model, "recorder[name]": $recorder_name, "recorder[recorder_type]": $recorder_recorder_type, "recorder[resolution]": $recorder_resolution, "recorder[onvif]": $recorder_onvif, "recorder[psia]": $recorder_psia, "recorder[ptz]": $recorder_ptz, "recorder[discontinued]": $recorder_discontinued, "recorder[support_3rdparty]": $recorder_support_3rdparty, "recorder[sd_card]": $recorder_sd_card, "recorder[upnp]": $recorder_upnp, "recorder[hot_swap]": $recorder_hot_swap, "recorder[hdmi]": $recorder_hdmi, "recorder[digital_io]": $recorder_digital_io, "recorder[audio_in]": $recorder_audio_in, "recorder[audio_out]": $recorder_audio_out, "recorder[input_channels]": $recorder_input_channels, "recorder[playback_channels]": $recorder_playback_channels, "recorder[usb]": $recorder_usb, "recorder[sdhc]": $recorder_sdhc, "recorder[mobile_access]": $recorder_mobile_access, "recorder[alarms]": $recorder_alarms, "recorder[raid_support]": $recorder_raid_support, "recorder[storage]": $recorder_storage, "recorder[additional_information]": $recorder_additional_information, "recorder[default_username]": $recorder_default_username, "recorder[default_password]": $recorder_default_password, "recorder[jpeg_url]": $recorder_jpeg_url, "recorder[h264_url]": $recorder_h264_url, "recorder[mjpeg_url]": $recorder_mjpeg_url, "recorder[official_url]": $recorder_official_url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
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
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Searches all Recorders
#
# GET /api/v1/recorders/search.json
# operationId: Api::V1::Recorders#search
export def "api-v1-recorderssearch" [
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
  let full_url = (build-url $base "/api/v1/recorders/search.json" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "q[model_cont]": $q_model_cont, "q[vendor_name_cont]": $q_vendor_name_cont, "q[sdhc_eq]": $q_sdhc_eq, "q[type_eq]": $q_type_eq, "q[resolution_eq]": $q_resolution_eq, "q[input_channels_eq]": $q_input_channels_eq, "q[playback_channels_eq]": $q_playback_channels_eq, "q[onvif_true]": $q_onvif_true, "q[psia_true]": $q_psia_true, "q[ptz_true]": $q_ptz_true, "q[sd_card_true]": $q_sd_card_true, "q[upnp_true]": $q_upnp_true, "q[audio_in_true]": $q_audio_in_true, "q[audio_out_true]": $q_audio_out_true, "q[hdmi_true]": $q_hdmi_true, "q[hot_swap_true]": $q_hot_swap_true, "q[support_3rdparty_true]": $q_support_3rdparty_true, "q[digital_io_true]": $q_digital_io_true} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetches a single Recorder
#
# GET /api/v1/recorders/{id}.json
# operationId: Api::V1::Recorders#show
export def "api-v1-recordersshow" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/recorders/{id}.json") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Updates an existing Recorder
#
# PATCH /api/v1/recorders/{id}.json
export def "patch-api-v1-recorders-id-json" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/recorders/{id}.json") $auth.query)
  let req_body = {"vendor_id": $vendor_id, "recorder[model]": $recorder_model, "recorder[name]": $recorder_name, "recorder[recorder_type]": $recorder_recorder_type, "recorder[resolution]": $recorder_resolution, "recorder[onvif]": $recorder_onvif, "recorder[psia]": $recorder_psia, "recorder[ptz]": $recorder_ptz, "recorder[discontinued]": $recorder_discontinued, "recorder[support_3rdparty]": $recorder_support_3rdparty, "recorder[sd_card]": $recorder_sd_card, "recorder[upnp]": $recorder_upnp, "recorder[hot_swap]": $recorder_hot_swap, "recorder[hdmi]": $recorder_hdmi, "recorder[digital_io]": $recorder_digital_io, "recorder[audio_in]": $recorder_audio_in, "recorder[audio_out]": $recorder_audio_out, "recorder[input_channels]": $recorder_input_channels, "recorder[playback_channels]": $recorder_playback_channels, "recorder[usb]": $recorder_usb, "recorder[sdhc]": $recorder_sdhc, "recorder[mobile_access]": $recorder_mobile_access, "recorder[alarms]": $recorder_alarms, "recorder[raid_support]": $recorder_raid_support, "recorder[storage]": $recorder_storage, "recorder[additional_information]": $recorder_additional_information, "recorder[default_username]": $recorder_default_username, "recorder[default_password]": $recorder_default_password, "recorder[jpeg_url]": $recorder_jpeg_url, "recorder[h264_url]": $recorder_h264_url, "recorder[mjpeg_url]": $recorder_mjpeg_url, "recorder[official_url]": $recorder_official_url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Updates an existing Recorder
#
# PUT /api/v1/recorders/{id}.json
export def "put-api-v1-recorders-id-json" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/recorders/{id}.json") $auth.query)
  let req_body = {"vendor_id": $vendor_id, "recorder[model]": $recorder_model, "recorder[name]": $recorder_name, "recorder[recorder_type]": $recorder_recorder_type, "recorder[resolution]": $recorder_resolution, "recorder[onvif]": $recorder_onvif, "recorder[psia]": $recorder_psia, "recorder[ptz]": $recorder_ptz, "recorder[discontinued]": $recorder_discontinued, "recorder[support_3rdparty]": $recorder_support_3rdparty, "recorder[sd_card]": $recorder_sd_card, "recorder[upnp]": $recorder_upnp, "recorder[hot_swap]": $recorder_hot_swap, "recorder[hdmi]": $recorder_hdmi, "recorder[digital_io]": $recorder_digital_io, "recorder[audio_in]": $recorder_audio_in, "recorder[audio_out]": $recorder_audio_out, "recorder[input_channels]": $recorder_input_channels, "recorder[playback_channels]": $recorder_playback_channels, "recorder[usb]": $recorder_usb, "recorder[sdhc]": $recorder_sdhc, "recorder[mobile_access]": $recorder_mobile_access, "recorder[alarms]": $recorder_alarms, "recorder[raid_support]": $recorder_raid_support, "recorder[storage]": $recorder_storage, "recorder[additional_information]": $recorder_additional_information, "recorder[default_username]": $recorder_default_username, "recorder[default_password]": $recorder_default_password, "recorder[jpeg_url]": $recorder_jpeg_url, "recorder[h264_url]": $recorder_h264_url, "recorder[mjpeg_url]": $recorder_mjpeg_url, "recorder[official_url]": $recorder_official_url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Fetches all Vendors
#
# GET /api/v1/vendors.json
# operationId: Api::V1::Vendors#index
export def "api-v1-vendorsindex" [
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
  let full_url = (build-url $base "/api/v1/vendors.json" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "order": $order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Vendor
#
# POST /api/v1/vendors.json
# operationId: Api::V1::Vendors#create
export def "api-v1-vendorscreate" [
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
  let full_url = (build-url $base "/api/v1/vendors.json" $auth.query)
  let req_body = {"vendor[name]": $vendor_name, "vendor[info]": $vendor_info, "vendor[url]": $vendor_url, "vendor[mac]": $vendor_mac} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
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
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Fetches a single Vendor
#
# GET /api/v1/vendors/{id}.json
# operationId: Api::V1::Vendors#show
export def "api-v1-vendorsshow" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/vendors/{id}.json") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"order": $order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Vendor
#
# PATCH /api/v1/vendors/{id}.json
export def "patch-api-v1-vendors-id-json" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/vendors/{id}.json") $auth.query)
  let req_body = {"vendor[name]": $vendor_name, "vendor[info]": $vendor_info, "vendor[url]": $vendor_url, "vendor[mac]": $vendor_mac} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Updates an existing Vendor
#
# PUT /api/v1/vendors/{id}.json
export def "put-api-v1-vendors-id-json" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/vendors/{id}.json") $auth.query)
  let req_body = {"vendor[name]": $vendor_name, "vendor[info]": $vendor_info, "vendor[url]": $vendor_url, "vendor[mac]": $vendor_mac} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}
