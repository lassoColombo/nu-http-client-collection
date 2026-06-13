# Auto-generated client for eDRV API vv1
# Source: https://api.apis.guru/v2/specs/edrv.io/v1/openapi.json
# Auth: --token flag or $env.EDRV_API_TOKEN

const BASE_URL = "http://localhost//api.edrv.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EDRV_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "chargestations list" } } | get name | first)
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
export def "chargestations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-location: oneof<nothing, bool> # Populate location
  --include-evses: oneof<nothing, bool> # Populate evses
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization" $organization "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "online" $online "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "public" $public "scalar") (serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_location" $include_location "scalar") (serialize-qp "include_evses" $include_evses "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/chargestations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new charge station
#
# POST /v1/chargestations
# operationId: postChargeStations
export def "chargestations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base "/v1/chargestations")
  let body = {location: $location, manufacturer: $manufacturer, model: $model, protocol: $protocol, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use to delete a charge station
#
# DELETE /v1/chargestations/{id}
# operationId: deleteChargeStation
export def "chargestations delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/chargestations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single charge station's data
#
# GET /v1/chargestations/{id}
# operationId: getChargeStation
export def "chargestations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-location: oneof<nothing, bool> # Populate location
  --include-evses: oneof<nothing, bool> # Populate evses
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_location" $include_location "scalar") (serialize-qp "include_evses" $include_evses "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/chargestations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a charge station's data
#
# PATCH /v1/chargestations/{id}
# operationId: patchChargeStation
export def "chargestations patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base $"/v1/chargestations/($id)")
  let body = {location: $location, manufacturer: $manufacturer, model: $model, protocol: $protocol, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List connectors for a chargestation
#
# GET /v1/chargestations/{id}/connectors
# operationId: getChargeStationConnectors
export def "chargestations-connectors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/chargestations/($id)/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-transaction: oneof<nothing, bool> # Populate transaction
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_transaction" $include_transaction "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/commands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use to request a delete an existing reservation. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/cancelreservation
# operationId: cancelreservation
export def "commands-cancelreservation cancelreservation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/cancelreservation")
  let body = {reservation: $reservation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a smart charging schedule
#
# DELETE /v1/commands/chargingschedule
# operationId: deletechargingschedule
export def "commands-chargingschedule deletechargingschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/chargingschedule")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set one of charging power or current of a specific chargestation connector
#
# POST /v1/commands/chargingschedule
# operationId: setchargingschedule
# --schedule item shape: {endDate?: string, limit?: float, startDate?: string, unit?: string}
export def "commands-chargingschedule setchargingschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --connector: string
  --schedule: list # item shape: {endDate?: string, limit?: float, startDate?: string, unit?: string}
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/chargingschedule")
  let body = {connector: $connector, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use to request a remote start command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/remotestart
# operationId: remotestart
export def "commands-remotestart remotestart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
  --driver: string
  --body-token: string
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/remotestart")
  let body = {chargestation: $chargestation, connector: $connector, driver: $driver, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use to request a remote stop command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/remotestop
# operationId: remotestop
export def "commands-remotestop remotestop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --driver: string
  --transaction: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/remotestop")
  let body = {chargestation: $chargestation, driver: $driver, transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use to request a reserve command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/reserve
# operationId: reserve
export def "commands-reserve reserve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
  --driver: string
  --endDate: string
  --body-token: string
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/reserve")
  let body = {chargestation: $chargestation, connector: $connector, driver: $driver, endDate: $endDate, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --type: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/reset")
  let body = {chargestation: $chargestation, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use to request an unlock command for a connector. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/unlockconnector
# operationId: unlockconnector
export def "commands-unlockconnector unlockconnector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
]: any -> record<command: record, message: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/unlockconnector")
  let body = {chargestation: $chargestation, connector: $connector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/commands/($id)/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update config variables for a chargestation
#
# PATCH /v1/commands/{id}/variables
# operationId: patchChargeStationVariable
export def "commands-variables patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
  --variable: string@variable-completer
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/commands/($id)/variables")
  let body = {value: $value, variable: $variable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create connector with parameters
#
# POST /v1/configurations
# operationId: postConfigurations
export def "configurations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --value: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/configurations")
  let body = {key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configurations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_organization" $include_organization "scalar") (serialize-qp "include_rate" $include_rate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new connector
#
# POST /v1/connectors
# operationId: postConnectors
export def "connectors post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base "/v1/connectors")
  let body = {chargestation: $chargestation, format: $format, power: $power, power_type: $power_type, rate: $rate, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_organization" $include_organization "scalar") (serialize-qp "include_rate" $include_rate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a connector's data
#
# PATCH /v1/connectors/{id}
# operationId: patchConnector
export def "connectors patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base $"/v1/connectors/($id)")
  let body = {chargestation: $chargestation, format: $format, power: $power, power_type: $power_type, rate: $rate, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Get a list of active drivers
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-tokens: oneof<nothing, bool> # Populate tokens
  --include-group: oneof<nothing, bool> # Populate group
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> record<message: string, ok: bool, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_tokens" $include_tokens "scalar") (serialize-qp "include_group" $include_group "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/drivers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new driver
#
# POST /v1/drivers
# operationId: postDrivers
# --address shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
# --phone shape: {home?: string, mobile?: string, work?: string}
export def "drivers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base "/v1/drivers")
  let body = {active: $active, address: $address, email: $email, firstname: $firstname, lastname: $lastname, phone: $phone, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/drivers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-tokens: oneof<nothing, bool> # Populate tokens
  --include-group: oneof<nothing, bool> # Populate group
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_tokens" $include_tokens "scalar") (serialize-qp "include_group" $include_group "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/drivers/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a driver's data
#
# PATCH /v1/drivers/{id}
# operationId: patchDriver
# --address shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
# --phone shape: {home?: string, mobile?: string, work?: string}
export def "drivers patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base $"/v1/drivers/($id)")
  let body = {active: $active, address: $address, email: $email, firstname: $firstname, lastname: $lastname, phone: $phone, source: $body_source, tokens: $tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/location/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-chargestations: oneof<nothing, bool> # Populate chargestations
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_chargestations" $include_chargestations "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/location/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a location's data
#
# PATCH /v1/location/{id}
# operationId: patchLocation
# --address shape: {city?: string, country?: string, postalCode?: string, state?: string, streetAndNumber?: string}
# --coordinates shape: {latitude?: float, longitude?: float}
# --openingHours shape: {0?: list, 1?: list, 2?: list, 3?: list, 4?: list, 5?: list, 6?: list}
export def "location patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  --address: record # shape: {city?: string, country?: string, postalCode?: string, state?: string, streetAndNumber?: string}
  --chargestations: list
  --coordinates: record # shape: {latitude?: float, longitude?: float}
  --openingHours: record # shape: {0?: list, 1?: list, 2?: list, 3?: list, 4?: list, 5?: list, 6?: list}
  --operatorName: string
  --timezone: string
]: any -> record<message: string, ok: bool, result: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/location/($id)")
  let body = {active: $active, address: $address, chargestations: $chargestations, coordinates: $coordinates, openingHours: $openingHours, operatorName: $operatorName, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new location
#
# POST /v1/locations
# operationId: postLocations
# --address shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
# --coordinates shape: {latitude?: float, longitude?: float}
export def "locations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --chargestations: list
  coordinates: record # shape: {latitude?: float, longitude?: float}
  operatorName: string
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/locations")
  let body = {active: $active, address: $address, chargestations: $chargestations, coordinates: $coordinates, operatorName: $operatorName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-locations: oneof<nothing, bool> # Populate locations
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_locations" $include_locations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-locations: oneof<nothing, bool> # Populate locations
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_locations" $include_locations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/organizations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
export def "organizations patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --supportChat: record # shape: {id?: string, name?: string}
  --theme: record # shape: {colors?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($id)")
  let body = {active: $active, address: $address, channels: $channels, configurations: $configurations, links: $links, locations: $locations, logo: $logo, name: $name, otp: $otp, stripe_connected_account_id: $stripe_connected_account_id, stripe_country: $stripe_country, stripe_currency: $stripe_currency, stripe_reserve_amount: $stripe_reserve_amount, support: $support, supportChat: $supportChat, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --sec-websocket-protocol: string # The JWT token to use for auth
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/realtime")
  let extra_headers = {"sec-websocket-protocol": $sec_websocket_protocol} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reservations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/reservations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use to request a update an existing reservation. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# PATCH /v1/reservations/{id}
# operationId: updatereservation
export def "reservations updatereservation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --connector: int
  --driver: string
  --endDate: string
  --evse: int
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/reservations/($id)")
  let body = {connector: $connector, driver: $driver, endDate: $endDate, evse: $evse} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> record<message: string, ok: bool, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new token
#
# POST /v1/tokens
# operationId: postTokens
export def "tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  channel: string@channel-completer
  driver: string
  physicalId: string
  --type: string
]: any -> record<message: string, ok: bool, result: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tokens")
  let body = {active: $active, channel: $channel, driver: $driver, physicalId: $physicalId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tokens/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a token
#
# PATCH /v1/tokens/{id}
# operationId: patchToken
export def "tokens patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  --channel: string@channel-completer
  --driver: string
  --physicalId: string
  --type: string
]: any -> record<message: string, ok: bool, result: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tokens/($id)")
  let body = {active: $active, channel: $channel, driver: $driver, physicalId: $physicalId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Started to get only active transactions
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
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
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_connector" $include_connector "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_token" $include_token "scalar") (serialize-qp "include_reservation" $include_reservation "scalar") (serialize-qp "include_organization" $include_organization "scalar") (serialize-qp "include_rate" $include_rate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let qp = [(serialize-qp "include_chargestation" $include_chargestation "scalar") (serialize-qp "include_evse" $include_evse "scalar") (serialize-qp "include_connector" $include_connector "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_token" $include_token "scalar") (serialize-qp "include_reservation" $include_reservation "scalar") (serialize-qp "include_organization" $include_organization "scalar") (serialize-qp "include_rate" $include_rate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/transactions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/transactions/($id)/cost")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Get a list of active vehicles
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --createdAtgte: string # Date as ISO String (format: date-time)
  --createdAtlte: string # Date as ISO String (format: date-time)
  --updatedAtgte: string # Date as ISO String (format: date-time)
  --updatedAtlte: string # Date as ISO String (format: date-time)
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> record<message: string, ok: bool, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "paginate_limit" $paginate_limit "scalar") (serialize-qp "paginate_page" $paginate_page "scalar") (serialize-qp "paginate_enabled" $paginate_enabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "createdAt[$gte]" $createdAtgte "scalar") (serialize-qp "createdAt[$lte]" $createdAtlte "scalar") (serialize-qp "updatedAt[$gte]" $updatedAtgte "scalar") (serialize-qp "updatedAt[$lte]" $updatedAtlte "scalar") (serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_token" $include_token "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/vehicles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_driver" $include_driver "scalar") (serialize-qp "include_token" $include_token "scalar") (serialize-qp "include_organization" $include_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/vehicles/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vehicles/($id)/battery")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vehicles/($id)/charge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change charge
#
# POST /v1/vehicles/{id}/charge
# operationId: postCharge
export def "vehicles-charge post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string@action-completer
]: any -> record<message: string, ok: bool, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vehicles/($id)/charge")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vehicles/($id)/location")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vehicles/($id)/odometer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
