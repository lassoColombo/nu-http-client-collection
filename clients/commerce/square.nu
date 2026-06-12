# Auto-generated client for Square v2.0
# Source: https://raw.githubusercontent.com/square/connect-api-specification/master/api.json
# Auth: --token flag or $env.SQUARE_TOKEN

const BASE_URL = "https://connect.squareup.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SQUARE_TOKEN | default "" }
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

def base-url-completer [] { ["https://connect.squareup.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-completer [] { ["ASC" "DESC"] }
def action-completer [] { ["CANCEL" "COMPLETE" "REFUND"] }
def sort-order-completer [] { ["ASC" "DESC"] }
def archived-state-completer [] { ["ARCHIVED_STATE_ALL" "ARCHIVED_STATE_ARCHIVED" "ARCHIVED_STATE_NOT_ARCHIVED"] }
def reference-type-completer [] { ["CASH_LOCAL" "FIRST_PARTY_INTEGRATION" "GIFT_CARD" "GIFT_CARD_MARKETPLACE" "INVOICE" "KIOSK" "LOCATION" "OAUTH_APPLICATION" "ONLINE_BOOKING_FLOW" "ONLINE_CHECKOUT" "ONLINE_SITE" "POINT_OF_SALE" "RECURRING_SUBSCRIPTION" "SQUARE_ASSISTANT" "UNKNOWN_TYPE"] }
def status-completer [] { ["ACTIVE" "INACTIVE"] }
def sort-field-completer [] { ["CREATED_AT" "DEFAULT"] }
def product-type-completer [] { ["TERMINAL_API"] }
def status-completer-1 [] { ["EXPIRED" "PAIRED" "UNKNOWN" "UNPAIRED"] }
def states-completer [] { ["ACCEPTED" "EVIDENCE_REQUIRED" "INQUIRY_CLOSED" "INQUIRY_EVIDENCE_REQUIRED" "INQUIRY_PROCESSING" "LOST" "PROCESSING" "WON"] }
def evidence-type-completer [] { ["AUTHORIZATION_DOCUMENTATION" "CANCELLATION_OR_REFUND_DOCUMENTATION" "CARDHOLDER_COMMUNICATION" "CARDHOLDER_INFORMATION" "DUPLICATE_CHARGE_DOCUMENTATION" "GENERIC_EVIDENCE" "ONLINE_OR_APP_ACCESS_LOG" "PRODUCT_OR_SERVICE_DESCRIPTION" "PROOF_OF_DELIVERY_DOCUMENTATION" "PURCHASE_ACKNOWLEDGEMENT" "REBUTTAL_EXPLANATION" "RECEIPT" "RELATED_TRANSACTION_DOCUMENTATION" "SERVICE_RECEIVED_DOCUMENTATION" "TRACKING_NUMBER"] }
def scheduled-shift-notification-audience-completer [] { ["AFFECTED" "ALL" "NONE"] }
def visibility-filter-completer [] { ["ALL" "READ" "READ_WRITE"] }
def status-completer-2 [] { ["ACTIVE" "CANCELED" "ENDED" "SCHEDULED"] }
def sort-field-completer-1 [] { ["CREATED_AT" "OFFLINE_CREATED_AT" "UPDATED_AT"] }
def status-completer-3 [] { ["FAILED" "PAID" "SENT"] }
def sort-field-completer-2 [] { ["CREATED_AT" "UPDATED_AT"] }
def resume-change-timing-completer [] { ["END_OF_BILLING_CYCLE" "IMMEDIATE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "oauth2-revoke RevokeToken" } } | get name | first)
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

# RevokeToken
#
# POST /oauth2/revoke
# operationId: RevokeToken
export def "oauth2-revoke RevokeToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # The Square-issued ID for your application, which is available on the **OAuth** page in the [Developer Dashboard](https://developer.squareup.com/apps). (nullable)
  --access-token: string # The access token of the merchant whose token you want to revoke. Do not provide a value for `merchant_id` if you provide this parameter. (nullable)
  --merchant-id: string # The ID of the merchant whose token you want to revoke. Do not provide a value for `access_token` if you provide this parameter. (nullable)
  --revoke-only-access-token: oneof<nothing, bool> # If `true`, terminate the given single access token, but do not terminate the entire authorization. Default: `false` (nullable)
]: any -> record<success: bool, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/revoke")
  let body = {client_id: $client_id, access_token: $access_token, merchant_id: $merchant_id, revoke_only_access_token: $revoke_only_access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ObtainToken
#
# POST /oauth2/token
# operationId: ObtainToken
export def "oauth2-token ObtainToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # The Square-issued ID of your application, which is available as the **Application ID** on the **OAuth** page in the [Developer Console](https://developer.squareup.com/apps).  Required for the code flow and PKCE flow for any grant type.
  --client-secret: string # The secret key for your application, which is available as the **Application secret** on the **OAuth** page in the [Developer Console](https://developer.squareup.com/apps).  Required for the code flow for any grant type. Don't confuse your client secret with your personal access token. (nullable)
  --code: string # The authorization code to exchange for an OAuth access token. This is the `code` value that Square sent to your redirect URL in the authorization response.  Required for the code flow and PKCE flow if `grant_type` is `authorization_code`. (nullable)
  --redirect-uri: string # The redirect URL for your application, which you registered as the **Redirect URL** on the **OAuth** page in the [Developer Console](https://developer.squareup.com/apps).  Required for the code flow and PKCE flow if `grant_type` is `authorization_code` and you provided the `redirect_uri` parameter in your authorization URL. (nullable)
  grant_type: string # The method used to obtain an OAuth access token. The request must include the credential that corresponds to the specified grant type. Valid values are: - `authorization_code` - Requires the `code` field. - `refresh_token` - Requires the `refresh_token` field. - `migration_token` - LEGACY for access tokens obtained using a Square API version prior to 2019-03-13. Requires the `migration_token` field.
  --refresh-token: string # A valid refresh token used to generate a new OAuth access token. This is a refresh token that was returned in a previous `ObtainToken` response.  Required for the code flow and PKCE flow if `grant_type` is `refresh_token`. (nullable)
  --migration-token: string # __LEGACY__ A valid access token (obtained using a Square API version prior to 2019-03-13) used to generate a new OAuth access token.  Required if `grant_type` is `migration_token`. For more information, see [Migrate to Using Refresh Tokens](https://developer.squareup.com/docs/oauth-api/migrate-to-refresh-tokens). (nullable)
  --scopes: list # The list of permissions that are explicitly requested for the access token. For example, ["MERCHANT_PROFILE_READ","PAYMENTS_READ","BANK_ACCOUNTS_READ"].  The returned access token is limited to the permissions that are the intersection of these requested permissions and those authorized by the provided `refresh_token`.  Optional for the code flow and PKCE flow if `grant_type` is `refresh_token`. (nullable)
  --short-lived: oneof<nothing, bool> # Indicates whether the returned access token should expire in 24 hours.  Optional for the code flow and PKCE flow for any grant type. The default value is `false`. (nullable)
  --code-verifier: string # The secret your application generated for the authorization request used to obtain the authorization code. This is the source of the `code_challenge` hash you provided in your authorization URL.  Required for the PKCE flow if `grant_type` is `authorization_code`. (nullable)
  --use-jwt: oneof<nothing, bool> # Indicates whether to use a JWT (JSON Web Token) as the OAuth access token. When set to `true`, the OAuth flow returns a JWT to your application, used in the same way as a regular token. The default value is `false`. (nullable)
]: any -> record<access_token: string, token_type: string, expires_at: string, merchant_id: string, subscription_id: string, plan_id: string, id_token: string, refresh_token: string, short_lived: bool, errors: table<category: string, code: string, detail: string, field: string>, refresh_token_expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/token")
  let body = {client_id: $client_id, client_secret: $client_secret, code: $code, redirect_uri: $redirect_uri, grant_type: $grant_type, refresh_token: $refresh_token, migration_token: $migration_token, scopes: $scopes, short_lived: $short_lived, code_verifier: $code_verifier, use_jwt: $use_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveTokenStatus
#
# POST /oauth2/token/status
# operationId: RetrieveTokenStatus
export def "oauth2-token-status RetrieveTokenStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scopes: list<string>, expires_at: string, client_id: string, merchant_id: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/token/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# V1ListOrders
#
# GET /v1/{location_id}/orders
# DEPRECATED
# operationId: V1ListOrders
@deprecated
export def "orders V1ListOrders" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order in which payments are listed in the response.
  --limit: int # The maximum number of payments to return in a single response. This value cannot exceed 200.
  --batch-token: string # A pagination cursor to retrieve the next set of results for your original query to the endpoint.
]: nothing -> table<errors: list<record>, id: string, buyer_email: string, recipient_name: string, recipient_phone_number: string, state: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, subtotal_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_discount_money: record<amount: int, currency_code: string>, created_at: string, updated_at: string, expires_at: string, payment_id: string, buyer_note: string, completed_note: string, refunded_note: string, canceled_note: string, tender: record<id: string, type: string, name: string, employee_id: string, receipt_url: string, card_brand: string, pan_suffix: string, entry_method: string, payment_note: string, total_money: record, tendered_money: record, tendered_at: string, settled_at: string, change_back_money: record, refunded_money: record, is_exchange: bool>, order_history: list<record>, promo_code: string, btc_receive_address: string, btc_price_satoshi: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "batch_token" $batch_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($location_id)/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# V1RetrieveOrder
#
# GET /v1/{location_id}/orders/{order_id}
# DEPRECATED
# operationId: V1RetrieveOrder
@deprecated
export def "orders V1RetrieveOrder" [
  location_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, id: string, buyer_email: string, recipient_name: string, recipient_phone_number: string, state: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, subtotal_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_discount_money: record<amount: int, currency_code: string>, created_at: string, updated_at: string, expires_at: string, payment_id: string, buyer_note: string, completed_note: string, refunded_note: string, canceled_note: string, tender: record<id: string, type: string, name: string, employee_id: string, receipt_url: string, card_brand: string, pan_suffix: string, entry_method: string, payment_note: string, total_money: record<amount: int, currency_code: string>, tendered_money: record<amount: int, currency_code: string>, tendered_at: string, settled_at: string, change_back_money: record<amount: int, currency_code: string>, refunded_money: record<amount: int, currency_code: string>, is_exchange: bool>, order_history: table<action: string, created_at: string>, promo_code: string, btc_receive_address: string, btc_price_satoshi: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($location_id)/orders/($order_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# V1UpdateOrder
#
# PUT /v1/{location_id}/orders/{order_id}
# DEPRECATED
# operationId: V1UpdateOrder
@deprecated
export def "orders V1UpdateOrder" [
  location_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  action: string@action-completer
  --shipped-tracking-number: string # The tracking number of the shipment associated with the order. Only valid if action is COMPLETE. (nullable)
  --completed-note: string # A merchant-specified note about the completion of the order. Only valid if action is COMPLETE. (nullable)
  --refunded-note: string # A merchant-specified note about the refunding of the order. Only valid if action is REFUND. (nullable)
  --canceled-note: string # A merchant-specified note about the canceling of the order. Only valid if action is CANCEL. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, id: string, buyer_email: string, recipient_name: string, recipient_phone_number: string, state: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, subtotal_money: record<amount: int, currency_code: string>, total_shipping_money: record<amount: int, currency_code: string>, total_tax_money: record<amount: int, currency_code: string>, total_price_money: record<amount: int, currency_code: string>, total_discount_money: record<amount: int, currency_code: string>, created_at: string, updated_at: string, expires_at: string, payment_id: string, buyer_note: string, completed_note: string, refunded_note: string, canceled_note: string, tender: record<id: string, type: string, name: string, employee_id: string, receipt_url: string, card_brand: string, pan_suffix: string, entry_method: string, payment_note: string, total_money: record<amount: int, currency_code: string>, tendered_money: record<amount: int, currency_code: string>, tendered_at: string, settled_at: string, change_back_money: record<amount: int, currency_code: string>, refunded_money: record<amount: int, currency_code: string>, is_exchange: bool>, order_history: table<action: string, created_at: string>, promo_code: string, btc_receive_address: string, btc_price_satoshi: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($location_id)/orders/($order_id)")
  let body = {action: $action, shipped_tracking_number: $shipped_tracking_number, completed_note: $completed_note, refunded_note: $refunded_note, canceled_note: $canceled_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RegisterDomain
#
# POST /v2/apple-pay/domains
# operationId: RegisterDomain
export def "apple-pay-domains RegisterDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain_name: string # A domain name as described in RFC-1034 that will be registered with ApplePay.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apple-pay/domains")
  let body = {domain_name: $domain_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListBankAccounts
#
# GET /v2/bank-accounts
# operationId: ListBankAccounts
export def "bank-accounts ListBankAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The pagination cursor returned by a previous call to this endpoint. Use it in the next `ListBankAccounts` request to retrieve the next set of results.  See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
  --limit: int # Upper limit on the number of bank accounts to return in the response. Currently, 1000 is the largest supported limit. You can specify a limit of up to 1000 bank accounts. This is also the default limit.
  --location-id: string # Location ID. You can specify this optional filter to retrieve only the linked bank accounts belonging to a specific location.
  --customer-id: string # Customer ID. You can specify this optional filter to retrieve only the linked bank accounts belonging to a specific customer.
]: nothing -> record<bank_accounts: table<id: string, account_number_suffix: string, country: string, currency: string, account_type: string, holder_name: string, primary_bank_identification_number: string, secondary_bank_identification_number: string, debit_mandate_reference_id: string, reference_id: string, location_id: string, status: string, creditable: bool, debitable: bool, fingerprint: string, version: int, bank_name: string, customer_id: string>, errors: table<category: string, code: string, detail: string, field: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "customer_id" $customer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bank-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateBankAccount
#
# POST /v2/bank-accounts
# operationId: CreateBankAccount
export def "bank-accounts CreateBankAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # Unique ID. For more information, see the [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  source_id: string # The ID of the source that represents the bank account information to be stored. This field accepts the payment token created by WebSDK
  --customer-id: string # The ID of the customer associated with the bank account to be stored.
]: any -> record<bank_account: record<id: string, account_number_suffix: string, country: string, currency: string, account_type: string, holder_name: string, primary_bank_identification_number: string, secondary_bank_identification_number: string, debit_mandate_reference_id: string, reference_id: string, location_id: string, status: string, creditable: bool, debitable: bool, fingerprint: string, version: int, bank_name: string, customer_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bank-accounts")
  let body = {idempotency_key: $idempotency_key, source_id: $source_id, customer_id: $customer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetBankAccountByV1Id
#
# GET /v2/bank-accounts/by-v1-id/{v1_bank_account_id}
# operationId: GetBankAccountByV1Id
export def "bank-accounts-by-v1-id GetBankAccountByV1Id" [
  v1_bank_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, bank_account: record<id: string, account_number_suffix: string, country: string, currency: string, account_type: string, holder_name: string, primary_bank_identification_number: string, secondary_bank_identification_number: string, debit_mandate_reference_id: string, reference_id: string, location_id: string, status: string, creditable: bool, debitable: bool, fingerprint: string, version: int, bank_name: string, customer_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bank-accounts/by-v1-id/($v1_bank_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetBankAccount
#
# GET /v2/bank-accounts/{bank_account_id}
# operationId: GetBankAccount
export def "bank-accounts GetBankAccount" [
  bank_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<bank_account: record<id: string, account_number_suffix: string, country: string, currency: string, account_type: string, holder_name: string, primary_bank_identification_number: string, secondary_bank_identification_number: string, debit_mandate_reference_id: string, reference_id: string, location_id: string, status: string, creditable: bool, debitable: bool, fingerprint: string, version: int, bank_name: string, customer_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bank-accounts/($bank_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DisableBankAccount
#
# POST /v2/bank-accounts/{bank_account_id}/disable
# operationId: DisableBankAccount
export def "bank-accounts-disable DisableBankAccount" [
  bank_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<bank_account: record<id: string, account_number_suffix: string, country: string, currency: string, account_type: string, holder_name: string, primary_bank_identification_number: string, secondary_bank_identification_number: string, debit_mandate_reference_id: string, reference_id: string, location_id: string, status: string, creditable: bool, debitable: bool, fingerprint: string, version: int, bank_name: string, customer_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bank-accounts/($bank_account_id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListBookings
#
# GET /v2/bookings
# operationId: ListBookings
export def "bookings ListBookings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results per page to return in a paged response.
  --cursor: string # The pagination cursor from the preceding response to return the next page of the results. Do not set this when retrieving the first page of the results.
  --customer-id: string # The [customer](entity:Customer) for whom to retrieve bookings. If this is not set, bookings for all customers are retrieved.
  --team-member-id: string # The team member for whom to retrieve bookings. If this is not set, bookings of all members are retrieved.
  --location-id: string # The location for which to retrieve bookings. If this is not set, all locations' bookings are retrieved.
  --start-at-min: string # The RFC 3339 timestamp specifying the earliest of the start time. If this is not set, the current time is used.
  --start-at-max: string # The RFC 3339 timestamp specifying the latest of the start time. If this is not set, the time of 31 days after `start_at_min` is used.
]: nothing -> record<bookings: table<id: string, version: int, status: string, created_at: string, updated_at: string, start_at: string, location_id: string, customer_id: string, customer_note: string, seller_note: string, appointment_segments: list, transition_time_minutes: int, all_day: bool, location_type: string, creator_details: record, source: string, address: record>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "team_member_id" $team_member_id "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "start_at_min" $start_at_min "scalar") (serialize-qp "start_at_max" $start_at_max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bookings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateBooking
#
# POST /v2/bookings
# operationId: CreateBooking
# --booking shape: {version?: int, status?: "PENDING"|"CANCELLED_BY_CUSTOMER"|"CANCELLED_BY_SELLER"|"DECLINED"|"ACCEPTED"|"NO_SHOW", start_at?: string, location_id?: string, customer_id?: string, customer_note?: string, seller_note?: string, appointment_segments?: list, location_type?: "BUSINESS_LOCATION"|"CUSTOMER_LOCATION"|"PHONE", creator_details?: record, source?: "FIRST_PARTY_MERCHANT"|"FIRST_PARTY_BUYER"|"THIRD_PARTY_BUYER"|"API", address?: record}
export def "bookings CreateBooking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique key to make this request an idempotent operation.
  booking: record # Represents a booking as a time-bound service contract for a seller's staff member to provide a specified service at a given location to a requesting customer in one or more appointment segments. — shape: {version?: int, status?: "PENDING"|"CANCELLED_BY_CUSTOMER"|"CANCELLED_BY_SELLER"|"DECLINED"|"ACCEPTED"|"NO_SHOW", start_at?: string, location_id?: string, customer_id?: string, customer_note?: string, seller_note?: string, appointment_segments?: list, location_type?: "BUSINESS_LOCATION"|"CUSTOMER_LOCATION"|"PHONE", creator_details?: record, source?: "FIRST_PARTY_MERCHANT"|"FIRST_PARTY_BUYER"|"THIRD_PARTY_BUYER"|"API", address?: record}
]: any -> record<booking: record<id: string, version: int, status: string, created_at: string, updated_at: string, start_at: string, location_id: string, customer_id: string, customer_note: string, seller_note: string, appointment_segments: list<record>, transition_time_minutes: int, all_day: bool, location_type: string, creator_details: record<creator_type: string, team_member_id: string, customer_id: string>, source: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings")
  let body = {idempotency_key: $idempotency_key, booking: $booking} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchAvailability
#
# POST /v2/bookings/availability/search
# operationId: SearchAvailability
# --query shape: {filter: record}
export def "bookings-availability-search SearchAvailability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # The query used to search for buyer-accessible availabilities of bookings. — shape: {filter: record}
]: any -> record<availabilities: table<start_at: string, location_id: string, appointment_segments: list>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/availability/search")
  let body = {query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkRetrieveBookings
#
# POST /v2/bookings/bulk-retrieve
# operationId: BulkRetrieveBookings
export def "bookings-bulk-retrieve BulkRetrieveBookings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  booking_ids: list # A non-empty list of [Booking](entity:Booking) IDs specifying bookings to retrieve.
]: any -> record<bookings: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/bulk-retrieve")
  let body = {booking_ids: $booking_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveBusinessBookingProfile
#
# GET /v2/bookings/business-booking-profile
# operationId: RetrieveBusinessBookingProfile
export def "bookings-business-booking-profile RetrieveBusinessBookingProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<business_booking_profile: record<seller_id: string, created_at: string, booking_enabled: bool, customer_timezone_choice: string, booking_policy: string, allow_user_cancel: bool, business_appointment_settings: record<location_types: list, alignment_time: string, min_booking_lead_time_seconds: int, max_booking_lead_time_seconds: int, any_team_member_booking_enabled: bool, multiple_service_booking_enabled: bool, max_appointments_per_day_limit_type: string, max_appointments_per_day_limit: int, cancellation_window_seconds: int, cancellation_fee_money: record, cancellation_policy: string, cancellation_policy_text: string, skip_booking_flow_staff_selection: bool>, support_seller_level_writes: bool>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/business-booking-profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListBookingCustomAttributeDefinitions
#
# GET /v2/bookings/custom-attribute-definitions
# operationId: ListBookingCustomAttributeDefinitions
export def "bookings-custom-attribute-definitions ListBookingCustomAttributeDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory. The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100. The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<custom_attribute_definitions: table<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bookings/custom-attribute-definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateBookingCustomAttributeDefinition
#
# POST /v2/bookings/custom-attribute-definitions
# operationId: CreateBookingCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "bookings-custom-attribute-definitions CreateBookingCustomAttributeDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/custom-attribute-definitions")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteBookingCustomAttributeDefinition
#
# DELETE /v2/bookings/custom-attribute-definitions/{key}
# operationId: DeleteBookingCustomAttributeDefinition
export def "bookings-custom-attribute-definitions DeleteBookingCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/custom-attribute-definitions/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveBookingCustomAttributeDefinition
#
# GET /v2/bookings/custom-attribute-definitions/{key}
# operationId: RetrieveBookingCustomAttributeDefinition
export def "bookings-custom-attribute-definitions RetrieveBookingCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # The current version of the custom attribute definition, which is used for strongly consistent reads to guarantee that you receive the most up-to-date data. When included in the request, Square returns the specified version or a higher version if one exists. If the specified version is higher than the current version, Square returns a `BAD_REQUEST` error.
]: nothing -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/bookings/custom-attribute-definitions/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateBookingCustomAttributeDefinition
#
# PUT /v2/bookings/custom-attribute-definitions/{key}
# operationId: UpdateBookingCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "bookings-custom-attribute-definitions UpdateBookingCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/custom-attribute-definitions/($key)")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkDeleteBookingCustomAttributes
#
# POST /v2/bookings/custom-attributes/bulk-delete
# operationId: BulkDeleteBookingCustomAttributes
export def "bookings-custom-attributes-bulk-delete BulkDeleteBookingCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # A map containing 1 to 25 individual Delete requests. For each request, provide an arbitrary ID that is unique for this `BulkDeleteBookingCustomAttributes` request and the information needed to delete a custom attribute.
]: any -> record<values: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/custom-attributes/bulk-delete")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkUpsertBookingCustomAttributes
#
# POST /v2/bookings/custom-attributes/bulk-upsert
# operationId: BulkUpsertBookingCustomAttributes
export def "bookings-custom-attributes-bulk-upsert BulkUpsertBookingCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # A map containing 1 to 25 individual upsert requests. For each request, provide an arbitrary ID that is unique for this `BulkUpsertBookingCustomAttributes` request and the information needed to create or update a custom attribute.
]: any -> record<values: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/custom-attributes/bulk-upsert")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListLocationBookingProfiles
#
# GET /v2/bookings/location-booking-profiles
# operationId: ListLocationBookingProfiles
export def "bookings-location-booking-profiles ListLocationBookingProfiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return in a paged response.
  --cursor: string # The pagination cursor from the preceding response to return the next page of the results. Do not set this when retrieving the first page of the results.
]: nothing -> record<location_booking_profiles: table<location_id: string, booking_site_url: string, online_booking_enabled: bool>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bookings/location-booking-profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveLocationBookingProfile
#
# GET /v2/bookings/location-booking-profiles/{location_id}
# operationId: RetrieveLocationBookingProfile
export def "bookings-location-booking-profiles RetrieveLocationBookingProfile" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<location_booking_profile: record<location_id: string, booking_site_url: string, online_booking_enabled: bool>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/location-booking-profiles/($location_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListTeamMemberBookingProfiles
#
# GET /v2/bookings/team-member-booking-profiles
# operationId: ListTeamMemberBookingProfiles
export def "bookings-team-member-booking-profiles ListTeamMemberBookingProfiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookable-only: oneof<nothing, bool> # Indicates whether to include only bookable team members in the returned result (`true`) or not (`false`). (default: false)
  --limit: int # The maximum number of results to return in a paged response.
  --cursor: string # The pagination cursor from the preceding response to return the next page of the results. Do not set this when retrieving the first page of the results.
  --location-id: string # Indicates whether to include only team members enabled at the given location in the returned result.
]: nothing -> record<team_member_booking_profiles: table<team_member_id: string, description: string, display_name: string, is_bookable: bool, profile_image_url: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookable_only" $bookable_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bookings/team-member-booking-profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# BulkRetrieveTeamMemberBookingProfiles
#
# POST /v2/bookings/team-member-booking-profiles/bulk-retrieve
# operationId: BulkRetrieveTeamMemberBookingProfiles
export def "bookings-team-member-booking-profiles-bulk-retrieve BulkRetrieveTeamMemberBookingProfiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  team_member_ids: list # A non-empty list of IDs of team members whose booking profiles you want to retrieve.
]: any -> record<team_member_booking_profiles: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings/team-member-booking-profiles/bulk-retrieve")
  let body = {team_member_ids: $team_member_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveTeamMemberBookingProfile
#
# GET /v2/bookings/team-member-booking-profiles/{team_member_id}
# operationId: RetrieveTeamMemberBookingProfile
export def "bookings-team-member-booking-profiles RetrieveTeamMemberBookingProfile" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<team_member_booking_profile: record<team_member_id: string, description: string, display_name: string, is_bookable: bool, profile_image_url: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/team-member-booking-profiles/($team_member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveBooking
#
# GET /v2/bookings/{booking_id}
# operationId: RetrieveBooking
export def "bookings RetrieveBooking" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<booking: record<id: string, version: int, status: string, created_at: string, updated_at: string, start_at: string, location_id: string, customer_id: string, customer_note: string, seller_note: string, appointment_segments: list<record>, transition_time_minutes: int, all_day: bool, location_type: string, creator_details: record<creator_type: string, team_member_id: string, customer_id: string>, source: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($booking_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateBooking
#
# PUT /v2/bookings/{booking_id}
# operationId: UpdateBooking
# --booking shape: {version?: int, status?: "PENDING"|"CANCELLED_BY_CUSTOMER"|"CANCELLED_BY_SELLER"|"DECLINED"|"ACCEPTED"|"NO_SHOW", start_at?: string, location_id?: string, customer_id?: string, customer_note?: string, seller_note?: string, appointment_segments?: list, location_type?: "BUSINESS_LOCATION"|"CUSTOMER_LOCATION"|"PHONE", creator_details?: record, source?: "FIRST_PARTY_MERCHANT"|"FIRST_PARTY_BUYER"|"THIRD_PARTY_BUYER"|"API", address?: record}
export def "bookings UpdateBooking" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique key to make this request an idempotent operation. (nullable)
  booking: record # Represents a booking as a time-bound service contract for a seller's staff member to provide a specified service at a given location to a requesting customer in one or more appointment segments. — shape: {version?: int, status?: "PENDING"|"CANCELLED_BY_CUSTOMER"|"CANCELLED_BY_SELLER"|"DECLINED"|"ACCEPTED"|"NO_SHOW", start_at?: string, location_id?: string, customer_id?: string, customer_note?: string, seller_note?: string, appointment_segments?: list, location_type?: "BUSINESS_LOCATION"|"CUSTOMER_LOCATION"|"PHONE", creator_details?: record, source?: "FIRST_PARTY_MERCHANT"|"FIRST_PARTY_BUYER"|"THIRD_PARTY_BUYER"|"API", address?: record}
]: any -> record<booking: record<id: string, version: int, status: string, created_at: string, updated_at: string, start_at: string, location_id: string, customer_id: string, customer_note: string, seller_note: string, appointment_segments: list<record>, transition_time_minutes: int, all_day: bool, location_type: string, creator_details: record<creator_type: string, team_member_id: string, customer_id: string>, source: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($booking_id)")
  let body = {idempotency_key: $idempotency_key, booking: $booking} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CancelBooking
#
# POST /v2/bookings/{booking_id}/cancel
# operationId: CancelBooking
export def "bookings-cancel CancelBooking" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique key to make this request an idempotent operation. (nullable)
  --booking-version: int # The revision number for the booking used for optimistic concurrency. (nullable)
]: any -> record<booking: record<id: string, version: int, status: string, created_at: string, updated_at: string, start_at: string, location_id: string, customer_id: string, customer_note: string, seller_note: string, appointment_segments: list<record>, transition_time_minutes: int, all_day: bool, location_type: string, creator_details: record<creator_type: string, team_member_id: string, customer_id: string>, source: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($booking_id)/cancel")
  let body = {idempotency_key: $idempotency_key, booking_version: $booking_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListBookingCustomAttributes
#
# GET /v2/bookings/{booking_id}/custom-attributes
# operationId: ListBookingCustomAttributes
export def "bookings-custom-attributes ListBookingCustomAttributes" [
  booking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory. The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100. The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --with-definitions: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of each custom attribute. Set this parameter to `true` to get the name and description of each custom attribute, information about the data type, or other definition details. The default value is `false`. (default: false)
]: nothing -> record<custom_attributes: table<key: string, value: any, version: int, visibility: string, definition: record, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "with_definitions" $with_definitions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/bookings/($booking_id)/custom-attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeleteBookingCustomAttribute
#
# DELETE /v2/bookings/{booking_id}/custom-attributes/{key}
# operationId: DeleteBookingCustomAttribute
export def "bookings-custom-attributes DeleteBookingCustomAttribute" [
  booking_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($booking_id)/custom-attributes/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveBookingCustomAttribute
#
# GET /v2/bookings/{booking_id}/custom-attributes/{key}
# operationId: RetrieveBookingCustomAttribute
export def "bookings-custom-attributes RetrieveBookingCustomAttribute" [
  booking_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-definition: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of the custom attribute. Set this parameter to `true` to get the name and description of the custom attribute, information about the data type, or other definition details. The default value is `false`. (default: false)
  --version: int # The current version of the custom attribute, which is used for strongly consistent reads to guarantee that you receive the most up-to-date data. When included in the request, Square returns the specified version or a higher version if one exists. If the specified version is higher than the current version, Square returns a `BAD_REQUEST` error.
]: nothing -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_definition" $with_definition "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/bookings/($booking_id)/custom-attributes/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpsertBookingCustomAttribute
#
# PUT /v2/bookings/{booking_id}/custom-attributes/{key}
# operationId: UpsertBookingCustomAttribute
# --custom_attribute shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
export def "bookings-custom-attributes UpsertBookingCustomAttribute" [
  booking_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute: record # A custom attribute value. Each custom attribute value has a corresponding `CustomAttributeDefinition` object. — shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($booking_id)/custom-attributes/($key)")
  let body = {custom_attribute: $custom_attribute, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListCards
#
# GET /v2/cards
# operationId: ListCards
export def "cards ListCards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query.  See [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination) for more information.
  --customer-id: string # Limit results to cards associated with the customer supplied. By default, all cards owned by the merchant are returned.
  --include-disabled: oneof<nothing, bool> # Includes disabled cards. By default, all enabled cards owned by the merchant are returned. (default: false)
  --reference-id: string # Limit results to cards associated with the reference_id supplied.
  --sort-order: string@sort-order-completer # Sorts the returned list by when the card was created with the specified order. This field defaults to ASC.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, cards: table<id: string, card_brand: string, last_4: string, exp_month: int, exp_year: int, cardholder_name: string, billing_address: record, fingerprint: string, customer_id: string, merchant_id: string, reference_id: string, enabled: bool, card_type: string, prepaid_type: string, bin: string, created_at: string, disabled_at: string, version: int, card_co_brand: string, issuer_alert: string, issuer_alert_at: string, hsa_fsa: bool>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "include_disabled" $include_disabled "scalar") (serialize-qp "reference_id" $reference_id "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateCard
#
# POST /v2/cards
# operationId: CreateCard
# --card shape: {card_brand?: "OTHER_BRAND"|"VISA"|"MASTERCARD"|"AMERICAN_EXPRESS"|"DISCOVER"|"DISCOVER_DINERS"|"JCB"|"CHINA_UNIONPAY"|"SQUARE_GIFT_CARD"|"SQUARE_CAPITAL_CARD"|"INTERAC"|"EFTPOS"|"FELICA"|"EBT", exp_month?: int, exp_year?: int, cardholder_name?: string, billing_address?: record, customer_id?: string, reference_id?: string, card_type?: "UNKNOWN_CARD_TYPE"|"CREDIT"|"DEBIT", prepaid_type?: "UNKNOWN_PREPAID_TYPE"|"NOT_PREPAID"|"PREPAID", version?: int, card_co_brand?: "UNKNOWN"|"AFTERPAY"|"CLEARPAY", issuer_alert?: "ISSUER_ALERT_CARD_CLOSED"}
export def "cards CreateCard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this CreateCard request. Keys can be any valid string and must be unique for every request.  Max: 45 characters  See [Idempotency keys](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) for more information.
  source_id: string # The ID of the source which represents the card information to be stored. This can be a card nonce or a payment id.
  --verification-token: string # An identifying token generated by [Payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity.  See the [SCA Overview](https://developer.squareup.com/docs/sca-overview).
  card: record # Represents the payment details of a card to be used for payments. These details are determined by the payment token generated by Web Payments SDK. — shape: {card_brand?: "OTHER_BRAND"|"VISA"|"MASTERCARD"|"AMERICAN_EXPRESS"|"DISCOVER"|"DISCOVER_DINERS"|"JCB"|"CHINA_UNIONPAY"|"SQUARE_GIFT_CARD"|"SQUARE_CAPITAL_CARD"|"INTERAC"|"EFTPOS"|"FELICA"|"EBT", exp_month?: int, exp_year?: int, cardholder_name?: string, billing_address?: record, customer_id?: string, reference_id?: string, card_type?: "UNKNOWN_CARD_TYPE"|"CREDIT"|"DEBIT", prepaid_type?: "UNKNOWN_PREPAID_TYPE"|"NOT_PREPAID"|"PREPAID", version?: int, card_co_brand?: "UNKNOWN"|"AFTERPAY"|"CLEARPAY", issuer_alert?: "ISSUER_ALERT_CARD_CLOSED"}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, card: record<id: string, card_brand: string, last_4: string, exp_month: int, exp_year: int, cardholder_name: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, fingerprint: string, customer_id: string, merchant_id: string, reference_id: string, enabled: bool, card_type: string, prepaid_type: string, bin: string, created_at: string, disabled_at: string, version: int, card_co_brand: string, issuer_alert: string, issuer_alert_at: string, hsa_fsa: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/cards")
  let body = {idempotency_key: $idempotency_key, source_id: $source_id, verification_token: $verification_token, card: $card} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveCard
#
# GET /v2/cards/{card_id}
# operationId: RetrieveCard
export def "cards RetrieveCard" [
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, card: record<id: string, card_brand: string, last_4: string, exp_month: int, exp_year: int, cardholder_name: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, fingerprint: string, customer_id: string, merchant_id: string, reference_id: string, enabled: bool, card_type: string, prepaid_type: string, bin: string, created_at: string, disabled_at: string, version: int, card_co_brand: string, issuer_alert: string, issuer_alert_at: string, hsa_fsa: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/cards/($card_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DisableCard
#
# POST /v2/cards/{card_id}/disable
# operationId: DisableCard
export def "cards-disable DisableCard" [
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, card: record<id: string, card_brand: string, last_4: string, exp_month: int, exp_year: int, cardholder_name: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, fingerprint: string, customer_id: string, merchant_id: string, reference_id: string, enabled: bool, card_type: string, prepaid_type: string, bin: string, created_at: string, disabled_at: string, version: int, card_co_brand: string, issuer_alert: string, issuer_alert_at: string, hsa_fsa: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/cards/($card_id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListCashDrawerShifts
#
# GET /v2/cash-drawers/shifts
# operationId: ListCashDrawerShifts
export def "cash-drawers-shifts ListCashDrawerShifts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-id: string # The ID of the location to query for a list of cash drawer shifts.
  --sort-order: string@sort-order-completer # The order in which cash drawer shifts are listed in the response, based on their opened_at field. Default value: ASC
  --begin-time: string # The inclusive start time of the query on opened_at, in ISO 8601 format.
  --end-time: string # The exclusive end date of the query on opened_at, in ISO 8601 format.
  --limit: int # Number of cash drawer shift events in a page of results (200 by default, 1000 max).
  --cursor: string # Opaque cursor for fetching the next page of results.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, cash_drawer_shifts: table<id: string, state: string, opened_at: string, ended_at: string, closed_at: string, description: string, opened_cash_money: record, expected_cash_money: record, closed_cash_money: record, created_at: string, updated_at: string, location_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cash-drawers/shifts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveCashDrawerShift
#
# GET /v2/cash-drawers/shifts/{shift_id}
# operationId: RetrieveCashDrawerShift
export def "cash-drawers-shifts RetrieveCashDrawerShift" [
  shift_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-id: string # The ID of the location to retrieve cash drawer shifts from.
]: nothing -> record<cash_drawer_shift: record<id: string, state: string, opened_at: string, ended_at: string, closed_at: string, description: string, opened_cash_money: record<amount: int, currency: string>, cash_payment_money: record<amount: int, currency: string>, cash_refunds_money: record<amount: int, currency: string>, cash_paid_in_money: record<amount: int, currency: string>, cash_paid_out_money: record<amount: int, currency: string>, expected_cash_money: record<amount: int, currency: string>, closed_cash_money: record<amount: int, currency: string>, device: record<id: string, name: string>, created_at: string, updated_at: string, location_id: string, team_member_ids: list<string>, opening_team_member_id: string, ending_team_member_id: string, closing_team_member_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/cash-drawers/shifts/($shift_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListCashDrawerShiftEvents
#
# GET /v2/cash-drawers/shifts/{shift_id}/events
# operationId: ListCashDrawerShiftEvents
export def "cash-drawers-shifts-events ListCashDrawerShiftEvents" [
  shift_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-id: string # The ID of the location to list cash drawer shifts for.
  --limit: int # Number of resources to be returned in a page of results (200 by default, 1000 max).
  --cursor: string # Opaque cursor for fetching the next page of results.
]: nothing -> record<cursor: string, errors: table<category: string, code: string, detail: string, field: string>, cash_drawer_shift_events: table<id: string, event_type: string, event_money: record, created_at: string, description: string, team_member_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/cash-drawers/shifts/($shift_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# BatchDeleteCatalogObjects
#
# POST /v2/catalog/batch-delete
# operationId: BatchDeleteCatalogObjects
export def "catalog-batch-delete BatchDeleteCatalogObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  object_ids: list # The IDs of the CatalogObjects to be deleted. When an object is deleted, other objects in the graph that depend on that object will be deleted as well (for example, deleting a CatalogItem will delete its CatalogItemVariation.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, deleted_object_ids: list<string>, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/batch-delete")
  let body = {object_ids: $object_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BatchRetrieveCatalogObjects
#
# POST /v2/catalog/batch-retrieve
# operationId: BatchRetrieveCatalogObjects
export def "catalog-batch-retrieve BatchRetrieveCatalogObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  object_ids: list # The IDs of the CatalogObjects to be retrieved.
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested objects. Related objects are defined as any objects referenced by ID by the results in the `objects` field of the response. These objects are put in the `related_objects` field. Setting this to `true` is helpful when the objects are needed for immediate display to a user. This process only goes one level deep. Objects referenced by the related objects will not be included. For example,  if the `objects` field of the response contains a CatalogItem, its associated CatalogCategory objects, CatalogTax objects, CatalogImage objects and CatalogModifierLists will be returned in the `related_objects` field of the response. If the `objects` field of the response contains a CatalogItemVariation, its parent CatalogItem will be returned in the `related_objects` field of the response.  Default value: `false` (nullable)
  --catalog-version: int # The specific version of the catalog objects to be included in the response.  This allows you to retrieve historical versions of objects. The specified version value is matched against the [CatalogObject](entity:CatalogObject)s' `version` attribute. If not included, results will be from the current version of the catalog. (nullable, format: int64)
  --include-deleted-objects: oneof<nothing, bool> # Indicates whether to include (`true`) or not (`false`) in the response deleted objects, namely, those with the `is_deleted` attribute set to `true`. (nullable)
  --include-category-path-to-root: oneof<nothing, bool> # Specifies whether or not to include the `path_to_root` list for each returned category instance. The `path_to_root` list consists of `CategoryPathToRootNode` objects and specifies the path that starts with the immediate parent category of the returned category and ends with its root category. If the returned category is a top-level category, the `path_to_root` list is empty and is not returned in the response payload. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, objects: table<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list, present_at_all_locations: bool, present_at_location_ids: list, absent_at_location_ids: list, item_data: record, category_data: record, item_variation_data: record, tax_data: record, discount_data: record, modifier_list_data: record, modifier_data: record, time_period_data: record, product_set_data: record, pricing_rule_data: record, image_data: record, measurement_unit_data: record, subscription_plan_data: record, item_option_data: record, item_option_value_data: record, custom_attribute_definition_data: record, quick_amounts_settings_data: record, subscription_plan_variation_data: record, availability_period_data: record>, related_objects: table<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list, present_at_all_locations: bool, present_at_location_ids: list, absent_at_location_ids: list, item_data: record, category_data: record, item_variation_data: record, tax_data: record, discount_data: record, modifier_list_data: record, modifier_data: record, time_period_data: record, product_set_data: record, pricing_rule_data: record, image_data: record, measurement_unit_data: record, subscription_plan_data: record, item_option_data: record, item_option_value_data: record, custom_attribute_definition_data: record, quick_amounts_settings_data: record, subscription_plan_variation_data: record, availability_period_data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/batch-retrieve")
  let body = {object_ids: $object_ids, include_related_objects: $include_related_objects, catalog_version: $catalog_version, include_deleted_objects: $include_deleted_objects, include_category_path_to_root: $include_category_path_to_root} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BatchUpsertCatalogObjects
#
# POST /v2/catalog/batch-upsert
# operationId: BatchUpsertCatalogObjects
# --batches item shape: {objects: list}
export def "catalog-batch-upsert BatchUpsertCatalogObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A value you specify that uniquely identifies this request among all your requests. A common way to create a valid idempotency key is to use a Universally unique identifier (UUID).  If you're unsure whether a particular request was successful, you can reattempt it with the same idempotency key without worrying about creating duplicate objects.  See [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) for more information.
  batches: list # A batch of CatalogObjects to be inserted/updated atomically. The objects within a batch will be inserted in an all-or-nothing fashion, i.e., if an error occurs attempting to insert or update an object within a batch, the entire batch will be rejected. However, an error in one batch will not affect other batches within the same request.  For each object, its `updated_at` field is ignored and replaced with a current [timestamp](https://developer.squareup.com/docs/build-basics/working-with-dates), and its `is_deleted` field must not be set to `true`.  To modify an existing object, supply its ID. To create a new object, use an ID starting with `#`. These IDs may be used to create relationships between an object and attributes of other objects that reference it. For example, you can create a CatalogItem with ID `#ABC` and a CatalogItemVariation with its `item_id` attribute set to `#ABC` in order to associate the CatalogItemVariation with its parent CatalogItem.  Any `#`-prefixed IDs are valid only within a single atomic batch, and will be replaced by server-generated IDs.  Each batch may contain up to 1,000 objects. The total number of objects across all batches for a single request may not exceed 10,000. If either of these limits is violated, an error will be returned and no objects will be inserted or updated. — item shape: {objects: list}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, objects: table<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list, present_at_all_locations: bool, present_at_location_ids: list, absent_at_location_ids: list, item_data: record, category_data: record, item_variation_data: record, tax_data: record, discount_data: record, modifier_list_data: record, modifier_data: record, time_period_data: record, product_set_data: record, pricing_rule_data: record, image_data: record, measurement_unit_data: record, subscription_plan_data: record, item_option_data: record, item_option_value_data: record, custom_attribute_definition_data: record, quick_amounts_settings_data: record, subscription_plan_variation_data: record, availability_period_data: record>, updated_at: string, id_mappings: table<client_object_id: string, object_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/batch-upsert")
  let body = {idempotency_key: $idempotency_key, batches: $batches} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateCatalogImage
#
# POST /v2/catalog/images
# operationId: CreateCatalogImage
# --request shape: {idempotency_key: string, object_id?: string, image: record, is_primary?: bool}
export def "catalog-images CreateCatalogImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request: record # e.g. {idempotency_key: 528dea59-7bfb-43c1-bd48-4a6bba7dd61f86, image: {id: #TEMP_ID, image_data: {caption: A picture of a cup of coffee}, type: IMAGE}, object_id: ND6EA5AAJEO5WL3JNNIAQA32} — shape: {idempotency_key: string, object_id?: string, image: record, is_primary?: bool}
  --image-file: string # format: binary
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, image: record<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list<record>, present_at_all_locations: bool, present_at_location_ids: list<string>, absent_at_location_ids: list<string>, item_data: record<name: string, description: string, abbreviation: string, label_color: string, is_taxable: bool, category_id: string, buyer_facing_name: string, tax_ids: list, modifier_list_info: list, variations: list, product_type: string, skip_modifier_screen: bool, item_options: list, ecom_uri: string, ecom_image_uris: list, image_ids: list, sort_name: string, categories: list, description_html: string, description_plaintext: string, kitchen_name: string, channels: list, is_archived: bool, ecom_seo_data: record, food_and_beverage_details: record, reporting_category: record, is_alcoholic: bool>, category_data: record<name: string, image_ids: list, category_type: string, parent_category: record, is_top_level: bool, channels: list, availability_period_ids: list, online_visibility: bool, root_category: string, ecom_seo_data: record, path_to_root: list>, item_variation_data: record<item_id: string, name: string, sku: string, upc: string, ordinal: int, pricing_type: string, price_money: record, location_overrides: list, track_inventory: bool, inventory_alert_type: string, inventory_alert_threshold: int, user_data: string, service_duration: int, available_for_booking: bool, item_option_values: list, measurement_unit_id: string, sellable: bool, stockable: bool, image_ids: list, team_member_ids: list, stockable_conversion: record, kitchen_name: string>, tax_data: record<name: string, calculation_phase: string, inclusion_type: string, percentage: string, applies_to_custom_amounts: bool, enabled: bool, applies_to_product_set_id: string>, discount_data: record<name: string, discount_type: string, percentage: string, amount_money: record, pin_required: bool, label_color: string, modify_tax_basis: string, maximum_amount_money: record>, modifier_list_data: record<name: string, ordinal: int, selection_type: string, modifiers: list, image_ids: list, allow_quantities: bool, is_conversational: bool, modifier_type: string, max_length: int, text_required: bool, internal_name: string, min_selected_modifiers: int, max_selected_modifiers: int, hidden_from_customer: bool>, modifier_data: record<name: string, price_money: record, on_by_default: bool, ordinal: int, modifier_list_id: string, location_overrides: list, kitchen_name: string, image_id: string, hidden_online: bool>, time_period_data: record<event: string>, product_set_data: record<name: string, product_ids_any: list, product_ids_all: list, quantity_exact: int, quantity_min: int, quantity_max: int, all_products: bool>, pricing_rule_data: record<name: string, time_period_ids: list, discount_id: string, match_products_id: string, apply_products_id: string, exclude_products_id: string, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string, exclude_strategy: string, minimum_order_subtotal_money: record, customer_group_ids_any: list>, image_data: record<name: string, url: string, caption: string, photo_studio_order_id: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, subscription_plan_data: record<name: string, phases: list, subscription_plan_variations: list, eligible_item_ids: list, eligible_category_ids: list, all_items: bool>, item_option_data: record<name: string, display_name: string, description: string, show_colors: bool, values: list>, item_option_value_data: record<item_option_id: string, name: string, description: string, color: string, ordinal: int>, custom_attribute_definition_data: record<type: string, name: string, description: string, source_application: record, allowed_object_types: list, seller_visibility: string, app_visibility: string, string_config: record, number_config: record, selection_config: record, custom_attribute_usage_count: int, key: string>, quick_amounts_settings_data: record<option: string, eligible_for_auto_amounts: bool, amounts: list>, subscription_plan_variation_data: record<name: string, phases: list, subscription_plan_id: string, monthly_billing_anchor_date: int, can_prorate: bool, successor_plan_variation_id: string>, availability_period_data: record<start_local_time: string, end_local_time: string, day_of_week: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/images")
  let body = {request: $request, image_file: $image_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# UpdateCatalogImage
#
# PUT /v2/catalog/images/{image_id}
# operationId: UpdateCatalogImage
# --request shape: {idempotency_key: string}
export def "catalog-images UpdateCatalogImage" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request: record # e.g. {idempotency_key: 528dea59-7bfb-43c1-bd48-4a6bba7dd61f86, image: {image_data: {caption: A picture of a cup of coffee, name: Coffee}, type: IMAGE}, object_id: ND6EA5AAJEO5WL3JNNIAQA32} — shape: {idempotency_key: string}
  --image-file: string # format: binary
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, image: record<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list<record>, present_at_all_locations: bool, present_at_location_ids: list<string>, absent_at_location_ids: list<string>, item_data: record<name: string, description: string, abbreviation: string, label_color: string, is_taxable: bool, category_id: string, buyer_facing_name: string, tax_ids: list, modifier_list_info: list, variations: list, product_type: string, skip_modifier_screen: bool, item_options: list, ecom_uri: string, ecom_image_uris: list, image_ids: list, sort_name: string, categories: list, description_html: string, description_plaintext: string, kitchen_name: string, channels: list, is_archived: bool, ecom_seo_data: record, food_and_beverage_details: record, reporting_category: record, is_alcoholic: bool>, category_data: record<name: string, image_ids: list, category_type: string, parent_category: record, is_top_level: bool, channels: list, availability_period_ids: list, online_visibility: bool, root_category: string, ecom_seo_data: record, path_to_root: list>, item_variation_data: record<item_id: string, name: string, sku: string, upc: string, ordinal: int, pricing_type: string, price_money: record, location_overrides: list, track_inventory: bool, inventory_alert_type: string, inventory_alert_threshold: int, user_data: string, service_duration: int, available_for_booking: bool, item_option_values: list, measurement_unit_id: string, sellable: bool, stockable: bool, image_ids: list, team_member_ids: list, stockable_conversion: record, kitchen_name: string>, tax_data: record<name: string, calculation_phase: string, inclusion_type: string, percentage: string, applies_to_custom_amounts: bool, enabled: bool, applies_to_product_set_id: string>, discount_data: record<name: string, discount_type: string, percentage: string, amount_money: record, pin_required: bool, label_color: string, modify_tax_basis: string, maximum_amount_money: record>, modifier_list_data: record<name: string, ordinal: int, selection_type: string, modifiers: list, image_ids: list, allow_quantities: bool, is_conversational: bool, modifier_type: string, max_length: int, text_required: bool, internal_name: string, min_selected_modifiers: int, max_selected_modifiers: int, hidden_from_customer: bool>, modifier_data: record<name: string, price_money: record, on_by_default: bool, ordinal: int, modifier_list_id: string, location_overrides: list, kitchen_name: string, image_id: string, hidden_online: bool>, time_period_data: record<event: string>, product_set_data: record<name: string, product_ids_any: list, product_ids_all: list, quantity_exact: int, quantity_min: int, quantity_max: int, all_products: bool>, pricing_rule_data: record<name: string, time_period_ids: list, discount_id: string, match_products_id: string, apply_products_id: string, exclude_products_id: string, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string, exclude_strategy: string, minimum_order_subtotal_money: record, customer_group_ids_any: list>, image_data: record<name: string, url: string, caption: string, photo_studio_order_id: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, subscription_plan_data: record<name: string, phases: list, subscription_plan_variations: list, eligible_item_ids: list, eligible_category_ids: list, all_items: bool>, item_option_data: record<name: string, display_name: string, description: string, show_colors: bool, values: list>, item_option_value_data: record<item_option_id: string, name: string, description: string, color: string, ordinal: int>, custom_attribute_definition_data: record<type: string, name: string, description: string, source_application: record, allowed_object_types: list, seller_visibility: string, app_visibility: string, string_config: record, number_config: record, selection_config: record, custom_attribute_usage_count: int, key: string>, quick_amounts_settings_data: record<option: string, eligible_for_auto_amounts: bool, amounts: list>, subscription_plan_variation_data: record<name: string, phases: list, subscription_plan_id: string, monthly_billing_anchor_date: int, can_prorate: bool, successor_plan_variation_id: string>, availability_period_data: record<start_local_time: string, end_local_time: string, day_of_week: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/catalog/images/($image_id)")
  let body = {request: $request, image_file: $image_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# CatalogInfo
#
# GET /v2/catalog/info
# operationId: CatalogInfo
export def "catalog-info CatalogInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, limits: record<batch_upsert_max_objects_per_batch: int, batch_upsert_max_total_objects: int, batch_retrieve_max_object_ids: int, search_max_page_limit: int, batch_delete_max_object_ids: int, update_item_taxes_max_item_ids: int, update_item_taxes_max_taxes_to_enable: int, update_item_taxes_max_taxes_to_disable: int, update_item_modifier_lists_max_item_ids: int, update_item_modifier_lists_max_modifier_lists_to_enable: int, update_item_modifier_lists_max_modifier_lists_to_disable: int>, standard_unit_description_group: record<standard_unit_descriptions: list<record>, language_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListCatalog
#
# GET /v2/catalog/list
# operationId: ListCatalog
export def "catalog-list ListCatalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The pagination cursor returned in the previous response. Leave unset for an initial request. The page size is currently set to be 100. See [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination) for more information.
  --types: string # An optional case-insensitive, comma-separated list of object types to retrieve.  The valid values are defined in the [CatalogObjectType](entity:CatalogObjectType) enum, for example, `ITEM`, `ITEM_VARIATION`, `CATEGORY`, `DISCOUNT`, `TAX`, `MODIFIER`, `MODIFIER_LIST`, `IMAGE`, etc.  If this is unspecified, the operation returns objects of all the top level types at the version of the Square API used to make the request. Object types that are nested onto other object types are not included in the defaults.  At the current API version the default object types are: ITEM, CATEGORY, TAX, DISCOUNT, MODIFIER_LIST,  PRICING_RULE, PRODUCT_SET, TIME_PERIOD, MEASUREMENT_UNIT, SUBSCRIPTION_PLAN, ITEM_OPTION, CUSTOM_ATTRIBUTE_DEFINITION, QUICK_AMOUNT_SETTINGS.
  --catalog-version: int # The specific version of the catalog objects to be included in the response. This allows you to retrieve historical versions of objects. The specified version value is matched against the [CatalogObject](entity:CatalogObject)s' `version` attribute.  If not included, results will be from the current version of the catalog. (format: int64)
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, cursor: string, objects: table<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list, present_at_all_locations: bool, present_at_location_ids: list, absent_at_location_ids: list, item_data: record, category_data: record, item_variation_data: record, tax_data: record, discount_data: record, modifier_list_data: record, modifier_data: record, time_period_data: record, product_set_data: record, pricing_rule_data: record, image_data: record, measurement_unit_data: record, subscription_plan_data: record, item_option_data: record, item_option_value_data: record, custom_attribute_definition_data: record, quick_amounts_settings_data: record, subscription_plan_variation_data: record, availability_period_data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "catalog_version" $catalog_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/catalog/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpsertCatalogObject
#
# POST /v2/catalog/object
# operationId: UpsertCatalogObject
# --object shape: {type: "ITEM"|"IMAGE"|"CATEGORY"|"ITEM_VARIATION"|"TAX"|"DISCOUNT"|"MODIFIER_LIST"|"MODIFIER"|"PRICING_RULE"|"PRODUCT_SET"|"TIME_PERIOD"|"MEASUREMENT_UNIT"|"SUBSCRIPTION_PLAN_VARIATION"|"ITEM_OPTION"|"ITEM_OPTION_VAL"|"CUSTOM_ATTRIBUTE_DEFINITION"|"QUICK_AMOUNTS_SETTINGS"|"SUBSCRIPTION_PLAN"|"AVAILABILITY_PERIOD", id: string, version?: int, is_deleted?: bool, custom_attribute_values?: record, catalog_v1_ids?: list, present_at_all_locations?: bool, present_at_location_ids?: list, absent_at_location_ids?: list, item_data?: record, category_data?: record, item_variation_data?: record, tax_data?: record, discount_data?: record, modifier_list_data?: record, modifier_data?: record, time_period_data?: record, product_set_data?: record, pricing_rule_data?: record, image_data?: record, measurement_unit_data?: record, subscription_plan_data?: record, item_option_data?: record, item_option_value_data?: record, custom_attribute_definition_data?: record, quick_amounts_settings_data?: record, subscription_plan_variation_data?: record, availability_period_data?: record}
export def "catalog-object UpsertCatalogObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A value you specify that uniquely identifies this request among all your requests. A common way to create a valid idempotency key is to use a Universally unique identifier (UUID).  If you're unsure whether a particular request was successful, you can reattempt it with the same idempotency key without worrying about creating duplicate objects.  See [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) for more information.
  object: record # The wrapper object for the catalog entries of a given object type.  Depending on the `type` attribute value, a `CatalogObject` instance assumes a type-specific data to yield the corresponding type of catalog object.  For example, if `type=ITEM`, the `CatalogObject` instance must have the ITEM-specific data set on the `item_data` attribute. The resulting `CatalogObject` instance is also a `CatalogItem` instance.  In general, if `type=<OBJECT_TYPE>`, the `CatalogObject` instance must have the `<OBJECT_TYPE>`-specific data set on the `<object_type>_data` attribute. The resulting `CatalogObject` instance is also a `Catalog<ObjectType>` instance.  For a more detailed discussion of the Catalog data model, please see the [Design a Catalog](https://developer.squareup.com/docs/catalog-api/design-a-catalog) guide. (e.g. {catalog_object: {absent_at_location_ids: [{{ LOCATIONID-1 }}, {{ LOCATIONID-N }}], category_data: {{ CatalogCategory object only if type=CATEGORY }}, connect_v1_ids: {catalog_v1_id: {{ itemID from Catalog v1 }}, location_id: {{ location where v1 ID is used }}}, discount_data: {{ CatalogDiscount object only if type=DISCOUNT }}, id: {{ set by Catalog during object creation }}, is_deleted: {{ [true | false] }}, item_data: {{ CatalogItem object only if type=ITEM }}, item_variation_data: {{ CatalogItemVariation object only if type=ITEM_VARIATION }}, modifier_data: {{ CatalogModifier object only if type=MODIFIER }}, modifier_list_data: {{ CatalogModifierList object only if type=MODIFIER_LIST }}, present_at_all_locations: {{ [true | false] }}, present_at_location_ids: [{{ LOCATIONID-1 }}, {{ LOCATIONID-N }}], tax_data: {{ CatalogTax object only if type=TAX }}, type: {{ [ITEM | ITEM_VARIATION | MODIFIER | MODIFIER_LIST | CATEGORY | DISCOUNT | TAX] }}, updated_at: {{ date & time of most recent update }}, version: {{ version of the CatalogObject }}}}) — shape: {type: "ITEM"|"IMAGE"|"CATEGORY"|"ITEM_VARIATION"|"TAX"|"DISCOUNT"|"MODIFIER_LIST"|"MODIFIER"|"PRICING_RULE"|"PRODUCT_SET"|"TIME_PERIOD"|"MEASUREMENT_UNIT"|"SUBSCRIPTION_PLAN_VARIATION"|"ITEM_OPTION"|"ITEM_OPTION_VAL"|"CUSTOM_ATTRIBUTE_DEFINITION"|"QUICK_AMOUNTS_SETTINGS"|"SUBSCRIPTION_PLAN"|"AVAILABILITY_PERIOD", id: string, version?: int, is_deleted?: bool, custom_attribute_values?: record, catalog_v1_ids?: list, present_at_all_locations?: bool, present_at_location_ids?: list, absent_at_location_ids?: list, item_data?: record, category_data?: record, item_variation_data?: record, tax_data?: record, discount_data?: record, modifier_list_data?: record, modifier_data?: record, time_period_data?: record, product_set_data?: record, pricing_rule_data?: record, image_data?: record, measurement_unit_data?: record, subscription_plan_data?: record, item_option_data?: record, item_option_value_data?: record, custom_attribute_definition_data?: record, quick_amounts_settings_data?: record, subscription_plan_variation_data?: record, availability_period_data?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, catalog_object: record<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list<record>, present_at_all_locations: bool, present_at_location_ids: list<string>, absent_at_location_ids: list<string>, item_data: record<name: string, description: string, abbreviation: string, label_color: string, is_taxable: bool, category_id: string, buyer_facing_name: string, tax_ids: list, modifier_list_info: list, variations: list, product_type: string, skip_modifier_screen: bool, item_options: list, ecom_uri: string, ecom_image_uris: list, image_ids: list, sort_name: string, categories: list, description_html: string, description_plaintext: string, kitchen_name: string, channels: list, is_archived: bool, ecom_seo_data: record, food_and_beverage_details: record, reporting_category: record, is_alcoholic: bool>, category_data: record<name: string, image_ids: list, category_type: string, parent_category: record, is_top_level: bool, channels: list, availability_period_ids: list, online_visibility: bool, root_category: string, ecom_seo_data: record, path_to_root: list>, item_variation_data: record<item_id: string, name: string, sku: string, upc: string, ordinal: int, pricing_type: string, price_money: record, location_overrides: list, track_inventory: bool, inventory_alert_type: string, inventory_alert_threshold: int, user_data: string, service_duration: int, available_for_booking: bool, item_option_values: list, measurement_unit_id: string, sellable: bool, stockable: bool, image_ids: list, team_member_ids: list, stockable_conversion: record, kitchen_name: string>, tax_data: record<name: string, calculation_phase: string, inclusion_type: string, percentage: string, applies_to_custom_amounts: bool, enabled: bool, applies_to_product_set_id: string>, discount_data: record<name: string, discount_type: string, percentage: string, amount_money: record, pin_required: bool, label_color: string, modify_tax_basis: string, maximum_amount_money: record>, modifier_list_data: record<name: string, ordinal: int, selection_type: string, modifiers: list, image_ids: list, allow_quantities: bool, is_conversational: bool, modifier_type: string, max_length: int, text_required: bool, internal_name: string, min_selected_modifiers: int, max_selected_modifiers: int, hidden_from_customer: bool>, modifier_data: record<name: string, price_money: record, on_by_default: bool, ordinal: int, modifier_list_id: string, location_overrides: list, kitchen_name: string, image_id: string, hidden_online: bool>, time_period_data: record<event: string>, product_set_data: record<name: string, product_ids_any: list, product_ids_all: list, quantity_exact: int, quantity_min: int, quantity_max: int, all_products: bool>, pricing_rule_data: record<name: string, time_period_ids: list, discount_id: string, match_products_id: string, apply_products_id: string, exclude_products_id: string, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string, exclude_strategy: string, minimum_order_subtotal_money: record, customer_group_ids_any: list>, image_data: record<name: string, url: string, caption: string, photo_studio_order_id: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, subscription_plan_data: record<name: string, phases: list, subscription_plan_variations: list, eligible_item_ids: list, eligible_category_ids: list, all_items: bool>, item_option_data: record<name: string, display_name: string, description: string, show_colors: bool, values: list>, item_option_value_data: record<item_option_id: string, name: string, description: string, color: string, ordinal: int>, custom_attribute_definition_data: record<type: string, name: string, description: string, source_application: record, allowed_object_types: list, seller_visibility: string, app_visibility: string, string_config: record, number_config: record, selection_config: record, custom_attribute_usage_count: int, key: string>, quick_amounts_settings_data: record<option: string, eligible_for_auto_amounts: bool, amounts: list>, subscription_plan_variation_data: record<name: string, phases: list, subscription_plan_id: string, monthly_billing_anchor_date: int, can_prorate: bool, successor_plan_variation_id: string>, availability_period_data: record<start_local_time: string, end_local_time: string, day_of_week: string>>, id_mappings: table<client_object_id: string, object_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/object")
  let body = {idempotency_key: $idempotency_key, object: $object} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteCatalogObject
#
# DELETE /v2/catalog/object/{object_id}
# operationId: DeleteCatalogObject
export def "catalog-object DeleteCatalogObject" [
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, deleted_object_ids: list<string>, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/catalog/object/($object_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveCatalogObject
#
# GET /v2/catalog/object/{object_id}
# operationId: RetrieveCatalogObject
export def "catalog-object RetrieveCatalogObject" [
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested objects. Related objects are defined as any objects referenced by ID by the results in the `objects` field of the response. These objects are put in the `related_objects` field. Setting this to `true` is helpful when the objects are needed for immediate display to a user. This process only goes one level deep. Objects referenced by the related objects will not be included. For example,  if the `objects` field of the response contains a CatalogItem, its associated CatalogCategory objects, CatalogTax objects, CatalogImage objects and CatalogModifierLists will be returned in the `related_objects` field of the response. If the `objects` field of the response contains a CatalogItemVariation, its parent CatalogItem will be returned in the `related_objects` field of the response.  Default value: `false` (default: false)
  --catalog-version: int # Requests objects as of a specific version of the catalog. This allows you to retrieve historical versions of objects. The value to retrieve a specific version of an object can be found in the version field of [CatalogObject](entity:CatalogObject)s. If not included, results will be from the current version of the catalog. (format: int64)
  --include-category-path-to-root: oneof<nothing, bool> # Specifies whether or not to include the `path_to_root` list for each returned category instance. The `path_to_root` list consists of `CategoryPathToRootNode` objects and specifies the path that starts with the immediate parent category of the returned category and ends with its root category. If the returned category is a top-level category, the `path_to_root` list is empty and is not returned in the response payload. (default: false)
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, object: record<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list<record>, present_at_all_locations: bool, present_at_location_ids: list<string>, absent_at_location_ids: list<string>, item_data: record<name: string, description: string, abbreviation: string, label_color: string, is_taxable: bool, category_id: string, buyer_facing_name: string, tax_ids: list, modifier_list_info: list, variations: list, product_type: string, skip_modifier_screen: bool, item_options: list, ecom_uri: string, ecom_image_uris: list, image_ids: list, sort_name: string, categories: list, description_html: string, description_plaintext: string, kitchen_name: string, channels: list, is_archived: bool, ecom_seo_data: record, food_and_beverage_details: record, reporting_category: record, is_alcoholic: bool>, category_data: record<name: string, image_ids: list, category_type: string, parent_category: record, is_top_level: bool, channels: list, availability_period_ids: list, online_visibility: bool, root_category: string, ecom_seo_data: record, path_to_root: list>, item_variation_data: record<item_id: string, name: string, sku: string, upc: string, ordinal: int, pricing_type: string, price_money: record, location_overrides: list, track_inventory: bool, inventory_alert_type: string, inventory_alert_threshold: int, user_data: string, service_duration: int, available_for_booking: bool, item_option_values: list, measurement_unit_id: string, sellable: bool, stockable: bool, image_ids: list, team_member_ids: list, stockable_conversion: record, kitchen_name: string>, tax_data: record<name: string, calculation_phase: string, inclusion_type: string, percentage: string, applies_to_custom_amounts: bool, enabled: bool, applies_to_product_set_id: string>, discount_data: record<name: string, discount_type: string, percentage: string, amount_money: record, pin_required: bool, label_color: string, modify_tax_basis: string, maximum_amount_money: record>, modifier_list_data: record<name: string, ordinal: int, selection_type: string, modifiers: list, image_ids: list, allow_quantities: bool, is_conversational: bool, modifier_type: string, max_length: int, text_required: bool, internal_name: string, min_selected_modifiers: int, max_selected_modifiers: int, hidden_from_customer: bool>, modifier_data: record<name: string, price_money: record, on_by_default: bool, ordinal: int, modifier_list_id: string, location_overrides: list, kitchen_name: string, image_id: string, hidden_online: bool>, time_period_data: record<event: string>, product_set_data: record<name: string, product_ids_any: list, product_ids_all: list, quantity_exact: int, quantity_min: int, quantity_max: int, all_products: bool>, pricing_rule_data: record<name: string, time_period_ids: list, discount_id: string, match_products_id: string, apply_products_id: string, exclude_products_id: string, valid_from_date: string, valid_from_local_time: string, valid_until_date: string, valid_until_local_time: string, exclude_strategy: string, minimum_order_subtotal_money: record, customer_group_ids_any: list>, image_data: record<name: string, url: string, caption: string, photo_studio_order_id: string>, measurement_unit_data: record<measurement_unit: record, precision: int>, subscription_plan_data: record<name: string, phases: list, subscription_plan_variations: list, eligible_item_ids: list, eligible_category_ids: list, all_items: bool>, item_option_data: record<name: string, display_name: string, description: string, show_colors: bool, values: list>, item_option_value_data: record<item_option_id: string, name: string, description: string, color: string, ordinal: int>, custom_attribute_definition_data: record<type: string, name: string, description: string, source_application: record, allowed_object_types: list, seller_visibility: string, app_visibility: string, string_config: record, number_config: record, selection_config: record, custom_attribute_usage_count: int, key: string>, quick_amounts_settings_data: record<option: string, eligible_for_auto_amounts: bool, amounts: list>, subscription_plan_variation_data: record<name: string, phases: list, subscription_plan_id: string, monthly_billing_anchor_date: int, can_prorate: bool, successor_plan_variation_id: string>, availability_period_data: record<start_local_time: string, end_local_time: string, day_of_week: string>>, related_objects: table<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list, present_at_all_locations: bool, present_at_location_ids: list, absent_at_location_ids: list, item_data: record, category_data: record, item_variation_data: record, tax_data: record, discount_data: record, modifier_list_data: record, modifier_data: record, time_period_data: record, product_set_data: record, pricing_rule_data: record, image_data: record, measurement_unit_data: record, subscription_plan_data: record, item_option_data: record, item_option_value_data: record, custom_attribute_definition_data: record, quick_amounts_settings_data: record, subscription_plan_variation_data: record, availability_period_data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_related_objects" $include_related_objects "scalar") (serialize-qp "catalog_version" $catalog_version "scalar") (serialize-qp "include_category_path_to_root" $include_category_path_to_root "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/catalog/object/($object_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# SearchCatalogObjects
#
# POST /v2/catalog/search
# operationId: SearchCatalogObjects
# --query shape: {sorted_attribute_query?: record, exact_query?: record, set_query?: record, prefix_query?: record, range_query?: record, text_query?: record, items_for_tax_query?: record, items_for_modifier_list_query?: record, items_for_item_options_query?: record, item_variations_for_item_option_values_query?: record}
export def "catalog-search SearchCatalogObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The pagination cursor returned in the previous response. Leave unset for an initial request. See [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination) for more information.
  --object-types: list # The desired set of object types to appear in the search results.  If this is unspecified, the operation returns objects of all the top level types at the version of the Square API used to make the request. Object types that are nested onto other object types are not included in the defaults.  At the current API version the default object types are: ITEM, CATEGORY, TAX, DISCOUNT, MODIFIER_LIST,  PRICING_RULE, PRODUCT_SET, TIME_PERIOD, MEASUREMENT_UNIT, SUBSCRIPTION_PLAN, ITEM_OPTION, CUSTOM_ATTRIBUTE_DEFINITION, QUICK_AMOUNT_SETTINGS.  Note that if you wish for the query to return objects belonging to nested types (i.e., COMPONENT, IMAGE, ITEM_OPTION_VAL, ITEM_VARIATION, or MODIFIER), you must explicitly include all the types of interest in this field.
  --include-deleted-objects: oneof<nothing, bool> # If `true`, deleted objects will be included in the results. Defaults to `false`. Deleted objects will have their `is_deleted` field set to `true`. If `include_deleted_objects` is `true`, then the `include_category_path_to_root` request parameter must be `false`. Both properties cannot be `true` at the same time.
  --include-related-objects: oneof<nothing, bool> # If `true`, the response will include additional objects that are related to the requested objects. Related objects are objects that are referenced by object ID by the objects in the response. This is helpful if the objects are being fetched for immediate display to a user. This process only goes one level deep. Objects referenced by the related objects will not be included. For example:  If the `objects` field of the response contains a CatalogItem, its associated CatalogCategory objects, CatalogTax objects, CatalogImage objects and CatalogModifierLists will be returned in the `related_objects` field of the response. If the `objects` field of the response contains a CatalogItemVariation, its parent CatalogItem will be returned in the `related_objects` field of the response.  Default value: `false`
  --begin-time: string # Return objects modified after this [timestamp](https://developer.squareup.com/docs/build-basics/working-with-dates), in RFC 3339 format, e.g., `2016-09-04T23:59:33.123Z`. The timestamp is exclusive - objects with a timestamp equal to `begin_time` will not be included in the response.
  --body-query: record # A query composed of one or more different types of filters to narrow the scope of targeted objects when calling the `SearchCatalogObjects` endpoint.  Although a query can have multiple filters, only certain query types can be combined per call to [SearchCatalogObjects](api-endpoint:Catalog-SearchCatalogObjects). Any combination of the following types may be used together: - [exact_query](entity:CatalogQueryExact) - [prefix_query](entity:CatalogQueryPrefix) - [range_query](entity:CatalogQueryRange) - [sorted_attribute_query](entity:CatalogQuerySortedAttribute) - [text_query](entity:CatalogQueryText)  All other query types cannot be combined with any others.  When a query filter is based on an attribute, the attribute must be searchable. Searchable attributes are listed as follows, along their parent types that can be searched for with applicable query filters.  Searchable attribute and objects queryable by searchable attributes: - `name`:  `CatalogItem`, `CatalogItemVariation`, `CatalogCategory`, `CatalogTax`, `CatalogDiscount`, `CatalogModifier`, `CatalogModifierList`, `CatalogItemOption`, `CatalogItemOptionValue` - `description`: `CatalogItem`, `CatalogItemOptionValue` - `abbreviation`: `CatalogItem` - `upc`: `CatalogItemVariation` - `sku`: `CatalogItemVariation` - `caption`: `CatalogImage` - `display_name`: `CatalogItemOption`  For example, to search for [CatalogItem](entity:CatalogItem) objects by searchable attributes, you can use the `"name"`, `"description"`, or `"abbreviation"` attribute in an applicable query filter. — shape: {sorted_attribute_query?: record, exact_query?: record, set_query?: record, prefix_query?: record, range_query?: record, text_query?: record, items_for_tax_query?: record, items_for_modifier_list_query?: record, items_for_item_options_query?: record, item_variations_for_item_option_values_query?: record}
  --limit: int # A limit on the number of results to be returned in a single page. The limit is advisory - the implementation may return more or fewer results. If the supplied limit is negative, zero, or is higher than the maximum limit of 1,000, it will be ignored.
  --include-category-path-to-root: oneof<nothing, bool> # Specifies whether or not to include the `path_to_root` list for each returned category instance. The `path_to_root` list consists of `CategoryPathToRootNode` objects and specifies the path that starts with the immediate parent category of the returned category and ends with its root category. If the returned category is a top-level category, the `path_to_root` list is empty and is not returned in the response payload. If `include_category_path_to_root` is `true`, then the `include_deleted_objects` request parameter must be `false`. Both properties cannot be `true` at the same time.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, cursor: string, objects: table<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list, present_at_all_locations: bool, present_at_location_ids: list, absent_at_location_ids: list, item_data: record, category_data: record, item_variation_data: record, tax_data: record, discount_data: record, modifier_list_data: record, modifier_data: record, time_period_data: record, product_set_data: record, pricing_rule_data: record, image_data: record, measurement_unit_data: record, subscription_plan_data: record, item_option_data: record, item_option_value_data: record, custom_attribute_definition_data: record, quick_amounts_settings_data: record, subscription_plan_variation_data: record, availability_period_data: record>, related_objects: table<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list, present_at_all_locations: bool, present_at_location_ids: list, absent_at_location_ids: list, item_data: record, category_data: record, item_variation_data: record, tax_data: record, discount_data: record, modifier_list_data: record, modifier_data: record, time_period_data: record, product_set_data: record, pricing_rule_data: record, image_data: record, measurement_unit_data: record, subscription_plan_data: record, item_option_data: record, item_option_value_data: record, custom_attribute_definition_data: record, quick_amounts_settings_data: record, subscription_plan_variation_data: record, availability_period_data: record>, latest_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/search")
  let body = {cursor: $cursor, object_types: $object_types, include_deleted_objects: $include_deleted_objects, include_related_objects: $include_related_objects, begin_time: $begin_time, query: $body_query, limit: $limit, include_category_path_to_root: $include_category_path_to_root} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchCatalogItems
#
# POST /v2/catalog/search-catalog-items
# operationId: SearchCatalogItems
# --custom_attribute_filters item shape: {custom_attribute_definition_id?: string, key?: string, string_filter?: string, number_filter?: record, selection_uids_filter?: list, bool_filter?: bool}
export def "catalog-search-catalog-items SearchCatalogItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text-filter: string # The text filter expression to return items or item variations containing specified text in the `name`, `description`, or `abbreviation` attribute value of an item, or in the `name`, `sku`, or `upc` attribute value of an item variation.
  --category-ids: list # The category id query expression to return items containing the specified category IDs.
  --stock-levels: list # The stock-level query expression to return item variations with the specified stock levels. See [SearchCatalogItemsRequestStockLevel](#type-searchcatalogitemsrequeststocklevel) for possible values
  --enabled-location-ids: list # The enabled-location query expression to return items and item variations having specified enabled locations.
  --cursor: string # The pagination token, returned in the previous response, used to fetch the next batch of pending results.
  --limit: int # The maximum number of results to return per page. The default value is 100.
  --sort-order: string@sort-order-completer # The order (e.g., chronological or alphabetical) in which results from a request are returned.
  --product-types: list # The product types query expression to return items or item variations having the specified product types.
  --custom-attribute-filters: list # The customer-attribute filter to return items or item variations matching the specified custom attribute expressions. A maximum number of 10 custom attribute expressions are supported in a single call to the [SearchCatalogItems](api-endpoint:Catalog-SearchCatalogItems) endpoint. — item shape: {custom_attribute_definition_id?: string, key?: string, string_filter?: string, number_filter?: record, selection_uids_filter?: list, bool_filter?: bool}
  --archived-state: string@archived-state-completer # Defines the values for the `archived_state` query expression  used in [SearchCatalogItems](api-endpoint:Catalog-SearchCatalogItems)  to return the archived, not archived or either type of catalog items.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, items: table<type: string, id: string, updated_at: string, version: int, is_deleted: bool, custom_attribute_values: record, catalog_v1_ids: list, present_at_all_locations: bool, present_at_location_ids: list, absent_at_location_ids: list, item_data: record, category_data: record, item_variation_data: record, tax_data: record, discount_data: record, modifier_list_data: record, modifier_data: record, time_period_data: record, product_set_data: record, pricing_rule_data: record, image_data: record, measurement_unit_data: record, subscription_plan_data: record, item_option_data: record, item_option_value_data: record, custom_attribute_definition_data: record, quick_amounts_settings_data: record, subscription_plan_variation_data: record, availability_period_data: record>, cursor: string, matched_variation_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/search-catalog-items")
  let body = {text_filter: $text_filter, category_ids: $category_ids, stock_levels: $stock_levels, enabled_location_ids: $enabled_location_ids, cursor: $cursor, limit: $limit, sort_order: $sort_order, product_types: $product_types, custom_attribute_filters: $custom_attribute_filters, archived_state: $archived_state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# UpdateItemModifierLists
#
# POST /v2/catalog/update-item-modifier-lists
# operationId: UpdateItemModifierLists
export def "catalog-update-item-modifier-lists UpdateItemModifierLists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  item_ids: list # The IDs of the catalog items associated with the CatalogModifierList objects being updated.
  --modifier-lists-to-enable: list # The IDs of the CatalogModifierList objects to enable for the CatalogItem. At least one of `modifier_lists_to_enable` or `modifier_lists_to_disable` must be specified. (nullable)
  --modifier-lists-to-disable: list # The IDs of the CatalogModifierList objects to disable for the CatalogItem. At least one of `modifier_lists_to_enable` or `modifier_lists_to_disable` must be specified. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/update-item-modifier-lists")
  let body = {item_ids: $item_ids, modifier_lists_to_enable: $modifier_lists_to_enable, modifier_lists_to_disable: $modifier_lists_to_disable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# UpdateItemTaxes
#
# POST /v2/catalog/update-item-taxes
# operationId: UpdateItemTaxes
export def "catalog-update-item-taxes UpdateItemTaxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  item_ids: list # IDs for the CatalogItems associated with the CatalogTax objects being updated. No more than 1,000 IDs may be provided.
  --taxes-to-enable: list # IDs of the CatalogTax objects to enable. At least one of `taxes_to_enable` or `taxes_to_disable` must be specified. (nullable)
  --taxes-to-disable: list # IDs of the CatalogTax objects to disable. At least one of `taxes_to_enable` or `taxes_to_disable` must be specified. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/update-item-taxes")
  let body = {item_ids: $item_ids, taxes_to_enable: $taxes_to_enable, taxes_to_disable: $taxes_to_disable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListChannels
#
# GET /v2/channels
# operationId: ListChannels
export def "channels ListChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reference-type: string@reference-type-completer # Type of reference associated to channel
  --reference-id: string # id of reference associated to channel
  --status: string@status-completer # Status of channel
  --cursor: string # Cursor to fetch the next result
  --limit: int # Maximum number of results to return. When not provided the returned results will be cap at 100 channels.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, channels: table<id: string, merchant_id: string, name: string, version: int, reference: record, status: string, created_at: string, updated_at: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reference_type" $reference_type "scalar") (serialize-qp "reference_id" $reference_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# BulkRetrieveChannels
#
# POST /v2/channels/bulk-retrieve
# operationId: BulkRetrieveChannels
export def "channels-bulk-retrieve BulkRetrieveChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_ids: list
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/channels/bulk-retrieve")
  let body = {channel_ids: $channel_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveChannel
#
# GET /v2/channels/{channel_id}
# operationId: RetrieveChannel
export def "channels RetrieveChannel" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, channel: record<id: string, merchant_id: string, name: string, version: int, reference: record<type: string, id: string>, status: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListCustomers
#
# GET /v2/customers
# operationId: ListCustomers
export def "customers ListCustomers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. If the specified limit is less than 1 or greater than 100, Square returns a `400 VALUE_TOO_LOW` or `400 VALUE_TOO_HIGH` error. The default value is 100.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --sort-field: string@sort-field-completer # Indicates how customers should be sorted.  The default value is `DEFAULT`.
  --sort-order: string@sort-order-completer # Indicates whether customers should be sorted in ascending (`ASC`) or descending (`DESC`) order.  The default value is `ASC`.
  --count: oneof<nothing, bool> # Indicates whether to return the total count of customers in the `count` field of the response.  The default value is `false`. (default: false)
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, customers: table<id: string, created_at: string, updated_at: string, given_name: string, family_name: string, nickname: string, company_name: string, email_address: string, address: record, phone_number: string, birthday: string, reference_id: string, note: string, preferences: record, creation_source: string, group_ids: list, segment_ids: list, version: int, tax_ids: record>, cursor: string, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateCustomer
#
# POST /v2/customers
# operationId: CreateCustomer
# --address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
# --tax_ids shape: {eu_vat?: string}
export def "customers CreateCustomer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The idempotency key for the request.	For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
  --given-name: string # The given name (that is, the first name) associated with the customer profile.  The maximum length for this value is 300 characters.
  --family-name: string # The family name (that is, the last name) associated with the customer profile.  The maximum length for this value is 300 characters.
  --company-name: string # A business name associated with the customer profile.  The maximum length for this value is 500 characters.
  --nickname: string # A nickname for the customer profile.  The maximum length for this value is 100 characters.
  --email-address: string # The email address associated with the customer profile.  The maximum length for this value is 254 characters.
  --address: record # Represents a postal address in a country.  For more information, see [Working with Addresses](https://developer.squareup.com/docs/build-basics/working-with-addresses). — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
  --phone-number: string # The phone number associated with the customer profile. The phone number must be valid and can contain 9–16 digits, with an optional `+` prefix and country code. For more information, see [Customer phone numbers](https://developer.squareup.com/docs/customers-api/use-the-api/keep-records#phone-number).
  --reference-id: string # An optional second ID used to associate the customer profile with an entity in another system.  The maximum length for this value is 100 characters.
  --note: string # A custom note associated with the customer profile.
  --birthday: string # The birthday associated with the customer profile, in `YYYY-MM-DD` or `MM-DD` format. For example, specify `1998-09-21` for September 21, 1998, or `09-21` for September 21. Birthdays are returned in `YYYY-MM-DD` format, where `YYYY` is the specified birth year or `0000` if a birth year is not specified.
  --tax-ids: record # Represents the tax ID associated with a [customer profile](entity:Customer). The corresponding `tax_ids` field is available only for customers of sellers in EU countries or the United Kingdom.  For more information, see [Customer tax IDs](https://developer.squareup.com/docs/customers-api/what-it-does#customer-tax-ids). — shape: {eu_vat?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, customer: record<id: string, created_at: string, updated_at: string, given_name: string, family_name: string, nickname: string, company_name: string, email_address: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, phone_number: string, birthday: string, reference_id: string, note: string, preferences: record<email_unsubscribed: bool>, creation_source: string, group_ids: list<string>, segment_ids: list<string>, version: int, tax_ids: record<eu_vat: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers")
  let body = {idempotency_key: $idempotency_key, given_name: $given_name, family_name: $family_name, company_name: $company_name, nickname: $nickname, email_address: $email_address, address: $address, phone_number: $phone_number, reference_id: $reference_id, note: $note, birthday: $birthday, tax_ids: $tax_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkCreateCustomers
#
# POST /v2/customers/bulk-create
# operationId: BulkCreateCustomers
export def "customers-bulk-create BulkCreateCustomers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customers: record # A map of 1 to 100 individual create requests, represented by `idempotency key: { customer data }` key-value pairs.  Each key is an [idempotency key](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) that uniquely identifies the create request. Each value contains the customer data used to create the customer profile.
]: any -> record<responses: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/bulk-create")
  let body = {customers: $customers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkDeleteCustomers
#
# POST /v2/customers/bulk-delete
# operationId: BulkDeleteCustomers
export def "customers-bulk-delete BulkDeleteCustomers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer_ids: list # The IDs of the [customer profiles](entity:Customer) to delete.
]: any -> record<responses: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/bulk-delete")
  let body = {customer_ids: $customer_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkRetrieveCustomers
#
# POST /v2/customers/bulk-retrieve
# operationId: BulkRetrieveCustomers
export def "customers-bulk-retrieve BulkRetrieveCustomers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer_ids: list # The IDs of the [customer profiles](entity:Customer) to retrieve.
]: any -> record<responses: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/bulk-retrieve")
  let body = {customer_ids: $customer_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkUpdateCustomers
#
# POST /v2/customers/bulk-update
# operationId: BulkUpdateCustomers
export def "customers-bulk-update BulkUpdateCustomers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customers: record # A map of 1 to 100 individual update requests, represented by `customer ID: { customer data }` key-value pairs.  Each key is the ID of the [customer profile](entity:Customer) to update. To update a customer profile that was created by merging existing profiles, provide the ID of the newly created profile.  Each value contains the updated customer data. Only new or changed fields are required. To add or update a field, specify the new value. To remove a field, specify `null`.
]: any -> record<responses: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/bulk-update")
  let body = {customers: $customers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListCustomerCustomAttributeDefinitions
#
# GET /v2/customers/custom-attribute-definitions
# operationId: ListCustomerCustomAttributeDefinitions
export def "customers-custom-attribute-definitions ListCustomerCustomAttributeDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory. The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100. The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<custom_attribute_definitions: table<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers/custom-attribute-definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateCustomerCustomAttributeDefinition
#
# POST /v2/customers/custom-attribute-definitions
# operationId: CreateCustomerCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "customers-custom-attribute-definitions CreateCustomerCustomAttributeDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/custom-attribute-definitions")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteCustomerCustomAttributeDefinition
#
# DELETE /v2/customers/custom-attribute-definitions/{key}
# operationId: DeleteCustomerCustomAttributeDefinition
export def "customers-custom-attribute-definitions DeleteCustomerCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/custom-attribute-definitions/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveCustomerCustomAttributeDefinition
#
# GET /v2/customers/custom-attribute-definitions/{key}
# operationId: RetrieveCustomerCustomAttributeDefinition
export def "customers-custom-attribute-definitions RetrieveCustomerCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # The current version of the custom attribute definition, which is used for strongly consistent reads to guarantee that you receive the most up-to-date data. When included in the request, Square returns the specified version or a higher version if one exists. If the specified version is higher than the current version, Square returns a `BAD_REQUEST` error.
]: nothing -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customers/custom-attribute-definitions/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateCustomerCustomAttributeDefinition
#
# PUT /v2/customers/custom-attribute-definitions/{key}
# operationId: UpdateCustomerCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "customers-custom-attribute-definitions UpdateCustomerCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/custom-attribute-definitions/($key)")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkUpsertCustomerCustomAttributes
#
# POST /v2/customers/custom-attributes/bulk-upsert
# operationId: BulkUpsertCustomerCustomAttributes
export def "customers-custom-attributes-bulk-upsert BulkUpsertCustomerCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # A map containing 1 to 25 individual upsert requests. For each request, provide an arbitrary ID that is unique for this `BulkUpsertCustomerCustomAttributes` request and the information needed to create or update a custom attribute.
]: any -> record<values: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/custom-attributes/bulk-upsert")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListCustomerGroups
#
# GET /v2/customers/groups
# operationId: ListCustomerGroups
export def "customers-groups ListCustomerGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. If the limit is less than 1 or greater than 50, Square returns a `400 VALUE_TOO_LOW` or `400 VALUE_TOO_HIGH` error. The default value is 50.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, groups: table<id: string, name: string, created_at: string, updated_at: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateCustomerGroup
#
# POST /v2/customers/groups
# operationId: CreateCustomerGroup
# --group shape: {name: string}
export def "customers-groups CreateCustomerGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The idempotency key for the request. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
  group: record # Represents a group of customer profiles.   Customer groups can be created, be modified, and have their membership defined using  the Customers API or within the Customer Directory in the Square Seller Dashboard or Point of Sale. — shape: {name: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, group: record<id: string, name: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/groups")
  let body = {idempotency_key: $idempotency_key, group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteCustomerGroup
#
# DELETE /v2/customers/groups/{group_id}
# operationId: DeleteCustomerGroup
export def "customers-groups DeleteCustomerGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveCustomerGroup
#
# GET /v2/customers/groups/{group_id}
# operationId: RetrieveCustomerGroup
export def "customers-groups RetrieveCustomerGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, group: record<id: string, name: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateCustomerGroup
#
# PUT /v2/customers/groups/{group_id}
# operationId: UpdateCustomerGroup
# --group shape: {name: string}
export def "customers-groups UpdateCustomerGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  group: record # Represents a group of customer profiles.   Customer groups can be created, be modified, and have their membership defined using  the Customers API or within the Customer Directory in the Square Seller Dashboard or Point of Sale. — shape: {name: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, group: record<id: string, name: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/groups/($group_id)")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchCustomers
#
# POST /v2/customers/search
# operationId: SearchCustomers
# --query shape: {filter?: record, sort?: record}
export def "customers-search SearchCustomers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Include the pagination cursor in subsequent calls to this endpoint to retrieve the next set of results associated with the original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. If the specified limit is invalid, Square returns a `400 VALUE_TOO_LOW` or `400 VALUE_TOO_HIGH` error. The default value is 100.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination). (format: int64)
  --body-query: record # Represents filtering and sorting criteria for a [SearchCustomers](api-endpoint:Customers-SearchCustomers) request. — shape: {filter?: record, sort?: record}
  --count: oneof<nothing, bool> # Indicates whether to return the total count of matching customers in the `count` field of the response.  The default value is `false`.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, customers: table<id: string, created_at: string, updated_at: string, given_name: string, family_name: string, nickname: string, company_name: string, email_address: string, address: record, phone_number: string, birthday: string, reference_id: string, note: string, preferences: record, creation_source: string, group_ids: list, segment_ids: list, version: int, tax_ids: record>, cursor: string, count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/search")
  let body = {cursor: $cursor, limit: $limit, query: $body_query, count: $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListCustomerSegments
#
# GET /v2/customers/segments
# operationId: ListCustomerSegments
export def "customers-segments ListCustomerSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by previous calls to `ListCustomerSegments`. This cursor is used to retrieve the next set of query results.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The maximum number of results to return in a single page. This limit is advisory. The response might contain more or fewer results. If the specified limit is less than 1 or greater than 50, Square returns a `400 VALUE_TOO_LOW` or `400 VALUE_TOO_HIGH` error. The default value is 50.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, segments: table<id: string, name: string, created_at: string, updated_at: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveCustomerSegment
#
# GET /v2/customers/segments/{segment_id}
# operationId: RetrieveCustomerSegment
export def "customers-segments RetrieveCustomerSegment" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, segment: record<id: string, name: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/segments/($segment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeleteCustomer
#
# DELETE /v2/customers/{customer_id}
# operationId: DeleteCustomer
export def "customers DeleteCustomer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # The current version of the customer profile.  As a best practice, you should include this parameter to enable [optimistic concurrency](https://developer.squareup.com/docs/build-basics/common-api-patterns/optimistic-concurrency) control.  For more information, see [Delete a customer profile](https://developer.squareup.com/docs/customers-api/use-the-api/keep-records#delete-customer-profile). (format: int64)
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customers/($customer_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveCustomer
#
# GET /v2/customers/{customer_id}
# operationId: RetrieveCustomer
export def "customers RetrieveCustomer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, customer: record<id: string, created_at: string, updated_at: string, given_name: string, family_name: string, nickname: string, company_name: string, email_address: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, phone_number: string, birthday: string, reference_id: string, note: string, preferences: record<email_unsubscribed: bool>, creation_source: string, group_ids: list<string>, segment_ids: list<string>, version: int, tax_ids: record<eu_vat: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateCustomer
#
# PUT /v2/customers/{customer_id}
# operationId: UpdateCustomer
# --address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
# --tax_ids shape: {eu_vat?: string}
export def "customers UpdateCustomer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --given-name: string # The given name (that is, the first name) associated with the customer profile.  The maximum length for this value is 300 characters. (nullable)
  --family-name: string # The family name (that is, the last name) associated with the customer profile.  The maximum length for this value is 300 characters. (nullable)
  --company-name: string # A business name associated with the customer profile.  The maximum length for this value is 500 characters. (nullable)
  --nickname: string # A nickname for the customer profile.  The maximum length for this value is 100 characters. (nullable)
  --email-address: string # The email address associated with the customer profile.  The maximum length for this value is 254 characters. (nullable)
  --address: record # Represents a postal address in a country.  For more information, see [Working with Addresses](https://developer.squareup.com/docs/build-basics/working-with-addresses). — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
  --phone-number: string # The phone number associated with the customer profile. The phone number must be valid and can contain 9–16 digits, with an optional `+` prefix and country code. For more information, see [Customer phone numbers](https://developer.squareup.com/docs/customers-api/use-the-api/keep-records#phone-number). (nullable)
  --reference-id: string # An optional second ID used to associate the customer profile with an entity in another system.  The maximum length for this value is 100 characters. (nullable)
  --note: string # A custom note associated with the customer profile. (nullable)
  --birthday: string # The birthday associated with the customer profile, in `YYYY-MM-DD` or `MM-DD` format. For example, specify `1998-09-21` for September 21, 1998, or `09-21` for September 21. Birthdays are returned in `YYYY-MM-DD` format, where `YYYY` is the specified birth year or `0000` if a birth year is not specified. (nullable)
  --version: int # The current version of the customer profile.  As a best practice, you should include this field to enable [optimistic concurrency](https://developer.squareup.com/docs/build-basics/common-api-patterns/optimistic-concurrency) control. For more information, see [Update a customer profile](https://developer.squareup.com/docs/customers-api/use-the-api/keep-records#update-a-customer-profile). (format: int64)
  --tax-ids: record # Represents the tax ID associated with a [customer profile](entity:Customer). The corresponding `tax_ids` field is available only for customers of sellers in EU countries or the United Kingdom.  For more information, see [Customer tax IDs](https://developer.squareup.com/docs/customers-api/what-it-does#customer-tax-ids). — shape: {eu_vat?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, customer: record<id: string, created_at: string, updated_at: string, given_name: string, family_name: string, nickname: string, company_name: string, email_address: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, phone_number: string, birthday: string, reference_id: string, note: string, preferences: record<email_unsubscribed: bool>, creation_source: string, group_ids: list<string>, segment_ids: list<string>, version: int, tax_ids: record<eu_vat: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customer_id)")
  let body = {given_name: $given_name, family_name: $family_name, company_name: $company_name, nickname: $nickname, email_address: $email_address, address: $address, phone_number: $phone_number, reference_id: $reference_id, note: $note, birthday: $birthday, version: $version, tax_ids: $tax_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateCustomerCard
#
# POST /v2/customers/{customer_id}/cards
# DEPRECATED
# operationId: CreateCustomerCard
# --billing_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
@deprecated
export def "customers-cards CreateCustomerCard" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  card_nonce: string # A card nonce representing the credit card to link to the customer.  Card nonces are generated by the Square payment form when customers enter their card information. For more information, see [Walkthrough: Integrate Square Payments in a Website](https://developer.squareup.com/docs/web-payments/take-card-payment).  __NOTE:__ Card nonces generated by digital wallets (such as Apple Pay) cannot be used to create a customer card.
  --billing-address: record # Represents a postal address in a country.  For more information, see [Working with Addresses](https://developer.squareup.com/docs/build-basics/working-with-addresses). — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
  --cardholder-name: string # The full name printed on the credit card.
  --verification-token: string # An identifying token generated by [Payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, card: record<id: string, card_brand: string, last_4: string, exp_month: int, exp_year: int, cardholder_name: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, fingerprint: string, customer_id: string, merchant_id: string, reference_id: string, enabled: bool, card_type: string, prepaid_type: string, bin: string, created_at: string, disabled_at: string, version: int, card_co_brand: string, issuer_alert: string, issuer_alert_at: string, hsa_fsa: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customer_id)/cards")
  let body = {card_nonce: $card_nonce, billing_address: $billing_address, cardholder_name: $cardholder_name, verification_token: $verification_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteCustomerCard
#
# DELETE /v2/customers/{customer_id}/cards/{card_id}
# DEPRECATED
# operationId: DeleteCustomerCard
@deprecated
export def "customers-cards DeleteCustomerCard" [
  customer_id: string
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customer_id)/cards/($card_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListCustomerCustomAttributes
#
# GET /v2/customers/{customer_id}/custom-attributes
# operationId: ListCustomerCustomAttributes
export def "customers-custom-attributes ListCustomerCustomAttributes" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory. The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100. The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --with-definitions: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of each custom attribute. Set this parameter to `true` to get the name and description of each custom attribute, information about the data type, or other definition details. The default value is `false`. (default: false)
]: nothing -> record<custom_attributes: table<key: string, value: any, version: int, visibility: string, definition: record, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "with_definitions" $with_definitions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customers/($customer_id)/custom-attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeleteCustomerCustomAttribute
#
# DELETE /v2/customers/{customer_id}/custom-attributes/{key}
# operationId: DeleteCustomerCustomAttribute
export def "customers-custom-attributes DeleteCustomerCustomAttribute" [
  customer_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customer_id)/custom-attributes/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveCustomerCustomAttribute
#
# GET /v2/customers/{customer_id}/custom-attributes/{key}
# operationId: RetrieveCustomerCustomAttribute
export def "customers-custom-attributes RetrieveCustomerCustomAttribute" [
  customer_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-definition: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of the custom attribute. Set this parameter to `true` to get the name and description of the custom attribute, information about the data type, or other definition details. The default value is `false`. (default: false)
  --version: int # The current version of the custom attribute, which is used for strongly consistent reads to guarantee that you receive the most up-to-date data. When included in the request, Square returns the specified version or a higher version if one exists. If the specified version is higher than the current version, Square returns a `BAD_REQUEST` error.
]: nothing -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_definition" $with_definition "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customers/($customer_id)/custom-attributes/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpsertCustomerCustomAttribute
#
# POST /v2/customers/{customer_id}/custom-attributes/{key}
# operationId: UpsertCustomerCustomAttribute
# --custom_attribute shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
export def "customers-custom-attributes UpsertCustomerCustomAttribute" [
  customer_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute: record # A custom attribute value. Each custom attribute value has a corresponding `CustomAttributeDefinition` object. — shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customer_id)/custom-attributes/($key)")
  let body = {custom_attribute: $custom_attribute, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RemoveGroupFromCustomer
#
# DELETE /v2/customers/{customer_id}/groups/{group_id}
# operationId: RemoveGroupFromCustomer
export def "customers-groups RemoveGroupFromCustomer" [
  customer_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customer_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# AddGroupToCustomer
#
# PUT /v2/customers/{customer_id}/groups/{group_id}
# operationId: AddGroupToCustomer
export def "customers-groups AddGroupToCustomer" [
  customer_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customer_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListDevices
#
# GET /v2/devices
# operationId: ListDevices
export def "devices ListDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. See [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination) for more information.
  --sort-order: string@sort-order-completer # The order in which results are listed. - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
  --limit: int # The number of results to return in a single page.
  --location-id: string # If present, only returns devices at the target location.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, devices: table<id: string, attributes: record, components: list, status: record>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListDeviceCodes
#
# GET /v2/devices/codes
# operationId: ListDeviceCodes
export def "devices-codes ListDeviceCodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query.  See [Paginating results](https://developer.squareup.com/docs/working-with-apis/pagination) for more information.
  --location-id: string # If specified, only returns DeviceCodes of the specified location. Returns DeviceCodes of all locations if empty.
  --product-type: string@product-type-completer # If specified, only returns DeviceCodes targeting the specified product type. Returns DeviceCodes of all product types if empty.
  --status: string@status-completer-1 # If specified, returns DeviceCodes with the specified statuses. Returns DeviceCodes of status `PAIRED` and `UNPAIRED` if empty.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, device_codes: table<id: string, name: string, code: string, device_id: string, product_type: string, location_id: string, status: string, pair_by: string, created_at: string, status_changed_at: string, paired_at: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "product_type" $product_type "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/devices/codes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateDeviceCode
#
# POST /v2/devices/codes
# operationId: CreateDeviceCode
# --device_code shape: {name?: string, product_type: "TERMINAL_API", location_id?: string, status?: "UNKNOWN"|"UNPAIRED"|"PAIRED"|"EXPIRED"}
export def "devices-codes CreateDeviceCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this CreateDeviceCode request. Keys can be any valid string but must be unique for every CreateDeviceCode request.  See [Idempotency keys](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) for more information.
  device_code: record # shape: {name?: string, product_type: "TERMINAL_API", location_id?: string, status?: "UNKNOWN"|"UNPAIRED"|"PAIRED"|"EXPIRED"}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, device_code: record<id: string, name: string, code: string, device_id: string, product_type: string, location_id: string, status: string, pair_by: string, created_at: string, status_changed_at: string, paired_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/devices/codes")
  let body = {idempotency_key: $idempotency_key, device_code: $device_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetDeviceCode
#
# GET /v2/devices/codes/{id}
# operationId: GetDeviceCode
export def "devices-codes GetDeviceCode" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, device_code: record<id: string, name: string, code: string, device_id: string, product_type: string, location_id: string, status: string, pair_by: string, created_at: string, status_changed_at: string, paired_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/devices/codes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetDevice
#
# GET /v2/devices/{device_id}
# operationId: GetDevice
export def "devices GetDevice" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, device: record<id: string, attributes: record<type: string, manufacturer: string, model: string, name: string, manufacturers_id: string, updated_at: string, version: string, merchant_token: string>, components: list<record>, status: record<category: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/devices/($device_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListDisputes
#
# GET /v2/disputes
# operationId: ListDisputes
export def "disputes ListDisputes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --states: string@states-completer # The dispute states used to filter the result. If not specified, the endpoint returns all disputes.
  --location-id: string # The ID of the location for which to return a list of disputes. If not specified, the endpoint returns disputes associated with all locations.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, disputes: table<dispute_id: string, id: string, amount_money: record, reason: string, state: string, due_at: string, disputed_payment: record, evidence_ids: list, card_brand: string, created_at: string, updated_at: string, brand_dispute_id: string, reported_date: string, reported_at: string, version: int, location_id: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "states" $states "scalar") (serialize-qp "location_id" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/disputes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveDispute
#
# GET /v2/disputes/{dispute_id}
# operationId: RetrieveDispute
export def "disputes RetrieveDispute" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, dispute: record<dispute_id: string, id: string, amount_money: record<amount: int, currency: string>, reason: string, state: string, due_at: string, disputed_payment: record<payment_id: string>, evidence_ids: list<string>, card_brand: string, created_at: string, updated_at: string, brand_dispute_id: string, reported_date: string, reported_at: string, version: int, location_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/disputes/($dispute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# AcceptDispute
#
# POST /v2/disputes/{dispute_id}/accept
# operationId: AcceptDispute
export def "disputes-accept AcceptDispute" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, dispute: record<dispute_id: string, id: string, amount_money: record<amount: int, currency: string>, reason: string, state: string, due_at: string, disputed_payment: record<payment_id: string>, evidence_ids: list<string>, card_brand: string, created_at: string, updated_at: string, brand_dispute_id: string, reported_date: string, reported_at: string, version: int, location_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/disputes/($dispute_id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListDisputeEvidence
#
# GET /v2/disputes/{dispute_id}/evidence
# operationId: ListDisputeEvidence
export def "disputes-evidence ListDisputeEvidence" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<evidence: table<evidence_id: string, id: string, dispute_id: string, evidence_file: record, evidence_text: string, uploaded_at: string, evidence_type: string>, errors: table<category: string, code: string, detail: string, field: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/disputes/($dispute_id)/evidence" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateDisputeEvidenceFile
#
# POST /v2/disputes/{dispute_id}/evidence-files
# operationId: CreateDisputeEvidenceFile
# --request shape: {idempotency_key: string, evidence_type?: "GENERIC_EVIDENCE"|"ONLINE_OR_APP_ACCESS_LOG"|"AUTHORIZATION_DOCUMENTATION"|"CANCELLATION_OR_REFUND_DOCUMENTATION"|"CARDHOLDER_COMMUNICATION"|"CARDHOLDER_INFORMATION"|"PURCHASE_ACKNOWLEDGEMENT"|"DUPLICATE_CHARGE_DOCUMENTATION"|"PRODUCT_OR_SERVICE_DESCRIPTION"|"RECEIPT"|"SERVICE_RECEIVED_DOCUMENTATION"|"PROOF_OF_DELIVERY_DOCUMENTATION"|"RELATED_TRANSACTION_DOCUMENTATION"|"REBUTTAL_EXPLANATION"|"TRACKING_NUMBER", content_type?: string}
export def "disputes-evidence-files CreateDisputeEvidenceFile" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request: record # Defines the parameters for a `CreateDisputeEvidenceFile` request. — shape: {idempotency_key: string, evidence_type?: "GENERIC_EVIDENCE"|"ONLINE_OR_APP_ACCESS_LOG"|"AUTHORIZATION_DOCUMENTATION"|"CANCELLATION_OR_REFUND_DOCUMENTATION"|"CARDHOLDER_COMMUNICATION"|"CARDHOLDER_INFORMATION"|"PURCHASE_ACKNOWLEDGEMENT"|"DUPLICATE_CHARGE_DOCUMENTATION"|"PRODUCT_OR_SERVICE_DESCRIPTION"|"RECEIPT"|"SERVICE_RECEIVED_DOCUMENTATION"|"PROOF_OF_DELIVERY_DOCUMENTATION"|"RELATED_TRANSACTION_DOCUMENTATION"|"REBUTTAL_EXPLANATION"|"TRACKING_NUMBER", content_type?: string}
  --image-file: string # format: binary
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<evidence_id: string, id: string, dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_text: string, uploaded_at: string, evidence_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/disputes/($dispute_id)/evidence-files")
  let body = {request: $request, image_file: $image_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# CreateDisputeEvidenceText
#
# POST /v2/disputes/{dispute_id}/evidence-text
# operationId: CreateDisputeEvidenceText
export def "disputes-evidence-text CreateDisputeEvidenceText" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique key identifying the request. For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --evidence-type: string@evidence-type-completer # The type of the dispute evidence.
  evidence_text: string # The evidence string.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<evidence_id: string, id: string, dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_text: string, uploaded_at: string, evidence_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/disputes/($dispute_id)/evidence-text")
  let body = {idempotency_key: $idempotency_key, evidence_type: $evidence_type, evidence_text: $evidence_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteDisputeEvidence
#
# DELETE /v2/disputes/{dispute_id}/evidence/{evidence_id}
# operationId: DeleteDisputeEvidence
export def "disputes-evidence DeleteDisputeEvidence" [
  dispute_id: string
  evidence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/disputes/($dispute_id)/evidence/($evidence_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveDisputeEvidence
#
# GET /v2/disputes/{dispute_id}/evidence/{evidence_id}
# operationId: RetrieveDisputeEvidence
export def "disputes-evidence RetrieveDisputeEvidence" [
  dispute_id: string
  evidence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, evidence: record<evidence_id: string, id: string, dispute_id: string, evidence_file: record<filename: string, filetype: string>, evidence_text: string, uploaded_at: string, evidence_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/disputes/($dispute_id)/evidence/($evidence_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# SubmitEvidence
#
# POST /v2/disputes/{dispute_id}/submit-evidence
# operationId: SubmitEvidence
export def "disputes-submit-evidence SubmitEvidence" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, dispute: record<dispute_id: string, id: string, amount_money: record<amount: int, currency: string>, reason: string, state: string, due_at: string, disputed_payment: record<payment_id: string>, evidence_ids: list<string>, card_brand: string, created_at: string, updated_at: string, brand_dispute_id: string, reported_date: string, reported_at: string, version: int, location_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/disputes/($dispute_id)/submit-evidence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListEmployees
#
# GET /v2/employees
# DEPRECATED
# operationId: ListEmployees
@deprecated
export def "employees ListEmployees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-id: string
  --status: string@status-completer # Specifies the EmployeeStatus to filter the employee by.
  --limit: int # The number of employees to be returned on each page.
  --cursor: string # The token required to retrieve the specified page of results.
]: nothing -> record<employees: table<id: string, first_name: string, last_name: string, email: string, phone_number: string, location_ids: list, status: string, is_owner: bool, created_at: string, updated_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/employees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveEmployee
#
# GET /v2/employees/{id}
# DEPRECATED
# operationId: RetrieveEmployee
@deprecated
export def "employees RetrieveEmployee" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<employee: record<id: string, first_name: string, last_name: string, email: string, phone_number: string, location_ids: list<string>, status: string, is_owner: bool, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/employees/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# SearchEvents
#
# POST /v2/events
# operationId: SearchEvents
# --query shape: {filter?: record, sort?: record}
export def "events SearchEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of events for your original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The maximum number of events to return in a single page. The response might contain fewer events. The default value is 100, which is also the maximum allowed value.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).  Default: 100
  --body-query: record # Contains query criteria for the search. — shape: {filter?: record, sort?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, events: table<merchant_id: string, location_id: string, type: string, event_id: string, created_at: string, data: record>, metadata: table<event_id: string, api_version: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/events")
  let body = {cursor: $cursor, limit: $limit, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DisableEvents
#
# PUT /v2/events/disable
# operationId: DisableEvents
export def "events-disable DisableEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/events/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# EnableEvents
#
# PUT /v2/events/enable
# operationId: EnableEvents
export def "events-enable EnableEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/events/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListEventTypes
#
# GET /v2/events/types
# operationId: ListEventTypes
export def "events-types ListEventTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The API version for which to list event types. Setting this field overrides the default version used by the application.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, event_types: list<string>, metadata: table<event_type: string, api_version_introduced: string, release_status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/events/types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListGiftCards
#
# GET /v2/gift-cards
# operationId: ListGiftCards
export def "gift-cards ListGiftCards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # If a [type](entity:GiftCardType) is provided, the endpoint returns gift cards of the specified type. Otherwise, the endpoint returns gift cards of all types.
  --state: string # If a [state](entity:GiftCardStatus) is provided, the endpoint returns the gift cards in the specified state. Otherwise, the endpoint returns the gift cards of all states.
  --limit: int # If a limit is provided, the endpoint returns only the specified number of results per page. The maximum value is 200. The default value is 30. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. If a cursor is not provided, the endpoint returns the first page of the results.  For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --customer-id: string # If a customer ID is provided, the endpoint returns only the gift cards linked to the specified customer.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_cards: table<id: string, type: string, gan_source: string, state: string, balance_money: record, gan: string, created_at: string, customer_ids: list>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "customer_id" $customer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/gift-cards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateGiftCard
#
# POST /v2/gift-cards
# operationId: CreateGiftCard
# --gift_card shape: {type: "PHYSICAL"|"DIGITAL", gan_source?: "SQUARE"|"OTHER", state?: "ACTIVE"|"DEACTIVATED"|"BLOCKED"|"PENDING", balance_money?: record, gan?: string}
export def "gift-cards CreateGiftCard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique identifier for this request, used to ensure idempotency. For more information,  see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
  location_id: string # The ID of the [location](entity:Location) where the gift card should be registered for  reporting purposes. Gift cards can be redeemed at any of the seller's locations.
  gift_card: record # Represents a Square gift card. — shape: {type: "PHYSICAL"|"DIGITAL", gan_source?: "SQUARE"|"OTHER", state?: "ACTIVE"|"DEACTIVATED"|"BLOCKED"|"PENDING", balance_money?: record, gan?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<id: string, type: string, gan_source: string, state: string, balance_money: record<amount: int, currency: string>, gan: string, created_at: string, customer_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/gift-cards")
  let body = {idempotency_key: $idempotency_key, location_id: $location_id, gift_card: $gift_card} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListGiftCardActivities
#
# GET /v2/gift-cards/activities
# operationId: ListGiftCardActivities
export def "gift-cards-activities ListGiftCardActivities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gift-card-id: string # If a gift card ID is provided, the endpoint returns activities related  to the specified gift card. Otherwise, the endpoint returns all gift card activities for  the seller.
  --type: string # If a [type](entity:GiftCardActivityType) is provided, the endpoint returns gift card activities of the specified type.  Otherwise, the endpoint returns all types of gift card activities.
  --location-id: string # If a location ID is provided, the endpoint returns gift card activities for the specified location.  Otherwise, the endpoint returns gift card activities for all locations.
  --begin-time: string # The timestamp for the beginning of the reporting period, in RFC 3339 format. This start time is inclusive. The default value is the current time minus one year.
  --end-time: string # The timestamp for the end of the reporting period, in RFC 3339 format. This end time is inclusive. The default value is the current time.
  --limit: int # If a limit is provided, the endpoint returns the specified number  of results (or fewer) per page. The maximum value is 100. The default value is 50. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. If a cursor is not provided, the endpoint returns the first page of the results. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --sort-order: string # The order in which the endpoint returns the activities, based on `created_at`. - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card_activities: table<id: string, type: string, location_id: string, created_at: string, gift_card_id: string, gift_card_gan: string, gift_card_balance_money: record, load_activity_details: record, activate_activity_details: record, redeem_activity_details: record, clear_balance_activity_details: record, deactivate_activity_details: record, adjust_increment_activity_details: record, adjust_decrement_activity_details: record, refund_activity_details: record, unlinked_activity_refund_activity_details: record, import_activity_details: record, block_activity_details: record, unblock_activity_details: record, import_reversal_activity_details: record, transfer_balance_to_activity_details: record, transfer_balance_from_activity_details: record>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gift_card_id" $gift_card_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/gift-cards/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateGiftCardActivity
#
# POST /v2/gift-cards/activities
# operationId: CreateGiftCardActivity
# --gift_card_activity shape: {type: "ACTIVATE"|"LOAD"|"REDEEM"|"CLEAR_BALANCE"|"DEACTIVATE"|"ADJUST_INCREMENT"|"ADJUST_DECREMENT"|"REFUND"|"UNLINKED_ACTIVITY_REFUND"|"IMPORT"|"BLOCK"|"UNBLOCK"|"IMPORT_REVERSAL"|"TRANSFER_BALANCE_FROM"|"TRANSFER_BALANCE_TO", location_id: string, gift_card_id?: string, gift_card_gan?: string, gift_card_balance_money?: record, load_activity_details?: record, activate_activity_details?: record, redeem_activity_details?: record, clear_balance_activity_details?: record, deactivate_activity_details?: record, adjust_increment_activity_details?: record, adjust_decrement_activity_details?: record, refund_activity_details?: record, unlinked_activity_refund_activity_details?: record, import_activity_details?: record, block_activity_details?: record, unblock_activity_details?: record, import_reversal_activity_details?: record, transfer_balance_to_activity_details?: record, transfer_balance_from_activity_details?: record}
export def "gift-cards-activities CreateGiftCardActivity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies the `CreateGiftCardActivity` request.
  gift_card_activity: record # Represents an action performed on a [gift card](entity:GiftCard) that affects its state or balance.  A gift card activity contains information about a specific activity type. For example, a `REDEEM` activity includes a `redeem_activity_details` field that contains information about the redemption. — shape: {type: "ACTIVATE"|"LOAD"|"REDEEM"|"CLEAR_BALANCE"|"DEACTIVATE"|"ADJUST_INCREMENT"|"ADJUST_DECREMENT"|"REFUND"|"UNLINKED_ACTIVITY_REFUND"|"IMPORT"|"BLOCK"|"UNBLOCK"|"IMPORT_REVERSAL"|"TRANSFER_BALANCE_FROM"|"TRANSFER_BALANCE_TO", location_id: string, gift_card_id?: string, gift_card_gan?: string, gift_card_balance_money?: record, load_activity_details?: record, activate_activity_details?: record, redeem_activity_details?: record, clear_balance_activity_details?: record, deactivate_activity_details?: record, adjust_increment_activity_details?: record, adjust_decrement_activity_details?: record, refund_activity_details?: record, unlinked_activity_refund_activity_details?: record, import_activity_details?: record, block_activity_details?: record, unblock_activity_details?: record, import_reversal_activity_details?: record, transfer_balance_to_activity_details?: record, transfer_balance_from_activity_details?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card_activity: record<id: string, type: string, location_id: string, created_at: string, gift_card_id: string, gift_card_gan: string, gift_card_balance_money: record<amount: int, currency: string>, load_activity_details: record<amount_money: record, order_id: string, line_item_uid: string, reference_id: string, buyer_payment_instrument_ids: list>, activate_activity_details: record<amount_money: record, order_id: string, line_item_uid: string, reference_id: string, buyer_payment_instrument_ids: list>, redeem_activity_details: record<amount_money: record, payment_id: string, reference_id: string, status: string>, clear_balance_activity_details: record<reason: string>, deactivate_activity_details: record<reason: string>, adjust_increment_activity_details: record<amount_money: record, reason: string>, adjust_decrement_activity_details: record<amount_money: record, reason: string>, refund_activity_details: record<redeem_activity_id: string, amount_money: record, reference_id: string, payment_id: string>, unlinked_activity_refund_activity_details: record<amount_money: record, reference_id: string, payment_id: string>, import_activity_details: record<amount_money: record>, block_activity_details: record<reason: string>, unblock_activity_details: record<reason: string>, import_reversal_activity_details: record<amount_money: record>, transfer_balance_to_activity_details: record<transfer_from_gift_card_id: string, amount_money: record>, transfer_balance_from_activity_details: record<transfer_to_gift_card_id: string, amount_money: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/gift-cards/activities")
  let body = {idempotency_key: $idempotency_key, gift_card_activity: $gift_card_activity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveGiftCardFromGAN
#
# POST /v2/gift-cards/from-gan
# operationId: RetrieveGiftCardFromGAN
export def "gift-cards-from-gan RetrieveGiftCardFromGAN" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  gan: string # The gift card account number (GAN) of the gift card to retrieve. The maximum length of a GAN is 255 digits to account for third-party GANs that have been imported. Square-issued gift cards have 16-digit GANs.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<id: string, type: string, gan_source: string, state: string, balance_money: record<amount: int, currency: string>, gan: string, created_at: string, customer_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/gift-cards/from-gan")
  let body = {gan: $gan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveGiftCardFromNonce
#
# POST /v2/gift-cards/from-nonce
# operationId: RetrieveGiftCardFromNonce
export def "gift-cards-from-nonce RetrieveGiftCardFromNonce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  nonce: string # The payment token of the gift card to retrieve. Payment tokens are generated by the  Web Payments SDK or In-App Payments SDK.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<id: string, type: string, gan_source: string, state: string, balance_money: record<amount: int, currency: string>, gan: string, created_at: string, customer_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/gift-cards/from-nonce")
  let body = {nonce: $nonce} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# LinkCustomerToGiftCard
#
# POST /v2/gift-cards/{gift_card_id}/link-customer
# operationId: LinkCustomerToGiftCard
export def "gift-cards-link-customer LinkCustomerToGiftCard" [
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer_id: string # The ID of the customer to link to the gift card.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<id: string, type: string, gan_source: string, state: string, balance_money: record<amount: int, currency: string>, gan: string, created_at: string, customer_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/gift-cards/($gift_card_id)/link-customer")
  let body = {customer_id: $customer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# UnlinkCustomerFromGiftCard
#
# POST /v2/gift-cards/{gift_card_id}/unlink-customer
# operationId: UnlinkCustomerFromGiftCard
export def "gift-cards-unlink-customer UnlinkCustomerFromGiftCard" [
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer_id: string # The ID of the customer to unlink from the gift card.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<id: string, type: string, gan_source: string, state: string, balance_money: record<amount: int, currency: string>, gan: string, created_at: string, customer_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/gift-cards/($gift_card_id)/unlink-customer")
  let body = {customer_id: $customer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveGiftCard
#
# GET /v2/gift-cards/{id}
# operationId: RetrieveGiftCard
export def "gift-cards RetrieveGiftCard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, gift_card: record<id: string, type: string, gan_source: string, state: string, balance_money: record<amount: int, currency: string>, gan: string, created_at: string, customer_ids: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/gift-cards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeprecatedRetrieveInventoryAdjustment
#
# GET /v2/inventory/adjustment/{adjustment_id}
# DEPRECATED
# operationId: DeprecatedRetrieveInventoryAdjustment
@deprecated
export def "inventory-adjustment DeprecatedRetrieveInventoryAdjustment" [
  adjustment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, adjustment: record<id: string, reference_id: string, from_state: string, to_state: string, location_id: string, catalog_object_id: string, catalog_object_type: string, quantity: string, total_price_money: record<amount: int, currency: string>, occurred_at: string, created_at: string, source: record<product: string, application_id: string, name: string>, employee_id: string, team_member_id: string, transaction_id: string, refund_id: string, purchase_order_id: string, goods_receipt_id: string, adjustment_group: record<id: string, root_adjustment_id: string, from_state: string, to_state: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/inventory/adjustment/($adjustment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveInventoryAdjustment
#
# GET /v2/inventory/adjustments/{adjustment_id}
# operationId: RetrieveInventoryAdjustment
export def "inventory-adjustments RetrieveInventoryAdjustment" [
  adjustment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, adjustment: record<id: string, reference_id: string, from_state: string, to_state: string, location_id: string, catalog_object_id: string, catalog_object_type: string, quantity: string, total_price_money: record<amount: int, currency: string>, occurred_at: string, created_at: string, source: record<product: string, application_id: string, name: string>, employee_id: string, team_member_id: string, transaction_id: string, refund_id: string, purchase_order_id: string, goods_receipt_id: string, adjustment_group: record<id: string, root_adjustment_id: string, from_state: string, to_state: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/inventory/adjustments/($adjustment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeprecatedBatchChangeInventory
#
# POST /v2/inventory/batch-change
# DEPRECATED
# operationId: DeprecatedBatchChangeInventory
# --changes item shape: {type?: "PHYSICAL_COUNT"|"ADJUSTMENT"|"TRANSFER", physical_count?: record, adjustment?: record, transfer?: record, measurement_unit?: record}
@deprecated
export def "inventory-batch-change DeprecatedBatchChangeInventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A client-supplied, universally unique identifier (UUID) for the request.  See [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) in the [API Development 101](https://developer.squareup.com/docs/buildbasics) section for more information.
  --changes: list # The set of physical counts and inventory adjustments to be made. Changes are applied based on the client-supplied timestamp and may be sent out of order. (nullable) — item shape: {type?: "PHYSICAL_COUNT"|"ADJUSTMENT"|"TRANSFER", physical_count?: record, adjustment?: record, transfer?: record, measurement_unit?: record}
  --ignore-unchanged-counts: oneof<nothing, bool> # Indicates whether the current physical count should be ignored if the quantity is unchanged since the last physical count. Default: `true`. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, counts: table<catalog_object_id: string, catalog_object_type: string, state: string, location_id: string, quantity: string, calculated_at: string, is_estimated: bool>, changes: table<type: string, physical_count: record, adjustment: record, transfer: record, measurement_unit: record, measurement_unit_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/batch-change")
  let body = {idempotency_key: $idempotency_key, changes: $changes, ignore_unchanged_counts: $ignore_unchanged_counts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeprecatedBatchRetrieveInventoryChanges
#
# POST /v2/inventory/batch-retrieve-changes
# DEPRECATED
# operationId: DeprecatedBatchRetrieveInventoryChanges
@deprecated
export def "inventory-batch-retrieve-changes DeprecatedBatchRetrieveInventoryChanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --catalog-object-ids: list # The filter to return results by `CatalogObject` ID. The filter is only applicable when set. The default value is null. (nullable)
  --location-ids: list # The filter to return results by `Location` ID. The filter is only applicable when set. The default value is null. (nullable)
  --types: list # The filter to return results by `InventoryChangeType` values other than `TRANSFER`. The default value is `[PHYSICAL_COUNT, ADJUSTMENT]`. (nullable)
  --states: list # The filter to return `ADJUSTMENT` query results by `InventoryState`. This filter is only applied when set. The default value is null. (nullable)
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`). (nullable)
  --updated-before: string # The filter to return results with their `created_at` or `calculated_at` value strictly before the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`). (nullable)
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query.  See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information. (nullable)
  --limit: int # The number of [records](entity:InventoryChange) to return. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, changes: table<type: string, physical_count: record, adjustment: record, transfer: record, measurement_unit: record, measurement_unit_id: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/batch-retrieve-changes")
  let body = {catalog_object_ids: $catalog_object_ids, location_ids: $location_ids, types: $types, states: $states, updated_after: $updated_after, updated_before: $updated_before, cursor: $cursor, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeprecatedBatchRetrieveInventoryCounts
#
# POST /v2/inventory/batch-retrieve-counts
# DEPRECATED
# operationId: DeprecatedBatchRetrieveInventoryCounts
@deprecated
export def "inventory-batch-retrieve-counts DeprecatedBatchRetrieveInventoryCounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --catalog-object-ids: list # The filter to return results by `CatalogObject` ID. The filter is applicable only when set.  The default is null. (nullable)
  --location-ids: list # The filter to return results by `Location` ID. This filter is applicable only when set. The default is null. (nullable)
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`). (nullable)
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query.  See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information. (nullable)
  --states: list # The filter to return results by `InventoryState`. The filter is only applicable when set. Ignored are untracked states of `NONE`, `SOLD`, and `UNLINKED_RETURN`. The default is null. (nullable)
  --limit: int # The number of [records](entity:InventoryCount) to return. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, counts: table<catalog_object_id: string, catalog_object_type: string, state: string, location_id: string, quantity: string, calculated_at: string, is_estimated: bool>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/batch-retrieve-counts")
  let body = {catalog_object_ids: $catalog_object_ids, location_ids: $location_ids, updated_after: $updated_after, cursor: $cursor, states: $states, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BatchChangeInventory
#
# POST /v2/inventory/changes/batch-create
# operationId: BatchChangeInventory
# --changes item shape: {type?: "PHYSICAL_COUNT"|"ADJUSTMENT"|"TRANSFER", physical_count?: record, adjustment?: record, transfer?: record, measurement_unit?: record}
export def "inventory-changes-batch-create BatchChangeInventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A client-supplied, universally unique identifier (UUID) for the request.  See [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) in the [API Development 101](https://developer.squareup.com/docs/buildbasics) section for more information.
  --changes: list # The set of physical counts and inventory adjustments to be made. Changes are applied based on the client-supplied timestamp and may be sent out of order. (nullable) — item shape: {type?: "PHYSICAL_COUNT"|"ADJUSTMENT"|"TRANSFER", physical_count?: record, adjustment?: record, transfer?: record, measurement_unit?: record}
  --ignore-unchanged-counts: oneof<nothing, bool> # Indicates whether the current physical count should be ignored if the quantity is unchanged since the last physical count. Default: `true`. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, counts: table<catalog_object_id: string, catalog_object_type: string, state: string, location_id: string, quantity: string, calculated_at: string, is_estimated: bool>, changes: table<type: string, physical_count: record, adjustment: record, transfer: record, measurement_unit: record, measurement_unit_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/changes/batch-create")
  let body = {idempotency_key: $idempotency_key, changes: $changes, ignore_unchanged_counts: $ignore_unchanged_counts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BatchRetrieveInventoryChanges
#
# POST /v2/inventory/changes/batch-retrieve
# operationId: BatchRetrieveInventoryChanges
export def "inventory-changes-batch-retrieve BatchRetrieveInventoryChanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --catalog-object-ids: list # The filter to return results by `CatalogObject` ID. The filter is only applicable when set. The default value is null. (nullable)
  --location-ids: list # The filter to return results by `Location` ID. The filter is only applicable when set. The default value is null. (nullable)
  --types: list # The filter to return results by `InventoryChangeType` values other than `TRANSFER`. The default value is `[PHYSICAL_COUNT, ADJUSTMENT]`. (nullable)
  --states: list # The filter to return `ADJUSTMENT` query results by `InventoryState`. This filter is only applied when set. The default value is null. (nullable)
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`). (nullable)
  --updated-before: string # The filter to return results with their `created_at` or `calculated_at` value strictly before the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`). (nullable)
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query.  See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information. (nullable)
  --limit: int # The number of [records](entity:InventoryChange) to return. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, changes: table<type: string, physical_count: record, adjustment: record, transfer: record, measurement_unit: record, measurement_unit_id: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/changes/batch-retrieve")
  let body = {catalog_object_ids: $catalog_object_ids, location_ids: $location_ids, types: $types, states: $states, updated_after: $updated_after, updated_before: $updated_before, cursor: $cursor, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BatchRetrieveInventoryCounts
#
# POST /v2/inventory/counts/batch-retrieve
# operationId: BatchRetrieveInventoryCounts
export def "inventory-counts-batch-retrieve BatchRetrieveInventoryCounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --catalog-object-ids: list # The filter to return results by `CatalogObject` ID. The filter is applicable only when set.  The default is null. (nullable)
  --location-ids: list # The filter to return results by `Location` ID. This filter is applicable only when set. The default is null. (nullable)
  --updated-after: string # The filter to return results with their `calculated_at` value after the given time as specified in an RFC 3339 timestamp. The default value is the UNIX epoch of (`1970-01-01T00:00:00Z`). (nullable)
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query.  See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information. (nullable)
  --states: list # The filter to return results by `InventoryState`. The filter is only applicable when set. Ignored are untracked states of `NONE`, `SOLD`, and `UNLINKED_RETURN`. The default is null. (nullable)
  --limit: int # The number of [records](entity:InventoryCount) to return. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, counts: table<catalog_object_id: string, catalog_object_type: string, state: string, location_id: string, quantity: string, calculated_at: string, is_estimated: bool>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/inventory/counts/batch-retrieve")
  let body = {catalog_object_ids: $catalog_object_ids, location_ids: $location_ids, updated_after: $updated_after, cursor: $cursor, states: $states, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeprecatedRetrieveInventoryPhysicalCount
#
# GET /v2/inventory/physical-count/{physical_count_id}
# DEPRECATED
# operationId: DeprecatedRetrieveInventoryPhysicalCount
@deprecated
export def "inventory-physical-count DeprecatedRetrieveInventoryPhysicalCount" [
  physical_count_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, count: record<id: string, reference_id: string, catalog_object_id: string, catalog_object_type: string, state: string, location_id: string, quantity: string, source: record<product: string, application_id: string, name: string>, employee_id: string, team_member_id: string, occurred_at: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/inventory/physical-count/($physical_count_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveInventoryPhysicalCount
#
# GET /v2/inventory/physical-counts/{physical_count_id}
# operationId: RetrieveInventoryPhysicalCount
export def "inventory-physical-counts RetrieveInventoryPhysicalCount" [
  physical_count_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, count: record<id: string, reference_id: string, catalog_object_id: string, catalog_object_type: string, state: string, location_id: string, quantity: string, source: record<product: string, application_id: string, name: string>, employee_id: string, team_member_id: string, occurred_at: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/inventory/physical-counts/($physical_count_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveInventoryTransfer
#
# GET /v2/inventory/transfers/{transfer_id}
# operationId: RetrieveInventoryTransfer
export def "inventory-transfers RetrieveInventoryTransfer" [
  transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, transfer: record<id: string, reference_id: string, state: string, from_location_id: string, to_location_id: string, catalog_object_id: string, catalog_object_type: string, quantity: string, occurred_at: string, created_at: string, source: record<product: string, application_id: string, name: string>, employee_id: string, team_member_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/inventory/transfers/($transfer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveInventoryCount
#
# GET /v2/inventory/{catalog_object_id}
# operationId: RetrieveInventoryCount
export def "inventory RetrieveInventoryCount" [
  catalog_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-ids: string # The [Location](entity:Location) IDs to look up as a comma-separated list. An empty list queries all locations.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query.  See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, counts: table<catalog_object_id: string, catalog_object_type: string, state: string, location_id: string, quantity: string, calculated_at: string, is_estimated: bool>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_ids" $location_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/inventory/($catalog_object_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveInventoryChanges
#
# GET /v2/inventory/{catalog_object_id}/changes
# DEPRECATED
# operationId: RetrieveInventoryChanges
@deprecated
export def "inventory-changes RetrieveInventoryChanges" [
  catalog_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-ids: string # The [Location](entity:Location) IDs to look up as a comma-separated list. An empty list queries all locations.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query.  See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, changes: table<type: string, physical_count: record, adjustment: record, transfer: record, measurement_unit: record, measurement_unit_id: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_ids" $location_ids "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/inventory/($catalog_object_id)/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListInvoices
#
# GET /v2/invoices
# operationId: ListInvoices
export def "invoices ListInvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-id: string # The ID of the location for which to list invoices.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint.  Provide this cursor to retrieve the next set of results for your original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The maximum number of invoices to return (200 is the maximum `limit`).  If not provided, the server uses a default limit of 100 invoices.
]: nothing -> record<invoices: table<id: string, version: int, location_id: string, order_id: string, primary_recipient: record, payment_requests: list, delivery_method: string, invoice_number: string, title: string, description: string, scheduled_at: string, public_url: string, next_payment_amount_money: record, status: string, timezone: string, created_at: string, updated_at: string, accepted_payment_methods: record, custom_fields: list, subscription_id: string, sale_or_service_date: string, payment_conditions: string, store_payment_method_enabled: bool, attachments: list, creator_team_member_id: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateInvoice
#
# POST /v2/invoices
# operationId: CreateInvoice
# --invoice shape: {version?: int, location_id?: string, order_id?: string, primary_recipient?: record, payment_requests?: list, delivery_method?: "EMAIL"|"SHARE_MANUALLY"|"SMS", invoice_number?: string, title?: string, description?: string, scheduled_at?: string, next_payment_amount_money?: record, status?: "DRAFT"|"UNPAID"|"SCHEDULED"|"PARTIALLY_PAID"|"PAID"|"PARTIALLY_REFUNDED"|"REFUNDED"|"CANCELED"|"FAILED"|"PAYMENT_PENDING", accepted_payment_methods?: record, custom_fields?: list, sale_or_service_date?: string, payment_conditions?: string, store_payment_method_enabled?: bool}
export def "invoices CreateInvoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invoice: record # Stores information about an invoice. You use the Invoices API to create and manage invoices. For more information, see [Invoices API Overview](https://developer.squareup.com/docs/invoices-api/overview). — shape: {version?: int, location_id?: string, order_id?: string, primary_recipient?: record, payment_requests?: list, delivery_method?: "EMAIL"|"SHARE_MANUALLY"|"SMS", invoice_number?: string, title?: string, description?: string, scheduled_at?: string, next_payment_amount_money?: record, status?: "DRAFT"|"UNPAID"|"SCHEDULED"|"PARTIALLY_PAID"|"PAID"|"PARTIALLY_REFUNDED"|"REFUNDED"|"CANCELED"|"FAILED"|"PAYMENT_PENDING", accepted_payment_methods?: record, custom_fields?: list, sale_or_service_date?: string, payment_conditions?: string, store_payment_method_enabled?: bool}
  --idempotency-key: string # A unique string that identifies the `CreateInvoice` request. If you do not  provide `idempotency_key` (or provide an empty string as the value), the endpoint  treats each request as independent.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<invoice: record<id: string, version: int, location_id: string, order_id: string, primary_recipient: record<customer_id: string, given_name: string, family_name: string, email_address: string, address: record, phone_number: string, company_name: string, tax_ids: record>, payment_requests: list<record>, delivery_method: string, invoice_number: string, title: string, description: string, scheduled_at: string, public_url: string, next_payment_amount_money: record<amount: int, currency: string>, status: string, timezone: string, created_at: string, updated_at: string, accepted_payment_methods: record<card: bool, square_gift_card: bool, bank_account: bool, buy_now_pay_later: bool, cash_app_pay: bool>, custom_fields: list<record>, subscription_id: string, sale_or_service_date: string, payment_conditions: string, store_payment_method_enabled: bool, attachments: list<record>, creator_team_member_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/invoices")
  let body = {invoice: $invoice, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchInvoices
#
# POST /v2/invoices/search
# operationId: SearchInvoices
# --query shape: {filter: record, sort?: record}
export def "invoices-search SearchInvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # Describes query criteria for searching invoices. — shape: {filter: record, sort?: record}
  --limit: int # The maximum number of invoices to return (200 is the maximum `limit`).  If not provided, the server uses a default limit of 100 invoices.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint.  Provide this cursor to retrieve the next set of results for your original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: any -> record<invoices: table<id: string, version: int, location_id: string, order_id: string, primary_recipient: record, payment_requests: list, delivery_method: string, invoice_number: string, title: string, description: string, scheduled_at: string, public_url: string, next_payment_amount_money: record, status: string, timezone: string, created_at: string, updated_at: string, accepted_payment_methods: record, custom_fields: list, subscription_id: string, sale_or_service_date: string, payment_conditions: string, store_payment_method_enabled: bool, attachments: list, creator_team_member_id: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/invoices/search")
  let body = {query: $body_query, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteInvoice
#
# DELETE /v2/invoices/{invoice_id}
# operationId: DeleteInvoice
export def "invoices DeleteInvoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # The version of the [invoice](entity:Invoice) to delete. If you do not know the version, you can call [GetInvoice](api-endpoint:Invoices-GetInvoice) or  [ListInvoices](api-endpoint:Invoices-ListInvoices).
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/invoices/($invoice_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetInvoice
#
# GET /v2/invoices/{invoice_id}
# operationId: GetInvoice
export def "invoices GetInvoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invoice: record<id: string, version: int, location_id: string, order_id: string, primary_recipient: record<customer_id: string, given_name: string, family_name: string, email_address: string, address: record, phone_number: string, company_name: string, tax_ids: record>, payment_requests: list<record>, delivery_method: string, invoice_number: string, title: string, description: string, scheduled_at: string, public_url: string, next_payment_amount_money: record<amount: int, currency: string>, status: string, timezone: string, created_at: string, updated_at: string, accepted_payment_methods: record<card: bool, square_gift_card: bool, bank_account: bool, buy_now_pay_later: bool, cash_app_pay: bool>, custom_fields: list<record>, subscription_id: string, sale_or_service_date: string, payment_conditions: string, store_payment_method_enabled: bool, attachments: list<record>, creator_team_member_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoices/($invoice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateInvoice
#
# PUT /v2/invoices/{invoice_id}
# operationId: UpdateInvoice
# --invoice shape: {version?: int, location_id?: string, order_id?: string, primary_recipient?: record, payment_requests?: list, delivery_method?: "EMAIL"|"SHARE_MANUALLY"|"SMS", invoice_number?: string, title?: string, description?: string, scheduled_at?: string, next_payment_amount_money?: record, status?: "DRAFT"|"UNPAID"|"SCHEDULED"|"PARTIALLY_PAID"|"PAID"|"PARTIALLY_REFUNDED"|"REFUNDED"|"CANCELED"|"FAILED"|"PAYMENT_PENDING", accepted_payment_methods?: record, custom_fields?: list, sale_or_service_date?: string, payment_conditions?: string, store_payment_method_enabled?: bool}
export def "invoices UpdateInvoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invoice: record # Stores information about an invoice. You use the Invoices API to create and manage invoices. For more information, see [Invoices API Overview](https://developer.squareup.com/docs/invoices-api/overview). — shape: {version?: int, location_id?: string, order_id?: string, primary_recipient?: record, payment_requests?: list, delivery_method?: "EMAIL"|"SHARE_MANUALLY"|"SMS", invoice_number?: string, title?: string, description?: string, scheduled_at?: string, next_payment_amount_money?: record, status?: "DRAFT"|"UNPAID"|"SCHEDULED"|"PARTIALLY_PAID"|"PAID"|"PARTIALLY_REFUNDED"|"REFUNDED"|"CANCELED"|"FAILED"|"PAYMENT_PENDING", accepted_payment_methods?: record, custom_fields?: list, sale_or_service_date?: string, payment_conditions?: string, store_payment_method_enabled?: bool}
  --idempotency-key: string # A unique string that identifies the `UpdateInvoice` request. If you do not provide `idempotency_key` (or provide an empty string as the value), the endpoint treats each request as independent.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
  --fields-to-clear: list # The list of fields to clear. Although this field is currently supported, we recommend using null values or the `remove` field when possible. For examples, see [Update an Invoice](https://developer.squareup.com/docs/invoices-api/update-invoices). (nullable)
]: any -> record<invoice: record<id: string, version: int, location_id: string, order_id: string, primary_recipient: record<customer_id: string, given_name: string, family_name: string, email_address: string, address: record, phone_number: string, company_name: string, tax_ids: record>, payment_requests: list<record>, delivery_method: string, invoice_number: string, title: string, description: string, scheduled_at: string, public_url: string, next_payment_amount_money: record<amount: int, currency: string>, status: string, timezone: string, created_at: string, updated_at: string, accepted_payment_methods: record<card: bool, square_gift_card: bool, bank_account: bool, buy_now_pay_later: bool, cash_app_pay: bool>, custom_fields: list<record>, subscription_id: string, sale_or_service_date: string, payment_conditions: string, store_payment_method_enabled: bool, attachments: list<record>, creator_team_member_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoices/($invoice_id)")
  let body = {invoice: $invoice, idempotency_key: $idempotency_key, fields_to_clear: $fields_to_clear} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateInvoiceAttachment
#
# POST /v2/invoices/{invoice_id}/attachments
# operationId: CreateInvoiceAttachment
# --request shape: {idempotency_key?: string, description?: string}
export def "invoices-attachments CreateInvoiceAttachment" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request: record # Represents a [CreateInvoiceAttachment](api-endpoint:Invoices-CreateInvoiceAttachment) request. (e.g. {description: Service contract, idempotency_key: ae5e84f9-4742-4fc1-ba12-a3ce3748f1c3}) — shape: {idempotency_key?: string, description?: string}
  --image-file: string # format: binary
]: any -> record<attachment: record<id: string, filename: string, description: string, filesize: int, hash: string, mime_type: string, uploaded_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoices/($invoice_id)/attachments")
  let body = {request: $request, image_file: $image_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# DeleteInvoiceAttachment
#
# DELETE /v2/invoices/{invoice_id}/attachments/{attachment_id}
# operationId: DeleteInvoiceAttachment
export def "invoices-attachments DeleteInvoiceAttachment" [
  invoice_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoices/($invoice_id)/attachments/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CancelInvoice
#
# POST /v2/invoices/{invoice_id}/cancel
# operationId: CancelInvoice
export def "invoices-cancel CancelInvoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  version: int # The version of the [invoice](entity:Invoice) to cancel. If you do not know the version, you can call  [GetInvoice](api-endpoint:Invoices-GetInvoice) or [ListInvoices](api-endpoint:Invoices-ListInvoices).
]: any -> record<invoice: record<id: string, version: int, location_id: string, order_id: string, primary_recipient: record<customer_id: string, given_name: string, family_name: string, email_address: string, address: record, phone_number: string, company_name: string, tax_ids: record>, payment_requests: list<record>, delivery_method: string, invoice_number: string, title: string, description: string, scheduled_at: string, public_url: string, next_payment_amount_money: record<amount: int, currency: string>, status: string, timezone: string, created_at: string, updated_at: string, accepted_payment_methods: record<card: bool, square_gift_card: bool, bank_account: bool, buy_now_pay_later: bool, cash_app_pay: bool>, custom_fields: list<record>, subscription_id: string, sale_or_service_date: string, payment_conditions: string, store_payment_method_enabled: bool, attachments: list<record>, creator_team_member_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoices/($invoice_id)/cancel")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PublishInvoice
#
# POST /v2/invoices/{invoice_id}/publish
# operationId: PublishInvoice
export def "invoices-publish PublishInvoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  version: int # The version of the [invoice](entity:Invoice) to publish. This must match the current version of the invoice; otherwise, the request is rejected.
  --idempotency-key: string # A unique string that identifies the `PublishInvoice` request. If you do not  provide `idempotency_key` (or provide an empty string as the value), the endpoint  treats each request as independent.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<invoice: record<id: string, version: int, location_id: string, order_id: string, primary_recipient: record<customer_id: string, given_name: string, family_name: string, email_address: string, address: record, phone_number: string, company_name: string, tax_ids: record>, payment_requests: list<record>, delivery_method: string, invoice_number: string, title: string, description: string, scheduled_at: string, public_url: string, next_payment_amount_money: record<amount: int, currency: string>, status: string, timezone: string, created_at: string, updated_at: string, accepted_payment_methods: record<card: bool, square_gift_card: bool, bank_account: bool, buy_now_pay_later: bool, cash_app_pay: bool>, custom_fields: list<record>, subscription_id: string, sale_or_service_date: string, payment_conditions: string, store_payment_method_enabled: bool, attachments: list<record>, creator_team_member_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoices/($invoice_id)/publish")
  let body = {version: $version, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListBreakTypes
#
# GET /v2/labor/break-types
# operationId: ListBreakTypes
export def "labor-break-types ListBreakTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-id: string # Filter the returned `BreakType` results to only those that are associated with the specified location.
  --limit: int # The maximum number of `BreakType` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `BreakType` results to fetch.
]: nothing -> record<break_types: table<id: string, location_id: string, break_name: string, expected_duration: string, is_paid: bool, version: int, created_at: string, updated_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/labor/break-types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateBreakType
#
# POST /v2/labor/break-types
# operationId: CreateBreakType
# --break_type shape: {id?: string, location_id: string, break_name: string, expected_duration: string, is_paid: bool, version?: int}
export def "labor-break-types CreateBreakType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string value to ensure the idempotency of the operation.
  break_type: record # A template for a type of [break](entity:Break) that can be added to a [timecard](entity:Timecard), including the expected duration and paid status. — shape: {id?: string, location_id: string, break_name: string, expected_duration: string, is_paid: bool, version?: int}
]: any -> record<break_type: record<id: string, location_id: string, break_name: string, expected_duration: string, is_paid: bool, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/break-types")
  let body = {idempotency_key: $idempotency_key, break_type: $break_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteBreakType
#
# DELETE /v2/labor/break-types/{id}
# operationId: DeleteBreakType
export def "labor-break-types DeleteBreakType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/break-types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetBreakType
#
# GET /v2/labor/break-types/{id}
# operationId: GetBreakType
export def "labor-break-types GetBreakType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<break_type: record<id: string, location_id: string, break_name: string, expected_duration: string, is_paid: bool, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/break-types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateBreakType
#
# PUT /v2/labor/break-types/{id}
# operationId: UpdateBreakType
# --break_type shape: {id?: string, location_id: string, break_name: string, expected_duration: string, is_paid: bool, version?: int}
export def "labor-break-types UpdateBreakType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  break_type: record # A template for a type of [break](entity:Break) that can be added to a [timecard](entity:Timecard), including the expected duration and paid status. — shape: {id?: string, location_id: string, break_name: string, expected_duration: string, is_paid: bool, version?: int}
]: any -> record<break_type: record<id: string, location_id: string, break_name: string, expected_duration: string, is_paid: bool, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/break-types/($id)")
  let body = {break_type: $break_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListEmployeeWages
#
# GET /v2/labor/employee-wages
# DEPRECATED
# operationId: ListEmployeeWages
@deprecated
export def "labor-employee-wages ListEmployeeWages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --employee-id: string # Filter the returned wages to only those that are associated with the specified employee.
  --limit: int # The maximum number of `EmployeeWage` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `EmployeeWage` results to fetch.
]: nothing -> record<employee_wages: table<id: string, employee_id: string, title: string, hourly_rate: record>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "employee_id" $employee_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/labor/employee-wages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetEmployeeWage
#
# GET /v2/labor/employee-wages/{id}
# DEPRECATED
# operationId: GetEmployeeWage
@deprecated
export def "labor-employee-wages GetEmployeeWage" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<employee_wage: record<id: string, employee_id: string, title: string, hourly_rate: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/employee-wages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateScheduledShift
#
# POST /v2/labor/scheduled-shifts
# operationId: CreateScheduledShift
# --scheduled_shift shape: {id?: string, draft_shift_details?: record, published_shift_details?: record, version?: int}
export def "labor-scheduled-shifts CreateScheduledShift" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique identifier for the `CreateScheduledShift` request, used to ensure the [idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) of the operation.
  scheduled_shift: record # Represents a specific time slot in a work schedule. This object is used to manage the lifecycle of a scheduled shift from the draft to published state. A scheduled shift contains the latest draft shift details and current published shift details. — shape: {id?: string, draft_shift_details?: record, published_shift_details?: record, version?: int}
]: any -> record<scheduled_shift: record<id: string, draft_shift_details: record<team_member_id: string, location_id: string, job_id: string, start_at: string, end_at: string, notes: string, is_deleted: bool, timezone: string>, published_shift_details: record<team_member_id: string, location_id: string, job_id: string, start_at: string, end_at: string, notes: string, is_deleted: bool, timezone: string>, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/scheduled-shifts")
  let body = {idempotency_key: $idempotency_key, scheduled_shift: $scheduled_shift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkPublishScheduledShifts
#
# POST /v2/labor/scheduled-shifts/bulk-publish
# operationId: BulkPublishScheduledShifts
export def "labor-scheduled-shifts-bulk-publish BulkPublishScheduledShifts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scheduled_shifts: record # A map of 1 to 100 key-value pairs that represent individual publish requests.  - Each key is the ID of a scheduled shift you want to publish. - Each value is a `BulkPublishScheduledShiftsData` object that contains the `version` field or is an empty object.
  --scheduled-shift-notification-audience: string@scheduled-shift-notification-audience-completer # Indicates whether Square sends an email notification to team members when a scheduled shift is published and which team members receive the notification.
]: any -> record<responses: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/scheduled-shifts/bulk-publish")
  let body = {scheduled_shifts: $scheduled_shifts, scheduled_shift_notification_audience: $scheduled_shift_notification_audience} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchScheduledShifts
#
# POST /v2/labor/scheduled-shifts/search
# operationId: SearchScheduledShifts
# --query shape: {filter?: record, sort?: record}
export def "labor-scheduled-shifts-search SearchScheduledShifts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # Represents filter and sort criteria for the `query` field in a [SearchScheduledShifts](api-endpoint:Labor-SearchScheduledShifts) request. — shape: {filter?: record, sort?: record}
  --limit: int # The maximum number of results to return in a single response page. The default value is 50.
  --cursor: string # The pagination cursor returned by the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: any -> record<scheduled_shifts: table<id: string, draft_shift_details: record, published_shift_details: record, version: int, created_at: string, updated_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/scheduled-shifts/search")
  let body = {query: $body_query, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveScheduledShift
#
# GET /v2/labor/scheduled-shifts/{id}
# operationId: RetrieveScheduledShift
export def "labor-scheduled-shifts RetrieveScheduledShift" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scheduled_shift: record<id: string, draft_shift_details: record<team_member_id: string, location_id: string, job_id: string, start_at: string, end_at: string, notes: string, is_deleted: bool, timezone: string>, published_shift_details: record<team_member_id: string, location_id: string, job_id: string, start_at: string, end_at: string, notes: string, is_deleted: bool, timezone: string>, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/scheduled-shifts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateScheduledShift
#
# PUT /v2/labor/scheduled-shifts/{id}
# operationId: UpdateScheduledShift
# --scheduled_shift shape: {id?: string, draft_shift_details?: record, published_shift_details?: record, version?: int}
export def "labor-scheduled-shifts UpdateScheduledShift" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scheduled_shift: record # Represents a specific time slot in a work schedule. This object is used to manage the lifecycle of a scheduled shift from the draft to published state. A scheduled shift contains the latest draft shift details and current published shift details. — shape: {id?: string, draft_shift_details?: record, published_shift_details?: record, version?: int}
]: any -> record<scheduled_shift: record<id: string, draft_shift_details: record<team_member_id: string, location_id: string, job_id: string, start_at: string, end_at: string, notes: string, is_deleted: bool, timezone: string>, published_shift_details: record<team_member_id: string, location_id: string, job_id: string, start_at: string, end_at: string, notes: string, is_deleted: bool, timezone: string>, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/scheduled-shifts/($id)")
  let body = {scheduled_shift: $scheduled_shift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PublishScheduledShift
#
# POST /v2/labor/scheduled-shifts/{id}/publish
# operationId: PublishScheduledShift
export def "labor-scheduled-shifts-publish PublishScheduledShift" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique identifier for the `PublishScheduledShift` request, used to ensure the [idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) of the operation.
  --version: int # The current version of the scheduled shift, used to enable [optimistic concurrency](https://developer.squareup.com/docs/build-basics/common-api-patterns/optimistic-concurrency) control. If the provided version doesn't match the server version, the request fails. If omitted, Square executes a blind write, potentially overwriting data from another publish request.
  --scheduled-shift-notification-audience: string@scheduled-shift-notification-audience-completer # Indicates whether Square sends an email notification to team members when a scheduled shift is published and which team members receive the notification.
]: any -> record<scheduled_shift: record<id: string, draft_shift_details: record<team_member_id: string, location_id: string, job_id: string, start_at: string, end_at: string, notes: string, is_deleted: bool, timezone: string>, published_shift_details: record<team_member_id: string, location_id: string, job_id: string, start_at: string, end_at: string, notes: string, is_deleted: bool, timezone: string>, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/scheduled-shifts/($id)/publish")
  let body = {idempotency_key: $idempotency_key, version: $version, scheduled_shift_notification_audience: $scheduled_shift_notification_audience} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateShift
#
# POST /v2/labor/shifts
# DEPRECATED
# operationId: CreateShift
# --shift shape: {id?: string, employee_id?: string, location_id: string, timezone?: string, start_at: string, end_at?: string, wage?: record, breaks?: list, status?: "OPEN"|"CLOSED", version?: int, team_member_id?: string, declared_cash_tip_money?: record}
@deprecated
export def "labor-shifts CreateShift" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string value to ensure the idempotency of the operation.
  shift: record # A record of the hourly rate, start, and end times for a single work shift for an employee. This might include a record of the start and end times for breaks taken during the shift.  Deprecated at Square API version 2025-05-21. Replaced by [Timecard](entity:Timecard). See the [migration notes](https://developer.squareup.com/docs/labor-api/what-it-does#migration-notes). — shape: {id?: string, employee_id?: string, location_id: string, timezone?: string, start_at: string, end_at?: string, wage?: record, breaks?: list, status?: "OPEN"|"CLOSED", version?: int, team_member_id?: string, declared_cash_tip_money?: record}
]: any -> record<shift: record<id: string, employee_id: string, location_id: string, timezone: string, start_at: string, end_at: string, wage: record<title: string, hourly_rate: record, job_id: string, tip_eligible: bool>, breaks: list<record>, status: string, version: int, created_at: string, updated_at: string, team_member_id: string, declared_cash_tip_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/shifts")
  let body = {idempotency_key: $idempotency_key, shift: $shift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchShifts
#
# POST /v2/labor/shifts/search
# DEPRECATED
# operationId: SearchShifts
# --query shape: {filter?: record, sort?: record}
@deprecated
export def "labor-shifts-search SearchShifts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # The parameters of a `Shift` search query, which includes filter and sort options.  Deprecated at Square API version 2025-05-21. See the [migration notes](https://developer.squareup.com/docs/labor-api/what-it-does#migration-notes). — shape: {filter?: record, sort?: record}
  --limit: int # The number of resources in a page (200 by default).
  --cursor: string # An opaque cursor for fetching the next page.
]: any -> record<shifts: table<id: string, employee_id: string, location_id: string, timezone: string, start_at: string, end_at: string, wage: record, breaks: list, status: string, version: int, created_at: string, updated_at: string, team_member_id: string, declared_cash_tip_money: record>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/shifts/search")
  let body = {query: $body_query, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteShift
#
# DELETE /v2/labor/shifts/{id}
# DEPRECATED
# operationId: DeleteShift
@deprecated
export def "labor-shifts DeleteShift" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/shifts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetShift
#
# GET /v2/labor/shifts/{id}
# DEPRECATED
# operationId: GetShift
@deprecated
export def "labor-shifts GetShift" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<shift: record<id: string, employee_id: string, location_id: string, timezone: string, start_at: string, end_at: string, wage: record<title: string, hourly_rate: record, job_id: string, tip_eligible: bool>, breaks: list<record>, status: string, version: int, created_at: string, updated_at: string, team_member_id: string, declared_cash_tip_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/shifts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateShift
#
# PUT /v2/labor/shifts/{id}
# DEPRECATED
# operationId: UpdateShift
# --shift shape: {id?: string, employee_id?: string, location_id: string, timezone?: string, start_at: string, end_at?: string, wage?: record, breaks?: list, status?: "OPEN"|"CLOSED", version?: int, team_member_id?: string, declared_cash_tip_money?: record}
@deprecated
export def "labor-shifts UpdateShift" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shift: record # A record of the hourly rate, start, and end times for a single work shift for an employee. This might include a record of the start and end times for breaks taken during the shift.  Deprecated at Square API version 2025-05-21. Replaced by [Timecard](entity:Timecard). See the [migration notes](https://developer.squareup.com/docs/labor-api/what-it-does#migration-notes). — shape: {id?: string, employee_id?: string, location_id: string, timezone?: string, start_at: string, end_at?: string, wage?: record, breaks?: list, status?: "OPEN"|"CLOSED", version?: int, team_member_id?: string, declared_cash_tip_money?: record}
]: any -> record<shift: record<id: string, employee_id: string, location_id: string, timezone: string, start_at: string, end_at: string, wage: record<title: string, hourly_rate: record, job_id: string, tip_eligible: bool>, breaks: list<record>, status: string, version: int, created_at: string, updated_at: string, team_member_id: string, declared_cash_tip_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/shifts/($id)")
  let body = {shift: $shift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListTeamMemberWages
#
# GET /v2/labor/team-member-wages
# operationId: ListTeamMemberWages
export def "labor-team-member-wages ListTeamMemberWages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-member-id: string # Filter the returned wages to only those that are associated with the specified team member.
  --limit: int # The maximum number of `TeamMemberWage` results to return per page. The number can range between 1 and 200. The default is 200.
  --cursor: string # A pointer to the next page of `EmployeeWage` results to fetch.
]: nothing -> record<team_member_wages: table<id: string, team_member_id: string, title: string, hourly_rate: record, job_id: string, tip_eligible: bool>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_member_id" $team_member_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/labor/team-member-wages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetTeamMemberWage
#
# GET /v2/labor/team-member-wages/{id}
# operationId: GetTeamMemberWage
export def "labor-team-member-wages GetTeamMemberWage" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<team_member_wage: record<id: string, team_member_id: string, title: string, hourly_rate: record<amount: int, currency: string>, job_id: string, tip_eligible: bool>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/team-member-wages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateTimecard
#
# POST /v2/labor/timecards
# operationId: CreateTimecard
# --timecard shape: {id?: string, location_id: string, timezone?: string, start_at: string, end_at?: string, wage?: record, breaks?: list, status?: "OPEN"|"CLOSED", version?: int, team_member_id: string, declared_cash_tip_money?: record}
export def "labor-timecards CreateTimecard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string value to ensure the idempotency of the operation.
  timecard: record # A record of the hourly rate, start time, and end time of a single timecard (shift) for a team member. This might include a record of the start and end times of breaks taken during the shift. — shape: {id?: string, location_id: string, timezone?: string, start_at: string, end_at?: string, wage?: record, breaks?: list, status?: "OPEN"|"CLOSED", version?: int, team_member_id: string, declared_cash_tip_money?: record}
]: any -> record<timecard: record<id: string, location_id: string, timezone: string, start_at: string, end_at: string, wage: record<title: string, hourly_rate: record, job_id: string, tip_eligible: bool>, breaks: list<record>, status: string, version: int, created_at: string, updated_at: string, team_member_id: string, declared_cash_tip_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/timecards")
  let body = {idempotency_key: $idempotency_key, timecard: $timecard} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchTimecards
#
# POST /v2/labor/timecards/search
# operationId: SearchTimecards
# --query shape: {filter?: record, sort?: record}
export def "labor-timecards-search SearchTimecards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # The parameters of a `Timecard` search query, which includes filter and sort options. — shape: {filter?: record, sort?: record}
  --limit: int # The number of resources in a page (200 by default).
  --cursor: string # An opaque cursor for fetching the next page.
]: any -> record<timecards: table<id: string, location_id: string, timezone: string, start_at: string, end_at: string, wage: record, breaks: list, status: string, version: int, created_at: string, updated_at: string, team_member_id: string, declared_cash_tip_money: record>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/labor/timecards/search")
  let body = {query: $body_query, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteTimecard
#
# DELETE /v2/labor/timecards/{id}
# operationId: DeleteTimecard
export def "labor-timecards DeleteTimecard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/timecards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveTimecard
#
# GET /v2/labor/timecards/{id}
# operationId: RetrieveTimecard
export def "labor-timecards RetrieveTimecard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<timecard: record<id: string, location_id: string, timezone: string, start_at: string, end_at: string, wage: record<title: string, hourly_rate: record, job_id: string, tip_eligible: bool>, breaks: list<record>, status: string, version: int, created_at: string, updated_at: string, team_member_id: string, declared_cash_tip_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/timecards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateTimecard
#
# PUT /v2/labor/timecards/{id}
# operationId: UpdateTimecard
# --timecard shape: {id?: string, location_id: string, timezone?: string, start_at: string, end_at?: string, wage?: record, breaks?: list, status?: "OPEN"|"CLOSED", version?: int, team_member_id: string, declared_cash_tip_money?: record}
export def "labor-timecards UpdateTimecard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timecard: record # A record of the hourly rate, start time, and end time of a single timecard (shift) for a team member. This might include a record of the start and end times of breaks taken during the shift. — shape: {id?: string, location_id: string, timezone?: string, start_at: string, end_at?: string, wage?: record, breaks?: list, status?: "OPEN"|"CLOSED", version?: int, team_member_id: string, declared_cash_tip_money?: record}
]: any -> record<timecard: record<id: string, location_id: string, timezone: string, start_at: string, end_at: string, wage: record<title: string, hourly_rate: record, job_id: string, tip_eligible: bool>, breaks: list<record>, status: string, version: int, created_at: string, updated_at: string, team_member_id: string, declared_cash_tip_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/timecards/($id)")
  let body = {timecard: $timecard} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListWorkweekConfigs
#
# GET /v2/labor/workweek-configs
# operationId: ListWorkweekConfigs
export def "labor-workweek-configs ListWorkweekConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of `WorkweekConfigs` results to return per page.
  --cursor: string # A pointer to the next page of `WorkweekConfig` results to fetch.
]: nothing -> record<workweek_configs: table<id: string, start_of_week: string, start_of_day_local_time: string, version: int, created_at: string, updated_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/labor/workweek-configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateWorkweekConfig
#
# PUT /v2/labor/workweek-configs/{id}
# operationId: UpdateWorkweekConfig
# --workweek_config shape: {id?: string, start_of_week: "MON"|"TUE"|"WED"|"THU"|"FRI"|"SAT"|"SUN", start_of_day_local_time: string, version?: int}
export def "labor-workweek-configs UpdateWorkweekConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workweek_config: record # Sets the day of the week and hour of the day that a business starts a workweek. This is used to calculate overtime pay. — shape: {id?: string, start_of_week: "MON"|"TUE"|"WED"|"THU"|"FRI"|"SAT"|"SUN", start_of_day_local_time: string, version?: int}
]: any -> record<workweek_config: record<id: string, start_of_week: string, start_of_day_local_time: string, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/labor/workweek-configs/($id)")
  let body = {workweek_config: $workweek_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListLocations
#
# GET /v2/locations
# operationId: ListLocations
export def "locations ListLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, locations: table<id: string, name: string, address: record, timezone: string, capabilities: list, status: string, created_at: string, merchant_id: string, country: string, language_code: string, currency: string, phone_number: string, business_name: string, type: string, website_url: string, business_hours: record, business_email: string, description: string, twitter_username: string, instagram_username: string, facebook_url: string, coordinates: record, logo_url: string, pos_background_url: string, mcc: string, full_format_logo_url: string, tax_ids: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateLocation
#
# POST /v2/locations
# operationId: CreateLocation
# --location shape: {name?: string, address?: record, timezone?: string, status?: "ACTIVE"|"INACTIVE", country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", language_code?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS", phone_number?: string, business_name?: string, type?: "PHYSICAL"|"MOBILE", website_url?: string, business_hours?: record, business_email?: string, description?: string, twitter_username?: string, instagram_username?: string, facebook_url?: string, coordinates?: record, mcc?: string, tax_ids?: record}
export def "locations CreateLocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: record # Represents one of a business' [locations](https://developer.squareup.com/docs/locations-api). — shape: {name?: string, address?: record, timezone?: string, status?: "ACTIVE"|"INACTIVE", country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", language_code?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS", phone_number?: string, business_name?: string, type?: "PHYSICAL"|"MOBILE", website_url?: string, business_hours?: record, business_email?: string, description?: string, twitter_username?: string, instagram_username?: string, facebook_url?: string, coordinates?: record, mcc?: string, tax_ids?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, location: record<id: string, name: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, timezone: string, capabilities: list<string>, status: string, created_at: string, merchant_id: string, country: string, language_code: string, currency: string, phone_number: string, business_name: string, type: string, website_url: string, business_hours: record<periods: list>, business_email: string, description: string, twitter_username: string, instagram_username: string, facebook_url: string, coordinates: record<latitude: float, longitude: float>, logo_url: string, pos_background_url: string, mcc: string, full_format_logo_url: string, tax_ids: record<eu_vat: string, fr_siret: string, fr_naf: string, es_nif: string, jp_qii: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations")
  let body = {location: $location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListLocationCustomAttributeDefinitions
#
# GET /v2/locations/custom-attribute-definitions
# operationId: ListLocationCustomAttributeDefinitions
export def "locations-custom-attribute-definitions ListLocationCustomAttributeDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility-filter: string@visibility-filter-completer # Filters the `CustomAttributeDefinition` results by their `visibility` values.
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory. The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100. The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<custom_attribute_definitions: table<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility_filter" $visibility_filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/locations/custom-attribute-definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateLocationCustomAttributeDefinition
#
# POST /v2/locations/custom-attribute-definitions
# operationId: CreateLocationCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "locations-custom-attribute-definitions CreateLocationCustomAttributeDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations/custom-attribute-definitions")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteLocationCustomAttributeDefinition
#
# DELETE /v2/locations/custom-attribute-definitions/{key}
# operationId: DeleteLocationCustomAttributeDefinition
export def "locations-custom-attribute-definitions DeleteLocationCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/custom-attribute-definitions/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveLocationCustomAttributeDefinition
#
# GET /v2/locations/custom-attribute-definitions/{key}
# operationId: RetrieveLocationCustomAttributeDefinition
export def "locations-custom-attribute-definitions RetrieveLocationCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # The current version of the custom attribute definition, which is used for strongly consistent reads to guarantee that you receive the most up-to-date data. When included in the request, Square returns the specified version or a higher version if one exists. If the specified version is higher than the current version, Square returns a `BAD_REQUEST` error.
]: nothing -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/locations/custom-attribute-definitions/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateLocationCustomAttributeDefinition
#
# PUT /v2/locations/custom-attribute-definitions/{key}
# operationId: UpdateLocationCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "locations-custom-attribute-definitions UpdateLocationCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/custom-attribute-definitions/($key)")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkDeleteLocationCustomAttributes
#
# POST /v2/locations/custom-attributes/bulk-delete
# operationId: BulkDeleteLocationCustomAttributes
export def "locations-custom-attributes-bulk-delete BulkDeleteLocationCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # The data used to update the `CustomAttribute` objects. The keys must be unique and are used to map to the corresponding response.
]: any -> record<values: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations/custom-attributes/bulk-delete")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkUpsertLocationCustomAttributes
#
# POST /v2/locations/custom-attributes/bulk-upsert
# operationId: BulkUpsertLocationCustomAttributes
export def "locations-custom-attributes-bulk-upsert BulkUpsertLocationCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # A map containing 1 to 25 individual upsert requests. For each request, provide an arbitrary ID that is unique for this `BulkUpsertLocationCustomAttributes` request and the information needed to create or update a custom attribute.
]: any -> record<values: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/locations/custom-attributes/bulk-upsert")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveLocation
#
# GET /v2/locations/{location_id}
# operationId: RetrieveLocation
export def "locations RetrieveLocation" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, location: record<id: string, name: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, timezone: string, capabilities: list<string>, status: string, created_at: string, merchant_id: string, country: string, language_code: string, currency: string, phone_number: string, business_name: string, type: string, website_url: string, business_hours: record<periods: list>, business_email: string, description: string, twitter_username: string, instagram_username: string, facebook_url: string, coordinates: record<latitude: float, longitude: float>, logo_url: string, pos_background_url: string, mcc: string, full_format_logo_url: string, tax_ids: record<eu_vat: string, fr_siret: string, fr_naf: string, es_nif: string, jp_qii: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/($location_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateLocation
#
# PUT /v2/locations/{location_id}
# operationId: UpdateLocation
# --location shape: {name?: string, address?: record, timezone?: string, status?: "ACTIVE"|"INACTIVE", country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", language_code?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS", phone_number?: string, business_name?: string, type?: "PHYSICAL"|"MOBILE", website_url?: string, business_hours?: record, business_email?: string, description?: string, twitter_username?: string, instagram_username?: string, facebook_url?: string, coordinates?: record, mcc?: string, tax_ids?: record}
export def "locations UpdateLocation" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: record # Represents one of a business' [locations](https://developer.squareup.com/docs/locations-api). — shape: {name?: string, address?: record, timezone?: string, status?: "ACTIVE"|"INACTIVE", country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", language_code?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS", phone_number?: string, business_name?: string, type?: "PHYSICAL"|"MOBILE", website_url?: string, business_hours?: record, business_email?: string, description?: string, twitter_username?: string, instagram_username?: string, facebook_url?: string, coordinates?: record, mcc?: string, tax_ids?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, location: record<id: string, name: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, timezone: string, capabilities: list<string>, status: string, created_at: string, merchant_id: string, country: string, language_code: string, currency: string, phone_number: string, business_name: string, type: string, website_url: string, business_hours: record<periods: list>, business_email: string, description: string, twitter_username: string, instagram_username: string, facebook_url: string, coordinates: record<latitude: float, longitude: float>, logo_url: string, pos_background_url: string, mcc: string, full_format_logo_url: string, tax_ids: record<eu_vat: string, fr_siret: string, fr_naf: string, es_nif: string, jp_qii: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/($location_id)")
  let body = {location: $location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateCheckout
#
# POST /v2/locations/{location_id}/checkouts
# DEPRECATED
# operationId: CreateCheckout
# --order shape: {order?: record, idempotency_key?: string}
# --pre_populate_shipping_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
# --additional_recipients item shape: {location_id: string, description: string, amount_money: record}
@deprecated
export def "locations-checkouts CreateCheckout" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this checkout among others you have created. It can be any valid string but must be unique for every order sent to Square Checkout for a given location ID.  The idempotency key is used to avoid processing the same order more than once. If you are  unsure whether a particular checkout was created successfully, you can attempt it again with the same idempotency key and all the same other parameters without worrying about creating duplicates.  You should use a random number/string generator native to the language you are working in to generate strings for your idempotency keys.  For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  order: record # e.g. {idempotency_key: 8193148c-9586-11e6-99f9-28cfe92138cf, order: {discounts: [{name: Labor Day Sale, percentage: 5, scope: ORDER, uid: labor-day-sale}, {catalog_object_id: DB7L55ZH2BGWI4H23ULIWOQ7, scope: ORDER, uid: membership-discount}, {amount_money: {amount: 100, currency: USD}, name: Sale - $1.00 off, scope: LINE_ITEM, uid: one-dollar-off}], line_items: [{base_price_money: {amount: 1599, currency: USD}, name: New York Strip Steak, quantity: 1}, {applied_discounts: [{discount_uid: one-dollar-off}], catalog_object_id: BEMYCSMIJL46OCDV4KYIKXIB, modifiers: [{catalog_object_id: CHQX7Y4KY6N5KINJKZCFURPZ}], quantity: 2}], location_id: 057P5VYJ4A5X1, reference_id: my-order-001, taxes: [{name: State Sales Tax, percentage: 9, scope: ORDER, uid: state-sales-tax}]}} — shape: {order?: record, idempotency_key?: string}
  --ask-for-shipping-address: oneof<nothing, bool> # If `true`, Square Checkout collects shipping information on your behalf and stores  that information with the transaction information in the Square Seller Dashboard.  Default: `false`.
  --merchant-support-email: string # The email address to display on the Square Checkout confirmation page and confirmation email that the buyer can use to contact the seller.  If this value is not set, the confirmation page and email display the primary email address associated with the seller's Square account.  Default: none; only exists if explicitly set.
  --pre-populate-buyer-email: string # If provided, the buyer's email is prepopulated on the checkout page as an editable text field.  Default: none; only exists if explicitly set.
  --pre-populate-shipping-address: record # Represents a postal address in a country.  For more information, see [Working with Addresses](https://developer.squareup.com/docs/build-basics/working-with-addresses). — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
  --redirect-url: string # The URL to redirect to after the checkout is completed with `checkoutId`, `transactionId`, and `referenceId` appended as URL parameters. For example, if the provided redirect URL is `http://www.example.com/order-complete`, a successful transaction redirects the customer to:  `http://www.example.com/order-complete?checkoutId=xxxxxx&amp;referenceId=xxxxxx&amp;transactionId=xxxxxx`  If you do not provide a redirect URL, Square Checkout displays an order confirmation page on your behalf; however, it is strongly recommended that you provide a redirect URL so you can verify the transaction results and finalize the order through your existing/normal confirmation workflow.  Default: none; only exists if explicitly set.
  --additional-recipients: list # The basic primitive of a multi-party transaction. The value is optional. The transaction facilitated by you can be split from here.  If you provide this value, the `amount_money` value in your `additional_recipients` field cannot be more than 90% of the `total_money` calculated by Square for your order. The `location_id` must be a valid seller location where the checkout is occurring.  This field requires `PAYMENTS_WRITE_ADDITIONAL_RECIPIENTS` OAuth permission.  This field is currently not supported in the Square Sandbox. — item shape: {location_id: string, description: string, amount_money: record}
  --note: string # An optional note to associate with the `checkout` object.  This value cannot exceed 60 characters.
]: any -> record<checkout: record<id: string, checkout_page_url: string, ask_for_shipping_address: bool, merchant_support_email: string, pre_populate_buyer_email: string, pre_populate_shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, redirect_url: string, order: record<id: string, location_id: string, reference_id: string, source: record, customer_id: string, line_items: list, taxes: list, discounts: list, service_charges: list, fulfillments: list, returns: list, return_amounts: record, net_amounts: record, rounding_adjustment: record, tenders: list, refunds: list, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record, total_tax_money: record, total_discount_money: record, total_tip_money: record, total_service_charge_money: record, ticket_name: string, pricing_options: record, rewards: list, net_amount_due_money: record>, created_at: string, additional_recipients: list<record>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/($location_id)/checkouts")
  let body = {idempotency_key: $idempotency_key, order: $order, ask_for_shipping_address: $ask_for_shipping_address, merchant_support_email: $merchant_support_email, pre_populate_buyer_email: $pre_populate_buyer_email, pre_populate_shipping_address: $pre_populate_shipping_address, redirect_url: $redirect_url, additional_recipients: $additional_recipients, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListLocationCustomAttributes
#
# GET /v2/locations/{location_id}/custom-attributes
# operationId: ListLocationCustomAttributes
export def "locations-custom-attributes ListLocationCustomAttributes" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility-filter: string@visibility-filter-completer # Filters the `CustomAttributeDefinition` results by their `visibility` values.
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory. The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100. The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --with-definitions: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of each custom attribute. Set this parameter to `true` to get the name and description of each custom attribute, information about the data type, or other definition details. The default value is `false`. (default: false)
]: nothing -> record<custom_attributes: table<key: string, value: any, version: int, visibility: string, definition: record, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility_filter" $visibility_filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "with_definitions" $with_definitions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/locations/($location_id)/custom-attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeleteLocationCustomAttribute
#
# DELETE /v2/locations/{location_id}/custom-attributes/{key}
# operationId: DeleteLocationCustomAttribute
export def "locations-custom-attributes DeleteLocationCustomAttribute" [
  location_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/($location_id)/custom-attributes/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveLocationCustomAttribute
#
# GET /v2/locations/{location_id}/custom-attributes/{key}
# operationId: RetrieveLocationCustomAttribute
export def "locations-custom-attributes RetrieveLocationCustomAttribute" [
  location_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-definition: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of the custom attribute. Set this parameter to `true` to get the name and description of the custom attribute, information about the data type, or other definition details. The default value is `false`. (default: false)
  --version: int # The current version of the custom attribute, which is used for strongly consistent reads to guarantee that you receive the most up-to-date data. When included in the request, Square returns the specified version or a higher version if one exists. If the specified version is higher than the current version, Square returns a `BAD_REQUEST` error.
]: nothing -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_definition" $with_definition "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/locations/($location_id)/custom-attributes/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpsertLocationCustomAttribute
#
# POST /v2/locations/{location_id}/custom-attributes/{key}
# operationId: UpsertLocationCustomAttribute
# --custom_attribute shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
export def "locations-custom-attributes UpsertLocationCustomAttribute" [
  location_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute: record # A custom attribute value. Each custom attribute value has a corresponding `CustomAttributeDefinition` object. — shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/($location_id)/custom-attributes/($key)")
  let body = {custom_attribute: $custom_attribute, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListTransactions
#
# GET /v2/locations/{location_id}/transactions
# DEPRECATED
# operationId: ListTransactions
@deprecated
export def "locations-transactions ListTransactions" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --begin-time: string # The beginning of the requested reporting period, in RFC 3339 format.  See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity.  Default value: The current time minus one year.
  --end-time: string # The end of the requested reporting period, in RFC 3339 format.  See [Date ranges](https://developer.squareup.com/docs/build-basics/working-with-dates) for details on date inclusivity/exclusivity.  Default value: The current time.
  --sort-order: string@sort-order-completer # The order in which results are listed in the response (`ASC` for oldest first, `DESC` for newest first).  Default value: `DESC`
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query.  See [Paginating results](https://developer.squareup.com/docs/working-with-apis/pagination) for more information.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, transactions: table<id: string, location_id: string, created_at: string, tenders: list, refunds: list, reference_id: string, product: string, client_id: string, shipping_address: record, order_id: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/locations/($location_id)/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveTransaction
#
# GET /v2/locations/{location_id}/transactions/{transaction_id}
# DEPRECATED
# operationId: RetrieveTransaction
@deprecated
export def "locations-transactions RetrieveTransaction" [
  location_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, transaction: record<id: string, location_id: string, created_at: string, tenders: list<record>, refunds: list<record>, reference_id: string, product: string, client_id: string, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, order_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/($location_id)/transactions/($transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CaptureTransaction
#
# POST /v2/locations/{location_id}/transactions/{transaction_id}/capture
# DEPRECATED
# operationId: CaptureTransaction
@deprecated
export def "locations-transactions-capture CaptureTransaction" [
  location_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/($location_id)/transactions/($transaction_id)/capture")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# VoidTransaction
#
# POST /v2/locations/{location_id}/transactions/{transaction_id}/void
# DEPRECATED
# operationId: VoidTransaction
@deprecated
export def "locations-transactions-void VoidTransaction" [
  location_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/locations/($location_id)/transactions/($transaction_id)/void")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateLoyaltyAccount
#
# POST /v2/loyalty/accounts
# operationId: CreateLoyaltyAccount
# --loyalty_account shape: {program_id: string, customer_id?: string, enrolled_at?: string, mapping?: record, expiring_point_deadlines?: list}
export def "loyalty-accounts CreateLoyaltyAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  loyalty_account: record # Describes a loyalty account in a [loyalty program](entity:LoyaltyProgram). For more information, see [Create and Retrieve Loyalty Accounts](https://developer.squareup.com/docs/loyalty-api/loyalty-accounts). — shape: {program_id: string, customer_id?: string, enrolled_at?: string, mapping?: record, expiring_point_deadlines?: list}
  idempotency_key: string # A unique string that identifies this `CreateLoyaltyAccount` request.  Keys can be any valid string, but must be unique for every request.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_account: record<id: string, program_id: string, balance: int, lifetime_points: int, customer_id: string, enrolled_at: string, created_at: string, updated_at: string, mapping: record<id: string, created_at: string, phone_number: string>, expiring_point_deadlines: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/accounts")
  let body = {loyalty_account: $loyalty_account, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchLoyaltyAccounts
#
# POST /v2/loyalty/accounts/search
# operationId: SearchLoyaltyAccounts
# --query shape: {mappings?: list, customer_ids?: list}
export def "loyalty-accounts-search SearchLoyaltyAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # The search criteria for the loyalty accounts. — shape: {mappings?: list, customer_ids?: list}
  --limit: int # The maximum number of results to include in the response. The default value is 30.
  --cursor: string # A pagination cursor returned by a previous call to  this endpoint. Provide this to retrieve the next set of  results for the original query.  For more information,  see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_accounts: table<id: string, program_id: string, balance: int, lifetime_points: int, customer_id: string, enrolled_at: string, created_at: string, updated_at: string, mapping: record, expiring_point_deadlines: list>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/accounts/search")
  let body = {query: $body_query, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveLoyaltyAccount
#
# GET /v2/loyalty/accounts/{account_id}
# operationId: RetrieveLoyaltyAccount
export def "loyalty-accounts RetrieveLoyaltyAccount" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_account: record<id: string, program_id: string, balance: int, lifetime_points: int, customer_id: string, enrolled_at: string, created_at: string, updated_at: string, mapping: record<id: string, created_at: string, phone_number: string>, expiring_point_deadlines: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# AccumulateLoyaltyPoints
#
# POST /v2/loyalty/accounts/{account_id}/accumulate
# operationId: AccumulateLoyaltyPoints
# --accumulate_points shape: {points?: int, order_id?: string}
export def "loyalty-accounts-accumulate AccumulateLoyaltyPoints" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accumulate_points: record # Provides metadata when the event `type` is `ACCUMULATE_POINTS`. — shape: {points?: int, order_id?: string}
  idempotency_key: string # A unique string that identifies the `AccumulateLoyaltyPoints` request.  Keys can be any valid string but must be unique for every request.
  location_id: string # The [location](entity:Location) where the purchase was made.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, event: record<id: string, type: string, created_at: string, accumulate_points: record<loyalty_program_id: string, points: int, order_id: string>, create_reward: record<loyalty_program_id: string, reward_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, reward_id: string, order_id: string>, delete_reward: record<loyalty_program_id: string, reward_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, loyalty_account_id: string, location_id: string, source: string, expire_points: record<loyalty_program_id: string, points: int>, other_event: record<loyalty_program_id: string, points: int>, accumulate_promotion_points: record<loyalty_program_id: string, loyalty_promotion_id: string, points: int, order_id: string>>, events: table<id: string, type: string, created_at: string, accumulate_points: record, create_reward: record, redeem_reward: record, delete_reward: record, adjust_points: record, loyalty_account_id: string, location_id: string, source: string, expire_points: record, other_event: record, accumulate_promotion_points: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/accounts/($account_id)/accumulate")
  let body = {accumulate_points: $accumulate_points, idempotency_key: $idempotency_key, location_id: $location_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# AdjustLoyaltyPoints
#
# POST /v2/loyalty/accounts/{account_id}/adjust
# operationId: AdjustLoyaltyPoints
# --adjust_points shape: {points: int, reason?: string}
export def "loyalty-accounts-adjust AdjustLoyaltyPoints" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this `AdjustLoyaltyPoints` request.  Keys can be any valid string, but must be unique for every request.
  adjust_points: record # Provides metadata when the event `type` is `ADJUST_POINTS`. — shape: {points: int, reason?: string}
  --allow-negative-balance: oneof<nothing, bool> # Indicates whether to allow a negative adjustment to result in a negative balance. If `true`, a negative balance is allowed when subtracting points. If `false`, Square returns a `BAD_REQUEST` error when subtracting the specified number of points would result in a negative balance. The default value is `false`. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, event: record<id: string, type: string, created_at: string, accumulate_points: record<loyalty_program_id: string, points: int, order_id: string>, create_reward: record<loyalty_program_id: string, reward_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, reward_id: string, order_id: string>, delete_reward: record<loyalty_program_id: string, reward_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, loyalty_account_id: string, location_id: string, source: string, expire_points: record<loyalty_program_id: string, points: int>, other_event: record<loyalty_program_id: string, points: int>, accumulate_promotion_points: record<loyalty_program_id: string, loyalty_promotion_id: string, points: int, order_id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/accounts/($account_id)/adjust")
  let body = {idempotency_key: $idempotency_key, adjust_points: $adjust_points, allow_negative_balance: $allow_negative_balance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchLoyaltyEvents
#
# POST /v2/loyalty/events/search
# operationId: SearchLoyaltyEvents
# --query shape: {filter?: record}
export def "loyalty-events-search SearchLoyaltyEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # Represents a query used to search for loyalty events. — shape: {filter?: record}
  --limit: int # The maximum number of results to include in the response.  The last page might contain fewer events.  The default is 30 events.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, events: table<id: string, type: string, created_at: string, accumulate_points: record, create_reward: record, redeem_reward: record, delete_reward: record, adjust_points: record, loyalty_account_id: string, location_id: string, source: string, expire_points: record, other_event: record, accumulate_promotion_points: record>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/events/search")
  let body = {query: $body_query, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListLoyaltyPrograms
#
# GET /v2/loyalty/programs
# DEPRECATED
# operationId: ListLoyaltyPrograms
@deprecated
export def "loyalty-programs ListLoyaltyPrograms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, programs: table<id: string, status: string, reward_tiers: list, expiration_policy: record, terminology: record, location_ids: list, created_at: string, updated_at: string, accrual_rules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/programs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveLoyaltyProgram
#
# GET /v2/loyalty/programs/{program_id}
# operationId: RetrieveLoyaltyProgram
export def "loyalty-programs RetrieveLoyaltyProgram" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, program: record<id: string, status: string, reward_tiers: list<record>, expiration_policy: record<expiration_duration: string>, terminology: record<one: string, other: string>, location_ids: list<string>, created_at: string, updated_at: string, accrual_rules: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/programs/($program_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CalculateLoyaltyPoints
#
# POST /v2/loyalty/programs/{program_id}/calculate
# operationId: CalculateLoyaltyPoints
# --transaction_amount_money shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
export def "loyalty-programs-calculate CalculateLoyaltyPoints" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-id: string # The [order](entity:Order) ID for which to calculate the points. Specify this field if your application uses the Orders API to process orders. Otherwise, specify the `transaction_amount_money`. (nullable)
  --transaction-amount-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
  --loyalty-account-id: string # The ID of the target [loyalty account](entity:LoyaltyAccount). Optionally specify this field if your application uses the Orders API to process orders.  If specified, the `promotion_points` field in the response shows the number of points the buyer would earn from the purchase. In this case, Square uses the account ID to determine whether the promotion's `trigger_limit` (the maximum number of times that a buyer can trigger the promotion) has been reached. If not specified, the `promotion_points` field shows the number of points the purchase qualifies for regardless of the trigger limit. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, points: int, promotion_points: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/programs/($program_id)/calculate")
  let body = {order_id: $order_id, transaction_amount_money: $transaction_amount_money, loyalty_account_id: $loyalty_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListLoyaltyPromotions
#
# GET /v2/loyalty/programs/{program_id}/promotions
# operationId: ListLoyaltyPromotions
export def "loyalty-programs-promotions ListLoyaltyPromotions" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2 # The status to filter the results by. If a status is provided, only loyalty promotions with the specified status are returned. Otherwise, all loyalty promotions associated with the loyalty program are returned.
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The maximum number of results to return in a single paged response. The minimum value is 1 and the maximum value is 30. The default value is 30. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_promotions: table<id: string, name: string, incentive: record, available_time: record, trigger_limit: record, status: string, created_at: string, canceled_at: string, updated_at: string, loyalty_program_id: string, minimum_spend_amount_money: record, qualifying_item_variation_ids: list, qualifying_category_ids: list>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/loyalty/programs/($program_id)/promotions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateLoyaltyPromotion
#
# POST /v2/loyalty/programs/{program_id}/promotions
# operationId: CreateLoyaltyPromotion
# --loyalty_promotion shape: {name: string, incentive: record, available_time: record, trigger_limit?: record, status?: "ACTIVE"|"ENDED"|"CANCELED"|"SCHEDULED", minimum_spend_amount_money?: record, qualifying_item_variation_ids?: list, qualifying_category_ids?: list}
export def "loyalty-programs-promotions CreateLoyaltyPromotion" [
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  loyalty_promotion: record # Represents a promotion for a [loyalty program](entity:LoyaltyProgram). Loyalty promotions enable buyers to earn extra points on top of those earned from the base program.  A loyalty program can have a maximum of 10 loyalty promotions with an `ACTIVE` or `SCHEDULED` status. — shape: {name: string, incentive: record, available_time: record, trigger_limit?: record, status?: "ACTIVE"|"ENDED"|"CANCELED"|"SCHEDULED", minimum_spend_amount_money?: record, qualifying_item_variation_ids?: list, qualifying_category_ids?: list}
  idempotency_key: string # A unique identifier for this request, which is used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_promotion: record<id: string, name: string, incentive: record<type: string, points_multiplier_data: record, points_addition_data: record>, available_time: record<start_date: string, end_date: string, time_periods: list>, trigger_limit: record<times: int, interval: string>, status: string, created_at: string, canceled_at: string, updated_at: string, loyalty_program_id: string, minimum_spend_amount_money: record<amount: int, currency: string>, qualifying_item_variation_ids: list<string>, qualifying_category_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/programs/($program_id)/promotions")
  let body = {loyalty_promotion: $loyalty_promotion, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveLoyaltyPromotion
#
# GET /v2/loyalty/programs/{program_id}/promotions/{promotion_id}
# operationId: RetrieveLoyaltyPromotion
export def "loyalty-programs-promotions RetrieveLoyaltyPromotion" [
  promotion_id: string
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_promotion: record<id: string, name: string, incentive: record<type: string, points_multiplier_data: record, points_addition_data: record>, available_time: record<start_date: string, end_date: string, time_periods: list>, trigger_limit: record<times: int, interval: string>, status: string, created_at: string, canceled_at: string, updated_at: string, loyalty_program_id: string, minimum_spend_amount_money: record<amount: int, currency: string>, qualifying_item_variation_ids: list<string>, qualifying_category_ids: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/programs/($program_id)/promotions/($promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CancelLoyaltyPromotion
#
# POST /v2/loyalty/programs/{program_id}/promotions/{promotion_id}/cancel
# operationId: CancelLoyaltyPromotion
export def "loyalty-programs-promotions-cancel CancelLoyaltyPromotion" [
  promotion_id: string
  program_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, loyalty_promotion: record<id: string, name: string, incentive: record<type: string, points_multiplier_data: record, points_addition_data: record>, available_time: record<start_date: string, end_date: string, time_periods: list>, trigger_limit: record<times: int, interval: string>, status: string, created_at: string, canceled_at: string, updated_at: string, loyalty_program_id: string, minimum_spend_amount_money: record<amount: int, currency: string>, qualifying_item_variation_ids: list<string>, qualifying_category_ids: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/programs/($program_id)/promotions/($promotion_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateLoyaltyReward
#
# POST /v2/loyalty/rewards
# operationId: CreateLoyaltyReward
# --reward shape: {status?: "ISSUED"|"REDEEMED"|"DELETED", loyalty_account_id: string, reward_tier_id: string, order_id?: string}
export def "loyalty-rewards CreateLoyaltyReward" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  reward: record # Represents a contract to redeem loyalty points for a [reward tier](entity:LoyaltyProgramRewardTier) discount. Loyalty rewards can be in an ISSUED, REDEEMED, or DELETED state.  For more information, see [Manage loyalty rewards](https://developer.squareup.com/docs/loyalty-api/loyalty-rewards). — shape: {status?: "ISSUED"|"REDEEMED"|"DELETED", loyalty_account_id: string, reward_tier_id: string, order_id?: string}
  idempotency_key: string # A unique string that identifies this `CreateLoyaltyReward` request.  Keys can be any valid string, but must be unique for every request.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, reward: record<id: string, status: string, loyalty_account_id: string, reward_tier_id: string, points: int, order_id: string, created_at: string, updated_at: string, redeemed_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/rewards")
  let body = {reward: $reward, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchLoyaltyRewards
#
# POST /v2/loyalty/rewards/search
# operationId: SearchLoyaltyRewards
# --query shape: {loyalty_account_id: string, status?: "ISSUED"|"REDEEMED"|"DELETED"}
export def "loyalty-rewards-search SearchLoyaltyRewards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # The set of search requirements. — shape: {loyalty_account_id: string, status?: "ISSUED"|"REDEEMED"|"DELETED"}
  --limit: int # The maximum number of results to return in the response. The default value is 30.
  --cursor: string # A pagination cursor returned by a previous call to  this endpoint. Provide this to retrieve the next set of  results for the original query. For more information,  see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, rewards: table<id: string, status: string, loyalty_account_id: string, reward_tier_id: string, points: int, order_id: string, created_at: string, updated_at: string, redeemed_at: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/loyalty/rewards/search")
  let body = {query: $body_query, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteLoyaltyReward
#
# DELETE /v2/loyalty/rewards/{reward_id}
# operationId: DeleteLoyaltyReward
export def "loyalty-rewards DeleteLoyaltyReward" [
  reward_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/rewards/($reward_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveLoyaltyReward
#
# GET /v2/loyalty/rewards/{reward_id}
# operationId: RetrieveLoyaltyReward
export def "loyalty-rewards RetrieveLoyaltyReward" [
  reward_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, reward: record<id: string, status: string, loyalty_account_id: string, reward_tier_id: string, points: int, order_id: string, created_at: string, updated_at: string, redeemed_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/rewards/($reward_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RedeemLoyaltyReward
#
# POST /v2/loyalty/rewards/{reward_id}/redeem
# operationId: RedeemLoyaltyReward
export def "loyalty-rewards-redeem RedeemLoyaltyReward" [
  reward_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this `RedeemLoyaltyReward` request.  Keys can be any valid string, but must be unique for every request.
  location_id: string # The ID of the [location](entity:Location) where the reward is redeemed.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, event: record<id: string, type: string, created_at: string, accumulate_points: record<loyalty_program_id: string, points: int, order_id: string>, create_reward: record<loyalty_program_id: string, reward_id: string, points: int>, redeem_reward: record<loyalty_program_id: string, reward_id: string, order_id: string>, delete_reward: record<loyalty_program_id: string, reward_id: string, points: int>, adjust_points: record<loyalty_program_id: string, points: int, reason: string>, loyalty_account_id: string, location_id: string, source: string, expire_points: record<loyalty_program_id: string, points: int>, other_event: record<loyalty_program_id: string, points: int>, accumulate_promotion_points: record<loyalty_program_id: string, loyalty_promotion_id: string, points: int, order_id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/loyalty/rewards/($reward_id)/redeem")
  let body = {idempotency_key: $idempotency_key, location_id: $location_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListMerchants
#
# GET /v2/merchants
# operationId: ListMerchants
export def "merchants ListMerchants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: int # The cursor generated by the previous response.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, merchant: table<id: string, business_name: string, country: string, language_code: string, currency: string, status: string, main_location_id: string, created_at: string>, cursor: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/merchants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListMerchantCustomAttributeDefinitions
#
# GET /v2/merchants/custom-attribute-definitions
# operationId: ListMerchantCustomAttributeDefinitions
export def "merchants-custom-attribute-definitions ListMerchantCustomAttributeDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility-filter: string@visibility-filter-completer # Filters the `CustomAttributeDefinition` results by their `visibility` values.
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory. The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100. The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<custom_attribute_definitions: table<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility_filter" $visibility_filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/merchants/custom-attribute-definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateMerchantCustomAttributeDefinition
#
# POST /v2/merchants/custom-attribute-definitions
# operationId: CreateMerchantCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "merchants-custom-attribute-definitions CreateMerchantCustomAttributeDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/merchants/custom-attribute-definitions")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteMerchantCustomAttributeDefinition
#
# DELETE /v2/merchants/custom-attribute-definitions/{key}
# operationId: DeleteMerchantCustomAttributeDefinition
export def "merchants-custom-attribute-definitions DeleteMerchantCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/merchants/custom-attribute-definitions/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveMerchantCustomAttributeDefinition
#
# GET /v2/merchants/custom-attribute-definitions/{key}
# operationId: RetrieveMerchantCustomAttributeDefinition
export def "merchants-custom-attribute-definitions RetrieveMerchantCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # The current version of the custom attribute definition, which is used for strongly consistent reads to guarantee that you receive the most up-to-date data. When included in the request, Square returns the specified version or a higher version if one exists. If the specified version is higher than the current version, Square returns a `BAD_REQUEST` error.
]: nothing -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/merchants/custom-attribute-definitions/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateMerchantCustomAttributeDefinition
#
# PUT /v2/merchants/custom-attribute-definitions/{key}
# operationId: UpdateMerchantCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "merchants-custom-attribute-definitions UpdateMerchantCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/merchants/custom-attribute-definitions/($key)")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkDeleteMerchantCustomAttributes
#
# POST /v2/merchants/custom-attributes/bulk-delete
# operationId: BulkDeleteMerchantCustomAttributes
export def "merchants-custom-attributes-bulk-delete BulkDeleteMerchantCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # The data used to update the `CustomAttribute` objects. The keys must be unique and are used to map to the corresponding response.
]: any -> record<values: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/merchants/custom-attributes/bulk-delete")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkUpsertMerchantCustomAttributes
#
# POST /v2/merchants/custom-attributes/bulk-upsert
# operationId: BulkUpsertMerchantCustomAttributes
export def "merchants-custom-attributes-bulk-upsert BulkUpsertMerchantCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # A map containing 1 to 25 individual upsert requests. For each request, provide an arbitrary ID that is unique for this `BulkUpsertMerchantCustomAttributes` request and the information needed to create or update a custom attribute.
]: any -> record<values: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/merchants/custom-attributes/bulk-upsert")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveMerchant
#
# GET /v2/merchants/{merchant_id}
# operationId: RetrieveMerchant
export def "merchants RetrieveMerchant" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, merchant: record<id: string, business_name: string, country: string, language_code: string, currency: string, status: string, main_location_id: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/merchants/($merchant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListMerchantCustomAttributes
#
# GET /v2/merchants/{merchant_id}/custom-attributes
# operationId: ListMerchantCustomAttributes
export def "merchants-custom-attributes ListMerchantCustomAttributes" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility-filter: string@visibility-filter-completer # Filters the `CustomAttributeDefinition` results by their `visibility` values.
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory. The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100. The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --with-definitions: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of each custom attribute. Set this parameter to `true` to get the name and description of each custom attribute, information about the data type, or other definition details. The default value is `false`. (default: false)
]: nothing -> record<custom_attributes: table<key: string, value: any, version: int, visibility: string, definition: record, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility_filter" $visibility_filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "with_definitions" $with_definitions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/merchants/($merchant_id)/custom-attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeleteMerchantCustomAttribute
#
# DELETE /v2/merchants/{merchant_id}/custom-attributes/{key}
# operationId: DeleteMerchantCustomAttribute
export def "merchants-custom-attributes DeleteMerchantCustomAttribute" [
  merchant_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/merchants/($merchant_id)/custom-attributes/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveMerchantCustomAttribute
#
# GET /v2/merchants/{merchant_id}/custom-attributes/{key}
# operationId: RetrieveMerchantCustomAttribute
export def "merchants-custom-attributes RetrieveMerchantCustomAttribute" [
  merchant_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-definition: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of the custom attribute. Set this parameter to `true` to get the name and description of the custom attribute, information about the data type, or other definition details. The default value is `false`. (default: false)
  --version: int # The current version of the custom attribute, which is used for strongly consistent reads to guarantee that you receive the most up-to-date data. When included in the request, Square returns the specified version or a higher version if one exists. If the specified version is higher than the current version, Square returns a `BAD_REQUEST` error.
]: nothing -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_definition" $with_definition "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/merchants/($merchant_id)/custom-attributes/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpsertMerchantCustomAttribute
#
# POST /v2/merchants/{merchant_id}/custom-attributes/{key}
# operationId: UpsertMerchantCustomAttribute
# --custom_attribute shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
export def "merchants-custom-attributes UpsertMerchantCustomAttribute" [
  merchant_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute: record # A custom attribute value. Each custom attribute value has a corresponding `CustomAttributeDefinition` object. — shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/merchants/($merchant_id)/custom-attributes/($key)")
  let body = {custom_attribute: $custom_attribute, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveLocationSettings
#
# GET /v2/online-checkout/location-settings/{location_id}
# operationId: RetrieveLocationSettings
export def "online-checkout-location-settings RetrieveLocationSettings" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, location_settings: record<location_id: string, customer_notes_enabled: bool, policies: list<record>, branding: record<header_type: string, button_color: string, button_shape: string>, tipping: record<percentages: list, smart_tipping_enabled: bool, default_percent: int, smart_tips: list, default_smart_tip: record>, coupons: record<enabled: bool>, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/online-checkout/location-settings/($location_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateLocationSettings
#
# PUT /v2/online-checkout/location-settings/{location_id}
# operationId: UpdateLocationSettings
# --location_settings shape: {location_id?: string, customer_notes_enabled?: bool, policies?: list, branding?: record, tipping?: record, coupons?: record}
export def "online-checkout-location-settings UpdateLocationSettings" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  location_settings: record # shape: {location_id?: string, customer_notes_enabled?: bool, policies?: list, branding?: record, tipping?: record, coupons?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, location_settings: record<location_id: string, customer_notes_enabled: bool, policies: list<record>, branding: record<header_type: string, button_color: string, button_shape: string>, tipping: record<percentages: list, smart_tipping_enabled: bool, default_percent: int, smart_tips: list, default_smart_tip: record>, coupons: record<enabled: bool>, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/online-checkout/location-settings/($location_id)")
  let body = {location_settings: $location_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveMerchantSettings
#
# GET /v2/online-checkout/merchant-settings
# operationId: RetrieveMerchantSettings
export def "online-checkout-merchant-settings RetrieveMerchantSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, merchant_settings: record<payment_methods: record<apple_pay: record, google_pay: record, cash_app: record, afterpay_clearpay: record>, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/online-checkout/merchant-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateMerchantSettings
#
# PUT /v2/online-checkout/merchant-settings
# operationId: UpdateMerchantSettings
# --merchant_settings shape: {payment_methods?: record}
export def "online-checkout-merchant-settings UpdateMerchantSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merchant_settings: record # shape: {payment_methods?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, merchant_settings: record<payment_methods: record<apple_pay: record, google_pay: record, cash_app: record, afterpay_clearpay: record>, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/online-checkout/merchant-settings")
  let body = {merchant_settings: $merchant_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListPaymentLinks
#
# GET /v2/online-checkout/payment-links
# operationId: ListPaymentLinks
export def "online-checkout-payment-links ListPaymentLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. If a cursor is not provided, the endpoint returns the first page of the results. For more  information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # A limit on the number of results to return per page. The limit is advisory and the implementation might return more or less results. If the supplied limit is negative, zero, or greater than the maximum limit of 1000, it is ignored.  Default value: `100`
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, payment_links: table<id: string, version: int, description: string, order_id: string, checkout_options: record, pre_populated_data: record, url: string, long_url: string, created_at: string, updated_at: string, payment_note: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/online-checkout/payment-links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreatePaymentLink
#
# POST /v2/online-checkout/payment-links
# operationId: CreatePaymentLink
# --quick_pay shape: {name: string, price_money: record, location_id: string}
# --order shape: {location_id: string, reference_id?: string, source?: record, customer_id?: string, line_items?: list, taxes?: list, discounts?: list, service_charges?: list, fulfillments?: list, return_amounts?: record, net_amounts?: record, rounding_adjustment?: record, metadata?: record, state?: "OPEN"|"COMPLETED"|"CANCELED"|"DRAFT", version?: int, total_money?: record, total_tax_money?: record, total_discount_money?: record, total_tip_money?: record, total_service_charge_money?: record, ticket_name?: string, pricing_options?: record, net_amount_due_money?: record}
# --checkout_options shape: {allow_tipping?: bool, custom_fields?: list, subscription_plan_id?: string, redirect_url?: string, merchant_support_email?: string, ask_for_shipping_address?: bool, accepted_payment_methods?: record, app_fee_money?: record, shipping_fee?: record, enable_coupon?: bool, enable_loyalty?: bool}
# --pre_populated_data shape: {buyer_email?: string, buyer_phone_number?: string, buyer_address?: record}
export def "online-checkout-payment-links CreatePaymentLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string that identifies this `CreatePaymentLinkRequest` request. If you do not provide a unique string (or provide an empty string as the value), the endpoint treats each request as independent.  For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --description: string # A description of the payment link. You provide this optional description that is useful in your application context. It is not used anywhere.
  --quick-pay: record # Describes an ad hoc item and price to generate a quick pay checkout link. For more information, see [Quick Pay Checkout](https://developer.squareup.com/docs/checkout-api/quick-pay-checkout). — shape: {name: string, price_money: record, location_id: string}
  --order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns.  All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {location_id: string, reference_id?: string, source?: record, customer_id?: string, line_items?: list, taxes?: list, discounts?: list, service_charges?: list, fulfillments?: list, return_amounts?: record, net_amounts?: record, rounding_adjustment?: record, metadata?: record, state?: "OPEN"|"COMPLETED"|"CANCELED"|"DRAFT", version?: int, total_money?: record, total_tax_money?: record, total_discount_money?: record, total_tip_money?: record, total_service_charge_money?: record, ticket_name?: string, pricing_options?: record, net_amount_due_money?: record}
  --checkout-options: record # shape: {allow_tipping?: bool, custom_fields?: list, subscription_plan_id?: string, redirect_url?: string, merchant_support_email?: string, ask_for_shipping_address?: bool, accepted_payment_methods?: record, app_fee_money?: record, shipping_fee?: record, enable_coupon?: bool, enable_loyalty?: bool}
  --pre-populated-data: record # Describes buyer data to prepopulate in the payment form. For more information, see [Optional Checkout Configurations](https://developer.squareup.com/docs/checkout-api/optional-checkout-configurations). — shape: {buyer_email?: string, buyer_phone_number?: string, buyer_address?: record}
  --payment-note: string # A note for the payment. After processing the payment, Square adds this note to the resulting `Payment`.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, payment_link: record<id: string, version: int, description: string, order_id: string, checkout_options: record<allow_tipping: bool, custom_fields: list, subscription_plan_id: string, redirect_url: string, merchant_support_email: string, ask_for_shipping_address: bool, accepted_payment_methods: record, app_fee_money: record, shipping_fee: record, enable_coupon: bool, enable_loyalty: bool>, pre_populated_data: record<buyer_email: string, buyer_phone_number: string, buyer_address: record>, url: string, long_url: string, created_at: string, updated_at: string, payment_note: string>, related_resources: record<orders: list<record>, subscription_plans: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/online-checkout/payment-links")
  let body = {idempotency_key: $idempotency_key, description: $description, quick_pay: $quick_pay, order: $order, checkout_options: $checkout_options, pre_populated_data: $pre_populated_data, payment_note: $payment_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeletePaymentLink
#
# DELETE /v2/online-checkout/payment-links/{id}
# operationId: DeletePaymentLink
export def "online-checkout-payment-links DeletePaymentLink" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, id: string, cancelled_order_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/online-checkout/payment-links/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrievePaymentLink
#
# GET /v2/online-checkout/payment-links/{id}
# operationId: RetrievePaymentLink
export def "online-checkout-payment-links RetrievePaymentLink" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, payment_link: record<id: string, version: int, description: string, order_id: string, checkout_options: record<allow_tipping: bool, custom_fields: list, subscription_plan_id: string, redirect_url: string, merchant_support_email: string, ask_for_shipping_address: bool, accepted_payment_methods: record, app_fee_money: record, shipping_fee: record, enable_coupon: bool, enable_loyalty: bool>, pre_populated_data: record<buyer_email: string, buyer_phone_number: string, buyer_address: record>, url: string, long_url: string, created_at: string, updated_at: string, payment_note: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/online-checkout/payment-links/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdatePaymentLink
#
# PUT /v2/online-checkout/payment-links/{id}
# operationId: UpdatePaymentLink
# --payment_link shape: {version: int, description?: string, checkout_options?: record, pre_populated_data?: record, created_at?: string, updated_at?: string, payment_note?: string}
export def "online-checkout-payment-links UpdatePaymentLink" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_link: record # shape: {version: int, description?: string, checkout_options?: record, pre_populated_data?: record, created_at?: string, updated_at?: string, payment_note?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, payment_link: record<id: string, version: int, description: string, order_id: string, checkout_options: record<allow_tipping: bool, custom_fields: list, subscription_plan_id: string, redirect_url: string, merchant_support_email: string, ask_for_shipping_address: bool, accepted_payment_methods: record, app_fee_money: record, shipping_fee: record, enable_coupon: bool, enable_loyalty: bool>, pre_populated_data: record<buyer_email: string, buyer_phone_number: string, buyer_address: record>, url: string, long_url: string, created_at: string, updated_at: string, payment_note: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/online-checkout/payment-links/($id)")
  let body = {payment_link: $payment_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateOrder
#
# POST /v2/orders
# operationId: CreateOrder
# --order shape: {location_id: string, reference_id?: string, source?: record, customer_id?: string, line_items?: list, taxes?: list, discounts?: list, service_charges?: list, fulfillments?: list, return_amounts?: record, net_amounts?: record, rounding_adjustment?: record, metadata?: record, state?: "OPEN"|"COMPLETED"|"CANCELED"|"DRAFT", version?: int, total_money?: record, total_tax_money?: record, total_discount_money?: record, total_tip_money?: record, total_service_charge_money?: record, ticket_name?: string, pricing_options?: record, net_amount_due_money?: record}
export def "orders CreateOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns.  All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {location_id: string, reference_id?: string, source?: record, customer_id?: string, line_items?: list, taxes?: list, discounts?: list, service_charges?: list, fulfillments?: list, return_amounts?: record, net_amounts?: record, rounding_adjustment?: record, metadata?: record, state?: "OPEN"|"COMPLETED"|"CANCELED"|"DRAFT", version?: int, total_money?: record, total_tax_money?: record, total_discount_money?: record, total_tip_money?: record, total_service_charge_money?: record, ticket_name?: string, pricing_options?: record, net_amount_due_money?: record}
  --idempotency-key: string # A value you specify that uniquely identifies this order among orders you have created.  If you are unsure whether a particular order was created successfully, you can try it again with the same idempotency key without worrying about creating duplicate orders.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<order: record<id: string, location_id: string, reference_id: string, source: record<name: string>, customer_id: string, line_items: list<record>, taxes: list<record>, discounts: list<record>, service_charges: list<record>, fulfillments: list<record>, returns: list<record>, return_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, net_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, rounding_adjustment: record<uid: string, name: string, amount_money: record>, tenders: list<record>, refunds: list<record>, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_discount_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, ticket_name: string, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, rewards: list<record>, net_amount_due_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders")
  let body = {order: $order, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BatchRetrieveOrders
#
# POST /v2/orders/batch-retrieve
# operationId: BatchRetrieveOrders
export def "orders-batch-retrieve BatchRetrieveOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-id: string # The ID of the location for these orders. This field is optional: omit it to retrieve orders within the scope of the current authorization's merchant ID. (nullable)
  order_ids: list # The IDs of the orders to retrieve. A maximum of 100 orders can be retrieved per request.
]: any -> record<orders: table<id: string, location_id: string, reference_id: string, source: record, customer_id: string, line_items: list, taxes: list, discounts: list, service_charges: list, fulfillments: list, returns: list, return_amounts: record, net_amounts: record, rounding_adjustment: record, tenders: list, refunds: list, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record, total_tax_money: record, total_discount_money: record, total_tip_money: record, total_service_charge_money: record, ticket_name: string, pricing_options: record, rewards: list, net_amount_due_money: record>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/batch-retrieve")
  let body = {location_id: $location_id, order_ids: $order_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CalculateOrder
#
# POST /v2/orders/calculate
# operationId: CalculateOrder
# --order shape: {location_id: string, reference_id?: string, source?: record, customer_id?: string, line_items?: list, taxes?: list, discounts?: list, service_charges?: list, fulfillments?: list, return_amounts?: record, net_amounts?: record, rounding_adjustment?: record, metadata?: record, state?: "OPEN"|"COMPLETED"|"CANCELED"|"DRAFT", version?: int, total_money?: record, total_tax_money?: record, total_discount_money?: record, total_tip_money?: record, total_service_charge_money?: record, ticket_name?: string, pricing_options?: record, net_amount_due_money?: record}
# --proposed_rewards item shape: {id: string, reward_tier_id: string}
export def "orders-calculate CalculateOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns.  All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {location_id: string, reference_id?: string, source?: record, customer_id?: string, line_items?: list, taxes?: list, discounts?: list, service_charges?: list, fulfillments?: list, return_amounts?: record, net_amounts?: record, rounding_adjustment?: record, metadata?: record, state?: "OPEN"|"COMPLETED"|"CANCELED"|"DRAFT", version?: int, total_money?: record, total_tax_money?: record, total_discount_money?: record, total_tip_money?: record, total_service_charge_money?: record, ticket_name?: string, pricing_options?: record, net_amount_due_money?: record}
  --proposed-rewards: list # Identifies one or more loyalty reward tiers to apply during the order calculation. The discounts defined by the reward tiers are added to the order only to preview the effect of applying the specified rewards. The rewards do not correspond to actual redemptions; that is, no `reward`s are created. Therefore, the reward `id`s are random strings used only to reference the reward tier. (nullable) — item shape: {id: string, reward_tier_id: string}
]: any -> record<order: record<id: string, location_id: string, reference_id: string, source: record<name: string>, customer_id: string, line_items: list<record>, taxes: list<record>, discounts: list<record>, service_charges: list<record>, fulfillments: list<record>, returns: list<record>, return_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, net_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, rounding_adjustment: record<uid: string, name: string, amount_money: record>, tenders: list<record>, refunds: list<record>, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_discount_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, ticket_name: string, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, rewards: list<record>, net_amount_due_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/calculate")
  let body = {order: $order, proposed_rewards: $proposed_rewards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CloneOrder
#
# POST /v2/orders/clone
# operationId: CloneOrder
export def "orders-clone CloneOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  order_id: string # The ID of the order to clone.
  --version: int # An optional order version for concurrency protection.  If a version is provided, it must match the latest stored version of the order to clone. If a version is not provided, the API clones the latest version.
  --idempotency-key: string # A value you specify that uniquely identifies this clone request.  If you are unsure whether a particular order was cloned successfully, you can reattempt the call with the same idempotency key without worrying about creating duplicate cloned orders. The originally cloned order is returned.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<order: record<id: string, location_id: string, reference_id: string, source: record<name: string>, customer_id: string, line_items: list<record>, taxes: list<record>, discounts: list<record>, service_charges: list<record>, fulfillments: list<record>, returns: list<record>, return_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, net_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, rounding_adjustment: record<uid: string, name: string, amount_money: record>, tenders: list<record>, refunds: list<record>, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_discount_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, ticket_name: string, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, rewards: list<record>, net_amount_due_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/clone")
  let body = {order_id: $order_id, version: $version, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListOrderCustomAttributeDefinitions
#
# GET /v2/orders/custom-attribute-definitions
# operationId: ListOrderCustomAttributeDefinitions
export def "orders-custom-attribute-definitions ListOrderCustomAttributeDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility-filter: string@visibility-filter-completer # Requests that all of the custom attributes be returned, or only those that are read-only or read-write.
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint.  Provide this cursor to retrieve the next page of results for your original request.  For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory.  The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100.  The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
]: nothing -> record<custom_attribute_definitions: table<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility_filter" $visibility_filter "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/orders/custom-attribute-definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateOrderCustomAttributeDefinition
#
# POST /v2/orders/custom-attribute-definitions
# operationId: CreateOrderCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "orders-custom-attribute-definitions CreateOrderCustomAttributeDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/custom-attribute-definitions")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteOrderCustomAttributeDefinition
#
# DELETE /v2/orders/custom-attribute-definitions/{key}
# operationId: DeleteOrderCustomAttributeDefinition
export def "orders-custom-attribute-definitions DeleteOrderCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/custom-attribute-definitions/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveOrderCustomAttributeDefinition
#
# GET /v2/orders/custom-attribute-definitions/{key}
# operationId: RetrieveOrderCustomAttributeDefinition
export def "orders-custom-attribute-definitions RetrieveOrderCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # To enable [optimistic concurrency](https://developer.squareup.com/docs/build-basics/common-api-patterns/optimistic-concurrency) control, include this optional field and specify the current version of the custom attribute.
]: nothing -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orders/custom-attribute-definitions/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateOrderCustomAttributeDefinition
#
# PUT /v2/orders/custom-attribute-definitions/{key}
# operationId: UpdateOrderCustomAttributeDefinition
# --custom_attribute_definition shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
export def "orders-custom-attribute-definitions UpdateOrderCustomAttributeDefinition" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute_definition: record # Represents a definition for custom attribute values. A custom attribute definition specifies the key, visibility, schema, and other properties for a custom attribute. — shape: {key?: string, schema?: record, name?: string, description?: string, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", version?: int}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute_definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/custom-attribute-definitions/($key)")
  let body = {custom_attribute_definition: $custom_attribute_definition, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkDeleteOrderCustomAttributes
#
# POST /v2/orders/custom-attributes/bulk-delete
# operationId: BulkDeleteOrderCustomAttributes
export def "orders-custom-attributes-bulk-delete BulkDeleteOrderCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # A map of requests that correspond to individual delete operations for custom attributes.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, values: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/custom-attributes/bulk-delete")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkUpsertOrderCustomAttributes
#
# POST /v2/orders/custom-attributes/bulk-upsert
# operationId: BulkUpsertOrderCustomAttributes
export def "orders-custom-attributes-bulk-upsert BulkUpsertOrderCustomAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  values: record # A map of requests that correspond to individual upsert operations for custom attributes.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, values: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/custom-attributes/bulk-upsert")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchOrders
#
# POST /v2/orders/search
# operationId: SearchOrders
# --query shape: {filter?: record, sort?: record}
export def "orders-search SearchOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-ids: list # The location IDs for the orders to query. All locations must belong to the same merchant.  Max: 10 location IDs.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for your original query. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --body-query: record # Contains query criteria for the search. — shape: {filter?: record, sort?: record}
  --limit: int # The maximum number of results to be returned in a single page.  Default: `500` Max: `1000`
  --return-entries: oneof<nothing, bool> # A Boolean that controls the format of the search results. If `true`, `SearchOrders` returns [OrderEntry](entity:OrderEntry) objects. If `false`, `SearchOrders` returns complete order objects.  Default: `false`.
]: any -> record<order_entries: table<order_id: string, version: int, location_id: string>, orders: table<id: string, location_id: string, reference_id: string, source: record, customer_id: string, line_items: list, taxes: list, discounts: list, service_charges: list, fulfillments: list, returns: list, return_amounts: record, net_amounts: record, rounding_adjustment: record, tenders: list, refunds: list, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record, total_tax_money: record, total_discount_money: record, total_tip_money: record, total_service_charge_money: record, ticket_name: string, pricing_options: record, rewards: list, net_amount_due_money: record>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders/search")
  let body = {location_ids: $location_ids, cursor: $cursor, query: $body_query, limit: $limit, return_entries: $return_entries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveOrder
#
# GET /v2/orders/{order_id}
# operationId: RetrieveOrder
export def "orders RetrieveOrder" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<order: record<id: string, location_id: string, reference_id: string, source: record<name: string>, customer_id: string, line_items: list<record>, taxes: list<record>, discounts: list<record>, service_charges: list<record>, fulfillments: list<record>, returns: list<record>, return_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, net_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, rounding_adjustment: record<uid: string, name: string, amount_money: record>, tenders: list<record>, refunds: list<record>, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_discount_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, ticket_name: string, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, rewards: list<record>, net_amount_due_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/($order_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateOrder
#
# PUT /v2/orders/{order_id}
# operationId: UpdateOrder
# --order shape: {location_id: string, reference_id?: string, source?: record, customer_id?: string, line_items?: list, taxes?: list, discounts?: list, service_charges?: list, fulfillments?: list, return_amounts?: record, net_amounts?: record, rounding_adjustment?: record, metadata?: record, state?: "OPEN"|"COMPLETED"|"CANCELED"|"DRAFT", version?: int, total_money?: record, total_tax_money?: record, total_discount_money?: record, total_tip_money?: record, total_service_charge_money?: record, ticket_name?: string, pricing_options?: record, net_amount_due_money?: record}
export def "orders UpdateOrder" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: record # Contains all information related to a single order to process with Square, including line items that specify the products to purchase. `Order` objects also include information about any associated tenders, refunds, and returns.  All Connect V2 Transactions have all been converted to Orders including all associated itemization data. — shape: {location_id: string, reference_id?: string, source?: record, customer_id?: string, line_items?: list, taxes?: list, discounts?: list, service_charges?: list, fulfillments?: list, return_amounts?: record, net_amounts?: record, rounding_adjustment?: record, metadata?: record, state?: "OPEN"|"COMPLETED"|"CANCELED"|"DRAFT", version?: int, total_money?: record, total_tax_money?: record, total_discount_money?: record, total_tip_money?: record, total_service_charge_money?: record, ticket_name?: string, pricing_options?: record, net_amount_due_money?: record}
  --fields-to-clear: list # The [dot notation paths](https://developer.squareup.com/docs/orders-api/manage-orders/update-orders#identifying-fields-to-delete) fields to clear. For example, `line_items[uid].note`. For more information, see [Deleting fields](https://developer.squareup.com/docs/orders-api/manage-orders/update-orders#deleting-fields). (nullable)
  --idempotency-key: string # A value you specify that uniquely identifies this update request.  If you are unsure whether a particular update was applied to an order successfully, you can reattempt it with the same idempotency key without worrying about creating duplicate updates to the order. The latest order version is returned.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<order: record<id: string, location_id: string, reference_id: string, source: record<name: string>, customer_id: string, line_items: list<record>, taxes: list<record>, discounts: list<record>, service_charges: list<record>, fulfillments: list<record>, returns: list<record>, return_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, net_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, rounding_adjustment: record<uid: string, name: string, amount_money: record>, tenders: list<record>, refunds: list<record>, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_discount_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, ticket_name: string, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, rewards: list<record>, net_amount_due_money: record<amount: int, currency: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/($order_id)")
  let body = {order: $order, fields_to_clear: $fields_to_clear, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListOrderCustomAttributes
#
# GET /v2/orders/{order_id}/custom-attributes
# operationId: ListOrderCustomAttributes
export def "orders-custom-attributes ListOrderCustomAttributes" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility-filter: string@visibility-filter-completer # Requests that all of the custom attributes be returned, or only those that are read-only or read-write.
  --cursor: string # The cursor returned in the paged response from the previous call to this endpoint.  Provide this cursor to retrieve the next page of results for your original request.  For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --limit: int # The maximum number of results to return in a single paged response. This limit is advisory.  The response might contain more or fewer results. The minimum value is 1 and the maximum value is 100.  The default value is 20. For more information, see [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
  --with-definitions: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of each custom attribute. Set this parameter to `true` to get the name and description of each custom attribute,  information about the data type, or other definition details. The default value is `false`. (default: false)
]: nothing -> record<custom_attributes: table<key: string, value: any, version: int, visibility: string, definition: record, updated_at: string, created_at: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility_filter" $visibility_filter "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_definitions" $with_definitions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orders/($order_id)/custom-attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeleteOrderCustomAttribute
#
# DELETE /v2/orders/{order_id}/custom-attributes/{custom_attribute_key}
# operationId: DeleteOrderCustomAttribute
export def "orders-custom-attributes DeleteOrderCustomAttribute" [
  order_id: string
  custom_attribute_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/($order_id)/custom-attributes/($custom_attribute_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveOrderCustomAttribute
#
# GET /v2/orders/{order_id}/custom-attributes/{custom_attribute_key}
# operationId: RetrieveOrderCustomAttribute
export def "orders-custom-attributes RetrieveOrderCustomAttribute" [
  order_id: string
  custom_attribute_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # To enable [optimistic concurrency](https://developer.squareup.com/docs/build-basics/common-api-patterns/optimistic-concurrency) control, include this optional field and specify the current version of the custom attribute.
  --with-definition: oneof<nothing, bool> # Indicates whether to return the [custom attribute definition](entity:CustomAttributeDefinition) in the `definition` field of each  custom attribute. Set this parameter to `true` to get the name and description of each custom attribute,  information about the data type, or other definition details. The default value is `false`. (default: false)
]: nothing -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "with_definition" $with_definition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orders/($order_id)/custom-attributes/($custom_attribute_key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpsertOrderCustomAttribute
#
# POST /v2/orders/{order_id}/custom-attributes/{custom_attribute_key}
# operationId: UpsertOrderCustomAttribute
# --custom_attribute shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
export def "orders-custom-attributes UpsertOrderCustomAttribute" [
  order_id: string
  custom_attribute_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attribute: record # A custom attribute value. Each custom attribute value has a corresponding `CustomAttributeDefinition` object. — shape: {key?: string, value?: any, version?: int, visibility?: "VISIBILITY_HIDDEN"|"VISIBILITY_READ_ONLY"|"VISIBILITY_READ_WRITE_VALUES", definition?: record}
  --idempotency-key: string # A unique identifier for this request, used to ensure idempotency.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency). (nullable)
]: any -> record<custom_attribute: record<key: string, value: any, version: int, visibility: string, definition: record<key: string, schema: record, name: string, description: string, visibility: string, version: int, updated_at: string, created_at: string>, updated_at: string, created_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/($order_id)/custom-attributes/($custom_attribute_key)")
  let body = {custom_attribute: $custom_attribute, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PayOrder
#
# POST /v2/orders/{order_id}/pay
# operationId: PayOrder
export def "orders-pay PayOrder" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A value you specify that uniquely identifies this request among requests you have sent. If you are unsure whether a particular payment request was completed successfully, you can reattempt it with the same idempotency key without worrying about duplicate payments.  For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --order-version: int # The version of the order being paid. If not supplied, the latest version will be paid. (nullable)
  --payment-ids: list # The IDs of the [payments](entity:Payment) to collect. The payment total must match the order total. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, order: record<id: string, location_id: string, reference_id: string, source: record<name: string>, customer_id: string, line_items: list<record>, taxes: list<record>, discounts: list<record>, service_charges: list<record>, fulfillments: list<record>, returns: list<record>, return_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, net_amounts: record<total_money: record, tax_money: record, discount_money: record, tip_money: record, service_charge_money: record>, rounding_adjustment: record<uid: string, name: string, amount_money: record>, tenders: list<record>, refunds: list<record>, metadata: record, created_at: string, updated_at: string, closed_at: string, state: string, version: int, total_money: record<amount: int, currency: string>, total_tax_money: record<amount: int, currency: string>, total_discount_money: record<amount: int, currency: string>, total_tip_money: record<amount: int, currency: string>, total_service_charge_money: record<amount: int, currency: string>, ticket_name: string, pricing_options: record<auto_apply_discounts: bool, auto_apply_taxes: bool>, rewards: list<record>, net_amount_due_money: record<amount: int, currency: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/($order_id)/pay")
  let body = {idempotency_key: $idempotency_key, order_version: $order_version, payment_ids: $payment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListPayments
#
# GET /v2/payments
# operationId: ListPayments
export def "payments ListPayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --begin-time: string # Indicates the start of the time range to retrieve payments for, in RFC 3339 format. The range is determined using the `created_at` field for each Payment. Inclusive. Default: The current time minus one year.
  --end-time: string # Indicates the end of the time range to retrieve payments for, in RFC 3339 format.  The range is determined using the `created_at` field for each Payment.  Default: The current time.
  --sort-order: string # The order in which results are listed by `ListPaymentsRequest.sort_field`: - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --location-id: string # Limit results to the location supplied. By default, results are returned for the default (main) location associated with the seller.
  --total: int # The exact amount in the `total_money` for a payment. (format: int64)
  --last-4: string # The last four digits of a payment card.
  --card-brand: string # The brand of the payment card (for example, VISA).
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page.  The default value of 100 is also the maximum allowed value. If the provided value is  greater than 100, it is ignored and the default value is used instead.  Default: `100`
  --is-offline-payment: oneof<nothing, bool> # Whether the payment was taken offline or not. (default: false)
  --offline-begin-time: string # Indicates the start of the time range for which to retrieve offline payments, in RFC 3339 format for timestamps. The range is determined using the `offline_payment_details.client_created_at` field for each Payment. If set, payments without a value set in `offline_payment_details.client_created_at` will not be returned.  Default: The current time.
  --offline-end-time: string # Indicates the end of the time range for which to retrieve offline payments, in RFC 3339 format for timestamps. The range is determined using the `offline_payment_details.client_created_at` field for each Payment. If set, payments without a value set in `offline_payment_details.client_created_at` will not be returned.  Default: The current time.
  --updated-at-begin-time: string # Indicates the start of the time range to retrieve payments for, in RFC 3339 format.  The range is determined using the `updated_at` field for each Payment.
  --updated-at-end-time: string # Indicates the end of the time range to retrieve payments for, in RFC 3339 format.  The range is determined using the `updated_at` field for each Payment.
  --sort-field: string@sort-field-completer-1 # The field used to sort results by. The default is `CREATED_AT`.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, payments: table<id: string, created_at: string, updated_at: string, amount_money: record, tip_money: record, total_money: record, app_fee_money: record, app_fee_allocations: list, approved_money: record, processing_fee: list, refunded_money: record, status: string, delay_duration: string, delay_action: string, delayed_until: string, source_type: string, card_details: record, cash_details: record, bank_account_details: record, electronic_money_details: record, external_details: record, wallet_details: record, buy_now_pay_later_details: record, square_account_details: record, location_id: string, order_id: string, reference_id: string, customer_id: string, employee_id: string, team_member_id: string, refund_ids: list, risk_evaluation: record, terminal_checkout_id: string, buyer_email_address: string, billing_address: record, shipping_address: record, note: string, statement_description_identifier: string, capabilities: list, receipt_number: string, receipt_url: string, device_details: record, application_details: record, buyer_currency_exchange: any, is_offline_payment: bool, offline_payment_details: record, version_token: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "last_4" $last_4 "scalar") (serialize-qp "card_brand" $card_brand "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "is_offline_payment" $is_offline_payment "scalar") (serialize-qp "offline_begin_time" $offline_begin_time "scalar") (serialize-qp "offline_end_time" $offline_end_time "scalar") (serialize-qp "updated_at_begin_time" $updated_at_begin_time "scalar") (serialize-qp "updated_at_end_time" $updated_at_end_time "scalar") (serialize-qp "sort_field" $sort_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreatePayment
#
# POST /v2/payments
# operationId: CreatePayment
# --amount_money shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
# --tip_money shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
# --app_fee_money shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
# --billing_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
# --shipping_address shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
# --cash_details shape: {buyer_supplied_money: record, change_back_money?: record}
# --external_details shape: {type: string, source: string, source_id?: string, source_fee_money?: record}
# --customer_details shape: {customer_initiated?: bool, seller_keyed_in?: bool}
export def "payments CreatePayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_id: string # The ID for the source of funds for this payment. This could be a payment token generated by the Web Payments SDK for any of its [supported methods](https://developer.squareup.com/docs/web-payments/overview#explore-payment-methods), including cards, bank transfers, Afterpay or Cash App Pay. If recording a payment that the seller received outside of Square, specify either "CASH" or "EXTERNAL". For more information, see [Take Payments](https://developer.squareup.com/docs/payments-api/take-payments).
  idempotency_key: string # A unique string that identifies this `CreatePayment` request. Keys can be any valid string but must be unique for every `CreatePayment` request.  Note: The number of allowed characters might be less than the stated maximum, if multi-byte characters are used.  For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  --amount-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
  --tip-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
  --app-fee-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
  --app-fee-allocations: list # Details pertaining to recipients of the application fee. The sum of the amounts in the app_fee_allocations must equal the app_fee_money amount, if present. If populated, an allocation must be present for every party that expects to receive a portion of the application fee, including the application developer.
  --delay-duration: string # The duration of time after the payment's creation when Square automatically either completes or cancels the payment depending on the `delay_action` field value. For more information, see [Time threshold](https://developer.squareup.com/docs/payments-api/take-payments/card-payments/delayed-capture#time-threshold).  This parameter should be specified as a time duration, in RFC 3339 format.  Note: This feature is only supported for card payments. This parameter can only be set for a delayed capture payment (`autocomplete=false`).  Default:  - Card-present payments: "PT36H" (36 hours) from the creation time. - Card-not-present payments: "P7D" (7 days) from the creation time.
  --delay-action: string # The action to be applied to the payment when the `delay_duration` has elapsed. The action must be CANCEL or COMPLETE. For more information, see [Time Threshold](https://developer.squareup.com/docs/payments-api/take-payments/card-payments/delayed-capture#time-threshold).  Default: CANCEL
  --autocomplete: oneof<nothing, bool> # If set to `true`, this payment will be completed when possible. If set to `false`, this payment is held in an approved state until either explicitly completed (captured) or canceled (voided). For more information, see [Delayed capture](https://developer.squareup.com/docs/payments-api/take-payments/card-payments#delayed-capture-of-a-card-payment).  Default: true
  --order-id: string # Associates a previously created order with this payment.
  --customer-id: string # The [Customer](entity:Customer) ID of the customer associated with the payment.  This is required if the `source_id` refers to a card on file created using the Cards API.
  --location-id: string # The location ID to associate with the payment. If not specified, the [main location](https://developer.squareup.com/docs/locations-api#about-the-main-location) is used.
  --team-member-id: string # An optional [TeamMember](entity:TeamMember) ID to associate with this payment.
  --reference-id: string # A user-defined ID to associate with the payment.  You can use this field to associate the payment to an entity in an external system (for example, you might specify an order ID that is generated by a third-party shopping cart).
  --verification-token: string # An identifying token generated by [payments.verifyBuyer()](https://developer.squareup.com/reference/sdks/web/payments/objects/Payments#Payments.verifyBuyer). Verification tokens encapsulate customer device information and 3-D Secure challenge results to indicate that Square has verified the buyer identity.  For more information, see [SCA Overview](https://developer.squareup.com/docs/sca-overview).
  --accept-partial-authorization: oneof<nothing, bool> # If set to `true` and charging a Square Gift Card, a payment might be returned with `amount_money` equal to less than what was requested. For example, a request for $20 when charging a Square Gift Card with a balance of $5 results in an APPROVED payment of $5. You might choose to prompt the buyer for an additional payment to cover the remainder or cancel the Gift Card payment. This field cannot be `true` when `autocomplete = true`.  For more information, see [Partial amount with Square Gift Cards](https://developer.squareup.com/docs/payments-api/take-payments#partial-payment-gift-card).  Default: false
  --buyer-email-address: string # The buyer's email address.
  --buyer-phone-number: string # The buyer's phone number. Must follow the following format: 1. A leading + symbol (followed by a country code) 2. The phone number can contain spaces and the special characters `(` , `)` , `-` , and `.`. Alphabetical characters aren't allowed. 3. The phone number must contain between 9 and 16 digits.
  --billing-address: record # Represents a postal address in a country.  For more information, see [Working with Addresses](https://developer.squareup.com/docs/build-basics/working-with-addresses). — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
  --shipping-address: record # Represents a postal address in a country.  For more information, see [Working with Addresses](https://developer.squareup.com/docs/build-basics/working-with-addresses). — shape: {address_line_1?: string, address_line_2?: string, address_line_3?: string, locality?: string, sublocality?: string, sublocality_2?: string, sublocality_3?: string, administrative_district_level_1?: string, administrative_district_level_2?: string, administrative_district_level_3?: string, postal_code?: string, country?: "ZZ"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BV"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HM"|"HN"|"HR"|"HT"|"HU"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"YE"|"YT"|"ZA"|"ZM"|"ZW", first_name?: string, last_name?: string}
  --note: string # An optional note to be entered by the developer when creating a payment.
  --statement-description-identifier: string # Optional additional payment information to include on the customer's card statement as part of the statement description. This can be, for example, an invoice number, ticket number, or short description that uniquely identifies the purchase.  Note that the `statement_description_identifier` might get truncated on the statement description to fit the required information including the Square identifier (SQ *) and name of the seller taking the payment.
  --cash-details: record # Stores details about a cash payment. Contains only non-confidential information. For more information, see  [Take Cash Payments](https://developer.squareup.com/docs/payments-api/take-payments/cash-payments). — shape: {buyer_supplied_money: record, change_back_money?: record}
  --external-details: record # Stores details about an external payment. Contains only non-confidential information. For more information, see  [Take External Payments](https://developer.squareup.com/docs/payments-api/take-payments/external-payments). — shape: {type: string, source: string, source_id?: string, source_fee_money?: record}
  --customer-details: record # Details about the customer making the payment. — shape: {customer_initiated?: bool, seller_keyed_in?: bool}
  --offline-payment-details: record # Details specific to offline payments.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<id: string, created_at: string, updated_at: string, amount_money: record<amount: int, currency: string>, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, app_fee_allocations: list<any>, approved_money: record<amount: int, currency: string>, processing_fee: list<record>, refunded_money: record<amount: int, currency: string>, status: string, delay_duration: string, delay_action: string, delayed_until: string, source_type: string, card_details: record<status: string, card: record, entry_method: string, cvv_status: string, avs_status: string, auth_result_code: string, application_identifier: string, application_name: string, application_cryptogram: string, verification_method: string, verification_results: string, statement_description: string, device_details: record, card_payment_timeline: record, refund_requires_card_presence: bool, errors: list, applied_card_surcharge_details: record, wallet_type: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, bank_account_details: record<bank_name: string, transfer_type: string, account_ownership_type: string, fingerprint: string, country: string, statement_description: string, ach_details: record, errors: list>, electronic_money_details: record<felica_details: record>, external_details: record<type: string, source: string, source_id: string, source_fee_money: record>, wallet_details: record<status: string, brand: string, cash_app_details: record, lightning_details: record, errors: list>, buy_now_pay_later_details: record<brand: string, afterpay_details: record, clearpay_details: record, errors: list>, square_account_details: record<payment_source_token: string, errors: list>, location_id: string, order_id: string, reference_id: string, customer_id: string, employee_id: string, team_member_id: string, refund_ids: list<string>, risk_evaluation: record<created_at: string, risk_level: string>, terminal_checkout_id: string, buyer_email_address: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, note: string, statement_description_identifier: string, capabilities: list<string>, receipt_number: string, receipt_url: string, device_details: record<device_id: string, device_installation_id: string, device_name: string>, application_details: record<square_product: string, application_id: string>, buyer_currency_exchange: any, is_offline_payment: bool, offline_payment_details: record<client_created_at: string>, version_token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payments")
  let body = {source_id: $source_id, idempotency_key: $idempotency_key, amount_money: $amount_money, tip_money: $tip_money, app_fee_money: $app_fee_money, app_fee_allocations: $app_fee_allocations, delay_duration: $delay_duration, delay_action: $delay_action, autocomplete: $autocomplete, order_id: $order_id, customer_id: $customer_id, location_id: $location_id, team_member_id: $team_member_id, reference_id: $reference_id, verification_token: $verification_token, accept_partial_authorization: $accept_partial_authorization, buyer_email_address: $buyer_email_address, buyer_phone_number: $buyer_phone_number, billing_address: $billing_address, shipping_address: $shipping_address, note: $note, statement_description_identifier: $statement_description_identifier, cash_details: $cash_details, external_details: $external_details, customer_details: $customer_details, offline_payment_details: $offline_payment_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CancelPaymentByIdempotencyKey
#
# POST /v2/payments/cancel
# operationId: CancelPaymentByIdempotencyKey
export def "payments-cancel CancelPaymentByIdempotencyKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # The `idempotency_key` identifying the payment to be canceled.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payments/cancel")
  let body = {idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetPayment
#
# GET /v2/payments/{payment_id}
# operationId: GetPayment
export def "payments GetPayment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<id: string, created_at: string, updated_at: string, amount_money: record<amount: int, currency: string>, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, app_fee_allocations: list<any>, approved_money: record<amount: int, currency: string>, processing_fee: list<record>, refunded_money: record<amount: int, currency: string>, status: string, delay_duration: string, delay_action: string, delayed_until: string, source_type: string, card_details: record<status: string, card: record, entry_method: string, cvv_status: string, avs_status: string, auth_result_code: string, application_identifier: string, application_name: string, application_cryptogram: string, verification_method: string, verification_results: string, statement_description: string, device_details: record, card_payment_timeline: record, refund_requires_card_presence: bool, errors: list, applied_card_surcharge_details: record, wallet_type: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, bank_account_details: record<bank_name: string, transfer_type: string, account_ownership_type: string, fingerprint: string, country: string, statement_description: string, ach_details: record, errors: list>, electronic_money_details: record<felica_details: record>, external_details: record<type: string, source: string, source_id: string, source_fee_money: record>, wallet_details: record<status: string, brand: string, cash_app_details: record, lightning_details: record, errors: list>, buy_now_pay_later_details: record<brand: string, afterpay_details: record, clearpay_details: record, errors: list>, square_account_details: record<payment_source_token: string, errors: list>, location_id: string, order_id: string, reference_id: string, customer_id: string, employee_id: string, team_member_id: string, refund_ids: list<string>, risk_evaluation: record<created_at: string, risk_level: string>, terminal_checkout_id: string, buyer_email_address: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, note: string, statement_description_identifier: string, capabilities: list<string>, receipt_number: string, receipt_url: string, device_details: record<device_id: string, device_installation_id: string, device_name: string>, application_details: record<square_product: string, application_id: string>, buyer_currency_exchange: any, is_offline_payment: bool, offline_payment_details: record<client_created_at: string>, version_token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($payment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdatePayment
#
# PUT /v2/payments/{payment_id}
# operationId: UpdatePayment
# --payment shape: {amount_money?: record, tip_money?: record, total_money?: record, app_fee_money?: record, app_fee_allocations?: list, approved_money?: record, refunded_money?: record, delay_action?: string, card_details?: record, cash_details?: record, bank_account_details?: record, electronic_money_details?: record, external_details?: record, wallet_details?: record, buy_now_pay_later_details?: record, square_account_details?: record, team_member_id?: string, risk_evaluation?: record, billing_address?: record, shipping_address?: record, device_details?: record, application_details?: record, offline_payment_details?: record, version_token?: string}
export def "payments UpdatePayment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment: record # Represents a payment processed by the Square API. — shape: {amount_money?: record, tip_money?: record, total_money?: record, app_fee_money?: record, app_fee_allocations?: list, approved_money?: record, refunded_money?: record, delay_action?: string, card_details?: record, cash_details?: record, bank_account_details?: record, electronic_money_details?: record, external_details?: record, wallet_details?: record, buy_now_pay_later_details?: record, square_account_details?: record, team_member_id?: string, risk_evaluation?: record, billing_address?: record, shipping_address?: record, device_details?: record, application_details?: record, offline_payment_details?: record, version_token?: string}
  idempotency_key: string # A unique string that identifies this `UpdatePayment` request. Keys can be any valid string but must be unique for every `UpdatePayment` request.  For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<id: string, created_at: string, updated_at: string, amount_money: record<amount: int, currency: string>, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, app_fee_allocations: list<any>, approved_money: record<amount: int, currency: string>, processing_fee: list<record>, refunded_money: record<amount: int, currency: string>, status: string, delay_duration: string, delay_action: string, delayed_until: string, source_type: string, card_details: record<status: string, card: record, entry_method: string, cvv_status: string, avs_status: string, auth_result_code: string, application_identifier: string, application_name: string, application_cryptogram: string, verification_method: string, verification_results: string, statement_description: string, device_details: record, card_payment_timeline: record, refund_requires_card_presence: bool, errors: list, applied_card_surcharge_details: record, wallet_type: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, bank_account_details: record<bank_name: string, transfer_type: string, account_ownership_type: string, fingerprint: string, country: string, statement_description: string, ach_details: record, errors: list>, electronic_money_details: record<felica_details: record>, external_details: record<type: string, source: string, source_id: string, source_fee_money: record>, wallet_details: record<status: string, brand: string, cash_app_details: record, lightning_details: record, errors: list>, buy_now_pay_later_details: record<brand: string, afterpay_details: record, clearpay_details: record, errors: list>, square_account_details: record<payment_source_token: string, errors: list>, location_id: string, order_id: string, reference_id: string, customer_id: string, employee_id: string, team_member_id: string, refund_ids: list<string>, risk_evaluation: record<created_at: string, risk_level: string>, terminal_checkout_id: string, buyer_email_address: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, note: string, statement_description_identifier: string, capabilities: list<string>, receipt_number: string, receipt_url: string, device_details: record<device_id: string, device_installation_id: string, device_name: string>, application_details: record<square_product: string, application_id: string>, buyer_currency_exchange: any, is_offline_payment: bool, offline_payment_details: record<client_created_at: string>, version_token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($payment_id)")
  let body = {payment: $payment, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CancelPayment
#
# POST /v2/payments/{payment_id}/cancel
# operationId: CancelPayment
export def "payments-cancel CancelPayment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<id: string, created_at: string, updated_at: string, amount_money: record<amount: int, currency: string>, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, app_fee_allocations: list<any>, approved_money: record<amount: int, currency: string>, processing_fee: list<record>, refunded_money: record<amount: int, currency: string>, status: string, delay_duration: string, delay_action: string, delayed_until: string, source_type: string, card_details: record<status: string, card: record, entry_method: string, cvv_status: string, avs_status: string, auth_result_code: string, application_identifier: string, application_name: string, application_cryptogram: string, verification_method: string, verification_results: string, statement_description: string, device_details: record, card_payment_timeline: record, refund_requires_card_presence: bool, errors: list, applied_card_surcharge_details: record, wallet_type: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, bank_account_details: record<bank_name: string, transfer_type: string, account_ownership_type: string, fingerprint: string, country: string, statement_description: string, ach_details: record, errors: list>, electronic_money_details: record<felica_details: record>, external_details: record<type: string, source: string, source_id: string, source_fee_money: record>, wallet_details: record<status: string, brand: string, cash_app_details: record, lightning_details: record, errors: list>, buy_now_pay_later_details: record<brand: string, afterpay_details: record, clearpay_details: record, errors: list>, square_account_details: record<payment_source_token: string, errors: list>, location_id: string, order_id: string, reference_id: string, customer_id: string, employee_id: string, team_member_id: string, refund_ids: list<string>, risk_evaluation: record<created_at: string, risk_level: string>, terminal_checkout_id: string, buyer_email_address: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, note: string, statement_description_identifier: string, capabilities: list<string>, receipt_number: string, receipt_url: string, device_details: record<device_id: string, device_installation_id: string, device_name: string>, application_details: record<square_product: string, application_id: string>, buyer_currency_exchange: any, is_offline_payment: bool, offline_payment_details: record<client_created_at: string>, version_token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($payment_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CompletePayment
#
# POST /v2/payments/{payment_id}/complete
# operationId: CompletePayment
export def "payments-complete CompletePayment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version-token: string # Used for optimistic concurrency. This opaque token identifies the current `Payment` version that the caller expects. If the server has a different version of the Payment, the update fails and a response with a VERSION_MISMATCH error is returned. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, payment: record<id: string, created_at: string, updated_at: string, amount_money: record<amount: int, currency: string>, tip_money: record<amount: int, currency: string>, total_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, app_fee_allocations: list<any>, approved_money: record<amount: int, currency: string>, processing_fee: list<record>, refunded_money: record<amount: int, currency: string>, status: string, delay_duration: string, delay_action: string, delayed_until: string, source_type: string, card_details: record<status: string, card: record, entry_method: string, cvv_status: string, avs_status: string, auth_result_code: string, application_identifier: string, application_name: string, application_cryptogram: string, verification_method: string, verification_results: string, statement_description: string, device_details: record, card_payment_timeline: record, refund_requires_card_presence: bool, errors: list, applied_card_surcharge_details: record, wallet_type: string>, cash_details: record<buyer_supplied_money: record, change_back_money: record>, bank_account_details: record<bank_name: string, transfer_type: string, account_ownership_type: string, fingerprint: string, country: string, statement_description: string, ach_details: record, errors: list>, electronic_money_details: record<felica_details: record>, external_details: record<type: string, source: string, source_id: string, source_fee_money: record>, wallet_details: record<status: string, brand: string, cash_app_details: record, lightning_details: record, errors: list>, buy_now_pay_later_details: record<brand: string, afterpay_details: record, clearpay_details: record, errors: list>, square_account_details: record<payment_source_token: string, errors: list>, location_id: string, order_id: string, reference_id: string, customer_id: string, employee_id: string, team_member_id: string, refund_ids: list<string>, risk_evaluation: record<created_at: string, risk_level: string>, terminal_checkout_id: string, buyer_email_address: string, billing_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, shipping_address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, note: string, statement_description_identifier: string, capabilities: list<string>, receipt_number: string, receipt_url: string, device_details: record<device_id: string, device_installation_id: string, device_name: string>, application_details: record<square_product: string, application_id: string>, buyer_currency_exchange: any, is_offline_payment: bool, offline_payment_details: record<client_created_at: string>, version_token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($payment_id)/complete")
  let body = {version_token: $version_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListPayouts
#
# GET /v2/payouts
# operationId: ListPayouts
export def "payouts ListPayouts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location-id: string # The ID of the location for which to list the payouts. By default, payouts are returned for the default (main) location associated with the seller.
  --status: string@status-completer-3 # If provided, only payouts with the given status are returned.
  --begin-time: string # The timestamp for the beginning of the payout creation time, in RFC 3339 format. Inclusive. Default: The current time minus one year.
  --end-time: string # The timestamp for the end of the payout creation time, in RFC 3339 format. Default: The current time.
  --sort-order: string@sort-order-completer # The order in which payouts are listed.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination). If request parameters change between requests, subsequent results may contain duplicates or missing records.
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. The default value of 100 is also the maximum allowed value. If the provided value is greater than 100, it is ignored and the default value is used instead. Default: `100`
]: nothing -> record<payouts: table<id: string, status: string, location_id: string, created_at: string, updated_at: string, amount_money: record, destination: record, version: int, type: string, payout_fee: list, arrival_date: string, end_to_end_id: string>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location_id" $location_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/payouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GetPayout
#
# GET /v2/payouts/{payout_id}
# operationId: GetPayout
export def "payouts GetPayout" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payout: record<id: string, status: string, location_id: string, created_at: string, updated_at: string, amount_money: record<amount: int, currency: string>, destination: record<type: string, id: string>, version: int, type: string, payout_fee: list<record>, arrival_date: string, end_to_end_id: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payouts/($payout_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListPayoutEntries
#
# GET /v2/payouts/{payout_id}/payout-entries
# operationId: ListPayoutEntries
export def "payouts-payout-entries ListPayoutEntries" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-order: string@sort-order-completer # The order in which payout entries are listed.
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination). If request parameters change between requests, subsequent results may contain duplicates or missing records.
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. The default value of 100 is also the maximum allowed value. If the provided value is greater than 100, it is ignored and the default value is used instead. Default: `100`
]: nothing -> record<payout_entries: table<id: string, payout_id: string, effective_at: string, type: string, gross_amount_money: record, fee_amount_money: record, net_amount_money: record, type_app_fee_revenue_details: record, type_app_fee_refund_details: record, type_automatic_savings_details: record, type_automatic_savings_reversed_details: record, type_charge_details: record, type_deposit_fee_details: record, type_deposit_fee_reversed_details: record, type_dispute_details: record, type_fee_details: record, type_free_processing_details: record, type_hold_adjustment_details: record, type_open_dispute_details: record, type_other_details: record, type_other_adjustment_details: record, type_refund_details: record, type_release_adjustment_details: record, type_reserve_hold_details: record, type_reserve_release_details: record, type_square_capital_payment_details: record, type_square_capital_reversed_payment_details: record, type_tax_on_fee_details: record, type_third_party_fee_details: record, type_third_party_fee_refund_details: record, type_square_payroll_transfer_details: record, type_square_payroll_transfer_reversed_details: record>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/payouts/($payout_id)/payout-entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListPaymentRefunds
#
# GET /v2/refunds
# operationId: ListPaymentRefunds
export def "refunds ListPaymentRefunds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --begin-time: string # Indicates the start of the time range to retrieve each `PaymentRefund` for, in RFC 3339  format.  The range is determined using the `created_at` field for each `PaymentRefund`.   Default: The current time minus one year.
  --end-time: string # Indicates the end of the time range to retrieve each `PaymentRefund` for, in RFC 3339  format.  The range is determined using the `created_at` field for each `PaymentRefund`.  Default: The current time.
  --sort-order: string # The order in which results are listed by `PaymentRefund.created_at`: - `ASC` - Oldest to newest. - `DESC` - Newest to oldest (default).
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --location-id: string # Limit results to the location supplied. By default, results are returned for all locations associated with the seller.
  --status: string # If provided, only refunds with the given status are returned. For a list of refund status values, see [PaymentRefund](entity:PaymentRefund).  Default: If omitted, refunds are returned regardless of their status.
  --source-type: string # If provided, only returns refunds whose payments have the indicated source type. Current values include `CARD`, `BANK_ACCOUNT`, `WALLET`, `CASH`, and `EXTERNAL`. For information about these payment source types, see [Take Payments](https://developer.squareup.com/docs/payments-api/take-payments).  Default: If omitted, refunds are returned regardless of the source type.
  --limit: int # The maximum number of results to be returned in a single page.  It is possible to receive fewer results than the specified limit on a given page.  If the supplied value is greater than 100, no more than 100 results are returned.  Default: 100
  --updated-at-begin-time: string # Indicates the start of the time range to retrieve each `PaymentRefund` for, in RFC 3339 format.  The range is determined using the `updated_at` field for each `PaymentRefund`.  Default: If omitted, the time range starts at `begin_time`.
  --updated-at-end-time: string # Indicates the end of the time range to retrieve each `PaymentRefund` for, in RFC 3339 format.  The range is determined using the `updated_at` field for each `PaymentRefund`.  Default: The current time.
  --sort-field: string@sort-field-completer-2 # The field used to sort results by. The default is `CREATED_AT`.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, refunds: table<id: string, status: string, location_id: string, unlinked: bool, destination_type: string, destination_details: record, amount_money: record, app_fee_money: record, app_fee_allocations: list, processing_fee: list, payment_id: string, order_id: string, reason: string, created_at: string, updated_at: string, team_member_id: string, terminal_refund_id: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "location_id" $location_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "updated_at_begin_time" $updated_at_begin_time "scalar") (serialize-qp "updated_at_end_time" $updated_at_end_time "scalar") (serialize-qp "sort_field" $sort_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/refunds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RefundPayment
#
# POST /v2/refunds
# operationId: RefundPayment
# --amount_money shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
# --app_fee_money shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
# --cash_details shape: {seller_supplied_money: record, change_back_money?: record}
# --external_details shape: {type: string, source: string, source_id?: string}
export def "refunds RefundPayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string #  A unique string that identifies this `RefundPayment` request. The key can be any valid string but must be unique for every `RefundPayment` request.  Keys are limited to a max of 45 characters - however, the number of allowed characters might be less than 45, if multi-byte characters are used.  For more information, see [Idempotency](https://developer.squareup.com/docs/working-with-apis/idempotency).
  amount_money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
  --app-fee-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
  --app-fee-allocations: list # Details pertaining to contributors to the refund of the application fee. The sum of the amounts in the app_fee_allocations must equal the app_fee_money amount, if present. If populated, an allocation must be present for every party that expects to contribute a portion of the refunded application fee, including the application developer. (nullable)
  --payment-id: string # The unique ID of the payment being refunded. Required when unlinked=false, otherwise must not be set. (nullable)
  --destination-id: string # The ID indicating where funds will be refunded to. Required for unlinked refunds. For more information, see [Process an Unlinked Refund](https://developer.squareup.com/docs/refunds-api/unlinked-refunds).  For refunds linked to Square payments, `destination_id` is usually omitted; in this case, funds will be returned to the original payment source. The field may be specified in order to request a cross-method refund to a gift card. For more information, see [Cross-method refunds to gift cards](https://developer.squareup.com/docs/payments-api/refund-payments#cross-method-refunds-to-gift-cards). (nullable)
  --unlinked: oneof<nothing, bool> # Indicates that the refund is not linked to a Square payment. If set to true, `destination_id` and `location_id` must be supplied while `payment_id` must not be provided. (nullable)
  --location-id: string # The location ID associated with the unlinked refund. Required for requests specifying `unlinked=true`. Otherwise, if included when `unlinked=false`, will throw an error. (nullable)
  --customer-id: string # The [Customer](entity:Customer) ID of the customer associated with the refund. This is required if the `destination_id` refers to a card on file created using the Cards API. Only allowed when `unlinked=true`. (nullable)
  --reason: string # A description of the reason for the refund. (nullable)
  --payment-version-token: string #  Used for optimistic concurrency. This opaque token identifies the current `Payment` version that the caller expects. If the server has a different version of the Payment, the update fails and a response with a VERSION_MISMATCH error is returned. If the versions match, or the field is not provided, the refund proceeds as normal. (nullable)
  --team-member-id: string # An optional [TeamMember](entity:TeamMember) ID to associate with this refund. (nullable)
  --cash-details: record # Stores details about a cash refund. Contains only non-confidential information. — shape: {seller_supplied_money: record, change_back_money?: record}
  --external-details: record # Stores details about an external refund. Contains only non-confidential information. — shape: {type: string, source: string, source_id?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<id: string, status: string, location_id: string, unlinked: bool, destination_type: string, destination_details: record<card_details: record, cash_details: record, external_details: record>, amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, app_fee_allocations: list<any>, processing_fee: list<record>, payment_id: string, order_id: string, reason: string, created_at: string, updated_at: string, team_member_id: string, terminal_refund_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/refunds")
  let body = {idempotency_key: $idempotency_key, amount_money: $amount_money, app_fee_money: $app_fee_money, app_fee_allocations: $app_fee_allocations, payment_id: $payment_id, destination_id: $destination_id, unlinked: $unlinked, location_id: $location_id, customer_id: $customer_id, reason: $reason, payment_version_token: $payment_version_token, team_member_id: $team_member_id, cash_details: $cash_details, external_details: $external_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetPaymentRefund
#
# GET /v2/refunds/{refund_id}
# operationId: GetPaymentRefund
export def "refunds GetPaymentRefund" [
  refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<id: string, status: string, location_id: string, unlinked: bool, destination_type: string, destination_details: record<card_details: record, cash_details: record, external_details: record>, amount_money: record<amount: int, currency: string>, app_fee_money: record<amount: int, currency: string>, app_fee_allocations: list<any>, processing_fee: list<record>, payment_id: string, order_id: string, reason: string, created_at: string, updated_at: string, team_member_id: string, terminal_refund_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/refunds/($refund_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListSites
#
# GET /v2/sites
# operationId: ListSites
export def "sites ListSites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, sites: table<id: string, site_title: string, domain: string, is_published: bool, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/sites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeleteSnippet
#
# DELETE /v2/sites/{site_id}/snippet
# operationId: DeleteSnippet
export def "sites-snippet DeleteSnippet" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/sites/($site_id)/snippet")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveSnippet
#
# GET /v2/sites/{site_id}/snippet
# operationId: RetrieveSnippet
export def "sites-snippet RetrieveSnippet" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, snippet: record<id: string, site_id: string, content: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/sites/($site_id)/snippet")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpsertSnippet
#
# POST /v2/sites/{site_id}/snippet
# operationId: UpsertSnippet
# --snippet shape: {content: string}
export def "sites-snippet UpsertSnippet" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  snippet: record # Represents the snippet that is added to a Square Online site. The snippet code is injected into the `head` element of all pages on the site, except for checkout pages. — shape: {content: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, snippet: record<id: string, site_id: string, content: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/sites/($site_id)/snippet")
  let body = {snippet: $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateSubscription
#
# POST /v2/subscriptions
# operationId: CreateSubscription
# --price_override_money shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
# --source shape: {name?: string}
# --phases item shape: {uid?: string, ordinal?: int, order_template_id?: string, plan_phase_uid?: string}
export def "subscriptions CreateSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string that identifies this `CreateSubscription` request. If you do not provide a unique string (or provide an empty string as the value), the endpoint treats each request as independent.  For more information, see [Idempotency keys](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
  location_id: string # The ID of the location the subscription is associated with.
  --plan-variation-id: string # The ID of the [subscription plan variation](https://developer.squareup.com/docs/subscriptions-api/plans-and-variations#plan-variations) created using the Catalog API.
  customer_id: string # The ID of the [customer](entity:Customer) subscribing to the subscription plan variation.
  --start-date: string # The `YYYY-MM-DD`-formatted date to start the subscription.  If it is unspecified, the subscription starts immediately.
  --canceled-date: string # The `YYYY-MM-DD`-formatted date when the newly created subscription is scheduled for cancellation.   This date overrides the cancellation date set in the plan variation configuration. If the cancellation date is earlier than the end date of a subscription cycle, the subscription stops at the canceled date and the subscriber is sent a prorated invoice at the beginning of the canceled cycle.   When the subscription plan of the newly created subscription has a fixed number of cycles and the `canceled_date` occurs before the subscription plan completes, the specified `canceled_date` sets the date when the subscription stops through the end of the last cycle.
  --tax-percentage: string # The tax to add when billing the subscription. The percentage is expressed in decimal form, using a `'.'` as the decimal separator and without a `'%'` sign. For example, a value of 7.5 corresponds to 7.5%.
  --price-override-money: record # Represents an amount of money. `Money` fields can be signed or unsigned. Fields that do not explicitly define whether they are signed or unsigned are considered unsigned and can only hold positive amounts. For signed fields, the sign of the value indicates the purpose of the money transfer. See [Working with Monetary Amounts](https://developer.squareup.com/docs/build-basics/working-with-monetary-amounts) for more information. — shape: {amount?: int, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SLE"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"XUS"}
  --card-id: string # The ID of the [subscriber's](entity:Customer) [card](entity:Card) to charge. If it is not specified, the subscriber receives an invoice via email with a link to pay for their subscription.
  --timezone: string # The timezone that is used in date calculations for the subscription. If unset, defaults to the location timezone. If a timezone is not configured for the location, defaults to "America/New_York". Format: the IANA Timezone Database identifier for the location timezone. For a list of time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
  --body-source: record # The origination details of the subscription. — shape: {name?: string}
  --monthly-billing-anchor-date: int # The day-of-the-month to change the billing date to.
  --phases: list # array of phases for this subscription — item shape: {uid?: string, ordinal?: int, order_template_id?: string, plan_phase_uid?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/subscriptions")
  let body = {idempotency_key: $idempotency_key, location_id: $location_id, plan_variation_id: $plan_variation_id, customer_id: $customer_id, start_date: $start_date, canceled_date: $canceled_date, tax_percentage: $tax_percentage, price_override_money: $price_override_money, card_id: $card_id, timezone: $timezone, source: $body_source, monthly_billing_anchor_date: $monthly_billing_anchor_date, phases: $phases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkSwapPlan
#
# POST /v2/subscriptions/bulk-swap-plan
# operationId: BulkSwapPlan
export def "subscriptions-bulk-swap-plan BulkSwapPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  new_plan_variation_id: string # The ID of the new subscription plan variation.  This field is required.
  old_plan_variation_id: string # The ID of the plan variation whose subscriptions should be swapped. Active subscriptions using this plan variation will be subscribed to the new plan variation on their next billing day.
  location_id: string # The ID of the location to associate with the swapped subscriptions.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, affected_subscriptions: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/subscriptions/bulk-swap-plan")
  let body = {new_plan_variation_id: $new_plan_variation_id, old_plan_variation_id: $old_plan_variation_id, location_id: $location_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchSubscriptions
#
# POST /v2/subscriptions/search
# operationId: SearchSubscriptions
# --query shape: {filter?: record}
export def "subscriptions-search SearchSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # When the total number of resulting subscriptions exceeds the limit of a paged response,  specify the cursor returned from a preceding response here to fetch the next set of results. If the cursor is unset, the response contains the last page of the results.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The upper limit on the number of subscriptions to return in a paged response.
  --body-query: record # Represents a query, consisting of specified query expressions, used to search for subscriptions. — shape: {filter?: record}
  --include: list # An option to include related information in the response.   The supported values are:   - `actions`: to include scheduled actions on the targeted subscriptions.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscriptions: table<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list, price_override_money: record, version: int, created_at: string, card_id: string, timezone: string, source: record, actions: list, monthly_billing_anchor_date: int, phases: list, completed_date: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/subscriptions/search")
  let body = {cursor: $cursor, limit: $limit, query: $body_query, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveSubscription
#
# GET /v2/subscriptions/{subscription_id}
# operationId: RetrieveSubscription
export def "subscriptions RetrieveSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # A query parameter to specify related information to be included in the response.   The supported query parameter values are:   - `actions`: to include scheduled actions on the targeted subscription.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateSubscription
#
# PUT /v2/subscriptions/{subscription_id}
# operationId: UpdateSubscription
# --subscription shape: {canceled_date?: string, status?: "PENDING"|"ACTIVE"|"CANCELED"|"DEACTIVATED"|"PAUSED"|"COMPLETED", tax_percentage?: string, price_override_money?: record, version?: int, card_id?: string, source?: record, actions?: list, completed_date?: string}
export def "subscriptions UpdateSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription: record # Represents a subscription purchased by a customer.  For more information, see [Manage Subscriptions](https://developer.squareup.com/docs/subscriptions-api/manage-subscriptions). — shape: {canceled_date?: string, status?: "PENDING"|"ACTIVE"|"CANCELED"|"DEACTIVATED"|"PAUSED"|"COMPLETED", tax_percentage?: string, price_override_money?: record, version?: int, card_id?: string, source?: record, actions?: list, completed_date?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)")
  let body = {subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteSubscriptionAction
#
# DELETE /v2/subscriptions/{subscription_id}/actions/{action_id}
# operationId: DeleteSubscriptionAction
export def "subscriptions-actions DeleteSubscriptionAction" [
  subscription_id: string
  action_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ChangeBillingAnchorDate
#
# POST /v2/subscriptions/{subscription_id}/billing-anchor
# operationId: ChangeBillingAnchorDate
export def "subscriptions-billing-anchor ChangeBillingAnchorDate" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --monthly-billing-anchor-date: int # The anchor day for the billing cycle. (nullable)
  --effective-date: string # The `YYYY-MM-DD`-formatted date when the scheduled `BILLING_ANCHOR_CHANGE` action takes place on the subscription.  When this date is unspecified or falls within the current billing cycle, the billing anchor date is changed immediately. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>, actions: table<id: string, type: string, effective_date: string, monthly_billing_anchor_date: int, phases: list, new_plan_variation_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)/billing-anchor")
  let body = {monthly_billing_anchor_date: $monthly_billing_anchor_date, effective_date: $effective_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CancelSubscription
#
# POST /v2/subscriptions/{subscription_id}/cancel
# operationId: CancelSubscription
export def "subscriptions-cancel CancelSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>, actions: table<id: string, type: string, effective_date: string, monthly_billing_anchor_date: int, phases: list, new_plan_variation_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListSubscriptionEvents
#
# GET /v2/subscriptions/{subscription_id}/events
# operationId: ListSubscriptionEvents
export def "subscriptions-events ListSubscriptionEvents" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # When the total number of resulting subscription events exceeds the limit of a paged response,  specify the cursor returned from a preceding response here to fetch the next set of results. If the cursor is unset, the response contains the last page of the results.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --limit: int # The upper limit on the number of subscription events to return in a paged response.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription_events: table<id: string, subscription_event_type: string, effective_date: string, monthly_billing_anchor_date: int, info: record, phases: list, plan_variation_id: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PauseSubscription
#
# POST /v2/subscriptions/{subscription_id}/pause
# operationId: PauseSubscription
export def "subscriptions-pause PauseSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pause-effective-date: string # The `YYYY-MM-DD`-formatted date when the scheduled `PAUSE` action takes place on the subscription.  When this date is unspecified or falls within the current billing cycle, the subscription is paused on the starting date of the next billing cycle. (nullable)
  --pause-cycle-duration: int # The number of billing cycles the subscription will be paused before it is reactivated.   When this is set, a `RESUME` action is also scheduled to take place on the subscription at  the end of the specified pause cycle duration. In this case, neither `resume_effective_date`  nor `resume_change_timing` may be specified. (nullable, format: int64)
  --resume-effective-date: string # The date when the subscription is reactivated by a scheduled `RESUME` action.  This date must be at least one billing cycle ahead of `pause_effective_date`. (nullable)
  --resume-change-timing: string@resume-change-timing-completer # Supported timings when a pending change, as an action, takes place to a subscription.
  --pause-reason: string # The user-provided reason to pause the subscription. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>, actions: table<id: string, type: string, effective_date: string, monthly_billing_anchor_date: int, phases: list, new_plan_variation_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)/pause")
  let body = {pause_effective_date: $pause_effective_date, pause_cycle_duration: $pause_cycle_duration, resume_effective_date: $resume_effective_date, resume_change_timing: $resume_change_timing, pause_reason: $pause_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ResumeSubscription
#
# POST /v2/subscriptions/{subscription_id}/resume
# operationId: ResumeSubscription
export def "subscriptions-resume ResumeSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resume-effective-date: string # The `YYYY-MM-DD`-formatted date when the subscription reactivated. (nullable)
  --resume-change-timing: string@resume-change-timing-completer # Supported timings when a pending change, as an action, takes place to a subscription.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>, actions: table<id: string, type: string, effective_date: string, monthly_billing_anchor_date: int, phases: list, new_plan_variation_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)/resume")
  let body = {resume_effective_date: $resume_effective_date, resume_change_timing: $resume_change_timing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SwapPlan
#
# POST /v2/subscriptions/{subscription_id}/swap-plan
# operationId: SwapPlan
# --phases item shape: {ordinal: int, order_template_id?: string}
export def "subscriptions-swap-plan SwapPlan" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --new-plan-variation-id: string # The ID of the new subscription plan variation.  This field is required. (nullable)
  --phases: list # A list of PhaseInputs, to pass phase-specific information used in the swap. (nullable) — item shape: {ordinal: int, order_template_id?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, location_id: string, plan_variation_id: string, customer_id: string, start_date: string, canceled_date: string, charged_through_date: string, status: string, tax_percentage: string, invoice_ids: list<string>, price_override_money: record<amount: int, currency: string>, version: int, created_at: string, card_id: string, timezone: string, source: record<name: string>, actions: list<record>, monthly_billing_anchor_date: int, phases: list<record>, completed_date: string>, actions: table<id: string, type: string, effective_date: string, monthly_billing_anchor_date: int, phases: list, new_plan_variation_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscriptions/($subscription_id)/swap-plan")
  let body = {new_plan_variation_id: $new_plan_variation_id, phases: $phases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateTeamMember
#
# POST /v2/team-members
# operationId: CreateTeamMember
# --team_member shape: {reference_id?: string, status?: "ACTIVE"|"INACTIVE", given_name?: string, family_name?: string, email_address?: string, phone_number?: string, assigned_locations?: record, wage_setting?: record}
export def "team-members CreateTeamMember" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string that identifies this `CreateTeamMember` request. Keys can be any valid string, but must be unique for every request. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).  The minimum length is 1 and the maximum length is 45.
  --team-member: record # A record representing an individual team member for a business. — shape: {reference_id?: string, status?: "ACTIVE"|"INACTIVE", given_name?: string, family_name?: string, email_address?: string, phone_number?: string, assigned_locations?: record, wage_setting?: record}
]: any -> record<team_member: record<id: string, reference_id: string, is_owner: bool, status: string, given_name: string, family_name: string, email_address: string, phone_number: string, created_at: string, updated_at: string, assigned_locations: record<assignment_type: string, location_ids: list>, wage_setting: record<team_member_id: string, job_assignments: list, is_overtime_exempt: bool, version: int, created_at: string, updated_at: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members")
  let body = {idempotency_key: $idempotency_key, team_member: $team_member} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkCreateTeamMembers
#
# POST /v2/team-members/bulk-create
# operationId: BulkCreateTeamMembers
export def "team-members-bulk-create BulkCreateTeamMembers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  team_members: record # The data used to create the `TeamMember` objects. Each key is the `idempotency_key` that maps to the `CreateTeamMemberRequest`. The maximum number of create objects is 25.  If you include a team member's `wage_setting`, you must provide `job_id` for each job assignment. To get job IDs, call [ListJobs](api-endpoint:Team-ListJobs).
]: any -> record<team_members: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members/bulk-create")
  let body = {team_members: $team_members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkUpdateTeamMembers
#
# POST /v2/team-members/bulk-update
# operationId: BulkUpdateTeamMembers
export def "team-members-bulk-update BulkUpdateTeamMembers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  team_members: record # The data used to update the `TeamMember` objects. Each key is the `team_member_id` that maps to the `UpdateTeamMemberRequest`. The maximum number of update objects is 25.  For each team member, include the fields to add, change, or clear. Fields can be cleared using a null value. To update `wage_setting.job_assignments`, you must provide the complete list of job assignments. If needed, call [ListJobs](api-endpoint:Team-ListJobs) to get the required `job_id` values.
]: any -> record<team_members: record, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members/bulk-update")
  let body = {team_members: $team_members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListJobs
#
# GET /v2/team-members/jobs
# operationId: ListJobs
export def "team-members-jobs ListJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The pagination cursor returned by the previous call to this endpoint. Provide this cursor to retrieve the next page of results for your original request. For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
]: nothing -> record<jobs: table<id: string, title: string, is_tip_eligible: bool, created_at: string, updated_at: string, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/team-members/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateJob
#
# POST /v2/team-members/jobs
# operationId: CreateJob
# --job shape: {id?: string, title?: string, is_tip_eligible?: bool, version?: int}
export def "team-members-jobs CreateJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  job: record # Represents a job that can be assigned to [team members](entity:TeamMember). This object defines the job's title and tip eligibility. Compensation is defined in a [job assignment](entity:JobAssignment) in a team member's wage setting. — shape: {id?: string, title?: string, is_tip_eligible?: bool, version?: int}
  idempotency_key: string # A unique identifier for the `CreateJob` request. Keys can be any valid string, but must be unique for each request. For more information, see [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency).
]: any -> record<job: record<id: string, title: string, is_tip_eligible: bool, created_at: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members/jobs")
  let body = {job: $job, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveJob
#
# GET /v2/team-members/jobs/{job_id}
# operationId: RetrieveJob
export def "team-members-jobs RetrieveJob" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job: record<id: string, title: string, is_tip_eligible: bool, created_at: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/team-members/jobs/($job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateJob
#
# PUT /v2/team-members/jobs/{job_id}
# operationId: UpdateJob
# --job shape: {id?: string, title?: string, is_tip_eligible?: bool, version?: int}
export def "team-members-jobs UpdateJob" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  job: record # Represents a job that can be assigned to [team members](entity:TeamMember). This object defines the job's title and tip eligibility. Compensation is defined in a [job assignment](entity:JobAssignment) in a team member's wage setting. — shape: {id?: string, title?: string, is_tip_eligible?: bool, version?: int}
]: any -> record<job: record<id: string, title: string, is_tip_eligible: bool, created_at: string, updated_at: string, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/team-members/jobs/($job_id)")
  let body = {job: $job} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchTeamMembers
#
# POST /v2/team-members/search
# operationId: SearchTeamMembers
# --query shape: {filter?: record}
export def "team-members-search SearchTeamMembers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # Represents the parameters in a search for `TeamMember` objects. — shape: {filter?: record}
  --limit: int # The maximum number of `TeamMember` objects in a page (100 by default).
  --cursor: string # The opaque cursor for fetching the next page. For more information, see [pagination](https://developer.squareup.com/docs/working-with-apis/pagination).
]: any -> record<team_members: table<id: string, reference_id: string, is_owner: bool, status: string, given_name: string, family_name: string, email_address: string, phone_number: string, created_at: string, updated_at: string, assigned_locations: record, wage_setting: record>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/team-members/search")
  let body = {query: $body_query, limit: $limit, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveTeamMember
#
# GET /v2/team-members/{team_member_id}
# operationId: RetrieveTeamMember
export def "team-members RetrieveTeamMember" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<team_member: record<id: string, reference_id: string, is_owner: bool, status: string, given_name: string, family_name: string, email_address: string, phone_number: string, created_at: string, updated_at: string, assigned_locations: record<assignment_type: string, location_ids: list>, wage_setting: record<team_member_id: string, job_assignments: list, is_overtime_exempt: bool, version: int, created_at: string, updated_at: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/team-members/($team_member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateTeamMember
#
# PUT /v2/team-members/{team_member_id}
# operationId: UpdateTeamMember
# --team_member shape: {reference_id?: string, status?: "ACTIVE"|"INACTIVE", given_name?: string, family_name?: string, email_address?: string, phone_number?: string, assigned_locations?: record, wage_setting?: record}
export def "team-members UpdateTeamMember" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-member: record # A record representing an individual team member for a business. — shape: {reference_id?: string, status?: "ACTIVE"|"INACTIVE", given_name?: string, family_name?: string, email_address?: string, phone_number?: string, assigned_locations?: record, wage_setting?: record}
]: any -> record<team_member: record<id: string, reference_id: string, is_owner: bool, status: string, given_name: string, family_name: string, email_address: string, phone_number: string, created_at: string, updated_at: string, assigned_locations: record<assignment_type: string, location_ids: list>, wage_setting: record<team_member_id: string, job_assignments: list, is_overtime_exempt: bool, version: int, created_at: string, updated_at: string>>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/team-members/($team_member_id)")
  let body = {team_member: $team_member} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveWageSetting
#
# GET /v2/team-members/{team_member_id}/wage-setting
# operationId: RetrieveWageSetting
export def "team-members-wage-setting RetrieveWageSetting" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<wage_setting: record<team_member_id: string, job_assignments: list<record>, is_overtime_exempt: bool, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/team-members/($team_member_id)/wage-setting")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateWageSetting
#
# PUT /v2/team-members/{team_member_id}/wage-setting
# operationId: UpdateWageSetting
# --wage_setting shape: {team_member_id?: string, job_assignments?: list, is_overtime_exempt?: bool, version?: int}
export def "team-members-wage-setting UpdateWageSetting" [
  team_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  wage_setting: record # Represents information about the overtime exemption status, job assignments, and compensation for a [team member](entity:TeamMember). — shape: {team_member_id?: string, job_assignments?: list, is_overtime_exempt?: bool, version?: int}
]: any -> record<wage_setting: record<team_member_id: string, job_assignments: list<record>, is_overtime_exempt: bool, version: int, created_at: string, updated_at: string>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/team-members/($team_member_id)/wage-setting")
  let body = {wage_setting: $wage_setting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateTerminalAction
#
# POST /v2/terminals/actions
# operationId: CreateTerminalAction
# --action shape: {device_id?: string, deadline_duration?: string, cancel_reason?: "BUYER_CANCELED"|"SELLER_CANCELED"|"TIMED_OUT", type?: "QR_CODE"|"PING"|"SAVE_CARD"|"SIGNATURE"|"CONFIRMATION"|"RECEIPT"|"DATA_COLLECTION"|"SELECT", qr_code_options?: record, save_card_options?: record, signature_options?: record, confirmation_options?: record, receipt_options?: record, data_collection_options?: record, select_options?: record, device_metadata?: record, await_next_action?: bool, await_next_action_duration?: string}
export def "terminals-actions CreateTerminalAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this `CreateAction` request. Keys can be any valid string but must be unique for every `CreateAction` request.  See [Idempotency keys](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) for more information.
  action: record # Represents an action processed by the Square Terminal. — shape: {device_id?: string, deadline_duration?: string, cancel_reason?: "BUYER_CANCELED"|"SELLER_CANCELED"|"TIMED_OUT", type?: "QR_CODE"|"PING"|"SAVE_CARD"|"SIGNATURE"|"CONFIRMATION"|"RECEIPT"|"DATA_COLLECTION"|"SELECT", qr_code_options?: record, save_card_options?: record, signature_options?: record, confirmation_options?: record, receipt_options?: record, data_collection_options?: record, select_options?: record, device_metadata?: record, await_next_action?: bool, await_next_action_duration?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, action: record<id: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string, type: string, qr_code_options: record<title: string, body: string, barcode_contents: string>, save_card_options: record<customer_id: string, card_id: string, reference_id: string>, signature_options: record<title: string, body: string, signature: list>, confirmation_options: record<title: string, body: string, agree_button_text: string, disagree_button_text: string, decision: record>, receipt_options: record<payment_id: string, print_only: bool, is_duplicate: bool>, data_collection_options: record<title: string, body: string, input_type: string, collected_data: record>, select_options: record<title: string, body: string, options: list, selected_option: record>, device_metadata: record<battery_percentage: string, charging_state: string, location_id: string, merchant_id: string, network_connection_type: string, payment_region: string, serial_number: string, os_version: string, app_version: string, wifi_network_name: string, wifi_network_strength: string, ip_address: string>, await_next_action: bool, await_next_action_duration: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/actions")
  let body = {idempotency_key: $idempotency_key, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchTerminalActions
#
# POST /v2/terminals/actions/search
# operationId: SearchTerminalActions
# --query shape: {filter?: record, sort?: record}
export def "terminals-actions-search SearchTerminalActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # e.g. {include: [CUSTOMER], limit: 2, query: {filter: {status: COMPLETED}}} — shape: {filter?: record, sort?: record}
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query. See [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination) for more information.
  --limit: int # Limit the number of results returned for a single request.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, action: table<id: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string, type: string, qr_code_options: record, save_card_options: record, signature_options: record, confirmation_options: record, receipt_options: record, data_collection_options: record, select_options: record, device_metadata: record, await_next_action: bool, await_next_action_duration: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/actions/search")
  let body = {query: $body_query, cursor: $cursor, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetTerminalAction
#
# GET /v2/terminals/actions/{action_id}
# operationId: GetTerminalAction
export def "terminals-actions GetTerminalAction" [
  action_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, action: record<id: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string, type: string, qr_code_options: record<title: string, body: string, barcode_contents: string>, save_card_options: record<customer_id: string, card_id: string, reference_id: string>, signature_options: record<title: string, body: string, signature: list>, confirmation_options: record<title: string, body: string, agree_button_text: string, disagree_button_text: string, decision: record>, receipt_options: record<payment_id: string, print_only: bool, is_duplicate: bool>, data_collection_options: record<title: string, body: string, input_type: string, collected_data: record>, select_options: record<title: string, body: string, options: list, selected_option: record>, device_metadata: record<battery_percentage: string, charging_state: string, location_id: string, merchant_id: string, network_connection_type: string, payment_region: string, serial_number: string, os_version: string, app_version: string, wifi_network_name: string, wifi_network_strength: string, ip_address: string>, await_next_action: bool, await_next_action_duration: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CancelTerminalAction
#
# POST /v2/terminals/actions/{action_id}/cancel
# operationId: CancelTerminalAction
export def "terminals-actions-cancel CancelTerminalAction" [
  action_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, action: record<id: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string, type: string, qr_code_options: record<title: string, body: string, barcode_contents: string>, save_card_options: record<customer_id: string, card_id: string, reference_id: string>, signature_options: record<title: string, body: string, signature: list>, confirmation_options: record<title: string, body: string, agree_button_text: string, disagree_button_text: string, decision: record>, receipt_options: record<payment_id: string, print_only: bool, is_duplicate: bool>, data_collection_options: record<title: string, body: string, input_type: string, collected_data: record>, select_options: record<title: string, body: string, options: list, selected_option: record>, device_metadata: record<battery_percentage: string, charging_state: string, location_id: string, merchant_id: string, network_connection_type: string, payment_region: string, serial_number: string, os_version: string, app_version: string, wifi_network_name: string, wifi_network_strength: string, ip_address: string>, await_next_action: bool, await_next_action_duration: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/actions/($action_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DismissTerminalAction
#
# POST /v2/terminals/actions/{action_id}/dismiss
# operationId: DismissTerminalAction
export def "terminals-actions-dismiss DismissTerminalAction" [
  action_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, action: record<id: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string, type: string, qr_code_options: record<title: string, body: string, barcode_contents: string>, save_card_options: record<customer_id: string, card_id: string, reference_id: string>, signature_options: record<title: string, body: string, signature: list>, confirmation_options: record<title: string, body: string, agree_button_text: string, disagree_button_text: string, decision: record>, receipt_options: record<payment_id: string, print_only: bool, is_duplicate: bool>, data_collection_options: record<title: string, body: string, input_type: string, collected_data: record>, select_options: record<title: string, body: string, options: list, selected_option: record>, device_metadata: record<battery_percentage: string, charging_state: string, location_id: string, merchant_id: string, network_connection_type: string, payment_region: string, serial_number: string, os_version: string, app_version: string, wifi_network_name: string, wifi_network_strength: string, ip_address: string>, await_next_action: bool, await_next_action_duration: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/actions/($action_id)/dismiss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateTerminalCheckout
#
# POST /v2/terminals/checkouts
# operationId: CreateTerminalCheckout
# --checkout shape: {amount_money: record, reference_id?: string, note?: string, order_id?: string, payment_options?: record, device_options: record, deadline_duration?: string, cancel_reason?: "BUYER_CANCELED"|"SELLER_CANCELED"|"TIMED_OUT", payment_type?: "CARD_PRESENT"|"MANUAL_CARD_ENTRY"|"FELICA_ID"|"FELICA_QUICPAY"|"FELICA_TRANSPORTATION_GROUP"|"FELICA_ALL"|"PAYPAY"|"QR_CODE", team_member_id?: string, customer_id?: string, app_fee_money?: record, statement_description_identifier?: string, tip_money?: record}
export def "terminals-checkouts CreateTerminalCheckout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this `CreateCheckout` request. Keys can be any valid string but must be unique for every `CreateCheckout` request.  See [Idempotency keys](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) for more information.
  checkout: record # Represents a checkout processed by the Square Terminal. — shape: {amount_money: record, reference_id?: string, note?: string, order_id?: string, payment_options?: record, device_options: record, deadline_duration?: string, cancel_reason?: "BUYER_CANCELED"|"SELLER_CANCELED"|"TIMED_OUT", payment_type?: "CARD_PRESENT"|"MANUAL_CARD_ENTRY"|"FELICA_ID"|"FELICA_QUICPAY"|"FELICA_TRANSPORTATION_GROUP"|"FELICA_ALL"|"PAYPAY"|"QR_CODE", team_member_id?: string, customer_id?: string, app_fee_money?: record, statement_description_identifier?: string, tip_money?: record}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, checkout: record<id: string, amount_money: record<amount: int, currency: string>, reference_id: string, note: string, order_id: string, payment_options: record<autocomplete: bool, delay_duration: string, accept_partial_authorization: bool, delay_action: string>, device_options: record<device_id: string, skip_receipt_screen: bool, collect_signature: bool, tip_settings: record, show_itemized_cart: bool, allow_auto_card_surcharge: bool>, deadline_duration: string, status: string, cancel_reason: string, payment_ids: list<string>, created_at: string, updated_at: string, app_id: string, location_id: string, payment_type: string, team_member_id: string, customer_id: string, app_fee_money: record<amount: int, currency: string>, statement_description_identifier: string, tip_money: record<amount: int, currency: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/checkouts")
  let body = {idempotency_key: $idempotency_key, checkout: $checkout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchTerminalCheckouts
#
# POST /v2/terminals/checkouts/search
# operationId: SearchTerminalCheckouts
# --query shape: {filter?: record, sort?: record}
export def "terminals-checkouts-search SearchTerminalCheckouts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # shape: {filter?: record, sort?: record}
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query. See [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination) for more information.
  --limit: int # Limits the number of results returned for a single request.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, checkouts: table<id: string, amount_money: record, reference_id: string, note: string, order_id: string, payment_options: record, device_options: record, deadline_duration: string, status: string, cancel_reason: string, payment_ids: list, created_at: string, updated_at: string, app_id: string, location_id: string, payment_type: string, team_member_id: string, customer_id: string, app_fee_money: record, statement_description_identifier: string, tip_money: record>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/checkouts/search")
  let body = {query: $body_query, cursor: $cursor, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetTerminalCheckout
#
# GET /v2/terminals/checkouts/{checkout_id}
# operationId: GetTerminalCheckout
export def "terminals-checkouts GetTerminalCheckout" [
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, checkout: record<id: string, amount_money: record<amount: int, currency: string>, reference_id: string, note: string, order_id: string, payment_options: record<autocomplete: bool, delay_duration: string, accept_partial_authorization: bool, delay_action: string>, device_options: record<device_id: string, skip_receipt_screen: bool, collect_signature: bool, tip_settings: record, show_itemized_cart: bool, allow_auto_card_surcharge: bool>, deadline_duration: string, status: string, cancel_reason: string, payment_ids: list<string>, created_at: string, updated_at: string, app_id: string, location_id: string, payment_type: string, team_member_id: string, customer_id: string, app_fee_money: record<amount: int, currency: string>, statement_description_identifier: string, tip_money: record<amount: int, currency: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/checkouts/($checkout_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CancelTerminalCheckout
#
# POST /v2/terminals/checkouts/{checkout_id}/cancel
# operationId: CancelTerminalCheckout
export def "terminals-checkouts-cancel CancelTerminalCheckout" [
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, checkout: record<id: string, amount_money: record<amount: int, currency: string>, reference_id: string, note: string, order_id: string, payment_options: record<autocomplete: bool, delay_duration: string, accept_partial_authorization: bool, delay_action: string>, device_options: record<device_id: string, skip_receipt_screen: bool, collect_signature: bool, tip_settings: record, show_itemized_cart: bool, allow_auto_card_surcharge: bool>, deadline_duration: string, status: string, cancel_reason: string, payment_ids: list<string>, created_at: string, updated_at: string, app_id: string, location_id: string, payment_type: string, team_member_id: string, customer_id: string, app_fee_money: record<amount: int, currency: string>, statement_description_identifier: string, tip_money: record<amount: int, currency: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/checkouts/($checkout_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DismissTerminalCheckout
#
# POST /v2/terminals/checkouts/{checkout_id}/dismiss
# operationId: DismissTerminalCheckout
export def "terminals-checkouts-dismiss DismissTerminalCheckout" [
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, checkout: record<id: string, amount_money: record<amount: int, currency: string>, reference_id: string, note: string, order_id: string, payment_options: record<autocomplete: bool, delay_duration: string, accept_partial_authorization: bool, delay_action: string>, device_options: record<device_id: string, skip_receipt_screen: bool, collect_signature: bool, tip_settings: record, show_itemized_cart: bool, allow_auto_card_surcharge: bool>, deadline_duration: string, status: string, cancel_reason: string, payment_ids: list<string>, created_at: string, updated_at: string, app_id: string, location_id: string, payment_type: string, team_member_id: string, customer_id: string, app_fee_money: record<amount: int, currency: string>, statement_description_identifier: string, tip_money: record<amount: int, currency: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/checkouts/($checkout_id)/dismiss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateTerminalRefund
#
# POST /v2/terminals/refunds
# operationId: CreateTerminalRefund
# --refund shape: {payment_id: string, amount_money: record, reason: string, device_id: string, deadline_duration?: string, cancel_reason?: "BUYER_CANCELED"|"SELLER_CANCELED"|"TIMED_OUT"}
export def "terminals-refunds CreateTerminalRefund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this `CreateRefund` request. Keys can be any valid string but must be unique for every `CreateRefund` request.  See [Idempotency keys](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) for more information.
  --refund: record # Represents a payment refund processed by the Square Terminal. Only supports Interac (Canadian debit network) payment refunds. — shape: {payment_id: string, amount_money: record, reason: string, device_id: string, deadline_duration?: string, cancel_reason?: "BUYER_CANCELED"|"SELLER_CANCELED"|"TIMED_OUT"}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<id: string, refund_id: string, payment_id: string, order_id: string, amount_money: record<amount: int, currency: string>, reason: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/refunds")
  let body = {idempotency_key: $idempotency_key, refund: $refund} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchTerminalRefunds
#
# POST /v2/terminals/refunds/search
# operationId: SearchTerminalRefunds
# --query shape: {filter?: record, sort?: record}
export def "terminals-refunds-search SearchTerminalRefunds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # shape: {filter?: record, sort?: record}
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this cursor to retrieve the next set of results for the original query.
  --limit: int # Limits the number of results returned for a single request.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, refunds: table<id: string, refund_id: string, payment_id: string, order_id: string, amount_money: record, reason: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/terminals/refunds/search")
  let body = {query: $body_query, cursor: $cursor, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetTerminalRefund
#
# GET /v2/terminals/refunds/{terminal_refund_id}
# operationId: GetTerminalRefund
export def "terminals-refunds GetTerminalRefund" [
  terminal_refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<id: string, refund_id: string, payment_id: string, order_id: string, amount_money: record<amount: int, currency: string>, reason: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/refunds/($terminal_refund_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CancelTerminalRefund
#
# POST /v2/terminals/refunds/{terminal_refund_id}/cancel
# operationId: CancelTerminalRefund
export def "terminals-refunds-cancel CancelTerminalRefund" [
  terminal_refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<id: string, refund_id: string, payment_id: string, order_id: string, amount_money: record<amount: int, currency: string>, reason: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/refunds/($terminal_refund_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DismissTerminalRefund
#
# POST /v2/terminals/refunds/{terminal_refund_id}/dismiss
# operationId: DismissTerminalRefund
export def "terminals-refunds-dismiss DismissTerminalRefund" [
  terminal_refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, refund: record<id: string, refund_id: string, payment_id: string, order_id: string, amount_money: record<amount: int, currency: string>, reason: string, device_id: string, deadline_duration: string, status: string, cancel_reason: string, created_at: string, updated_at: string, app_id: string, location_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/terminals/refunds/($terminal_refund_id)/dismiss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateTransferOrder
#
# POST /v2/transfer-orders
# operationId: CreateTransferOrder
# --transfer_order shape: {source_location_id: string, destination_location_id: string, expected_at?: string, notes?: string, tracking_number?: string, created_by_team_member_id?: string, line_items?: list}
export def "transfer-orders CreateTransferOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this CreateTransferOrder request. Keys can be any valid string but must be unique for every CreateTransferOrder request.
  transfer_order: record # Data for creating a new transfer order to move [CatalogItemVariation](entity:CatalogItemVariation)s between [Location](entity:Location)s. Used with the [CreateTransferOrder](api-endpoint:TransferOrders-CreateTransferOrder) endpoint. — shape: {source_location_id: string, destination_location_id: string, expected_at?: string, notes?: string, tracking_number?: string, created_by_team_member_id?: string, line_items?: list}
]: any -> record<transfer_order: record<id: string, source_location_id: string, destination_location_id: string, status: string, created_at: string, updated_at: string, expected_at: string, completed_at: string, notes: string, tracking_number: string, created_by_team_member_id: string, line_items: list<record>, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/transfer-orders")
  let body = {idempotency_key: $idempotency_key, transfer_order: $transfer_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchTransferOrders
#
# POST /v2/transfer-orders/search
# operationId: SearchTransferOrders
# --query shape: {filter?: record, sort?: record}
export def "transfer-orders-search SearchTransferOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: record # Query parameters for searching transfer orders — shape: {filter?: record, sort?: record}
  --cursor: string # Pagination cursor from a previous search response
  --limit: int # Maximum number of results to return (1-100)
]: any -> record<transfer_orders: table<id: string, source_location_id: string, destination_location_id: string, status: string, created_at: string, updated_at: string, expected_at: string, completed_at: string, notes: string, tracking_number: string, created_by_team_member_id: string, line_items: list, version: int>, cursor: string, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/transfer-orders/search")
  let body = {query: $body_query, cursor: $cursor, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteTransferOrder
#
# DELETE /v2/transfer-orders/{transfer_order_id}
# operationId: DeleteTransferOrder
export def "transfer-orders DeleteTransferOrder" [
  transfer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # Version for optimistic concurrency (format: int64)
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/transfer-orders/($transfer_order_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveTransferOrder
#
# GET /v2/transfer-orders/{transfer_order_id}
# operationId: RetrieveTransferOrder
export def "transfer-orders RetrieveTransferOrder" [
  transfer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<transfer_order: record<id: string, source_location_id: string, destination_location_id: string, status: string, created_at: string, updated_at: string, expected_at: string, completed_at: string, notes: string, tracking_number: string, created_by_team_member_id: string, line_items: list<record>, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transfer-orders/($transfer_order_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateTransferOrder
#
# PUT /v2/transfer-orders/{transfer_order_id}
# operationId: UpdateTransferOrder
# --transfer_order shape: {source_location_id?: string, destination_location_id?: string, expected_at?: string, notes?: string, tracking_number?: string, line_items?: list}
export def "transfer-orders UpdateTransferOrder" [
  transfer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this UpdateTransferOrder request. Keys must contain only alphanumeric characters, dashes and underscores
  transfer_order: record # Data model for updating a transfer order. All fields are optional. — shape: {source_location_id?: string, destination_location_id?: string, expected_at?: string, notes?: string, tracking_number?: string, line_items?: list}
  --version: int # Version for optimistic concurrency (format: int64)
]: any -> record<transfer_order: record<id: string, source_location_id: string, destination_location_id: string, status: string, created_at: string, updated_at: string, expected_at: string, completed_at: string, notes: string, tracking_number: string, created_by_team_member_id: string, line_items: list<record>, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transfer-orders/($transfer_order_id)")
  let body = {idempotency_key: $idempotency_key, transfer_order: $transfer_order, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CancelTransferOrder
#
# POST /v2/transfer-orders/{transfer_order_id}/cancel
# operationId: CancelTransferOrder
export def "transfer-orders-cancel CancelTransferOrder" [
  transfer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this UpdateTransferOrder request. Keys can be any valid string but must be unique for every UpdateTransferOrder request.
  --version: int # Version for optimistic concurrency (format: int64)
]: any -> record<transfer_order: record<id: string, source_location_id: string, destination_location_id: string, status: string, created_at: string, updated_at: string, expected_at: string, completed_at: string, notes: string, tracking_number: string, created_by_team_member_id: string, line_items: list<record>, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transfer-orders/($transfer_order_id)/cancel")
  let body = {idempotency_key: $idempotency_key, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ReceiveTransferOrder
#
# POST /v2/transfer-orders/{transfer_order_id}/receive
# operationId: ReceiveTransferOrder
# --receipt shape: {line_items?: list}
export def "transfer-orders-receive ReceiveTransferOrder" [
  transfer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique key to make this request idempotent
  receipt: record # The goods receipt details for a transfer order. This object represents a single receipt of goods against a transfer order, tracking:  - Which [CatalogItemVariation](entity:CatalogItemVariation)s were received - Quantities received in good condition - Quantities damaged during transit/handling - Quantities canceled during receipt  Multiple goods receipts can be created for a single transfer order to handle: - Partial deliveries - Multiple shipments - Split receipts across different dates - Cancellations of specific quantities  Each receipt automatically: - Updates the transfer order status - Adjusts received quantities - Updates inventory levels at both source and destination [Location](entity:Location)s — shape: {line_items?: list}
  --version: int # Version for optimistic concurrency (format: int64)
]: any -> record<transfer_order: record<id: string, source_location_id: string, destination_location_id: string, status: string, created_at: string, updated_at: string, expected_at: string, completed_at: string, notes: string, tracking_number: string, created_by_team_member_id: string, line_items: list<record>, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transfer-orders/($transfer_order_id)/receive")
  let body = {idempotency_key: $idempotency_key, receipt: $receipt, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# StartTransferOrder
#
# POST /v2/transfer-orders/{transfer_order_id}/start
# operationId: StartTransferOrder
export def "transfer-orders-start StartTransferOrder" [
  transfer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A unique string that identifies this UpdateTransferOrder request. Keys can be any valid string but must be unique for every UpdateTransferOrder request.
  --version: int # Version for optimistic concurrency (format: int64)
]: any -> record<transfer_order: record<id: string, source_location_id: string, destination_location_id: string, status: string, created_at: string, updated_at: string, expected_at: string, completed_at: string, notes: string, tracking_number: string, created_by_team_member_id: string, line_items: list<record>, version: int>, errors: table<category: string, code: string, detail: string, field: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transfer-orders/($transfer_order_id)/start")
  let body = {idempotency_key: $idempotency_key, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkCreateVendors
#
# POST /v2/vendors/bulk-create
# operationId: BulkCreateVendors
export def "vendors-bulk-create BulkCreateVendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  vendors: record # Specifies a set of new [Vendor](entity:Vendor) objects as represented by a collection of idempotency-key/`Vendor`-object pairs.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vendors/bulk-create")
  let body = {vendors: $vendors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkRetrieveVendors
#
# POST /v2/vendors/bulk-retrieve
# operationId: BulkRetrieveVendors
export def "vendors-bulk-retrieve BulkRetrieveVendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vendor-ids: list # IDs of the [Vendor](entity:Vendor) objects to retrieve. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vendors/bulk-retrieve")
  let body = {vendor_ids: $vendor_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# BulkUpdateVendors
#
# PUT /v2/vendors/bulk-update
# operationId: BulkUpdateVendors
export def "vendors-bulk-update BulkUpdateVendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  vendors: record # A set of [UpdateVendorRequest](entity:UpdateVendorRequest) objects encapsulating to-be-updated [Vendor](entity:Vendor) objects. The set is represented by  a collection of `Vendor`-ID/`UpdateVendorRequest`-object pairs.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vendors/bulk-update")
  let body = {vendors: $vendors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# CreateVendor
#
# POST /v2/vendors/create
# operationId: CreateVendor
# --vendor shape: {id?: string, name?: string, address?: record, contacts?: list, account_number?: string, note?: string, version?: int, status?: "ACTIVE"|"INACTIVE"}
export def "vendors-create CreateVendor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idempotency_key: string # A client-supplied, universally unique identifier (UUID) to make this [CreateVendor](api-endpoint:Vendors-CreateVendor) call idempotent.  See [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) in the [API Development 101](https://developer.squareup.com/docs/buildbasics) section for more information.
  --vendor: record # Represents a supplier to a seller. — shape: {id?: string, name?: string, address?: record, contacts?: list, account_number?: string, note?: string, version?: int, status?: "ACTIVE"|"INACTIVE"}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, vendor: record<id: string, created_at: string, updated_at: string, name: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, contacts: list<record>, account_number: string, note: string, version: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vendors/create")
  let body = {idempotency_key: $idempotency_key, vendor: $vendor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SearchVendors
#
# POST /v2/vendors/search
# operationId: SearchVendors
# --filter shape: {name?: list, status?: list}
# --sort shape: {field?: "NAME"|"CREATED_AT", order?: "DESC"|"ASC"}
export def "vendors-search SearchVendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record # Defines supported query expressions to search for vendors by. — shape: {name?: list, status?: list}
  --body-sort: record # Defines a sorter used to sort results from [SearchVendors](api-endpoint:Vendors-SearchVendors). — shape: {field?: "NAME"|"CREATED_AT", order?: "DESC"|"ASC"}
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for the original query.  See the [Pagination](https://developer.squareup.com/docs/working-with-apis/pagination) guide for more information.
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, vendors: table<id: string, created_at: string, updated_at: string, name: string, address: record, contacts: list, account_number: string, note: string, version: int, status: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vendors/search")
  let body = {filter: $filter, sort: $body_sort, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# RetrieveVendor
#
# GET /v2/vendors/{vendor_id}
# operationId: RetrieveVendor
export def "vendors RetrieveVendor" [
  vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, vendor: record<id: string, created_at: string, updated_at: string, name: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, contacts: list<record>, account_number: string, note: string, version: int, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vendors/($vendor_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateVendor
#
# PUT /v2/vendors/{vendor_id}
# operationId: UpdateVendor
# --vendor shape: {id?: string, name?: string, address?: record, contacts?: list, account_number?: string, note?: string, version?: int, status?: "ACTIVE"|"INACTIVE"}
export def "vendors UpdateVendor" [
  vendor_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A client-supplied, universally unique identifier (UUID) for the request.  See [Idempotency](https://developer.squareup.com/docs/build-basics/common-api-patterns/idempotency) in the [API Development 101](https://developer.squareup.com/docs/buildbasics) section for more information. (nullable)
  vendor: record # Represents a supplier to a seller. — shape: {id?: string, name?: string, address?: record, contacts?: list, account_number?: string, note?: string, version?: int, status?: "ACTIVE"|"INACTIVE"}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, vendor: record<id: string, created_at: string, updated_at: string, name: string, address: record<address_line_1: string, address_line_2: string, address_line_3: string, locality: string, sublocality: string, sublocality_2: string, sublocality_3: string, administrative_district_level_1: string, administrative_district_level_2: string, administrative_district_level_3: string, postal_code: string, country: string, first_name: string, last_name: string>, contacts: list<record>, account_number: string, note: string, version: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/vendors/($vendor_id)")
  let body = {idempotency_key: $idempotency_key, vendor: $vendor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ListWebhookEventTypes
#
# GET /v2/webhooks/event-types
# operationId: ListWebhookEventTypes
export def "webhooks-event-types ListWebhookEventTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The API version for which to list event types. Setting this field overrides the default version used by the application.
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, event_types: list<string>, metadata: table<event_type: string, api_version_introduced: string, release_status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/webhooks/event-types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ListWebhookSubscriptions
#
# GET /v2/webhooks/subscriptions
# operationId: ListWebhookSubscriptions
export def "webhooks-subscriptions ListWebhookSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pagination cursor returned by a previous call to this endpoint. Provide this to retrieve the next set of results for your original query.  For more information, see [Pagination](https://developer.squareup.com/docs/build-basics/common-api-patterns/pagination).
  --include-disabled: oneof<nothing, bool> # Includes disabled [Subscription](entity:WebhookSubscription)s. By default, all enabled [Subscription](entity:WebhookSubscription)s are returned. (default: false)
  --sort-order: string@sort-order-completer # Sorts the returned list by when the [Subscription](entity:WebhookSubscription) was created with the specified order. This field defaults to ASC.
  --limit: int # The maximum number of results to be returned in a single page. It is possible to receive fewer results than the specified limit on a given page. The default value of 100 is also the maximum allowed value.  Default: 100
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscriptions: table<id: string, name: string, enabled: bool, event_types: list, notification_url: string, api_version: string, signature_key: string, created_at: string, updated_at: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "include_disabled" $include_disabled "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/webhooks/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateWebhookSubscription
#
# POST /v2/webhooks/subscriptions
# operationId: CreateWebhookSubscription
# --subscription shape: {name?: string, enabled?: bool, event_types?: list, notification_url?: string, api_version?: string}
export def "webhooks-subscriptions CreateWebhookSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string that identifies the [CreateWebhookSubscription](api-endpoint:WebhookSubscriptions-CreateWebhookSubscription) request.
  subscription: record # Represents the details of a webhook subscription, including notification URL, event types, and signature key. — shape: {name?: string, enabled?: bool, event_types?: list, notification_url?: string, api_version?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, name: string, enabled: bool, event_types: list<string>, notification_url: string, api_version: string, signature_key: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/webhooks/subscriptions")
  let body = {idempotency_key: $idempotency_key, subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteWebhookSubscription
#
# DELETE /v2/webhooks/subscriptions/{subscription_id}
# operationId: DeleteWebhookSubscription
export def "webhooks-subscriptions DeleteWebhookSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/subscriptions/($subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# RetrieveWebhookSubscription
#
# GET /v2/webhooks/subscriptions/{subscription_id}
# operationId: RetrieveWebhookSubscription
export def "webhooks-subscriptions RetrieveWebhookSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, name: string, enabled: bool, event_types: list<string>, notification_url: string, api_version: string, signature_key: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/subscriptions/($subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UpdateWebhookSubscription
#
# PUT /v2/webhooks/subscriptions/{subscription_id}
# operationId: UpdateWebhookSubscription
# --subscription shape: {name?: string, enabled?: bool, event_types?: list, notification_url?: string, api_version?: string}
export def "webhooks-subscriptions UpdateWebhookSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription: record # Represents the details of a webhook subscription, including notification URL, event types, and signature key. — shape: {name?: string, enabled?: bool, event_types?: list, notification_url?: string, api_version?: string}
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription: record<id: string, name: string, enabled: bool, event_types: list<string>, notification_url: string, api_version: string, signature_key: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/subscriptions/($subscription_id)")
  let body = {subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# UpdateWebhookSubscriptionSignatureKey
#
# POST /v2/webhooks/subscriptions/{subscription_id}/signature-key
# operationId: UpdateWebhookSubscriptionSignatureKey
export def "webhooks-subscriptions-signature-key UpdateWebhookSubscriptionSignatureKey" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string that identifies the [UpdateWebhookSubscriptionSignatureKey](api-endpoint:WebhookSubscriptions-UpdateWebhookSubscriptionSignatureKey) request. (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, signature_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/subscriptions/($subscription_id)/signature-key")
  let body = {idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TestWebhookSubscription
#
# POST /v2/webhooks/subscriptions/{subscription_id}/test
# operationId: TestWebhookSubscription
export def "webhooks-subscriptions-test TestWebhookSubscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event-type: string # The event type that will be used to test the [Subscription](entity:WebhookSubscription). The event type must be contained in the list of event types in the [Subscription](entity:WebhookSubscription). (nullable)
]: any -> record<errors: table<category: string, code: string, detail: string, field: string>, subscription_test_result: record<id: string, status_code: int, payload: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/subscriptions/($subscription_id)/test")
  let body = {event_type: $event_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
