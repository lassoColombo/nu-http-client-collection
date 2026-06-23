# Auto-generated client for Subscriptions API (v3) v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Subscriptions-API-(v3)/1.0/openapi.json
# Auth: --token flag or $env.SUBSCRIPTIONS_API_V3_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUBSCRIPTIONS_API_V3_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rns-pub-cycles list" } } | get name | first)
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

# List cycles
#
# GET /api/rns/pub/cycles
export def "rns-pub-cycles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --begin-date: string # Lower limit for the date of creation of the cycle (nullable)
  --end-date: string # Upper limit for the date of creation of the cycle (nullable)
  --subscription-id: string # Id from the subscription that generated the cycle (nullable)
  --customer-email: string # Customer that owns the subscription. Defaults to the current logged user (nullable)
  --status: string # Current cycle status (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<context: record<addressId: string, addressType: string, items: list, paymentAccountId: string, paymentSystem: string, paymentSystemGroup: string, paymentSystemName: string>, customerEmail: string, cycleCount: int, date: string, id: string, isInRetry: bool, lastUpdate: string, message: string, orderInfo: record<orderGroup: string, orderId: string, paymentURL: string, value: int>, simulationItems: list<record>, status: string, subscriptionId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "beginDate" $begin_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "subscriptionId" $subscription_id "scalar") (serialize-qp "customerEmail" $customer_email "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rns/pub/cycles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"beginDate": $begin_date, "endDate": $end_date, "subscriptionId": $subscription_id, "customerEmail": $customer_email, "status": $status, "page": $page, "size": $size} | compact), body: null}
}

