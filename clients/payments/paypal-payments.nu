# Auto-generated client for Payments v2.12
# Source: https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/payments_payment_v2.json
# Auth: --token flag or $env.PAYPAL_TOKEN

const BASE_URL = "https://api-m.paypal.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYPAL_TOKEN | default "" }
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
def base-url-completer [] { ["https://api-m.paypal.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payments-authorizations authorizationsget" } } | get name | first)
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

# Show details for authorized payment
#
# GET /v2/payments/authorizations/{authorization_id}
# operationId: authorizations.get
export def "payments-authorizations authorizationsget" [
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/authorizations/($authorization_id)")
  let extra_headers = {"Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Capture authorized payment
#
# POST /v2/payments/authorizations/{authorization_id}/capture
# operationId: authorizations.capture
export def "payments-authorizations-capture authorizationscapture" [
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PayPal-Request-Id: string # A unique ID identifying the request header for idempotency purposes.
  --Prefer: string # The preferred server response upon successful completion of the request. Value is:<ul><li><code>return=minimal</code>. The server returns a minimal response to optimize communication between the API caller and the server. A minimal response includes the <code>id</code>, <code>status</code> and HATEOAS links.</li><li><code>return=representation</code>. The server returns a complete resource representation, including the current state of the resource.</li></ul>
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --invoice-id: string # The API caller-provided external invoice number for this order. Appears in both the payer's transaction history and the emails that the payer receives.
  --note-to-payer: string # An informational note about this settlement. Appears in both the payer's transaction history and the emails that the payer receives.
  --amount: any
  --final-capture: string@bool-completer # Indicates whether you can make additional captures against the authorized payment. Set to `true` if you do not intend to capture additional payments against the authorization. Set to `false` if you intend to capture additional payments against the authorization. (default: false)
  --payment-instruction: any
  --soft-descriptor: string # The payment descriptor on the payer's account statement.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/authorizations/($authorization_id)/capture")
  let body = {invoice_id: $invoice_id, note_to_payer: $note_to_payer, amount: $amount, final_capture: $final_capture, payment_instruction: $payment_instruction, soft_descriptor: $soft_descriptor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"PayPal-Request-Id": $PayPal_Request_Id, "Prefer": $Prefer, "Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reauthorize authorized payment
#
# POST /v2/payments/authorizations/{authorization_id}/reauthorize
# operationId: authorizations.reauthorize
export def "payments-authorizations-reauthorize authorizationsreauthorize" [
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PayPal-Request-Id: string # A unique ID identifying the request header for idempotency purposes.
  --Prefer: string # The preferred server response upon successful completion of the request. Value is:<ul><li><code>return=minimal</code>. The server returns a minimal response to optimize communication between the API caller and the server. A minimal response includes the <code>id</code>, <code>status</code> and HATEOAS links.</li><li><code>return=representation</code>. The server returns a complete resource representation, including the current state of the resource.</li></ul>
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --amount: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/authorizations/($authorization_id)/reauthorize")
  let body = {amount: $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"PayPal-Request-Id": $PayPal_Request_Id, "Prefer": $Prefer, "Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Void authorized payment
#
# POST /v2/payments/authorizations/{authorization_id}/void
# operationId: authorizations.void
export def "payments-authorizations-void authorizationsvoid" [
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --PayPal-Request-Id: string # A unique ID identifying the request header for idempotency purposes.
  --Prefer: string # The preferred server response upon successful completion of the request. Value is:<ul><li><code>return=minimal</code>. The server returns a minimal response to optimize communication between the API caller and the server. A minimal response includes the <code>id</code>, <code>status</code> and HATEOAS links.</li><li><code>return=representation</code>. The server returns a complete resource representation, including the current state of the resource.</li></ul>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/authorizations/($authorization_id)/void")
  let extra_headers = {"Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion, "PayPal-Request-Id": $PayPal_Request_Id, "Prefer": $Prefer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show captured payment details
#
# GET /v2/payments/captures/{capture_id}
# operationId: captures.get
export def "payments-captures capturesget" [
  capture_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Holds authorization information for external API calls.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/captures/($capture_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refund captured payment
#
# POST /v2/payments/captures/{capture_id}/refund
# operationId: captures.refund
export def "payments-captures-refund capturesrefund" [
  capture_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PayPal-Request-Id: string # A unique ID identifying the request header for idempotency purposes.
  --Prefer: string # The preferred server response upon successful completion of the request. Value is:<ul><li><code>return=minimal</code>. The server returns a minimal response to optimize communication between the API caller and the server. A minimal response includes the <code>id</code>, <code>status</code> and HATEOAS links.</li><li><code>return=representation</code>. The server returns a complete resource representation, including the current state of the resource.</li></ul>
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --amount: any
  --custom-id: string # The API caller-provided external ID. Used to reconcile API caller-initiated transactions with PayPal transactions. Appears in transaction and settlement reports. The pattern is defined by an external party and supports Unicode.
  --invoice-id: string # The API caller-provided external invoice ID for this order. The pattern is defined by an external party and supports Unicode.
  --note-to-payer: string # The reason for the refund. Appears in both the payer's transaction history and the emails that the payer receives. The pattern is defined by an external party and supports Unicode.
  --payment-instruction: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/captures/($capture_id)/refund")
  let body = {amount: $amount, custom_id: $custom_id, invoice_id: $invoice_id, note_to_payer: $note_to_payer, payment_instruction: $payment_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"PayPal-Request-Id": $PayPal_Request_Id, "Prefer": $Prefer, "Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find a list of eligible payment methods.
#
# POST /v2/payments/find-eligible-methods
# operationId: find.eligible.methods
# --customer shape: {country_code?: any, channel?: any, id?: string, email?: string, phone?: any}
# --purchase_units item shape: {amount?: record, payee?: record}
# --preferences shape: {payment_flow?: "ONE_TIME_PAYMENT"|"RECURRING_PAYMENT"|"VAULT_WITH_PAYMENT"|"VAULT_WITHOUT_PAYMENT", include_account_details?: bool, include_vault_tokens?: bool, payment_source_constraint?: record}
export def "payments-find-eligible-methods findeligiblemethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --User-Agent: string # A characteristic string that lets servers and network peers identify the application, operating system, vendor, and/or version of the requesting user agent. API calls made by PayPal SDKs SHOULD be identified using this request header.
  --PayPal-Client-Metadata-Id: string # A GUID value originating from Fraudnet and Dyson passed from external API clients via HTTP header. The value is used by Risk decisions to correlate calls which, in turn, might result in lower decline rates..
  --customer: record # Customer who is making a purchase from the merchant/partner. — shape: {country_code?: any, channel?: any, id?: string, email?: string, phone?: any}
  --purchase-units: list # Array of purchase units. — item shape: {amount?: record, payee?: record}
  --preferences: record # Preferences of merchant/partner consuming the API. — shape: {payment_flow?: "ONE_TIME_PAYMENT"|"RECURRING_PAYMENT"|"VAULT_WITH_PAYMENT"|"VAULT_WITHOUT_PAYMENT", include_account_details?: bool, include_vault_tokens?: bool, payment_source_constraint?: record}
]: any -> record<eligible_methods: record<paypal: record, venmo: record, paypal_credit: record<can_be_vaulted: bool, country_code: record, product_code: record>, paypal_pay_later: record<can_be_vaulted: bool, country_code: record, product_code: record>>, payment_tokens: table<id: string, payment_source: record, links: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payments/find-eligible-methods")
  let body = {customer: $customer, purchase_units: $purchase_units, preferences: $preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion, "User-Agent": $User_Agent, "PayPal-Client-Metadata-Id": $PayPal_Client_Metadata_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show refund details
#
# GET /v2/payments/refunds/{refund_id}
# operationId: refunds.get
export def "payments-refunds refundsget" [
  refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/refunds/($refund_id)")
  let extra_headers = {"Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
