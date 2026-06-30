# Auto-generated client for Azure Reservation v2019-04-01
# Source: https://api.apis.guru/v2/specs/azure.com/reservations/2019-04-01/swagger.json
# Auth: --token flag or $env.AZURE_RESERVATION_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AZURE_RESERVATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-capacity-calculate-price create-reservation-order" } } | get name | first)
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

# Calculate price for a `ReservationOrder`.
#
# POST /providers/Microsoft.Capacity/calculatePrice
# operationId: ReservationOrder_Calculate
# --properties shape: {appliedScopeType?: "Single"|"Shared", appliedScopes?: list<string>, billingPlan?: "Upfront"|"Monthly", billingScopeId?: string, displayName?: string, quantity?: int, renew?: bool, reservedResourceProperties?: record, reservedResourceType?: "VirtualMachines"|"SqlDatabases"|"SuseLinux"|"CosmosDb"|"RedHat"|"SqlDataWarehouse"|"VMwareCloudSimple"|"RedHatOsa", term?: "P1Y"|"P3Y"}
# --sku shape: {name?: string}
export def "providers-microsoft-capacity-calculate-price create-reservation-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --location: string # The Azure Region where the reserved resource lives.
  --properties: record # shape: {appliedScopeType?: "Single"|"Shared", appliedScopes?: list<string>, billingPlan?: "Upfront"|"Monthly", billingScopeId?: string, displayName?: string, quantity?: int, renew?: bool, reservedResourceProperties?: record, reservedResourceType?: "VirtualMachines"|"SqlDatabases"|"SuseLinux"|"CosmosDb"|"RedHat"|"SqlDataWarehouse"|"VMwareCloudSimple"|"RedHatOsa", term?: "P1Y"|"P3Y"}
  --sku: record # shape: {name?: string}
]: any -> record<properties: record<billingCurrencyTotal: record<amount: float, currencyCode: string>, isBillingPartnerManaged: bool, paymentSchedule: list<record>, pricingCurrencyTotal: record<amount: float, currencyCode: string>, reservationOrderId: string, skuDescription: string, skuTitle: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Capacity/calculatePrice" $qp $auth.query)
  let req_body = {"location": $location, "properties": $properties, "sku": $sku} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get operations.
#
# GET /providers/Microsoft.Capacity/operations
# operationId: Operation_List
export def "providers-microsoft-capacity-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Capacity/operations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all `ReservationOrder`s.
#
# GET /providers/Microsoft.Capacity/reservationOrders
# operationId: ReservationOrder_List
export def "providers-microsoft-capacity-reservation-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<nextLink: string, value: table<etag: int, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Capacity/reservationOrders" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific `ReservationOrder`.
#
# GET /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}
# operationId: ReservationOrder_Get
export def "providers-microsoft-capacity-reservation-orders get" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --expand: string # May be used to expand the planInformation.
]: nothing -> record<etag: int, id: string, name: string, properties: record<billingPlan: string, createdDateTime: string, displayName: string, expiryDate: string, originalQuantity: int, planInformation: record<nextPaymentDueDate: string, pricingCurrencyTotal: record, startDate: string, transactions: list>, provisioningState: string, requestDateTime: string, reservations: list<record>, term: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Purchase `ReservationOrder`
#
# PUT /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}
# operationId: ReservationOrder_Purchase
# --properties shape: {appliedScopeType?: "Single"|"Shared", appliedScopes?: list<string>, billingPlan?: "Upfront"|"Monthly", billingScopeId?: string, displayName?: string, quantity?: int, renew?: bool, reservedResourceProperties?: record, reservedResourceType?: "VirtualMachines"|"SqlDatabases"|"SuseLinux"|"CosmosDb"|"RedHat"|"SqlDataWarehouse"|"VMwareCloudSimple"|"RedHatOsa", term?: "P1Y"|"P3Y"}
# --sku shape: {name?: string}
export def "providers-microsoft-capacity-reservation-orders update-purchase" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --location: string # The Azure Region where the reserved resource lives.
  --properties: record # shape: {appliedScopeType?: "Single"|"Shared", appliedScopes?: list<string>, billingPlan?: "Upfront"|"Monthly", billingScopeId?: string, displayName?: string, quantity?: int, renew?: bool, reservedResourceProperties?: record, reservedResourceType?: "VirtualMachines"|"SqlDatabases"|"SuseLinux"|"CosmosDb"|"RedHat"|"SqlDataWarehouse"|"VMwareCloudSimple"|"RedHatOsa", term?: "P1Y"|"P3Y"}
  --sku: record # shape: {name?: string}
]: any -> record<etag: int, id: string, name: string, properties: record<billingPlan: string, createdDateTime: string, displayName: string, expiryDate: string, originalQuantity: int, planInformation: record<nextPaymentDueDate: string, pricingCurrencyTotal: record, startDate: string, transactions: list>, provisioningState: string, requestDateTime: string, reservations: list<record>, term: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}") $qp $auth.query)
  let req_body = {"location": $location, "properties": $properties, "sku": $sku} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Merges two `Reservation`s.
