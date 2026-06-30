# Auto-generated client for ChannelShipper & Royal Mail Public API v1.0.0
# Source: https://api.apis.guru/v2/specs/royalmail.com/click-and-drop/1.0.0/swagger.json
# Auth: --token flag or $env.CHANNELSHIPPER_ROYAL_MAIL_PUBLIC_API_TOKEN

const BASE_URL = "https://localhost/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CHANNELSHIPPER_ROYAL_MAIL_PUBLIC_API_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://localhost/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def document-type-completer [] { ["CN22" "CN23" "despatchNote" "postageLabel"] }
def accept-completer [] { ["application/json" "application/pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "manifests create-async" } } | get name | first)
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

# Manifest orders
#
# POST /manifests
# operationId: CreateManifestsAsync
export def "manifests create-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-batch-numbers: list<string> # Cannot be mixed with other parameter types. (e.g. [B1111, B12345])
  --all-orders: oneof<nothing, bool> # Set to true and leave all the other parameters empty to manifest all orders in an eligible state up to and including the current day (orders with a future despatch date will not be included). Do not specify this parameter or alternatively set to false if specifying any other parameter options. (e.g. false)
  --end-date-time: string # Date and time in UTC. Used together with startDateTime to manifest all orders in an eligible state in a date/time range. If a startDateTime is specified without this parameter the end of the date/time range will be the latest possible order. Cannot be mixed with other parameter types. (format: date-time)
  --order-identifiers: list<int> # Can be specified together with orderReferences in the same call, but cannot be mixed with other parameter types
  --order-references: list<string> # Can be specified together with orderIdentifiers in the same call, but cannot be mixed with other parameter types
  --start-date-time: string # Date and time in UTC. Used together with endDateTime to manifest all orders in an eligible state in a date/time range. If an endDateTime is specified without this parameter the start of the date/time range will be the earliest possible order. Cannot be mixed with other parameter types. (format: date-time)
]: any -> record<manifests: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/manifests" $auth.query)
  let req_body = {"accountBatchNumbers": $account_batch_numbers, "allOrders": $all_orders, "endDateTime": $end_date_time, "orderIdentifiers": $order_identifiers, "orderReferences": $order_references, "startDateTime": $start_date_time} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve manifest status and documentation
#
# GET /manifests/{manifestGuid}
# operationId: GetManifestAsync
export def "manifests get-async" [
  manifest_guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<documentStatus: string, errorReference: string, manifestStatus: string, orders: table<orderIdentifier: int, orderReference: string>, pdf: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($manifest_guid | is-empty) { error make --unspanned { msg: "path parameter 'manifestGuid' must be non-empty" } }
  let full_url = (build-url $base ({manifest_guid: (encode-path-segment $manifest_guid)} | format pattern "/manifests/{manifest_guid}") $auth.query)
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

# Retry failed manifest
#
# POST /manifests/{manifestGuid}/retry
# operationId: RetryManifestAsync
export def "manifests-retry create-async" [
  manifest_guid: string
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
  if ($manifest_guid | is-empty) { error make --unspanned { msg: "path parameter 'manifestGuid' must be non-empty" } }
  let full_url = (build-url $base ({manifest_guid: (encode-path-segment $manifest_guid)} | format pattern "/manifests/{manifest_guid}/retry") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Retrieve pageable list of orders
#
# GET /orders
# operationId: GetOrdersAsync
export def "orders get-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The number of items to return (default: 25)
  --start-date-time: string # Date and time lower bound for items filtering (format: date-time)
  --end-date-time: string # Date and time upper bound for items filtering (format: date-time)
  --continuation-token: string # The token for retrieving the next page of items
]: nothing -> record<continuationToken: string, orders: table<createdOn: string, manifestedOn: string, orderDate: string, orderIdentifier: int, orderReference: string, printedOn: string, shippedOn: string, trackingNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "continuationToken" $continuation_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "startDateTime": $start_date_time, "endDateTime": $end_date_time, "continuationToken": $continuation_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create orders
#
# POST /orders
# operationId: CreateOrdersAsync
# --items item shape: {billing?: record, currencyCode?: string, customsDutyCosts?: float, label?: record, orderDate: string, orderReference?: string, otherCosts?: float, packages?: list, plannedDespatchDate?: string, postageDetails?: record, recipient: record, sender?: record, shippingCostCharged: float, specialInstructions?: string, subtotal: float, tags?: list, total: float}
export def "orders create-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  items: list # item shape: {billing?: record, currencyCode?: string, customsDutyCosts?: float, label?: record, orderDate: string, orderReference?: string, otherCosts?: float, packages?: list, plannedDespatchDate?: string, postageDetails?: record, recipient: record, sender?: record, shippingCostCharged: float, specialInstructions?: string, subtotal: float, tags?: list, total: float}
]: any -> record<createdOrders: table<createdOn: string, label: string, labelErrors: list, manifestedOn: string, orderDate: string, orderIdentifier: int, orderReference: string, printedOn: string, shippedOn: string, trackingNumber: string>, errorsCount: int, failedOrders: table<errors: list, order: record>, successCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders" $auth.query)
  let req_body = {"items": $items} | compact
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

# Retrieve pageable list of orders with details
#
# GET /orders/full
# operationId: GetOrdersWithDetailsAsync
export def "orders-full get-with-details-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The number of items to return (default: 25)
  --start-date-time: string # Date and time lower bound for items filtering (format: date-time)
  --end-date-time: string # Date and time upper bound for items filtering (format: date-time)
  --continuation-token: string # The token for retrieving the next page of items
]: nothing -> record<continuationToken: string, orders: table<AIRNumber: string, accountBatchNumber: string, billingInfo: record, channel: string, channelShippingMethod: string, commercialInvoiceDate: string, commercialInvoiceNumber: string, createdOn: string, currencyCode: string, department: string, despatchedByOtherCourierOn: string, manifestedOn: string, marketplaceTypeName: string, orderDate: string, orderDiscount: float, orderIdentifier: int, orderLines: list, orderReference: string, orderStatus: string, packageSize: string, pickerSpecialInstructions: string, postageAppliedOn: string, printedOn: string, requiresExportLicense: bool, shippedOn: string, shippingCostCharged: float, shippingDetails: record, shippingInfo: record, specialInstructions: string, subtotal: float, tags: list, total: float, tradingName: string, weightInGrams: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "continuationToken" $continuation_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/full" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "startDateTime": $start_date_time, "endDateTime": $end_date_time, "continuationToken": $continuation_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Set order status
#
# PUT /orders/status
# operationId: UpdateOrdersStatusAsync
# --items item shape: {despatchDate?: string, orderIdentifier?: int, orderReference?: string, shippingCarrier?: string, shippingService?: string, status?: "new"|"despatchedByOtherCourier"|"despatched", trackingNumber?: string}
export def "orders-status update-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --items: list # item shape: {despatchDate?: string, orderIdentifier?: int, orderReference?: string, shippingCarrier?: string, shippingService?: string, status?: "new"|"despatchedByOtherCourier"|"despatched", trackingNumber?: string}
]: any -> record<errors: table<code: string, message: string, orderIdentifier: int, orderReference: string, status: string>, updatedOrders: table<orderIdentifier: int, orderReference: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/status" $auth.query)
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Delete orders
#
# DELETE /orders/{orderIdentifiers}
# operationId: DeleteOrdersAsync
export def "orders delete-async" [
  order_identifiers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedOrders: table<orderIdentifier: int, orderInfo: string, orderReference: string>, errors: table<code: string, message: string, orderIdentifier: int, orderReference: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_identifiers | is-empty) { error make --unspanned { msg: "path parameter 'orderIdentifiers' must be non-empty" } }
  let full_url = (build-url $base ({order_identifiers: (encode-path-segment $order_identifiers)} | format pattern "/orders/{order_identifiers}") $auth.query)
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

