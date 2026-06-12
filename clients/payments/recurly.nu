# Auto-generated client for Recurly V3 API vv2021-02-25
# Source: https://raw.githubusercontent.com/recurly/recurly-client-go/master/openapi/api.yaml
# Auth: --token flag or $env.RECURLY_API_KEY

const BASE_URL = "https://v3.recurly.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RECURLY_API_KEY | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://v3.recurly.com" "https://v3.eu.recurly.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def order-completer [] { ["asc" "desc"] }
def sort-completer [] { ["created_at" "updated_at"] }
def state-completer [] { ["active" "inactive"] }
def past-due-completer [] { ["true"] }
def preferred-locale-completer [] { ["da-DK" "de-CH" "de-DE" "en-AU" "en-CA" "en-GB" "en-IE" "en-NZ" "en-US" "es-ES" "es-MX" "es-US" "fi-FI" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "hi-IN" "it-IT" "ja-JP" "ko-KR" "nl-BE" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sk-SK" "sv-SE" "tr-TR" "zh-CN"] }
def bill-to-completer [] { ["parent" "self"] }
def transaction-type-completer [] { ["moto"] }
def channel-completer [] { ["advertising" "blog" "direct_traffic" "email" "events" "marketing_content" "organic_search" "other" "outbound_sales" "paid_search" "public_relations" "referral" "social_media"] }
def type-completer [] { ["bacs" "becs" "mercadopago" "pix-automatico"] }
def account-type-completer [] { ["checking" "savings"] }
def tax-identifier-type-completer [] { ["cnpj" "cpf" "cuit"] }
def external-hpp-type-completer [] { ["adyen"] }
def online-banking-payment-type-completer [] { ["ideal" "sofort"] }
def card-type-completer [] { ["American Express" "Dankort" "Diners Club" "Discover" "ELO" "Forbrugsforeningen" "Hipercard" "JCB" "Laser" "Maestro" "MasterCard" "Tarjeta Naranja" "Test Card" "Union Pay" "Unknown" "Visa"] }
def card-network-preference-completer [] { ["Bancontact" "CartesBancaires" "Dankort" "MasterCard" "Visa"] }
def state-completer-1 [] { ["closed" "failed" "open" "paid" "past_due" "pending" "processing" "voided"] }
def type-completer-1 [] { ["charge" "credit" "legacy" "non-legacy"] }
def collection-method-completer [] { ["automatic" "manual"] }
def net-terms-type-completer [] { ["eom" "net"] }
def vertex-transaction-type-completer [] { ["lease" "rental" "sale"] }
def original-completer [] { ["true"] }
def state-completer-2 [] { ["invoiced" "pending"] }
def type-completer-2 [] { ["charge" "credit"] }
def revenue-schedule-type-completer [] { ["at_invoice" "at_range_end" "at_range_start" "evenly" "never"] }
def credit-reason-code-completer [] { ["general" "promotional" "service"] }
def origin-completer [] { ["external_gift_card" "prepayment"] }
def origin-tax-address-source-completer [] { ["destination" "origin"] }
def destination-tax-address-source-completer [] { ["destination" "origin"] }
def state-completer-3 [] { ["active" "canceled" "expired" "future" "in_trial" "live"] }
def type-completer-3 [] { ["authorization" "capture" "payment" "purchase" "refund" "verify"] }
def success-completer [] { ["true"] }
def discount-type-completer [] { ["fixed" "free_trial" "percent"] }
def free-trial-unit-completer [] { ["billing_period" "day" "month" "week"] }
def duration-completer [] { ["forever" "single_use" "temporal"] }
def temporal-unit-completer [] { ["billing_period" "day" "month" "week" "year"] }
def coupon-type-completer [] { ["bulk" "single_code"] }
def redemption-resource-completer [] { ["account" "subscription"] }
def redeemed-completer [] { ["false" "true"] }
def related-type-completer [] { ["account" "charge" "item" "plan" "subscription"] }
def account-type-completer-1 [] { ["liability" "revenue"] }
def revenue-schedule-type-completer-1 [] { ["at_range_end" "at_range_start" "evenly" "never"] }
def state-completer-4 [] { ["paid"] }
def accept-completer [] { ["application/json" "application/pdf"] }
def payment-method-completer [] { ["ach" "amazon" "apple_pay" "bacs" "braintree_apple_pay" "check" "credit_card" "eft" "google_pay" "mercadopago" "money_order" "other" "paypal" "pix_automatico" "roku" "sepadirectdebit" "wire_transfer"] }
def type-completer-4 [] { ["amount" "line_items" "percentage"] }
def refund-method-completer [] { ["all_credit" "all_transaction" "credit_first" "transaction_first"] }
def pricing-model-completer [] { ["fixed" "ramp"] }
def interval-unit-completer [] { ["days" "months"] }
def setup-fee-revenue-schedule-type-completer [] { ["at_range_end" "at_range_start" "evenly" "never"] }
def trial-unit-completer [] { ["days" "months"] }
def add-on-type-completer [] { ["fixed" "usage"] }
def usage-type-completer [] { ["percentage" "price"] }
def usage-calculation-type-completer [] { ["cumulative" "last_in_period"] }
def tier-type-completer [] { ["flat" "stairstep" "tiered" "volume"] }
def usage-timeframe-completer [] { ["billing_period" "subscription_term"] }
def refund-completer [] { ["full" "none" "partial"] }
def timeframe-completer [] { ["bill_date" "term_end"] }
def timeframe-completer-1 [] { ["bill_date" "now" "renewal" "term_end"] }
def sort-completer-1 [] { ["recorded_timestamp" "usage_timestamp"] }
def billing-status-completer [] { ["all" "billed" "unbilled"] }
def state-completer-5 [] { ["active" "canceled" "expired" "future"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sites sites" } } | get name | first)
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

# List sites
#
# GET /sites
# operationId: list_sites
export def "sites sites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --state: string@state-completer # Filter by state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, subdomain: string, public_api_key: string, mode: string, address: record, settings: record, features: list, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a site
#
# GET /sites/{site_id}
# operationId: get_site
export def "sites site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, subdomain: string, public_api_key: string, mode: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, settings: record<billing_address_requirement: string, accepted_currencies: list<string>, default_currency: string>, features: list<string>, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's accounts
#
# GET /accounts
# operationId: list_accounts
export def "accounts accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --email: string # Filter for accounts with this exact email address. A blank value will return accounts with both `null` and `""` email addresses. Note that multiple accounts can share one email address.
  --subscriber: oneof<nothing, bool> # Filter for accounts with or without a subscription in the `active`, `canceled`, or `future` state.
  --past-due: string@past-due-completer # Filter for accounts with an invoice in the `past_due` state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: list, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: list, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record, billing_info: record, custom_fields: list, entity_use_code: string, bill_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "subscriber" $subscriber "scalar") (serialize-qp "past_due" $past_due "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an account
#
# POST /accounts
# operationId: create_account
# --acquisition shape: {cost?: record, channel?: "advertising"|"blog"|"direct_traffic"|"email"|"events"|"marketing_content"|"organic_search"|"other"|"outbound_sales"|"paid_search"|"public_relations"|"referral"|"social_media", subchannel?: string, campaign?: string, acquired_at?: string}
# --external_accounts item shape: {external_account_code: string, external_connection_type: string}
# --shipping_addresses item shape: {nickname?: string, first_name: string, last_name: string, company?: string, email?: string, vat_number?: string, phone?: string, street1: string, street2?: string, city: string, region?: string, postal_code: string, geo_code?: string, country: string}
# --address shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
# --billing_info shape: {token_id?: string, first_name?: string, last_name?: string, company?: string, address?: record, number?: string, month?: string, year?: string, cvv?: string, currency?: string, vat_number?: string, ip_address?: string, gateway_token?: string, gateway_code?: string, payment_gateway_references?: list, gateway_attributes?: record, amazon_billing_agreement_id?: string, paypal_billing_agreement_id?: string, roku_billing_agreement_id?: string, fraud_session_id?: string, adyen_risk_profile_reference_id?: string, transaction_type?: "moto", three_d_secure_action_result_token_id?: string, iban?: string, name_on_account?: string, account_number?: string, routing_number?: string, sort_code?: string, type?: "bacs"|"becs"|"pix-automatico"|"mercadopago", account_type?: "checking"|"savings", tax_identifier?: string, tax_identifier_type?: "cpf"|"cnpj"|"cuit", primary_payment_method?: bool, backup_payment_method?: bool, external_hpp_type?: "adyen", online_banking_payment_type?: "ideal"|"sofort", card_type?: "American Express"|"Dankort"|"Diners Club"|"Discover"|"ELO"|"Forbrugsforeningen"|"Hipercard"|"JCB"|"Laser"|"Maestro"|"MasterCard"|"Test Card"|"Union Pay"|"Unknown"|"Visa"|"Tarjeta Naranja", card_network_preference?: "Bancontact"|"CartesBancaires"|"Dankort"|"MasterCard"|"Visa", return_url?: string}
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
export def "accounts account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # The unique identifier of the account. This cannot be changed once the account is created.
  --acquisition: record # shape: {cost?: record, channel?: "advertising"|"blog"|"direct_traffic"|"email"|"events"|"marketing_content"|"organic_search"|"other"|"outbound_sales"|"paid_search"|"public_relations"|"referral"|"social_media", subchannel?: string, campaign?: string, acquired_at?: string}
  --external-accounts: list # item shape: {external_account_code: string, external_connection_type: string}
  --shipping-addresses: list # item shape: {nickname?: string, first_name: string, last_name: string, company?: string, email?: string, vat_number?: string, phone?: string, street1: string, street2?: string, city: string, region?: string, postal_code: string, geo_code?: string, country: string}
  --username: string # A secondary value for the account.
  --email: string # The email address used for communicating with this customer. The customer will also use this email address to log into your hosted account management pages. This value does not need to be unique. (format: email)
  --preferred-locale: string@preferred-locale-completer
  --preferred-time-zone: string # Used to determine the time zone of emails sent on behalf of the merchant to the customer. Must be a [supported IANA time zone name](https://docs.recurly.com/docs/email-time-zones-and-time-stamps#supported-api-iana-time-zone-names) (e.g. America/Los_Angeles)
  --cc-emails: string # Additional email address that should receive account correspondence. These should be separated only by commas. These CC emails will receive all emails that the `email` field also receives.
  --first-name: string
  --last-name: string
  --company: string
  --vat-number: string # The VAT number of the account (to avoid having the VAT applied). This is only used for manually collected invoices.
  --tax-exempt: oneof<nothing, bool> # The tax status of the account. `true` exempts tax on the account, `false` applies tax on the account.
  --exemption-certificate: string # The tax exemption certificate number for the account. If the merchant has an integration for the Vertex tax provider, this optional value will be sent in any tax calculation requests for the account.
  --override-business-entity-id: string # Unique ID to identify the business entity assigned to the account. Available when the `Multiple Business Entities` feature is enabled.
  --parent-account-code: string # The account code of the parent account to be associated with this account. Passing an empty value removes any existing parent association from this account. If both `parent_account_code` and `parent_account_id` are passed, the non-blank value in `parent_account_id` will be used. Only one level of parent child relationship is allowed. You cannot assign a parent account that itself has a parent account.
  --parent-account-id: string # The UUID of the parent account to be associated with this account. Passing an empty value removes any existing parent association from this account. If both `parent_account_code` and `parent_account_id` are passed, the non-blank value in `parent_account_id` will be used. Only one level of parent child relationship is allowed. You cannot assign a parent account that itself has a parent account.
  --bill-to: string@bill-to-completer
  --transaction-type: string@transaction-type-completer
  --dunning-campaign-id: string # Unique ID to identify a dunning campaign. Used to specify if a non-default dunning campaign should be assigned to this account. For sites without multiple dunning campaigns enabled, the default dunning campaign will always be used.
  --invoice-template-id: string # Unique ID to identify an invoice template.  Available when the site is on a Pro or Elite plan.  Used to specify which invoice template, if any, should be used to generate invoices for the account.
  --address: record # shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
  --billing-info: record # shape: {token_id?: string, first_name?: string, last_name?: string, company?: string, address?: record, number?: string, month?: string, year?: string, cvv?: string, currency?: string, vat_number?: string, ip_address?: string, gateway_token?: string, gateway_code?: string, payment_gateway_references?: list, gateway_attributes?: record, amazon_billing_agreement_id?: string, paypal_billing_agreement_id?: string, roku_billing_agreement_id?: string, fraud_session_id?: string, adyen_risk_profile_reference_id?: string, transaction_type?: "moto", three_d_secure_action_result_token_id?: string, iban?: string, name_on_account?: string, account_number?: string, routing_number?: string, sort_code?: string, type?: "bacs"|"becs"|"pix-automatico"|"mercadopago", account_type?: "checking"|"savings", tax_identifier?: string, tax_identifier_type?: "cpf"|"cnpj"|"cuit", primary_payment_method?: bool, backup_payment_method?: bool, external_hpp_type?: "adyen", online_banking_payment_type?: "ideal"|"sofort", card_type?: "American Express"|"Dankort"|"Diners Club"|"Discover"|"ELO"|"Forbrugsforeningen"|"Hipercard"|"JCB"|"Laser"|"Maestro"|"MasterCard"|"Test Card"|"Union Pay"|"Unknown"|"Visa"|"Tarjeta Naranja", card_network_preference?: "Bancontact"|"CartesBancaires"|"Dankort"|"MasterCard"|"Visa", return_url?: string}
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --entity-use-code: string # The Avalara AvaTax value that can be passed to identify the customer type for tax purposes. The range of values can be A - R (more info at Avalara). Value is case-sensitive.
  --bill-date: string # The preferred billing date for the account. This date will be used as the billing date for when activating new subscriptions on the account. (format: date-time)
]: any -> record<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: table<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: table<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string>, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, billing_info: record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: list<record>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, entity_use_code: string, bill_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let body = {code: $code, acquisition: $acquisition, external_accounts: $external_accounts, shipping_addresses: $shipping_addresses, username: $username, email: $email, preferred_locale: $preferred_locale, preferred_time_zone: $preferred_time_zone, cc_emails: $cc_emails, first_name: $first_name, last_name: $last_name, company: $company, vat_number: $vat_number, tax_exempt: $tax_exempt, exemption_certificate: $exemption_certificate, override_business_entity_id: $override_business_entity_id, parent_account_code: $parent_account_code, parent_account_id: $parent_account_id, bill_to: $bill_to, transaction_type: $transaction_type, dunning_campaign_id: $dunning_campaign_id, invoice_template_id: $invoice_template_id, address: $address, billing_info: $billing_info, custom_fields: $custom_fields, entity_use_code: $entity_use_code, bill_date: $bill_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an account
#
# GET /accounts/{account_id}
# operationId: get_account
export def "accounts account-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: table<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: table<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string>, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, billing_info: record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: list<record>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, entity_use_code: string, bill_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account
#
# PUT /accounts/{account_id}
# operationId: update_account
# --address shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
# --billing_info shape: {token_id?: string, first_name?: string, last_name?: string, company?: string, address?: record, number?: string, month?: string, year?: string, cvv?: string, currency?: string, vat_number?: string, ip_address?: string, gateway_token?: string, gateway_code?: string, payment_gateway_references?: list, gateway_attributes?: record, amazon_billing_agreement_id?: string, paypal_billing_agreement_id?: string, roku_billing_agreement_id?: string, fraud_session_id?: string, adyen_risk_profile_reference_id?: string, transaction_type?: "moto", three_d_secure_action_result_token_id?: string, iban?: string, name_on_account?: string, account_number?: string, routing_number?: string, sort_code?: string, type?: "bacs"|"becs"|"pix-automatico"|"mercadopago", account_type?: "checking"|"savings", tax_identifier?: string, tax_identifier_type?: "cpf"|"cnpj"|"cuit", primary_payment_method?: bool, backup_payment_method?: bool, external_hpp_type?: "adyen", online_banking_payment_type?: "ideal"|"sofort", card_type?: "American Express"|"Dankort"|"Diners Club"|"Discover"|"ELO"|"Forbrugsforeningen"|"Hipercard"|"JCB"|"Laser"|"Maestro"|"MasterCard"|"Test Card"|"Union Pay"|"Unknown"|"Visa"|"Tarjeta Naranja", card_network_preference?: "Bancontact"|"CartesBancaires"|"Dankort"|"MasterCard"|"Visa", return_url?: string}
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
export def "accounts account-by-account_id-1" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # A secondary value for the account.
  --email: string # The email address used for communicating with this customer. The customer will also use this email address to log into your hosted account management pages. This value does not need to be unique. (format: email)
  --preferred-locale: string@preferred-locale-completer
  --preferred-time-zone: string # Used to determine the time zone of emails sent on behalf of the merchant to the customer. Must be a [supported IANA time zone name](https://docs.recurly.com/docs/email-time-zones-and-time-stamps#supported-api-iana-time-zone-names) (e.g. America/Los_Angeles)
  --cc-emails: string # Additional email address that should receive account correspondence. These should be separated only by commas. These CC emails will receive all emails that the `email` field also receives.
  --first-name: string
  --last-name: string
  --company: string
  --vat-number: string # The VAT number of the account (to avoid having the VAT applied). This is only used for manually collected invoices.
  --tax-exempt: oneof<nothing, bool> # The tax status of the account. `true` exempts tax on the account, `false` applies tax on the account.
  --exemption-certificate: string # The tax exemption certificate number for the account. If the merchant has an integration for the Vertex tax provider, this optional value will be sent in any tax calculation requests for the account.
  --override-business-entity-id: string # Unique ID to identify the business entity assigned to the account. Available when the `Multiple Business Entities` feature is enabled.
  --parent-account-code: string # The account code of the parent account to be associated with this account. Passing an empty value removes any existing parent association from this account. If both `parent_account_code` and `parent_account_id` are passed, the non-blank value in `parent_account_id` will be used. Only one level of parent child relationship is allowed. You cannot assign a parent account that itself has a parent account.
  --parent-account-id: string # The UUID of the parent account to be associated with this account. Passing an empty value removes any existing parent association from this account. If both `parent_account_code` and `parent_account_id` are passed, the non-blank value in `parent_account_id` will be used. Only one level of parent child relationship is allowed. You cannot assign a parent account that itself has a parent account.
  --bill-to: string@bill-to-completer
  --transaction-type: string@transaction-type-completer
  --dunning-campaign-id: string # Unique ID to identify a dunning campaign. Used to specify if a non-default dunning campaign should be assigned to this account. For sites without multiple dunning campaigns enabled, the default dunning campaign will always be used.
  --invoice-template-id: string # Unique ID to identify an invoice template.  Available when the site is on a Pro or Elite plan.  Used to specify which invoice template, if any, should be used to generate invoices for the account.
  --address: record # shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
  --billing-info: record # shape: {token_id?: string, first_name?: string, last_name?: string, company?: string, address?: record, number?: string, month?: string, year?: string, cvv?: string, currency?: string, vat_number?: string, ip_address?: string, gateway_token?: string, gateway_code?: string, payment_gateway_references?: list, gateway_attributes?: record, amazon_billing_agreement_id?: string, paypal_billing_agreement_id?: string, roku_billing_agreement_id?: string, fraud_session_id?: string, adyen_risk_profile_reference_id?: string, transaction_type?: "moto", three_d_secure_action_result_token_id?: string, iban?: string, name_on_account?: string, account_number?: string, routing_number?: string, sort_code?: string, type?: "bacs"|"becs"|"pix-automatico"|"mercadopago", account_type?: "checking"|"savings", tax_identifier?: string, tax_identifier_type?: "cpf"|"cnpj"|"cuit", primary_payment_method?: bool, backup_payment_method?: bool, external_hpp_type?: "adyen", online_banking_payment_type?: "ideal"|"sofort", card_type?: "American Express"|"Dankort"|"Diners Club"|"Discover"|"ELO"|"Forbrugsforeningen"|"Hipercard"|"JCB"|"Laser"|"Maestro"|"MasterCard"|"Test Card"|"Union Pay"|"Unknown"|"Visa"|"Tarjeta Naranja", card_network_preference?: "Bancontact"|"CartesBancaires"|"Dankort"|"MasterCard"|"Visa", return_url?: string}
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --entity-use-code: string # The Avalara AvaTax value that can be passed to identify the customer type for tax purposes. The range of values can be A - R (more info at Avalara). Value is case-sensitive.
  --bill-date: string # The preferred billing date for the account. This date will be used as the billing date for when activating new subscriptions on the account. (format: date-time)
]: any -> record<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: table<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: table<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string>, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, billing_info: record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: list<record>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, entity_use_code: string, bill_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let body = {username: $username, email: $email, preferred_locale: $preferred_locale, preferred_time_zone: $preferred_time_zone, cc_emails: $cc_emails, first_name: $first_name, last_name: $last_name, company: $company, vat_number: $vat_number, tax_exempt: $tax_exempt, exemption_certificate: $exemption_certificate, override_business_entity_id: $override_business_entity_id, parent_account_code: $parent_account_code, parent_account_id: $parent_account_id, bill_to: $bill_to, transaction_type: $transaction_type, dunning_campaign_id: $dunning_campaign_id, invoice_template_id: $invoice_template_id, address: $address, billing_info: $billing_info, custom_fields: $custom_fields, entity_use_code: $entity_use_code, bill_date: $bill_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate an account
#
# DELETE /accounts/{account_id}
# operationId: deactivate_account
export def "accounts account-by-account_id-2" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: table<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: table<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string>, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, billing_info: record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: list<record>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, entity_use_code: string, bill_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redact an account (GDPR Right to Erasure)
#
# PUT /accounts/{account_id}/redact
# operationId: redact_account
export def "accounts-redact account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: table<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: table<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string>, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, billing_info: record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: list<record>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, entity_use_code: string, bill_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/redact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an account's acquisition data
#
# GET /accounts/{account_id}/acquisition
# operationId: get_account_acquisition
export def "accounts-acquisition acquisition-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cost: record<currency: string, amount: float>, channel: string, subchannel: string, campaign: string, acquired_at: string, id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/acquisition")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account's acquisition data
#
# PUT /accounts/{account_id}/acquisition
# operationId: update_account_acquisition
# --cost shape: {currency?: string, amount?: float}
export def "accounts-acquisition acquisition-by-account_id-1" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cost: record # shape: {currency?: string, amount?: float}
  --channel: string@channel-completer
  --subchannel: string # An arbitrary subchannel string representing a distinction/subcategory within a broader channel.
  --campaign: string # An arbitrary identifier for the marketing campaign that led to the acquisition of this account.
  --acquired-at: string # Date the account was first created if different than the account.created_at. ie Importing accounts. (format: date-time)
]: any -> record<cost: record<currency: string, amount: float>, channel: string, subchannel: string, campaign: string, acquired_at: string, id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/acquisition")
  let body = {cost: $cost, channel: $channel, subchannel: $subchannel, campaign: $campaign, acquired_at: $acquired_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an account's acquisition data
#
# DELETE /accounts/{account_id}/acquisition
# operationId: remove_account_acquisition
export def "accounts-acquisition acquisition-by-account_id-2" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/acquisition")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reactivate an inactive account
#
# PUT /accounts/{account_id}/reactivate
# operationId: reactivate_account
export def "accounts-reactivate account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: table<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: table<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string>, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, billing_info: record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: list<record>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, entity_use_code: string, bill_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/reactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an account's balance and past due status
#
# GET /accounts/{account_id}/balance
# operationId: get_account_balance
export def "accounts-balance balance" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, past_due: bool, balances: table<currency: string, amount: float, processing_prepayment_amount: float, available_credit_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an account's billing information
#
# GET /accounts/{account_id}/billing_info
# operationId: get_billing_info
export def "accounts-billing-info info-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: table<token: string, reference_type: string>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set an account's billing information
#
# PUT /accounts/{account_id}/billing_info
# operationId: update_billing_info
# --address shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
# --payment_gateway_references item shape: {token?: string, reference_type?: "stripe_confirmation_token"|"upi_vpa"}
# --gateway_attributes shape: {account_reference?: string}
export def "accounts-billing-info info-by-account_id-1" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --token-id: string # A token [generated by Recurly.js](https://recurly.com/developers/reference/recurly-js/#getting-a-token).
  --first-name: string
  --last-name: string
  --company: string
  --address: record # shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
  --number: string # Credit card number, spaces and dashes are accepted.
  --month: string
  --year: string
  --cvv: string # *STRONGLY RECOMMENDED*
  --currency: string # 3-letter ISO 4217 currency code.
  --vat-number: string
  --ip-address: string # *STRONGLY RECOMMENDED* Customer's IP address when updating their billing information.
  --gateway-token: string
  --gateway-code: string
  --payment-gateway-references: list # Array of Payment Gateway References, each a reference to a third-party gateway object of varying types. — item shape: {token?: string, reference_type?: "stripe_confirmation_token"|"upi_vpa"}
  --gateway-attributes: record # Additional attributes to send to the gateway. — shape: {account_reference?: string}
  --amazon-billing-agreement-id: string # Only supported on Amazon V1. For Amazon V2, use token_id with Recurly.js.
  --paypal-billing-agreement-id: string
  --roku-billing-agreement-id: string
  --fraud-session-id: string
  --adyen-risk-profile-reference-id: string # The Adyen Risk Profile Reference ID is used to identify the risk profile for the payment method.
  --transaction-type: string@transaction-type-completer
  --three-d-secure-action-result-token-id: string # A token generated by Recurly.js after completing a 3-D Secure device fingerprinting or authentication challenge.
  --iban: string # The International Bank Account Number, up to 34 alphanumeric characters comprising a country code; two check digits; and a number that includes the domestic bank account number, branch identifier, and potential routing information
  --name-on-account: string # The name associated with the bank account (ACH, SEPA, Bacs only)
  --account-number: string # The bank account number. (ACH, Bacs only)
  --routing-number: string # The bank's rounting number. (ACH only)
  --sort-code: string # Bank identifier code for UK based banks. Required for Bacs based billing infos. (Bacs only)
  --type: string@type-completer # The payment method type for a non-credit card based billing info. `bacs`, `becs`, `pix-automatico`, `mercadopago` are the only accepted values.
  --account-type: string@account-type-completer # The bank account type. (ACH only)
  --tax-identifier: string # Tax identifier is required if adding a billing info that is a consumer card in Brazil or in Argentina. This would be the customer's CPF/CNPJ (Brazil) and CUIT (Argentina). CPF, CNPJ and CUIT are tax identifiers for all residents who pay taxes in Brazil and Argentina respectively.
  --tax-identifier-type: string@tax-identifier-type-completer
  --primary-payment-method: oneof<nothing, bool> # The `primary_payment_method` field is used to designate the primary billing info on the account. The first billing info created on an account will always become primary. Adding additional billing infos provides the flexibility to mark another billing info as primary, or adding additional non-primary billing infos. This can be accomplished by passing the `primary_payment_method` with a value of `true`. When adding billing infos via the billing_info and /accounts endpoints, this value is not permitted, and will return an error if provided.
  --backup-payment-method: oneof<nothing, bool> # The `backup_payment_method` field is used to designate a billing info as a backup on the account that will be tried if the initial billing info used for an invoice is declined. All payment methods, including the billing info marked `primary_payment_method` can be set as a backup. An account can have a maximum of 1 backup, if a user sets a different payment method as a backup, the existing backup will no longer be marked as such.
  --external-hpp-type: string@external-hpp-type-completer # Use for Adyen HPP billing info. This should only be used as part of a pending purchase request, when the billing info is nested inside an account object.
  --online-banking-payment-type: string@online-banking-payment-type-completer # Use for Online Banking billing info. This should only be used as part of a pending purchase request, when the billing info is nested inside an account object.
  --card-type: string@card-type-completer
  --card-network-preference: string@card-network-preference-completer
  --return-url: string # Specifies a URL to which a consumer will be redirected upon completion of a redirect payment flow. Only redirect payment flows operating through Adyen Components will utilize this return URL.
]: any -> record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: table<token: string, reference_type: string>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_info")
  let body = {token_id: $token_id, first_name: $first_name, last_name: $last_name, company: $company, address: $address, number: $number, month: $month, year: $year, cvv: $cvv, currency: $currency, vat_number: $vat_number, ip_address: $ip_address, gateway_token: $gateway_token, gateway_code: $gateway_code, payment_gateway_references: $payment_gateway_references, gateway_attributes: $gateway_attributes, amazon_billing_agreement_id: $amazon_billing_agreement_id, paypal_billing_agreement_id: $paypal_billing_agreement_id, roku_billing_agreement_id: $roku_billing_agreement_id, fraud_session_id: $fraud_session_id, adyen_risk_profile_reference_id: $adyen_risk_profile_reference_id, transaction_type: $transaction_type, three_d_secure_action_result_token_id: $three_d_secure_action_result_token_id, iban: $iban, name_on_account: $name_on_account, account_number: $account_number, routing_number: $routing_number, sort_code: $sort_code, type: $type, account_type: $account_type, tax_identifier: $tax_identifier, tax_identifier_type: $tax_identifier_type, primary_payment_method: $primary_payment_method, backup_payment_method: $backup_payment_method, external_hpp_type: $external_hpp_type, online_banking_payment_type: $online_banking_payment_type, card_type: $card_type, card_network_preference: $card_network_preference, return_url: $return_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an account's billing information
#
# DELETE /accounts/{account_id}/billing_info
# operationId: remove_billing_info
export def "accounts-billing-info info-by-account_id-2" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify an account's credit card billing information
#
# POST /accounts/{account_id}/billing_info/verify
# operationId: verify_billing_info
export def "accounts-billing-info-verify info" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gateway-code: string # An identifier for a specific payment gateway.
  --three-d-secure-action-result-token-id: string # A token generated by Recurly.js after completing a 3-D Secure device fingerprinting or authentication challenge.
]: any -> record<id: string, object: string, uuid: string, original_transaction_id: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, initiator: string, invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, merchant_reason_code: string, voided_by_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, subscription_ids: list<string>, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record<first_name: string, last_name: string>, collection_method: string, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record<id: string, object: string, type: string, name: string>, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record<object: string, score: int, decision: string, reference: string, risk_rules_triggered: list<record>>, next_action: record<type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_info/verify")
  let body = {gateway_code: $gateway_code, three_d_secure_action_result_token_id: $three_d_secure_action_result_token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify an account's credit card billing cvv
#
# POST /accounts/{account_id}/billing_info/verify_cvv
# operationId: verify_billing_info_cvv
export def "accounts-billing-info-verify-cvv cvv" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --verification-value: string # Unique security code for a credit card.
  --gateway-code: string # An identifier for a specific payment gateway.
  --three-d-secure-action-result-token-id: string # A token generated by Recurly.js after completing a 3-D Secure device fingerprinting or authentication challenge.
  --token-id: string # A token [generated by Recurly.js](https://recurly.com/developers/reference/recurly-js/#getting-a-token).
]: any -> record<id: string, object: string, uuid: string, original_transaction_id: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, initiator: string, invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, merchant_reason_code: string, voided_by_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, subscription_ids: list<string>, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record<first_name: string, last_name: string>, collection_method: string, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record<id: string, object: string, type: string, name: string>, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record<object: string, score: int, decision: string, reference: string, risk_rules_triggered: list<record>>, next_action: record<type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_info/verify_cvv")
  let body = {verification_value: $verification_value, gateway_code: $gateway_code, three_d_secure_action_result_token_id: $three_d_secure_action_result_token_id, token_id: $token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of billing information associated with an account
#
# GET /accounts/{account_id}/billing_infos
# operationId: list_billing_infos
export def "accounts-billing-infos infos" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record, vat_number: string, valid: bool, payment_method: record, fraud: record, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: list, created_at: string, updated_at: string, updated_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/billing_infos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add new billing information on an account
#
# POST /accounts/{account_id}/billing_infos
# operationId: create_billing_info
# --address shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
# --payment_gateway_references item shape: {token?: string, reference_type?: "stripe_confirmation_token"|"upi_vpa"}
# --gateway_attributes shape: {account_reference?: string}
export def "accounts-billing-infos info-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --token-id: string # A token [generated by Recurly.js](https://recurly.com/developers/reference/recurly-js/#getting-a-token).
  --first-name: string
  --last-name: string
  --company: string
  --address: record # shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
  --number: string # Credit card number, spaces and dashes are accepted.
  --month: string
  --year: string
  --cvv: string # *STRONGLY RECOMMENDED*
  --currency: string # 3-letter ISO 4217 currency code.
  --vat-number: string
  --ip-address: string # *STRONGLY RECOMMENDED* Customer's IP address when updating their billing information.
  --gateway-token: string
  --gateway-code: string
  --payment-gateway-references: list # Array of Payment Gateway References, each a reference to a third-party gateway object of varying types. — item shape: {token?: string, reference_type?: "stripe_confirmation_token"|"upi_vpa"}
  --gateway-attributes: record # Additional attributes to send to the gateway. — shape: {account_reference?: string}
  --amazon-billing-agreement-id: string # Only supported on Amazon V1. For Amazon V2, use token_id with Recurly.js.
  --paypal-billing-agreement-id: string
  --roku-billing-agreement-id: string
  --fraud-session-id: string
  --adyen-risk-profile-reference-id: string # The Adyen Risk Profile Reference ID is used to identify the risk profile for the payment method.
  --transaction-type: string@transaction-type-completer
  --three-d-secure-action-result-token-id: string # A token generated by Recurly.js after completing a 3-D Secure device fingerprinting or authentication challenge.
  --iban: string # The International Bank Account Number, up to 34 alphanumeric characters comprising a country code; two check digits; and a number that includes the domestic bank account number, branch identifier, and potential routing information
  --name-on-account: string # The name associated with the bank account (ACH, SEPA, Bacs only)
  --account-number: string # The bank account number. (ACH, Bacs only)
  --routing-number: string # The bank's rounting number. (ACH only)
  --sort-code: string # Bank identifier code for UK based banks. Required for Bacs based billing infos. (Bacs only)
  --type: string@type-completer # The payment method type for a non-credit card based billing info. `bacs`, `becs`, `pix-automatico`, `mercadopago` are the only accepted values.
  --account-type: string@account-type-completer # The bank account type. (ACH only)
  --tax-identifier: string # Tax identifier is required if adding a billing info that is a consumer card in Brazil or in Argentina. This would be the customer's CPF/CNPJ (Brazil) and CUIT (Argentina). CPF, CNPJ and CUIT are tax identifiers for all residents who pay taxes in Brazil and Argentina respectively.
  --tax-identifier-type: string@tax-identifier-type-completer
  --primary-payment-method: oneof<nothing, bool> # The `primary_payment_method` field is used to designate the primary billing info on the account. The first billing info created on an account will always become primary. Adding additional billing infos provides the flexibility to mark another billing info as primary, or adding additional non-primary billing infos. This can be accomplished by passing the `primary_payment_method` with a value of `true`. When adding billing infos via the billing_info and /accounts endpoints, this value is not permitted, and will return an error if provided.
  --backup-payment-method: oneof<nothing, bool> # The `backup_payment_method` field is used to designate a billing info as a backup on the account that will be tried if the initial billing info used for an invoice is declined. All payment methods, including the billing info marked `primary_payment_method` can be set as a backup. An account can have a maximum of 1 backup, if a user sets a different payment method as a backup, the existing backup will no longer be marked as such.
  --external-hpp-type: string@external-hpp-type-completer # Use for Adyen HPP billing info. This should only be used as part of a pending purchase request, when the billing info is nested inside an account object.
  --online-banking-payment-type: string@online-banking-payment-type-completer # Use for Online Banking billing info. This should only be used as part of a pending purchase request, when the billing info is nested inside an account object.
  --card-type: string@card-type-completer
  --card-network-preference: string@card-network-preference-completer
  --return-url: string # Specifies a URL to which a consumer will be redirected upon completion of a redirect payment flow. Only redirect payment flows operating through Adyen Components will utilize this return URL.
]: any -> record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: table<token: string, reference_type: string>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_infos")
  let body = {token_id: $token_id, first_name: $first_name, last_name: $last_name, company: $company, address: $address, number: $number, month: $month, year: $year, cvv: $cvv, currency: $currency, vat_number: $vat_number, ip_address: $ip_address, gateway_token: $gateway_token, gateway_code: $gateway_code, payment_gateway_references: $payment_gateway_references, gateway_attributes: $gateway_attributes, amazon_billing_agreement_id: $amazon_billing_agreement_id, paypal_billing_agreement_id: $paypal_billing_agreement_id, roku_billing_agreement_id: $roku_billing_agreement_id, fraud_session_id: $fraud_session_id, adyen_risk_profile_reference_id: $adyen_risk_profile_reference_id, transaction_type: $transaction_type, three_d_secure_action_result_token_id: $three_d_secure_action_result_token_id, iban: $iban, name_on_account: $name_on_account, account_number: $account_number, routing_number: $routing_number, sort_code: $sort_code, type: $type, account_type: $account_type, tax_identifier: $tax_identifier, tax_identifier_type: $tax_identifier_type, primary_payment_method: $primary_payment_method, backup_payment_method: $backup_payment_method, external_hpp_type: $external_hpp_type, online_banking_payment_type: $online_banking_payment_type, card_type: $card_type, card_network_preference: $card_network_preference, return_url: $return_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a billing info
#
# GET /accounts/{account_id}/billing_infos/{billing_info_id}
# operationId: get_a_billing_info
export def "accounts-billing-infos info-by-account_id-billing_info_id" [
  account_id: string
  billing_info_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: table<token: string, reference_type: string>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_infos/($billing_info_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account's billing information
#
# PUT /accounts/{account_id}/billing_infos/{billing_info_id}
# operationId: update_a_billing_info
# --address shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
# --payment_gateway_references item shape: {token?: string, reference_type?: "stripe_confirmation_token"|"upi_vpa"}
# --gateway_attributes shape: {account_reference?: string}
export def "accounts-billing-infos info-by-account_id-billing_info_id-1" [
  account_id: string
  billing_info_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --token-id: string # A token [generated by Recurly.js](https://recurly.com/developers/reference/recurly-js/#getting-a-token).
  --first-name: string
  --last-name: string
  --company: string
  --address: record # shape: {phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string}
  --number: string # Credit card number, spaces and dashes are accepted.
  --month: string
  --year: string
  --cvv: string # *STRONGLY RECOMMENDED*
  --currency: string # 3-letter ISO 4217 currency code.
  --vat-number: string
  --ip-address: string # *STRONGLY RECOMMENDED* Customer's IP address when updating their billing information.
  --gateway-token: string
  --gateway-code: string
  --payment-gateway-references: list # Array of Payment Gateway References, each a reference to a third-party gateway object of varying types. — item shape: {token?: string, reference_type?: "stripe_confirmation_token"|"upi_vpa"}
  --gateway-attributes: record # Additional attributes to send to the gateway. — shape: {account_reference?: string}
  --amazon-billing-agreement-id: string # Only supported on Amazon V1. For Amazon V2, use token_id with Recurly.js.
  --paypal-billing-agreement-id: string
  --roku-billing-agreement-id: string
  --fraud-session-id: string
  --adyen-risk-profile-reference-id: string # The Adyen Risk Profile Reference ID is used to identify the risk profile for the payment method.
  --transaction-type: string@transaction-type-completer
  --three-d-secure-action-result-token-id: string # A token generated by Recurly.js after completing a 3-D Secure device fingerprinting or authentication challenge.
  --iban: string # The International Bank Account Number, up to 34 alphanumeric characters comprising a country code; two check digits; and a number that includes the domestic bank account number, branch identifier, and potential routing information
  --name-on-account: string # The name associated with the bank account (ACH, SEPA, Bacs only)
  --account-number: string # The bank account number. (ACH, Bacs only)
  --routing-number: string # The bank's rounting number. (ACH only)
  --sort-code: string # Bank identifier code for UK based banks. Required for Bacs based billing infos. (Bacs only)
  --type: string@type-completer # The payment method type for a non-credit card based billing info. `bacs`, `becs`, `pix-automatico`, `mercadopago` are the only accepted values.
  --account-type: string@account-type-completer # The bank account type. (ACH only)
  --tax-identifier: string # Tax identifier is required if adding a billing info that is a consumer card in Brazil or in Argentina. This would be the customer's CPF/CNPJ (Brazil) and CUIT (Argentina). CPF, CNPJ and CUIT are tax identifiers for all residents who pay taxes in Brazil and Argentina respectively.
  --tax-identifier-type: string@tax-identifier-type-completer
  --primary-payment-method: oneof<nothing, bool> # The `primary_payment_method` field is used to designate the primary billing info on the account. The first billing info created on an account will always become primary. Adding additional billing infos provides the flexibility to mark another billing info as primary, or adding additional non-primary billing infos. This can be accomplished by passing the `primary_payment_method` with a value of `true`. When adding billing infos via the billing_info and /accounts endpoints, this value is not permitted, and will return an error if provided.
  --backup-payment-method: oneof<nothing, bool> # The `backup_payment_method` field is used to designate a billing info as a backup on the account that will be tried if the initial billing info used for an invoice is declined. All payment methods, including the billing info marked `primary_payment_method` can be set as a backup. An account can have a maximum of 1 backup, if a user sets a different payment method as a backup, the existing backup will no longer be marked as such.
  --external-hpp-type: string@external-hpp-type-completer # Use for Adyen HPP billing info. This should only be used as part of a pending purchase request, when the billing info is nested inside an account object.
  --online-banking-payment-type: string@online-banking-payment-type-completer # Use for Online Banking billing info. This should only be used as part of a pending purchase request, when the billing info is nested inside an account object.
  --card-type: string@card-type-completer
  --card-network-preference: string@card-network-preference-completer
  --return-url: string # Specifies a URL to which a consumer will be redirected upon completion of a redirect payment flow. Only redirect payment flows operating through Adyen Components will utilize this return URL.
]: any -> record<id: string, object: string, account_id: string, first_name: string, last_name: string, company: string, address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, vat_number: string, valid: bool, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, fraud: record<score: int, decision: string, risk_rules_triggered: record>, primary_payment_method: bool, backup_payment_method: bool, payment_gateway_references: table<token: string, reference_type: string>, created_at: string, updated_at: string, updated_by: record<ip: string, country: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_infos/($billing_info_id)")
  let body = {token_id: $token_id, first_name: $first_name, last_name: $last_name, company: $company, address: $address, number: $number, month: $month, year: $year, cvv: $cvv, currency: $currency, vat_number: $vat_number, ip_address: $ip_address, gateway_token: $gateway_token, gateway_code: $gateway_code, payment_gateway_references: $payment_gateway_references, gateway_attributes: $gateway_attributes, amazon_billing_agreement_id: $amazon_billing_agreement_id, paypal_billing_agreement_id: $paypal_billing_agreement_id, roku_billing_agreement_id: $roku_billing_agreement_id, fraud_session_id: $fraud_session_id, adyen_risk_profile_reference_id: $adyen_risk_profile_reference_id, transaction_type: $transaction_type, three_d_secure_action_result_token_id: $three_d_secure_action_result_token_id, iban: $iban, name_on_account: $name_on_account, account_number: $account_number, routing_number: $routing_number, sort_code: $sort_code, type: $type, account_type: $account_type, tax_identifier: $tax_identifier, tax_identifier_type: $tax_identifier_type, primary_payment_method: $primary_payment_method, backup_payment_method: $backup_payment_method, external_hpp_type: $external_hpp_type, online_banking_payment_type: $online_banking_payment_type, card_type: $card_type, card_network_preference: $card_network_preference, return_url: $return_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an account's billing information
#
# DELETE /accounts/{account_id}/billing_infos/{billing_info_id}
# operationId: remove_a_billing_info
export def "accounts-billing-infos info-by-account_id-billing_info_id-2" [
  account_id: string
  billing_info_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_infos/($billing_info_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify a billing information's credit card
#
# POST /accounts/{account_id}/billing_infos/{billing_info_id}/verify
# operationId: verify_billing_infos
export def "accounts-billing-infos-verify infos" [
  account_id: string
  billing_info_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gateway-code: string # An identifier for a specific payment gateway.
  --three-d-secure-action-result-token-id: string # A token generated by Recurly.js after completing a 3-D Secure device fingerprinting or authentication challenge.
]: any -> record<id: string, object: string, uuid: string, original_transaction_id: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, initiator: string, invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, merchant_reason_code: string, voided_by_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, subscription_ids: list<string>, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record<first_name: string, last_name: string>, collection_method: string, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record<id: string, object: string, type: string, name: string>, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record<object: string, score: int, decision: string, reference: string, risk_rules_triggered: list<record>>, next_action: record<type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_infos/($billing_info_id)/verify")
  let body = {gateway_code: $gateway_code, three_d_secure_action_result_token_id: $three_d_secure_action_result_token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify a billing information's credit card cvv
#
# POST /accounts/{account_id}/billing_infos/{billing_info_id}/verify_cvv
# operationId: verify_billing_infos_cvv
export def "accounts-billing-infos-verify-cvv cvv" [
  account_id: string
  billing_info_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --verification-value: string # Unique security code for a credit card.
  --gateway-code: string # An identifier for a specific payment gateway.
  --three-d-secure-action-result-token-id: string # A token generated by Recurly.js after completing a 3-D Secure device fingerprinting or authentication challenge.
  --token-id: string # A token [generated by Recurly.js](https://recurly.com/developers/reference/recurly-js/#getting-a-token).
]: any -> record<id: string, object: string, uuid: string, original_transaction_id: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, initiator: string, invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, merchant_reason_code: string, voided_by_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, subscription_ids: list<string>, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record<first_name: string, last_name: string>, collection_method: string, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record<id: string, object: string, type: string, name: string>, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record<object: string, score: int, decision: string, reference: string, risk_rules_triggered: list<record>>, next_action: record<type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/billing_infos/($billing_info_id)/verify_cvv")
  let body = {verification_value: $verification_value, gateway_code: $gateway_code, three_d_secure_action_result_token_id: $three_d_secure_action_result_token_id, token_id: $token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the coupon redemptions for an account
#
# GET /accounts/{account_id}/coupon_redemptions
# operationId: list_account_coupon_redemptions
export def "accounts-coupon-redemptions redemptions" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --state: string@state-completer # Filter by state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, account: record, subscription_id: string, coupon: record, state: string, remaining_duration: record, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/coupon_redemptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the coupon redemptions that are active on an account
#
# GET /accounts/{account_id}/coupon_redemptions/active
# operationId: list_active_coupon_redemptions
export def "accounts-coupon-redemptions-active redemptions" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, account: record, subscription_id: string, coupon: record, state: string, remaining_duration: record, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/coupon_redemptions/active")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate an active coupon redemption on an account or subscription
#
# POST /accounts/{account_id}/coupon_redemptions/active
# operationId: create_coupon_redemption
export def "accounts-coupon-redemptions-active redemption-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  coupon_id: string
  --currency: string # 3-letter ISO 4217 currency code.
  --subscription-id: string
]: any -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, subscription_id: string, coupon: record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: list<record>, items: list<record>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list, trial: record>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string>, state: string, remaining_duration: record<type: string, expires_at: string>, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/coupon_redemptions/active")
  let body = {coupon_id: $coupon_id, currency: $currency, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the active coupon redemption from an account
#
# DELETE /accounts/{account_id}/coupon_redemptions/active
# operationId: remove_coupon_redemption
export def "accounts-coupon-redemptions-active redemption-by-account_id-1" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, subscription_id: string, coupon: record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: list<record>, items: list<record>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list, trial: record>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string>, state: string, remaining_duration: record<type: string, expires_at: string>, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/coupon_redemptions/active")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show the coupon redemption
#
# GET /accounts/{account_id}/coupon_redemptions/{coupon_redemption_id}
# operationId: get_coupon_redemption
export def "accounts-coupon-redemptions redemption" [
  account_id: string
  coupon_redemption_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, subscription_id: string, coupon: record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: list<record>, items: list<record>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list, trial: record>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string>, state: string, remaining_duration: record<type: string, expires_at: string>, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/coupon_redemptions/($coupon_redemption_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the coupon redemption
#
# DELETE /accounts/{account_id}/coupon_redemptions/{coupon_redemption_id}
# operationId: remove_coupon_redemption_by_id
export def "accounts-coupon-redemptions id" [
  account_id: string
  coupon_redemption_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, subscription_id: string, coupon: record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: list<record>, items: list<record>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list, trial: record>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string>, state: string, remaining_duration: record<type: string, expires_at: string>, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/coupon_redemptions/($coupon_redemption_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an account's credit payments
#
# GET /accounts/{account_id}/credit_payments
# operationId: list_account_credit_payments
export def "accounts-credit-payments payments" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/credit_payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List external accounts for an account
#
# GET /accounts/{account_id}/external_accounts
# operationId: list_account_external_account
export def "accounts-external-accounts account-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, has_more: bool, next: string, data: table<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/external_accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an external account
#
# POST /accounts/{account_id}/external_accounts
# operationId: create_account_external_account
export def "accounts-external-accounts account-by-account_id-1" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_account_code: string # Represents the account code for the external account.
  external_connection_type: string # Represents the connection type. One of the connection types of your enabled App Connectors
]: any -> record<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/external_accounts")
  let body = {external_account_code: $external_account_code, external_connection_type: $external_connection_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an external account for an account
#
# GET /accounts/{account_id}/external_accounts/{external_account_id}
# operationId: get_account_external_account
export def "accounts-external-accounts account-by-account_id-external_account_id" [
  account_id: string
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/external_accounts/($external_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an external account
#
# PUT /accounts/{account_id}/external_accounts/{external_account_id}
# operationId: update_account_external_account
export def "accounts-external-accounts account-by-account_id-external_account_id-1" [
  account_id: string
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-account-code: string # Represents the account code for the external account.
  --external-connection-type: string # Represents the connection type. One of the connection types of your enabled App Connectors
]: any -> record<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/external_accounts/($external_account_id)")
  let body = {external_account_code: $external_account_code, external_connection_type: $external_connection_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an external account for an account
#
# DELETE /accounts/{account_id}/external_accounts/{external_account_id}
# operationId: delete_account_external_account
export def "accounts-external-accounts account-by-account_id-external_account_id-2" [
  account_id: string
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, external_account_code: string, external_connection_type: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/external_accounts/($external_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the external invoices on an account
#
# GET /accounts/{account_id}/external_invoices
# operationId: list_account_external_invoices
export def "accounts-external-invoices invoices" [
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, account: record, external_subscription: record, external_id: string, state: string, total: string, currency: string, line_items: list, purchased_at: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/external_invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an account's invoices
#
# GET /accounts/{account_id}/invoices
# operationId: list_account_invoices
export def "accounts-invoices invoices" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --state: string@state-completer-1 # Invoice state. (default: all)
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --type: string@type-completer-1 # Filter by type when: - `type=charge`, only charge invoices will be returned. - `type=credit`, only credit invoices will be returned. - `type=non-legacy`, only charge and credit invoices will be returned. - `type=legacy`, only legacy invoices will be returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invoice for pending line items
#
# POST /accounts/{account_id}/invoices
# operationId: create_invoice
# --credit_application_policy shape: {mode: "all"|"none", allowed_origins?: list}
export def "accounts-invoices invoice" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currency: string # 3-letter ISO 4217 currency code.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer which will be assigned to the invoice. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer which will be assigned to the invoice. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --collection-method: string@collection-method-completer
  --charge-customer-notes: string # This will default to the Customer Notes text specified on the Invoice Settings for charge invoices. Specify custom notes to add or override Customer Notes on charge invoices.
  --credit-customer-notes: string # This will default to the Customer Notes text specified on the Invoice Settings for credit invoices. Specify customer notes to add or override Customer Notes on credit invoices.
  --net-terms: int # Integer paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. For `manual` collection method, an additional 24 hours is added to ensure the customer has the entire last day to make payment before becoming past due. For example:  If an invoice is due `net 0`, it is due 'On Receipt' and will become past due 24 hours after it's created. If an invoice is due `net 30`, it will become past due at 31 days exactly. If an invoice is due `eom 30`, it will become past due 31 days from the last day of the current month.  For `automatic` collection method, the additional 24 hours is not added. For example, On-Receipt is due immediately, and `net 30` will become due exactly 30 days from invoice generation, at which point Recurly will attempt collection. When `eom` Net Terms Type is passed, the value for `Net Terms` is restricted to `0, 15, 30, 45, 60, or 90`.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --credit-application-policy: record # Controls whether credit invoices are automatically applied to new invoices. The `mode` field determines the application behavior. When mode is `all`, the optional `allowed_origins` array can restrict which credit invoice origins are applied. — shape: {mode: "all"|"none", allowed_origins?: list}
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --terms-and-conditions: string # This will default to the Terms and Conditions text specified on the Invoice Settings page in your Recurly admin. Specify custom notes to add or override Terms and Conditions.
  --vat-reverse-charge-notes: string # VAT Reverse Charge Notes only appear if you have EU VAT enabled or are using your own Avalara AvaTax account and the customer is in the EU, has a VAT number, and is in a different country than your own. This will default to the VAT Reverse Charge Notes text specified on the Tax Settings page in your Recurly admin, unless custom notes were created with the original subscription.
  --vertex-transaction-type: string@vertex-transaction-type-completer # Used by Vertex for tax calculations. Possible values are sale, rental, lease.
]: any -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/invoices")
  let body = {currency: $currency, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, collection_method: $collection_method, charge_customer_notes: $charge_customer_notes, credit_customer_notes: $credit_customer_notes, net_terms: $net_terms, net_terms_type: $net_terms_type, credit_application_policy: $credit_application_policy, po_number: $po_number, terms_and_conditions: $terms_and_conditions, vat_reverse_charge_notes: $vat_reverse_charge_notes, vertex_transaction_type: $vertex_transaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preview new invoice for pending line items
#
# POST /accounts/{account_id}/invoices/preview
# operationId: preview_invoice
# --credit_application_policy shape: {mode: "all"|"none", allowed_origins?: list}
export def "accounts-invoices-preview invoice" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currency: string # 3-letter ISO 4217 currency code.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer which will be assigned to the invoice. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer which will be assigned to the invoice. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --collection-method: string@collection-method-completer
  --charge-customer-notes: string # This will default to the Customer Notes text specified on the Invoice Settings for charge invoices. Specify custom notes to add or override Customer Notes on charge invoices.
  --credit-customer-notes: string # This will default to the Customer Notes text specified on the Invoice Settings for credit invoices. Specify customer notes to add or override Customer Notes on credit invoices.
  --net-terms: int # Integer paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. For `manual` collection method, an additional 24 hours is added to ensure the customer has the entire last day to make payment before becoming past due. For example:  If an invoice is due `net 0`, it is due 'On Receipt' and will become past due 24 hours after it's created. If an invoice is due `net 30`, it will become past due at 31 days exactly. If an invoice is due `eom 30`, it will become past due 31 days from the last day of the current month.  For `automatic` collection method, the additional 24 hours is not added. For example, On-Receipt is due immediately, and `net 30` will become due exactly 30 days from invoice generation, at which point Recurly will attempt collection. When `eom` Net Terms Type is passed, the value for `Net Terms` is restricted to `0, 15, 30, 45, 60, or 90`.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --credit-application-policy: record # Controls whether credit invoices are automatically applied to new invoices. The `mode` field determines the application behavior. When mode is `all`, the optional `allowed_origins` array can restrict which credit invoice origins are applied. — shape: {mode: "all"|"none", allowed_origins?: list}
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --terms-and-conditions: string # This will default to the Terms and Conditions text specified on the Invoice Settings page in your Recurly admin. Specify custom notes to add or override Terms and Conditions.
  --vat-reverse-charge-notes: string # VAT Reverse Charge Notes only appear if you have EU VAT enabled or are using your own Avalara AvaTax account and the customer is in the EU, has a VAT number, and is in a different country than your own. This will default to the VAT Reverse Charge Notes text specified on the Tax Settings page in your Recurly admin, unless custom notes were created with the original subscription.
  --vertex-transaction-type: string@vertex-transaction-type-completer # Used by Vertex for tax calculations. Possible values are sale, rental, lease.
]: any -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/invoices/preview")
  let body = {currency: $currency, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, collection_method: $collection_method, charge_customer_notes: $charge_customer_notes, credit_customer_notes: $credit_customer_notes, net_terms: $net_terms, net_terms_type: $net_terms_type, credit_application_policy: $credit_application_policy, po_number: $po_number, terms_and_conditions: $terms_and_conditions, vat_reverse_charge_notes: $vat_reverse_charge_notes, vertex_transaction_type: $vertex_transaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List an account's line items
#
# GET /accounts/{account_id}/line_items
# operationId: list_account_line_items
export def "accounts-line-items items" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --original: string@original-completer # Filter by original field.
  --state: string@state-completer-2 # Filter by state field.
  --type: string@type-completer-2 # Filter by type field.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "original" $original "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/line_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new line item for the account
#
# POST /accounts/{account_id}/line_items
# operationId: create_line_item
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
export def "accounts-line-items item" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currency: string # 3-letter ISO 4217 currency code. If `item_code`/`item_id` is part of the request then `currency` is optional, if the site has a single default currency. `currency` is required if `item_code`/`item_id` is present, and there are multiple currencies defined on the site. If `item_code`/`item_id` is not present `currency` is required.
  unit_amount: float # A positive or negative amount with `type=charge` will result in a positive `unit_amount`. A positive or negative amount with `type=credit` will result in a negative `unit_amount`. If `item_code`/`item_id` is present, `unit_amount` can be passed in, to override the `Item`'s `unit_amount`. If `item_code`/`item_id` is not present then `unit_amount` is required.  (format: float)
  --tax-inclusive: oneof<nothing, bool> # Determines whether or not tax is included in the unit amount. The Tax Inclusive Pricing feature (separate from the Mixed Tax Pricing feature) must be enabled to use this flag. (default: false)
  --quantity: int # This number will be multiplied by the unit amount to compute the subtotal before any discounts or taxes. (default: 1)
  --description: string # Description that appears on the invoice. If `item_code`/`item_id` is part of the request then `description` must be absent.
  --item-code: string # Unique code to identify an item. Available when the Credit Invoices feature is enabled.
  --item-id: string # System-generated unique identifier for an item. Available when the Credit Invoices feature is enabled.
  --revenue-schedule-type: string@revenue-schedule-type-completer
  type: string@type-completer-2
  --credit-reason-code: string@credit-reason-code-completer
  --accounting-code: string # Accounting Code for the `LineItem`. If `item_code`/`item_id` is part of the request then `accounting_code` must be absent.
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --tax-exempt: oneof<nothing, bool> # `true` exempts tax on charges, `false` applies tax on charges. If not defined, then defaults to the Plan and Site settings. This attribute does not work for credits (negative line items). Credits are always applied post-tax. Pre-tax discounts should use the Coupons feature.
  --avalara-transaction-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the line item is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types. If an `Item` is associated to the `LineItem`, then the `avalara_transaction_type` must be absent.
  --avalara-service-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the line item is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types. If an `Item` is associated to the `LineItem`, then the `avalara_service_type` must be absent.
  --vertex-transaction-type: string@vertex-transaction-type-completer # Used by Vertex for tax calculations. Possible values are sale, rental, lease.
  --tax-code: string # Optional field used by Avalara, Vertex, and Recurly's In-the-Box tax solution to determine taxation rules. You can pass in specific tax codes using any of these tax integrations. For Recurly's In-the-Box tax offering you can also choose to instead use simple values of `unknown`, `physical`, or `digital` tax codes.
  --harmonized-system-code: string # The Harmonized System (HS) code is an internationally standardized system of names and numbers to classify traded products. The HS code, sometimes called Commodity Code, is used by customs authorities around the world to identify products when assessing duties and taxes. The HS code may also be referred to as the tariff code or customs code. Values should contain only digits and decimals. If `item_code`/`item_id` is part of the request then `harmonized_system_code` must be absent.
  --product-code: string # Optional field to track a product code or SKU for the line item. This can be used to later reporting on product purchases. For Vertex tax calculations, this field will be used as the Vertex `product` field. If `item_code`/`item_id` is part of the request then `product_code` must be absent.
  --origin: string@origin-completer
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --start-date: string # If an end date is present, this is value indicates the beginning of a billing time range. If no end date is present it indicates billing for a specific date. Defaults to the current date-time. (format: date-time)
  --end-date: string # If this date is provided, it indicates the end of a time range. (format: date-time)
  --origin-tax-address-source: string@origin-tax-address-source-completer # The source of the address that will be used as the origin in determining taxes. Available only when the site is on an Elite plan. A value of "origin" refers to the "Business entity tax address". A value of "destination" refers to the "Customer tax address". (default: origin)
  --destination-tax-address-source: string@destination-tax-address-source-completer # The source of the address that will be used as the destinaion in determining taxes. Available only when the site is on an Elite plan. A value of "destination" refers to the "Customer tax address". A value of "origin" refers to the "Business entity tax address". (default: destination)
]: any -> record<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: table<object: string, coupon_id: string, coupon_redemption_id: string, order_applied: int, discount_amount: float, currency: string>, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, start_date: string, end_date: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/line_items")
  let body = {currency: $currency, unit_amount: $unit_amount, tax_inclusive: $tax_inclusive, quantity: $quantity, description: $description, item_code: $item_code, item_id: $item_id, revenue_schedule_type: $revenue_schedule_type, type: $type, credit_reason_code: $credit_reason_code, accounting_code: $accounting_code, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, performance_obligation_id: $performance_obligation_id, tax_exempt: $tax_exempt, avalara_transaction_type: $avalara_transaction_type, avalara_service_type: $avalara_service_type, vertex_transaction_type: $vertex_transaction_type, tax_code: $tax_code, harmonized_system_code: $harmonized_system_code, product_code: $product_code, origin: $origin, custom_fields: $custom_fields, start_date: $start_date, end_date: $end_date, origin_tax_address_source: $origin_tax_address_source, destination_tax_address_source: $destination_tax_address_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List an account's notes
#
# GET /accounts/{account_id}/notes
# operationId: list_account_notes
export def "accounts-notes notes" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, account_id: string, user: record, message: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an account note
#
# POST /accounts/{account_id}/notes
# operationId: create_account_note
export def "accounts-notes note-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message: string # The content of the account note.
]: any -> record<id: string, object: string, account_id: string, user: record<id: string, object: string, email: string, first_name: string, last_name: string, time_zone: string, created_at: string, deleted_at: string>, message: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/notes")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an account note
#
# GET /accounts/{account_id}/notes/{account_note_id}
# operationId: get_account_note
export def "accounts-notes note-by-account_id-account_note_id" [
  account_id: string
  account_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, account_id: string, user: record<id: string, object: string, email: string, first_name: string, last_name: string, time_zone: string, created_at: string, deleted_at: string>, message: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/notes/($account_note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an account note
#
# DELETE /accounts/{account_id}/notes/{account_note_id}
# operationId: remove_account_note
export def "accounts-notes note-by-account_id-account_note_id-1" [
  account_id: string
  account_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, message: string, params: table<param: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/notes/($account_note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a list of an account's shipping addresses
#
# GET /accounts/{account_id}/shipping_addresses
# operationId: list_shipping_addresses
export def "accounts-shipping-addresses addresses" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/shipping_addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new shipping address for the account
#
# POST /accounts/{account_id}/shipping_addresses
# operationId: create_shipping_address
export def "accounts-shipping-addresses address-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nickname: string
  first_name: string
  last_name: string
  --company: string
  --email: string
  --vat-number: string
  --phone: string
  street1: string
  --street2: string
  city: string
  --region: string # State or province.
  postal_code: string # Zip or postal code.
  --geo-code: string # Code that represents a geographic entity (location or object). Only returned when Vertex or Avalara for Communications is enabled.
  country: string # Country, 2-letter ISO 3166-1 alpha-2 code.
]: any -> record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/shipping_addresses")
  let body = {nickname: $nickname, first_name: $first_name, last_name: $last_name, company: $company, email: $email, vat_number: $vat_number, phone: $phone, street1: $street1, street2: $street2, city: $city, region: $region, postal_code: $postal_code, geo_code: $geo_code, country: $country} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an account's shipping address
#
# GET /accounts/{account_id}/shipping_addresses/{shipping_address_id}
# operationId: get_shipping_address
export def "accounts-shipping-addresses address-by-account_id-shipping_address_id" [
  account_id: string
  shipping_address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/shipping_addresses/($shipping_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account's shipping address
#
# PUT /accounts/{account_id}/shipping_addresses/{shipping_address_id}
# operationId: update_shipping_address
export def "accounts-shipping-addresses address-by-account_id-shipping_address_id-1" [
  account_id: string
  shipping_address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nickname: string
  --first-name: string
  --last-name: string
  --company: string
  --email: string
  --vat-number: string
  --phone: string
  --street1: string
  --street2: string
  --city: string
  --region: string # State or province.
  --postal-code: string # Zip or postal code.
  --country: string # Country, 2-letter ISO 3166-1 alpha-2 code.
  --geo-code: string # Code that represents a geographic entity (location or object). Only returned when Vertex or Avalara for Communications is enabled.
]: any -> record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/shipping_addresses/($shipping_address_id)")
  let body = {nickname: $nickname, first_name: $first_name, last_name: $last_name, company: $company, email: $email, vat_number: $vat_number, phone: $phone, street1: $street1, street2: $street2, city: $city, region: $region, postal_code: $postal_code, country: $country, geo_code: $geo_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an account's shipping address
#
# DELETE /accounts/{account_id}/shipping_addresses/{shipping_address_id}
# operationId: remove_shipping_address
export def "accounts-shipping-addresses address-by-account_id-shipping_address_id-2" [
  account_id: string
  shipping_address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/shipping_addresses/($shipping_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an account's subscriptions
#
# GET /accounts/{account_id}/subscriptions
# operationId: list_account_subscriptions
export def "accounts-subscriptions subscriptions" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --state: string@state-completer-3 # Filter by state.  - When `state=active`, `state=canceled`, `state=expired`, or `state=future`, subscriptions with states that match the query and only those subscriptions will be returned. - When `state=in_trial`, only subscriptions that have a trial_started_at date earlier than now and a trial_ends_at date later than now will be returned. - When `state=live`, only subscriptions that are in an active, canceled, or future state or are in trial will be returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, account: record, plan: record, state: string, shipping: record, coupon_redemptions: list, pending_change: record, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: list, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: list, add_ons_total: float, subtotal: float, tax: float, tax_info: record, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: list, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an account's transactions
#
# GET /accounts/{account_id}/transactions
# operationId: list_account_transactions
export def "accounts-transactions transactions" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --type: string@type-completer-3 # Filter by type field. The value `payment` will return both `purchase` and `capture` transactions.
  --success: string@success-completer # Filter by success field.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "success" $success "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an account's child accounts
#
# GET /accounts/{account_id}/accounts
# operationId: list_child_accounts
export def "accounts-accounts accounts" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --email: string # Filter for accounts with this exact email address. A blank value will return accounts with both `null` and `""` email addresses. Note that multiple accounts can share one email address.
  --subscriber: oneof<nothing, bool> # Filter for accounts with or without a subscription in the `active`, `canceled`, or `future` state.
  --past-due: string@past-due-completer # Filter for accounts with an invoice in the `past_due` state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: list, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: list, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record, billing_info: record, custom_fields: list, entity_use_code: string, bill_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "subscriber" $subscriber "scalar") (serialize-qp "past_due" $past_due "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's account acquisition data
#
# GET /acquisitions
# operationId: list_account_acquisition
export def "acquisitions acquisition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<cost: record, channel: string, subchannel: string, campaign: string, acquired_at: string, id: string, object: string, account: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acquisitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's coupons
#
# GET /coupons
# operationId: list_coupons
export def "coupons coupons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: list, items: list, redemption_resource: string, discount: record, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coupons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new coupon
#
# POST /coupons
# operationId: create_coupon
# --currencies item shape: {currency?: string, discount?: float}
export def "coupons coupon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The internal name for the coupon.
  --max-redemptions: int # A maximum number of redemptions for the coupon. The coupon will expire when it hits its maximum redemptions.
  --max-redemptions-per-account: int # Redemptions per account is the number of times a specific account can redeem the coupon. Set redemptions per account to `1` if you want to keep customers from gaming the system and getting more than one discount from the coupon campaign.
  --hosted-description: string # This description will show up when a customer redeems a coupon on your Hosted Payment Pages, or if you choose to show the description on your own checkout page.
  --invoice-description: string # Description of the coupon on the invoice.
  --redeem-by-date: string # The date and time the coupon will expire and can no longer be redeemed. Time is always 11:59:59, the end-of-day Pacific time.
  code: string # The code the customer enters to redeem the coupon.
  discount_type: string@discount-type-completer
  --discount-percent: int # The percent of the price discounted by the coupon.  Required if `discount_type` is `percent`.
  --free-trial-unit: string@free-trial-unit-completer
  --free-trial-amount: int # Sets the duration of time the `free_trial_unit` is for. Required if `discount_type` is `free_trial`.
  --currencies: list # Fixed discount currencies by currency. Required if the coupon type is `fixed`. This parameter should contain the coupon discount values — item shape: {currency?: string, discount?: float}
  --applies-to-non-plan-charges: oneof<nothing, bool> # The coupon is valid for one-time, non-plan charges if true. (default: false)
  --applies-to-all-plans: oneof<nothing, bool> # The coupon is valid for all plans if true. If false then `plans` will list the applicable plans. (default: true)
  --applies-to-all-items: oneof<nothing, bool> # To apply coupon to Items in your Catalog, include a list of `item_codes` in the request that the coupon will apply to. Or set value to true to apply to all Items in your Catalog. The following values are not permitted when `applies_to_all_items` is included: `free_trial_amount` and `free_trial_unit`.  (default: false)
  --plan-codes: list # List of plan codes to which this coupon applies. Required if `applies_to_all_plans` is false. Overrides `applies_to_all_plans` when `applies_to_all_plans` is true.
  --item-codes: list # List of item codes to which this coupon applies. Sending `item_codes` is only permitted when `applies_to_all_items` is set to false. The following values are not permitted when `item_codes` is included: `free_trial_amount` and `free_trial_unit`.
  --duration: string@duration-completer
  --temporal-amount: int # If `duration` is "temporal" than `temporal_amount` is an integer which is multiplied by `temporal_unit` to define the duration that the coupon will be applied to invoices for. When `temporal_unit` is "billing_period", this is the number of complete billing cycles.
  --temporal-unit: string@temporal-unit-completer # The temporal unit for the coupon's duration. Used with temporal_amount to define how long the coupon applies. When temporal_unit is billing_period, the coupon applies for temporal_amount complete billing cycles rather than a fixed calendar duration. billing_period requires redemption_resource=subscription.
  --coupon-type: string@coupon-type-completer
  --unique-code-template: string # On a bulk coupon, the template from which unique coupon codes are generated. - You must start the template with your coupon_code wrapped in single quotes. - Outside of single quotes, use a 9 for a character that you want to be a random number. - Outside of single quotes, use an "x" for a character that you want to be a random letter. - Outside of single quotes, use an * for a character that you want to be a random number or letter. - Use single quotes ' ' for characters that you want to remain static. These strings can be alphanumeric and may contain a - _ or +. For example: "'abc-'****'-def'"
  --redemption-resource: string@redemption-resource-completer
]: any -> record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: table<id: string, object: string, code: string, name: string>, items: table<id: string, object: string, code: string, state: string, name: string, description: string>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list<record>, trial: record<unit: string, length: int>>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coupons")
  let body = {name: $name, max_redemptions: $max_redemptions, max_redemptions_per_account: $max_redemptions_per_account, hosted_description: $hosted_description, invoice_description: $invoice_description, redeem_by_date: $redeem_by_date, code: $code, discount_type: $discount_type, discount_percent: $discount_percent, free_trial_unit: $free_trial_unit, free_trial_amount: $free_trial_amount, currencies: $currencies, applies_to_non_plan_charges: $applies_to_non_plan_charges, applies_to_all_plans: $applies_to_all_plans, applies_to_all_items: $applies_to_all_items, plan_codes: $plan_codes, item_codes: $item_codes, duration: $duration, temporal_amount: $temporal_amount, temporal_unit: $temporal_unit, coupon_type: $coupon_type, unique_code_template: $unique_code_template, redemption_resource: $redemption_resource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a coupon
#
# GET /coupons/{coupon_id}
# operationId: get_coupon
export def "coupons coupon-by-coupon_id" [
  coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: table<id: string, object: string, code: string, name: string>, items: table<id: string, object: string, code: string, state: string, name: string, description: string>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list<record>, trial: record<unit: string, length: int>>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($coupon_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an active coupon
#
# PUT /coupons/{coupon_id}
# operationId: update_coupon
export def "coupons coupon-by-coupon_id-1" [
  coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The internal name for the coupon.
  --max-redemptions: int # A maximum number of redemptions for the coupon. The coupon will expire when it hits its maximum redemptions.
  --max-redemptions-per-account: int # Redemptions per account is the number of times a specific account can redeem the coupon. Set redemptions per account to `1` if you want to keep customers from gaming the system and getting more than one discount from the coupon campaign.
  --hosted-description: string # This description will show up when a customer redeems a coupon on your Hosted Payment Pages, or if you choose to show the description on your own checkout page.
  --invoice-description: string # Description of the coupon on the invoice.
  --redeem-by-date: string # The date and time the coupon will expire and can no longer be redeemed. Time is always 11:59:59, the end-of-day Pacific time.
]: any -> record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: table<id: string, object: string, code: string, name: string>, items: table<id: string, object: string, code: string, state: string, name: string, description: string>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list<record>, trial: record<unit: string, length: int>>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($coupon_id)")
  let body = {name: $name, max_redemptions: $max_redemptions, max_redemptions_per_account: $max_redemptions_per_account, hosted_description: $hosted_description, invoice_description: $invoice_description, redeem_by_date: $redeem_by_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Expire a coupon
#
# DELETE /coupons/{coupon_id}
# operationId: deactivate_coupon
export def "coupons coupon-by-coupon_id-2" [
  coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: table<id: string, object: string, code: string, name: string>, items: table<id: string, object: string, code: string, state: string, name: string, description: string>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list<record>, trial: record<unit: string, length: int>>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($coupon_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate unique coupon codes
#
# POST /coupons/{coupon_id}/generate
# operationId: generate_unique_coupon_codes
export def "coupons-generate codes" [
  coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --number-of-unique-codes: int # The quantity of unique coupon codes to generate. A bulk coupon can have up to 100,000 unique codes (or your site's configured limit).
]: any -> record<limit: int, order: string, sort: string, begin_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($coupon_id)/generate")
  let body = {number_of_unique_codes: $number_of_unique_codes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate unique coupon codes synchronously
#
# POST /coupons/{coupon_id}/generate_sync
# operationId: generate_unique_coupon_codes_sync
export def "coupons-generate-sync sync" [
  coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  number_of_unique_codes: int # The quantity of unique coupon codes to generate. A bulk coupon can have up to 100,000 unique codes (or your site's configured limit).
]: any -> record<object: string, unique_coupon_codes: table<id: string, object: string, code: string, state: string, bulk_coupon_id: string, bulk_coupon_code: string, created_at: string, updated_at: string, redeemed_at: string, expired_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($coupon_id)/generate_sync")
  let body = {number_of_unique_codes: $number_of_unique_codes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restore an inactive coupon
#
# PUT /coupons/{coupon_id}/restore
# operationId: restore_coupon
export def "coupons-restore coupon" [
  coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The internal name for the coupon.
  --max-redemptions: int # A maximum number of redemptions for the coupon. The coupon will expire when it hits its maximum redemptions.
  --max-redemptions-per-account: int # Redemptions per account is the number of times a specific account can redeem the coupon. Set redemptions per account to `1` if you want to keep customers from gaming the system and getting more than one discount from the coupon campaign.
  --hosted-description: string # This description will show up when a customer redeems a coupon on your Hosted Payment Pages, or if you choose to show the description on your own checkout page.
  --invoice-description: string # Description of the coupon on the invoice.
  --redeem-by-date: string # The date and time the coupon will expire and can no longer be redeemed. Time is always 11:59:59, the end-of-day Pacific time.
]: any -> record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: table<id: string, object: string, code: string, name: string>, items: table<id: string, object: string, code: string, state: string, name: string, description: string>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list<record>, trial: record<unit: string, length: int>>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($coupon_id)/restore")
  let body = {name: $name, max_redemptions: $max_redemptions, max_redemptions_per_account: $max_redemptions_per_account, hosted_description: $hosted_description, invoice_description: $invoice_description, redeem_by_date: $redeem_by_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List unique coupon codes associated with a bulk coupon
#
# GET /coupons/{coupon_id}/unique_coupon_codes
# operationId: list_unique_coupon_codes
export def "coupons-unique-coupon-codes codes" [
  coupon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --redeemed: string@redeemed-completer # Filter unique coupon codes by redemption status. `true` for redeemed, `false` for not redeemed.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, code: string, state: string, bulk_coupon_id: string, bulk_coupon_code: string, created_at: string, updated_at: string, redeemed_at: string, expired_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "redeemed" $redeemed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coupons/($coupon_id)/unique_coupon_codes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's credit payments
#
# GET /credit_payments
# operationId: list_credit_payments
export def "credit-payments payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/credit_payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a credit payment
#
# GET /credit_payments/{credit_payment_id}
# operationId: get_credit_payment
export def "credit-payments payment" [
  credit_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, action: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, applied_to_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, original_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record<id: string, object: string, uuid: string, original_transaction_id: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, initiator: string, invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, merchant_reason_code: string, voided_by_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, subscription_ids: list<string>, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record<first_name: string, last_name: string>, collection_method: string, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record<id: string, object: string, type: string, name: string>, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record<object: string, score: int, decision: string, reference: string, risk_rules_triggered: list>, next_action: record<type: string, value: string>>, created_at: string, updated_at: string, voided_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credit_payments/($credit_payment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's custom field definitions
#
# GET /custom_field_definitions
# operationId: list_custom_field_definitions
export def "custom-field-definitions definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --related-type: string@related-type-completer # Filter by related type.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, related_type: string, name: string, user_access: string, display_name: string, tooltip: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "related_type" $related_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_field_definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an custom field definition
#
# GET /custom_field_definitions/{custom_field_definition_id}
# operationId: get_custom_field_definition
export def "custom-field-definitions definition" [
  custom_field_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, related_type: string, name: string, user_access: string, display_name: string, tooltip: string, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field_definitions/($custom_field_definition_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new general ledger account
#
# POST /general_ledger_accounts
# operationId: create_general_ledger_account
export def "general-ledger-accounts account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Unique code to identify the ledger account. Each code must start with a letter or number. The following special characters are allowed: `-_.,:`
  --description: string # Optional description.
  --account-type: string@account-type-completer-1
]: any -> record<id: string, object: string, code: string, description: string, account_type: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/general_ledger_accounts")
  let body = {code: $code, description: $description, account_type: $account_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a site's general ledger accounts
#
# GET /general_ledger_accounts
# operationId: list_general_ledger_accounts
export def "general-ledger-accounts accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --account-type: string@account-type-completer-1 # General Ledger Account type by which to filter the response.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, code: string, description: string, account_type: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "account_type" $account_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/general_ledger_accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a general ledger account
#
# GET /general_ledger_accounts/{general_ledger_account_id}
# operationId: get_general_ledger_account
export def "general-ledger-accounts account-by-general_ledger_account_id" [
  general_ledger_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, description: string, account_type: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/general_ledger_accounts/($general_ledger_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a general ledger account
#
# PUT /general_ledger_accounts/{general_ledger_account_id}
# operationId: update_general_ledger_account
export def "general-ledger-accounts account-by-general_ledger_account_id-1" [
  general_ledger_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Unique code to identify the ledger account. Each code must start with a letter or number. The following special characters are allowed: `-_.,:`
  --description: string # Optional description.
]: any -> record<id: string, object: string, code: string, description: string, account_type: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/general_ledger_accounts/($general_ledger_account_id)")
  let body = {code: $code, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Performance Obligation.
#
# GET /performance_obligations/{performance_obligation_id}
# operationId: get_performance_obligation
export def "performance-obligations obligation" [
  performance_obligation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/performance_obligations/($performance_obligation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a site's Performance Obligations
#
# GET /performance_obligations
# operationId: get_performance_obligations
export def "performance-obligations obligations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, name: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/performance_obligations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an invoice template's associated accounts
#
# GET /invoice_templates/{invoice_template_id}/accounts
# operationId: list_invoice_template_accounts
export def "invoice-templates-accounts accounts" [
  invoice_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --email: string # Filter for accounts with this exact email address. A blank value will return accounts with both `null` and `""` email addresses. Note that multiple accounts can share one email address.
  --subscriber: oneof<nothing, bool> # Filter for accounts with or without a subscription in the `active`, `canceled`, or `future` state.
  --past-due: string@past-due-completer # Filter for accounts with an invoice in the `past_due` state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, state: string, hosted_login_token: string, shipping_addresses: list, has_live_subscription: bool, has_active_subscription: bool, has_future_subscription: bool, has_canceled_subscription: bool, has_paused_subscription: bool, has_past_due_invoice: bool, created_at: string, updated_at: string, deleted_at: string, code: string, username: string, email: string, override_business_entity_id: string, preferred_locale: string, preferred_time_zone: string, cc_emails: string, first_name: string, last_name: string, company: string, vat_number: string, tax_exempt: bool, exemption_certificate: string, external_accounts: list, parent_account_id: string, bill_to: string, dunning_campaign_id: string, invoice_template_id: string, address: record, billing_info: record, custom_fields: list, entity_use_code: string, bill_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "subscriber" $subscriber "scalar") (serialize-qp "past_due" $past_due "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invoice_templates/($invoice_template_id)/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's items
#
# GET /items
# operationId: list_items
export def "items items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --state: string@state-completer # Filter by state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, code: string, state: string, name: string, description: string, external_sku: string, accounting_code: string, revenue_schedule_type: string, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, tax_exempt: bool, custom_fields: list, currencies: list, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new item
#
# POST /items
# operationId: create_item
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
# --currencies item shape: {currency: string, unit_amount: float, tax_inclusive?: bool}
export def "items item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # Unique code to identify the item.
  name: string # This name describes your item and will appear on the invoice when it's purchased on a one time basis.
  --description: string # Optional, description.
  --external-sku: string # Optional, stock keeping unit to link the item to other inventory systems.
  --accounting-code: string # Accounting code for invoice line items.
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --avalara-transaction-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the item is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types.
  --avalara-service-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the item is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types.
  --tax-code: string # Optional field used by Avalara, Vertex, and Recurly's In-the-Box tax solution to determine taxation rules. You can pass in specific tax codes using any of these tax integrations. For Recurly's In-the-Box tax offering you can also choose to instead use simple values of `unknown`, `physical`, or `digital` tax codes.
  --harmonized-system-code: string # The Harmonized System (HS) code is an internationally standardized system of names and numbers to classify traded products. The HS code, sometimes called Commodity Code, is used by customs authorities around the world to identify products when assessing duties and taxes. The HS code may also be referred to as the tariff code or customs code. Values should contain only digits and decimals.
  --tax-exempt: oneof<nothing, bool> # `true` exempts tax on the item, `false` applies tax on the item.
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --currencies: list # item shape: {currency: string, unit_amount: float, tax_inclusive?: bool}
]: any -> record<id: string, object: string, code: string, state: string, name: string, description: string, external_sku: string, accounting_code: string, revenue_schedule_type: string, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, tax_exempt: bool, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, currencies: table<currency: string, unit_amount: float, tax_inclusive: bool>, created_at: string, updated_at: string, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/items")
  let body = {code: $code, name: $name, description: $description, external_sku: $external_sku, accounting_code: $accounting_code, revenue_schedule_type: $revenue_schedule_type, performance_obligation_id: $performance_obligation_id, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, avalara_transaction_type: $avalara_transaction_type, avalara_service_type: $avalara_service_type, tax_code: $tax_code, harmonized_system_code: $harmonized_system_code, tax_exempt: $tax_exempt, custom_fields: $custom_fields, currencies: $currencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an item
#
# GET /items/{item_id}
# operationId: get_item
export def "items item-by-item_id" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, state: string, name: string, description: string, external_sku: string, accounting_code: string, revenue_schedule_type: string, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, tax_exempt: bool, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, currencies: table<currency: string, unit_amount: float, tax_inclusive: bool>, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/items/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an active item
#
# PUT /items/{item_id}
# operationId: update_item
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
# --currencies item shape: {currency: string, unit_amount: float, tax_inclusive?: bool}
export def "items item-by-item_id-1" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Unique code to identify the item.
  --name: string # This name describes your item and will appear on the invoice when it's purchased on a one time basis.
  --description: string # Optional, description.
  --external-sku: string # Optional, stock keeping unit to link the item to other inventory systems.
  --accounting-code: string # Accounting code for invoice line items.
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --avalara-transaction-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the item is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types.
  --avalara-service-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the item is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types.
  --tax-code: string # Optional field used by Avalara, Vertex, and Recurly's In-the-Box tax solution to determine taxation rules. You can pass in specific tax codes using any of these tax integrations. For Recurly's In-the-Box tax offering you can also choose to instead use simple values of `unknown`, `physical`, or `digital` tax codes.
  --harmonized-system-code: string # The Harmonized System (HS) code is an internationally standardized system of names and numbers to classify traded products. The HS code, sometimes called Commodity Code, is used by customs authorities around the world to identify products when assessing duties and taxes. The HS code may also be referred to as the tariff code or customs code. Values should contain only digits and decimals.
  --tax-exempt: oneof<nothing, bool> # `true` exempts tax on the item, `false` applies tax on the item.
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --currencies: list # item shape: {currency: string, unit_amount: float, tax_inclusive?: bool}
]: any -> record<id: string, object: string, code: string, state: string, name: string, description: string, external_sku: string, accounting_code: string, revenue_schedule_type: string, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, tax_exempt: bool, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, currencies: table<currency: string, unit_amount: float, tax_inclusive: bool>, created_at: string, updated_at: string, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/items/($item_id)")
  let body = {code: $code, name: $name, description: $description, external_sku: $external_sku, accounting_code: $accounting_code, revenue_schedule_type: $revenue_schedule_type, performance_obligation_id: $performance_obligation_id, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, avalara_transaction_type: $avalara_transaction_type, avalara_service_type: $avalara_service_type, tax_code: $tax_code, harmonized_system_code: $harmonized_system_code, tax_exempt: $tax_exempt, custom_fields: $custom_fields, currencies: $currencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate an item
#
# DELETE /items/{item_id}
# operationId: deactivate_item
export def "items item-by-item_id-2" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, state: string, name: string, description: string, external_sku: string, accounting_code: string, revenue_schedule_type: string, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, tax_exempt: bool, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, currencies: table<currency: string, unit_amount: float, tax_inclusive: bool>, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/items/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reactivate an inactive item
#
# PUT /items/{item_id}/reactivate
# operationId: reactivate_item
export def "items-reactivate item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, state: string, name: string, description: string, external_sku: string, accounting_code: string, revenue_schedule_type: string, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, tax_exempt: bool, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, currencies: table<currency: string, unit_amount: float, tax_inclusive: bool>, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/items/($item_id)/reactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's measured units
#
# GET /measured_units
# operationId: list_measured_unit
export def "measured-units unit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --state: string@state-completer # Filter by state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, name: string, display_name: string, state: string, description: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/measured_units" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new measured unit
#
# POST /measured_units
# operationId: create_measured_unit
export def "measured-units unit-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Unique internal name of the measured unit on your site.
  display_name: string # Display name for the measured unit.
  --description: string # Optional internal description.
]: any -> record<id: string, object: string, name: string, display_name: string, state: string, description: string, created_at: string, updated_at: string, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/measured_units")
  let body = {name: $name, display_name: $display_name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a measured unit
#
# GET /measured_units/{measured_unit_id}
# operationId: get_measured_unit
export def "measured-units unit-by-measured_unit_id" [
  measured_unit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, display_name: string, state: string, description: string, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/measured_units/($measured_unit_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a measured unit
#
# PUT /measured_units/{measured_unit_id}
# operationId: update_measured_unit
export def "measured-units unit-by-measured_unit_id-1" [
  measured_unit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Unique internal name of the measured unit on your site.
  --display-name: string # Display name for the measured unit.
  --description: string # Optional internal description.
]: any -> record<id: string, object: string, name: string, display_name: string, state: string, description: string, created_at: string, updated_at: string, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/measured_units/($measured_unit_id)")
  let body = {name: $name, display_name: $display_name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a measured unit
#
# DELETE /measured_units/{measured_unit_id}
# operationId: remove_measured_unit
export def "measured-units unit-by-measured_unit_id-2" [
  measured_unit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, display_name: string, state: string, description: string, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/measured_units/($measured_unit_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's external products
#
# GET /external_products
# operationId: list_external_products
export def "external-products products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, name: string, plan: record, created_at: string, updated_at: string, external_product_references: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/external_products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an external product
#
# POST /external_products
# operationId: create_external_product
# --external_product_references item shape: {reference_code?: string, external_connection_type?: string}
export def "external-products product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # External product name.
  --plan-id: string # Recurly plan UUID.
  --external-product-references: list # List of external product references of the external product. — item shape: {reference_code?: string, external_connection_type?: string}
]: any -> record<id: string, object: string, name: string, plan: record<id: string, object: string, code: string, name: string>, created_at: string, updated_at: string, external_product_references: table<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/external_products")
  let body = {name: $name, plan_id: $plan_id, external_product_references: $external_product_references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an external product
#
# GET /external_products/{external_product_id}
# operationId: get_external_product
export def "external-products product-by-external_product_id" [
  external_product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, plan: record<id: string, object: string, code: string, name: string>, created_at: string, updated_at: string, external_product_references: table<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_products/($external_product_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an external product
#
# PUT /external_products/{external_product_id}
# operationId: update_external_product
export def "external-products product-by-external_product_id-1" [
  external_product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  plan_id: string # Recurly plan UUID.
]: any -> record<id: string, object: string, name: string, plan: record<id: string, object: string, code: string, name: string>, created_at: string, updated_at: string, external_product_references: table<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_products/($external_product_id)")
  let body = {plan_id: $plan_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate an external product
#
# DELETE /external_products/{external_product_id}
# operationId: deactivate_external_products
export def "external-products products-by-external_product_id" [
  external_product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, plan: record<id: string, object: string, code: string, name: string>, created_at: string, updated_at: string, external_product_references: table<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_products/($external_product_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the external product references for an external product
#
# GET /external_products/{external_product_id}/external_product_references
# operationId: list_external_product_external_product_references
export def "external-products-external-product-references references" [
  external_product_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/external_products/($external_product_id)/external_product_references" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an external product reference on an external product
#
# POST /external_products/{external_product_id}/external_product_references
# operationId: create_external_product_external_product_reference
export def "external-products-external-product-references reference-by-external_product_id" [
  external_product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  reference_code: string # A code which associates the external product to a corresponding object or resource in an external platform like the Apple App Store or Google Play Store.
  external_connection_type: string # Represents the connection type. One of the connection types of your enabled App Connectors
]: any -> record<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_products/($external_product_id)/external_product_references")
  let body = {reference_code: $reference_code, external_connection_type: $external_connection_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an external product reference
#
# GET /external_products/{external_product_id}/external_product_references/{external_product_reference_id}
# operationId: get_external_product_external_product_reference
export def "external-products-external-product-references reference-by-external_product_id-external_product_reference_id" [
  external_product_id: string
  external_product_reference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_products/($external_product_id)/external_product_references/($external_product_reference_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate an external product reference
#
# DELETE /external_products/{external_product_id}/external_product_references/{external_product_reference_id}
# operationId: deactivate_external_product_external_product_reference
export def "external-products-external-product-references reference-by-external_product_id-external_product_reference_id-1" [
  external_product_id: string
  external_product_reference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_products/($external_product_id)/external_product_references/($external_product_reference_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an external subscription
#
# POST /external_subscriptions
# operationId: create_external_subscription
export def "external-subscriptions subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: any
  --external-product-reference: any
  external_id: string # Id of the subscription in the external system, i.e. Apple App Store or Google Play Store.
  --last-purchased: string # When a new billing event occurred on the external subscription in conjunction with a recent billing period, reactivation or upgrade/downgrade. (format: date-time)
  --auto-renew: oneof<nothing, bool> # An indication of whether or not the external subscription will auto-renew at the expiration date. (default: false)
  --state: string # External subscriptions can be active, canceled, expired, past_due, voided, revoked, or paused. (default: active)
  --app-identifier: string # Identifier of the app that generated the external subscription.
  quantity: int # An indication of the quantity of a subscribed item's quantity. (default: 1)
  activated_at: string # When the external subscription was activated in the external platform. (format: date-time)
  expires_at: string # When the external subscription expires in the external platform. (format: date-time)
  --trial-started-at: string # When the external subscription trial period started in the external platform. (format: date-time)
  --trial-ends-at: string # When the external subscription trial period ends in the external platform. (format: date-time)
  --imported: oneof<nothing, bool> # An indication of whether or not the external subscription was being created by a historical data import. (default: false)
]: any -> record<id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, external_product_reference: record<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>, external_payment_phases: table<id: string, object: string, started_at: string, ends_at: string, starting_billing_period_index: int, ending_billing_period_index: int, offer_type: string, offer_name: string, period_count: int, period_length: string, amount: string, currency: string, created_at: string, updated_at: string>, external_id: string, uuid: string, last_purchased: string, auto_renew: bool, in_grace_period: bool, app_identifier: string, quantity: int, state: string, activated_at: string, canceled_at: string, expires_at: string, trial_started_at: string, trial_ends_at: string, test: bool, imported: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/external_subscriptions")
  let body = {account: $account, external_product_reference: $external_product_reference, external_id: $external_id, last_purchased: $last_purchased, auto_renew: $auto_renew, state: $state, app_identifier: $app_identifier, quantity: $quantity, activated_at: $activated_at, expires_at: $expires_at, trial_started_at: $trial_started_at, trial_ends_at: $trial_ends_at, imported: $imported} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the external subscriptions on a site
#
# GET /external_subscriptions
# operationId: list_external_subscriptions
export def "external-subscriptions subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, account: record, external_product_reference: record, external_payment_phases: list, external_id: string, uuid: string, last_purchased: string, auto_renew: bool, in_grace_period: bool, app_identifier: string, quantity: int, state: string, activated_at: string, canceled_at: string, expires_at: string, trial_started_at: string, trial_ends_at: string, test: bool, imported: bool, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/external_subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an external subscription
#
# GET /external_subscriptions/{external_subscription_id}
# operationId: get_external_subscription
export def "external-subscriptions subscription-by-external_subscription_id" [
  external_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, external_product_reference: record<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>, external_payment_phases: table<id: string, object: string, started_at: string, ends_at: string, starting_billing_period_index: int, ending_billing_period_index: int, offer_type: string, offer_name: string, period_count: int, period_length: string, amount: string, currency: string, created_at: string, updated_at: string>, external_id: string, uuid: string, last_purchased: string, auto_renew: bool, in_grace_period: bool, app_identifier: string, quantity: int, state: string, activated_at: string, canceled_at: string, expires_at: string, trial_started_at: string, trial_ends_at: string, test: bool, imported: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_subscriptions/($external_subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an external subscription
#
# PUT /external_subscriptions/{external_subscription_id}
# operationId: put_external_subscription
export def "external-subscriptions subscription-by-external_subscription_id-1" [
  external_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-product-reference: any
  --external-id: string # Id of the subscription in the external system, i.e. Apple App Store or Google Play Store.
  --last-purchased: string # When a new billing event occurred on the external subscription in conjunction with a recent billing period, reactivation or upgrade/downgrade. (format: date-time)
  --auto-renew: oneof<nothing, bool> # An indication of whether or not the external subscription will auto-renew at the expiration date. (default: false)
  --state: string # External subscriptions can be active, canceled, expired, past_due, voided, revoked, or paused. (default: active)
  --app-identifier: string # Identifier of the app that generated the external subscription.
  --quantity: int # An indication of the quantity of a subscribed item's quantity. (default: 1)
  --activated-at: string # When the external subscription was activated in the external platform. (format: date-time)
  --expires-at: string # When the external subscription expires in the external platform. (format: date-time)
  --trial-started-at: string # When the external subscription trial period started in the external platform. (format: date-time)
  --trial-ends-at: string # When the external subscription trial period ends in the external platform. (format: date-time)
  --imported: oneof<nothing, bool> # An indication of whether or not the external subscription was being created by a historical data import. (default: false)
]: any -> record<id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, external_product_reference: record<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>, external_payment_phases: table<id: string, object: string, started_at: string, ends_at: string, starting_billing_period_index: int, ending_billing_period_index: int, offer_type: string, offer_name: string, period_count: int, period_length: string, amount: string, currency: string, created_at: string, updated_at: string>, external_id: string, uuid: string, last_purchased: string, auto_renew: bool, in_grace_period: bool, app_identifier: string, quantity: int, state: string, activated_at: string, canceled_at: string, expires_at: string, trial_started_at: string, trial_ends_at: string, test: bool, imported: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_subscriptions/($external_subscription_id)")
  let body = {external_product_reference: $external_product_reference, external_id: $external_id, last_purchased: $last_purchased, auto_renew: $auto_renew, state: $state, app_identifier: $app_identifier, quantity: $quantity, activated_at: $activated_at, expires_at: $expires_at, trial_started_at: $trial_started_at, trial_ends_at: $trial_ends_at, imported: $imported} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the external invoices on an external subscription
#
# GET /external_subscriptions/{external_subscription_id}/external_invoices
# operationId: list_external_subscription_external_invoices
export def "external-subscriptions-external-invoices invoices" [
  external_subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, account: record, external_subscription: record, external_id: string, state: string, total: string, currency: string, line_items: list, purchased_at: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/external_subscriptions/($external_subscription_id)/external_invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an external invoice
#
# POST /external_subscriptions/{external_subscription_id}/external_invoices
# operationId: create_external_invoice
# --line_items item shape: {currency: string, unit_amount: string, quantity: int, description?: string, external_product_reference?: any}
# --external_payment_phase shape: {started_at?: string, ends_at?: string, starting_billing_period_index?: int, ending_billing_period_index?: int, offer_type?: string, offer_name?: string, period_count?: int, period_length?: string, amount?: string, currency?: string}
export def "external-subscriptions-external-invoices invoice" [
  external_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_id: string # An identifier which associates the external invoice to a corresponding object in an external platform.
  state: string@state-completer-4
  total: string # format: decimal
  currency: string # 3-letter ISO 4217 currency code.
  purchased_at: string # When the invoice was created in the external platform. (format: date-time)
  --line-items: list # item shape: {currency: string, unit_amount: string, quantity: int, description?: string, external_product_reference?: any}
  --external-payment-phase: record # shape: {started_at?: string, ends_at?: string, starting_billing_period_index?: int, ending_billing_period_index?: int, offer_type?: string, offer_name?: string, period_count?: int, period_length?: string, amount?: string, currency?: string}
  --external-payment-phase-id: string # External payment phase ID, e.g. `a34ypb2ef9w1`.
]: any -> record<id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, external_subscription: record<id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, external_product_reference: record<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>, external_payment_phases: list<record>, external_id: string, uuid: string, last_purchased: string, auto_renew: bool, in_grace_period: bool, app_identifier: string, quantity: int, state: string, activated_at: string, canceled_at: string, expires_at: string, trial_started_at: string, trial_ends_at: string, test: bool, imported: bool, created_at: string, updated_at: string>, external_id: string, state: string, total: string, currency: string, line_items: table<id: string, object: string, account: record, currency: string, unit_amount: string, quantity: int, description: string, external_product_reference: record, created_at: string, updated_at: string>, purchased_at: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_subscriptions/($external_subscription_id)/external_invoices")
  let body = {external_id: $external_id, state: $state, total: $total, currency: $currency, purchased_at: $purchased_at, line_items: $line_items, external_payment_phase: $external_payment_phase, external_payment_phase_id: $external_payment_phase_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a site's invoices
#
# GET /invoices
# operationId: list_invoices
export def "invoices invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --state: string@state-completer-1 # Invoice state. (default: all)
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --type: string@type-completer-1 # Filter by type when: - `type=charge`, only charge invoices will be returned. - `type=credit`, only credit invoices will be returned. - `type=non-legacy`, only charge and credit invoices will be returned. - `type=legacy`, only legacy invoices will be returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an invoice
#
# GET /invoices/{invoice_id}
# operationId: get_invoice
export def "invoices invoice-by-invoice_id" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an invoice
#
# PUT /invoices/{invoice_id}
# operationId: update_invoice
# --address shape: {name_on_account?: string, company?: string, phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string, first_name?: string, last_name?: string}
export def "invoices invoice-by-invoice_id-1" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --po-number: string # This identifies the PO number associated with the invoice. Not editable for credit invoices.
  --vat-reverse-charge-notes: string # VAT Reverse Charge Notes are editable only if there was a VAT reverse charge applied to the invoice.
  --terms-and-conditions: string # Terms and conditions are an optional note field. Not editable for credit invoices.
  --customer-notes: string # Customer notes are an optional note field.
  --net-terms: int # Integer representing the number of days after an invoice's creation that the invoice will become past due. Changing Net terms changes due_on, and the invoice could move between past due and pending.
  --address: record # shape: {name_on_account?: string, company?: string, phone?: string, street1?: string, street2?: string, city?: string, region?: string, postal_code?: string, country?: string, geo_code?: string, first_name?: string, last_name?: string}
  --gateway-code: string # An alphanumeric code shown per gateway on your site's payment gateways page. Set this code to ensure that a given invoice targets a given gateway.
]: any -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)")
  let body = {po_number: $po_number, vat_reverse_charge_notes: $vat_reverse_charge_notes, terms_and_conditions: $terms_and_conditions, customer_notes: $customer_notes, net_terms: $net_terms, address: $address, gateway_code: $gateway_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an invoice as a PDF
#
# GET /invoices/{invoice_id}.pdf
# operationId: get_invoice_pdf
export def "invoices pdf" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, message: string, params: table<param: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id).pdf")
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply available credit to a pending or past due charge invoice
#
# PUT /invoices/{invoice_id}/apply_credit_balance
# operationId: apply_credit_balance
export def "invoices-apply-credit-balance balance" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/apply_credit_balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Collect a pending or past due, automatic invoice
#
# PUT /invoices/{invoice_id}/collect
# operationId: collect_invoice
export def "invoices-collect invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --three-d-secure-action-result-token-id: string # A token generated by Recurly.js after completing a 3-D Secure device fingerprinting or authentication challenge.
  --transaction-type: string@transaction-type-completer
  --billing-info-id: string # The `billing_info_id` is the value that represents a specific billing info for an end customer. When `billing_info_id` is used to assign billing info to the subscription, all future billing events for the subscription will bill to the specified billing info. `billing_info_id` can ONLY be used for sites utilizing the Wallet feature.
]: any -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/collect")
  let body = {three_d_secure_action_result_token_id: $three_d_secure_action_result_token_id, transaction_type: $transaction_type, billing_info_id: $billing_info_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark an open invoice as failed
#
# PUT /invoices/{invoice_id}/mark_failed
# operationId: mark_invoice_failed
export def "invoices-mark-failed failed" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/mark_failed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark an open invoice as successful
#
# PUT /invoices/{invoice_id}/mark_successful
# operationId: mark_invoice_successful
export def "invoices-mark-successful successful" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/mark_successful")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reopen a closed, manual invoice
#
# PUT /invoices/{invoice_id}/reopen
# operationId: reopen_invoice
export def "invoices-reopen invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/reopen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Void a credit invoice.
#
# PUT /invoices/{invoice_id}/void
# operationId: void_invoice
export def "invoices-void invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/void")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Record an external payment for a manual invoices.
#
# POST /invoices/{invoice_id}/transactions
# operationId: record_external_transaction
export def "invoices-transactions transaction" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment-method: string@payment-method-completer
  --description: string # Used as the transaction's description.
  --amount: float # The total amount of the transcaction. Cannot excceed the invoice total. (format: float)
  --collected-at: string # Datetime that the external payment was collected. Defaults to current datetime. (format: date-time)
]: any -> record<id: string, object: string, uuid: string, original_transaction_id: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, initiator: string, invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, merchant_reason_code: string, voided_by_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, subscription_ids: list<string>, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record<first_name: string, last_name: string>, collection_method: string, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record<id: string, object: string, type: string, name: string>, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record<object: string, score: int, decision: string, reference: string, risk_rules_triggered: list<record>>, next_action: record<type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/transactions")
  let body = {payment_method: $payment_method, description: $description, amount: $amount, collected_at: $collected_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List an invoice's line items
#
# GET /invoices/{invoice_id}/line_items
# operationId: list_invoice_line_items
export def "invoices-line-items items" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --original: string@original-completer # Filter by original field.
  --state: string@state-completer-2 # Filter by state field.
  --type: string@type-completer-2 # Filter by type field.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "original" $original "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invoices/($invoice_id)/line_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the coupon redemptions applied to an invoice
#
# GET /invoices/{invoice_id}/coupon_redemptions
# operationId: list_invoice_coupon_redemptions
export def "invoices-coupon-redemptions redemptions" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, account: record, subscription_id: string, coupon: record, state: string, remaining_duration: record, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invoices/($invoice_id)/coupon_redemptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an invoice's related credit or charge invoices
#
# GET /invoices/{invoice_id}/related_invoices
# operationId: list_related_invoices
export def "invoices-related-invoices invoices" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/related_invoices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refund an invoice
#
# POST /invoices/{invoice_id}/refund
# operationId: refund_invoice
# --line_items item shape: {id?: string, quantity?: int, quantity_decimal?: string, amount?: float, percentage?: int, prorate?: bool}
# --external_refund shape: {payment_method: "bacs"|"ach"|"amazon"|"apple_pay"|"braintree_apple_pay"|"check"|"credit_card"|"eft"|"google_pay"|"mercadopago"|"money_order"|"other"|"paypal"|"pix_automatico"|"roku"|"sepadirectdebit"|"wire_transfer", description?: string, refunded_at?: string}
export def "invoices-refund invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-4
  --amount: float # The amount to be refunded. The amount will be split between the line items. If `type` is "amount" and no amount is specified, it will default to refunding the total refundable amount on the invoice. Can only be present if `type` is "amount".  (format: float)
  --percentage: int # The percentage of the remaining balance to be refunded. The percentage will be split between the line items. If `type` is "percentage" and no percentage is specified, it will default to refunding 100% of the refundable amount on the invoice. Can only be present if `type` is "percentage".
  --line-items: list # The line items to be refunded. This is required when `type=line_items`. — item shape: {id?: string, quantity?: int, quantity_decimal?: string, amount?: float, percentage?: int, prorate?: bool}
  --refund-method: string@refund-method-completer
  --credit-customer-notes: string # Used as the Customer Notes on the credit invoice.  This field can only be include when the Credit Invoices feature is enabled.
  --external-refund: record # Indicates that the refund was settled outside of Recurly, and a manual transaction should be created to track it in Recurly.  Required when: - refunding a manually collected charge invoice, and `refund_method` is not `all_credit` - refunding a credit invoice that refunded manually collecting invoices - refunding a credit invoice for a partial amount  This field can only be included when the Credit Invoices feature is enabled. — shape: {payment_method: "bacs"|"ach"|"amazon"|"apple_pay"|"braintree_apple_pay"|"check"|"credit_card"|"eft"|"google_pay"|"mercadopago"|"money_order"|"other"|"paypal"|"pix_automatico"|"roku"|"sepadirectdebit"|"wire_transfer", description?: string, refunded_at?: string}
]: any -> record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>, has_more_line_items: bool, transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>, credit_payments: table<id: string, object: string, uuid: string, action: string, account: record, applied_to_invoice: record, original_invoice: record, currency: string, amount: float, original_credit_payment_id: string, refund_transaction: record, created_at: string, updated_at: string, voided_at: string>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($invoice_id)/refund")
  let body = {type: $type, amount: $amount, percentage: $percentage, line_items: $line_items, refund_method: $refund_method, credit_customer_notes: $credit_customer_notes, external_refund: $external_refund} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an invoice for revenue recovery
#
# POST /invoices/recovery
# operationId: create_invoice_retry
# --account shape: {address?: record, billing_infos: list, code: string, email?: string, custom_fields?: list, dunning_campaign_id?: string}
# --line_items item shape: {tax?: float, custom_fields?: list, harmonized_system_code?: string, product_code?: string, quantity?: int, description?: string, unit_amount: float}
export def "invoices-recovery retry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currency: string # 3-letter ISO 4217 currency code.
  due_at: string # Date invoice was originally due. Must be in the past. (format: date-time)
  --po-number: string # This identifies the PO number associated with the subscription.
  --external-recovery-eligible: oneof<nothing, bool> # Must be set to `true` to acknowledge that the invoice is eligible for external recovery. Requests with `false`, omitted, or non-boolean values will be rejected.
  account: record # shape: {address?: record, billing_infos: list, code: string, email?: string, custom_fields?: list, dunning_campaign_id?: string}
  line_items: list # Line items to include on the invoice. Currency is specified at the root level and must not be included in individual line items. — item shape: {tax?: float, custom_fields?: list, harmonized_system_code?: string, product_code?: string, quantity?: int, description?: string, unit_amount: float}
]: any -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoices/recovery")
  let body = {currency: $currency, due_at: $due_at, po_number: $po_number, external_recovery_eligible: $external_recovery_eligible, account: $account, line_items: $line_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a site's line items
#
# GET /line_items
# operationId: list_line_items
export def "line-items items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --original: string@original-completer # Filter by original field.
  --state: string@state-completer-2 # Filter by state field.
  --type: string@type-completer-2 # Filter by type field.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "original" $original "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/line_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a line item
#
# GET /line_items/{line_item_id}
# operationId: get_line_item
export def "line-items item-by-line_item_id" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: table<object: string, coupon_id: string, coupon_redemption_id: string, order_applied: int, discount_amount: float, currency: string>, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, start_date: string, end_date: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/line_items/($line_item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an uninvoiced line item
#
# DELETE /line_items/{line_item_id}
# operationId: remove_line_item
export def "line-items item-by-line_item_id-1" [
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, message: string, params: table<param: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/line_items/($line_item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's plans
#
# GET /plans
# operationId: list_plans
export def "plans plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --state: string@state-completer # Filter by state.
]: nothing -> record<object: string, has_more: bool, next: string, data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a plan
#
# POST /plans
# operationId: create_plan
# --currencies item shape: {currency?: string, setup_fee?: float, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool}
# --ramp_intervals item shape: {starting_billing_cycle?: int, currencies?: list}
# --setup_fees item shape: {currency?: string, unit_amount?: float}
# --add_ons item shape: {item_code?: string, item_id?: string, code: string, name: string, add_on_type?: "fixed"|"usage", usage_type?: "price"|"percentage", usage_calculation_type?: "cumulative"|"last_in_period", usage_percentage?: float, measured_unit_id?: string, measured_unit_name?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, accounting_code?: string, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", display_quantity?: bool, default_quantity?: int, optional?: bool, avalara_transaction_type?: int, avalara_service_type?: int, tax_code?: string, harmonized_system_code?: string, currencies?: list, tier_type?: "flat"|"tiered"|"stairstep"|"volume", usage_timeframe?: "billing_period"|"subscription_term", tiers?: list, percentage_tiers?: list}
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
# --hosted_pages shape: {success_url?: string, cancel_url?: string, bypass_confirmation?: bool, display_quantity?: bool}
export def "plans plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # Unique code to identify the plan. This is used in Hosted Payment Page URLs and in the invoice exports.
  name: string # This name describes your plan and will appear on the Hosted Payment Page and the subscriber's invoice.
  --pricing-model: string@pricing-model-completer # A fixed pricing model has the same price for each billing period. A ramp pricing model defines a set of Ramp Intervals, where a subscription changes price on a specified cadence of billing periods. The price change could be an increase or decrease.  (default: fixed)
  currencies: list # Required only when `pricing_model` is `'fixed'`. — item shape: {currency?: string, setup_fee?: float, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool}
  --ramp-intervals: list # item shape: {starting_billing_cycle?: int, currencies?: list}
  --setup-fees: list # item shape: {currency?: string, unit_amount?: float}
  --add-ons: list # item shape: {item_code?: string, item_id?: string, code: string, name: string, add_on_type?: "fixed"|"usage", usage_type?: "price"|"percentage", usage_calculation_type?: "cumulative"|"last_in_period", usage_percentage?: float, measured_unit_id?: string, measured_unit_name?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, accounting_code?: string, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", display_quantity?: bool, default_quantity?: int, optional?: bool, avalara_transaction_type?: int, avalara_service_type?: int, tax_code?: string, harmonized_system_code?: string, currencies?: list, tier_type?: "flat"|"tiered"|"stairstep"|"volume", usage_timeframe?: "billing_period"|"subscription_term", tiers?: list, percentage_tiers?: list}
  --interval-unit: string@interval-unit-completer
  --interval-length: int # Length of the plan's billing interval in `interval_unit`. (default: 1)
  --description: string # Optional description, not displayed.
  --accounting-code: string # Accounting code for invoice line items for the plan. If no value is provided, it defaults to plan's code.
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --setup-fee-accounting-code: string # Accounting code for invoice line items for the plan's setup fee. If no value is provided, it defaults to plan's accounting code.
  --setup-fee-revenue-schedule-type: string@setup-fee-revenue-schedule-type-completer
  --setup-fee-liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --setup-fee-revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --setup-fee-performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --trial-unit: string@trial-unit-completer
  --trial-length: int # Length of plan's trial period in `trial_units`. `0` means `no trial`. (default: 0)
  --trial-requires-billing-info: oneof<nothing, bool> # Allow free trial subscriptions to be created without billing info. Should not be used if billing info is needed for initial invoice due to existing uninvoiced charges or setup fee. (default: true)
  --total-billing-cycles: int # Automatically terminate subscriptions after a defined number of billing cycles. Number of billing cycles before the plan automatically stops renewing, defaults to `null` for continuous, automatic renewal.
  --auto-renew: oneof<nothing, bool> # Subscriptions will automatically inherit this value once they are active. If `auto_renew` is `true`, then a subscription will automatically renew its term at renewal. If `auto_renew` is `false`, then a subscription will expire at the end of its term. `auto_renew` can be overridden on the subscription record itself. (default: true)
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --avalara-transaction-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the plan is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types.
  --avalara-service-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the plan is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types.
  --tax-code: string # Optional field used by Avalara, Vertex, and Recurly's In-the-Box tax solution to determine taxation rules. You can pass in specific tax codes using any of these tax integrations. For Recurly's In-the-Box tax offering you can also choose to instead use simple values of `unknown`, `physical`, or `digital` tax codes.
  --harmonized-system-code: string # The Harmonized System (HS) code is an internationally standardized system of names and numbers to classify traded products. The HS code, sometimes called Commodity Code, is used by customs authorities around the world to identify products when assessing duties and taxes. The HS code may also be referred to as the tariff code or customs code. Values should contain only digits and decimals.
  --tax-exempt: oneof<nothing, bool> # `true` exempts tax on the plan, `false` applies tax on the plan.
  --vertex-transaction-type: string # Used by Vertex for tax calculations. Possible values are `sale`, `rental`, `lease`.
  --hosted-pages: record # shape: {success_url?: string, cancel_url?: string, bypass_confirmation?: bool, display_quantity?: bool}
  --allow-any-item-on-subscriptions: oneof<nothing, bool> # Used to determine whether items can be assigned as add-ons to individual subscriptions. If `true`, items can be assigned as add-ons to individual subscription add-ons. If `false`, only plan add-ons can be used.
  --dunning-campaign-id: string # Unique ID to identify a dunning campaign. Used to specify if a non-default dunning campaign should be assigned to this plan. For sites without multiple dunning campaigns enabled, the default dunning campaign will always be used.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/plans")
  let body = {code: $code, name: $name, pricing_model: $pricing_model, currencies: $currencies, ramp_intervals: $ramp_intervals, setup_fees: $setup_fees, add_ons: $add_ons, interval_unit: $interval_unit, interval_length: $interval_length, description: $description, accounting_code: $accounting_code, revenue_schedule_type: $revenue_schedule_type, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, performance_obligation_id: $performance_obligation_id, setup_fee_accounting_code: $setup_fee_accounting_code, setup_fee_revenue_schedule_type: $setup_fee_revenue_schedule_type, setup_fee_liability_gl_account_id: $setup_fee_liability_gl_account_id, setup_fee_revenue_gl_account_id: $setup_fee_revenue_gl_account_id, setup_fee_performance_obligation_id: $setup_fee_performance_obligation_id, trial_unit: $trial_unit, trial_length: $trial_length, trial_requires_billing_info: $trial_requires_billing_info, total_billing_cycles: $total_billing_cycles, auto_renew: $auto_renew, custom_fields: $custom_fields, avalara_transaction_type: $avalara_transaction_type, avalara_service_type: $avalara_service_type, tax_code: $tax_code, harmonized_system_code: $harmonized_system_code, tax_exempt: $tax_exempt, vertex_transaction_type: $vertex_transaction_type, hosted_pages: $hosted_pages, allow_any_item_on_subscriptions: $allow_any_item_on_subscriptions, dunning_campaign_id: $dunning_campaign_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a plan
#
# GET /plans/{plan_id}
# operationId: get_plan
export def "plans plan-by-plan_id" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($plan_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a plan
#
# PUT /plans/{plan_id}
# operationId: update_plan
# --currencies item shape: {currency?: string, setup_fee?: float, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool}
# --ramp_intervals item shape: {starting_billing_cycle?: int, currencies?: list}
# --setup_fees item shape: {currency?: string, unit_amount?: float}
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
# --hosted_pages shape: {success_url?: string, cancel_url?: string, bypass_confirmation?: bool, display_quantity?: bool}
export def "plans plan-by-plan_id-1" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Unique code to identify the plan. This is used in Hosted Payment Page URLs and in the invoice exports.
  --name: string # This name describes your plan and will appear on the Hosted Payment Page and the subscriber's invoice.
  --currencies: list # Required only when `pricing_model` is `'fixed'`. — item shape: {currency?: string, setup_fee?: float, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool}
  --ramp-intervals: list # item shape: {starting_billing_cycle?: int, currencies?: list}
  --setup-fees: list # item shape: {currency?: string, unit_amount?: float}
  --description: string # Optional description, not displayed.
  --accounting-code: string # Accounting code for invoice line items for the plan. If no value is provided, it defaults to plan's code.
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --setup-fee-accounting-code: string # Accounting code for invoice line items for the plan's setup fee. If no value is provided, it defaults to plan's accounting code.
  --setup-fee-revenue-schedule-type: string@setup-fee-revenue-schedule-type-completer
  --setup-fee-liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --setup-fee-revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --setup-fee-performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --trial-unit: string@trial-unit-completer
  --trial-length: int # Length of plan's trial period in `trial_units`. `0` means `no trial`. (default: 0)
  --trial-requires-billing-info: oneof<nothing, bool> # Allow free trial subscriptions to be created without billing info. Should not be used if billing info is needed for initial invoice due to existing uninvoiced charges or setup fee. (default: true)
  --total-billing-cycles: int # Automatically terminate subscriptions after a defined number of billing cycles. Number of billing cycles before the plan automatically stops renewing, defaults to `null` for continuous, automatic renewal.
  --auto-renew: oneof<nothing, bool> # Subscriptions will automatically inherit this value once they are active. If `auto_renew` is `true`, then a subscription will automatically renew its term at renewal. If `auto_renew` is `false`, then a subscription will expire at the end of its term. `auto_renew` can be overridden on the subscription record itself. (default: true)
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --avalara-transaction-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the plan is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types.
  --avalara-service-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the plan is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types.
  --tax-code: string # Optional field used by Avalara, Vertex, and Recurly's In-the-Box tax solution to determine taxation rules. You can pass in specific tax codes using any of these tax integrations. For Recurly's In-the-Box tax offering you can also choose to instead use simple values of `unknown`, `physical`, or `digital` tax codes.
  --harmonized-system-code: string # The Harmonized System (HS) code is an internationally standardized system of names and numbers to classify traded products. The HS code, sometimes called Commodity Code, is used by customs authorities around the world to identify products when assessing duties and taxes. The HS code may also be referred to as the tariff code or customs code. Values should contain only digits and decimals.
  --tax-exempt: oneof<nothing, bool> # `true` exempts tax on the plan, `false` applies tax on the plan.
  --vertex-transaction-type: string # Used by Vertex for tax calculations. Possible values are `sale`, `rental`, `lease`.
  --hosted-pages: record # shape: {success_url?: string, cancel_url?: string, bypass_confirmation?: bool, display_quantity?: bool}
  --allow-any-item-on-subscriptions: oneof<nothing, bool> # Used to determine whether items can be assigned as add-ons to individual subscriptions. If `true`, items can be assigned as add-ons to individual subscription add-ons. If `false`, only plan add-ons can be used.
  --dunning-campaign-id: string # Unique ID to identify a dunning campaign. Used to specify if a non-default dunning campaign should be assigned to this plan. For sites without multiple dunning campaigns enabled, the default dunning campaign will always be used.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($plan_id)")
  let body = {code: $code, name: $name, currencies: $currencies, ramp_intervals: $ramp_intervals, setup_fees: $setup_fees, description: $description, accounting_code: $accounting_code, revenue_schedule_type: $revenue_schedule_type, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, performance_obligation_id: $performance_obligation_id, setup_fee_accounting_code: $setup_fee_accounting_code, setup_fee_revenue_schedule_type: $setup_fee_revenue_schedule_type, setup_fee_liability_gl_account_id: $setup_fee_liability_gl_account_id, setup_fee_revenue_gl_account_id: $setup_fee_revenue_gl_account_id, setup_fee_performance_obligation_id: $setup_fee_performance_obligation_id, trial_unit: $trial_unit, trial_length: $trial_length, trial_requires_billing_info: $trial_requires_billing_info, total_billing_cycles: $total_billing_cycles, auto_renew: $auto_renew, custom_fields: $custom_fields, avalara_transaction_type: $avalara_transaction_type, avalara_service_type: $avalara_service_type, tax_code: $tax_code, harmonized_system_code: $harmonized_system_code, tax_exempt: $tax_exempt, vertex_transaction_type: $vertex_transaction_type, hosted_pages: $hosted_pages, allow_any_item_on_subscriptions: $allow_any_item_on_subscriptions, dunning_campaign_id: $dunning_campaign_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a plan
#
# DELETE /plans/{plan_id}
# operationId: remove_plan
export def "plans plan-by-plan_id-2" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($plan_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a plan's add-ons
#
# GET /plans/{plan_id}/add_ons
# operationId: list_plan_add_ons
export def "plans-add-ons ons" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --state: string@state-completer # Filter by state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, plan_id: string, code: string, state: string, name: string, add_on_type: string, usage_type: string, usage_calculation_type: string, usage_percentage: float, measured_unit_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, accounting_code: string, revenue_schedule_type: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, display_quantity: bool, default_quantity: int, optional: bool, currencies: list, item: record, tier_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, external_sku: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plans/($plan_id)/add_ons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an add-on
#
# POST /plans/{plan_id}/add_ons
# operationId: create_plan_add_on
# --currencies item shape: {currency: string, unit_amount?: float, unit_amount_decimal?: string, tax_inclusive?: bool}
# --tiers item shape: {ending_quantity?: int, usage_percentage?: string, currencies?: list}
# --percentage_tiers item shape: {currency?: string, tiers?: list}
export def "plans-add-ons on-by-plan_id" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --item-code: string # Unique code to identify an item. Available when the `Credit Invoices` feature is enabled. If `item_id` and `item_code` are both present, `item_id` will be used.
  --item-id: string # System-generated unique identifier for an item. Available when the `Credit Invoices` feature is enabled. If `item_id` and `item_code` are both present, `item_id` will be used.
  code: string # The unique identifier for the add-on within its plan. If `item_code`/`item_id` is part of the request then `code` must be absent. If `item_code`/`item_id` is not present `code` is required.
  name: string # Describes your add-on and will appear in subscribers' invoices. If `item_code`/`item_id` is part of the request then `name` must be absent. If `item_code`/`item_id` is not present `name` is required.
  --add-on-type: string@add-on-type-completer # Whether the add-on type is fixed, or usage-based. (default: fixed)
  --usage-type: string@usage-type-completer # Type of usage, required if `add_on_type` is `usage`. See our [Guide](https://recurly.com/developers/guides/usage-based-billing-guide.html) for an overview of how to configure usage add-ons.
  --usage-calculation-type: string@usage-calculation-type-completer # The type of calculation to be employed for an add-on.  Cumulative billing will sum all usage records created in the current billing cycle.  Last-in-period billing will apply only the most recent usage record in the billing period.  If no value is specified, cumulative billing will be used.
  --usage-percentage: float # The percentage taken of the monetary amount of usage tracked. This can be up to 4 decimal places. A value between 0.0 and 100.0. Required if `add_on_type` is usage, `tier_type` is `flat` and `usage_type` is percentage. Must be omitted otherwise. (format: float)
  --measured-unit-id: string # System-generated unique identifier for a measured unit to be associated with the add-on. Either `measured_unit_id` or `measured_unit_name` are required when `add_on_type` is `usage`. If `measured_unit_id` and `measured_unit_name` are both present, `measured_unit_id` will be used.
  --measured-unit-name: string # Name of a measured unit to be associated with the add-on. Either `measured_unit_id` or `measured_unit_name` are required when `add_on_type` is `usage`. If `measured_unit_id` and `measured_unit_name` are both present, `measured_unit_id` will be used.
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --accounting-code: string # Accounting code for invoice line items for this add-on. If no value is provided, it defaults to add-on's code. If `item_code`/`item_id` is part of the request then `accounting_code` must be absent.
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --display-quantity: oneof<nothing, bool> # Determines if the quantity field is displayed on the hosted pages for the add-on. (default: false)
  --default-quantity: int # Default quantity for the hosted pages. (default: 1)
  --optional: oneof<nothing, bool> # Whether the add-on is optional for the customer to include in their purchase on the hosted payment page. If false, the add-on will be included when a subscription is created through the Recurly UI. However, the add-on will not be included when a subscription is created through the API.
  --avalara-transaction-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the add-on is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types. If an `Item` is associated to the `AddOn`, then the `avalara_transaction_type` must be absent.
  --avalara-service-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the add-on is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types. If an `Item` is associated to the `AddOn`, then the `avalara_service_type` must be absent.
  --tax-code: string # Optional field used by Avalara, Vertex, and Recurly's In-the-Box tax solution to determine taxation rules. You can pass in specific tax codes using any of these tax integrations. For Recurly's In-the-Box tax offering you can also choose to instead use simple values of `unknown`, `physical`, or `digital` tax codes. If `item_code`/`item_id` is part of the request then `tax_code` must be absent.
  --harmonized-system-code: string # The Harmonized System (HS) code is an internationally standardized system of names and numbers to classify traded products. The HS code, sometimes called Commodity Code, is used by customs authorities around the world to identify products when assessing duties and taxes. The HS code may also be referred to as the tariff code or customs code. Values should contain only digits and decimals.
  --currencies: list # * If `item_code`/`item_id` is part of the request and the item has a default currency, then `currencies` is optional. If the item does not have a default currency, then `currencies` is required. If `item_code`/`item_id` is not present `currencies` is required. * If the add-on's `tier_type` is `tiered`, `volume`, or `stairstep`, then `currencies` must be absent. * Must be absent if `add_on_type` is `usage` and `usage_type` is `percentage`. — item shape: {currency: string, unit_amount?: float, unit_amount_decimal?: string, tax_inclusive?: bool}
  --tier-type: string@tier-type-completer # The pricing model for the add-on.  For more information, [click here](https://docs.recurly.com/docs/billing-models#section-quantity-based). See our [Guide](https://recurly.com/developers/guides/item-addon-guide.html) for an overview of how to configure quantity-based pricing models.  (default: flat)
  --usage-timeframe: string@usage-timeframe-completer # The time at which usage totals are reset for billing purposes. Allows for `tiered` add-ons to accumulate usage over the course of multiple billing periods.  (default: billing_period)
  --tiers: list # If the tier_type is `flat`, then `tiers` must be absent. The `tiers` object must include one to many tiers with `ending_quantity` and `unit_amount` for the desired `currencies`. There must be one tier without an `ending_quantity` value which represents the final tier. — item shape: {ending_quantity?: int, usage_percentage?: string, currencies?: list}
  --percentage-tiers: list # Array of objects which must have at least one set of tiers per currency and the currency code. The tier_type must be `volume` or `tiered`, if not, it must be absent. There must be one tier without an `ending_amount` value which represents the final tier. This feature is currently in development and requires approval and enablement, please contact support. — item shape: {currency?: string, tiers?: list}
]: any -> record<id: string, object: string, plan_id: string, code: string, state: string, name: string, add_on_type: string, usage_type: string, usage_calculation_type: string, usage_percentage: float, measured_unit_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, accounting_code: string, revenue_schedule_type: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, display_quantity: bool, default_quantity: int, optional: bool, currencies: table<currency: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool>, item: record<id: string, object: string, code: string, state: string, name: string, description: string>, tier_type: string, usage_timeframe: string, tiers: table<ending_quantity: int, usage_percentage: string, currencies: list>, percentage_tiers: table<currency: string, tiers: list>, external_sku: string, created_at: string, updated_at: string, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($plan_id)/add_ons")
  let body = {item_code: $item_code, item_id: $item_id, code: $code, name: $name, add_on_type: $add_on_type, usage_type: $usage_type, usage_calculation_type: $usage_calculation_type, usage_percentage: $usage_percentage, measured_unit_id: $measured_unit_id, measured_unit_name: $measured_unit_name, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, performance_obligation_id: $performance_obligation_id, accounting_code: $accounting_code, revenue_schedule_type: $revenue_schedule_type, display_quantity: $display_quantity, default_quantity: $default_quantity, optional: $optional, avalara_transaction_type: $avalara_transaction_type, avalara_service_type: $avalara_service_type, tax_code: $tax_code, harmonized_system_code: $harmonized_system_code, currencies: $currencies, tier_type: $tier_type, usage_timeframe: $usage_timeframe, tiers: $tiers, percentage_tiers: $percentage_tiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a plan's add-on
#
# GET /plans/{plan_id}/add_ons/{add_on_id}
# operationId: get_plan_add_on
export def "plans-add-ons on-by-plan_id-add_on_id" [
  plan_id: string
  add_on_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, plan_id: string, code: string, state: string, name: string, add_on_type: string, usage_type: string, usage_calculation_type: string, usage_percentage: float, measured_unit_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, accounting_code: string, revenue_schedule_type: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, display_quantity: bool, default_quantity: int, optional: bool, currencies: table<currency: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool>, item: record<id: string, object: string, code: string, state: string, name: string, description: string>, tier_type: string, usage_timeframe: string, tiers: table<ending_quantity: int, usage_percentage: string, currencies: list>, percentage_tiers: table<currency: string, tiers: list>, external_sku: string, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($plan_id)/add_ons/($add_on_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an add-on
#
# PUT /plans/{plan_id}/add_ons/{add_on_id}
# operationId: update_plan_add_on
# --currencies item shape: {currency: string, unit_amount?: float, unit_amount_decimal?: string, tax_inclusive?: bool}
# --tiers item shape: {ending_quantity?: int, usage_percentage?: string, currencies?: list}
# --percentage_tiers item shape: {currency?: string, tiers?: list}
export def "plans-add-ons on-by-plan_id-add_on_id-1" [
  plan_id: string
  add_on_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # The unique identifier for the add-on within its plan. If an `Item` is associated to the `AddOn` then `code` must be absent.
  --name: string # Describes your add-on and will appear in subscribers' invoices. If an `Item` is associated to the `AddOn` then `name` must be absent.
  --usage-percentage: float # The percentage taken of the monetary amount of usage tracked. This can be up to 4 decimal places. A value between 0.0 and 100.0. Required if `add_on_type` is usage, `tier_type` is `flat` and `usage_type` is percentage. Must be omitted otherwise. (format: float)
  --usage-calculation-type: string@usage-calculation-type-completer # The type of calculation to be employed for an add-on.  Cumulative billing will sum all usage records created in the current billing cycle.  Last-in-period billing will apply only the most recent usage record in the billing period.  If no value is specified, cumulative billing will be used.
  --measured-unit-id: string # System-generated unique identifier for a measured unit to be associated with the add-on. Either `measured_unit_id` or `measured_unit_name` are required when `add_on_type` is `usage`. If `measured_unit_id` and `measured_unit_name` are both present, `measured_unit_id` will be used.
  --measured-unit-name: string # Name of a measured unit to be associated with the add-on. Either `measured_unit_id` or `measured_unit_name` are required when `add_on_type` is `usage`. If `measured_unit_id` and `measured_unit_name` are both present, `measured_unit_id` will be used.
  --accounting-code: string # Accounting code for invoice line items for this add-on. If no value is provided, it defaults to add-on's code. If an `Item` is associated to the `AddOn` then `accounting code` must be absent.
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --avalara-transaction-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the add-on is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types. If an `Item` is associated to the `AddOn`, then the `avalara_transaction_type` must be absent.
  --avalara-service-type: int # Used by Avalara for Communications taxes. The transaction type in combination with the service type describe how the add-on is taxed. Refer to [the documentation](https://help.avalara.com/AvaTax_for_Communications/Tax_Calculation/AvaTax_for_Communications_Tax_Engine/Mapping_Resources/TM_00115_AFC_Modules_Corresponding_Transaction_Types) for more available t/s types. If an `Item` is associated to the `AddOn`, then the `avalara_service_type` must be absent.
  --tax-code: string # Optional field used by Avalara, Vertex, and Recurly's In-the-Box tax solution to determine taxation rules. You can pass in specific tax codes using any of these tax integrations. For Recurly's In-the-Box tax offering you can also choose to instead use simple values of `unknown`, `physical`, or `digital` tax codes. If an `Item` is associated to the `AddOn` then `tax_code` must be absent.
  --harmonized-system-code: string # The Harmonized System (HS) code is an internationally standardized system of names and numbers to classify traded products. The HS code, sometimes called Commodity Code, is used by customs authorities around the world to identify products when assessing duties and taxes. The HS code may also be referred to as the tariff code or customs code. Values should contain only digits and decimals.
  --display-quantity: oneof<nothing, bool> # Determines if the quantity field is displayed on the hosted pages for the add-on. (default: false)
  --default-quantity: int # Default quantity for the hosted pages. (default: 1)
  --optional: oneof<nothing, bool> # Whether the add-on is optional for the customer to include in their purchase on the hosted payment page. If false, the add-on will be included when a subscription is created through the Recurly UI. However, the add-on will not be included when a subscription is created through the API.
  --currencies: list # If the add-on's `tier_type` is `tiered`, `volume`, or `stairstep`, then currencies must be absent. Must also be absent if `add_on_type` is `usage` and `usage_type` is `percentage`. — item shape: {currency: string, unit_amount?: float, unit_amount_decimal?: string, tax_inclusive?: bool}
  --tiers: list # If the tier_type is `flat`, then `tiers` must be absent. The `tiers` object must include one to many tiers with `ending_quantity` and `unit_amount` for the desired `currencies`. There must be one tier without an `ending_quantity` value which represents the final tier. — item shape: {ending_quantity?: int, usage_percentage?: string, currencies?: list}
  --percentage-tiers: list # `percentage_tiers` is an array of objects, which must have the set of tiers per currency and the currency code. The tier_type must be `volume` or `tiered`, if not, it must be absent. There must be one tier without an `ending_amount` value which represents the final tier. This feature is currently in development and requires approval and enablement, please contact support. — item shape: {currency?: string, tiers?: list}
]: any -> record<id: string, object: string, plan_id: string, code: string, state: string, name: string, add_on_type: string, usage_type: string, usage_calculation_type: string, usage_percentage: float, measured_unit_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, accounting_code: string, revenue_schedule_type: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, display_quantity: bool, default_quantity: int, optional: bool, currencies: table<currency: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool>, item: record<id: string, object: string, code: string, state: string, name: string, description: string>, tier_type: string, usage_timeframe: string, tiers: table<ending_quantity: int, usage_percentage: string, currencies: list>, percentage_tiers: table<currency: string, tiers: list>, external_sku: string, created_at: string, updated_at: string, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($plan_id)/add_ons/($add_on_id)")
  let body = {code: $code, name: $name, usage_percentage: $usage_percentage, usage_calculation_type: $usage_calculation_type, measured_unit_id: $measured_unit_id, measured_unit_name: $measured_unit_name, accounting_code: $accounting_code, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, performance_obligation_id: $performance_obligation_id, revenue_schedule_type: $revenue_schedule_type, avalara_transaction_type: $avalara_transaction_type, avalara_service_type: $avalara_service_type, tax_code: $tax_code, harmonized_system_code: $harmonized_system_code, display_quantity: $display_quantity, default_quantity: $default_quantity, optional: $optional, currencies: $currencies, tiers: $tiers, percentage_tiers: $percentage_tiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an add-on
#
# DELETE /plans/{plan_id}/add_ons/{add_on_id}
# operationId: remove_plan_add_on
export def "plans-add-ons on-by-plan_id-add_on_id-2" [
  plan_id: string
  add_on_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, plan_id: string, code: string, state: string, name: string, add_on_type: string, usage_type: string, usage_calculation_type: string, usage_percentage: float, measured_unit_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, accounting_code: string, revenue_schedule_type: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, display_quantity: bool, default_quantity: int, optional: bool, currencies: table<currency: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool>, item: record<id: string, object: string, code: string, state: string, name: string, description: string>, tier_type: string, usage_timeframe: string, tiers: table<ending_quantity: int, usage_percentage: string, currencies: list>, percentage_tiers: table<currency: string, tiers: list>, external_sku: string, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($plan_id)/add_ons/($add_on_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's price segments
#
# GET /price_segments
# operationId: list_price_segments
export def "price-segments segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<object: string, id: string, code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price_segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a price segment
#
# GET /price_segments/{price_segment_id}
# operationId: get_price_segment
export def "price-segments segment" [
  price_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, code: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/price_segments/($price_segment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's add-ons
#
# GET /add_ons
# operationId: list_add_ons
export def "add-ons ons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --state: string@state-completer # Filter by state.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, plan_id: string, code: string, state: string, name: string, add_on_type: string, usage_type: string, usage_calculation_type: string, usage_percentage: float, measured_unit_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, accounting_code: string, revenue_schedule_type: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, display_quantity: bool, default_quantity: int, optional: bool, currencies: list, item: record, tier_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, external_sku: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/add_ons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an add-on
#
# GET /add_ons/{add_on_id}
# operationId: get_add_on
export def "add-ons on" [
  add_on_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, plan_id: string, code: string, state: string, name: string, add_on_type: string, usage_type: string, usage_calculation_type: string, usage_percentage: float, measured_unit_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, accounting_code: string, revenue_schedule_type: string, avalara_transaction_type: int, avalara_service_type: int, tax_code: string, harmonized_system_code: string, display_quantity: bool, default_quantity: int, optional: bool, currencies: table<currency: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool>, item: record<id: string, object: string, code: string, state: string, name: string, description: string>, tier_type: string, usage_timeframe: string, tiers: table<ending_quantity: int, usage_percentage: string, currencies: list>, percentage_tiers: table<currency: string, tiers: list>, external_sku: string, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/add_ons/($add_on_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's shipping methods
#
# GET /shipping_methods
# operationId: list_shipping_methods
export def "shipping-methods methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, code: string, name: string, accounting_code: string, tax_code: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipping_methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new shipping method
#
# POST /shipping_methods
# operationId: create_shipping_method
export def "shipping-methods method" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # The internal name used identify the shipping method.
  name: string # The name of the shipping method displayed to customers.
  --accounting-code: string # Accounting code for shipping method.
  --tax-code: string # Used by Avalara, Vertex, and Recurly’s built-in tax feature. The tax code values are specific to each tax system. If you are using Recurly’s built-in taxes the values are:  - `FR` – Common Carrier FOB Destination - `FR022000` – Common Carrier FOB Origin - `FR020400` – Non Common Carrier FOB Destination - `FR020500` – Non Common Carrier FOB Origin - `FR010100` – Delivery by Company Vehicle Before Passage of Title - `FR010200` – Delivery by Company Vehicle After Passage of Title - `NT` – Non-Taxable
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
]: any -> record<id: string, object: string, code: string, name: string, accounting_code: string, tax_code: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, created_at: string, updated_at: string, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipping_methods")
  let body = {code: $code, name: $name, accounting_code: $accounting_code, tax_code: $tax_code, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, performance_obligation_id: $performance_obligation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a shipping method
#
# GET /shipping_methods/{shipping_method_id}
# operationId: get_shipping_method
export def "shipping-methods method-by-shipping_method_id" [
  shipping_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, name: string, accounting_code: string, tax_code: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipping_methods/($shipping_method_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an active Shipping Method
#
# PUT /shipping_methods/{shipping_method_id}
# operationId: update_shipping_method
export def "shipping-methods method-by-shipping_method_id-1" [
  shipping_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # The internal name used identify the shipping method.
  --name: string # The name of the shipping method displayed to customers.
  --accounting-code: string # Accounting code for shipping method.
  --tax-code: string # Used by Avalara, Vertex, and Recurly’s built-in tax feature. The tax code values are specific to each tax system. If you are using Recurly’s built-in taxes the values are:  - `FR` – Common Carrier FOB Destination - `FR022000` – Common Carrier FOB Origin - `FR020400` – Non Common Carrier FOB Destination - `FR020500` – Non Common Carrier FOB Origin - `FR010100` – Delivery by Company Vehicle Before Passage of Title - `FR010200` – Delivery by Company Vehicle After Passage of Title - `NT` – Non-Taxable
  --liability-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --revenue-gl-account-id: string # The ID of a general ledger account. General ledger accounts are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
  --performance-obligation-id: string # The ID of a performance obligation. Performance obligations are only accessible as a part of the Recurly RevRec Standard and Recurly RevRec Advanced features.
]: any -> record<id: string, object: string, code: string, name: string, accounting_code: string, tax_code: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, created_at: string, updated_at: string, deleted_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipping_methods/($shipping_method_id)")
  let body = {code: $code, name: $name, accounting_code: $accounting_code, tax_code: $tax_code, liability_gl_account_id: $liability_gl_account_id, revenue_gl_account_id: $revenue_gl_account_id, performance_obligation_id: $performance_obligation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate a shipping method
#
# DELETE /shipping_methods/{shipping_method_id}
# operationId: deactivate_shipping_method
export def "shipping-methods method-by-shipping_method_id-2" [
  shipping_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, name: string, accounting_code: string, tax_code: string, liability_gl_account_id: string, revenue_gl_account_id: string, performance_obligation_id: string, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipping_methods/($shipping_method_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's subscriptions
#
# GET /subscriptions
# operationId: list_subscriptions
export def "subscriptions subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --state: string@state-completer-3 # Filter by state.  - When `state=active`, `state=canceled`, `state=expired`, or `state=future`, subscriptions with states that match the query and only those subscriptions will be returned. - When `state=in_trial`, only subscriptions that have a trial_started_at date earlier than now and a trial_ends_at date later than now will be returned. - When `state=live`, only subscriptions that are in an active, canceled, or future state or are in trial will be returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, account: record, plan: record, state: string, shipping: record, coupon_redemptions: list, pending_change: record, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: list, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: list, add_ons_total: float, subtotal: float, tax: float, tax_info: record, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: list, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new subscription
#
# POST /subscriptions
# operationId: create_subscription
# --shipping shape: {address?: record, address_id?: string, method_id?: string, method_code?: string, amount?: float, expected_first_delivery_at?: string}
# --add_ons item shape: {code: string, add_on_source?: "plan_add_on"|"item", quantity?: int, unit_amount?: float, unit_amount_decimal?: string, tiers?: list, percentage_tiers?: list, usage_percentage?: float, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never"}
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
# --ramp_intervals item shape: {starting_billing_cycle?: int, unit_amount?: float}
# --credit_application_policy shape: {mode: "all"|"none", allowed_origins?: list}
# --proration_settings shape: {charge?: "full_amount"|"prorated_amount"}
export def "subscriptions subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  plan_code: string # You must provide either a `plan_code` or `plan_id`. If both are provided the `plan_id` will be used.
  --plan-id: string # You must provide either a `plan_code` or `plan_id`. If both are provided the `plan_id` will be used.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer. When `business_entity_id` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer. When `business_entity_code` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  account: any
  --price-segment-id: string # The price segment ID, e.g. `e28zov4fw0v2`.
  --billing-info-id: string # The `billing_info_id` is the value that represents a specific billing info for an end customer. When `billing_info_id` is used to assign billing info to the subscription, all future billing events for the subscription will bill to the specified billing info. `billing_info_id` can ONLY be used for sites utilizing the Wallet feature.
  --shipping: record # shape: {address?: record, address_id?: string, method_id?: string, method_code?: string, amount?: float, expected_first_delivery_at?: string}
  --collection-method: string@collection-method-completer
  currency: string # 3-letter ISO 4217 currency code.
  --unit-amount: float # Override the unit amount of the subscription plan by setting this value. If not provided, the subscription will inherit the price from the subscription plan for the provided currency. (format: float)
  --tax-inclusive: oneof<nothing, bool> # Determines whether or not tax is included in the unit amount. The Tax Inclusive Pricing feature (separate from the Mixed Tax Pricing feature) must be enabled to use this flag. (default: false)
  --quantity: int # Optionally override the default quantity of 1. (default: 1)
  --add-ons: list # item shape: {code: string, add_on_source?: "plan_add_on"|"item", quantity?: int, unit_amount?: float, unit_amount_decimal?: string, tiers?: list, percentage_tiers?: list, usage_percentage?: float, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never"}
  --coupon-codes: list # A list of coupon_codes to be redeemed on the subscription or account during the purchase.
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --trial-ends-at: string # If set, overrides the default trial behavior for the subscription. When the current date time or a past date time is provided the subscription will begin with no trial phase (overriding any plan default trial). When a future date time is provided the subscription will begin with a trial phase ending at the specified date time. (format: date-time)
  --starts-at: string # If set, the subscription will begin on this specified date. The subscription will apply the setup fee and trial period, unless the plan has no trial. Omit this field if the subscription should be started immediately. (format: date-time)
  --next-bill-date: string # If present, this sets the date the subscription's next billing period will start (`current_period_ends_at`). This can be used to align the subscription’s billing to a specific day of the month. The initial invoice will be prorated for the period between the subscription's activation date and the billing period end date. Subsequent periods will be based off the plan interval. For a subscription with a trial period, this will change when the trial expires. (format: date-time)
  --total-billing-cycles: int # The number of cycles/billing periods in a term. When `remaining_billing_cycles=0`, if `auto_renew=true` the subscription will renew and a new term will begin, otherwise the subscription will expire.
  --renewal-billing-cycles: int # If `auto_renew=true`, when a term completes, `total_billing_cycles` takes this value as the length of subsequent terms. Defaults to the plan's `total_billing_cycles`.
  --auto-renew: oneof<nothing, bool> # Whether the subscription renews at the end of its term. (default: true)
  --ramp-intervals: list # The new set of ramp intervals for the subscription. — item shape: {starting_billing_cycle?: int, unit_amount?: float}
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --terms-and-conditions: string # This will default to the Terms and Conditions text specified on the Invoice Settings page in your Recurly admin. Specify custom notes to add or override Terms and Conditions. Custom notes will stay with a subscription on all renewals.
  --customer-notes: string # This will default to the Customer Notes text specified on the Invoice Settings. Specify custom notes to add or override Customer Notes. Custom notes will stay with a subscription on all renewals.
  --credit-customer-notes: string # If there are pending credits on the account that will be invoiced during the subscription creation, these will be used as the Customer Notes on the credit invoice.
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --net-terms: int # Integer paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. For `manual` collection method, an additional 24 hours is added to ensure the customer has the entire last day to make payment before becoming past due. For example:  If an invoice is due `net 0`, it is due 'On Receipt' and will become past due 24 hours after it's created. If an invoice is due `net 30`, it will become past due at 31 days exactly. If an invoice is due `eom 30`, it will become past due 31 days from the last day of the current month.  For `automatic` collection method, the additional 24 hours is not added. For example, On-Receipt is due immediately, and `net 30` will become due exactly 30 days from invoice generation, at which point Recurly will attempt collection. When `eom` Net Terms Type is passed, the value for `Net Terms` is restricted to `0, 15, 30, 45, 60, or 90`.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --credit-application-policy: record # Controls whether credit invoices are automatically applied to new invoices. The `mode` field determines the application behavior. When mode is `all`, the optional `allowed_origins` array can restrict which credit invoice origins are applied. — shape: {mode: "all"|"none", allowed_origins?: list}
  --gateway-code: string # If present, this subscription's subsequent transactions will use the payment gateway with this code. To select a payment gateway to use when creating a Subscription, be sure to set the `account.billing_info.gateway_code` as well.
  --transaction-type: string@transaction-type-completer
  --gift-card-redemption-code: string # A gift card redemption code to be redeemed on the purchase invoice.
  --bulk: oneof<nothing, bool> # Optional field to be used only when needing to bypass the 60 second limit on creating subscriptions. Should only be used when creating subscriptions in bulk from the API. (default: false)
  --proration-settings: record # Allows you to control how any resulting charges will be calculated and prorated. — shape: {charge?: "full_amount"|"prorated_amount"}
]: any -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let body = {plan_code: $plan_code, plan_id: $plan_id, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, account: $account, price_segment_id: $price_segment_id, billing_info_id: $billing_info_id, shipping: $shipping, collection_method: $collection_method, currency: $currency, unit_amount: $unit_amount, tax_inclusive: $tax_inclusive, quantity: $quantity, add_ons: $add_ons, coupon_codes: $coupon_codes, custom_fields: $custom_fields, trial_ends_at: $trial_ends_at, starts_at: $starts_at, next_bill_date: $next_bill_date, total_billing_cycles: $total_billing_cycles, renewal_billing_cycles: $renewal_billing_cycles, auto_renew: $auto_renew, ramp_intervals: $ramp_intervals, revenue_schedule_type: $revenue_schedule_type, terms_and_conditions: $terms_and_conditions, customer_notes: $customer_notes, credit_customer_notes: $credit_customer_notes, po_number: $po_number, net_terms: $net_terms, net_terms_type: $net_terms_type, credit_application_policy: $credit_application_policy, gateway_code: $gateway_code, transaction_type: $transaction_type, gift_card_redemption_code: $gift_card_redemption_code, bulk: $bulk, proration_settings: $proration_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a subscription
#
# GET /subscriptions/{subscription_id}
# operationId: get_subscription
export def "subscriptions subscription-by-subscription_id" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a subscription
#
# PUT /subscriptions/{subscription_id}
# operationId: update_subscription
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
# --credit_application_policy shape: {mode: "all"|"none", allowed_origins?: list}
# --shipping shape: {object?: string, address?: record, address_id?: string}
@deprecated --flag tax-inclusive
export def "subscriptions subscription-by-subscription_id-1" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collection-method: string@collection-method-completer
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --remaining-billing-cycles: int # The remaining billing cycles in the current term.
  --renewal-billing-cycles: int # If `auto_renew=true`, when a term completes, `total_billing_cycles` takes this value as the length of subsequent terms. Defaults to the plan's `total_billing_cycles`.
  --auto-renew: oneof<nothing, bool> # Whether the subscription renews at the end of its term. (default: true)
  --next-bill-date: string # If present, this sets the date the subscription's next billing period will start (`current_period_ends_at`). This can be used to align the subscription’s billing to a specific day of the month. For a subscription in a trial period, this will change when the trial expires. This parameter is useful for postponement of a subscription to change its billing date without proration. (format: date-time)
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --terms-and-conditions: string # Specify custom notes to add or override Terms and Conditions. Custom notes will stay with a subscription on all renewals.
  --customer-notes: string # Specify custom notes to add or override Customer Notes. Custom notes will stay with a subscription on all renewals.
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --price-segment-id: string # The price segment ID, e.g. `e28zov4fw0v2`.
  --net-terms: int # Integer paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. For `manual` collection method, an additional 24 hours is added to ensure the customer has the entire last day to make payment before becoming past due. For example:  If an invoice is due `net 0`, it is due 'On Receipt' and will become past due 24 hours after it's created. If an invoice is due `net 30`, it will become past due at 31 days exactly. If an invoice is due `eom 30`, it will become past due 31 days from the last day of the current month.  For `automatic` collection method, the additional 24 hours is not added. For example, On-Receipt is due immediately, and `net 30` will become due exactly 30 days from invoice generation, at which point Recurly will attempt collection. When `eom` Net Terms Type is passed, the value for `Net Terms` is restricted to `0, 15, 30, 45, 60, or 90`.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --credit-application-policy: record # Controls whether credit invoices are automatically applied to new invoices. The `mode` field determines the application behavior. When mode is `all`, the optional `allowed_origins` array can restrict which credit invoice origins are applied. — shape: {mode: "all"|"none", allowed_origins?: list}
  --gateway-code: string # If present, this subscription's transactions will use the payment gateway with this code.
  --tax-inclusive: oneof<nothing, bool> # This field is deprecated. Please do not use it. (DEPRECATED, default: false)
  --shipping: record # shape: {object?: string, address?: record, address_id?: string}
  --billing-info-id: string # The `billing_info_id` is the value that represents a specific billing info for an end customer. When `billing_info_id` is used to assign billing info to the subscription, all future billing events for the subscription will bill to the specified billing info. `billing_info_id` can ONLY be used for sites utilizing the Wallet feature.
]: any -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)")
  let body = {collection_method: $collection_method, custom_fields: $custom_fields, remaining_billing_cycles: $remaining_billing_cycles, renewal_billing_cycles: $renewal_billing_cycles, auto_renew: $auto_renew, next_bill_date: $next_bill_date, revenue_schedule_type: $revenue_schedule_type, terms_and_conditions: $terms_and_conditions, customer_notes: $customer_notes, po_number: $po_number, price_segment_id: $price_segment_id, net_terms: $net_terms, net_terms_type: $net_terms_type, credit_application_policy: $credit_application_policy, gateway_code: $gateway_code, tax_inclusive: $tax_inclusive, shipping: $shipping, billing_info_id: $billing_info_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Terminate a subscription
#
# DELETE /subscriptions/{subscription_id}
# operationId: terminate_subscription
export def "subscriptions subscription-by-subscription_id-2" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refund: string@refund-completer # The type of refund to perform:  * `full` - Performs a full refund of the last invoice for the current subscription term. * `partial` - Prorates a refund based on the amount of time remaining in the current bill cycle. * `none` - Terminates the subscription without a refund.  In the event that the most recent invoice is a $0 invoice paid entirely by credit, Recurly will apply the credit back to the customer’s account.  You may also terminate a subscription with no refund and then manually refund specific invoices.
  --charge: oneof<nothing, bool> # Applicable only if the subscription has usage based add-ons and unbilled usage logged for the current billing cycle. If true, current billing cycle unbilled usage is billed on the final invoice. If false, Recurly will create a negative usage record for current billing cycle usage that will zero out the final invoice line items. (default: true)
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refund" $refund "scalar") (serialize-qp "charge" $charge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscription_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a subscription
#
# PUT /subscriptions/{subscription_id}/cancel
# operationId: cancel_subscription
export def "subscriptions-cancel subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeframe: string@timeframe-completer
]: any -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/cancel")
  let body = {timeframe: $timeframe} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reactivate a canceled subscription
#
# PUT /subscriptions/{subscription_id}/reactivate
# operationId: reactivate_subscription
export def "subscriptions-reactivate subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/reactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause subscription
#
# PUT /subscriptions/{subscription_id}/pause
# operationId: pause_subscription
export def "subscriptions-pause subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  remaining_pause_cycles: int # Number of billing cycles to pause the subscriptions. A value of 0 will cancel any pending pauses on the subscription.
]: any -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/pause")
  let body = {remaining_pause_cycles: $remaining_pause_cycles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resume subscription
#
# PUT /subscriptions/{subscription_id}/resume
# operationId: resume_subscription
export def "subscriptions-resume subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Convert trial subscription
#
# PUT /subscriptions/{subscription_id}/convert_trial
# operationId: convert_trial
export def "subscriptions-convert-trial trial" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, plan: record<id: string, object: string, code: string, name: string>, state: string, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, coupon_redemptions: table<id: string, object: string, coupon: record, state: string, remaining_duration: record, discounted: float, created_at: string>, pending_change: record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: list<record>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record, method: record, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record, credit_invoices: list, verification_transactions: list>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: list<record>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: list<record>, next_bill_date: string>, current_period_started_at: string, current_period_ends_at: string, current_term_started_at: string, current_term_ends_at: string, trial_started_at: string, trial_ends_at: string, remaining_billing_cycles: int, total_billing_cycles: int, renewal_billing_cycles: int, auto_renew: bool, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, paused_at: string, remaining_pause_cycles: int, currency: string, revenue_schedule_type: string, unit_amount: float, tax_inclusive: bool, quantity: int, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, add_ons_total: float, subtotal: float, tax: float, tax_info: record<type: string, region: string, rate: float, tax_details: list<record>>, price_segment_id: string, total: float, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, credit_application_policy: record<mode: string, allowed_origins: list<string>>, terms_and_conditions: string, customer_notes: string, expiration_reason: string, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, activated_at: string, canceled_at: string, expires_at: string, bank_account_authorized_at: string, gateway_code: string, billing_info_id: string, active_invoice_id: string, business_entity_id: string, started_with_gift: bool, converted_at: string, action_result: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/convert_trial")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a preview of a subscription's renewal invoice(s)
#
# GET /subscriptions/{subscription_id}/preview_renewal
# operationId: get_preview_renewal
export def "subscriptions-preview-renewal renewal" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/preview_renewal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a subscription's pending change
#
# GET /subscriptions/{subscription_id}/change
# operationId: get_subscription_change
export def "subscriptions-change change-by-subscription_id" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, credit_invoices: list<record>, verification_transactions: list<record>>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, next_bill_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/change")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new subscription change
#
# POST /subscriptions/{subscription_id}/change
# operationId: create_subscription_change
# --shipping shape: {method_id?: string, method_code?: string, amount?: float, address_id?: string, address?: record}
# --add_ons item shape: {id?: string, code?: string, add_on_source?: "plan_add_on"|"item", quantity?: int, unit_amount?: float, unit_amount_decimal?: string, tiers?: list, percentage_tiers?: list, usage_percentage?: float, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never"}
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
# --ramp_intervals item shape: {starting_billing_cycle?: int, unit_amount?: float}
# --proration_settings shape: {charge?: "full_amount"|"prorated_amount"|"none", credit?: "full_amount"|"prorated_amount"|"none"}
@deprecated --flag tax-inclusive
export def "subscriptions-change change-by-subscription_id-1" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeframe: string@timeframe-completer-1
  --plan-id: string # If you want to change to a new plan, you can provide the plan's code or id. If both are provided the `plan_id` will be used.
  --plan-code: string # If you want to change to a new plan, you can provide the plan's code or id. If both are provided the `plan_id` will be used.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer. When `business_entity_id` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used. Only allowed if the `timeframe` is not `now`.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer. When `business_entity_code` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used. Only allowed if the `timeframe` is not `now`.
  --price-segment-id: string # The price segment ID, e.g. `e28zov4fw0v2`.
  --unit-amount: float # Optionally, sets custom pricing for the subscription, overriding the plan's default unit amount. The subscription's current currency will be used. (format: float)
  --tax-inclusive: oneof<nothing, bool> # This field is deprecated. Please do not use it. (DEPRECATED, default: false)
  --quantity: int # Optionally override the default quantity of 1. (default: 1)
  --shipping: record # Shipping addresses are tied to a customer's account. Each account can have up to 20 different shipping addresses, and if you have enabled multiple subscriptions per account, you can associate different shipping addresses to each subscription. — shape: {method_id?: string, method_code?: string, amount?: float, address_id?: string, address?: record}
  --coupon-codes: list # A list of coupon_codes to be redeemed on the subscription during the change. Only allowed if timeframe is now and you change something about the subscription that creates an invoice.
  --add-ons: list # If you provide a value for this field it will replace any existing add-ons. So, when adding or modifying an add-on, you need to include the existing subscription add-ons. Unchanged add-ons can be included just using the subscription add-on''s ID: `{"id": "abc123"}`. If this value is omitted your existing add-ons will be unaffected. To remove all existing add-ons, this value should be an empty array.'  If a subscription add-on's `code` is supplied without the `id`, `{"code": "def456"}`, the subscription add-on attributes will be set to the current values of the plan add-on unless provided in the request.  - If an `id` is passed, any attributes not passed in will pull from the   existing subscription add-on - If a `code` is passed, any attributes not passed in will pull from the   current values of the plan add-on - Attributes passed in as part of the request will override either of the   above scenarios — item shape: {id?: string, code?: string, add_on_source?: "plan_add_on"|"item", quantity?: int, unit_amount?: float, unit_amount_decimal?: string, tiers?: list, percentage_tiers?: list, usage_percentage?: float, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never"}
  --collection-method: string@collection-method-completer
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --net-terms: int # Integer normally paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. During a subscription change, it's not necessary to provide both the `Net Terms Type` and `Net Terms` parameters.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --transaction-type: string@transaction-type-completer
  --billing-info: any
  --ramp-intervals: list # The new set of ramp intervals for the subscription. — item shape: {starting_billing_cycle?: int, unit_amount?: float}
  --proration-settings: record # Allows you to control how any resulting charges and credits will be calculated and prorated. — shape: {charge?: "full_amount"|"prorated_amount"|"none", credit?: "full_amount"|"prorated_amount"|"none"}
  --next-bill-date: string # If present, this sets the date the subscription's next billing period will start (`current_period_ends_at`). When combined with proration_settings, proration calculation should occur, only supported when timeframe is now. (format: date-time)
]: any -> record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, credit_invoices: list<record>, verification_transactions: list<record>>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, next_bill_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/change")
  let body = {timeframe: $timeframe, plan_id: $plan_id, plan_code: $plan_code, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, price_segment_id: $price_segment_id, unit_amount: $unit_amount, tax_inclusive: $tax_inclusive, quantity: $quantity, shipping: $shipping, coupon_codes: $coupon_codes, add_ons: $add_ons, collection_method: $collection_method, revenue_schedule_type: $revenue_schedule_type, custom_fields: $custom_fields, po_number: $po_number, net_terms: $net_terms, net_terms_type: $net_terms_type, transaction_type: $transaction_type, billing_info: $billing_info, ramp_intervals: $ramp_intervals, proration_settings: $proration_settings, next_bill_date: $next_bill_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the pending subscription change
#
# DELETE /subscriptions/{subscription_id}/change
# operationId: remove_subscription_change
export def "subscriptions-change change-by-subscription_id-2" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, message: string, params: table<param: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/change")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview a new subscription change
#
# POST /subscriptions/{subscription_id}/change/preview
# operationId: preview_subscription_change
# --shipping shape: {method_id?: string, method_code?: string, amount?: float, address_id?: string, address?: record}
# --add_ons item shape: {id?: string, code?: string, add_on_source?: "plan_add_on"|"item", quantity?: int, unit_amount?: float, unit_amount_decimal?: string, tiers?: list, percentage_tiers?: list, usage_percentage?: float, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never"}
# --custom_fields item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
# --ramp_intervals item shape: {starting_billing_cycle?: int, unit_amount?: float}
# --proration_settings shape: {charge?: "full_amount"|"prorated_amount"|"none", credit?: "full_amount"|"prorated_amount"|"none"}
@deprecated --flag tax-inclusive
export def "subscriptions-change-preview change" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeframe: string@timeframe-completer-1
  --plan-id: string # If you want to change to a new plan, you can provide the plan's code or id. If both are provided the `plan_id` will be used.
  --plan-code: string # If you want to change to a new plan, you can provide the plan's code or id. If both are provided the `plan_id` will be used.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer. When `business_entity_id` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used. Only allowed if the `timeframe` is not `now`.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer. When `business_entity_code` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used. Only allowed if the `timeframe` is not `now`.
  --price-segment-id: string # The price segment ID, e.g. `e28zov4fw0v2`.
  --unit-amount: float # Optionally, sets custom pricing for the subscription, overriding the plan's default unit amount. The subscription's current currency will be used. (format: float)
  --tax-inclusive: oneof<nothing, bool> # This field is deprecated. Please do not use it. (DEPRECATED, default: false)
  --quantity: int # Optionally override the default quantity of 1. (default: 1)
  --shipping: record # Shipping addresses are tied to a customer's account. Each account can have up to 20 different shipping addresses, and if you have enabled multiple subscriptions per account, you can associate different shipping addresses to each subscription. — shape: {method_id?: string, method_code?: string, amount?: float, address_id?: string, address?: record}
  --coupon-codes: list # A list of coupon_codes to be redeemed on the subscription during the change. Only allowed if timeframe is now and you change something about the subscription that creates an invoice.
  --add-ons: list # If you provide a value for this field it will replace any existing add-ons. So, when adding or modifying an add-on, you need to include the existing subscription add-ons. Unchanged add-ons can be included just using the subscription add-on''s ID: `{"id": "abc123"}`. If this value is omitted your existing add-ons will be unaffected. To remove all existing add-ons, this value should be an empty array.'  If a subscription add-on's `code` is supplied without the `id`, `{"code": "def456"}`, the subscription add-on attributes will be set to the current values of the plan add-on unless provided in the request.  - If an `id` is passed, any attributes not passed in will pull from the   existing subscription add-on - If a `code` is passed, any attributes not passed in will pull from the   current values of the plan add-on - Attributes passed in as part of the request will override either of the   above scenarios — item shape: {id?: string, code?: string, add_on_source?: "plan_add_on"|"item", quantity?: int, unit_amount?: float, unit_amount_decimal?: string, tiers?: list, percentage_tiers?: list, usage_percentage?: float, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never"}
  --collection-method: string@collection-method-completer
  --revenue-schedule-type: string@revenue-schedule-type-completer-1
  --custom-fields: list # The custom fields will only be altered when they are included in a request. Sending an empty array will not remove any existing values. To remove a field send the name with a null or empty value. — item shape: {name: string, value: string, source_record_type?: "account"|"plan"|"product"|"subscription"}
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --net-terms: int # Integer normally paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. During a subscription change, it's not necessary to provide both the `Net Terms Type` and `Net Terms` parameters.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --transaction-type: string@transaction-type-completer
  --billing-info: any
  --ramp-intervals: list # The new set of ramp intervals for the subscription. — item shape: {starting_billing_cycle?: int, unit_amount?: float}
  --proration-settings: record # Allows you to control how any resulting charges and credits will be calculated and prorated. — shape: {charge?: "full_amount"|"prorated_amount"|"none", credit?: "full_amount"|"prorated_amount"|"none"}
  --next-bill-date: string # If present, this sets the date the subscription's next billing period will start (`current_period_ends_at`). When combined with proration_settings, proration calculation should occur, only supported when timeframe is now. (format: date-time)
]: any -> record<id: string, object: string, subscription_id: string, plan: record<id: string, object: string, code: string, name: string>, add_ons: table<id: string, object: string, subscription_id: string, add_on: record, add_on_source: string, quantity: int, unit_amount: float, unit_amount_decimal: string, revenue_schedule_type: string, tier_type: string, usage_calculation_type: string, usage_timeframe: string, tiers: list, percentage_tiers: list, usage_percentage: float, created_at: string, updated_at: string, expired_at: string>, unit_amount: float, tax_inclusive: bool, quantity: int, shipping: record<object: string, address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, method: record<id: string, object: string, code: string, name: string>, amount: float>, activate_at: string, activated: bool, revenue_schedule_type: string, invoice_collection: record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, credit_invoices: list<record>, verification_transactions: list<record>>, business_entity: record<id: string, object: string, code: string, name: string>, custom_fields: table<name: string, value: string, source_record_type: string, source_record_id: string>, created_at: string, updated_at: string, deleted_at: string, billing_info: record<three_d_secure_action_result_token_id: string>, ramp_intervals: table<starting_billing_cycle: int, remaining_billing_cycles: int, starting_on: string, ending_on: string, unit_amount: float>, next_bill_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/change/preview")
  let body = {timeframe: $timeframe, plan_id: $plan_id, plan_code: $plan_code, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, price_segment_id: $price_segment_id, unit_amount: $unit_amount, tax_inclusive: $tax_inclusive, quantity: $quantity, shipping: $shipping, coupon_codes: $coupon_codes, add_ons: $add_ons, collection_method: $collection_method, revenue_schedule_type: $revenue_schedule_type, custom_fields: $custom_fields, po_number: $po_number, net_terms: $net_terms, net_terms_type: $net_terms_type, transaction_type: $transaction_type, billing_info: $billing_info, ramp_intervals: $ramp_intervals, proration_settings: $proration_settings, next_bill_date: $next_bill_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a subscription's invoices
#
# GET /subscriptions/{subscription_id}/invoices
# operationId: list_subscription_invoices
export def "subscriptions-invoices invoices" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --state: string@state-completer-1 # Invoice state. (default: all)
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --type: string@type-completer-1 # Filter by type when: - `type=charge`, only charge invoices will be returned. - `type=credit`, only credit invoices will be returned. - `type=non-legacy`, only charge and credit invoices will be returned. - `type=legacy`, only legacy invoices will be returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a subscription's line items
#
# GET /subscriptions/{subscription_id}/line_items
# operationId: list_subscription_line_items
export def "subscriptions-line-items items" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --original: string@original-completer # Filter by original field.
  --state: string@state-completer-2 # Filter by state field.
  --type: string@type-completer-2 # Filter by type field.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, type: string, item_code: string, item_id: string, external_sku: string, revenue_schedule_type: string, state: string, legacy_category: string, account: record, bill_for_account_id: string, subscription_id: string, plan_id: string, plan_code: string, add_on_id: string, add_on_code: string, invoice_id: string, invoice_number: string, previous_line_item_id: string, original_line_item_invoice_id: string, origin: string, accounting_code: string, product_code: string, credit_reason_code: string, currency: string, amount: float, description: string, quantity: int, quantity_decimal: string, unit_amount: float, unit_amount_decimal: string, tax_inclusive: bool, subtotal: float, discount: float, discounts: list, liability_gl_account_code: string, revenue_gl_account_code: string, performance_obligation_id: string, tax: float, taxable: bool, tax_exempt: bool, avalara_transaction_type: int, avalara_service_type: int, vertex_transaction_type: string, tax_code: string, harmonized_system_code: string, tax_info: record, origin_tax_address_source: string, destination_tax_address_source: string, proration_rate: float, refund: bool, refunded_quantity: int, refunded_quantity_decimal: string, credit_applied: float, shipping_address: record, start_date: string, end_date: string, custom_fields: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "original" $original "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/line_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the coupon redemptions for a subscription
#
# GET /subscriptions/{subscription_id}/coupon_redemptions
# operationId: list_subscription_coupon_redemptions
export def "subscriptions-coupon-redemptions redemptions" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, account: record, subscription_id: string, coupon: record, state: string, remaining_duration: record, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/coupon_redemptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show the coupon redemption for a subscription
#
# GET /subscriptions/{subscription_id}/coupon_redemptions/{coupon_redemption_id}
# operationId: get_subscription_coupon_redemption
export def "subscriptions-coupon-redemptions redemption-by-subscription_id-coupon_redemption_id" [
  subscription_id: string
  coupon_redemption_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, subscription_id: string, coupon: record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: list<record>, items: list<record>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list, trial: record>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string>, state: string, remaining_duration: record<type: string, expires_at: string>, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/coupon_redemptions/($coupon_redemption_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the coupon redemption from a subscription
#
# DELETE /subscriptions/{subscription_id}/coupon_redemptions/{coupon_redemption_id}
# operationId: remove_subscription_coupon_redemption
export def "subscriptions-coupon-redemptions redemption-by-subscription_id-coupon_redemption_id-1" [
  subscription_id: string
  coupon_redemption_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, subscription_id: string, coupon: record<id: string, object: string, code: string, name: string, state: string, max_redemptions: int, max_redemptions_per_account: int, unique_coupon_codes_count: int, unique_code_template: string, unique_coupon_code: record, duration: string, temporal_amount: int, temporal_unit: string, free_trial_unit: string, free_trial_amount: int, applies_to_all_plans: bool, applies_to_all_items: bool, applies_to_non_plan_charges: bool, plans: list<record>, items: list<record>, redemption_resource: string, discount: record<type: string, percent: int, currencies: list, trial: record>, coupon_type: string, hosted_page_description: string, invoice_description: string, redeem_by: string, created_at: string, updated_at: string, expired_at: string>, state: string, remaining_duration: record<type: string, expires_at: string>, currency: string, discounted: float, created_at: string, updated_at: string, removed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/coupon_redemptions/($coupon_redemption_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a subscription add-on's usage records
#
# GET /subscriptions/{subscription_id}/add_ons/{add_on_id}/usage
# operationId: list_usage
export def "subscriptions-add-ons-usage usage-by-subscription_id-add_on_id" [
  subscription_id: string
  add_on_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer-1 # Sort field. You *really* only want to sort by `usage_timestamp` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.  (default: usage_timestamp)
  --begin-time: string # Inclusively filter by begin_time when `sort=usage_timestamp` or `sort=recorded_timestamp`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=usage_timestamp` or `sort=recorded_timestamp`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --billing-status: string@billing-status-completer # Filter by usage record's billing status (default: unbilled)
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, merchant_tag: string, amount: float, usage_type: string, tier_type: string, tiers: list, percentage_tiers: list, measured_unit_id: string, recording_timestamp: string, usage_timestamp: string, usage_percentage: float, unit_amount: float, unit_amount_decimal: string, billed_at: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "billing_status" $billing_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/add_ons/($add_on_id)/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Log a usage record on this subscription add-on
#
# POST /subscriptions/{subscription_id}/add_ons/{add_on_id}/usage
# operationId: create_usage
export def "subscriptions-add-ons-usage usage-by-subscription_id-add_on_id-1" [
  subscription_id: string
  add_on_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merchant-tag: string # Custom field for recording the id in your own system associated with the usage, so you can provide auditable usage displays to your customers using a GET on this endpoint.
  --amount: float # The amount of usage. Can be positive, negative, or 0. If the Decimal Quantity feature is enabled, this value will be rounded to nine decimal places.  Otherwise, all digits after the decimal will be stripped. If the usage-based add-on is billed with a percentage, your usage should be a monetary amount formatted in cents (e.g., $5.00 is "500"). (format: float)
  --recording-timestamp: string # When the usage was recorded in your system. (format: date-time)
  --usage-timestamp: string # When the usage actually happened. This will define the line item dates this usage is billed under and is important for revenue recognition. (format: date-time)
]: any -> record<id: string, object: string, merchant_tag: string, amount: float, usage_type: string, tier_type: string, tiers: table<ending_quantity: int, unit_amount: float, unit_amount_decimal: string, usage_percentage: string>, percentage_tiers: table<ending_amount: float, usage_percentage: string>, measured_unit_id: string, recording_timestamp: string, usage_timestamp: string, usage_percentage: float, unit_amount: float, unit_amount_decimal: string, billed_at: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/add_ons/($add_on_id)/usage")
  let body = {merchant_tag: $merchant_tag, amount: $amount, recording_timestamp: $recording_timestamp, usage_timestamp: $usage_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a usage record
#
# GET /usage/{usage_id}
# operationId: get_usage
export def "usage usage-by-usage_id" [
  usage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, merchant_tag: string, amount: float, usage_type: string, tier_type: string, tiers: table<ending_quantity: int, unit_amount: float, unit_amount_decimal: string, usage_percentage: string>, percentage_tiers: table<ending_amount: float, usage_percentage: string>, measured_unit_id: string, recording_timestamp: string, usage_timestamp: string, usage_percentage: float, unit_amount: float, unit_amount_decimal: string, billed_at: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usage/($usage_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a usage record
#
# PUT /usage/{usage_id}
# operationId: update_usage
export def "usage usage-by-usage_id-1" [
  usage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merchant-tag: string # Custom field for recording the id in your own system associated with the usage, so you can provide auditable usage displays to your customers using a GET on this endpoint.
  --amount: float # The amount of usage. Can be positive, negative, or 0. If the Decimal Quantity feature is enabled, this value will be rounded to nine decimal places.  Otherwise, all digits after the decimal will be stripped. If the usage-based add-on is billed with a percentage, your usage should be a monetary amount formatted in cents (e.g., $5.00 is "500"). (format: float)
  --recording-timestamp: string # When the usage was recorded in your system. (format: date-time)
  --usage-timestamp: string # When the usage actually happened. This will define the line item dates this usage is billed under and is important for revenue recognition. (format: date-time)
]: any -> record<id: string, object: string, merchant_tag: string, amount: float, usage_type: string, tier_type: string, tiers: table<ending_quantity: int, unit_amount: float, unit_amount_decimal: string, usage_percentage: string>, percentage_tiers: table<ending_amount: float, usage_percentage: string>, measured_unit_id: string, recording_timestamp: string, usage_timestamp: string, usage_percentage: float, unit_amount: float, unit_amount_decimal: string, billed_at: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usage/($usage_id)")
  let body = {merchant_tag: $merchant_tag, amount: $amount, recording_timestamp: $recording_timestamp, usage_timestamp: $usage_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a usage record.
#
# DELETE /usage/{usage_id}
# operationId: remove_usage
export def "usage usage-by-usage_id-2" [
  usage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, message: string, params: table<param: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usage/($usage_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a site's transactions
#
# GET /transactions
# operationId: list_transactions
export def "transactions transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --type: string@type-completer-3 # Filter by type field. The value `payment` will return both `purchase` and `capture` transactions.
  --success: string@success-completer # Filter by success field.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "success" $success "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a transaction
#
# GET /transactions/{transaction_id}
# operationId: get_transaction
export def "transactions transaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, uuid: string, original_transaction_id: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, initiator: string, invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, merchant_reason_code: string, voided_by_invoice: record<id: string, object: string, number: string, business_entity_id: string, type: string, state: string>, subscription_ids: list<string>, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record<first_name: string, last_name: string>, collection_method: string, payment_method: record<object: string, card_type: string, first_six: string, last_four: string, last_two: string, exp_month: int, exp_year: int, gateway_token: string, cc_bin_country: string, funding_source: string, gateway_code: string, gateway_attributes: record<account_reference: string>, card_network_preference: string, billing_agreement_id: string, name_on_account: string, account_type: string, routing_number: string, routing_number_bank: string, username: string>, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record<id: string, object: string, type: string, name: string>, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record<object: string, score: int, decision: string, reference: string, risk_rules_triggered: list<record>>, next_action: record<type: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a unique coupon code
#
# GET /unique_coupon_codes/{unique_coupon_code_id}
# operationId: get_unique_coupon_code
export def "unique-coupon-codes code-by-unique_coupon_code_id" [
  unique_coupon_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, state: string, bulk_coupon_id: string, bulk_coupon_code: string, created_at: string, updated_at: string, redeemed_at: string, expired_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/unique_coupon_codes/($unique_coupon_code_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate a unique coupon code
#
# DELETE /unique_coupon_codes/{unique_coupon_code_id}
# operationId: deactivate_unique_coupon_code
export def "unique-coupon-codes code-by-unique_coupon_code_id-1" [
  unique_coupon_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, state: string, bulk_coupon_id: string, bulk_coupon_code: string, created_at: string, updated_at: string, redeemed_at: string, expired_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/unique_coupon_codes/($unique_coupon_code_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore a unique coupon code
#
# PUT /unique_coupon_codes/{unique_coupon_code_id}/restore
# operationId: reactivate_unique_coupon_code
export def "unique-coupon-codes-restore code" [
  unique_coupon_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, state: string, bulk_coupon_id: string, bulk_coupon_code: string, created_at: string, updated_at: string, redeemed_at: string, expired_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/unique_coupon_codes/($unique_coupon_code_id)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new purchase
#
# POST /purchases
# operationId: create_purchase
# --credit_application_policy_override shape: {mode: "all"|"none", allowed_origins?: list}
# --transaction shape: {initiator?: any, merchant_reason_code?: any, skip_gateway_fraud?: bool, skip_recurly_fraud?: bool, skip_all_fraud?: bool}
# --shipping shape: {address_id?: string, address?: record, fees?: list}
# --line_items item shape: {currency: string, unit_amount: float, tax_inclusive?: bool, quantity?: int, description?: string, item_code?: string, item_id?: string, revenue_schedule_type?: "at_invoice"|"at_range_end"|"at_range_start"|"evenly"|"never", type: "charge"|"credit", credit_reason_code?: "general"|"promotional"|"service", accounting_code?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, tax_exempt?: bool, avalara_transaction_type?: int, avalara_service_type?: int, vertex_transaction_type?: "sale"|"rental"|"lease", tax_code?: string, harmonized_system_code?: string, product_code?: string, origin?: "external_gift_card"|"prepayment", custom_fields?: list, start_date?: string, end_date?: string, origin_tax_address_source?: "origin"|"destination", destination_tax_address_source?: "destination"|"origin"}
# --subscriptions item shape: {plan_code: string, plan_id?: string, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool, quantity?: int, add_ons?: list, custom_fields?: list, shipping?: record, trial_ends_at?: string, starts_at?: string, next_bill_date?: string, total_billing_cycles?: int, renewal_billing_cycles?: int, auto_renew?: bool, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", ramp_intervals?: list, credit_application_policy?: record, bulk?: bool, proration_settings?: record}
export def "purchases purchase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currency: string # 3-letter ISO 4217 currency code.
  account: any
  --billing-info-id: string # The `billing_info_id` is the value that represents a specific billing info for an end customer. When `billing_info_id` is used to assign billing info to the subscription, all future billing events for the subscription will bill to the specified billing info. `billing_info_id` can ONLY be used for sites utilizing the Wallet feature.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer. When `business_entity_id` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer. When `business_entity_code` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --collection-method: string@collection-method-completer
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --net-terms: int # Integer paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. For `manual` collection method, an additional 24 hours is added to ensure the customer has the entire last day to make payment before becoming past due. For example:  If an invoice is due `net 0`, it is due 'On Receipt' and will become past due 24 hours after it's created. If an invoice is due `net 30`, it will become past due at 31 days exactly. If an invoice is due `eom 30`, it will become past due 31 days from the last day of the current month.  For `automatic` collection method, the additional 24 hours is not added. For example, On-Receipt is due immediately, and `net 30` will become due exactly 30 days from invoice generation, at which point Recurly will attempt collection. When `eom` Net Terms Type is passed, the value for `Net Terms` is restricted to `0, 15, 30, 45, 60, or 90`.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --credit-application-policy-override: record # Controls whether credit invoices are automatically applied to new invoices. The `mode` field determines the application behavior. When mode is `all`, the optional `allowed_origins` array can restrict which credit invoice origins are applied. — shape: {mode: "all"|"none", allowed_origins?: list}
  --terms-and-conditions: string # Terms and conditions to be put on the purchase invoice.
  --transaction: record # (Transaction Data, Card on File) - Options for flagging transactions as Customer or Merchant Initiated Unscheduled. — shape: {initiator?: any, merchant_reason_code?: any, skip_gateway_fraud?: bool, skip_recurly_fraud?: bool, skip_all_fraud?: bool}
  --customer-notes: string
  --vat-reverse-charge-notes: string # VAT reverse charge notes for cross border European tax settlement.
  --vertex-transaction-type: string@vertex-transaction-type-completer # Used by Vertex for tax calculations. Possible values are sale, rental, lease.
  --credit-customer-notes: string # Notes to be put on the credit invoice resulting from credits in the purchase, if any.
  --gateway-code: string # The default payment gateway identifier to be used for the purchase transaction.  This will also be applied as the default for any subscriptions included in the purchase request.
  --shipping: record # shape: {address_id?: string, address?: record, fees?: list}
  --line-items: list # A list of one time charges or credits to be created with the purchase. — item shape: {currency: string, unit_amount: float, tax_inclusive?: bool, quantity?: int, description?: string, item_code?: string, item_id?: string, revenue_schedule_type?: "at_invoice"|"at_range_end"|"at_range_start"|"evenly"|"never", type: "charge"|"credit", credit_reason_code?: "general"|"promotional"|"service", accounting_code?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, tax_exempt?: bool, avalara_transaction_type?: int, avalara_service_type?: int, vertex_transaction_type?: "sale"|"rental"|"lease", tax_code?: string, harmonized_system_code?: string, product_code?: string, origin?: "external_gift_card"|"prepayment", custom_fields?: list, start_date?: string, end_date?: string, origin_tax_address_source?: "origin"|"destination", destination_tax_address_source?: "destination"|"origin"}
  --subscriptions: list # A list of subscriptions to be created with the purchase. — item shape: {plan_code: string, plan_id?: string, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool, quantity?: int, add_ons?: list, custom_fields?: list, shipping?: record, trial_ends_at?: string, starts_at?: string, next_bill_date?: string, total_billing_cycles?: int, renewal_billing_cycles?: int, auto_renew?: bool, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", ramp_intervals?: list, credit_application_policy?: record, bulk?: bool, proration_settings?: record}
  --coupon-codes: list # A list of coupon_codes to be redeemed on the subscription or account during the purchase.
  --gift-card-redemption-code: string # A gift card redemption code to be redeemed on the purchase invoice.
  --transaction-type: string@transaction-type-completer
]: any -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/purchases")
  let body = {currency: $currency, account: $account, billing_info_id: $billing_info_id, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, collection_method: $collection_method, po_number: $po_number, net_terms: $net_terms, net_terms_type: $net_terms_type, credit_application_policy_override: $credit_application_policy_override, terms_and_conditions: $terms_and_conditions, transaction: $transaction, customer_notes: $customer_notes, vat_reverse_charge_notes: $vat_reverse_charge_notes, vertex_transaction_type: $vertex_transaction_type, credit_customer_notes: $credit_customer_notes, gateway_code: $gateway_code, shipping: $shipping, line_items: $line_items, subscriptions: $subscriptions, coupon_codes: $coupon_codes, gift_card_redemption_code: $gift_card_redemption_code, transaction_type: $transaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preview a new purchase
#
# POST /purchases/preview
# operationId: preview_purchase
# --credit_application_policy_override shape: {mode: "all"|"none", allowed_origins?: list}
# --transaction shape: {initiator?: any, merchant_reason_code?: any, skip_gateway_fraud?: bool, skip_recurly_fraud?: bool, skip_all_fraud?: bool}
# --shipping shape: {address_id?: string, address?: record, fees?: list}
# --line_items item shape: {currency: string, unit_amount: float, tax_inclusive?: bool, quantity?: int, description?: string, item_code?: string, item_id?: string, revenue_schedule_type?: "at_invoice"|"at_range_end"|"at_range_start"|"evenly"|"never", type: "charge"|"credit", credit_reason_code?: "general"|"promotional"|"service", accounting_code?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, tax_exempt?: bool, avalara_transaction_type?: int, avalara_service_type?: int, vertex_transaction_type?: "sale"|"rental"|"lease", tax_code?: string, harmonized_system_code?: string, product_code?: string, origin?: "external_gift_card"|"prepayment", custom_fields?: list, start_date?: string, end_date?: string, origin_tax_address_source?: "origin"|"destination", destination_tax_address_source?: "destination"|"origin"}
# --subscriptions item shape: {plan_code: string, plan_id?: string, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool, quantity?: int, add_ons?: list, custom_fields?: list, shipping?: record, trial_ends_at?: string, starts_at?: string, next_bill_date?: string, total_billing_cycles?: int, renewal_billing_cycles?: int, auto_renew?: bool, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", ramp_intervals?: list, credit_application_policy?: record, bulk?: bool, proration_settings?: record}
export def "purchases-preview purchase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currency: string # 3-letter ISO 4217 currency code.
  account: any
  --billing-info-id: string # The `billing_info_id` is the value that represents a specific billing info for an end customer. When `billing_info_id` is used to assign billing info to the subscription, all future billing events for the subscription will bill to the specified billing info. `billing_info_id` can ONLY be used for sites utilizing the Wallet feature.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer. When `business_entity_id` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer. When `business_entity_code` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --collection-method: string@collection-method-completer
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --net-terms: int # Integer paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. For `manual` collection method, an additional 24 hours is added to ensure the customer has the entire last day to make payment before becoming past due. For example:  If an invoice is due `net 0`, it is due 'On Receipt' and will become past due 24 hours after it's created. If an invoice is due `net 30`, it will become past due at 31 days exactly. If an invoice is due `eom 30`, it will become past due 31 days from the last day of the current month.  For `automatic` collection method, the additional 24 hours is not added. For example, On-Receipt is due immediately, and `net 30` will become due exactly 30 days from invoice generation, at which point Recurly will attempt collection. When `eom` Net Terms Type is passed, the value for `Net Terms` is restricted to `0, 15, 30, 45, 60, or 90`.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --credit-application-policy-override: record # Controls whether credit invoices are automatically applied to new invoices. The `mode` field determines the application behavior. When mode is `all`, the optional `allowed_origins` array can restrict which credit invoice origins are applied. — shape: {mode: "all"|"none", allowed_origins?: list}
  --terms-and-conditions: string # Terms and conditions to be put on the purchase invoice.
  --transaction: record # (Transaction Data, Card on File) - Options for flagging transactions as Customer or Merchant Initiated Unscheduled. — shape: {initiator?: any, merchant_reason_code?: any, skip_gateway_fraud?: bool, skip_recurly_fraud?: bool, skip_all_fraud?: bool}
  --customer-notes: string
  --vat-reverse-charge-notes: string # VAT reverse charge notes for cross border European tax settlement.
  --vertex-transaction-type: string@vertex-transaction-type-completer # Used by Vertex for tax calculations. Possible values are sale, rental, lease.
  --credit-customer-notes: string # Notes to be put on the credit invoice resulting from credits in the purchase, if any.
  --gateway-code: string # The default payment gateway identifier to be used for the purchase transaction.  This will also be applied as the default for any subscriptions included in the purchase request.
  --shipping: record # shape: {address_id?: string, address?: record, fees?: list}
  --line-items: list # A list of one time charges or credits to be created with the purchase. — item shape: {currency: string, unit_amount: float, tax_inclusive?: bool, quantity?: int, description?: string, item_code?: string, item_id?: string, revenue_schedule_type?: "at_invoice"|"at_range_end"|"at_range_start"|"evenly"|"never", type: "charge"|"credit", credit_reason_code?: "general"|"promotional"|"service", accounting_code?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, tax_exempt?: bool, avalara_transaction_type?: int, avalara_service_type?: int, vertex_transaction_type?: "sale"|"rental"|"lease", tax_code?: string, harmonized_system_code?: string, product_code?: string, origin?: "external_gift_card"|"prepayment", custom_fields?: list, start_date?: string, end_date?: string, origin_tax_address_source?: "origin"|"destination", destination_tax_address_source?: "destination"|"origin"}
  --subscriptions: list # A list of subscriptions to be created with the purchase. — item shape: {plan_code: string, plan_id?: string, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool, quantity?: int, add_ons?: list, custom_fields?: list, shipping?: record, trial_ends_at?: string, starts_at?: string, next_bill_date?: string, total_billing_cycles?: int, renewal_billing_cycles?: int, auto_renew?: bool, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", ramp_intervals?: list, credit_application_policy?: record, bulk?: bool, proration_settings?: record}
  --coupon-codes: list # A list of coupon_codes to be redeemed on the subscription or account during the purchase.
  --gift-card-redemption-code: string # A gift card redemption code to be redeemed on the purchase invoice.
  --transaction-type: string@transaction-type-completer
]: any -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/purchases/preview")
  let body = {currency: $currency, account: $account, billing_info_id: $billing_info_id, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, collection_method: $collection_method, po_number: $po_number, net_terms: $net_terms, net_terms_type: $net_terms_type, credit_application_policy_override: $credit_application_policy_override, terms_and_conditions: $terms_and_conditions, transaction: $transaction, customer_notes: $customer_notes, vat_reverse_charge_notes: $vat_reverse_charge_notes, vertex_transaction_type: $vertex_transaction_type, credit_customer_notes: $credit_customer_notes, gateway_code: $gateway_code, shipping: $shipping, line_items: $line_items, subscriptions: $subscriptions, coupon_codes: $coupon_codes, gift_card_redemption_code: $gift_card_redemption_code, transaction_type: $transaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a pending purchase
#
# POST /purchases/pending
# operationId: create_pending_purchase
# --credit_application_policy_override shape: {mode: "all"|"none", allowed_origins?: list}
# --transaction shape: {initiator?: any, merchant_reason_code?: any, skip_gateway_fraud?: bool, skip_recurly_fraud?: bool, skip_all_fraud?: bool}
# --shipping shape: {address_id?: string, address?: record, fees?: list}
# --line_items item shape: {currency: string, unit_amount: float, tax_inclusive?: bool, quantity?: int, description?: string, item_code?: string, item_id?: string, revenue_schedule_type?: "at_invoice"|"at_range_end"|"at_range_start"|"evenly"|"never", type: "charge"|"credit", credit_reason_code?: "general"|"promotional"|"service", accounting_code?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, tax_exempt?: bool, avalara_transaction_type?: int, avalara_service_type?: int, vertex_transaction_type?: "sale"|"rental"|"lease", tax_code?: string, harmonized_system_code?: string, product_code?: string, origin?: "external_gift_card"|"prepayment", custom_fields?: list, start_date?: string, end_date?: string, origin_tax_address_source?: "origin"|"destination", destination_tax_address_source?: "destination"|"origin"}
# --subscriptions item shape: {plan_code: string, plan_id?: string, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool, quantity?: int, add_ons?: list, custom_fields?: list, shipping?: record, trial_ends_at?: string, starts_at?: string, next_bill_date?: string, total_billing_cycles?: int, renewal_billing_cycles?: int, auto_renew?: bool, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", ramp_intervals?: list, credit_application_policy?: record, bulk?: bool, proration_settings?: record}
export def "purchases-pending purchase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currency: string # 3-letter ISO 4217 currency code.
  account: any
  --billing-info-id: string # The `billing_info_id` is the value that represents a specific billing info for an end customer. When `billing_info_id` is used to assign billing info to the subscription, all future billing events for the subscription will bill to the specified billing info. `billing_info_id` can ONLY be used for sites utilizing the Wallet feature.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer. When `business_entity_id` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer. When `business_entity_code` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --collection-method: string@collection-method-completer
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --net-terms: int # Integer paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. For `manual` collection method, an additional 24 hours is added to ensure the customer has the entire last day to make payment before becoming past due. For example:  If an invoice is due `net 0`, it is due 'On Receipt' and will become past due 24 hours after it's created. If an invoice is due `net 30`, it will become past due at 31 days exactly. If an invoice is due `eom 30`, it will become past due 31 days from the last day of the current month.  For `automatic` collection method, the additional 24 hours is not added. For example, On-Receipt is due immediately, and `net 30` will become due exactly 30 days from invoice generation, at which point Recurly will attempt collection. When `eom` Net Terms Type is passed, the value for `Net Terms` is restricted to `0, 15, 30, 45, 60, or 90`.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --credit-application-policy-override: record # Controls whether credit invoices are automatically applied to new invoices. The `mode` field determines the application behavior. When mode is `all`, the optional `allowed_origins` array can restrict which credit invoice origins are applied. — shape: {mode: "all"|"none", allowed_origins?: list}
  --terms-and-conditions: string # Terms and conditions to be put on the purchase invoice.
  --transaction: record # (Transaction Data, Card on File) - Options for flagging transactions as Customer or Merchant Initiated Unscheduled. — shape: {initiator?: any, merchant_reason_code?: any, skip_gateway_fraud?: bool, skip_recurly_fraud?: bool, skip_all_fraud?: bool}
  --customer-notes: string
  --vat-reverse-charge-notes: string # VAT reverse charge notes for cross border European tax settlement.
  --vertex-transaction-type: string@vertex-transaction-type-completer # Used by Vertex for tax calculations. Possible values are sale, rental, lease.
  --credit-customer-notes: string # Notes to be put on the credit invoice resulting from credits in the purchase, if any.
  --gateway-code: string # The default payment gateway identifier to be used for the purchase transaction.  This will also be applied as the default for any subscriptions included in the purchase request.
  --shipping: record # shape: {address_id?: string, address?: record, fees?: list}
  --line-items: list # A list of one time charges or credits to be created with the purchase. — item shape: {currency: string, unit_amount: float, tax_inclusive?: bool, quantity?: int, description?: string, item_code?: string, item_id?: string, revenue_schedule_type?: "at_invoice"|"at_range_end"|"at_range_start"|"evenly"|"never", type: "charge"|"credit", credit_reason_code?: "general"|"promotional"|"service", accounting_code?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, tax_exempt?: bool, avalara_transaction_type?: int, avalara_service_type?: int, vertex_transaction_type?: "sale"|"rental"|"lease", tax_code?: string, harmonized_system_code?: string, product_code?: string, origin?: "external_gift_card"|"prepayment", custom_fields?: list, start_date?: string, end_date?: string, origin_tax_address_source?: "origin"|"destination", destination_tax_address_source?: "destination"|"origin"}
  --subscriptions: list # A list of subscriptions to be created with the purchase. — item shape: {plan_code: string, plan_id?: string, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool, quantity?: int, add_ons?: list, custom_fields?: list, shipping?: record, trial_ends_at?: string, starts_at?: string, next_bill_date?: string, total_billing_cycles?: int, renewal_billing_cycles?: int, auto_renew?: bool, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", ramp_intervals?: list, credit_application_policy?: record, bulk?: bool, proration_settings?: record}
  --coupon-codes: list # A list of coupon_codes to be redeemed on the subscription or account during the purchase.
  --gift-card-redemption-code: string # A gift card redemption code to be redeemed on the purchase invoice.
  --transaction-type: string@transaction-type-completer
]: any -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/purchases/pending")
  let body = {currency: $currency, account: $account, billing_info_id: $billing_info_id, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, collection_method: $collection_method, po_number: $po_number, net_terms: $net_terms, net_terms_type: $net_terms_type, credit_application_policy_override: $credit_application_policy_override, terms_and_conditions: $terms_and_conditions, transaction: $transaction, customer_notes: $customer_notes, vat_reverse_charge_notes: $vat_reverse_charge_notes, vertex_transaction_type: $vertex_transaction_type, credit_customer_notes: $credit_customer_notes, gateway_code: $gateway_code, shipping: $shipping, line_items: $line_items, subscriptions: $subscriptions, coupon_codes: $coupon_codes, gift_card_redemption_code: $gift_card_redemption_code, transaction_type: $transaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authorize a purchase
#
# POST /purchases/authorize
# operationId: create_authorize_purchase
# --credit_application_policy_override shape: {mode: "all"|"none", allowed_origins?: list}
# --transaction shape: {initiator?: any, merchant_reason_code?: any, skip_gateway_fraud?: bool, skip_recurly_fraud?: bool, skip_all_fraud?: bool}
# --shipping shape: {address_id?: string, address?: record, fees?: list}
# --line_items item shape: {currency: string, unit_amount: float, tax_inclusive?: bool, quantity?: int, description?: string, item_code?: string, item_id?: string, revenue_schedule_type?: "at_invoice"|"at_range_end"|"at_range_start"|"evenly"|"never", type: "charge"|"credit", credit_reason_code?: "general"|"promotional"|"service", accounting_code?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, tax_exempt?: bool, avalara_transaction_type?: int, avalara_service_type?: int, vertex_transaction_type?: "sale"|"rental"|"lease", tax_code?: string, harmonized_system_code?: string, product_code?: string, origin?: "external_gift_card"|"prepayment", custom_fields?: list, start_date?: string, end_date?: string, origin_tax_address_source?: "origin"|"destination", destination_tax_address_source?: "destination"|"origin"}
# --subscriptions item shape: {plan_code: string, plan_id?: string, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool, quantity?: int, add_ons?: list, custom_fields?: list, shipping?: record, trial_ends_at?: string, starts_at?: string, next_bill_date?: string, total_billing_cycles?: int, renewal_billing_cycles?: int, auto_renew?: bool, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", ramp_intervals?: list, credit_application_policy?: record, bulk?: bool, proration_settings?: record}
export def "purchases-authorize purchase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currency: string # 3-letter ISO 4217 currency code.
  account: any
  --billing-info-id: string # The `billing_info_id` is the value that represents a specific billing info for an end customer. When `billing_info_id` is used to assign billing info to the subscription, all future billing events for the subscription will bill to the specified billing info. `billing_info_id` can ONLY be used for sites utilizing the Wallet feature.
  --business-entity-id: string # The `business_entity_id` is the value that represents a specific business entity for an end customer. When `business_entity_id` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --business-entity-code: string # The `business_entity_code` is the value that represents a specific business entity for an end customer. When `business_entity_code` is used to assign a business entity to the subscription, all future billing events for the subscription will bill to the specified business entity. Available when the `Multiple Business Entities` feature is enabled. If both `business_entity_id` and `business_entity_code` are present, `business_entity_id` will be used.
  --collection-method: string@collection-method-completer
  --po-number: string # For manual invoicing, this identifies the PO number associated with the subscription.
  --net-terms: int # Integer paired with `Net Terms Type` and representing the number of days past the current date (for `net` Net Terms Type) or days after the last day of the current month (for `eom` Net Terms Type) that the invoice will become past due. For `manual` collection method, an additional 24 hours is added to ensure the customer has the entire last day to make payment before becoming past due. For example:  If an invoice is due `net 0`, it is due 'On Receipt' and will become past due 24 hours after it's created. If an invoice is due `net 30`, it will become past due at 31 days exactly. If an invoice is due `eom 30`, it will become past due 31 days from the last day of the current month.  For `automatic` collection method, the additional 24 hours is not added. For example, On-Receipt is due immediately, and `net 30` will become due exactly 30 days from invoice generation, at which point Recurly will attempt collection. When `eom` Net Terms Type is passed, the value for `Net Terms` is restricted to `0, 15, 30, 45, 60, or 90`.  For more information on how net terms work with `manual` collection visit our docs page (https://docs.recurly.com/docs/manual-payments#section-collection-terms) or visit (https://docs.recurly.com/docs/automatic-invoicing-terms#section-collection-terms) for information about net terms using `automatic` collection. (default: 0)
  --net-terms-type: string@net-terms-type-completer # Optionally supplied string that may be either `net` or `eom` (end-of-month). When `net`, an invoice becomes past due the specified number of `Net Terms` days from the current date. When `eom` an invoice becomes past due the specified number of `Net Terms` days from the last day of the current month.  (default: net)
  --credit-application-policy-override: record # Controls whether credit invoices are automatically applied to new invoices. The `mode` field determines the application behavior. When mode is `all`, the optional `allowed_origins` array can restrict which credit invoice origins are applied. — shape: {mode: "all"|"none", allowed_origins?: list}
  --terms-and-conditions: string # Terms and conditions to be put on the purchase invoice.
  --transaction: record # (Transaction Data, Card on File) - Options for flagging transactions as Customer or Merchant Initiated Unscheduled. — shape: {initiator?: any, merchant_reason_code?: any, skip_gateway_fraud?: bool, skip_recurly_fraud?: bool, skip_all_fraud?: bool}
  --customer-notes: string
  --vat-reverse-charge-notes: string # VAT reverse charge notes for cross border European tax settlement.
  --vertex-transaction-type: string@vertex-transaction-type-completer # Used by Vertex for tax calculations. Possible values are sale, rental, lease.
  --credit-customer-notes: string # Notes to be put on the credit invoice resulting from credits in the purchase, if any.
  --gateway-code: string # The default payment gateway identifier to be used for the purchase transaction.  This will also be applied as the default for any subscriptions included in the purchase request.
  --shipping: record # shape: {address_id?: string, address?: record, fees?: list}
  --line-items: list # A list of one time charges or credits to be created with the purchase. — item shape: {currency: string, unit_amount: float, tax_inclusive?: bool, quantity?: int, description?: string, item_code?: string, item_id?: string, revenue_schedule_type?: "at_invoice"|"at_range_end"|"at_range_start"|"evenly"|"never", type: "charge"|"credit", credit_reason_code?: "general"|"promotional"|"service", accounting_code?: string, liability_gl_account_id?: string, revenue_gl_account_id?: string, performance_obligation_id?: string, tax_exempt?: bool, avalara_transaction_type?: int, avalara_service_type?: int, vertex_transaction_type?: "sale"|"rental"|"lease", tax_code?: string, harmonized_system_code?: string, product_code?: string, origin?: "external_gift_card"|"prepayment", custom_fields?: list, start_date?: string, end_date?: string, origin_tax_address_source?: "origin"|"destination", destination_tax_address_source?: "destination"|"origin"}
  --subscriptions: list # A list of subscriptions to be created with the purchase. — item shape: {plan_code: string, plan_id?: string, unit_amount?: float, price_segment_id?: string, tax_inclusive?: bool, quantity?: int, add_ons?: list, custom_fields?: list, shipping?: record, trial_ends_at?: string, starts_at?: string, next_bill_date?: string, total_billing_cycles?: int, renewal_billing_cycles?: int, auto_renew?: bool, revenue_schedule_type?: "at_range_end"|"at_range_start"|"evenly"|"never", ramp_intervals?: list, credit_application_policy?: record, bulk?: bool, proration_settings?: record}
  --coupon-codes: list # A list of coupon_codes to be redeemed on the subscription or account during the purchase.
  --gift-card-redemption-code: string # A gift card redemption code to be redeemed on the purchase invoice.
  --transaction-type: string@transaction-type-completer
]: any -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/purchases/authorize")
  let body = {currency: $currency, account: $account, billing_info_id: $billing_info_id, business_entity_id: $business_entity_id, business_entity_code: $business_entity_code, collection_method: $collection_method, po_number: $po_number, net_terms: $net_terms, net_terms_type: $net_terms_type, credit_application_policy_override: $credit_application_policy_override, terms_and_conditions: $terms_and_conditions, transaction: $transaction, customer_notes: $customer_notes, vat_reverse_charge_notes: $vat_reverse_charge_notes, vertex_transaction_type: $vertex_transaction_type, credit_customer_notes: $credit_customer_notes, gateway_code: $gateway_code, shipping: $shipping, line_items: $line_items, subscriptions: $subscriptions, coupon_codes: $coupon_codes, gift_card_redemption_code: $gift_card_redemption_code, transaction_type: $transaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Capture a purchase
#
# POST /purchases/{transaction_id}/capture
# operationId: create_capture_purchase
export def "purchases-capture purchase" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/purchases/($transaction_id)/capture")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Purchase
#
# POST /purchases/{transaction_id}/cancel/
# operationId: cancelPurchase
export def "purchases-cancel cancelPurchase" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, charge_invoice: record<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, billing_info_id: string, subscription_ids: list<string>, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record<name_on_account: string, company: string>, shipping_address: record<id: string, object: string, account_id: string, nickname: string, first_name: string, last_name: string, company: string, email: string, vat_number: string, phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string, created_at: string, updated_at: string>, currency: string, discount: float, coupon_redemptions: list<record>, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record<currency: string, subtotal_in_cents: float, tax_in_cents: float, rate: string, source: string, date: string>, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record<type: string, region: string, rate: float, tax_details: list>, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list<record>, has_more_line_items: bool, transactions: list<record>, credit_payments: list<record>, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list<record>>, credit_invoices: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>, verification_transactions: table<id: string, object: string, uuid: string, original_transaction_id: string, account: record, initiator: string, invoice: record, merchant_reason_code: string, voided_by_invoice: record, subscription_ids: list, type: string, origin: string, currency: string, amount: float, status: string, success: bool, backup_payment_method_used: bool, refunded: bool, billing_address: record, collection_method: string, payment_method: record, ip_address_v4: string, ip_address_country: string, status_code: string, status_message: string, customer_message: string, customer_message_locale: string, payment_gateway: record, gateway_message: string, gateway_reference: string, gateway_approval_code: string, gateway_response_code: string, gateway_response_time: float, gateway_response_values: record, cvv_check: string, avs_check: string, created_at: string, updated_at: string, voided_at: string, collected_at: string, action_result: record, vat_number: string, fraud_info: record, next_action: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/purchases/($transaction_id)/cancel/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the dates that have an available export to download.
#
# GET /export_dates
# operationId: get_export_dates
export def "export-dates dates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, dates: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export_dates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of the export files that are available to download.
#
# GET /export_dates/{export_date}/export_files
# operationId: get_export_files
export def "export-dates-export-files files" [
  export_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, files: table<name: string, md5sum: string, href: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/export_dates/($export_date)/export_files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the dunning campaigns for a site
#
# GET /dunning_campaigns
# operationId: list_dunning_campaigns
export def "dunning-campaigns campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, code: string, name: string, description: string, default_campaign: bool, dunning_cycles: list, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dunning_campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a dunning campaign
#
# GET /dunning_campaigns/{dunning_campaign_id}
# operationId: get_dunning_campaign
export def "dunning-campaigns campaign" [
  dunning_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, name: string, description: string, default_campaign: bool, dunning_cycles: table<type: string, applies_to_manual_trial: bool, first_communication_interval: int, send_immediately_on_hard_decline: bool, intervals: list, expire_subscription: bool, fail_invoice: bool, total_dunning_days: int, total_recycling_days: int, version: int, created_at: string, updated_at: string>, created_at: string, updated_at: string, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dunning_campaigns/($dunning_campaign_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a dunning campaign to multiple plans
#
# PUT /dunning_campaigns/{dunning_campaign_id}/bulk_update
# operationId: put_dunning_campaign_bulk_update
export def "dunning-campaigns-bulk-update update" [
  dunning_campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plan-codes: list # List of `plan_codes` associated with the Plans for which the dunning campaign should be updated. Required unless `plan_ids` is present.
  --plan-ids: list # List of `plan_ids` associated with the Plans for which the dunning campaign should be updated. Required unless `plan_codes` is present.
]: any -> record<object: string, plans: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dunning_campaigns/($dunning_campaign_id)/bulk_update")
  let body = {plan_codes: $plan_codes, plan_ids: $plan_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show the invoice templates for a site
#
# GET /invoice_templates
# operationId: list_invoice_templates
export def "invoice-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, code: string, name: string, description: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invoice_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an invoice template
#
# GET /invoice_templates/{invoice_template_id}
# operationId: get_invoice_template
export def "invoice-templates template" [
  invoice_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, code: string, name: string, description: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoice_templates/($invoice_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the external invoices on a site
#
# GET /external_invoices
# operationId: list_external_invoices
export def "external-invoices invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, account: record, external_subscription: record, external_id: string, state: string, total: string, currency: string, line_items: list, purchased_at: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/external_invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an external invoice
#
# GET /external_invoices/{external_invoice_id}
# operationId: show_external_invoice
export def "external-invoices invoice" [
  external_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, external_subscription: record<id: string, object: string, account: record<id: string, object: string, code: string, email: string, first_name: string, last_name: string, company: string, parent_account_id: string, bill_to: string, dunning_campaign_id: string>, external_product_reference: record<id: string, object: string, reference_code: string, external_connection_type: string, created_at: string, updated_at: string>, external_payment_phases: list<record>, external_id: string, uuid: string, last_purchased: string, auto_renew: bool, in_grace_period: bool, app_identifier: string, quantity: int, state: string, activated_at: string, canceled_at: string, expires_at: string, trial_started_at: string, trial_ends_at: string, test: bool, imported: bool, created_at: string, updated_at: string>, external_id: string, state: string, total: string, currency: string, line_items: table<id: string, object: string, account: record, currency: string, unit_amount: string, quantity: int, description: string, external_product_reference: record, created_at: string, updated_at: string>, purchased_at: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_invoices/($external_invoice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the external payment phases on an external subscription
#
# GET /external_subscriptions/{external_subscription_id}/external_payment_phases
# operationId: list_external_subscription_external_payment_phases
export def "external-subscriptions-external-payment-phases phases" [
  external_subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, started_at: string, ends_at: string, starting_billing_period_index: int, ending_billing_period_index: int, offer_type: string, offer_name: string, period_count: int, period_length: string, amount: string, currency: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/external_subscriptions/($external_subscription_id)/external_payment_phases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an external payment phase
#
# GET /external_subscriptions/{external_subscription_id}/external_payment_phases/{external_payment_phase_id}
# operationId: get_external_subscription_external_payment_phase
export def "external-subscriptions-external-payment-phases phase" [
  external_subscription_id: string
  external_payment_phase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, started_at: string, ends_at: string, starting_billing_period_index: int, ending_billing_period_index: int, offer_type: string, offer_name: string, period_count: int, period_length: string, amount: string, currency: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_subscriptions/($external_subscription_id)/external_payment_phases/($external_payment_phase_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List entitlements granted to an account
#
# GET /accounts/{account_id}/entitlements
# operationId: list_entitlements
export def "accounts-entitlements entitlements" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer-5 # Filter the entitlements based on the state of the applicable subscription.  - When `state=active`, `state=canceled`, `state=expired`, or `state=future`, subscriptions with states that match the query and only those subscriptions will be returned. - When no state is provided, subscriptions with active or canceled states will be returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<object: string, customer_permission: record, granted_by: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/entitlements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an account's external subscriptions
#
# GET /accounts/{account_id}/external_subscriptions
# operationId: list_account_external_subscriptions
export def "accounts-external-subscriptions subscriptions" [
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, account: record, external_product_reference: record, external_payment_phases: list, external_id: string, uuid: string, last_purchased: string, auto_renew: bool, in_grace_period: bool, app_identifier: string, quantity: int, state: string, activated_at: string, canceled_at: string, expires_at: string, trial_started_at: string, trial_ends_at: string, test: bool, imported: bool, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($account_id)/external_subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a business entity
#
# GET /business_entities/{business_entity_id}
# operationId: get_business_entity
export def "business-entities entity" [
  business_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, code: string, name: string, invoice_display_address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, tax_address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, origin_tax_address_source: string, destination_tax_address_source: string, default_vat_number: string, default_registration_number: string, subscriber_location_countries: list<string>, default_liability_gl_account_id: string, default_revenue_gl_account_id: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_entities/($business_entity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List business entities
#
# GET /business_entities
# operationId: list_business_entities
export def "business-entities entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, code: string, name: string, invoice_display_address: record, tax_address: record, origin_tax_address_source: string, destination_tax_address_source: string, default_vat_number: string, default_registration_number: string, subscriber_location_countries: list, default_liability_gl_account_id: string, default_revenue_gl_account_id: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business_entities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List gift cards
#
# GET /gift_cards
# operationId: list_gift_cards
export def "gift-cards cards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, object: string, gifter_account_id: string, recipient_account_id: string, purchase_invoice_id: string, redemption_invoice_id: string, redemption_code: string, balance: float, product_code: string, unit_amount: float, currency: string, delivery: record, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, created_at: string, updated_at: string, delivered_at: string, redeemed_at: string, canceled_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gift_cards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create gift card
#
# POST /gift_cards
# operationId: create_gift_card
# --delivery shape: {method: "email"|"post", email_address?: string, first_name?: string, last_name?: string, recipient_address?: record, gifter_name?: string, personal_message?: string}
export def "gift-cards card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  product_code: string # The product code or SKU of the gift card product.
  unit_amount: float # The amount of the gift card, which is the amount of the charge to the gifter account and the amount of credit that is applied to the recipient account upon successful redemption. (format: float)
  currency: string # 3-letter ISO 4217 currency code.
  --tax-service-opt-out: oneof<nothing, bool> # Set to `true` to bypass sending the purchase to your configured tax service. Defaults to `false`.
  delivery: record # Gift card delivery details — shape: {method: "email"|"post", email_address?: string, first_name?: string, last_name?: string, recipient_address?: record, gifter_name?: string, personal_message?: string}
  gifter_account: any
]: any -> record<id: string, object: string, gifter_account_id: string, recipient_account_id: string, purchase_invoice_id: string, redemption_invoice_id: string, redemption_code: string, balance: float, product_code: string, unit_amount: float, currency: string, delivery: record<method: string, email_address: string, deliver_at: string, first_name: string, last_name: string, recipient_address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, gifter_name: string, personal_message: string>, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, created_at: string, updated_at: string, delivered_at: string, redeemed_at: string, canceled_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gift_cards")
  let body = {product_code: $product_code, unit_amount: $unit_amount, currency: $currency, tax_service_opt_out: $tax_service_opt_out, delivery: $delivery, gifter_account: $gifter_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a gift card
#
# GET /gift_cards/{gift_card_id}
# operationId: get_gift_card
export def "gift-cards card-by-gift_card_id" [
  gift_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, gifter_account_id: string, recipient_account_id: string, purchase_invoice_id: string, redemption_invoice_id: string, redemption_code: string, balance: float, product_code: string, unit_amount: float, currency: string, delivery: record<method: string, email_address: string, deliver_at: string, first_name: string, last_name: string, recipient_address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, gifter_name: string, personal_message: string>, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, created_at: string, updated_at: string, delivered_at: string, redeemed_at: string, canceled_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gift_cards/($gift_card_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview gift card
#
# POST /gift_cards/preview
# operationId: preview_gift_card
# --delivery shape: {method: "email"|"post", email_address?: string, first_name?: string, last_name?: string, recipient_address?: record, gifter_name?: string, personal_message?: string}
export def "gift-cards-preview card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  product_code: string # The product code or SKU of the gift card product.
  unit_amount: float # The amount of the gift card, which is the amount of the charge to the gifter account and the amount of credit that is applied to the recipient account upon successful redemption. (format: float)
  currency: string # 3-letter ISO 4217 currency code.
  --tax-service-opt-out: oneof<nothing, bool> # Set to `true` to bypass sending the purchase to your configured tax service. Defaults to `false`.
  delivery: record # Gift card delivery details — shape: {method: "email"|"post", email_address?: string, first_name?: string, last_name?: string, recipient_address?: record, gifter_name?: string, personal_message?: string}
  gifter_account: any
]: any -> record<id: string, object: string, gifter_account_id: string, recipient_account_id: string, purchase_invoice_id: string, redemption_invoice_id: string, redemption_code: string, balance: float, product_code: string, unit_amount: float, currency: string, delivery: record<method: string, email_address: string, deliver_at: string, first_name: string, last_name: string, recipient_address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, gifter_name: string, personal_message: string>, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, created_at: string, updated_at: string, delivered_at: string, redeemed_at: string, canceled_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gift_cards/preview")
  let body = {product_code: $product_code, unit_amount: $unit_amount, currency: $currency, tax_service_opt_out: $tax_service_opt_out, delivery: $delivery, gifter_account: $gifter_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Redeem gift card
#
# POST /gift_cards/{redemption_code}/redeem
# operationId: redeem_gift_card
# --recipient_account shape: {id?: string, code?: string}
export def "gift-cards-redeem card" [
  redemption_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  recipient_account: record # shape: {id?: string, code?: string}
]: any -> record<id: string, object: string, gifter_account_id: string, recipient_account_id: string, purchase_invoice_id: string, redemption_invoice_id: string, redemption_code: string, balance: float, product_code: string, unit_amount: float, currency: string, delivery: record<method: string, email_address: string, deliver_at: string, first_name: string, last_name: string, recipient_address: record<phone: string, street1: string, street2: string, city: string, region: string, postal_code: string, country: string, geo_code: string>, gifter_name: string, personal_message: string>, performance_obligation_id: string, liability_gl_account_id: string, revenue_gl_account_id: string, created_at: string, updated_at: string, delivered_at: string, redeemed_at: string, canceled_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gift_cards/($redemption_code)/redeem")
  let body = {recipient_account: $recipient_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a business entity's invoices
#
# GET /business_entities/{business_entity_id}/invoices
# operationId: list_business_entity_invoices
export def "business-entities-invoices invoices" [
  business_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Filter results by their IDs. Up to 200 IDs can be passed at once using commas as separators, e.g. `ids=h1at4d57xlmy,gyqgg0d3v9n1,jrsm5b4yefg6`.  **Important notes:**  * The `ids` parameter cannot be used with any other ordering or filtering   parameters (`limit`, `order`, `sort`, `begin_time`, `end_time`, etc) * Invalid or unknown IDs will be ignored, so you should check that the   results correspond to your request. * Records are returned in an arbitrary order. Since results are all   returned at once you can sort the records yourself.
  --state: string@state-completer-1 # Invoice state. (default: all)
  --limit: int # Limit number of records 1-200. (default: 20)
  --order: string@order-completer # Sort order.
  --qp-sort: string@sort-completer # Sort field. You *really* only want to sort by `updated_at` in ascending order. In descending order updated records will move behind the cursor and could prevent some records from being returned.
  --begin-time: string # Inclusively filter by begin_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --end-time: string # Inclusively filter by end_time when `sort=created_at` or `sort=updated_at`. **Note:** this value is an ISO8601 timestamp. A partial timestamp that does not include a time zone will default to UTC.  (format: date-time)
  --type: string@type-completer-1 # Filter by type when: - `type=charge`, only charge invoices will be returned. - `type=credit`, only credit invoices will be returned. - `type=non-legacy`, only charge and credit invoices will be returned. - `type=legacy`, only legacy invoices will be returned.
]: nothing -> record<object: string, has_more: bool, next: string, data: table<id: string, uuid: string, object: string, type: string, origin: string, state: string, account: record, billing_info_id: string, subscription_ids: list, previous_invoice_id: string, number: string, collection_method: string, po_number: string, net_terms: int, net_terms_type: string, address: record, shipping_address: record, currency: string, discount: float, coupon_redemptions: list, subtotal: float, subtotal_after_discount: float, tax: float, reference_only_currency_conversion: record, total: float, refundable_amount: float, paid: float, balance: float, tax_info: record, used_tax_service: bool, vat_number: string, vat_reverse_charge_notes: string, terms_and_conditions: string, customer_notes: string, line_items: list, has_more_line_items: bool, transactions: list, credit_payments: list, created_at: string, updated_at: string, due_at: string, closed_at: string, dunning_campaign_id: string, dunning_events_sent: int, final_dunning_event: bool, business_entity_id: string, custom_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "begin_time" $begin_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/business_entities/($business_entity_id)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