#
# POST /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/merge
# operationId: Reservation_Merge
# --properties shape: {sources?: list<string>}
export def "providers-microsoft-capacity-reservation-orders-merge create" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --properties: record # shape: {sources?: list<string>}
]: any -> table<etag: int, id: string, location: string, name: string, properties: record<appliedScopeType: string, appliedScopes: list, billingPlan: string, billingScopeId: string, displayName: string, effectiveDateTime: string, expiryDate: string, extendedStatusInfo: record, instanceFlexibility: string, lastUpdatedDateTime: string, mergeProperties: record, provisioningState: string, quantity: int, renew: bool, renewDestination: string, renewProperties: record, renewSource: string, reservedResourceType: string, skuDescription: string, splitProperties: record, term: string>, sku: record<name: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/merge") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Get `Reservation`s in a given reservation Order
#
# GET /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations
# operationId: Reservation_List
export def "providers-microsoft-capacity-reservation-orders-reservations list" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<nextLink: string, value: table<etag: int, id: string, location: string, name: string, properties: record, sku: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get `Reservation` details.
#
# GET /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations/{reservationId}
# operationId: Reservation_Get
export def "providers-microsoft-capacity-reservation-orders-reservations get" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --expand: string # Supported value of this query is renewProperties
]: nothing -> record<etag: int, id: string, location: string, name: string, properties: record<appliedScopeType: string, appliedScopes: list<string>, billingPlan: string, billingScopeId: string, displayName: string, effectiveDateTime: string, expiryDate: string, extendedStatusInfo: record<message: string, statusCode: string>, instanceFlexibility: string, lastUpdatedDateTime: string, mergeProperties: record<mergeDestination: string, mergeSources: list>, provisioningState: string, quantity: int, renew: bool, renewDestination: string, renewProperties: record<billingCurrencyTotal: record, pricingCurrencyTotal: record, purchaseProperties: record>, renewSource: string, reservedResourceType: string, skuDescription: string, splitProperties: record<splitDestinations: list, splitSource: string>, term: string>, sku: record<name: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations/{reservation_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a `Reservation`.
#
# PATCH /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations/{reservationId}
# operationId: Reservation_Update
# --properties shape: {appliedScopeType?: "Single"|"Shared", appliedScopes?: list<string>, instanceFlexibility?: "On"|"Off", name?: string, renew?: bool, renewProperties?: record}
export def "providers-microsoft-capacity-reservation-orders-reservations update" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --properties: record # shape: {appliedScopeType?: "Single"|"Shared", appliedScopes?: list<string>, instanceFlexibility?: "On"|"Off", name?: string, renew?: bool, renewProperties?: record}
]: any -> record<etag: int, id: string, location: string, name: string, properties: record<appliedScopeType: string, appliedScopes: list<string>, billingPlan: string, billingScopeId: string, displayName: string, effectiveDateTime: string, expiryDate: string, extendedStatusInfo: record<message: string, statusCode: string>, instanceFlexibility: string, lastUpdatedDateTime: string, mergeProperties: record<mergeDestination: string, mergeSources: list>, provisioningState: string, quantity: int, renew: bool, renewDestination: string, renewProperties: record<billingCurrencyTotal: record, pricingCurrencyTotal: record, purchaseProperties: record>, renewSource: string, reservedResourceType: string, skuDescription: string, splitProperties: record<splitDestinations: list, splitSource: string>, term: string>, sku: record<name: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations/{reservation_id}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Get Available Scopes for `Reservation`.
#
# POST /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations/{reservationId}/availableScopes
# operationId: Reservation_AvailableScopes
export def "providers-microsoft-capacity-reservation-orders-reservations-available-scopes create" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --body: list
]: any -> record<properties: record<scopes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations/{reservation_id}/availableScopes") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get `Reservation` revisions.
#
# GET /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations/{reservationId}/revisions
# operationId: Reservation_ListRevisions
export def "providers-microsoft-capacity-reservation-orders-reservations-revisions list" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<nextLink: string, value: table<etag: int, id: string, location: string, name: string, properties: record, sku: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations/{reservation_id}/revisions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Split the `Reservation`.
#
# POST /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/split
# operationId: Reservation_Split
# --properties shape: {quantities?: list<int>, reservationId?: string}
export def "providers-microsoft-capacity-reservation-orders-split create" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --properties: record # shape: {quantities?: list<int>, reservationId?: string}
]: any -> table<etag: int, id: string, location: string, name: string, properties: record<appliedScopeType: string, appliedScopes: list, billingPlan: string, billingScopeId: string, displayName: string, effectiveDateTime: string, expiryDate: string, extendedStatusInfo: record, instanceFlexibility: string, lastUpdatedDateTime: string, mergeProperties: record, provisioningState: string, quantity: int, renew: bool, renewDestination: string, renewProperties: record, renewSource: string, reservedResourceType: string, skuDescription: string, splitProperties: record, term: string>, sku: record<name: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_order_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationOrderId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/split") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Get list of applicable `Reservation`s.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Capacity/appliedReservations
# operationId: GetAppliedReservationList
export def "subscriptions-providers-microsoft-capacity-applied-reservations get-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<id: string, name: string, properties: record<reservationOrderIds: record<nextLink: string, value: list>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Capacity/appliedReservations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the regions and skus that are available for RI purchase for the specified Azure subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Capacity/catalogs
# operationId: GetCatalog
export def "subscriptions-providers-microsoft-capacity-catalogs get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --reserved-resource-type: string # The type of the resource for which the skus should be provided.
  --location: string # Filters the skus based on the location specified in this parameter. This can be an azure region or global
]: nothing -> table<billingPlans: record, locations: list<string>, name: string, resourceType: string, restrictions: list<record>, skuProperties: list<record>, terms: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "reservedResourceType" $reserved_resource_type "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Capacity/catalogs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "reservedResourceType": $reserved_resource_type, "location": $location} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
