# Auto-generated client for smart-me v1
# Source: https://api.apis.guru/v2/specs/smart-me.com/v1/openapi.json
# Auth: --token flag or $env.SMART_ME_TOKEN

const BASE_URL = "https://smart-me.com:443"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SMART_ME_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {"Authorization": $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://smart-me.com:443"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def device-energy-type-completer [] { ["MeterTypeAllMeters" "MeterTypeCompressedAir" "MeterTypeCustomDevice" "MeterTypeElectricity" "MeterTypeGas" "MeterTypeHCA" "MeterTypeHeat" "MeterTypeMBusGateway" "MeterTypeRS485Gateway" "MeterTypeSolarLog" "MeterTypeTemperature" "MeterTypeUnknown" "MeterTypeVirtualMeter" "MeterTypeWMBusGateway" "MeterTypeWater"] }
def meter-sub-type-completer [] { ["MeterSubTypeChargingStation" "MeterSubTypeCold" "MeterSubTypeElectricity" "MeterSubTypeElectricityHeat" "MeterSubTypeGas" "MeterSubTypeHeat" "MeterSubTypeTemperature" "MeterSubTypeUnknown" "MeterSubTypeVirtualBattery" "MeterSubTypeWater"] }
def meter-energy-type-completer [] { ["MeterTypeAllMeters" "MeterTypeCompressedAir" "MeterTypeCustomDevice" "MeterTypeElectricity" "MeterTypeGas" "MeterTypeHCA" "MeterTypeHeat" "MeterTypeMBusGateway" "MeterTypeRS485Gateway" "MeterTypeSolarLog" "MeterTypeTemperature" "MeterTypeUnknown" "MeterTypeVirtualMeter" "MeterTypeWMBusGateway" "MeterTypeWater"] }
def registration-type-completer [] { ["Disabled" "SingleMeterRegistration" "UserRegistration"] }
def dns-update-state-completer [] { ["DnsUpdateInternalIp" "DnsUpdatePublicIp" "NoUpdate"] }
def upload-interval-completer [] { ["UploadInterval_10s" "UploadInterval_12h" "UploadInterval_15min" "UploadInterval_1s" "UploadInterval_24h" "UploadInterval_30min" "UploadInterval_30s" "UploadInterval_5min" "UploadInterval_5s" "UploadInterval_60min" "UploadInterval_60s" "UploadInterval_6h"] }
def permission-level-completer [] { ["SelectedFolderAndSubfoldersMeters" "SelectedFolderOnly"] }
def folder-type-completer [] { ["Car" "ChargingStation" "Coffee" "ElecticityFolder" "Factory" "Folder" "Food" "GasFolder" "GridPhotovoltaicPowerSystem" "HeatFolder" "House" "Ice" "Light" "Location" "Machine" "Meter" "Office" "Sofa" "Sun" "TemperatureFolder" "Trash" "User" "VirtualMeter" "WaterFolder"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["access-token-put" "account-login" "post-api-account-login" "actions-post" "actions-get" "additional-device-information-get" "custom-device-get" "custom-device-post" "get-api-custom-device-id" "device-by-serial-get" "devices-get" "devices-post" "get-api-devices-id" "devices-put" "devices-by-energy-get" "devices-by-sub-type-get" "fast-send-device-values-get" "folder-get" "folder-menu-get" "folder-menu-post" "health-get" "m-bus-post" "meter-folder-information-post" "meter-folder-information-get" "meter-values-get" "register-for-realtime-api-get" "register-for-realtime-api-post" "register-for-realtime-api-delete" "smart-me-device-configuration-post" "smart-me-device-configuration-get" "sub-user-post" "sub-user-delete" "sub-user-get" "user-delete" "user-get" "values-get" "values-in-past-get" "values-in-past-multiple-get" "virtual-billing-meter-active-get" "virtual-billing-meter-active-post" "virtual-billing-meter-deactivate-post" "virtual-billing-meters-get" "virtual-meter-calculate-formula-get" "virtual-tariff-get" "get-api-virtual-tariff-id" "virtual-tariff-consumption-get" "virtual-tariffs-for-property-get" "virtual-tariffs-status-for-property-get" "folder-assign-post" "folder-settings-delete" "folder-settings-get" "folder-settings-post" "user-to-folder-assign-delete" "user-to-folder-assign-post" "o-auth-authorize" "post-api-oauth-authorize" "pico-get" "pico-charging-get" "pico-charging-history-get" "get-api-pico-loadmanagementgroup" "pico-loadmanagement-set-dynamic-current-post" "pico-loadmanagement-group-get" "pico-settings-get" "pico-enable-fix-cable-lock-post" "commands"] | sort) } | get name | first)
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

