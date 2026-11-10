# Auto-generated client for Netatmo v1.1.5
# Source: https://api.apis.guru/v2/specs/netatmo.net/1.1.5/openapi.json
# Auth: --token flag or $env.NETATMO_TOKEN

const BASE_URL = "https://api.netatmo.net/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o NETATMO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.netatmo.net/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def app-type-completer [] { ["app_station" "app_thermostat"] }
def scale-completer [] { ["1day" "1hour" "1month" "1week" "30min" "3hours" "max"] }
def setpoint-mode-completer [] { ["away" "hg" "manual" "max" "off" "program"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["addwebhook" "createnewschedule" "devicelist" "dropwebhook" "getcamerapicture" "geteventsuntil" "gethomecoachsdata" "gethomedata" "getlasteventof" "getmeasure" "getnextevents" "getpublicdata" "getstationsdata" "getthermostatsdata" "getthermstate" "getuser" "partnerdevices" "setpersonsaway" "setpersonshome" "setthermpoint" "switchschedule" "syncschedule" "commands"] | sort) } | get name | first)
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

# Links a callback url to a user.
#
# GET /addwebhook
# operationId: addwebhook
export def "addwebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # Your webhook callback url (required)
  --app-type: string # Webhooks are only available for Welcome, enter app_camera. (required)
]: nothing -> oneof<record<status: string, time_exec: float>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($url == null) { error make --unspanned { msg: "required query parameter 'url' missing: pass --url" } }
  if ($app_type == null) { error make --unspanned { msg: "required query parameter 'app_type' missing: pass --app-type" } }
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "app_type" $app_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addwebhook" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"url": $url, "app_type": $app_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The method createnewschedule creates a new schedule stored in the backup list.
#
# POST /createnewschedule
# operationId: createnewschedule
export def "createnewschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id (required)
  --module-id: string # The thermostat id (required)
  --body: any
]: any -> oneof<record<body: record<schedule_id: string>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id == null) { error make --unspanned { msg: "required query parameter 'device_id' missing: pass --device-id" } }
  if ($module_id == null) { error make --unspanned { msg: "required query parameter 'module_id' missing: pass --module-id" } }
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/createnewschedule" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"device_id": $device_id, "module_id": $module_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# The method devicelist returns the list of devices owned by the user, and their modules. A device is identified by its _id (which is its mac address) and each device may have one, several or no modules, also identified by an _id.
#
# GET /devicelist
# DEPRECATED
# operationId: devicelist
@deprecated
export def "devicelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-type: string@app-type-completer # Defines which device type will be returned by devicelist. It could be app_thermostat or app_station (by default if not provided)
  --device-id: string # Specify a device_id if you want to retrieve only this device informations.
  --get-favorites: oneof<nothing, bool> # When set to "true", the favorite devices of the user are returned. This flag is available only if the devices requested are Weather Stations. (default: false)
]: nothing -> oneof<record<body: record<devices: list<record>, modules: list<record>>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_type" $app_type "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "get_favorites" $get_favorites "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devicelist" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"app_type": $app_type, "device_id": $device_id, "get_favorites": $get_favorites} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Dissociates a webhook from a user.
#
# GET /dropwebhook
# operationId: dropwebhook
export def "dropwebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-type: string # For Welcome, use app_camera (required)
]: nothing -> oneof<record<status: string, time_exec: float>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_type == null) { error make --unspanned { msg: "required query parameter 'app_type' missing: pass --app-type" } }
  let qp = [(serialize-qp "app_type" $app_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dropwebhook" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"app_type": $app_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the snapshot associated to an event.
#
# GET /getcamerapicture
# operationId: getcamerapicture
export def "getcamerapicture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-id: string # id of the image (can be retrieved as 'id' in 'face' in Gethomedata, or as 'id' in 'snapshot' in Getnextevents, Getlasteventof and Geteventsuntil) (required)
  --key: string # Security key to access snapshots. (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id == null) { error make --unspanned { msg: "required query parameter 'image_id' missing: pass --image-id" } }
  if ($key == null) { error make --unspanned { msg: "required query parameter 'key' missing: pass --key" } }
  let qp = [(serialize-qp "image_id" $image_id "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getcamerapicture" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"image_id": $image_id, "key": $key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the snapshot associated to an event.
#
# GET /geteventsuntil
# operationId: geteventsuntil
export def "geteventsuntil" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in (required)
  --event-id: string # Your request will retrieve all the events until this one (required)
]: nothing -> oneof<record<body: record<events_list: list<record>>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($home_id == null) { error make --unspanned { msg: "required query parameter 'home_id' missing: pass --home-id" } }
  if ($event_id == null) { error make --unspanned { msg: "required query parameter 'event_id' missing: pass --event-id" } }
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "event_id" $event_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geteventsuntil" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"home_id": $home_id, "event_id": $event_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The method gethomecoachsdata Returns data from a user Healthy Home Coach Station (measures and device specific data).
#
# GET /gethomecoachsdata
# operationId: gethomecoachsdata
export def "gethomecoachsdata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # Id of the device you want to retrieve information of
]: nothing -> oneof<record<body: record<devices: list<record>, user: record<_id: string, administrative: record, date_creation: record, devices: list, friend_devices: list, mail: string, timeline_not_read: int, timeline_size: int>>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gethomecoachsdata" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"device_id": $device_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about users homes and cameras.
#
# GET /gethomedata
# operationId: gethomedata
export def "gethomedata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # Specify if you're looking for the events of a specific Home.
  --size: int # Number of events to retrieve. Default is `30`.
]: nothing -> oneof<record<body: record<global_info: record<show_tags: bool>, homes: list<record>, user: record<lang: string, reg_locale: string>>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gethomedata" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"home_id": $home_id, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns most recent events.
#
# GET /getlasteventof
# operationId: getlasteventof
export def "getlasteventof" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in (required)
  --person-id: string # Your request will retrieve all events of the given home until the most recent event of the given person (required)
  --offset: int # Number of events to retrieve. Default is 30.
]: nothing -> oneof<record<body: record<events_list: list<record>>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($home_id == null) { error make --unspanned { msg: "required query parameter 'home_id' missing: pass --home-id" } }
  if ($person_id == null) { error make --unspanned { msg: "required query parameter 'person_id' missing: pass --person-id" } }
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getlasteventof" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"home_id": $home_id, "person_id": $person_id, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The method getmeasure returns the measurements of a device or a module.
#
# GET /getmeasure
# operationId: getmeasure
export def "getmeasure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # Id of the device whose module's measurements you want to retrieve. This _id can be found in the user's devices field. (required)
  --module-id: string # If you don't specify any module_id you will retrieve the device's measurements. If you specify a module_id you will retrieve the module's measurements.
  --scale: string@scale-completer # Defines the time interval between two measurements. Possible values : max -> every value stored will be returned 30min -> 1 value every 30 minutes 1hour -> 1 value every hour 3hours -> 1 value every 3 hours 1day -> 1 value per day 1week -> 1 value per week 1month -> 1 value per month (required)
  --type: list<string> # Measures you are interested in. Data you can request depends on the scale. **For Weather Station:** * max -> Temperature (°C), CO2 (ppm), Humidity (%), Pressure (mbar), Noise (db), Rain (mm), WindStrength (km/h), WindAngle (angles), Guststrength (km/h), GustAngle (angles) * 30min, 1hour, 3hours -> Same as above + min_temp, max_temp, min_hum, max_hum, min_pressure, max_pressure, min_noise, max_noise, sum_rain, date_max_gust * 1day, 1week, 1month -> Same as above + date_min_temp, date_max_temp, date_min_hum, date_max_hum, date_min_pressure, date_max_pressure, date_min_noise, date_max_noise, date_min_co2, date_max_co2 **For Thermostat:** * max -> temperature (°C), sp_temperature (°C), boileron (sec), boileroff (sec) * 30min, 1hour, 3hours -> temperature, sp_temperature, min_temp, max_temp, sum_boiler_on, sum_boiler_off * 1day, 1week, 1month -> temperature, min_temp, date_min_temp, max_temp, sum_boiler_on, sum_boiler_off (required)
  --date-begin: int # Starting timestamp (utc) of the requested measurements. Please note measurement retrieving is limited to 1024 measurements. (format: int32)
  --date-end: string # Ending timestamp (utc) of the request measurements. If you want only the last measurement, do not provide date_begin, and set date_end to `last`.
  --limit: int # Limits the number of measurements returned (default & max is 1024) (format: int32)
  --optimize: oneof<nothing, bool> # Allows you to choose the format of the answer. If you build a mobile app and bandwith usage is an issue, use `optimize = true`. Use `optimize = false`, for an easier parse. In this case, values are indexed by sorted timestamp. Example of un-optimized response : ```json {"status": "ok", "body": { "1347575400": [18.3,39], "1347586200": [20.6,48] }, "time_exec": 0.012136936187744} ``` If optimize is set true, measurements are returned as an array of series of regularly spaced measurements. Each series is defined by a beginning time beg_time and a step between measurements, step_time: ```json {"status": "ok", "body": [ {"beg_time": 1347575400, "step_time": 10800, "value": [[18.3,39], [ 20.6,48]] }], "time_exec": 0.014238119125366} ``` Default value is `true`.
  --real-time: oneof<nothing, bool> # In scales higher than max, since the data is aggregated, the timestamps returned are by default offset by +(scale/2). For instance, if you ask for measurements at a daily scale, you will receive data timestamped at 12:00 if real_time is set to `false` (default case), and timestamped at 00:00 if real_time is set to `true`. NB : The servers always store data with real_time set to `true` and data are offset by this parameter AFTER having being time-filtered, thus you could have data after date_end if real_time is set to `false`.
]: nothing -> oneof<record<body: table<beg_time: int, step_time: int, value: list>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id == null) { error make --unspanned { msg: "required query parameter 'device_id' missing: pass --device-id" } }
  if ($scale == null) { error make --unspanned { msg: "required query parameter 'scale' missing: pass --scale" } }
  if ($type == null) { error make --unspanned { msg: "required query parameter 'type' missing: pass --type" } }
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "type" $type "csv") (serialize-qp "date_begin" $date_begin "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "optimize" $optimize "scalar") (serialize-qp "real_time" $real_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getmeasure" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"device_id": $device_id, "module_id": $module_id, "scale": $scale, "type": $type, "date_begin": $date_begin, "date_end": $date_end, "limit": $limit, "optimize": $optimize, "real_time": $real_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns previous events.
#
# GET /getnextevents
# operationId: getnextevents
export def "getnextevents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in (required)
  --event-id: string # Your request will retrieve events occured before this one (required)
  --size: int # Number of events to retrieve. Default is 30.
]: nothing -> oneof<record<body: record<events_list: list<record>>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($home_id == null) { error make --unspanned { msg: "required query parameter 'home_id' missing: pass --home-id" } }
  if ($event_id == null) { error make --unspanned { msg: "required query parameter 'event_id' missing: pass --event-id" } }
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "event_id" $event_id "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getnextevents" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"home_id": $home_id, "event_id": $event_id, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves publicly shared weather data from Outdoor Modules within a predefined area.
#
# GET /getpublicdata
# operationId: getpublicdata
export def "getpublicdata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat-ne: int # Latitude of the north east corner of the requested area. -85 <= lat_ne <= 85 and lat_ne>lat_sw (required, format: int32)
  --lon-ne: int # Longitude of the north east corner of the requested area. -180 <= lon_ne <= 180 and lon_ne>lon_sw (required, format: int32)
  --lat-sw: int # Latitude of the south west corner of the requested area. -85 <= lat_sw <= 85 (required, format: int32)
  --lon-sw: int # Longitude of the south west corner of the requested area. -180 <= lon_sw <= 180 (required, format: int32)
  --required-data: list<string> # To filter stations based on relevant measurements you want (e.g. rain will only return stations with rain gauges). Default is no filter. You can find all measurements available on the Thermostat page.
  --filter: oneof<nothing, bool> # True to exclude stations with abnormal temperature measures. Default is false.
]: nothing -> oneof<record<body: table<_id: string, mark: int, measures: record, module_types: record, modules: list, place: record>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lat_ne == null) { error make --unspanned { msg: "required query parameter 'lat_ne' missing: pass --lat-ne" } }
  if ($lon_ne == null) { error make --unspanned { msg: "required query parameter 'lon_ne' missing: pass --lon-ne" } }
  if ($lat_sw == null) { error make --unspanned { msg: "required query parameter 'lat_sw' missing: pass --lat-sw" } }
  if ($lon_sw == null) { error make --unspanned { msg: "required query parameter 'lon_sw' missing: pass --lon-sw" } }
  let qp = [(serialize-qp "lat_ne" $lat_ne "scalar") (serialize-qp "lon_ne" $lon_ne "scalar") (serialize-qp "lat_sw" $lat_sw "scalar") (serialize-qp "lon_sw" $lon_sw "scalar") (serialize-qp "required_data" $required_data "csv") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getpublicdata" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lat_ne": $lat_ne, "lon_ne": $lon_ne, "lat_sw": $lat_sw, "lon_sw": $lon_sw, "required_data": $required_data, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The method getstationsdata Returns data from a user's Weather Stations (measures and device specific data).
#
# GET /getstationsdata
# operationId: getstationsdata
export def "getstationsdata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # Id of the device you want to retrieve information of
  --get-favorites: oneof<nothing, bool> # Whether to include the user's favorite Weather Stations in addition to the user's own Weather Stations (default: false)
]: nothing -> oneof<record<body: record<devices: list<record>, user: record<_id: string, administrative: record, date_creation: record, devices: list, friend_devices: list, mail: string, timeline_not_read: int, timeline_size: int>>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "get_favorites" $get_favorites "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getstationsdata" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"device_id": $device_id, "get_favorites": $get_favorites} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The method getthermostatsdata returns information about user's thermostats such as their last measurements.
#
# GET /getthermostatsdata
# operationId: getthermostatsdata
export def "getthermostatsdata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # Id of the device you want to retrieve information of
]: nothing -> oneof<record<body: record<devices: list<record>, user: record<_id: string, administrative: record, date_creation: record, devices: list, friend_devices: list, mail: string, timeline_not_read: int, timeline_size: int>>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getthermostatsdata" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"device_id": $device_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The method getthermstate returns the last Thermostat measurements, its current weekly schedule, and, if present, its current manual temperature setpoint.
#
# GET /getthermstate
# DEPRECATED
# operationId: getthermstate
@deprecated
export def "getthermstate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id (required)
  --module-id: string # The thermostat id (required)
]: nothing -> oneof<record<body: record<battery_percent: int, battery_vp: int, last_plug_seen: int, last_therm_seen: int, measured: record<setpoint_temp: float, temperature: float, time: int>, plug_connected_boiler: int, rf_status: int, setpoint: record<setpoint_endtime: int, setpoint_mode: string, setpoint_temp: float>, setpoint_order: record<setpoint_endtime: int, setpoint_mode: string, setpoint_temp: float>, therm_orientation: int, therm_program: record<name: string, program_id: string, selected: bool, timetable: list, zones: list>, therm_program_backup: list<record>, therm_program_order: record<name: string, program_id: string, selected: bool, timetable: list, zones: list>, therm_relay_cmd: int, udp_conn: bool, wifi_status: int>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id == null) { error make --unspanned { msg: "required query parameter 'device_id' missing: pass --device-id" } }
  if ($module_id == null) { error make --unspanned { msg: "required query parameter 'module_id' missing: pass --module-id" } }
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getthermstate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"device_id": $device_id, "module_id": $module_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The method getuser returns information about a user such as prefered language, prefered units, and list of devices.
#
# GET /getuser
# DEPRECATED
# operationId: getuser
@deprecated
export def "getuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<body: record<_id: string, administrative: record<country: string, feel_like_algo: string, lang: string, pressureunit: string, reg_locale: string, unit: string, windunit: string>, date_creation: record<sec: int, usec: int>, devices: list<string>, friend_devices: list<string>, mail: string, timeline_not_read: int, timeline_size: int>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getuser" $auth.query)
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

