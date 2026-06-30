# Auto-generated client for Orders API (PII version) v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Orders-API-(PII-version)/1.0/openapi.json
# Auth: --token flag or $env.ORDERS_API_PII_VERSION_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ORDERS_API_PII_VERSION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "vtexidclientautcookie" => { {scheme: $scheme, headers: {VtexIdclientAutCookie: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["vtexidclientautcookie" "x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "orders-extendsearch-orders list-orders2" } } | get name | first)
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

# List orders
#
# POST /api/orders/extendsearch/orders
# operationId: ListOrders2
export def "orders-extendsearch-orders list-orders2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-has-input-invoice: oneof<nothing, bool> # Filters list to return only orders with non `null` values for the `invoiceInput` field. (default: false)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  f_creation_date: string # Concatened value sufix {{creationDate}} and range date in Timestamp format. (e.g. creationDate:[2021-11-01T00:00:00.000Z TO 2022-11-10T02:00:00.000Z])
  page: int # Number of the page to be retrieved. (e.g. 1)
  per_page: int # Number of orders per page. (e.g. 15)
  --q: string # Full-text search for the orders. (e.g. Postman Test)
]: any -> record<facets: list<string>, list: table<ShippingEstimatedDate: string, ShippingEstimatedDateMax: string, ShippingEstimatedDateMin: string, affiliateId: string, authorizedDate: string, callCenterOperatorName: string, clientName: string, creationDate: string, currencyCode: string, items: string, lastMessageUnread: string, listId: string, listType: string, marketPlaceOrderId: string, orderId: string, orderIsComplete: bool, origin: string, paymentNames: string, salesChannel: string, sequence: string, status: string, statusDescription: string, totalItems: int, totalValue: int, workflowInErrorState: bool, workflowInRetry: bool>, paging: record<currentPage: int, pages: int, perPage: int, total: int>, stats: record<stats: record<totalItems: record, totalValue: record>>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o ORDERS_API_PII_VERSION_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o ORDERS_API_PII_VERSION_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "f_hasInputInvoice" $f_has_input_invoice "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/orders/extendsearch/orders" $qp $auth.query)
  let req_body = {"f_creationDate": $f_creation_date, "page": $page, "per_page": $per_page, "q": $q} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: ({"f_hasInputInvoice": $f_has_input_invoice} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get order
#
# GET /api/orders/pvt/document/{orderId}
# operationId: GetOrder2
export def "orders-pvt-document get-order2" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --content-type: string # Type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<affiliateId: string, allowCancellation: bool, allowEdition: bool, approvedBy: string, authorizedDate: string, callCenterOperatorData: string, cancelReason: string, cancelledBy: string, changesAttachment: record<changesData: list<record>, id: string>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, id: string, isCorporate: bool, lastName: string, phone: string, stateInscription: string, tradeName: string, userProfileId: string>, commercialConditionData: string, creationDate: string, customData: string, emailTracked: string, followUpEmail: string, giftRegistryData: string, hostname: string, invoiceData: record, invoicedDate: string, isCheckedIn: bool, isCompleted: bool, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, lastChange: string, lastMessage: string, marketingData: string, marketplace: record<baseURL: string, isCertified: string, name: string>, marketplaceItems: list<string>, marketplaceOrderId: string, marketplaceServicesEndpoint: string, merchantName: string, openTextField: string, orderFormId: string, orderGroup: string, orderId: string, origin: string, packageAttachment: record<packages: list<record>>, paymentData: record<transactions: list<record>>, ratesAndBenefitsData: record<id: string, rateAndBenefitsIdentifiers: list<string>>, roundingError: int, salesChannel: string, sellerOrderId: string, sellers: table<id: string, logo: string, name: string>, sequence: string, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, id: string, logisticsInfo: list<record>, selectedAddresses: list<record>, trackingHints: string>, status: string, statusDescription: string, storePreferencesData: record<countryCode: string, currencyCode: string, currencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, currencyLocale: int, currencySymbol: string, timeZone: string>, totals: table<id: string, name: string, value: int>, value: int> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o ORDERS_API_PII_VERSION_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o ORDERS_API_PII_VERSION_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/orders/pvt/document/{order_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reason": $reason} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Start handling order
#
# POST /api/orders/pvt/document/{orderId}/actions/start-handling
# operationId: StartHandling2
export def "orders-pvt-document-actions-start-handling start-handling2" [
  order_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o ORDERS_API_PII_VERSION_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o ORDERS_API_PII_VERSION_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/orders/pvt/document/{order_id}/actions/start-handling") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Cancel order
#
# POST /api/orders/pvt/document/{orderId}/cancel
# operationId: CancelOrder2
export def "orders-pvt-document-cancel cancel-order2" [
  order_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --reason: string # Reason for cancelling the order. (e.g. Unexpected stock shortage)
]: any -> record<date: string, orderId: string, receipt: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o ORDERS_API_PII_VERSION_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o ORDERS_API_PII_VERSION_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/orders/pvt/document/{order_id}/cancel") $auth.query)
  let req_body = {"reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Order invoice notification
#
# POST /api/orders/pvt/document/{orderId}/invoices
# operationId: InvoiceNotification2
# --items item shape: {itemIndex: string, price: int, quantity: int}
export def "orders-pvt-document-invoices create-notification2" [
  order_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --cfop: string # Fiscal code used in Brazil. (e.g. 6.104)
  --courier: string # The name of the carrier responsible for delivering the order. > This field should only be used when sending **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`). (nullable)
  --extra-value: int # Extra value in the invoice in cents. Do not use any decimal separator. For instance, `$24.99` should be represented as `2499`. (e.g. 100)
  --invoice-key: string # Invoice key. (nullable)
  invoice_number: string # Number that identifies the invoice. (e.g. 123456789)
  --invoice-url: string # URL of the invoice. Can be used to send the URL of an XML file, for example, which is useful for some integrations.
  invoice_value: string # Total amount being invoiced in cents. Do not use any decimal separator. For instance, `$24.99` should be represented as `2499`. (e.g. 2499)
  issued_date: string # Issuance date of the invoice in ISO format. (e.g. 2020-07-15)
  items: list # Array containing the SKUs that are being invoiced. — item shape: {itemIndex: string, price: int, quantity: int}
  --tracking-number: string # Code that identifies the order tracking. > This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`). (nullable)
  --tracking-url: string # URL used to track the order. > This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`). (nullable)
  type: string # The type of invoice. There are two possible values: `"Output"` and `"Input"`. The `"Output"` type should be used when the invoice you are sending is a selling invoice. The `"Input"` type should be used when you send a return invoice. (e.g. Output)
  --volumes: int # Number of volumes in the invoice. (e.g. 3)
]: any -> record<date: string, orderId: string, receipt: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o ORDERS_API_PII_VERSION_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o ORDERS_API_PII_VERSION_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/orders/pvt/document/{order_id}/invoices") $auth.query)
  let req_body = {"cfop": $cfop, "courier": $courier, "extraValue": $extra_value, "invoiceKey": $invoice_key, "invoiceNumber": $invoice_number, "invoiceUrl": $invoice_url, "invoiceValue": $invoice_value, "issuedDate": $issued_date, "items": $items, "trackingNumber": $tracking_number, "trackingUrl": $tracking_url, "type": $type, "volumes": $volumes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Send payment notification
#
# POST /api/orders/pvt/document/{orderId}/payment/{paymentId}/notify-payment
# operationId: SendPaymentNotification2
export def "orders-pvt-document-payment-notify-payment send-notification2" [
  order_id: string
  payment_id: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o ORDERS_API_PII_VERSION_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o ORDERS_API_PII_VERSION_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id), payment_id: (encode-path-segment $payment_id)} | format pattern "/api/orders/pvt/document/{order_id}/payment/{payment_id}/notify-payment") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