# Creates a Access Token to write on a Card (e.g. NFC)
#
# PUT /api/AccessToken
# operationId: AccessToken_Put
export def "access-token-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --card-id: int # The ID of the Card (format: int64)
  --user-id: int # The ID of the User. The credentials provided must have permission to edit the user. If no ID is provided, the user in the credentials is taken. (format: int64)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/AccessToken" $auth.query)
  let req_body = {"CardId": $card_id, "UserId": $user_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# GET /api/Account/login
#
# operationId: Account_Login
export def "account-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Account/login" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# POST /api/Account/login
export def "post-api-account-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Account/login" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Set an action for the specified device.
#
# POST /api/Actions
# operationId: Actions_Post
export def "actions-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list # List with all Actions for this device — item shape: {ObisCode?: string, Value?: float}
  --device-id: string # The ID of the Device
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Actions" $auth.query)
  let req_body = {"Actions": $actions, "DeviceID": $device_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets all available Actions of a Device
#
# GET /api/Actions/{id}
# operationId: Actions_Get
export def "actions-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<ActionType: string, MaxValue: float, MinValue: float, Name: string, ObisCode: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Actions/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets the additional information (e.g. Firmware Version) about a device.
#
# GET /api/AdditionalDeviceInformation/{id}
# operationId: AdditionalDeviceInformation_Get
export def "additional-device-information-get" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<AdditionalMeterSerialNumber: string, FirmwareVersion: int, HardwareVersion: int, ID: string, NetworkConnection: string, NetworkConnectionRSSI: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/AdditionalDeviceInformation/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets all Custom Devices
#
# GET /api/CustomDevice
# operationId: CustomDevice_Get
export def "custom-device-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<Id: string, Name: string, Serial: int, ValueDate: string, Values: list<record>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/CustomDevice" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Creates or updates a Custom Device or updates it's values.
#
# POST /api/CustomDevice
# operationId: CustomDevice_Post
export def "custom-device-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # The ID of the device
  --name: string # The Name of the Device
  --serial: int # The Serial number (format: int64)
  --value-date: string # The Date of the Value (in UTC). If this is null the Server Time is used. (format: date-time)
  --values: list # The Values of the custom Device — item shape: {Name?: string, Value?: float}
]: any -> oneof<record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/CustomDevice" $auth.query)
  let req_body = {"Id": $id, "Name": $name, "Serial": $serial, "ValueDate": $value_date, "Values": $values} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a Custom Device by it's ID
#
# GET /api/CustomDevice/{id}
export def "get-api-custom-device-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/CustomDevice/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets a Device by it's Serial Number. The Serial is the part before the "-".
#
# GET /api/DeviceBySerial
# operationId: DeviceBySerial_Get
export def "device-by-serial-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --serial: int # The Serial Number of the device (required, format: int64)
]: nothing -> oneof<record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($serial == null) { error make --unspanned { msg: "required query parameter 'serial' missing: pass --serial" } }
  let qp = [(serialize-qp "serial" $serial "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DeviceBySerial" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"serial": $serial} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all Devices
#
# GET /api/Devices
# operationId: Devices_Get
export def "devices-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Devices" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Creates or updates a Device or updates it's values.
#
# POST /api/Devices
# operationId: Devices_Post
export def "devices-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-power: float # The Active Power or current flow rate. In kW or m3/h (format: double)
  --counter-reading: float # The Meter Counter Reading (Total Energy used) in kWh or m3. (format: double)
  --counter-reading-export: float # The Meter Counter Reading only export (format: double)
  --counter-reading-export-t1: float # The Meter Counter Reading only export (Tariff 1) (format: double)
  --counter-reading-export-t2: float # The Meter Counter Reading only export (Tariff 2) (format: double)
  --counter-reading-t1: float # The Meter Counter Reading Tariff 1 in kWh or m3. (format: double)
  --counter-reading-t2: float # The Meter Counter Reading Tariff 2 in kWh or m3. (format: double)
  --current: float # The Current (in A) (format: double)
  --current-l1: float # The Current Phase L1 (in A) (format: double)
  --current-l2: float # The Current Phase L2 (in A) (format: double)
  --current-l3: float # The Current Phase L3 (in A) (format: double)
  --device-energy-type: string@device-energy-type-completer # The Energy Type of this device
  --digital-input1: oneof<nothing, bool> # The digital input number 1
  --id: string # The ID of the device
  --meter-sub-type: string@meter-sub-type-completer # The Sub Type of this Meter.
  --name: string # The Name of the Device
  --power-factor: float # The Power Factor (cos phi). Range: 0 - 1 (format: double)
  --power-factor-l1: float # The Power Factor (cos phi) Phase L1. Range: 0 - 1 (format: double)
  --power-factor-l2: float # The Power Factor (cos phi) Phase L2. Range: 0 - 1 (format: double)
  --power-factor-l3: float # The Power Factor (cos phi) Phase L3. Range: 0 - 1 (format: double)
  --serial: int # The Serial number (format: int64)
  --temperature: float # The Temperature (in degree celsius) (format: double)
  --value-date: string # The Date of the Value (in UTC). If this is null the Server Time is used. (format: date-time)
  --voltage: float # The Voltage (in V) (format: double)
  --voltage-l1: float # The Voltage Phase L1 (in V) (format: double)
  --voltage-l2: float # The Voltage Phase L2 (in V) (format: double)
  --voltage-l3: float # The Voltage Phase L3 (in V) (format: double)
]: any -> oneof<record<ActivePower: float, CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingT1: float, CounterReadingT2: float, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Devices" $auth.query)
  let req_body = {"ActivePower": $active_power, "CounterReading": $counter_reading, "CounterReadingExport": $counter_reading_export, "CounterReadingExportT1": $counter_reading_export_t1, "CounterReadingExportT2": $counter_reading_export_t2, "CounterReadingT1": $counter_reading_t1, "CounterReadingT2": $counter_reading_t2, "Current": $current, "CurrentL1": $current_l1, "CurrentL2": $current_l2, "CurrentL3": $current_l3, "DeviceEnergyType": $device_energy_type, "DigitalInput1": $digital_input1, "Id": $id, "MeterSubType": $meter_sub_type, "Name": $name, "PowerFactor": $power_factor, "PowerFactorL1": $power_factor_l1, "PowerFactorL2": $power_factor_l2, "PowerFactorL3": $power_factor_l3, "Serial": $serial, "Temperature": $temperature, "ValueDate": $value_date, "Voltage": $voltage, "VoltageL1": $voltage_l1, "VoltageL2": $voltage_l2, "VoltageL3": $voltage_l3} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a Device by it's ID