# Get cycle details
#
# GET /api/rns/pub/cycles/{cycleId}
export def "rns-pub-cycles get" [
  cycle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<context: record<addressId: string, addressType: string, items: list<record>, paymentAccountId: string, paymentSystem: string, paymentSystemGroup: string, paymentSystemName: string>, customerEmail: string, cycleCount: int, date: string, id: string, isInRetry: bool, lastUpdate: string, message: string, orderInfo: record<orderGroup: string, orderId: string, paymentURL: string, value: int>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, status: string, subscriptionId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($cycle_id | is-empty) { error make --unspanned { msg: "path parameter 'cycleId' must be non-empty" } }
  let full_url = (build-url $base ({cycle_id: (encode-path-segment $cycle_id)} | format pattern "/api/rns/pub/cycles/{cycle_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retry cycle
#
# POST /api/rns/pub/cycles/{cycleId}/retry
export def "rns-pub-cycles-retry create" [
  cycle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($cycle_id | is-empty) { error make --unspanned { msg: "path parameter 'cycleId' must be non-empty" } }
  let full_url = (build-url $base ({cycle_id: (encode-path-segment $cycle_id)} | format pattern "/api/rns/pub/cycles/{cycle_id}/retry"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List subscriptions
#
# GET /api/rns/pub/subscriptions
export def "rns-pub-subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --customer-email: string # Customer that owns the subscription. Defaults to the current logged user. (nullable)
  --status: string # Current subscription status (nullable)
  --address-id: string # Id from the address used as shipping address (nullable)
  --payment-id: string # Id from the payment used as payment method (nullable)
  --plan-id: string # Id from the plan that the subscription belongs to (nullable)
  --next-purchase-date: string # Date for the next cycle (nullable)
  --original-order-id: string # Id from the order that generated the subscription (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: list<record>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record, id: string, purchaseDay: int, validity: record>, purchaseSettings: record<currencyCode: string, paymentMethod: record>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customerEmail" $customer_email "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "addressId" $address_id "scalar") (serialize-qp "paymentId" $payment_id "scalar") (serialize-qp "planId" $plan_id "scalar") (serialize-qp "nextPurchaseDate" $next_purchase_date "scalar") (serialize-qp "originalOrderId" $original_order_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rns/pub/subscriptions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"customerEmail": $customer_email, "status": $status, "addressId": $address_id, "paymentId": $payment_id, "planId": $plan_id, "nextPurchaseDate": $next_purchase_date, "originalOrderId": $original_order_id, "page": $page, "size": $size} | compact), body: null}
}

# Create subscription
#
# POST /api/rns/pub/subscriptions
# --items item shape: {manualPrice?: int, quantity?: int, skuId?: string}
# --plan shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
# --purchaseSettings shape: {paymentMethod: record, salesChannel: string}
# --shippingAddress shape: {addressId: string, addressType: string}
export def "rns-pub-subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --catalog-attachment: string # nullable
  --customer-email: string # nullable
  --items: list # nullable — item shape: {manualPrice?: int, quantity?: int, skuId?: string}
  --next-purchase-date: string # nullable, format: date-time
  plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  purchase_settings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  shipping_address: record # shape: {addressId: string, addressType: string}
  --status: string # nullable
  --title: string # nullable
]: any -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/pub/subscriptions")
  let req_body = {"catalogAttachment": $catalog_attachment, "customerEmail": $customer_email, "items": $items, "nextPurchaseDate": $next_purchase_date, "plan": $plan, "purchaseSettings": $purchase_settings, "shippingAddress": $shipping_address, "status": $status, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Calculate the current prices for the provided subscription template
#
# POST /api/rns/pub/subscriptions/simulate
# --items item shape: {manualPrice?: int, quantity?: int, skuId?: string}
# --plan shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
# --purchaseSettings shape: {paymentMethod: record, salesChannel: string}
# --shippingAddress shape: {addressId: string, addressType: string}
export def "rns-pub-subscriptions-simulate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --catalog-attachment: string # nullable
  --customer-email: string # nullable
  --items: list # nullable — item shape: {manualPrice?: int, quantity?: int, skuId?: string}
  --next-purchase-date: string # nullable, format: date-time
  plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  purchase_settings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  shipping_address: record # shape: {addressId: string, addressType: string}
  --status: string # nullable
  --title: string # nullable
]: any -> record<shippingEstimate: record<allItemsMatched: bool, estimate: string, estimateDeliveryDate: string, name: string, nextPurchaseDate: string>, simulateResponse: record<country: string, items: list<record>, logisticsInfo: list<record>, messages: list<record>, paymentData: record<payments: list, transactions: list>, postalCode: string, selectableGiftsResponse: list<record>, simulationItems: list<record>, totals: list<record>>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, totals: table<id: string, value: float>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/pub/subscriptions/simulate")
  let req_body = {"catalogAttachment": $catalog_attachment, "customerEmail": $customer_email, "items": $items, "nextPurchaseDate": $next_purchase_date, "plan": $plan, "purchaseSettings": $purchase_settings, "shippingAddress": $shipping_address, "status": $status, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get subscription details
#
# GET /api/rns/pub/subscriptions/{id}
export def "rns-pub-subscriptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/rns/pub/subscriptions/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update subscription
#
# PATCH /api/rns/pub/subscriptions/{id}
# --plan shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
# --purchaseSettings shape: {paymentMethod: record, salesChannel: string}
# --shippingAddress shape: {addressId: string, addressType: string}
export def "rns-pub-subscriptions update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --is-skipped: oneof<nothing, bool> # When set as `true`, it means the shopper asked to skip the next subscription order, and when set as `false`, no subscription order is going to be skipped. (nullable, e.g. false)
  --plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  --purchase-settings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  --shipping-address: record # shape: {addressId: string, addressType: string}
  --status: string # Status to which you wish to update the subscription. The accepted values are: - `ACTIVE` - `PAUSED` - `CANCELLED` - `EXPIRED` - `MISSING` (nullable, e.g. ACTIVE)
  --title: string # Name of the subscription. (nullable, e.g. catFood)
]: any -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/rns/pub/subscriptions/{id}"))
  let req_body = {"isSkipped": $is_skipped, "plan": $plan, "purchaseSettings": $purchase_settings, "shippingAddress": $shipping_address, "status": $status, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Add item to subscription
#
# POST /api/rns/pub/subscriptions/{id}/items
export def "rns-pub-subscriptions-items create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --manual-price: int # Manual price. (nullable, format: int32, e.g. 40)
  --quantity: int # Amount of units in the cart. (format: int32, e.g. 5)
  --sku-id: string # SKU ID. (nullable, e.g. 12)
]: any -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/rns/pub/subscriptions/{id}/items"))
  let req_body = {"manualPrice": $manual_price, "quantity": $quantity, "skuId": $sku_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Remove items from a subscription.
#
# DELETE /api/rns/pub/subscriptions/{id}/items/{itemId}
export def "rns-pub-subscriptions-items delete" [
  id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), item_id: (encode-path-segment $item_id)} | format pattern "/api/rns/pub/subscriptions/{id}/items/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit items on a subscription.
#
# PATCH /api/rns/pub/subscriptions/{id}/items/{itemId}
export def "rns-pub-subscriptions-items update" [
  id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --is-skipped: oneof<nothing, bool> # nullable
  --manual-price: int # Manual price. (nullable, format: int32, e.g. 40)
  --quantity: int # Amount of units in the cart. (format: int32, e.g. 5)
  --status: string # nullable
]: any -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), item_id: (encode-path-segment $item_id)} | format pattern "/api/rns/pub/subscriptions/{id}/items/{item_id}"))
  let req_body = {"isSkipped": $is_skipped, "manualPrice": $manual_price, "quantity": $quantity, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Calculate the current prices for a specific subscription
#
# POST /api/rns/pub/subscriptions/{id}/simulate
export def "rns-pub-subscriptions-simulate create-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<shippingEstimate: record<allItemsMatched: bool, estimate: string, estimateDeliveryDate: string, name: string, nextPurchaseDate: string>, simulateResponse: record<country: string, items: list<record>, logisticsInfo: list<record>, messages: list<record>, paymentData: record<payments: list, transactions: list>, postalCode: string, selectableGiftsResponse: list<record>, simulationItems: list<record>, totals: list<record>>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, totals: table<id: string, value: float>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/rns/pub/subscriptions/{id}/simulate"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get conversation messages
#
# GET /api/rns/pub/subscriptions/{subscriptionId}/conversation-message
export def "rns-pub-subscriptions-conversation-message get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<attachmentNames: list<string>, body: string, date: string, firstWords: string, from: record<aliasMaskType: string, conversationRelatedTo: string, conversationSubject: string, email: string, emailAlias: string, name: string, role: string>, hasAttachment: bool, id: string, subject: string, to: list<record>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/api/rns/pub/subscriptions/{subscription_id}/conversation-message"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List plans
#
# GET /api/rns/pvt/plans
export def "rns-pvt-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --periodicity: string # Filter plans by available periodicity (nullable)
  --interval: string # Filter plans by available interval (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<frequencies: list<record>, id: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodicity" $periodicity "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rns/pvt/plans" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"periodicity": $periodicity, "interval": $interval, "page": $page, "size": $size} | compact), body: null}
}