# The method partnerdevices returns the list of device_id to which your partner application has access to.
#
# GET /partnerdevices
# operationId: partnerdevices
export def "partnerdevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<body: list<string>, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partnerdevices" $auth.query)
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

# Sets a person as 'Away' or the Home as 'Empty'. The event will be added to the user’s timeline.
#
# POST /setpersonsaway
# operationId: setpersonsaway
export def "setpersonsaway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in (required)
  --person-id: string # If a person_id is specified, that person will be set as 'Away'. If no person_id is specified, the Home will be set as 'Empty'.
]: nothing -> oneof<record<status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($home_id == null) { error make --unspanned { msg: "required query parameter 'home_id' missing: pass --home-id" } }
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "person_id" $person_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setpersonsaway" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"home_id": $home_id, "person_id": $person_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Sets a person as 'At home'.
#
# POST /setpersonshome
# operationId: setpersonshome
export def "setpersonshome" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in (required)
  --person-ids: string # List of persons IDs (required)
]: nothing -> oneof<record<status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($home_id == null) { error make --unspanned { msg: "required query parameter 'home_id' missing: pass --home-id" } }
  if ($person_ids == null) { error make --unspanned { msg: "required query parameter 'person_ids' missing: pass --person-ids" } }
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "person_ids" $person_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setpersonshome" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"home_id": $home_id, "person_ids": $person_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# The method setthermpoint changes the Thermostat manual temperature setpoint.
#
# POST /setthermpoint
# operationId: setthermpoint
export def "setthermpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id (required)
  --module-id: string # The thermostat id (required)
  --setpoint-mode: string@setpoint-mode-completer # Chosen setpoint_mode (required)
  --setpoint-endtime: int # When using the manual or max setpoint_mode, this parameter defines when the setpoint expires. (format: int32)
  --setpoint-temp: float # When using the manual setpoint_mode, this parameter defines the temperature setpoint (in Celcius) to use. (format: float)
]: nothing -> oneof<record<body: string, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id == null) { error make --unspanned { msg: "required query parameter 'device_id' missing: pass --device-id" } }
  if ($module_id == null) { error make --unspanned { msg: "required query parameter 'module_id' missing: pass --module-id" } }
  if ($setpoint_mode == null) { error make --unspanned { msg: "required query parameter 'setpoint_mode' missing: pass --setpoint-mode" } }
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar") (serialize-qp "setpoint_mode" $setpoint_mode "scalar") (serialize-qp "setpoint_endtime" $setpoint_endtime "scalar") (serialize-qp "setpoint_temp" $setpoint_temp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setthermpoint" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"device_id": $device_id, "module_id": $module_id, "setpoint_mode": $setpoint_mode, "setpoint_endtime": $setpoint_endtime, "setpoint_temp": $setpoint_temp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# The method switchschedule switches the Thermostat's schedule to another existing schedule.
#
# POST /switchschedule
# operationId: switchschedule
export def "switchschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id (required)
  --module-id: string # The thermostat id (required)
  --schedule-id: string # The schedule id. It can be found in the getthermstate response, under the keys `therm_program_backup` and `therm_program`. (required)
]: nothing -> oneof<record<body: string, status: string, time_exec: float, time_server: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id == null) { error make --unspanned { msg: "required query parameter 'device_id' missing: pass --device-id" } }
  if ($module_id == null) { error make --unspanned { msg: "required query parameter 'module_id' missing: pass --module-id" } }
  if ($schedule_id == null) { error make --unspanned { msg: "required query parameter 'schedule_id' missing: pass --schedule-id" } }
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar") (serialize-qp "schedule_id" $schedule_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/switchschedule" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"device_id": $device_id, "module_id": $module_id, "schedule_id": $schedule_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# The method syncschedule changes the Thermostat weekly schedule.
#
# POST /syncschedule
# operationId: syncschedule
export def "syncschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id (required)
  --module-id: string # The thermostat id (required)
  --body: any
]: any -> oneof<record<body: string, status: string, time_exec: float, time_server: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id == null) { error make --unspanned { msg: "required query parameter 'device_id' missing: pass --device-id" } }
  if ($module_id == null) { error make --unspanned { msg: "required query parameter 'module_id' missing: pass --module-id" } }
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/syncschedule" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"device_id": $device_id, "module_id": $module_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