# Retrieve specific orders
#
# GET /orders/{orderIdentifiers}
# operationId: GetSpecificOrdersAsync
export def "orders get-specific-async" [
  order_identifiers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdOn: string, manifestedOn: string, orderDate: string, orderIdentifier: int, orderReference: string, printedOn: string, shippedOn: string, trackingNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_identifiers | is-empty) { error make --unspanned { msg: "path parameter 'orderIdentifiers' must be non-empty" } }
  let full_url = (build-url $base ({order_identifiers: (encode-path-segment $order_identifiers)} | format pattern "/orders/{order_identifiers}") $auth.query)
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

# Retrieve details of the specific orders
#
# GET /orders/{orderIdentifiers}/full
# operationId: GetSpecificOrdersWithDetailsAsync
export def "orders-full get-specific-with-details-async" [
  order_identifiers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AIRNumber: string, accountBatchNumber: string, billingInfo: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, countryCode: string, county: string, emailAddress: string, firstName: string, lastName: string, phoneNumber: string, postcode: string, title: string>, channel: string, channelShippingMethod: string, commercialInvoiceDate: string, commercialInvoiceNumber: string, createdOn: string, currencyCode: string, department: string, despatchedByOtherCourierOn: string, manifestedOn: string, marketplaceTypeName: string, orderDate: string, orderDiscount: float, orderIdentifier: int, orderLines: list<record>, orderReference: string, orderStatus: string, packageSize: string, pickerSpecialInstructions: string, postageAppliedOn: string, printedOn: string, requiresExportLicense: bool, shippedOn: string, shippingCostCharged: float, shippingDetails: record<guaranteedSaturdayDelivery: bool, isLocalCollect: bool, receiveEmailNotification: bool, receiveSmsNotification: bool, requestSignatureUponDelivery: bool, serviceCode: string, shippingCarrier: string, shippingCost: float, shippingService: string, shippingTrackingStatus: string, trackingNumber: string>, shippingInfo: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, countryCode: string, county: string, emailAddress: string, firstName: string, lastName: string, phoneNumber: string, postcode: string, title: string>, specialInstructions: string, subtotal: float, tags: list<record>, total: float, tradingName: string, weightInGrams: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_identifiers | is-empty) { error make --unspanned { msg: "path parameter 'orderIdentifiers' must be non-empty" } }
  let full_url = (build-url $base ({order_identifiers: (encode-path-segment $order_identifiers)} | format pattern "/orders/{order_identifiers}/full") $auth.query)
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

