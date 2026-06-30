# Auto-generated client for Klarna Payments API V1 v1.0.0
# Source: https://api.apis.guru/v2/specs/klarna.com/payments/1.0.0/openapi.json
# Auth: --token flag or $env.KLARNA_PAYMENTS_API_V1_TOKEN

const BASE_URL = "https://api.klarna.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o KLARNA_PAYMENTS_API_V1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.klarna.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def intended-use-completer [] { ["SUBSCRIPTION"] }
def acquiring-channel-completer [] { ["ECOMMERCE" "IN_STORE" "TELESALES"] }
def intent-completer [] { ["buy" "buy_and_tokenize" "tokenize"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payments-authorizations cancel" } } | get name | first)
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

# Cancel an existing authorization
#
# DELETE /payments/v1/authorizations/{authorizationToken}
# operationId: cancelAuthorization
export def "payments-authorizations cancel" [
  authorization_token: string
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
  if ($authorization_token | is-empty) { error make --unspanned { msg: "path parameter 'authorizationToken' must be non-empty" } }
  let full_url = (build-url $base ({authorization_token: (encode-path-segment $authorization_token)} | format pattern "/payments/v1/authorizations/{authorization_token}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Generate a consumer token
#
# POST /payments/v1/authorizations/{authorizationToken}/customer-token
# operationId: purchaseToken
# --billing_address shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
# --customer shape: {date_of_birth?: string, gender?: string, last_four_ssn?: string, national_identification_number?: string, organization_entity_type?: "LIMITED_COMPANY"|"PUBLIC_LIMITED_COMPANY"|"ENTREPRENEURIAL_COMPANY"|"LIMITED_PARTNERSHIP_LIMITED_COMPANY"|"LIMITED_PARTNERSHIP"|"GENERAL_PARTNERSHIP"|"REGISTERED_SOLE_TRADER"|"SOLE_TRADER"|"CIVIL_LAW_PARTNERSHIP"|"PUBLIC_INSTITUTION"|"OTHER", organization_registration_id?: string, title?: string, type?: string, vat_id?: string}
export def "payments-authorizations-customer-token create-purchase" [
  authorization_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-address: record # shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
  --customer: record # shape: {date_of_birth?: string, gender?: string, last_four_ssn?: string, national_identification_number?: string, organization_entity_type?: "LIMITED_COMPANY"|"PUBLIC_LIMITED_COMPANY"|"ENTREPRENEURIAL_COMPANY"|"LIMITED_PARTNERSHIP_LIMITED_COMPANY"|"LIMITED_PARTNERSHIP"|"GENERAL_PARTNERSHIP"|"REGISTERED_SOLE_TRADER"|"SOLE_TRADER"|"CIVIL_LAW_PARTNERSHIP"|"PUBLIC_INSTITUTION"|"OTHER", organization_registration_id?: string, title?: string, type?: string, vat_id?: string}
  description: string # Description of the purpose of the token.
  intended_use: string@intended-use-completer # Intended use for the token.
  locale: string # RFC 1766 customer's locale. (e.g. en-GB)
  purchase_country: string # ISO 3166 alpha-2 purchase country. (e.g. GB)
  purchase_currency: string # ISO 4217 purchase currency. (e.g. GBP)
]: any -> record<billing_address: record<attention: string, city: string, country: string, email: string, family_name: string, given_name: string, organization_name: string, phone: string, postal_code: string, region: string, street_address: string, street_address2: string, title: string>, customer: record<date_of_birth: string, gender: string>, payment_method_reference: string, redirect_url: string, token_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization_token | is-empty) { error make --unspanned { msg: "path parameter 'authorizationToken' must be non-empty" } }
  let full_url = (build-url $base ({authorization_token: (encode-path-segment $authorization_token)} | format pattern "/payments/v1/authorizations/{authorization_token}/customer-token") $auth.query)
  let req_body = {"billing_address": $billing_address, "customer": $customer, "description": $description, "intended_use": $intended_use, "locale": $locale, "purchase_country": $purchase_country, "purchase_currency": $purchase_currency} | compact
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

# Create a new order
#
# POST /payments/v1/authorizations/{authorizationToken}/order
# operationId: createOrder
# --billing_address shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
# --customer shape: {date_of_birth?: string, gender?: string, last_four_ssn?: string, national_identification_number?: string, organization_entity_type?: "LIMITED_COMPANY"|"PUBLIC_LIMITED_COMPANY"|"ENTREPRENEURIAL_COMPANY"|"LIMITED_PARTNERSHIP_LIMITED_COMPANY"|"LIMITED_PARTNERSHIP"|"GENERAL_PARTNERSHIP"|"REGISTERED_SOLE_TRADER"|"SOLE_TRADER"|"CIVIL_LAW_PARTNERSHIP"|"PUBLIC_INSTITUTION"|"OTHER", organization_registration_id?: string, title?: string, type?: string, vat_id?: string}
# --merchant_urls shape: {authorization?: string, confirmation?: string, notification?: string, push?: string}
# --order_lines item shape: {image_url?: string, merchant_data?: string, name: string, product_identifiers?: record, product_url?: string, quantity: int, quantity_unit?: string, reference?: string, subscription?: record, tax_rate?: int, total_amount: int, total_discount_amount?: int, total_tax_amount?: int, type?: string, unit_price: int}
# --payment_method_categories item shape: {asset_urls?: record, identifier?: string, name?: string}
# --shipping_address shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
export def "payments-authorizations-order create" [
  authorization_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-capture: oneof<nothing, bool> # Allow merchant to trigger auto capturing. (default: false)
  --billing-address: record # shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
  --custom-payment-method-ids: list<string> # Promo codes - The array could be used to define which of the configured payment options within a payment category (pay_later, pay_over_time, etc.) should be shown for this purchase. Discuss with the delivery manager to know about the promo codes that will be configured for your account. The feature could also be used to provide promotional offers to specific customers (eg: 0% financing). Please be informed that the usage of this feature can have commercial implications.
  --customer: record # shape: {date_of_birth?: string, gender?: string, last_four_ssn?: string, national_identification_number?: string, organization_entity_type?: "LIMITED_COMPANY"|"PUBLIC_LIMITED_COMPANY"|"ENTREPRENEURIAL_COMPANY"|"LIMITED_PARTNERSHIP_LIMITED_COMPANY"|"LIMITED_PARTNERSHIP"|"GENERAL_PARTNERSHIP"|"REGISTERED_SOLE_TRADER"|"SOLE_TRADER"|"CIVIL_LAW_PARTNERSHIP"|"PUBLIC_INSTITUTION"|"OTHER", organization_registration_id?: string, title?: string, type?: string, vat_id?: string}
  --locale: string # Used to define the language and region of the customer. The locale follows the format of (RFC 1766)[https://datatracker.ietf.org/doc/rfc1766/], meaning its value consists of language-country. The following values are applicable: AT: "de-AT", "de-DE", "en-DE" BE: "be-BE", "nl-BE", "fr-BE", "en-BE" CH: "it-CH", "de-CH", "fr-CH", "en-CH" DE: "de-DE", "de-AT", "en-DE" DK: "da-DK", "en-DK" ES: "es-ES", "ca-ES", "en-ES" FI: "fi-FI", "sv-FI", "en-FI" GB: "en-GB" IT: "it-IT", "en-IT" NL: "nl-NL", "en-NL" NO: "nb-NO", "en-NO" PL: "pl-PL", "en-PL" SE: "sv-SE", "en-SE" US: "en-US". (e.g. en-GB)
  --merchant-data: string # Pass through field to send any information about the order to be used later for reference while retrieving the order details (max 6000 characters) (e.g. {"order_specific":[{"substore":"Women's Fashion","product_name":"Women Sweatshirt"}]})
  --merchant-reference1: string # Used for storing merchant's internal order number or other reference. (e.g. ON4711)
  --merchant-reference2: string # Used for storing merchant's internal order number or other reference. The value is available in the settlement files. (max 255 characters). (e.g. hdt53h-zdgg6-hdaff2)
  --merchant-urls: record # shape: {authorization?: string, confirmation?: string, notification?: string, push?: string}
  order_amount: int # Total amount of the order including tax and any available discounts. The value should be in non-negative minor units. Eg: 25 Euros should be 2500. (format: int64, e.g. 2500)
  order_lines: list # The array containing list of line items that are part of this order. Maximum of 1000 line items could be processed in a single order. — item shape: {image_url?: string, merchant_data?: string, name: string, product_identifiers?: record, product_url?: string, quantity: int, quantity_unit?: string, reference?: string, subscription?: record, tax_rate?: int, total_amount: int, total_discount_amount?: int, total_tax_amount?: int, type?: string, unit_price: int}
  --order-tax-amount: int # Total tax amount of the order. The value should be in non-negative minor units. Eg: 25 Euros should be 2500. (format: int64, e.g. 475)
  purchase_country: string # The purchase country of the customer. The billing country always overrides purchase country if the values are different. Formatted according to ISO 3166 alpha-2 standard, e.g. GB, SE, DE, US, etc. (e.g. GB)
  purchase_currency: string # The purchase currency of the order. Formatted according to ISO 4217 standard, e.g. USD, EUR, SEK, GBP, etc. (e.g. GBP)
  --shipping-address: record # shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
]: any -> record<authorized_payment_method: record<number_of_days: int, number_of_installments: int, type: string>, fraud_status: string, order_id: string, redirect_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization_token | is-empty) { error make --unspanned { msg: "path parameter 'authorizationToken' must be non-empty" } }
  let full_url = (build-url $base ({authorization_token: (encode-path-segment $authorization_token)} | format pattern "/payments/v1/authorizations/{authorization_token}/order") $auth.query)
  let req_body = {"auto_capture": $auto_capture, "billing_address": $billing_address, "custom_payment_method_ids": $custom_payment_method_ids, "customer": $customer, "locale": $locale, "merchant_data": $merchant_data, "merchant_reference1": $merchant_reference1, "merchant_reference2": $merchant_reference2, "merchant_urls": $merchant_urls, "order_amount": $order_amount, "order_lines": $order_lines, "order_tax_amount": $order_tax_amount, "purchase_country": $purchase_country, "purchase_currency": $purchase_currency, "shipping_address": $shipping_address} | compact
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

# Create a new payment session
#
# POST /payments/v1/sessions
# operationId: createCreditSession
# --attachment shape: {body: string, content_type: string}
# --billing_address shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
# --customer shape: {date_of_birth?: string, gender?: string, last_four_ssn?: string, national_identification_number?: string, organization_entity_type?: "LIMITED_COMPANY"|"PUBLIC_LIMITED_COMPANY"|"ENTREPRENEURIAL_COMPANY"|"LIMITED_PARTNERSHIP_LIMITED_COMPANY"|"LIMITED_PARTNERSHIP"|"GENERAL_PARTNERSHIP"|"REGISTERED_SOLE_TRADER"|"SOLE_TRADER"|"CIVIL_LAW_PARTNERSHIP"|"PUBLIC_INSTITUTION"|"OTHER", organization_registration_id?: string, title?: string, type?: string, vat_id?: string}
# --merchant_urls shape: {authorization?: string, confirmation?: string, notification?: string, push?: string}
# --options shape: {color_border?: string, color_border_selected?: string, color_details?: string, color_text?: string, radius_border?: string}
# --order_lines item shape: {image_url?: string, merchant_data?: string, name: string, product_identifiers?: record, product_url?: string, quantity: int, quantity_unit?: string, reference?: string, subscription?: record, tax_rate?: int, total_amount: int, total_discount_amount?: int, total_tax_amount?: int, type?: string, unit_price: int}
# --payment_method_categories item shape: {asset_urls?: record, identifier?: string, name?: string}
# --shipping_address shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
export def "payments-sessions create-credit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acquiring-channel: string@acquiring-channel-completer # The acquiring channel in which the session takes place. Ecommerce is default unless specified. Any other values should be defined in the agreement. (e.g. ECOMMERCE)
  --attachment: record # shape: {body: string, content_type: string}
  --billing-address: record # shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
  --custom-payment-method-ids: list<string> # Promo codes - The array could be used to define which of the configured payment options within a payment category (pay_later, pay_over_time, etc.) should be shown for this purchase. Discuss with the delivery manager to know about the promo codes that will be configured for your account. The feature could also be used to provide promotional offers to specific customers (eg: 0% financing). Please be informed that the usage of this feature can have commercial implications.
  --customer: record # shape: {date_of_birth?: string, gender?: string, last_four_ssn?: string, national_identification_number?: string, organization_entity_type?: "LIMITED_COMPANY"|"PUBLIC_LIMITED_COMPANY"|"ENTREPRENEURIAL_COMPANY"|"LIMITED_PARTNERSHIP_LIMITED_COMPANY"|"LIMITED_PARTNERSHIP"|"GENERAL_PARTNERSHIP"|"REGISTERED_SOLE_TRADER"|"SOLE_TRADER"|"CIVIL_LAW_PARTNERSHIP"|"PUBLIC_INSTITUTION"|"OTHER", organization_registration_id?: string, title?: string, type?: string, vat_id?: string}
  --design: string # Design package to use in the session. This can only by used if a custom design has been implemented for Klarna Payments and agreed upon in the agreement. It might have a financial impact. Delivery manager will provide the value for the parameter.
  --intent: string@intent-completer # Intent for the session. The field is designed to let partners inform Klarna of the purpose of the customer’s session. (e.g. buy)
  --locale: string # Used to define the language and region of the customer. The locale follows the format of (RFC 1766)[https://datatracker.ietf.org/doc/rfc1766/], meaning its value consists of language-country. The following values are applicable: AT: "de-AT", "de-DE", "en-DE" BE: "be-BE", "nl-BE", "fr-BE", "en-BE" CH: "it-CH", "de-CH", "fr-CH", "en-CH" DE: "de-DE", "de-AT", "en-DE" DK: "da-DK", "en-DK" ES: "es-ES", "ca-ES", "en-ES" FI: "fi-FI", "sv-FI", "en-FI" GB: "en-GB" IT: "it-IT", "en-IT" NL: "nl-NL", "en-NL" NO: "nb-NO", "en-NO" PL: "pl-PL", "en-PL" SE: "sv-SE", "en-SE" US: "en-US". Default value is "en-US". (e.g. en-US)
  --merchant-data: string # Pass through field to send any information about the order to be used later for reference while retrieving the order details (max 6000 characters) (e.g. {"order_specific":[{"substore":"Women's Fashion","product_name":"Women Sweatshirt"}]})
  --merchant-reference1: string # Used for storing merchant's internal order number or other reference. (e.g. ON4711)
  --merchant-reference2: string # Used for storing merchant's internal order number or other reference. The value is available in the settlement files. (max 255 characters). (e.g. hdt53h-zdgg6-hdaff2)
  --merchant-urls: record # shape: {authorization?: string, confirmation?: string, notification?: string, push?: string}
  --options: record # shape: {color_border?: string, color_border_selected?: string, color_details?: string, color_text?: string, radius_border?: string}
  order_amount: int # Total amount of the order including tax and any available discounts. The value should be in non-negative minor units. Eg: 25 Euros should be 2500. (format: int64, e.g. 2500)
  order_lines: list # The array containing list of line items that are part of this order. Maximum of 1000 line items could be processed in a single order. — item shape: {image_url?: string, merchant_data?: string, name: string, product_identifiers?: record, product_url?: string, quantity: int, quantity_unit?: string, reference?: string, subscription?: record, tax_rate?: int, total_amount: int, total_discount_amount?: int, total_tax_amount?: int, type?: string, unit_price: int}
  --order-tax-amount: int # Total tax amount of the order. The value should be in non-negative minor units. Eg: 25 Euros should be 2500. (format: int64, e.g. 475)
  purchase_country: string # The purchase country of the customer. The billing country always overrides purchase country if the values are different. Formatted according to ISO 3166 alpha-2 standard, e.g. GB, SE, DE, US, etc. (e.g. GB)
  purchase_currency: string # The purchase currency of the order. Formatted according to ISO 4217 standard, e.g. USD, EUR, SEK, GBP, etc. (e.g. GBP)
  --shipping-address: record # shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
]: any -> record<client_token: string, payment_method_categories: table<asset_urls: record, identifier: string, name: string>, session_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/v1/sessions" $auth.query)
  let req_body = {"acquiring_channel": $acquiring_channel, "attachment": $attachment, "billing_address": $billing_address, "custom_payment_method_ids": $custom_payment_method_ids, "customer": $customer, "design": $design, "intent": $intent, "locale": $locale, "merchant_data": $merchant_data, "merchant_reference1": $merchant_reference1, "merchant_reference2": $merchant_reference2, "merchant_urls": $merchant_urls, "options": $options, "order_amount": $order_amount, "order_lines": $order_lines, "order_tax_amount": $order_tax_amount, "purchase_country": $purchase_country, "purchase_currency": $purchase_currency, "shipping_address": $shipping_address} | compact
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

# Read an existing payment session
#
# GET /payments/v1/sessions/{session_id}
# operationId: readCreditSession
export def "payments-sessions get-credit" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acquiring_channel: string, attachment: record<body: string, content_type: string>, authorization_token: string, billing_address: record<attention: string, city: string, country: string, email: string, family_name: string, given_name: string, organization_name: string, phone: string, postal_code: string, region: string, street_address: string, street_address2: string, title: string>, client_token: string, custom_payment_method_ids: list<string>, customer: record<date_of_birth: string, gender: string, organization_entity_type: string, organization_registration_id: string, title: string, type: string, vat_id: string>, design: string, expires_at: string, intent: string, locale: string, merchant_data: string, merchant_reference1: string, merchant_reference2: string, merchant_urls: record<authorization: string, confirmation: string, notification: string, push: string>, options: record<color_border: string, color_border_selected: string, color_details: string, color_text: string, radius_border: string>, order_amount: int, order_lines: table<image_url: string, merchant_data: string, name: string, product_identifiers: record, product_url: string, quantity: int, quantity_unit: string, reference: string, subscription: record, tax_rate: int, total_amount: int, total_discount_amount: int, total_tax_amount: int, type: string, unit_price: int>, order_tax_amount: int, payment_method_categories: table<asset_urls: record, identifier: string, name: string>, purchase_country: string, purchase_currency: string, shipping_address: record<attention: string, city: string, country: string, email: string, family_name: string, given_name: string, organization_name: string, phone: string, postal_code: string, region: string, street_address: string, street_address2: string, title: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'session_id' must be non-empty" } }
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/payments/v1/sessions/{session_id}") $auth.query)
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

# Update an existing payment session
#
# POST /payments/v1/sessions/{session_id}
# operationId: updateCreditSession
# --attachment shape: {body: string, content_type: string}
# --billing_address shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
# --customer shape: {date_of_birth?: string, gender?: string, last_four_ssn?: string, national_identification_number?: string, organization_entity_type?: "LIMITED_COMPANY"|"PUBLIC_LIMITED_COMPANY"|"ENTREPRENEURIAL_COMPANY"|"LIMITED_PARTNERSHIP_LIMITED_COMPANY"|"LIMITED_PARTNERSHIP"|"GENERAL_PARTNERSHIP"|"REGISTERED_SOLE_TRADER"|"SOLE_TRADER"|"CIVIL_LAW_PARTNERSHIP"|"PUBLIC_INSTITUTION"|"OTHER", organization_registration_id?: string, title?: string, type?: string, vat_id?: string}
# --merchant_urls shape: {authorization?: string, confirmation?: string, notification?: string, push?: string}
# --options shape: {color_border?: string, color_border_selected?: string, color_details?: string, color_text?: string, radius_border?: string}
# --order_lines item shape: {image_url?: string, merchant_data?: string, name: string, product_identifiers?: record, product_url?: string, quantity: int, quantity_unit?: string, reference?: string, subscription?: record, tax_rate?: int, total_amount: int, total_discount_amount?: int, total_tax_amount?: int, type?: string, unit_price: int}
# --payment_method_categories item shape: {asset_urls?: record, identifier?: string, name?: string}
# --shipping_address shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
export def "payments-sessions update-credit" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acquiring-channel: string@acquiring-channel-completer # The acquiring channel in which the session takes place. Ecommerce is default unless specified. Any other values should be defined in the agreement. (e.g. ECOMMERCE)
  --attachment: record # shape: {body: string, content_type: string}
  --billing-address: record # shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
  --custom-payment-method-ids: list<string> # Promo codes - The array could be used to define which of the configured payment options within a payment category (pay_later, pay_over_time, etc.) should be shown for this purchase. Discuss with the delivery manager to know about the promo codes that will be configured for your account. The feature could also be used to provide promotional offers to specific customers (eg: 0% financing). Please be informed that the usage of this feature can have commercial implications.
  --customer: record # shape: {date_of_birth?: string, gender?: string, last_four_ssn?: string, national_identification_number?: string, organization_entity_type?: "LIMITED_COMPANY"|"PUBLIC_LIMITED_COMPANY"|"ENTREPRENEURIAL_COMPANY"|"LIMITED_PARTNERSHIP_LIMITED_COMPANY"|"LIMITED_PARTNERSHIP"|"GENERAL_PARTNERSHIP"|"REGISTERED_SOLE_TRADER"|"SOLE_TRADER"|"CIVIL_LAW_PARTNERSHIP"|"PUBLIC_INSTITUTION"|"OTHER", organization_registration_id?: string, title?: string, type?: string, vat_id?: string}
  --design: string # Design package to use in the session. This can only by used if a custom design has been implemented for Klarna Payments and agreed upon in the agreement. It might have a financial impact. Delivery manager will provide the value for the parameter.
  --intent: string@intent-completer # Intent for the session. The field is designed to let partners inform Klarna of the purpose of the customer’s session. (e.g. buy)
  --locale: string # Used to define the language and region of the customer. The locale follows the format of (RFC 1766)[https://datatracker.ietf.org/doc/rfc1766/], meaning its value consists of language-country. The following values are applicable: AT: "de-AT", "de-DE", "en-DE" BE: "be-BE", "nl-BE", "fr-BE", "en-BE" CH: "it-CH", "de-CH", "fr-CH", "en-CH" DE: "de-DE", "de-AT", "en-DE" DK: "da-DK", "en-DK" ES: "es-ES", "ca-ES", "en-ES" FI: "fi-FI", "sv-FI", "en-FI" GB: "en-GB" IT: "it-IT", "en-IT" NL: "nl-NL", "en-NL" NO: "nb-NO", "en-NO" PL: "pl-PL", "en-PL" SE: "sv-SE", "en-SE" US: "en-US". (e.g. en-GB)
  --merchant-data: string # Pass through field to send any information about the order to be used later for reference while retrieving the order details (max 6000 characters) (e.g. {"order_specific":[{"substore":"Women's Fashion","product_name":"Women Sweatshirt"}]})
  --merchant-reference1: string # Used for storing merchant's internal order number or other reference. (e.g. ON4711)
  --merchant-reference2: string # Used for storing merchant's internal order number or other reference. The value is available in the settlement files. (max 255 characters). (e.g. hdt53h-zdgg6-hdaff2)
  --merchant-urls: record # shape: {authorization?: string, confirmation?: string, notification?: string, push?: string}
  --options: record # shape: {color_border?: string, color_border_selected?: string, color_details?: string, color_text?: string, radius_border?: string}
  --order-amount: int # Total amount of the order including tax and any available discounts. The value should be in non-negative minor units. Eg: 25 Euros should be 2500. (format: int64, e.g. 2500)
  --order-lines: list # The array containing list of line items that are part of this order. Maximum of 1000 line items could be processed in a single order. — item shape: {image_url?: string, merchant_data?: string, name: string, product_identifiers?: record, product_url?: string, quantity: int, quantity_unit?: string, reference?: string, subscription?: record, tax_rate?: int, total_amount: int, total_discount_amount?: int, total_tax_amount?: int, type?: string, unit_price: int}
  --order-tax-amount: int # Total tax amount of the order. The value should be in non-negative minor units. Eg: 25 Euros should be 2500. (format: int64, e.g. 475)
  --purchase-country: string # The purchase country of the customer. The billing country always overrides purchase country if the values are different. Formatted according to ISO 3166 alpha-2 standard, e.g. GB, SE, DE, US, etc. (e.g. GB)
  --purchase-currency: string # The purchase currency of the order. Formatted according to ISO 4217 standard, e.g. USD, EUR, SEK, GBP, etc. (e.g. GBP)
  --shipping-address: record # shape: {attention?: string, city?: string, country?: string, email?: string, family_name?: string, given_name?: string, organization_name?: string, phone?: string, postal_code?: string, region?: string, street_address?: string, street_address2?: string, title?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'session_id' must be non-empty" } }
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/payments/v1/sessions/{session_id}") $auth.query)
  let req_body = {"acquiring_channel": $acquiring_channel, "attachment": $attachment, "billing_address": $billing_address, "custom_payment_method_ids": $custom_payment_method_ids, "customer": $customer, "design": $design, "intent": $intent, "locale": $locale, "merchant_data": $merchant_data, "merchant_reference1": $merchant_reference1, "merchant_reference2": $merchant_reference2, "merchant_urls": $merchant_urls, "options": $options, "order_amount": $order_amount, "order_lines": $order_lines, "order_tax_amount": $order_tax_amount, "purchase_country": $purchase_country, "purchase_currency": $purchase_currency, "shipping_address": $shipping_address} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}
