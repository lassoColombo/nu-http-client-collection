# Auto-generated client for BrandLovers Marketplace API V1 v1.0.0
# Source: https://api.apis.guru/v2/specs/brandlovers.com/1.0.0/swagger.json
# Auth: --token flag or $env.BRANDLOVERS_MARKETPLACE_API_V1_TOKEN

const BASE_URL = "https://api.brandlovers.com/marketplace/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BRANDLOVERS_MARKETPLACE_API_V1_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.brandlovers.com/marketplace/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["APPROVED" "DECLINED" "NEW" "PENDING"] }
def status-completer-1 [] { ["CLOSED" "OPEN" "REOPENED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "order get" } } | get name | first)
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

# Returns all details of a order
#
# GET /order/{orderId}
export def "order get" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<approvedAt: string, billingAddress: record<address: string, city: string, complement: string, countryId: string, neighbourhood: string, number: string, recipientName: string, reference: string, state: string, zipCode: string>, createdAt: string, customer: record<documentNumber: string, email: string, id: string, name: string, phones: list<record>, type: string>, freight: record<ETA: string, additionalInfo: string, chargedAmount: int, crossDockingTime: int, defaultAmount: int, scheduledPeriod: string, transitTime: int, type: string>, items: table<freight: record, giftWrap: record, id: string, name: string, promotions: list, salePrice: int, sent: bool, skuSellerId: string>, orderId: string, orderMarketplaceId: string, seller: record<id: string, name: string>, shipments: table<courier: record, cte: string, description: string, id: string, invoice: record, items: list, number: string, occurredAt: string, sellerShipmentId: string, status: string, trackingUrl: string>, shippingAddress: record<address: string, city: string, complement: string, countryId: string, neighbourhood: string, number: string, recipientName: string, reference: string, state: string, zipCode: string>, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Confirm shipment canceletion (when requested by the customer) or failure to deliver
#
# POST /order/{orderId}/shipment/cancel
# --courier shape: {name: string, taxID?: string}
# --items item shape: {quantity: int, skuSellerId: string}
export def "order-shipment-cancel create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  info: string # Aditional information about this shippment
  items: list # item shape: {quantity: int, skuSellerId: string}
  --number: string # Tracking Id in the courier
  --occurred-at: string # Date time that this was created (format: date-time)
  --seller-shipment-id: string # Unique Seller shipment Id. This must be unique across all orders and shipments
  --trancking-url: string # Courier tracking URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}/shipment/cancel") $auth.query)
  let req_body = {"courier": $courier, "cte": $cte, "info": $info, "items": $items, "number": $number, "occurredAt": $occurred_at, "sellerShipmentId": $seller_shipment_id, "tranckingUrl": $trancking_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Confirms that a shipment was delivered
#
# POST /order/{orderId}/shipment/delivered
# --courier shape: {name: string, taxID?: string}
# --invoice shape: {accessKey: string, cnpj?: string, issuedAt?: string, linkDanfe?: string, linkXml?: string, number: string, serie: string}
export def "order-shipment-delivered create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  invoice: any # shape: {accessKey: string, cnpj?: string, issuedAt?: string, linkDanfe?: string, linkXml?: string, number: string, serie: string}
  items: list<string> # List of Order IDs of this items from this order that will be updated in this shipment
  --number: string # Unique id shipment Id in the courier system
  occurred_at: string # Data da ocorrência (format: date-time)
  seller_shipment_id: string # Unique Seller shipment Id. This must be unique across all orders and shipmnents
  --tracking-url: string # Courier tracking URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}/shipment/delivered") $auth.query)
  let req_body = {"courier": $courier, "cte": $cte, "invoice": $invoice, "items": $items, "number": $number, "occurredAt": $occurred_at, "sellerShipmentId": $seller_shipment_id, "trackingUrl": $tracking_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Confirm item exchange
#
# POST /order/{orderId}/shipment/exchange
# --courier shape: {name: string, taxID?: string}
# --items item shape: {quantity: int, skuSellerId: string}
export def "order-shipment-exchange create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  info: string # Aditional information about this shippment
  items: list # item shape: {quantity: int, skuSellerId: string}
  --number: string # Tracking Id in the courier
  --occurred-at: string # Date time that this was created (format: date-time)
  --seller-shipment-id: string # Unique Seller shipment Id. This must be unique across all orders and shipments
  --trancking-url: string # Courier tracking URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}/shipment/exchange") $auth.query)
  let req_body = {"courier": $courier, "cte": $cte, "info": $info, "items": $items, "number": $number, "occurredAt": $occurred_at, "sellerShipmentId": $seller_shipment_id, "tranckingUrl": $trancking_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Confirm order item return and refund
#
# POST /order/{orderId}/shipment/return
# --courier shape: {name: string, taxID?: string}
# --items item shape: {quantity: int, skuSellerId: string}
export def "order-shipment-return create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  info: string # Aditional information about this shippment
  items: list # item shape: {quantity: int, skuSellerId: string}
  --number: string # Tracking Id in the courier
  --occurred-at: string # Date time that this was created (format: date-time)
  --seller-shipment-id: string # Unique Seller shipment Id. This must be unique across all orders and shipments
  --trancking-url: string # Courier tracking URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}/shipment/return") $auth.query)
  let req_body = {"courier": $courier, "cte": $cte, "info": $info, "items": $items, "number": $number, "occurredAt": $occurred_at, "sellerShipmentId": $seller_shipment_id, "tranckingUrl": $trancking_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update new order to include shipment information
#
# POST /order/{orderId}/shipment/sent
# --courier shape: {name: string, taxID?: string}
# --invoice shape: {accessKey: string, cnpj?: string, issuedAt?: string, linkDanfe?: string, linkXml?: string, number: string, serie: string}
export def "order-shipment-sent create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  invoice: any # shape: {accessKey: string, cnpj?: string, issuedAt?: string, linkDanfe?: string, linkXml?: string, number: string, serie: string}
  items: list<string> # List of Order IDs of this items from this order that will be updated in this shipment
  --number: string # Unique id shipment Id in the courier system
  occurred_at: string # Data da ocorrência (format: date-time)
  seller_shipment_id: string # Unique Seller shipment Id. This must be unique across all orders and shipmnents
  --tracking-url: string # Courier tracking URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}/shipment/sent") $auth.query)
  let req_body = {"courier": $courier, "cte": $cte, "invoice": $invoice, "items": $items, "number": $number, "occurredAt": $occurred_at, "sellerShipmentId": $seller_shipment_id, "trackingUrl": $tracking_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns orders details
#
# GET /orders
export def "orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of shipments
#
# GET /orders/shipments/delivered
export def "orders-shipments-delivered get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Query by shippment status.
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, shipments: table<errors: list, items: list, shipmentId: string, status: string, trackingUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/shipments/delivered" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bulk update of order shipments
#
# POST /orders/shipments/delivered
# --shipments item shape: {courier?: any, cte?: string, invoice?: any, items?: list, number?: string, occurredAt?: string, order?: string, sellerShipmentId?: string, status?: string, trackingUrl?: string}
export def "orders-shipments-delivered create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --shipments: list # item shape: {courier?: any, cte?: string, invoice?: any, items?: list, number?: string, occurredAt?: string, order?: string, sellerShipmentId?: string, status?: string, trackingUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/shipments/delivered" $auth.query)
  let req_body = {"shipments": $shipments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns a list of shipments shipped
#
# GET /orders/shipments/shipped
export def "orders-shipments-shipped get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Product status.
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, shipments: table<errors: list, items: list, shipmentId: string, status: string, trackingUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/shipments/shipped" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bulk update of order shipments
#
# POST /orders/shipments/shipped
# --shipments item shape: {courier?: any, cte?: string, invoice?: any, items?: list, number?: string, occurredAt?: string, order?: string, sellerShipmentId?: string, status?: string, trackingUrl?: string}
export def "orders-shipments-shipped create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipments: list # item shape: {courier?: any, cte?: string, invoice?: any, items?: list, number?: string, occurredAt?: string, order?: string, sellerShipmentId?: string, status?: string, trackingUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/shipments/shipped" $auth.query)
  let req_body = {"shipments": $shipments} | compact
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

# Return list of approved orders
#
# GET /orders/status/approved
export def "orders-status-approved get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 100, max 200. Use this in conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/status/approved" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns lists of canceled orders
#
# GET /orders/status/canceled
export def "orders-status-canceled get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Default 100, max 250. Use this conjuction with `offset` to paginate across the results. (default: 100)
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/status/canceled" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of orders successfully delivered associated with this seller.
#
# GET /orders/status/delivered
export def "orders-status-delivered get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/status/delivered" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of orders flagged as new.
#
# GET /orders/status/new
export def "orders-status-new get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 100. Max 250. Use this conjuction with `offset` to paginate across the results. (default: 100)
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/status/new" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of partially deliverd orders
#
# GET /orders/status/partiallyDelivered
export def "orders-status-partially-delivered get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 100. Max 250. Use this conjuction with `offset` to paginate across the results. (default: 100)
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/status/partiallyDelivered" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of orders partially fullfiled
#
# GET /orders/status/partiallySent
export def "orders-status-partially-sent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 100. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/status/partiallySent" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list with orders fully sent
#
# GET /orders/status/sent
export def "orders-status-sent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/status/sent" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new product to the marketplace
#
# POST /product
# --attributes item shape: {name: string, value: string}
# --dimensions shape: {height: int, length: int, weight: int, width: int}
# --giftWrap shape: {available: bool, messageSupport?: bool, value: int}
# --price shape: {default: int, offer: int}
export def "product create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  attributes: list # List of `key` `value` attributes of this product. This is very important for search and SEO optmization. Include all relevant information — item shape: {name: string, value: string}
  brand: string # Brand name
  categories: list<string> # Array of categories associated with this product
  description: string # Product description.
  --dimensions: any # shape: {height: int, length: int, weight: int, width: int}
  --gift-wrap: any # shape: {available: bool, messageSupport?: bool, value: int}
  --gtin: list<string> # Array of product EAN and/or ISBN and/or ASIN codes
  images: list<string> # List of valid Product image URLs. HTTP or HTTPS are valid. HTTPS is prefered.
  price: any # shape: {default: int, offer: int}
  --product-group-id: string # Unique Product Group ID. Products with the same `productGroupId` will be grouped and displayed as a unique entry. Use `productGroupId` to group diferent SKUs that represent diferent colors, sizes, capacities, etc..
  --product-id: string # Brand Lovers Product ID. Use this to suggest a product association. This field is optional.
  sku_seller_id: string # Unique Product Id (SKU) in the seller system
  stock: int # Number of products availble for sale from the seller. Each new successfull order will automatically reduce the number of products available.
  title: string # Product name as advertised by manufacturer. This how the product will be displayed in the Marketplace
  --videos: list<string> # List of videos de URLs associated with this product. HTTP or HTTPS are valid. HTTPS is prefered.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product" $auth.query)
  let req_body = {"attributes": $attributes, "brand": $brand, "categories": $categories, "description": $description, "dimensions": $dimensions, "giftWrap": $gift_wrap, "gtin": $gtin, "images": $images, "price": $price, "productGroupId": $product_group_id, "productId": $product_id, "skuSellerId": $sku_seller_id, "stock": $stock, "title": $title, "videos": $videos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns details of a single product using the seller `skuSellerId`
#
# GET /product/{skuSellerId}
export def "product get" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<attributes: table<name: string, value: string>, brand: string, categories: list<string>, description: string, dimensions: record<height: int, length: int, weight: int, width: int>, errors: table<message: string, skuSellerId: string, type: string>, giftWrap: record<available: bool, messageSupport: bool, value: int>, gtin: list<string>, images: list<string>, price: record<default: int, offer: int>, productGroupId: string, skuSellerId: string, status: string, stock: int, title: string, videos: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sku_seller_id | is-empty) { error make --unspanned { msg: "path parameter 'skuSellerId' must be non-empty" } }
  let full_url = (build-url $base ({sku_seller_id: (encode-path-segment $sku_seller_id)} | format pattern "/product/{sku_seller_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update product details
#
# PUT /product/{skuSellerId}
# --attributes item shape: {name: string, value: string}
# --dimensions shape: {height: int, length: int, weight: int, width: int}
# --giftWrap shape: {available: bool, messageSupport?: bool, value: int}
# --price shape: {default: int, offer: int}
export def "product update" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --attributes: list # List of `key` `value` attributes of this product. This is very important for search and SEO optmization. Include all relevant information — item shape: {name: string, value: string}
  --brand: string # Brand name
  --categories: list<string> # Array of categories associated with this product
  --description: string # Product text description.
  --dimensions: any # shape: {height: int, length: int, weight: int, width: int}
  --gift-wrap: any # shape: {available: bool, messageSupport?: bool, value: int}
  --gtin: list<string> # Array of product EAN and/or ISBN and/or ASIN codes
  --images: list<string> # List of valid Product image URLs. HTTP or HTTPS are valid. HTTPS is prefered.
  --price: any # shape: {default: int, offer: int}
  --product-group-id: string # Unique Product Group ID. Products with the same `productGroupId` will be grouped and displayed as a unique entry. Use `productGroupId` to group diferent SKUs that represent diferent colors, sizes, capacities, etc..
  --product-id: string # Brand Lovers Product Id. Use this to recommend a product association
  --body-sku-seller-id: string # Unique Product Id (SKU) in the seller system
  --stock: int # Number of products availble for sale from the seller. Each new successfull order will automatically reduce the number of products available.
  --title: string # Product name as advertised by manufacturer. This how the product will be displayed in the Marketplace
  --videos: list<string> # List of videos de URLs associated with this product. HTTP or HTTPS are valid. HTTPS is prefered.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sku_seller_id | is-empty) { error make --unspanned { msg: "path parameter 'skuSellerId' must be non-empty" } }
  let full_url = (build-url $base ({sku_seller_id: (encode-path-segment $sku_seller_id)} | format pattern "/product/{sku_seller_id}") $auth.query)
  let req_body = {"attributes": $attributes, "brand": $brand, "categories": $categories, "description": $description, "dimensions": $dimensions, "giftWrap": $gift_wrap, "gtin": $gtin, "images": $images, "price": $price, "productGroupId": $product_group_id, "productId": $product_id, "skuSellerId": $body_sku_seller_id, "stock": $stock, "title": $title, "videos": $videos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Allows seller to update prices of a single SKU
#
# PUT /product/{skuSellerId}/prices
export def "product-prices update" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  default: int # List price, also known as MSRP (Manufacturer Suggest Retail Price) or the recommended retail price (RRP). All prices must be provided in cents. No commas or periods are accepeted. For example one dollar should be informed as 100. $1,2345.67 should be informed solely as 1234567
  offer: int # Product price. This is what will be offered to the customer. All prices must be provided in cents. No commas or periods are accepeted. For example one dollar should be informed as 100. $1,2345.67 should be informed solely as 1234567
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sku_seller_id | is-empty) { error make --unspanned { msg: "path parameter 'skuSellerId' must be non-empty" } }
  let full_url = (build-url $base ({sku_seller_id: (encode-path-segment $sku_seller_id)} | format pattern "/product/{sku_seller_id}/prices") $auth.query)
  let req_body = {"default": $default, "offer": $offer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Enable/disable a single product in the Marketplace
#
# PUT /product/{skuSellerId}/status
export def "product-status update" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --active: oneof<nothing, bool> # Defines if this product is ready for sale. Active `true`, disabled `false`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sku_seller_id | is-empty) { error make --unspanned { msg: "path parameter 'skuSellerId' must be non-empty" } }
  let full_url = (build-url $base ({sku_seller_id: (encode-path-segment $sku_seller_id)} | format pattern "/product/{sku_seller_id}/status") $auth.query)
  let req_body = {"active": $active} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a single product stock
#
# PUT /product/{skuSellerId}/stock
export def "product-stock update" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --cross-docking-time: int # Time it will take to manufacture, prepare or setup this product. Time must be provided in seconds. For example 1 day should be informed as 86400. This time will be included in the product ETA informed to the customer (default: 0)
  quantity: int # Stock available
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sku_seller_id | is-empty) { error make --unspanned { msg: "path parameter 'skuSellerId' must be non-empty" } }
  let full_url = (build-url $base ({sku_seller_id: (encode-path-segment $sku_seller_id)} | format pattern "/product/{sku_seller_id}/stock") $auth.query)
  let req_body = {"crossDockingTime": $cross_docking_time, "quantity": $quantity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns a list of products loaded into BrandLovers Marketplace
#
# GET /products
export def "products get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number of items to retun. Defaults to 100. Max alowed is 200. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, skus: table<attributes: list, brand: string, categories: list, description: string, dimensions: record, errors: list, giftWrap: record, gtin: list, images: list, price: record, productGroupId: string, skuSellerId: string, status: string, stock: int, title: string, videos: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows new products from the seller to be loaded into the marketplace
#
# POST /products
export def "products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Allows bulk update of product prices.
#
# PUT /products/prices
export def "products-prices update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products/prices" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns seller products status in the marketplace
#
# GET /products/status
export def "products-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number of items to return in this query. Defaults to 250. Maximum 1000. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, skus: table<errors: list, price: record, skuSellerId: string, status: string, stock: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products/status" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bulk enable/disable products in the marketplace
#
# PUT /products/status
export def "products-status update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products/status" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns products that are successfully listed for sale.
#
# GET /products/status/selling
export def "products-status-selling get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, sellerItems: table<attributes: list, brand: string, dimensions: record, giftWrap: record, gtin: list, images: list, prices: list, product: record, skuSellerId: string, status: list, stocks: list, title: string, urls: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products/status/selling" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bulk product stock update
#
# PUT /products/stocks
export def "products-stocks update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products/stocks" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates a new trouble ticket
#
# POST /ticket
# --customer shape: {name?: string, phoneNumber?: string}
# --message shape: {body: string, visibility: string}
export def "ticket create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  body: string # Message to the customer
  --customer: any # shape: {name?: string, phoneNumber?: string}
  --description: string # Trouble ticked brief description
  --body-from: string # Friendly name of the person sending this message, if not provided the seller `name` will be used
  --message: any # shape: {body: string, visibility: string}
  order_id: string # Unique order Id that this trouble ticket belongs to
  type: string # Trouble ticket type.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ticket" $auth.query)
  let req_body = {"body": $body, "customer": $customer, "description": $description, "from": $body_from, "message": $message, "orderId": $order_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Add new message to trouble ticket
#
# POST /ticket/{ticketId}/message
export def "ticket-message create" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  body: string # Message text
  visibility: string # Defines if this message is `CUSTOMER` (customer will receive a copy) or `INTERNAL`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticketId' must be non-empty" } }
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/ticket/{ticket_id}/message") $auth.query)
  let req_body = {"body": $body, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get trouble ticket messages
#
# GET /ticket/{ticketId}/messages
export def "ticket-messages get" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<messages: table<body: string, createdAt: string, id: string, visibility: string>, metadata: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticketId' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/ticket/{ticket_id}/messages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update trouble ticket status
#
# PUT /ticket/{ticketId}/status
export def "ticket-status update" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
  ticket_status: string # New trouble ticket status. Valid options are `REOPENED`, `CLOSED`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticketId' must be non-empty" } }
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/ticket/{ticket_id}/status") $auth.query)
  let req_body = {"ticketStatus": $ticket_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get customers trouble tickets
#
# GET /tickets
export def "tickets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Query by trouble ticket status
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console.
]: nothing -> record<metadata: table<key: string, value: string>, tickets: table<closedAt: string, createdAt: string, customer: record, description: string, metadata: list, priority: string, sla: string, status: string, subject: string, ticketId: string, type: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tickets" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
