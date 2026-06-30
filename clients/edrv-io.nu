# Auto-generated client for eDRV API vv1
# Source: https://api.apis.guru/v2/specs/edrv.io/v1/openapi.json
# Auth: --token flag or $env.EDRV_API_TOKEN

const BASE_URL = "http://localhost//api.edrv.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o EDRV_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://localhost//api.edrv.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-order-completer [] { ["asc" "desc"] }
def variable-completer [] { ["ConnectionTimeOut" "HeartbeatInterval" "MeterValueSampleInterval" "TransactionMessageAttempts" "TransactionMessageRetryInterval" "WebSocketPingInterval"] }
def source-completer [] { ["physical" "slack" "sms" "telegram"] }
def channel-completer [] { ["physical" "slack" "sms" "telegram"] }
def status-completer [] { ["Ended" "Started"] }
def action-completer [] { ["START" "STOP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "chargestations get-charge-stations" } } | get name | first)
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

# List all Chargestations
#
# GET /v1/chargestations
# operationId: getChargeStations
export def "chargestations get-charge-stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization: string # Filter by Org. Id
  --location: string # Filter by Location Id
  --online: oneof<nothing, bool> # Filter by Online Status
  --active: oneof<nothing, bool> # Chargestations that have been activated/deactivated by the admin
  --public: oneof<nothing, bool> # Chargestations that are public
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-location: oneof<nothing, bool> # Populate location
  --include-evses: oneof<nothing, bool> # Populate evses
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization" $organization "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "online" $online "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "public" $public "scalar") (serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_location" $include_location "scalar") (serialize-qp "include_evses" $include_evses "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/chargestations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"organization": $organization, "location": $location, "online": $online, "active": $active, "public": $public, "paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_location": $include_location, "include_evses": $include_evses, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new charge station
#
# POST /v1/chargestations
# operationId: postChargeStations
export def "chargestations create-charge-stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: string
  --manufacturer: string
  --model: string
  --protocol: string
  --public: oneof<nothing, bool>
]: any -> record<chargestation: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/chargestations" $auth.query)
  let req_body = {"location": $location, "manufacturer": $manufacturer, "model": $model, "protocol": $protocol, "public": $public} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use to delete a charge station
#
# DELETE /v1/chargestations/{id}
# operationId: deleteChargeStation
export def "chargestations delete-charge-station" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/chargestations/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a single charge station's data
#
# GET /v1/chargestations/{id}
# operationId: getChargeStation
export def "chargestations get-charge-station" [
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
  --include-location: oneof<nothing, bool> # Populate location
  --include-evses: oneof<nothing, bool> # Populate evses
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_location" $include_location "scalar") (serialize-qp "include_evses" $include_evses "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/chargestations/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_location": $include_location, "include_evses": $include_evses, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a charge station's data
#
# PATCH /v1/chargestations/{id}
# operationId: patchChargeStation
export def "chargestations update-charge-station" [
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
  --location: string
  --manufacturer: string
  --model: string
  --protocol: string
  --public: oneof<nothing, bool>
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/chargestations/{id}") $auth.query)
  let req_body = {"location": $location, "manufacturer": $manufacturer, "model": $model, "protocol": $protocol, "public": $public} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# List connectors for a chargestation
#
# GET /v1/chargestations/{id}/connectors
# operationId: getChargeStationConnectors
export def "chargestations-connectors get-charge-station" [
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
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/chargestations/{id}/connectors") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_evse": $include_evse, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Commands data
#
# GET /v1/commands
# operationId: getCommands
export def "commands get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-transaction: oneof<nothing, bool> # Populate transaction
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_transaction" $include_transaction "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/commands" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_chargestation": $include_chargestation, "include_driver": $include_driver, "include_transaction": $include_transaction, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use to request a delete an existing reservation. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/cancelreservation
# operationId: cancelreservation
export def "commands-cancelreservation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/cancelreservation" $auth.query)
  let req_body = {"reservation": $reservation} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a smart charging schedule
#
# DELETE /v1/commands/chargingschedule
# operationId: deletechargingschedule
export def "commands-chargingschedule delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/chargingschedule" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [201]
}

# Set one of charging power or current of a specific chargestation connector
#
# POST /v1/commands/chargingschedule
# operationId: setchargingschedule
# --schedule item shape: {endDate?: string, limit?: float, startDate?: string, unit?: string}
export def "commands-chargingschedule create-setchargingschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connector: string
  --schedule: list # item shape: {endDate?: string, limit?: float, startDate?: string, unit?: string}
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/chargingschedule" $auth.query)
  let req_body = {"connector": $connector, "schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use to request a remote start command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/remotestart
# operationId: remotestart
export def "commands-remotestart create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
  --driver: string
  --body-token: string
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/remotestart" $auth.query)
  let req_body = {"chargestation": $chargestation, "connector": $connector, "driver": $driver, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use to request a remote stop command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/remotestop
# operationId: remotestop
export def "commands-remotestop create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --driver: string
  --transaction: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/remotestop" $auth.query)
  let req_body = {"chargestation": $chargestation, "driver": $driver, "transaction": $transaction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use to request a reserve command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/reserve
# operationId: reserve
export def "commands-reserve create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
  --driver: string
  --end-date: string
  --body-token: string
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/reserve" $auth.query)
  let req_body = {"chargestation": $chargestation, "connector": $connector, "driver": $driver, "endDate": $end_date, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use to request a reset command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/reset
# operationId: reset
export def "commands-reset reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --type: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/reset" $auth.query)
  let req_body = {"chargestation": $chargestation, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use to request an unlock command for a connector. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/unlockconnector
# operationId: unlockconnector
export def "commands-unlockconnector create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/unlockconnector" $auth.query)
  let req_body = {"chargestation": $chargestation, "connector": $connector} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get a charge station's config variables
#
# GET /v1/commands/{id}/variables
# operationId: getVariables
export def "commands-variables get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/commands/{id}/variables") $auth.query)
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

# Update config variables for a chargestation
#
# PATCH /v1/commands/{id}/variables
# operationId: patchChargeStationVariable
export def "commands-variables update-charge-station" [
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
  --value: string
  --variable: string@variable-completer
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/commands/{id}/variables") $auth.query)
  let req_body = {"value": $value, "variable": $variable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get Configurations data
#
# GET /v1/configurations
# operationId: getConfigurations
export def "configurations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/configurations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create connector with parameters
#
# POST /v1/configurations
# operationId: postConfigurations
export def "configurations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --value: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/configurations" $auth.query)
  let req_body = {"key": $key, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get one Configuration data
#
# GET /v1/configurations/{id}
# operationId: getConfiguration
export def "configurations get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/configurations/{id}") $auth.query)
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

# List connectors
#
# GET /v1/connectors
# operationId: getConnectors
export def "connectors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_organization" $include_organization "scalar") (serialize-qp "include_rate" $include_rate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connectors" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_evse": $include_evse, "include_organization": $include_organization, "include_rate": $include_rate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new connector
#
# POST /v1/connectors
# operationId: postConnectors
export def "connectors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --format: string
  --power: int
  --power-type: string
  --rate: string
  --type: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connectors" $auth.query)
  let req_body = {"chargestation": $chargestation, "format": $format, "power": $power, "power_type": $power_type, "rate": $rate, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Delete a connector
#
# DELETE /v1/connectors/{id}
# operationId: deleteConnector
export def "connectors delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/connectors/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a connector
#
# GET /v1/connectors/{id}
# operationId: getConnector
export def "connectors get" [
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
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_organization" $include_organization "scalar") (serialize-qp "include_rate" $include_rate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/connectors/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_evse": $include_evse, "include_organization": $include_organization, "include_rate": $include_rate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a connector's data
#
# PATCH /v1/connectors/{id}
# operationId: patchConnector
export def "connectors update" [
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
  --chargestation: string
  --format: string
  --power: int
  --power-type: string
  --rate: string
  --type: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/connectors/{id}") $auth.query)
  let req_body = {"chargestation": $chargestation, "format": $format, "power": $power, "power_type": $power_type, "rate": $rate, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# List all drivers
#
# GET /v1/drivers
# operationId: getDrivers
export def "drivers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Get a list of active drivers
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-tokens: oneof<nothing, bool> # Populate tokens
  --include-group: oneof<nothing, bool> # Populate group
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> record<message: string, ok: bool, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_tokens" $include_tokens "scalar") (serialize-qp "include_group" $include_group "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/drivers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"active": $active, "paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_tokens": $include_tokens, "include_group": $include_group, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new driver
#
# POST /v1/drivers
# operationId: postDrivers
# --address shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
# --phone shape: {home?: string, mobile?: string, work?: string}
export def "drivers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  --address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --email: string
  firstname: string
  lastname: string
  --phone: record # shape: {home?: string, mobile?: string, work?: string}
  --body-source: string@source-completer
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/drivers" $auth.query)
  let req_body = {"active": $active, "address": $address, "email": $email, "firstname": $firstname, "lastname": $lastname, "phone": $phone, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Delete a driver
#
# DELETE /v1/drivers/{id}
# operationId: deleteDriver
export def "drivers delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/drivers/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a driver's data
#
# GET /v1/drivers/{id}
# operationId: getDriver
export def "drivers get" [
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
  --include-tokens: oneof<nothing, bool> # Populate tokens
  --include-group: oneof<nothing, bool> # Populate group
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_tokens" $include_tokens "scalar") (serialize-qp "include_group" $include_group "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/drivers/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_tokens": $include_tokens, "include_group": $include_group, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a driver's data
#
# PATCH /v1/drivers/{id}
# operationId: patchDriver
# --address shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
# --phone shape: {home?: string, mobile?: string, work?: string}
export def "drivers update" [
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
  --active: oneof<nothing, bool>
  --address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --email: string
  --firstname: string
  --lastname: string
  --phone: record # shape: {home?: string, mobile?: string, work?: string}
  --body-source: string
  --tokens: list
]: any -> record<message: string, ok: bool, result: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/drivers/{id}") $auth.query)
  let req_body = {"active": $active, "address": $address, "email": $email, "firstname": $firstname, "lastname": $lastname, "phone": $phone, "source": $body_source, "tokens": $tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a location
#
# DELETE /v1/location/{id}
# operationId: deleteLocation
export def "location delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/location/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a location's data
#
# GET /v1/location/{id}
# operationId: getLocation
export def "location get" [
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
  --include-chargestations: oneof<nothing, bool> # Populate chargestations
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_chargestations" $include_chargestations "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/location/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_chargestations": $include_chargestations, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a location's data
#
# PATCH /v1/location/{id}
# operationId: patchLocation
# --address shape: {city?: string, country?: string, postalCode?: string, state?: string, streetAndNumber?: string}
# --coordinates shape: {latitude?: float, longitude?: float}
# --openingHours shape: {0?: list, 1?: list, 2?: list, 3?: list, 4?: list, 5?: list, 6?: list}
export def "location update" [
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
  --active: oneof<nothing, bool> # default: true
  --address: record # shape: {city?: string, country?: string, postalCode?: string, state?: string, streetAndNumber?: string}
  --chargestations: list
  --coordinates: record # shape: {latitude?: float, longitude?: float}
  --opening-hours: record # shape: {0?: list, 1?: list, 2?: list, 3?: list, 4?: list, 5?: list, 6?: list}
  --operator-name: string
  --timezone: string
]: any -> record<message: string, ok: bool, result: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/location/{id}") $auth.query)
  let req_body = {"active": $active, "address": $address, "chargestations": $chargestations, "coordinates": $coordinates, "openingHours": $opening_hours, "operatorName": $operator_name, "timezone": $timezone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Locations data
#
# GET /v1/locations
# operationId: getLocations
export def "locations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/locations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new location
#
# POST /v1/locations
# operationId: postLocations
# --address shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
# --coordinates shape: {latitude?: float, longitude?: float}
export def "locations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --chargestations: list
  coordinates: record # shape: {latitude?: float, longitude?: float}
  operator_name: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/locations" $auth.query)
  let req_body = {"active": $active, "address": $address, "chargestations": $chargestations, "coordinates": $coordinates, "operatorName": $operator_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get an array of all Organizations
#
# GET /v1/organizations
# operationId: getOrganizations
export def "organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-locations: oneof<nothing, bool> # Populate locations
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_locations" $include_locations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/organizations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_locations": $include_locations} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get one organization's data by id
#
# GET /v1/organizations/{id}
# operationId: getOrganization
export def "organizations get" [
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
  --include-locations: oneof<nothing, bool> # Populate locations
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_locations" $include_locations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/organizations/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_locations": $include_locations} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an organization's data
#
# PATCH /v1/organizations/{id}
# operationId: patchOrganization
# --address shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
# --channels shape: {slack?: record, telegram?: record}
# --configurations shape: {basicAuthEnabled?: bool, basicAuthPassword?: bool}
# --links shape: {about?: string, contact?: string, privacy?: string, support?: string}
# --support shape: {business_hours?: string, chat?: record, contact_number?: string, email?: string}
# --supportChat shape: {id?: string, name?: string}
# --theme shape: {colors?: record}
export def "organizations update" [
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
  --active: oneof<nothing, bool>
  --address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --channels: record # shape: {slack?: record, telegram?: record}
  --configurations: record # shape: {basicAuthEnabled?: bool, basicAuthPassword?: bool}
  --links: record # shape: {about?: string, contact?: string, privacy?: string, support?: string}
  --locations: list
  --logo: string
  --name: string
  --otp: string
  --stripe-connected-account-id: string
  --stripe-country: string
  --stripe-currency: string
  --stripe-reserve-amount: int
  --support: record # shape: {business_hours?: string, chat?: record, contact_number?: string, email?: string}
  --support-chat: record # shape: {id?: string, name?: string}
  --theme: record # shape: {colors?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/organizations/{id}") $auth.query)
  let req_body = {"active": $active, "address": $address, "channels": $channels, "configurations": $configurations, "links": $links, "locations": $locations, "logo": $logo, "name": $name, "otp": $otp, "stripe_connected_account_id": $stripe_connected_account_id, "stripe_country": $stripe_country, "stripe_currency": $stripe_currency, "stripe_reserve_amount": $stripe_reserve_amount, "support": $support, "supportChat": $support_chat, "theme": $theme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use to request a Websockets handshake
#
# GET /v1/realtime
# operationId: getRealtime
export def "realtime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sec-websocket-protocol: string # The JWT token to use for auth
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/realtime" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"sec-websocket-protocol": $sec_websocket_protocol} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Get Reservations data
#
# GET /v1/reservations
# operationId: getReservations
export def "reservations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reservations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_chargestation": $include_chargestation, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get one reservation data
#
# GET /v1/reservations/{id}
# operationId: getReservation
export def "reservations get" [
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
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/reservations/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_chargestation": $include_chargestation, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use to request a update an existing reservation. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# PATCH /v1/reservations/{id}
# operationId: updatereservation
export def "reservations update" [
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
  --connector: int
  --driver: string
  --end-date: string
  --evse: int
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/reservations/{id}") $auth.query)
  let req_body = {"connector": $connector, "driver": $driver, "endDate": $end_date, "evse": $evse} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# List tokens
#
# GET /v1/tokens
# operationId: getTokens
export def "tokens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> record<message: string, ok: bool, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tokens" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_driver": $include_driver, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new token
#
# POST /v1/tokens
# operationId: postTokens
export def "tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  channel: string@channel-completer
  driver: string
  physical_id: string
  --type: string
]: any -> record<message: string, ok: bool, result: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tokens" $auth.query)
  let req_body = {"active": $active, "channel": $channel, "driver": $driver, "physicalId": $physical_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use to delete a token
#
# DELETE /v1/tokens/{id}
# operationId: deleteToken
export def "tokens delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/tokens/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a single token's data
#
# GET /v1/tokens/{id}
# operationId: getToken
export def "tokens get" [
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
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/tokens/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_driver": $include_driver, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a token
#
# PATCH /v1/tokens/{id}
# operationId: patchToken
export def "tokens update" [
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
  --active: oneof<nothing, bool> # default: true
  --channel: string@channel-completer
  --driver: string
  --physical-id: string
  --type: string
]: any -> record<message: string, ok: bool, result: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/tokens/{id}") $auth.query)
  let req_body = {"active": $active, "channel": $channel, "driver": $driver, "physicalId": $physical_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get a list of transactions
#
# GET /v1/transactions
# operationId: getTransactions
export def "transactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Started to get only active transactions
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-connector: oneof<nothing, bool> # Populate connector
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-reservation: oneof<nothing, bool> # Populate reservation
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> record<hasNext: bool, hasPrevious: bool, message: string, ok: bool, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_connector" $include_connector "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_token" $include_token "scalar") (serialize-qp "include_reservation" $include_reservation "scalar") (serialize-qp "include_organization" $include_organization "scalar") (serialize-qp "include_rate" $include_rate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/transactions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_chargestation": $include_chargestation, "include_evse": $include_evse, "include_connector": $include_connector, "include_driver": $include_driver, "include_token": $include_token, "include_reservation": $include_reservation, "include_organization": $include_organization, "include_rate": $include_rate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific transaction
#
# GET /v1/transactions/{id}
# operationId: getTransaction
export def "transactions get" [
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
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-connector: oneof<nothing, bool> # Populate connector
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-reservation: oneof<nothing, bool> # Populate reservation
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_connector" $include_connector "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_token" $include_token "scalar") (serialize-qp "include_reservation" $include_reservation "scalar") (serialize-qp "include_organization" $include_organization "scalar") (serialize-qp "include_rate" $include_rate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/transactions/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_chargestation": $include_chargestation, "include_evse": $include_evse, "include_connector": $include_connector, "include_driver": $include_driver, "include_token": $include_token, "include_reservation": $include_reservation, "include_organization": $include_organization, "include_rate": $include_rate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific transaction's cost
#
# GET /v1/transactions/{id}/cost
# operationId: getTransactionCost
export def "transactions-cost get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/transactions/{id}/cost") $auth.query)
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

# List all vehicles
#
# GET /v1/vehicles
# operationId: getVehicles
export def "vehicles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Get a list of active vehicles
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> record<message: string, ok: bool, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $created_at_gte "scalar") (serialize-qp "createdAt[$lte]" $created_at_lte "scalar") (serialize-qp "updatedAt[$gte]" $updated_at_gte "scalar") (serialize-qp "updatedAt[$lte]" $updated_at_lte "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_token" $include_token "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/vehicles" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"active": $active, "paginate_limit": $paginate_limit, "paginate_page": $paginate_page, "paginate_enabled": $paginate_enabled, "sort_by": $sort_by, "sort_order": $sort_order, "createdAt[$gte]": $created_at_gte, "createdAt[$lte]": $created_at_lte, "updatedAt[$gte]": $updated_at_gte, "updatedAt[$lte]": $updated_at_lte, "include_driver": $include_driver, "include_token": $include_token, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a vehicle's data
#
# GET /v1/vehicles/{id}
# operationId: getVehicle
export def "vehicles get" [
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
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_token" $include_token "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/vehicles/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_driver": $include_driver, "include_token": $include_token, "include_organization": $include_organization} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a vehicle's battery
#
# GET /v1/vehicles/{id}/battery
# operationId: getVehicleBattery
export def "vehicles-battery get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/vehicles/{id}/battery") $auth.query)
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

# Get a vehicle's charge
#
# GET /v1/vehicles/{id}/charge
# operationId: getVehicleCharge
export def "vehicles-charge get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/vehicles/{id}/charge") $auth.query)
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

# Change charge
#
# POST /v1/vehicles/{id}/charge
# operationId: postCharge
export def "vehicles-charge create" [
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
  action: string@action-completer
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/vehicles/{id}/charge") $auth.query)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a vehicle's location
#
# GET /v1/vehicles/{id}/location
# operationId: getVehicleLocation
export def "vehicles-location get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/vehicles/{id}/location") $auth.query)
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

# Get a vehicle's odometer
#
# GET /v1/vehicles/{id}/odometer
# operationId: getVehicleOdometer
export def "vehicles-odometer get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/vehicles/{id}/odometer") $auth.query)
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
