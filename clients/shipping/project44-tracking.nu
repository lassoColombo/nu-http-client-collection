# Auto-generated client for project44 Tracking API v2.0.0
# Source: https://raw.githubusercontent.com/api-evangelist/project44/main/openapi/project44-tracking-openapi.yml
# Auth: --token flag or $env.PROJECT44_TRACKING_API_TOKEN

const BASE_URL = "https://api.project44.com/api/v4"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PROJECT44_TRACKING_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.project44.com/api/v4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def mode-completer [] { ["AIR" "DRAY" "LTL" "OCEAN" "PARCEL" "RAIL" "TL"] }
def status-completer [] { ["AT_STOP" "COMPLETED" "EXCEPTION" "IN_TRANSIT" "UNKNOWN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "shipments createShipment" } } | get name | first)
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

# Create a tracked shipment
#
# POST /shipments
# operationId: createShipment
# --identifiers item shape: {type: "PRO"|"BOL"|"PO"|"TRACKING_NUMBER"|"CONTAINER_NUMBER"|"BOOKING_NUMBER", value: string}
# --stops item shape: {stopNumber: int, stopType: "ORIGIN"|"DESTINATION"|"INTERMEDIATE", city?: string, state?: string, postalCode?: string, country?: string, appointmentWindow?: record}
export def "shipments createShipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mode: string@mode-completer
  carrierCode: string # SCAC code
  identifiers: list # At least one tracking identifier required — item shape: {type: "PRO"|"BOL"|"PO"|"TRACKING_NUMBER"|"CONTAINER_NUMBER"|"BOOKING_NUMBER", value: string}
  --stops: list # item shape: {stopNumber: int, stopType: "ORIGIN"|"DESTINATION"|"INTERMEDIATE", city?: string, state?: string, postalCode?: string, country?: string, appointmentWindow?: record}
]: any -> record<id: string, masterShipmentId: string, mode: string, status: string, carrierCode: string, carrierName: string, proNumber: string, bolNumber: string, poNumber: string, origin: record<stopNumber: int, stopType: string, name: string, address: string, city: string, state: string, postalCode: string, country: string, latitude: float, longitude: float, appointmentWindow: record<startDateTime: string, endDateTime: string>, actualArrival: string, actualDeparture: string>, destination: record<stopNumber: int, stopType: string, name: string, address: string, city: string, state: string, postalCode: string, country: string, latitude: float, longitude: float, appointmentWindow: record<startDateTime: string, endDateTime: string>, actualArrival: string, actualDeparture: string>, estimatedDelivery: record<estimatedAt: string, confidenceLow: string, confidenceHigh: string, predictedOnTime: bool, predictedLateMinutes: int>, currentPosition: record<timestamp: string, latitude: float, longitude: float, heading: float, speed: float, speedUnit: string>, exceptions: table<exceptionCode: string, description: string, severity: string, timestamp: string, resolvedAt: string>, createDatetime: string, lastUpdateDatetime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipments")
  let body = {mode: $mode, carrierCode: $carrierCode, identifiers: $identifiers, stops: $stops} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List tracked shipments
#
# GET /shipments
# operationId: listShipments
export def "shipments listShipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Filter by shipment lifecycle status
  --mode: string@mode-completer # Transportation mode filter
  --carrierId: string # Carrier SCAC code or project44 carrier ID
  --updatedSince: string # Return shipments updated after this ISO 8601 timestamp (format: date-time)
  --page: int # default: 0
  --pageSize: int # default: 50
]: nothing -> record<shipments: table<id: string, masterShipmentId: string, mode: string, status: string, carrierCode: string, carrierName: string, proNumber: string, bolNumber: string, poNumber: string, origin: record, destination: record, estimatedDelivery: record, currentPosition: record, exceptions: list, createDatetime: string, lastUpdateDatetime: string>, pageInfo: record<page: int, pageSize: int, totalCount: int, hasNextPage: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "carrierId" $carrierId "scalar") (serialize-qp "updatedSince" $updatedSince "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a shipment
#
# GET /shipments/{shipmentId}
# operationId: getShipment
export def "shipments get" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, masterShipmentId: string, mode: string, status: string, carrierCode: string, carrierName: string, proNumber: string, bolNumber: string, poNumber: string, origin: record<stopNumber: int, stopType: string, name: string, address: string, city: string, state: string, postalCode: string, country: string, latitude: float, longitude: float, appointmentWindow: record<startDateTime: string, endDateTime: string>, actualArrival: string, actualDeparture: string>, destination: record<stopNumber: int, stopType: string, name: string, address: string, city: string, state: string, postalCode: string, country: string, latitude: float, longitude: float, appointmentWindow: record<startDateTime: string, endDateTime: string>, actualArrival: string, actualDeparture: string>, estimatedDelivery: record<estimatedAt: string, confidenceLow: string, confidenceHigh: string, predictedOnTime: bool, predictedLateMinutes: int>, currentPosition: record<timestamp: string, latitude: float, longitude: float, heading: float, speed: float, speedUnit: string>, exceptions: table<exceptionCode: string, description: string, severity: string, timestamp: string, resolvedAt: string>, createDatetime: string, lastUpdateDatetime: string, stops: table<stopNumber: int, stopType: string, name: string, address: string, city: string, state: string, postalCode: string, country: string, latitude: float, longitude: float, appointmentWindow: record, actualArrival: string, actualDeparture: string>, statusUpdates: table<updateId: string, timestamp: string, statusCode: string, statusDescription: string, city: string, state: string, country: string, isException: bool, exceptionCode: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipments/($shipmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop tracking a shipment
#
# DELETE /shipments/{shipmentId}
# operationId: deleteShipment
export def "shipments delete" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipments/($shipmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shipment status updates
#
# GET /shipments/{shipmentId}/status-updates
# operationId: getShipmentStatusUpdates
export def "shipments-status-updates get" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 50
]: nothing -> record<statusUpdates: table<updateId: string, timestamp: string, statusCode: string, statusDescription: string, city: string, state: string, country: string, isException: bool, exceptionCode: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shipments/($shipmentId)/status-updates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shipment position history
#
# GET /shipments/{shipmentId}/positions
# operationId: getShipmentPositions
export def "shipments-positions get" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # format: date-time
  --endTime: string # format: date-time
  --limit: int # default: 100
]: nothing -> record<positions: table<timestamp: string, latitude: float, longitude: float, heading: float, speed: float, speedUnit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shipments/($shipmentId)/positions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhook subscriptions
#
# GET /webhooks/subscriptions
# operationId: listWebhookSubscriptions
export def "webhooks-subscriptions listWebhookSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<subscriptions: table<id: string, callbackUrl: string, eventTypes: list, status: string, createDatetime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create webhook subscription
#
# POST /webhooks/subscriptions
# operationId: createWebhookSubscription
export def "webhooks-subscriptions createWebhookSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  callbackUrl: string # HTTPS URL to receive event notifications (format: uri)
  eventTypes: list # Event types to subscribe to
  --secret: string # HMAC secret for webhook signature verification
]: any -> record<id: string, callbackUrl: string, eventTypes: list<string>, status: string, createDatetime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/subscriptions")
  let body = {callbackUrl: $callbackUrl, eventTypes: $eventTypes, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete webhook subscription
#
# DELETE /webhooks/subscriptions/{subscriptionId}
# operationId: deleteWebhookSubscription
export def "webhooks-subscriptions delete" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/subscriptions/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