# Get plan details
#
# GET /api/rns/pvt/plans/{id}
export def "rns-pvt-plans get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<frequencies: table<interval: int, periodicity: int, periodicityAsString: string>, id: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/rns/pvt/plans/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List report templates
#
# GET /api/rns/pvt/reports
export def "rns-pvt-reports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<account: string, description: string, entity: string, key: string, name: string, params: list<record>, query: string, requesterEmail: string, schema: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/pvt/reports")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate report
#
# POST /api/rns/pvt/reports/{reportName}/documents
export def "rns-pvt-reports-documents create" [
  report_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The report is sent to the email in this field. (default: receiver@email.com)
  --begin-date: string # Start date of the report with the format `yyyy-mm-dd`. This field is required for any type of report. (default: 2022-09-01)
  --end-date: string # End date of the report with the format `yyyy-mm-dd`. This field is required for any type of report. (default: 2022-10-01)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<canceled: bool, completedDate: string, email: string, enqueueDate: string, errorCount: int, finished: bool, id: string, lastErrorMessage: string, lastUpdateTime: string, linkToDownload: string, outputType: string, percentageProcessed: int, recordsProcessed: int, recordsSum: int, startDate: string, statusMessage: string, zipped: bool> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($report_name | is-empty) { error make --unspanned { msg: "path parameter 'reportName' must be non-empty" } }
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "beginDate" $begin_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({report_name: (encode-path-segment $report_name)} | format pattern "/api/rns/pvt/reports/{report_name}/documents") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"email": $email, "beginDate": $begin_date, "endDate": $end_date} | compact), body: null}
}