#
# GET /api/Devices/{id}
export def "get-api-devices-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Devices/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Updates the On/Off Switch on a device. For new implementations please use the "actions" command
#
# PUT /api/Devices/{id}
# operationId: Devices_Put
export def "devices-put" [
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
  --accept: string@accept-completer # Response content type
  --switch-state: oneof<nothing, bool> # The new state of the switch (required)
  --switch-number: int # The number of the switch if there are multiple (1 for L1, 3 for L3) (format: int32)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($switch_state == null) { error make --unspanned { msg: "required query parameter 'switchState' missing: pass --switch-state" } }
  let qp = [(serialize-qp "switchState" $switch_state "scalar") (serialize-qp "switchNumber" $switch_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Devices/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"switchState": $switch_state, "switchNumber": $switch_number} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Gets all Devices for an Energy Type
#
# GET /api/DevicesByEnergy
# operationId: DevicesByEnergy_Get
export def "devices-by-energy-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --meter-energy-type: string@meter-energy-type-completer # required
]: nothing -> oneof<table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($meter_energy_type == null) { error make --unspanned { msg: "required query parameter 'meterEnergyType' missing: pass --meter-energy-type" } }
  let qp = [(serialize-qp "meterEnergyType" $meter_energy_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DevicesByEnergy" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meterEnergyType": $meter_energy_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all Devices by it's Sub Type (e.g. E-Charging Station)
#
# GET /api/DevicesBySubType
# operationId: DevicesBySubType_Get
export def "devices-by-sub-type-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --meter-sub-type: string@meter-sub-type-completer # required
]: nothing -> oneof<table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($meter_sub_type == null) { error make --unspanned { msg: "required query parameter 'meterSubType' missing: pass --meter-sub-type" } }
  let qp = [(serialize-qp "meterSubType" $meter_sub_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/DevicesBySubType" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meterSubType": $meter_sub_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Force a device to send the data every second (if supported). This for about 30s. Don't use this call to force a device to send the data every second for a longer time.
#
# GET /api/FastSendDeviceValues/{id}
# operationId: FastSendDeviceValues_Get
export def "fast-send-device-values-get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/FastSendDeviceValues/{id}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# Gets the Values for a folder or a meter
#
# GET /api/Folder/{id}
# operationId: Folder_Get
export def "folder-get" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<ElectricityCounterValue: float, ElectricityPower: float, GasCounterValue: float, GasFlowRate: float, HeatCounterValue: float, HeatPower: float, WaterCounterValue: float, WaterFlowRate: float>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Folder/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets the folder menu items (each item might contain child items)
#
# GET /api/FolderMenu
# operationId: FolderMenu_Get
export def "folder-menu-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # (optional) Filter for the folders and meters: all: load everything assigned: load only folders and meters that are assigend to a folder unassigend: load only meters that are not assigend to a folder user: load only folder and all users assigned to this folders subuserlist: load all subusers as a list
]: nothing -> oneof<record<BrowserTimeZoneName: string, BrowserUtcTime: string, Items: table<AutoExportSettings: record, Children: list, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/FolderMenu" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates and updates the folder menu items
#
# POST /api/FolderMenu
# operationId: FolderMenu_Post
export def "folder-menu-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --browser-time-zone-name: string # The time zone name taken from the browser
  --browser-utc-time: string # The UTC time taken from the browser
  --items: list # item shape: {AutoExportSettings?: record, Children?: list, Description?: string, FolderType?: "Folder"|"Location"|"Factory"|"House"|"Office"|"Machine"|"VirtualMeter"|"ElecticityFolder"|"WaterFolder"|"HeatFolder"|"GasFolder"|"TemperatureFolder"|"Sun"|"Light"|"Ice"|"Sofa"|"Food"|"Coffee"|"Car"|"ChargingStation"|"Meter"|"User"|"Trash"|"GridPhotovoltaicPowerSystem", Icon?: string, Id?: string, MeterSerialNumber?: string, Name?: string, UserId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/FolderMenu" $auth.query)
  let req_body = {"BrowserTimeZoneName": $browser_time_zone_name, "BrowserUtcTime": $browser_utc_time, "Items": $items} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# A method returning HTTP 200 OK when queried. It is used by Kubernetes probes to determine whether the app is healthy.
#
# GET /api/Health
# operationId: Health_Get
export def "health-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Health" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# M-BUS API: Adds data of a M-BUS Meter to the smart-me Cloud. Just send us the M-BUS Telegram (RSP_UD) and we will do the Rest.
#
# POST /api/MBus
# operationId: MBus_Post
export def "m-bus-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --date: string # The Date of the M-BUS Telegram Readout (in UTC). If this is null the Server Time is used. (format: date-time)
  --telegram: string # The M-BUS Telegram as Hex string. Example: 68 1F 1F 68 08 02 72 78 56 34 12 24 40 01 07 55 00 00 00 03 13 15 31 00 DA 02 3B 13 01 8B 60 04 37 18 02 18 16
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/MBus" $auth.query)
  let req_body = {"Date": $date, "Telegram": $telegram} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Sets the Name of a Meter or a Folder
#
# POST /api/MeterFolderInformation
# operationId: MeterFolderInformation_Post
export def "meter-folder-information-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the device or folder
  --name: string # Name of the Meter or Folder
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/MeterFolderInformation" $auth.query)
  let req_body = {"Id": $id, "Name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Beta: Gets the General Information for a Meter or a Folder
#
# GET /api/MeterFolderInformation/{id}
# operationId: MeterFolderInformation_Get
export def "meter-folder-information-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<CommunicationModuleFirmwareVersion: int, CommunicationModuleHardwareVersion: int, FirmwareVersion: int, HardwareVersion: int, InputInformations: table<Name: string, Number: int>, IsFolder: bool, Name: string, OutputInformations: table<ActionType: string, Name: string, Number: int, ObisCode: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/MeterFolderInformation/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets the Values for a Meter at a given Date. The first Value found before the given Date is returned.
#
# GET /api/MeterValues/{id}
# operationId: MeterValues_Get
export def "meter-values-get" [
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
  --accept: string@accept-completer # Response content type
  --date: string # required, format: date-time
]: nothing -> oneof<record<CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingExportT3: float, CounterReadingExportT4: float, CounterReadingImport: float, CounterReadingImportT1: float, CounterReadingImportT2: float, CounterReadingImportT3: float, CounterReadingImportT4: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Date: string, Id: string, Serial: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($date == null) { error make --unspanned { msg: "required query parameter 'date' missing: pass --date" } }
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/MeterValues/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"date": $date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all registrations for the Realtime API.
#
# GET /api/RegisterForRealtimeApi
# operationId: RegisterForRealtimeApi_Get
export def "register-for-realtime-api-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<ApiUrl: string, BasicAuthPassword: string, BasicAuthUsername: string, Id: string, MeterId: string, RegistrationType: string, SerialNumber: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/RegisterForRealtimeApi" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Creates a new registration for the realtime API. The Realtime API sends you the data of the registred devices as soon as we have them on the cloud. More Information about the realtime API: https://www.smart-me.com/Description/api/realtimeapi.aspx
#
# POST /api/RegisterForRealtimeApi
# operationId: RegisterForRealtimeApi_Post
export def "register-for-realtime-api-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-url: string # The URL of your endpoint. To this endpoint all the values are send to.
  --basic-auth-password: string # The Password (basic auth) of your endpoint. Leave empty of none.
  --basic-auth-username: string # The Username (basic auth) of your endpoint. Leave empty of none.
  --id: string # The ID of the registration
  --meter-id: string # The ID of the Meter. Just used if the RegistrationType is "SingleMeterRegistration".
  --registration-type: string@registration-type-completer # The Type of this registration (per meter, per user, ...)
  --serial-number: string # The serial number of the Meter. Just used if the RegistrationType is "SingleMeterRegistration" and the MeterId is null. Example: 1 SME 01 63000000 or 6300000
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/RegisterForRealtimeApi" $auth.query)
  let req_body = {"ApiUrl": $api_url, "BasicAuthPassword": $basic_auth_password, "BasicAuthUsername": $basic_auth_username, "Id": $id, "MeterId": $meter_id, "RegistrationType": $registration_type, "SerialNumber": $serial_number} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Deletes a realtime API registration.
#
# DELETE /api/RegisterForRealtimeApi/{id}
# operationId: RegisterForRealtimeApi_Delete
export def "register-for-realtime-api-delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/RegisterForRealtimeApi/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Sets the configuration of a smart-me device. The device needs to be online.
#
# POST /api/SmartMeDeviceConfiguration
# operationId: SmartMeDeviceConfiguration_Post
export def "smart-me-device-configuration-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-encryption-key: string # The encryption key used to decrypt messages received from an external meter (used only for the smart-me modules)
  --device-pin-code: string # PIN code to enter on a external meter (e.g. for the FNN meters)
  --dns-update-state: string@dns-update-state-completer # Configuration of the dynamic DNS service. More information: http://wiki.smart-me.com/index.php/Dynamisches_DNS
  --enable-modbus-tcp: oneof<nothing, bool> # Enables or disables Modbus TCP (if the meter supports it).
  --id: string # The ID of the device
  --input-configuration: list # The configuration for the intput outputs — item shape: {Name?: string, Number?: int, OffText?: string, OnText?: string, Type?: "TariffInput"|"DigitalInput"}
  --output-configuration: list # The configuration for the external outputs — item shape: {DigitalOutputNoConnectionAction?: "Nothing"|"TurnOff"|"TurnOn"|"SetPwmValue", Name?: string, Number?: int, S0PulseValue?: "PulseValue1000Kwh"|"PulseValue10000Kwh", Type?: "ImpulseOutputActiveEnergy"|"ImpulseOutputActiveEnergyImport"|"ImpulseOutputActiveEnergyExport"|"ImpulseOutputReactiveEnergy"|"DigitalOutput"|"AnalogPwmSignalOutput"|"Disabled"}
  --show-reactive-energy: oneof<nothing, bool> # Shows the reactive energy values (if the meter supports it).
  --switch-configuration: list # The configuration for the phase switches — item shape: {CanSwitchOff?: bool, Number?: int}
  --upload-interval: string@upload-interval-completer # Number of seconds the device will upload the data. For smaller values maybe a professional license is needed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/SmartMeDeviceConfiguration" $auth.query)
  let req_body = {"DeviceEncryptionKey": $device_encryption_key, "DevicePinCode": $device_pin_code, "DnsUpdateState": $dns_update_state, "EnableModbusTcp": $enable_modbus_tcp, "Id": $id, "InputConfiguration": $input_configuration, "OutputConfiguration": $output_configuration, "ShowReactiveEnergy": $show_reactive_energy, "SwitchConfiguration": $switch_configuration, "UploadInterval": $upload_interval} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets the configuration of a smart-me device.
#
# GET /api/SmartMeDeviceConfiguration/{id}
# operationId: SmartMeDeviceConfiguration_Get
export def "smart-me-device-configuration-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<DeviceEncryptionKey: string, DevicePinCode: string, DnsUpdateState: string, EnableModbusTcp: bool, Id: string, InputConfiguration: table<Name: string, Number: int, OffText: string, OnText: string, Type: string>, OutputConfiguration: table<DigitalOutputNoConnectionAction: string, Name: string, Number: int, S0PulseValue: string, Type: string>, ShowReactiveEnergy: bool, SwitchConfiguration: table<CanSwitchOff: bool, Number: int>, UploadInterval: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/SmartMeDeviceConfiguration/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Creates or updates a subuser. To create a new user set no ID (empty)
#
# POST /api/SubUser
# operationId: SubUser_Post
export def "sub-user-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-end-date: string # The end date. until this date the user has access (format: date-time)
  --access-time-start-date: string # The start date. From this date the user has access (format: date-time)
  --email: string # The Email adress
  --id: string # The ID of the user
  --new-password: string # If set this is used a new password
  --permission-level: string@permission-level-completer # The permission level of the user
  --username: string # The username
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/SubUser" $auth.query)
  let req_body = {"AccessEndDate": $access_end_date, "AccessTimeStartDate": $access_time_start_date, "Email": $email, "Id": $id, "NewPassword": $new_password, "PermissionLevel": $permission_level, "Username": $username} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete a subuser
#
# DELETE /api/SubUser/{id}
# operationId: SubUser_Delete
export def "sub-user-delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/SubUser/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a sub user. The user must be assigend to the user that makes this call.
#
# GET /api/SubUser/{id}
# operationId: SubUser_Get
export def "sub-user-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<AccessEndDate: string, AccessTimeStartDate: string, Email: string, Id: string, NewPassword: string, PermissionLevel: string, Username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/SubUser/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Triggers user account deletion.
#
# DELETE /api/User
# operationId: User_Delete
export def "user-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/User" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Gets the informations for the user.
#
# GET /api/User
# operationId: User_Get
export def "user-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<ChildUsers: list<any>, Email: string, Id: int, IdAsString: string, IsAdmin: bool, Permissions: list<string>, Username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/User" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets all (last) values of a device
#
# GET /api/Values/{id}
# operationId: Values_Get
export def "values-get" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<Date: string, DeviceId: string, Values: table<Obis: string, Value: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Values/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets all (last) values of a device The first Value found before the given Date is returned.
#
# GET /api/ValuesInPast/{id}
# operationId: ValuesInPast_Get
export def "values-in-past-get" [
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
  --accept: string@accept-completer-1 # Response content type
  --date: string # the date of the value (required, format: date-time)
]: nothing -> oneof<record<Date: string, DeviceId: string, Values: table<Obis: string, Value: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($date == null) { error make --unspanned { msg: "required query parameter 'date' missing: pass --date" } }
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/ValuesInPast/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"date": $date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets multiple values of a device. This call needs a smart-me professional licence.
#
# GET /api/ValuesInPastMultiple/{id}
# operationId: ValuesInPastMultiple_Get
export def "values-in-past-multiple-get" [
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
  --accept: string@accept-completer # Response content type
  --start-date: string # The date when the first value should start (required, format: date-time)
  --end-date: string # The date when the last value should start (required, format: date-time)
  --interval: int # The interval in minutes betwenn the values. 0 means as fast as possible. Only 1000 values can be get in one call. (required, format: int32)
]: nothing -> oneof<table<Date: string, DeviceId: string, Values: list<record>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  if ($interval == null) { error make --unspanned { msg: "required query parameter 'interval' missing: pass --interval" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/ValuesInPastMultiple/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date, "interval": $interval} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Beta: Gets all active virtual meters
#
# GET /api/VirtualBillingMeterActive
# operationId: VirtualBillingMeterActive_Get
export def "virtual-billing-meter-active-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeterActive" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Beta: Virtual Meter API: Activates a Meter and add the Consumption to a Virtual Meter assosiated with the User.
#
# POST /api/VirtualBillingMeterActive
# operationId: VirtualBillingMeterActive_Post
export def "virtual-billing-meter-active-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --serial-number: string # The Serialnumber of the Meter to activate.
]: any -> oneof<record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeterActive" $auth.query)
  let req_body = {"SerialNumber": $serial_number} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Beta: Virtual Meter API: Deactivates a Virtual Meter.
#
# POST /api/VirtualBillingMeterDeactivate
# operationId: VirtualBillingMeterDeactivate_Post
export def "virtual-billing-meter-deactivate-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # The ID of the Virtual meter to deactivate
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeterDeactivate" $auth.query)
  let req_body = {"ID": $id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Beta: Gets all Meters available to activate as a Virtual Meter.
#
# GET /api/VirtualBillingMeters
# operationId: VirtualBillingMeters_Get
export def "virtual-billing-meters-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualBillingMeters" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Calculates a virtual meter from a formula. A meter is coded as ID("METERID")
#
# GET /api/VirtualMeterCalculateFormula
# operationId: VirtualMeterCalculateFormula_Get
export def "virtual-meter-calculate-formula-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --formula: string # required
]: nothing -> oneof<record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($formula == null) { error make --unspanned { msg: "required query parameter 'formula' missing: pass --formula" } }
  let qp = [(serialize-qp "formula" $formula "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/VirtualMeterCalculateFormula" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"formula": $formula} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all Virtual Tariffs of a user
#
# GET /api/VirtualTariff
# operationId: VirtualTariff_Get
export def "virtual-tariff-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<Date: string, FolderId: string, Name: string, VirtualTariffs: list<record>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/VirtualTariff" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets all virtual tariffs of a folder
#
# GET /api/VirtualTariff/{id}
export def "get-api-virtual-tariff-id" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<Date: string, FolderId: string, Name: string, VirtualTariffs: table<Factor: float, Id: string, Name: string, Type: string, Unit: string, Value: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/VirtualTariff/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets the consumption of a folder with a virtuall tariffs.
#
# GET /api/VirtualTariffConsumption
# operationId: VirtualTariffConsumption_Get
export def "virtual-tariff-consumption-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --folder-id: string # The ID of the Folder (required)
  --start-date: string # The start date (UTC) (required, format: date-time)
  --end-date: string # The end date (UTC) (required, format: date-time)
]: nothing -> oneof<table<Consumption: float, Currency: string, Name: string, Price: float, TariffType: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($folder_id == null) { error make --unspanned { msg: "required query parameter 'folderId' missing: pass --folder-id" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  let qp = [(serialize-qp "folderId" $folder_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/VirtualTariffConsumption" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"folderId": $folder_id, "startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all Virtual Tariffs for a property (folder)
#
# GET /api/VirtualTariffsForProperty/{id}
# operationId: VirtualTariffsForProperty_Get
export def "virtual-tariffs-for-property-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<Date: string, FolderId: string, Name: string, VirtualTariffs: list<record>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/VirtualTariffsForProperty/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets the calculation status for a virtual tariff property
#
# GET /api/VirtualTariffsStatusForProperty/{id}
# operationId: VirtualTariffsStatusForProperty_Get
export def "virtual-tariffs-status-for-property-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/VirtualTariffsStatusForProperty/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Assign a folder (source) or meter to another folder (target). Can be used to create a folder structure.
#
# POST /api/folder/assign
# operationId: FolderAssign_Post
export def "folder-assign-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string # The ID of the meter or folder that should be assign (required)
  --target: string # The ID of the meter or folder that should be the parent (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($source == null) { error make --unspanned { msg: "required query parameter 'source' missing: pass --source" } }
  if ($target == null) { error make --unspanned { msg: "required query parameter 'target' missing: pass --target" } }
  let qp = [(serialize-qp "source" $source "scalar") (serialize-qp "target" $target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/folder/assign" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"source": $source, "target": $target} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Deletes a folder
#
# DELETE /api/folder/settings/{id}
# operationId: FolderSettings_Delete
export def "folder-settings-delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/folder/settings/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the settings of a folder or meter
#
# GET /api/folder/settings/{id}
# operationId: FolderSettings_Get
export def "folder-settings-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<Description: string, Enable: bool, FolderType: string, Name: string, ParentFolderId: string, SerialNumber: int, UseableForVirtualBillingMeters: bool, ValueCorrection: float, ValueCorrectionParentFolder: float, VisualizationName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/folder/settings/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Add or edit a folder or a meter. To add a new folder use and empty ID
#
# POST /api/folder/settings/{id}
# operationId: FolderSettings_Post
export def "folder-settings-post" [
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
  --accept: string@accept-completer # Response content type
  --description: string # The Description of the folder or meter
  --enable: oneof<nothing, bool> # Flag if the meter is enabled (folder not supported yet)
  --folder-type: string@folder-type-completer # The Type of the folder
  --name: string # The Name of the folder or meter
  --parent-folder-id: string # The parent folder ID of this item
  --serial-number: int # The serial number (meter only) (format: int64)
  --useable-for-virtual-billing-meters: oneof<nothing, bool> # Flag if the meter is usable for virtual billing meters (e.g. washroom)
  --value-correction: float # The value correction on this meter (format: double)
  --value-correction-parent-folder: float # The value correction on all parent folders. but not on the meter itself (format: double)
  --visualization-name: string # The name of the visualization of the folder
]: any -> oneof<record<AutoExportSettings: record<ExportFormat: string, ExportInterval: string, MeterPointId: string, UploadType: string>, Children: list<any>, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/folder/settings/{id}") $auth.query)
  let req_body = {"Description": $description, "Enable": $enable, "FolderType": $folder_type, "Name": $name, "ParentFolderId": $parent_folder_id, "SerialNumber": $serial_number, "UseableForVirtualBillingMeters": $useable_for_virtual_billing_meters, "ValueCorrection": $value_correction, "ValueCorrectionParentFolder": $value_correction_parent_folder, "VisualizationName": $visualization_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a user to folder assignement
#
# DELETE /api/folder/user/assign
# operationId: UserToFolderAssign_Delete
export def "user-to-folder-assign-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string # The ID of the user that should be de-assign (required)
  --target: string # The ID of the folder (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($source == null) { error make --unspanned { msg: "required query parameter 'source' missing: pass --source" } }
  if ($target == null) { error make --unspanned { msg: "required query parameter 'target' missing: pass --target" } }
  let qp = [(serialize-qp "source" $source "scalar") (serialize-qp "target" $target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/folder/user/assign" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"source": $source, "target": $target} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Assign a user to a folder
#
# POST /api/folder/user/assign
# operationId: UserToFolderAssign_Post
export def "user-to-folder-assign-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string # The ID of the user that should be assign (required)
  --target: string # The ID of the folder that should be the parent (required)
  --old-folder: string # The ID of the old folder (in case of a drag and drop to a new folder) (required)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($source == null) { error make --unspanned { msg: "required query parameter 'source' missing: pass --source" } }
  if ($target == null) { error make --unspanned { msg: "required query parameter 'target' missing: pass --target" } }
  if ($old_folder == null) { error make --unspanned { msg: "required query parameter 'oldFolder' missing: pass --old-folder" } }
  let qp = [(serialize-qp "source" $source "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "oldFolder" $old_folder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/folder/user/assign" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"source": $source, "target": $target, "oldFolder": $old_folder} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# GET /api/oauth/authorize
#
# operationId: OAuth_Authorize
export def "o-auth-authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string # required
  --redirect-uri: string # required
  --state: string # required
  --scope: string
  --client-secret: string
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id == null) { error make --unspanned { msg: "required query parameter 'client_id' missing: pass --client-id" } }
  if ($redirect_uri == null) { error make --unspanned { msg: "required query parameter 'redirect_uri' missing: pass --redirect-uri" } }
  if ($state == null) { error make --unspanned { msg: "required query parameter 'state' missing: pass --state" } }
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/oauth/authorize" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"client_id": $client_id, "redirect_uri": $redirect_uri, "state": $state, "scope": $scope, "client_secret": $client_secret} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /api/oauth/authorize
export def "post-api-oauth-authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string # required
  --redirect-uri: string # required
  --state: string # required
  --scope: string
  --client-secret: string
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id == null) { error make --unspanned { msg: "required query parameter 'client_id' missing: pass --client-id" } }
  if ($redirect_uri == null) { error make --unspanned { msg: "required query parameter 'redirect_uri' missing: pass --redirect-uri" } }
  if ($state == null) { error make --unspanned { msg: "required query parameter 'state' missing: pass --state" } }
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/oauth/authorize" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"client_id": $client_id, "redirect_uri": $redirect_uri, "state": $state, "scope": $scope, "client_secret": $client_secret} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Gets all pico charging stations for this user
#
# GET /api/pico
# operationId: Pico_Get
export def "pico-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pico" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets the active charging data of a pico station
#
# GET /api/pico/charging/{id}
# operationId: PicoCharging_Get
export def "pico-charging-get" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<ActiveChargingEnergy: float, ActiveChargingPower: float, ConnectionMode: string, Duration: int, LastWarningOrError: string, LastWarningOrErrorMessage: string, LastWarningOrErrorTime: string, LoadSheddingState: string, LoadmanagementGroupName: string, MaxAllowedChargingCurrent: int, MaxDynamicCurrent: int, MaxLoadmanagementGroupCurrent: int, MaxStationCurrent: int, MinStationCurrent: int, State: string, ValueDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/pico/charging/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets the last charging history for a pico station
#
# GET /api/pico/history/{id}
# operationId: PicoChargingHistory_Get
export def "pico-charging-history-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<Duration: int, EnergyUsed: float, StartTime: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/pico/history/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# GET: api/pico/loadmanagementgroup Returns all available load management groups
#
# GET /api/pico/loadmanagementgroup
export def "get-api-pico-loadmanagementgroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<Id: string, MaxCurrent: float, Name: string, NumberOfStations: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pico/loadmanagementgroup" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Sets the dynamic current of a load management group or a single station.
#
# POST /api/pico/loadmanagementgroup/current/{serial}
# operationId: PicoLoadmanagementSetDynamicCurrent_Post
export def "pico-loadmanagement-set-dynamic-current-post" [
  serial: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --current: int # The dynamic current of the group (in mA) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($serial | is-empty) { error make --unspanned { msg: "path parameter 'serial' must be non-empty" } }
  if ($current == null) { error make --unspanned { msg: "required query parameter 'current' missing: pass --current" } }
  let qp = [(serialize-qp "current" $current "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/api/pico/loadmanagementgroup/current/{serial}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"current": $current} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# GET: api/pico/loadmanagementgroup Returns a pico load management group by it's id
#
# GET /api/pico/loadmanagementgroup/{id}
# operationId: PicoLoadmanagementGroup_Get
export def "pico-loadmanagement-group-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<Id: string, MaxCurrent: float, Name: string, NumberOfStations: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/pico/loadmanagementgroup/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# GET: api/pico/settings Returns the settings of a pico charging station.
#
# GET /api/pico/settings/{id}
# operationId: PicoSettings_Get
export def "pico-settings-get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<AuthenticationType: string, CarIdDetection: bool, DisplayBrightness: string, DnsName: string, FixCableLockEnable: bool, IdleImageUrl: string, InternalIp: string, LoadmanagementGroupId: string, MaxCurrent: int, MinCurrent: int, ModbusTcp: bool, Name: string, SerialNumber: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/pico/settings/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Try to fix lock the cable of a pico. The pico must be online and a cable (without car) needs to be connected. Otherwise this will fail.
#
# POST /api/pico/tryenablecablelock/{id}
# operationId: PicoEnableFixCableLock_Post
export def "pico-enable-fix-cable-lock-post" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/pico/tryenablecablelock/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