# Return a single PDF file with generated label and/or associated document(s)
#
# GET /orders/{orderIdentifiers}/label
# operationId: GetOrdersLabelAsync
export def "orders-label get-async" [
  order_identifiers: string
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
  --document-type: string@document-type-completer # Document generation mode. When documentType is set to "postageLabel" the additional parameters below must be used. These additional parameters will be ignored when documentType is not set to "postageLabel"
  --include-returns-label: oneof<nothing, bool> # Include returns label. Required when documentType is set to 'postageLabel'
  --include-cn: oneof<nothing, bool> # Include CN22/CN23 with label. Optional parameter. If this parameter is used the setting will override the default account behaviour specified in the "Label format" setting "Generate customs declarations with orders"
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_identifiers | is-empty) { error make --unspanned { msg: "path parameter 'orderIdentifiers' must be non-empty" } }
  let qp = [(serialize-qp "documentType" $document_type "scalar") (serialize-qp "includeReturnsLabel" $include_returns_label "scalar") (serialize-qp "includeCN" $include_cn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_identifiers: (encode-path-segment $order_identifiers)} | format pattern "/orders/{order_identifiers}/label") $qp $auth.query)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"documentType": $document_type, "includeReturnsLabel": $include_returns_label, "includeCN": $include_cn} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get API version details.
#
# GET /version
# operationId: GetVersionAsync
export def "version get-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<build: string, commit: string, release: string, releaseDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version" $auth.query)
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