# Get report document details
#
# GET /api/rns/pvt/reports/{reportName}/documents/{documentId}
export def "rns-pvt-reports-documents get" [
  report_name: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<canceled: bool, completedDate: string, email: string, enqueueDate: string, errorCount: int, finished: bool, id: string, lastErrorMessage: string, lastUpdateTime: string, linkToDownload: string, outputType: string, percentageProcessed: int, recordsProcessed: int, recordsSum: int, startDate: string, statusMessage: string, zipped: bool> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($report_name | is-empty) { error make --unspanned { msg: "path parameter 'reportName' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({report_name: (encode-path-segment $report_name), document_id: (encode-path-segment $document_id)} | format pattern "/api/rns/pvt/reports/{report_name}/documents/{document_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Subscription Settings
#
# GET /api/rns/settings
# operationId: GetSettings
export def "rns-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit Subscriptions settings
#
# POST /api/rns/settings
# operationId: EditSettings
export def "rns-settings create-edit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --default-sla: string # Default delivery method. (nullable)
  delivery_channels: list<string> # Array containing delivery channels. (default: [], e.g. delivery)
  execution_hour_in_utc: int # Indicates the time future subscription orders will be generated. (default: 0, e.g. 9)
  --is-multiple-installments-enabled-on-creation: oneof<nothing, bool> # Defines whether or not multiple installments are enabled when a subscription is created. (default: false, e.g. false)
  --is-multiple-installments-enabled-on-update: oneof<nothing, bool> # Defines whether or not multiple installments are enabled when a subscription is updated. (default: false, e.g. false)
  --is-using-v3: oneof<nothing, bool> # Indicates whether or not Subscriptions V3 is enabled. (default: false, e.g. true)
  --manual-price-allowed: oneof<nothing, bool> # When set to `true`, this property enables manual price configuration in subscription items. This is valid for all existing subscriptions, provided that there is a manual price configured and that `isUsingV3` is `true`. (default: false, e.g. false)
  --on-migration-process: oneof<nothing, bool> # Indicates whether or not the account is in the migration process to Subscriptions V3. (default: false, e.g. false)
  order_custom_data_app_id: string # When filled, this field passes along the `customData` infomration in the order to the future recurrent subscription orders.
  --postpone-expiration: oneof<nothing, bool> # Defines whether or not the expiration of subscriptions can be postponed. (default: false, e.g. false)
  --random-id-generation: oneof<nothing, bool> # Defines whether or not the subscription order IDs will be randomly generated. (default: false, e.g. false)
  sla_option: string # Delivery method. (default: , e.g. NONE)
  --use-item-price-from-original-order: oneof<nothing, bool> # When set to `true`, this property enables using the manual price for each item from the original subscription order. This is only valid for new subscriptions, created from the moment this configuration is enabled. For this to work, it is mandatory that the `manualPriceAllowed` property is set to `true` and that `isUsingV3` is `true`. (default: false, e.g. false)
  workflow_version: string # Workflow version. (default: , e.g. 1.1)
]: any -> record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o SUBSCRIPTIONS_API_V3_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o SUBSCRIPTIONS_API_V3_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/settings")
  let req_body = {"defaultSla": $default_sla, "deliveryChannels": $delivery_channels, "executionHourInUtc": $execution_hour_in_utc, "isMultipleInstallmentsEnabledOnCreation": $is_multiple_installments_enabled_on_creation, "isMultipleInstallmentsEnabledOnUpdate": $is_multiple_installments_enabled_on_update, "isUsingV3": $is_using_v3, "manualPriceAllowed": $manual_price_allowed, "onMigrationProcess": $on_migration_process, "orderCustomDataAppId": $order_custom_data_app_id, "postponeExpiration": $postpone_expiration, "randomIdGeneration": $random_id_generation, "slaOption": $sla_option, "useItemPriceFromOriginalOrder": $use_item_price_from_original_order, "workflowVersion": $workflow_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}
