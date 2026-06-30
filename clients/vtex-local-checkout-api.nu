# Auto-generated client for Checkout API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Checkout-API/1.0/openapi.json
# Auth: --token flag or $env.CHECKOUT_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CHECKOUT_API_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken" "none"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "checkout-pub-gateway-callback create-process-order" } } | get name | first)
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

# Process order
#
# POST /api/checkout/pub/gatewayCallback/{orderGroup}
# operationId: ProcessOrder
export def "checkout-pub-gateway-callback create-process-order" [
  order_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --cookie: string # VTEX Chekout cookie associated with a specific order. Use the `Vtex_CHKO_Auth` and the `CheckoutDataAccess` cookies returned by the [Place order](https://developers.vtex.com/vtex-rest-api/reference/order-placement-1#placeorder) or [Place order from existing cart](https://developers.vtex.com/vtex-rest-api/reference/order-placement-1#placeorderfromexistingorderform) API requests, like a browser would.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_group | is-empty) { error make --unspanned { msg: "path parameter 'orderGroup' must be non-empty" } }
  let full_url = (build-url $base ({order_group: (encode-path-segment $order_group)} | format pattern "/api/checkout/pub/gatewayCallback/{order_group}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "Cookie": $cookie} | compact
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

# Get current or create a new cart
#
# GET /api/checkout/pub/orderForm
# operationId: CreateANewCart
export def "checkout-pub-order-form create-new-cart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-new-cart: oneof<nothing, bool> # Use this query parameter to create a new empty shopping cart. (default: true)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceNewCart" $force_new_cart "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/orderForm" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"forceNewCart": $force_new_cart} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get cart information by ID
#
# GET /api/checkout/pub/orderForm/{orderFormId}
# operationId: GetCartInformationById
export def "checkout-pub-order-form get-cart-information" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --refresh-outdated-data: oneof<nothing, bool> # It is possible to use the [Update cart items request](https://developers.vtex.com/vtex-rest-api/reference/cart-update#itemsupdate) so as to allow outdated information in the `orderForm`, which may improve performance in some cases. To guarantee that all cart information is updated, send this request with this parameter as `true`. We recommend doing this in the final stages of the shopping experience, starting from the checkout page. (default: true)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let qp = [(serialize-qp "refreshOutdatedData" $refresh_outdated_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"refreshOutdatedData": $refresh_outdated_data} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add client preferences
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/clientPreferencesData
# operationId: AddClientPreferences
export def "checkout-pub-order-form-attachments-client-preferences-data create" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --locale: string # Locale chosen by the shopper. Determines website language. (default: EN)
  --optin-news-letter: oneof<nothing, bool> # Indicates whether the shopper opted in to receive the store's news letter. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/attachments/clientPreferencesData") $auth.query)
  let req_body = {"locale": $locale, "optinNewsLetter": $optin_news_letter} | compact
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

# Add client profile
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/clientProfileData
# operationId: AddClientProfile
export def "checkout-pub-order-form-attachments-client-profile-data create" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --corporate-document: string # Corporate document, if the customer is a legal entity. (default: 12345678000100)
  --corporate-name: string # Company name, if the customer is a legal entity. (default: company-name)
  --corporate-phone: string # Corporate phone number, if the customer is a legal entity. (default: +551100988887777)
  document: string # Document number informed by the customer. (default: 123456789)
  document_type: string # Type of the document informed by the customer. (default: cpf)
  email: string # Customer's email address. (default: customer@examplemail.com)
  first_name: string # Customer's first name. (default: first-name)
  --is-corporate: oneof<nothing, bool> # `true` if the customer is a legal entity. (default: false)
  last_name: string # Customer's last name. (default: last-name)
  --phone: string # Customer's phone number. (default: +55110988887777)
  --state-inscription: string # State inscription, if the customer is a legal entity. (default: 12345678)
  --trade-name: string # Trade name, if the customer is a legal entity. (default: trade-name)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/attachments/clientProfileData") $auth.query)
  let req_body = {"corporateDocument": $corporate_document, "corporateName": $corporate_name, "corporatePhone": $corporate_phone, "document": $document, "documentType": $document_type, "email": $email, "firstName": $first_name, "isCorporate": $is_corporate, "lastName": $last_name, "phone": $phone, "stateInscription": $state_inscription, "tradeName": $trade_name} | compact
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

# Add marketing data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/marketingData
# operationId: AddMarketingData
export def "checkout-pub-order-form-attachments-marketing-data create" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --coupon: string # Sending an existing coupon code in this field will return the corresponding discount in the purchase. Use the [cart simulation](https://developers.vtex.com/vtex-rest-api/reference/orderform#orderformsimulation) request to check which coupons might apply before placing the order. (default: free-shipping)
  --marketing-tags: list<string> # Marketing tags. (default: [tag1, tag2])
  --utm-campaign: string # UTM campaign (default: Black friday)
  --utm-medium: string # UTM medium. (default: CPC)
  --utm-source: string # UTM source. (default: Facebook)
  --utmi-campaign: string # utmi_campaign (internal utm) (default: utmi_campaign-exmaple)
  --utmi-page: string # utmi_page (internal utm) (default: utmi_page-example)
  --utmi-part: string # utmi_part (internal utm) (default: utmi_part-exmaple)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/attachments/marketingData") $auth.query)
  let req_body = {"coupon": $coupon, "marketingTags": $marketing_tags, "utmCampaign": $utm_campaign, "utmMedium": $utm_medium, "utmSource": $utm_source, "utmiCampaign": $utmi_campaign, "utmiPage": $utmi_page, "utmiPart": $utmi_part} | compact
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

# Add merchant context data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/merchantContextData
# operationId: AddMerchantContextData
# --salesAssociateData shape: {salesAssociateId?: string}
export def "checkout-pub-order-form-attachments-merchant-context-data create" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  sales_associate_data: record # Sales Associate information. — shape: {salesAssociateId?: string}
]: any -> record<salesAssociateId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/attachments/merchantContextData") $auth.query)
  let req_body = {"salesAssociateData": $sales_associate_data} | compact
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

# Add payment data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/paymentData
# operationId: AddPaymentData
# --payments item shape: {group?: string, hasDefaultBillingAddress?: bool, installments?: int, installmentsInterestRate?: float, installmentsValue?: int, paymentSystem?: int, paymentSystemName?: string, referenceValue?: int, value?: int}
export def "checkout-pub-order-form-attachments-payment-data create" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --payments: list # Array with information on each payment chosen by the shopper. — item shape: {group?: string, hasDefaultBillingAddress?: bool, installments?: int, installmentsInterestRate?: float, installmentsValue?: int, paymentSystem?: int, paymentSystemName?: string, referenceValue?: int, value?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/attachments/paymentData") $auth.query)
  let req_body = {"payments": $payments} | compact
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

# Add shipping address and select delivery option
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/shippingData
# operationId: AddShippingAddress
# --logisticsInfo item shape: {itemIndex?: int, selectedDeliveryChannel?: string, selectedSla?: string}
# --selectedAddresses item shape: {addressType?: string, city?: string, complement?: string, country?: string, geoCoordinates?: list<float>, neighborhood?: string, number?: string, postalCode?: string, receiverName?: string, reference?: string, state?: string, street?: string}
export def "checkout-pub-order-form-attachments-shipping-data create-address" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --clear-address-if-postal-code-not-found: oneof<nothing, bool> # This field should be sent as `false` to prevent the address information from being filled in automatically based on the `postalCode` information. (e.g. false)
  --logistics-info: list # Array with logistics information on each item of the `items` array in the `orderForm`. — item shape: {itemIndex?: int, selectedDeliveryChannel?: string, selectedSla?: string}
  --selected-addresses: list # List of objects with addresses information. — item shape: {addressType?: string, city?: string, complement?: string, country?: string, geoCoordinates?: list<float>, neighborhood?: string, number?: string, postalCode?: string, receiverName?: string, reference?: string, state?: string, street?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/attachments/shippingData") $auth.query)
  let req_body = {"clearAddressIfPostalCodeNotFound": $clear_address_if_postal_code_not_found, "logisticsInfo": $logistics_info, "selectedAddresses": $selected_addresses} | compact
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

# Add coupons to the cart
#
# POST /api/checkout/pub/orderForm/{orderFormId}/coupons
# operationId: AddCoupons
export def "checkout-pub-order-form-coupons create" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --text: string # Sending an existing coupon code in this field will return the corresponding discount in the purchase. Use the [cart simulation](https://developers.vtex.com/vtex-rest-api/reference/orderform#orderformsimulation) request to check which coupons might apply before placing the order. (default: freeshipping)
]: any -> record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/coupons") $auth.query)
  let req_body = {"text": $text} | compact
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

# Set multiple custom field values
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}
# operationId: SetMultipleCustomFieldValues
export def "checkout-pub-order-form-custom-data update-multiple-field-values" [
  order_form_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id), app_id: (encode-path-segment $app_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/customData/{app_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Remove single custom field value
#
# DELETE /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}/{appFieldName}
# operationId: Removesinglecustomfieldvalue
export def "checkout-pub-order-form-custom-data delete-singlecustomfieldvalue" [
  order_form_id: string
  app_id: string
  app_field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($app_field_name | is-empty) { error make --unspanned { msg: "path parameter 'appFieldName' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id), app_id: (encode-path-segment $app_id), app_field_name: (encode-path-segment $app_field_name)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/customData/{app_id}/{app_field_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Set single custom field value
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}/{appFieldName}
# operationId: SetSingleCustomFieldValue
export def "checkout-pub-order-form-custom-data update-single-field-value" [
  order_form_id: string
  app_id: string
  app_field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  value: string # The value you want to set to the specified field.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($app_field_name | is-empty) { error make --unspanned { msg: "path parameter 'appFieldName' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id), app_id: (encode-path-segment $app_id), app_field_name: (encode-path-segment $app_field_name)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/customData/{app_id}/{app_field_name}") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Cart installments
#
# GET /api/checkout/pub/orderForm/{orderFormId}/installments
# operationId: GetCartInstallments
export def "checkout-pub-order-form-installments get-cart" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payment-system: int # ID of the payment method to be consulted for installments.
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let qp = [(serialize-qp "paymentSystem" $payment_system "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/installments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"paymentSystem": $payment_system} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add cart items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items
# operationId: Items
# --orderItems item shape: {id: string, index: int, price?: int, quantity: int, seller: string}
export def "checkout-pub-order-form-items create" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-outdated-data: list # In order to optimize performance, this parameter allows some information to not be updated when there are changes in the minicart. For instance, if a shopper adds another unit of a given SKU to the cart, it may not be necessary to recalculate payment information, which could impact performance. This array accepts strings and currently the only possible value is `”paymentData”`. (default: [paymentData])
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --order-items: list # Array containing the cart items. Each object inside this array corresponds to a different item. — item shape: {id: string, index: int, price?: int, quantity: int, seller: string}
]: any -> record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let qp = [(serialize-qp "allowedOutdatedData" $allowed_outdated_data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/items") $qp $auth.query)
  let req_body = {"orderItems": $order_items} | compact
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
    query: ({"allowedOutdatedData": $allowed_outdated_data} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Remove all items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items/removeAll
# operationId: RemoveAllItems
export def "checkout-pub-order-form-items-remove-all delete" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/items/removeAll") $auth.query)
  let req_body = $body
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

# Update cart items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items/update
# operationId: ItemsUpdate
# --orderItems item shape: {index: int, quantity: int}
export def "checkout-pub-order-form-items-update update" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-outdated-data: list # In order to optimize performance, this parameter allows some information to not be updated when there are changes in the minicart. For instance, if a shopper adds another unit of a given SKU to the cart, it may not be necessary to recalculate payment information, which could impact performance. This array accepts strings and currently the only possible value is `”paymentData”`. (default: [paymentData])
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --order-items: list # Array containing the cart items. Each object inside this array corresponds to a different item. — item shape: {index: int, quantity: int}
]: any -> record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let qp = [(serialize-qp "allowedOutdatedData" $allowed_outdated_data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/items/update") $qp $auth.query)
  let req_body = {"orderItems": $order_items} | compact
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
    query: ({"allowedOutdatedData": $allowed_outdated_data} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Change price
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/items/{itemIndex}/price
# operationId: PriceChange
export def "checkout-pub-order-form-items-price update-change" [
  order_form_id: string
  item_index: string
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  price: int # The new price of the item. (format: int32)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CHECKOUT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CHECKOUT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  if ($item_index | is-empty) { error make --unspanned { msg: "path parameter 'itemIndex' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id), item_index: (encode-path-segment $item_index)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/items/{item_index}/price") $auth.query)
  let req_body = {"price": $price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Clear orderForm messages
#
# POST /api/checkout/pub/orderForm/{orderFormId}/messages/clear
# operationId: ClearorderFormMessages
export def "checkout-pub-order-form-messages-clear create-clearorder" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/messages/clear") $auth.query)
  let req_body = $body
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

# Ignore profile data
#
# PATCH /api/checkout/pub/orderForm/{orderFormId}/profile
# operationId: IgnoreProfileData
export def "checkout-pub-order-form-profile update-ignore-data" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --ignore-profile-data: oneof<nothing, bool> # Indicates whether profile data should be ignored. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/profile") $auth.query)
  let req_body = {"ignoreProfileData": $ignore_profile_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Place order from an existing cart
#
# POST /api/checkout/pub/orderForm/{orderFormId}/transaction
# operationId: PlaceOrderFromExistingOrderForm
export def "checkout-pub-order-form-transaction create-place-from-existing" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  interest_value: int # Interest rate to be used in case it applies. (default: 0)
  --optin-news-letter: oneof<nothing, bool> # True if the shopper opted to receive the newsletter. (default: false)
  reference_id: string # ID of the `orderForm` corresponding to the cart from which to place the order. This is the same as the `orderFormId` parameter. (default: 41a22925298a4ddca95318131a25b000)
  reference_value: int # Reference value of the order for calculating interest if that is the case. Can be equal to the total value and does not separate cents. For example, $24.99 is represented `2499`. (default: 6800)
  --save-personal-data: oneof<nothing, bool> # `true` if the shopper's data provided during checkout should be saved for future reference. (default: false)
  value: int # Total value of the order without separating cents. For example, $24.99 is represented `2499`. (default: 6800)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/api/checkout/pub/orderForm/{order_form_id}/transaction") $auth.query)
  let req_body = {"interestValue": $interest_value, "optinNewsLetter": $optin_news_letter, "referenceId": $reference_id, "referenceValue": $reference_value, "savePersonalData": $save_personal_data, "value": $value} | compact
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

# Cart simulation
#
# POST /api/checkout/pub/orderForms/simulation
# operationId: CartSimulation
# --items item shape: {id?: string, quantity?: int, seller?: string}
export def "checkout-pub-order-forms-simulation create-cart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rnb-behavior: int # This parameter defines which promotions apply to the simulation. Use `0` for simulations at cart stage, which means all promotions apply. In case of window simulation use `1`, which indicates promotions that apply nominal discounts over the total purchase value shouldn't be considered on the simulation. Note that if this not sent, the parameter is `1`. (default: 0)
  --sc: int # Trade Policy (Sales Channel) identification. (e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --country: string # Three letter ISO code of the country of the shipping address. This value must be sent along with the `postalCode` or `geoCoordinates` values. (e.g. BRA)
  --geo-coordinates: list<float> # Array containing two floats with geocoordinates, first longitude, then latitude. (default: [-47.924747467041016, -15.832582473754883])
  --items: list # Array containing information about the SKUs inside the cart to be simulated. — item shape: {id?: string, quantity?: int, seller?: string}
  --postal-code: string # Postal code. (e.g. 12345-000)
]: any -> record<country: string, items: table<availability: string, id: string, listPrice: int, measurementUnit: string, offerings: list, parentAssemblyBinding: string, parentItemIndex: int, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, tax: int, unitMultiplier: int>, logisticsInfo: table<addressId: string, deliveryChannels: list, itemIndex: int, itemMetadata: record, messages: list, pickupPoints: list, purchaseConditions: record, quantity: int, selectedDeliveryChannel: string, selectedSla: string, shipsTo: list, slas: list, subscriptionData: record, totals: list>, marketingData: record, paymentData: record<availableAccounts: list<any>, availableAssociations: record, availableTokens: list<any>, giftCardMessages: list<any>, giftCards: list<any>, installmentOptions: list<any>, paymentSystems: list<record>, payments: list<any>>, postalCode: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<any>, teaser: list<any>>, selectableGifts: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RnbBehavior" $rnb_behavior "scalar") (serialize-qp "sc" $sc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/orderForms/simulation" $qp $auth.query)
  let req_body = {"country": $country, "geoCoordinates": $geo_coordinates, "items": $items, "postalCode": $postal_code} | compact
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
    query: ({"RnbBehavior": $rnb_behavior, "sc": $sc} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Place order
#
# PUT /api/checkout/pub/orders
# operationId: PlaceOrder
# --clientProfileData shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document?: string, documentType?: string, email: string, firstName?: string, isCorporate?: bool, lastName?: string, phone?: string, stateInscription?: string, tradeName?: string}
# --items item shape: {attachments?: list<string>, bundleItems?: list, commission?: int, freightCommission?: int, id: string, isGift?: bool, itemAttachment?: record, measurementUnit?: string, price?: int, priceTags?: list, quantity: int, seller: string, unitMultiplier?: int}
# --marketingData shape: {coupon?: string, utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
# --paymentData shape: {giftCardMessages?: list, giftCards?: list, paymentSystems?: list, payments: list, updateStatus?: string}
# --salesAssociateData shape: {salesAssociateId?: string}
# --shippingData shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
export def "checkout-pub-orders update-place" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy (Sales Channel) identification. This query can be used to create an order for a specific sales channel. (e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  client_profile_data: record # Customer's profile information. The `email` functions as a customer's ID. For customers already in your database, sending only the email address is enough to register the order to the shopper’s existing account. > If the shopper exists in you database but is not logged in, sending other profile information along with the email will cause the platform to fail placing the order. This happens because this action is interpreted as an attempt to edit profile data, which is not possible unless the customer is logged in to the store. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document?: string, documentType?: string, email: string, firstName?: string, isCorporate?: bool, lastName?: string, phone?: string, stateInscription?: string, tradeName?: string}
  items: list # Array of objects containing information on each of the order's items. — item shape: {attachments?: list<string>, bundleItems?: list, commission?: int, freightCommission?: int, id: string, isGift?: bool, itemAttachment?: record, measurementUnit?: string, price?: int, priceTags?: list, quantity: int, seller: string, unitMultiplier?: int}
  --marketing-data: record # shape: {coupon?: string, utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  --open-text-field: string # Optional field meant to hold additional information about the order. We recommend using this field for text, not data formats such as `JSON` even if escaped. For that purpose, see [Creating customizable fields](https://developers.vtex.com/vtex-rest-api/docs/creating-customizable-fields-in-the-cart-with-checkout-api-1) (default: open-text-example)
  payment_data: record # Payment infomation. — shape: {giftCardMessages?: list, giftCards?: list, paymentSystems?: list, payments: list, updateStatus?: string}
  --sales-associate-data: record # Sales Associate information. — shape: {salesAssociateId?: string}
  shipping_data: record # Shipping information. — shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
]: any -> record<orderForm: string, orders: table<allowCancelation: bool, allowChangeSeller: bool, allowEdition: bool, checkedInPickupPointId: string, clientProfileData: record, creationDate: string, followUpEmail: string, hostName: string, isCheckedIn: bool, isCompleted: bool, isUserDataVisible: bool, itemMetadata: record, items: list, lastChange: string, merchantName: string, orderFormCreationDate: string, orderGroup: string, orderId: string, paymentData: record, ratesAndBenefitsData: record, roundingError: int, salesAssociateId: string, salesChannel: string, sellerOrderId: string, sellers: list, shippingData: record, state: string, storeId: string, timeZoneCreationDate: string, timeZoneLastChange: string, totals: list, userType: string, value: int>, transactionData: record<gatewayCallbackTemplatePath: string, merchantTransactions: list<record>, receiverUri: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CHECKOUT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CHECKOUT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/orders" $qp $auth.query)
  let req_body = {"clientProfileData": $client_profile_data, "items": $items, "marketingData": $marketing_data, "openTextField": $open_text_field, "paymentData": $payment_data, "salesAssociateData": $sales_associate_data, "shippingData": $shipping_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: ({"sc": $sc} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List pickup points by location
#
# GET /api/checkout/pub/pickup-points
# operationId: ListPickupPpointsByLocation
export def "checkout-pub-pickup-points list-ppoints-by-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --geo-coordinates: list<float> # Geocoordinates (first longitude, then latitude) around which to search for pickup points. If you use this type of search, do not pass postal and country codes. (default: [-47.924747467041016, -15.832582473754883])
  --postal-code: string # Postal code around which to search for pickup points. If you use this type of search, make sure to pass a `countryCode` and do not pass `geoCoordinates`. (default: 1234000)
  --country-code: string # Three letter country code refering to the `postalCode` field. Pass the country code only if you are searching pickup points by postal code. (default: BRA)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geoCoordinates" $geo_coordinates "multi") (serialize-qp "postalCode" $postal_code "scalar") (serialize-qp "countryCode" $country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/pickup-points" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"geoCoordinates": $geo_coordinates, "postalCode": $postal_code, "countryCode": $country_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get address by postal code
#
# GET /api/checkout/pub/postal-code/{countryCode}/{postalCode}
# operationId: GetAddressByPostalCode
export def "checkout-pub-postal-code get-address" [
  country_code: string
  postal_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($country_code | is-empty) { error make --unspanned { msg: "path parameter 'countryCode' must be non-empty" } }
  if ($postal_code | is-empty) { error make --unspanned { msg: "path parameter 'postalCode' must be non-empty" } }
  let full_url = (build-url $base ({country_code: (encode-path-segment $country_code), postal_code: (encode-path-segment $postal_code)} | format pattern "/api/checkout/pub/postal-code/{country_code}/{postal_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Get client profile by email
#
# GET /api/checkout/pub/profiles
# operationId: GetClientProfileByEmail
export def "checkout-pub-profiles get-client-by-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Client's email address to be searched. (default: clark.kent@examplemail.com)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, isComplete: bool, profileProvider: string, userProfile: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: string, profileErrorOnLoading: string, stateInscription: string, tradeName: string>, userProfileId: string> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/profiles" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"email": $email} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get sellers by region or address
#
# GET /api/checkout/pub/regions/{regionId}
# operationId: GetSellersByRegion
export def "checkout-pub-regions get-sellers" [
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Three letter country code refering to the `postalCode` field. (default: BRA)
  --postal-code: string # Postal code corresponding to the shopper's location. (default: 1234000)
  --geo-coordinates: list<float> # Geocoordinates (first longitude, semicolon, then latitude) corresponding to the shopper's location. (default: [-47.924747467041016, -15.832582473754883])
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<id: string, sellers: table<id: string, logo: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($region_id | is-empty) { error make --unspanned { msg: "path parameter 'regionId' must be non-empty" } }
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "postalCode" $postal_code "scalar") (serialize-qp "geoCoordinates" $geo_coordinates "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({region_id: (encode-path-segment $region_id)} | format pattern "/api/checkout/pub/regions/{region_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country, "postalCode": $postal_code, "geoCoordinates": $geo_coordinates} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get orderForm configuration
#
# GET /api/checkout/pvt/configuration/orderForm
# operationId: GetorderFormconfiguration
export def "checkout-pvt-configuration-order-form get-formconfiguration" [
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CHECKOUT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CHECKOUT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/orderForm" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Update orderForm configuration
#
# POST /api/checkout/pvt/configuration/orderForm
# operationId: UpdateorderFormconfiguration
# --apps item shape: {fields?: list<string>, id?: string, major?: int}
# --paymentConfiguration shape: {allowInstallmentsMerge?: bool, requiresAuthenticationForPreAuthorizedPaymentOption: bool}
# --taxConfiguration shape: {appId?: string, authorizationHeader?: string, url?: string}
export def "checkout-pvt-configuration-order-form update-formconfiguration" [
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --allow-manual-price: oneof<nothing, bool> # Allows the editing of SKU prices right in the cart. (nullable)
  --allow-multiple-deliveries: oneof<nothing, bool> # On the same purchase, allows the selection of items from multiple delivery channels. (nullable)
  --apps: list # Array of objects containing Apps configuration information. (nullable) — item shape: {fields?: list<string>, id?: string, major?: int}
  decimal_digits_precision: int # Number of price digits. (format: int32)
  --mask-first-purchase-data: oneof<nothing, bool> # Allows, on a first purchase, masking client's data. It could be useful when a shared cart is used and the client doesn't want to share its data.
  --max-number-of-white-label-sellers: int # Allows the input of a limit of white label sellers involved on the cart.
  minimum_quantity_accumulated_for_items: int # Minimum SKU quantity by cart. (format: int32)
  --minimum-value-accumulated: int # Minimum cart value. (nullable)
  payment_configuration: record # Payment Configuration object (e.g. {allowInstallmentsMerge: false, requiresAuthenticationForPreAuthorizedPaymentOption: false}) — shape: {allowInstallmentsMerge?: bool, requiresAuthenticationForPreAuthorizedPaymentOption: bool}
  --payment-system-to-check-first-installment: string # If you want to apply a first installment discount to a particular payment system, set this field to that payment system's ID. Learn more: [Configuring a discount for orders prepaid in full](https://help.vtex.com/en/tutorial/configurar-desconto-de-preco-a-vista--7Lfcj9Wb5dpYfA2gKkACIt). (e.g. 6)
  --recaptcha-validation: string # Configures reCAPTCHA validation for the account, defining in which situations the shopper will be prompted to validate a purchase with reCAPTCHA. Learn more about [reCAPTCHA validation for VTEX stores](https://help.vtex.com/tutorial/recaptcha-no-checkout--18Te3oDd7f4qcjKu9jhNzP) Possible values are: - `"never"`: no purchases are validated with reCAPTCHA. - `"always"`: every purchase is validated with reCAPTCHA. - `"vtexCriteria"`: only some purchases are validated with reCAPTCHA in order to minimize friction and improve shopping experience. VTEX’s algorithm determines which sessions are trustworthy and which should be validated with reCAPTCHA. This is the recommended option. (default: vtexCriteria)
  --tax-configuration: record # External tax service configuration. (nullable) — shape: {appId?: string, authorizationHeader?: string, url?: string}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CHECKOUT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CHECKOUT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/orderForm" $auth.query)
  let req_body = {"allowManualPrice": $allow_manual_price, "allowMultipleDeliveries": $allow_multiple_deliveries, "apps": $apps, "decimalDigitsPrecision": $decimal_digits_precision, "maskFirstPurchaseData": $mask_first_purchase_data, "maxNumberOfWhiteLabelSellers": $max_number_of_white_label_sellers, "minimumQuantityAccumulatedForItems": $minimum_quantity_accumulated_for_items, "minimumValueAccumulated": $minimum_value_accumulated, "paymentConfiguration": $payment_configuration, "paymentSystemToCheckFirstInstallment": $payment_system_to_check_first_installment, "recaptchaValidation": $recaptcha_validation, "taxConfiguration": $tax_configuration} | compact
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
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [204]
}

# Get window to change seller
#
# GET /api/checkout/pvt/configuration/window-to-change-seller
# operationId: GetWindowToChangeSeller
export def "checkout-pvt-configuration-window-to-change-seller get" [
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CHECKOUT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CHECKOUT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/window-to-change-seller" $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Update window to change seller
#
# POST /api/checkout/pvt/configuration/window-to-change-seller
# operationId: UpdateWindowToChangeSeller
export def "checkout-pvt-configuration-window-to-change-seller update" [
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
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  waiting_time: int # Number of days after order cancelation by a seller, during which another seller may be assigned to fulfill the order.
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CHECKOUT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CHECKOUT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/window-to-change-seller" $auth.query)
  let req_body = {"waitingTime": $waiting_time} | compact
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
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Remove all personal data
#
# GET /checkout/changeToAnonymousUser/{orderFormId}
# operationId: Removeallpersonaldata
export def "checkout-change-to-anonymous-user delete-allpersonaldata" [
  order_form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($order_form_id | is-empty) { error make --unspanned { msg: "path parameter 'orderFormId' must be non-empty" } }
  let full_url = (build-url $base ({order_form_id: (encode-path-segment $order_form_id)} | format pattern "/checkout/changeToAnonymousUser/{order_form_id}") $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
