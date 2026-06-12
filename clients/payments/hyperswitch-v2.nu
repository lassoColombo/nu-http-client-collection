# Auto-generated client for Hyperswitch - API Documentation v0.1.0
# Source: https://raw.githubusercontent.com/juspay/hyperswitch/main/api-reference/v2/openapi_spec_v2.json
# Auth: --token flag or $env.HYPERSWITCH_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://sandbox.hyperswitch.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HYPERSWITCH_API_DOCUMENTATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox.hyperswitch.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def connector-type-completer [] { ["authentication_processor" "banking_entities" "billing_processor" "fin_operations" "fiz_operations" "networks" "non_banking_finance" "payment_method_auth" "payment_processor" "payment_vas" "payout_processor" "surcharge_processor" "tax_processor" "vault_processor"] }
def connector-name-completer [] { ["absa_sanlam" "aci" "adyen" "adyen_test" "adyenplatform" "affirm" "airwallex" "amazonpay" "archipel" "authipay" "authorizedotnet" "bambora" "bamboraapac" "bankofamerica" "barclaycard" "billwerk" "bitpay" "blackhawknetwork" "bluesnap" "boku" "braintree" "breadpay" "calida" "cardinal" "cashtocode" "celero" "chargebee" "checkbook" "checkout" "checkout_test" "coinbase" "coingate" "cryptopay" "ctp_mastercard" "ctp_visa" "custombilling" "cybersource" "cybersourcedecisionmanager" "datatrans" "deutschebank" "digitalvirgo" "dlocal" "dwolla" "ebanx" "elavon" "envoy" "facilitapay" "fauxpay" "finix" "fiserv" "fiservcommercehub" "fiservemea" "fiuu" "flexiti" "forte" "getnet" "gigadat" "globalpay" "globepay" "gocardless" "gpayments" "helcim" "hipay" "hyperpg" "hyperswitch_vault" "iatapay" "imerchantsolutions" "inespay" "interpayments" "itaubank" "jpmorgan" "juspaythreedsserver" "klarna" "loonio" "mifinity" "mollie" "moneris" "multisafepay" "netcetera" "nexinets" "nexixpay" "nmi" "nomupay" "noon" "nordea" "novalnet" "nuvei" "opennode" "paybox" "payconex" "payjustnow" "payjustnowinstore" "payload" "payme" "payone" "paypal" "paypal_test" "paysafe" "paystack" "paytm" "payu" "peachpayments" "phonepe" "phonypay" "placetopay" "plaid" "powertranz" "pretendpay" "prophetpay" "rapyd" "razorpay" "recurly" "redsys" "revolv3" "riskified" "santander" "shift4" "signifyd" "silverflow" "square" "stax" "stripe" "stripe_billing_test" "stripe_test" "stripebilling" "taxjar" "tesouro" "threedsecureio" "tokenex" "tokenio" "truelayer" "trustly" "trustpay" "trustpayments" "tsys" "vgs" "volt" "wellsfargo" "wise" "worldline" "worldpay" "worldpaymodular" "worldpayvantiv" "worldpayxml" "xendit" "zen" "zift" "zsl"] }
def status-completer [] { ["active" "inactive"] }
def payment-method-type-completer [] { ["bank_debit" "bank_redirect" "bank_transfer" "card" "card_redirect" "crypto" "gift_card" "mobile_payment" "network_token" "open_banking" "pay_later" "real_time_payment" "reward" "upi" "voucher" "wallet"] }
def force-sync-completer [] { ["false" "true"] }
def storage-type-completer [] { ["persistent" "volatile"] }
def payment-method-subtype-completer [] { ["ach" "affirm" "afterpay_clearpay" "alfamart" "ali_pay" "ali_pay_hk" "alma" "amazon_pay" "apple_pay" "atome" "bacs" "bancontact_card" "bca_bank_transfer" "becs" "benefit" "bhn_card_network" "bizum" "blik" "bluecode" "bni_va" "boleto" "breadpay" "bri_va" "card_redirect" "cashapp" "cimb_va" "classic" "credit" "crypto_currency" "dana" "danamon_va" "debit" "direct_carrier_billing" "duit_now" "efecty" "eft" "eft_debit_order" "eps" "evoucher" "family_mart" "flexiti" "fps" "gcash" "giropay" "givex" "go_pay" "google_pay" "ideal" "indomaret" "indonesian_bank_transfer" "instant_bank_transfer" "instant_bank_transfer_finland" "instant_bank_transfer_poland" "interac" "kakao_pay" "klarna" "knet" "lawson" "local_bank_redirect" "local_bank_transfer" "mandiri_va" "mb_way" "mifinity" "mini_stop" "mobile_pay" "momo" "momo_atm" "multibanco" "network_token" "online_banking_czech_republic" "online_banking_finland" "online_banking_fpx" "online_banking_poland" "online_banking_slovakia" "online_banking_thailand" "open_banking" "open_banking_pis" "open_banking_uk" "oxxo" "pago_efectivo" "pay_bright" "pay_easy" "pay_safe_card" "payjustnow" "paypal" "paysera" "paze" "permata_bank_transfer" "pix" "pix_automatico_push" "pix_automatico_qr" "pix_emv" "pix_key" "prompt_pay" "przelewy24" "pse" "qris" "red_compra" "red_pagos" "revolut_pay" "samsung_pay" "seicomart" "sepa" "sepa_bank_transfer" "sepa_guarenteed_debit" "seven_eleven" "skrill" "sofort" "swish" "touch_n_go" "trustly" "twint" "upi_collect" "upi_intent" "upi_qr" "venmo" "viet_qr" "vipps" "walley" "we_chat_pay"] }
def method-completer [] { ["DELETE" "GET" "PATCH" "POST" "PUT"] }
def token-type-completer [] { ["payment_method_id" "payment_method_token" "tokenization_id" "volatile_payment_method_id"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "organizations Create-an-Organization" } } | get name | first)
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

# Organization - Create
#
# POST /v2/organizations
# operationId: Create an Organization
export def "organizations Create-an-Organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_name: string # Name of the organization
  --organization-details: record # Details about the organization (nullable)
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
]: any -> record<id: string, organization_name: string, organization_details: record, metadata: record, modified_at: string, created_at: string, organization_type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/organizations")
  let body = {organization_name: $organization_name, organization_details: $organization_details, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Organization - Retrieve
#
# GET /v2/organizations/{id}
# operationId: Retrieve an Organization
export def "organizations Retrieve-an-Organization" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, organization_name: string, organization_details: record, metadata: record, modified_at: string, created_at: string, organization_type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization - Update
#
# PUT /v2/organizations/{id}
# operationId: Update an Organization
export def "organizations Update-an-Organization" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-name: string # Name of the organization (nullable)
  --organization-details: record # Details about the organization (nullable)
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  platform_merchant_id: string # Platform merchant id is unique distiguisher for special merchant in the platform org
]: any -> record<id: string, organization_name: string, organization_details: record, metadata: record, modified_at: string, created_at: string, organization_type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($id)")
  let body = {organization_name: $organization_name, organization_details: $organization_details, metadata: $metadata, platform_merchant_id: $platform_merchant_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Organization - Merchant Account - List
#
# GET /v2/organizations/{id}/merchant-accounts
# operationId: List Merchant Accounts
export def "organizations-merchant-accounts List-Merchant-Accounts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, merchant_name: string, merchant_details: record<primary_contact_person: string, primary_phone: string, primary_email: string, secondary_contact_person: string, secondary_phone: string, secondary_email: string, website: string, about_business: string, address: record, merchant_tax_registration_id: string>, publishable_key: string, metadata: record, organization_id: string, recon_status: string, product_type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($id)/merchant-accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Connector Account - Create
#
# POST /v2/connector-accounts
# operationId: Create a Merchant Connector
# --payment_methods_enabled shape: {payment_method_type: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_subtypes?: list}
# --frm_configs item shape: {gateway: "payment_processor"|"payment_vas"|"fin_operations"|"fiz_operations"|"networks"|"banking_entities"|"non_banking_finance"|"payout_processor"|"payment_method_auth"|"authentication_processor"|"tax_processor"|"surcharge_processor"|"billing_processor"|"vault_processor", payment_methods: list}
export def "connector-accounts Create-a-Merchant-Connector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector_type: string@connector-type-completer # Type of the Connector for the financial use case. Could range from Payments to Accounting to Banking.
  connector_name: string@connector-name-completer
  --connector-label: string # This is an unique label you can generate and pass in order to identify this connector account on your Hyperswitch dashboard and reports, If not passed then if will take `connector_name`_`profile_name`. Eg: if your profile label is `default`, connector label can be `stripe_default` (nullable, e.g. stripe_US_travel)
  profile_id: string # Identifier for the profile, if not provided default will be chosen from merchant account
  --connector-account-details: any # nullable
  payment_methods_enabled: record # Details of all the payment methods enabled for the connector for the given merchant account — shape: {payment_method_type: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_subtypes?: list}
  --connector-webhook-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --disabled: oneof<nothing, bool> # A boolean value to indicate if the connector is disabled. By default, its value is false. (nullable, default: false, e.g. false)
  --frm-configs: list # Contains the frm configs for the merchant connector (nullable, e.g.  [{"gateway":"stripe","payment_methods":[{"payment_method":"card","payment_method_types":[{"payment_method_type":"credit","card_networks":["Visa"],"flow":"pre","action":"cancel_txn"},{"payment_method_type":"debit","card_networks":["Visa"],"flow":"pre"}]}]}] ) — item shape: {gateway: "payment_processor"|"payment_vas"|"fin_operations"|"fiz_operations"|"networks"|"banking_entities"|"non_banking_finance"|"payout_processor"|"payment_method_auth"|"authentication_processor"|"tax_processor"|"surcharge_processor"|"billing_processor"|"vault_processor", payment_methods: list}
  --pm-auth-config: record # pm_auth_config will relate MCA records to their respective chosen auth services, based on payment_method and pmt (nullable)
  --status: any # nullable
  --additional-merchant-data: any # nullable
  --connector-wallets-details: any # nullable
  --feature-metadata: any # nullable
]: any -> record<connector_type: string, connector_name: string, connector_label: string, id: string, profile_id: string, connector_account_details: record<connector_account_details: record, metadata: record>, payment_methods_enabled: table<payment_method_type: string, payment_method_subtypes: list>, connector_webhook_details: record<merchant_secret: string, additional_secret: string>, metadata: record, disabled: bool, frm_configs: table<gateway: string, payment_methods: list>, applepay_verified_domains: list<string>, pm_auth_config: record, status: string, additional_merchant_data: record, connector_wallets_details: record<apple_pay_combined: record, apple_pay: record, amazon_pay: record, samsung_pay: record, paze: record, google_pay: record>, feature_metadata: record<revenue_recovery: record<max_retry_count: int, billing_connector_retry_threshold: int, billing_account_reference: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/connector-accounts")
  let body = {connector_type: $connector_type, connector_name: $connector_name, connector_label: $connector_label, profile_id: $profile_id, connector_account_details: $connector_account_details, payment_methods_enabled: $payment_methods_enabled, connector_webhook_details: $connector_webhook_details, metadata: $metadata, disabled: $disabled, frm_configs: $frm_configs, pm_auth_config: $pm_auth_config, status: $status, additional_merchant_data: $additional_merchant_data, connector_wallets_details: $connector_wallets_details, feature_metadata: $feature_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Connector Account - Retrieve
#
# GET /v2/connector-accounts/{id}
# operationId: Retrieve a Merchant Connector
export def "connector-accounts Retrieve-a-Merchant-Connector" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connector_type: string, connector_name: string, connector_label: string, id: string, profile_id: string, connector_account_details: record<connector_account_details: record, metadata: record>, payment_methods_enabled: table<payment_method_type: string, payment_method_subtypes: list>, connector_webhook_details: record<merchant_secret: string, additional_secret: string>, metadata: record, disabled: bool, frm_configs: table<gateway: string, payment_methods: list>, applepay_verified_domains: list<string>, pm_auth_config: record, status: string, additional_merchant_data: record, connector_wallets_details: record<apple_pay_combined: record, apple_pay: record, amazon_pay: record, samsung_pay: record, paze: record, google_pay: record>, feature_metadata: record<revenue_recovery: record<max_retry_count: int, billing_connector_retry_threshold: int, billing_account_reference: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/connector-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Connector Account - Update
#
# PUT /v2/connector-accounts/{id}
# operationId: Update a Merchant Connector
# --payment_methods_enabled item shape: {payment_method_type: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_subtypes?: list}
# --frm_configs item shape: {gateway: "payment_processor"|"payment_vas"|"fin_operations"|"fiz_operations"|"networks"|"banking_entities"|"non_banking_finance"|"payout_processor"|"payment_method_auth"|"authentication_processor"|"tax_processor"|"surcharge_processor"|"billing_processor"|"vault_processor", payment_methods: list}
export def "connector-accounts Update-a-Merchant-Connector" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector_type: string@connector-type-completer # Type of the Connector for the financial use case. Could range from Payments to Accounting to Banking.
  --connector-label: string # This is an unique label you can generate and pass in order to identify this connector account on your Hyperswitch dashboard and reports, If not passed then if will take `connector_name`_`profile_name`. Eg: if your profile label is `default`, connector label can be `stripe_default` (nullable, e.g. stripe_US_travel)
  --connector-account-details: any # nullable
  --payment-methods-enabled: list # An object containing the details about the payment methods that need to be enabled under this merchant connector account (nullable) — item shape: {payment_method_type: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_subtypes?: list}
  --connector-webhook-details: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --disabled: oneof<nothing, bool> # A boolean value to indicate if the connector is disabled. By default, its value is false. (nullable, default: false, e.g. false)
  --frm-configs: list # Contains the frm configs for the merchant connector (nullable, e.g.  [{"gateway":"stripe","payment_methods":[{"payment_method":"card","payment_method_types":[{"payment_method_type":"credit","card_networks":["Visa"],"flow":"pre","action":"cancel_txn"},{"payment_method_type":"debit","card_networks":["Visa"],"flow":"pre"}]}]}] ) — item shape: {gateway: "payment_processor"|"payment_vas"|"fin_operations"|"fiz_operations"|"networks"|"banking_entities"|"non_banking_finance"|"payout_processor"|"payment_method_auth"|"authentication_processor"|"tax_processor"|"surcharge_processor"|"billing_processor"|"vault_processor", payment_methods: list}
  --pm-auth-config: record # pm_auth_config will relate MCA records to their respective chosen auth services, based on payment_method and pmt (nullable)
  status: string@status-completer
  merchant_id: string # The identifier for the Merchant Account (e.g. y3oqhf46pyzuxjbcn2giaqnb44)
  --additional-merchant-data: any # nullable
  --connector-wallets-details: any # nullable
  --feature-metadata: any # nullable
]: any -> record<connector_type: string, connector_name: string, connector_label: string, id: string, profile_id: string, connector_account_details: record<connector_account_details: record, metadata: record>, payment_methods_enabled: table<payment_method_type: string, payment_method_subtypes: list>, connector_webhook_details: record<merchant_secret: string, additional_secret: string>, metadata: record, disabled: bool, frm_configs: table<gateway: string, payment_methods: list>, applepay_verified_domains: list<string>, pm_auth_config: record, status: string, additional_merchant_data: record, connector_wallets_details: record<apple_pay_combined: record, apple_pay: record, amazon_pay: record, samsung_pay: record, paze: record, google_pay: record>, feature_metadata: record<revenue_recovery: record<max_retry_count: int, billing_connector_retry_threshold: int, billing_account_reference: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/connector-accounts/($id)")
  let body = {connector_type: $connector_type, connector_label: $connector_label, connector_account_details: $connector_account_details, payment_methods_enabled: $payment_methods_enabled, connector_webhook_details: $connector_webhook_details, metadata: $metadata, disabled: $disabled, frm_configs: $frm_configs, pm_auth_config: $pm_auth_config, status: $status, merchant_id: $merchant_id, additional_merchant_data: $additional_merchant_data, connector_wallets_details: $connector_wallets_details, feature_metadata: $feature_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Connector - Delete
#
# DELETE /v2/connector-accounts/{id}
# operationId: Delete a Merchant Connector
export def "connector-accounts Delete-a-Merchant-Connector" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<merchant_id: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/connector-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merchant Account - Create
#
# POST /v2/merchant-accounts
# operationId: Create a Merchant Account
export def "merchant-accounts Create-a-Merchant-Account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Organization-Id: string # Organization ID for which the merchant account has to be created. (e.g. {X-Organization-Id: org_abcdefghijklmnop})
  merchant_name: string # Name of the Merchant Account, This will be used as a prefix to generate the id (e.g. NewAge Retailer)
  --merchant-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information about the merchant account. (nullable)
  --product-type: any # nullable
]: any -> record<id: string, merchant_name: string, merchant_details: record<primary_contact_person: string, primary_phone: string, primary_email: string, secondary_contact_person: string, secondary_phone: string, secondary_email: string, website: string, about_business: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, merchant_tax_registration_id: string>, publishable_key: string, metadata: record, organization_id: string, recon_status: string, product_type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/merchant-accounts")
  let body = {merchant_name: $merchant_name, merchant_details: $merchant_details, metadata: $metadata, product_type: $product_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Organization-Id": $X_Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Account - Retrieve
#
# GET /v2/merchant-accounts/{id}
# operationId: Retrieve a Merchant Account
export def "merchant-accounts Retrieve-a-Merchant-Account" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, merchant_name: string, merchant_details: record<primary_contact_person: string, primary_phone: string, primary_email: string, secondary_contact_person: string, secondary_phone: string, secondary_email: string, website: string, about_business: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, merchant_tax_registration_id: string>, publishable_key: string, metadata: record, organization_id: string, recon_status: string, product_type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/merchant-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merchant Account - Update
#
# PUT /v2/merchant-accounts/{id}
# operationId: Update a Merchant Account
export def "merchant-accounts Update-a-Merchant-Account" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merchant-name: string # Name of the Merchant Account (nullable, e.g. NewAge Retailer)
  --merchant-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
]: any -> record<id: string, merchant_name: string, merchant_details: record<primary_contact_person: string, primary_phone: string, primary_email: string, secondary_contact_person: string, secondary_phone: string, secondary_email: string, website: string, about_business: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, merchant_tax_registration_id: string>, publishable_key: string, metadata: record, organization_id: string, recon_status: string, product_type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/merchant-accounts/($id)")
  let body = {merchant_name: $merchant_name, merchant_details: $merchant_details, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Account - Profile List
#
# GET /v2/merchant-accounts/{id}/profiles
# operationId: List Profiles
export def "merchant-accounts-profiles List-Profiles" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<merchant_id: string, id: string, profile_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list, refund_statuses_enabled: list, payout_statuses_enabled: list>, metadata: record, applepay_verified_domains: list<string>, session_expiry: int, payment_link_config: record, authentication_connector_details: record<authentication_connectors: list, three_ds_requestor_url: string, three_ds_requestor_app_url: string>, use_billing_as_payment_method_billing: bool, extended_card_info_config: record<public_key: string, ttl_in_secs: int>, collect_shipping_details_from_wallet_connector_if_required: bool, collect_billing_details_from_wallet_connector_if_required: bool, always_collect_shipping_details_from_wallet_connector: bool, always_collect_billing_details_from_wallet_connector: bool, is_connector_agnostic_mit_enabled: bool, payout_link_config: record, outgoing_webhook_custom_http_headers: record, order_fulfillment_time: int, order_fulfillment_time_origin: record, tax_connector_id: string, is_tax_connector_enabled: bool, is_network_tokenization_enabled: bool, should_collect_cvv_during_payment: bool, is_click_to_pay_enabled: bool, authentication_product_ids: record, card_testing_guard_config: record<card_ip_blocking_status: string, card_ip_blocking_threshold: int, guest_user_card_blocking_status: string, guest_user_card_blocking_threshold: int, customer_id_blocking_status: string, customer_id_blocking_threshold: int, card_testing_guard_expiry: int>, is_clear_pan_retries_enabled: bool, is_debit_routing_enabled: bool, merchant_business_country: record, is_iframe_redirection_enabled: bool, is_external_vault_enabled: bool, external_vault_connector_details: record<vault_connector_id: string, vault_sdk: record, vault_token_selector: list>, merchant_category_code: record, merchant_country_code: record, split_txns_enabled: record, revenue_recovery_retry_algorithm_type: record, billing_processor_id: string, surcharge_connector_details: record<surcharge_connector_id: string>, is_l2_l3_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/merchant-accounts/($id)/profiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Profile - Create
#
# POST /v2/profiles
# operationId: Create A Profile
export def "profiles Create-A-Profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Merchant-Id: string # Merchant ID of the profile. (e.g. {X-Merchant-Id: abc_iG5VNjsN9xuCg7Xx0uWh})
  profile_name: string # The name of profile
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://www.example.com/success)
  --enable-payment-response-hash: oneof<nothing, bool> # A boolean value to indicate if payment response hash needs to be enabled (nullable, default: true, e.g. true)
  --payment-response-hash-key: string # Refers to the hash key used for calculating the signature for webhooks and redirect response. If the value is not provided, a value is automatically generated. (nullable)
  --redirect-to-merchant-with-http-post: oneof<nothing, bool> # A boolean value to indicate if redirect to merchant with http post needs to be enabled (nullable, default: false, e.g. true)
  --webhook-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --order-fulfillment-time: int # Will be used to determine the time till which your payment will be active once the payment session starts (nullable, format: int32, e.g. 900)
  --order-fulfillment-time-origin: any # nullable
  --applepay-verified-domains: list # Verified Apple Pay domains for a particular profile (nullable)
  --session-expiry: int # Client Secret Default expiry for all payments created under this profile (nullable, format: int32, e.g. 900)
  --payment-link-config: any # nullable
  --authentication-connector-details: any # nullable
  --use-billing-as-payment-method-billing: oneof<nothing, bool> # Whether to use the billing details passed when creating the intent as payment method billing (nullable)
  --collect-shipping-details-from-wallet-connector-if-required: oneof<nothing, bool> # A boolean value to indicate if customer shipping details needs to be collected from wallet connector only if it is required field for connector (Eg. Apple Pay, Google Pay etc) (nullable, default: false, e.g. false)
  --collect-billing-details-from-wallet-connector-if-required: oneof<nothing, bool> # A boolean value to indicate if customer billing details needs to be collected from wallet connector only if it is required field for connector (Eg. Apple Pay, Google Pay etc) (nullable, default: false, e.g. false)
  --always-collect-shipping-details-from-wallet-connector: oneof<nothing, bool> # A boolean value to indicate if customer shipping details needs to be collected from wallet connector irrespective of connector required fields (Eg. Apple pay, Google pay etc) (nullable, default: false, e.g. false)
  --always-collect-billing-details-from-wallet-connector: oneof<nothing, bool> # A boolean value to indicate if customer billing details needs to be collected from wallet connector irrespective of connector required fields (Eg. Apple pay, Google pay etc) (nullable, default: false, e.g. false)
  --is-connector-agnostic-mit-enabled: oneof<nothing, bool> # Indicates if the MIT (merchant initiated transaction) payments can be made connector agnostic, i.e., MITs may be processed through different connector than CIT (customer initiated transaction) based on the routing rules. If set to `false`, MIT will go through the same connector as the CIT. (nullable)
  --payout-link-config: any # nullable
  --outgoing-webhook-custom-http-headers: record # These key-value pairs are sent as additional custom headers in the outgoing webhook request. It is recommended not to use more than four key-value pairs. (nullable)
  --tax-connector-id: string # Merchant Connector id to be stored for tax_calculator connector (nullable)
  --is-tax-connector-enabled: oneof<nothing, bool> # Indicates if tax_calculator connector is enabled or not. If set to `true` tax_connector_id will be checked.
  --is-network-tokenization-enabled: oneof<nothing, bool> # Indicates if network tokenization is enabled or not.
  --is-click-to-pay-enabled: oneof<nothing, bool> # Indicates if click to pay is enabled or not. (default: false, e.g. false)
  --authentication-product-ids: record # Product authentication ids (nullable)
  --card-testing-guard-config: any # nullable
  --is-clear-pan-retries-enabled: oneof<nothing, bool> # Indicates if clear pan retries is enabled or not. (nullable)
  --is-debit-routing-enabled: oneof<nothing, bool> # Indicates if debit routing is enabled or not (nullable)
  --merchant-business-country: any # nullable
  --is-iframe-redirection-enabled: oneof<nothing, bool> # Indicates if the redirection has to open in the iframe (nullable, e.g. false)
  --is-external-vault-enabled: oneof<nothing, bool> # Indicates if external vault is enabled or not. (nullable)
  --external-vault-connector-details: any # nullable
  --merchant-category-code: any # nullable
  --merchant-country-code: any # nullable
  --split-txns-enabled: any # nullable, default: skip
  --billing-processor-id: string # Merchant Connector id to be stored for billing_processor connector (nullable)
  --surcharge-connector-details: any # nullable
  --is-l2-l3-enabled: oneof<nothing, bool> # Flag to enable Level 2 and Level 3 processing data for card transactions (nullable)
]: any -> record<merchant_id: string, id: string, profile_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, metadata: record, applepay_verified_domains: list<string>, session_expiry: int, payment_link_config: record, authentication_connector_details: record<authentication_connectors: list<string>, three_ds_requestor_url: string, three_ds_requestor_app_url: string>, use_billing_as_payment_method_billing: bool, extended_card_info_config: record<public_key: string, ttl_in_secs: int>, collect_shipping_details_from_wallet_connector_if_required: bool, collect_billing_details_from_wallet_connector_if_required: bool, always_collect_shipping_details_from_wallet_connector: bool, always_collect_billing_details_from_wallet_connector: bool, is_connector_agnostic_mit_enabled: bool, payout_link_config: record, outgoing_webhook_custom_http_headers: record, order_fulfillment_time: int, order_fulfillment_time_origin: record, tax_connector_id: string, is_tax_connector_enabled: bool, is_network_tokenization_enabled: bool, should_collect_cvv_during_payment: bool, is_click_to_pay_enabled: bool, authentication_product_ids: record, card_testing_guard_config: record<card_ip_blocking_status: string, card_ip_blocking_threshold: int, guest_user_card_blocking_status: string, guest_user_card_blocking_threshold: int, customer_id_blocking_status: string, customer_id_blocking_threshold: int, card_testing_guard_expiry: int>, is_clear_pan_retries_enabled: bool, is_debit_routing_enabled: bool, merchant_business_country: record, is_iframe_redirection_enabled: bool, is_external_vault_enabled: bool, external_vault_connector_details: record<vault_connector_id: string, vault_sdk: record, vault_token_selector: list<record>>, merchant_category_code: record, merchant_country_code: record, split_txns_enabled: record, revenue_recovery_retry_algorithm_type: record, billing_processor_id: string, surcharge_connector_details: record<surcharge_connector_id: string>, is_l2_l3_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/profiles")
  let body = {profile_name: $profile_name, return_url: $return_url, enable_payment_response_hash: $enable_payment_response_hash, payment_response_hash_key: $payment_response_hash_key, redirect_to_merchant_with_http_post: $redirect_to_merchant_with_http_post, webhook_details: $webhook_details, metadata: $metadata, order_fulfillment_time: $order_fulfillment_time, order_fulfillment_time_origin: $order_fulfillment_time_origin, applepay_verified_domains: $applepay_verified_domains, session_expiry: $session_expiry, payment_link_config: $payment_link_config, authentication_connector_details: $authentication_connector_details, use_billing_as_payment_method_billing: $use_billing_as_payment_method_billing, collect_shipping_details_from_wallet_connector_if_required: $collect_shipping_details_from_wallet_connector_if_required, collect_billing_details_from_wallet_connector_if_required: $collect_billing_details_from_wallet_connector_if_required, always_collect_shipping_details_from_wallet_connector: $always_collect_shipping_details_from_wallet_connector, always_collect_billing_details_from_wallet_connector: $always_collect_billing_details_from_wallet_connector, is_connector_agnostic_mit_enabled: $is_connector_agnostic_mit_enabled, payout_link_config: $payout_link_config, outgoing_webhook_custom_http_headers: $outgoing_webhook_custom_http_headers, tax_connector_id: $tax_connector_id, is_tax_connector_enabled: $is_tax_connector_enabled, is_network_tokenization_enabled: $is_network_tokenization_enabled, is_click_to_pay_enabled: $is_click_to_pay_enabled, authentication_product_ids: $authentication_product_ids, card_testing_guard_config: $card_testing_guard_config, is_clear_pan_retries_enabled: $is_clear_pan_retries_enabled, is_debit_routing_enabled: $is_debit_routing_enabled, merchant_business_country: $merchant_business_country, is_iframe_redirection_enabled: $is_iframe_redirection_enabled, is_external_vault_enabled: $is_external_vault_enabled, external_vault_connector_details: $external_vault_connector_details, merchant_category_code: $merchant_category_code, merchant_country_code: $merchant_country_code, split_txns_enabled: $split_txns_enabled, billing_processor_id: $billing_processor_id, surcharge_connector_details: $surcharge_connector_details, is_l2_l3_enabled: $is_l2_l3_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Merchant-Id": $X_Merchant_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Profile - Retrieve
#
# GET /v2/profiles/{id}
# operationId: Retrieve a Profile
export def "profiles Retrieve-a-Profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Merchant-Id: string # Merchant ID of the profile. (e.g. {X-Merchant-Id: abc_iG5VNjsN9xuCg7Xx0uWh})
]: nothing -> record<merchant_id: string, id: string, profile_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, metadata: record, applepay_verified_domains: list<string>, session_expiry: int, payment_link_config: record, authentication_connector_details: record<authentication_connectors: list<string>, three_ds_requestor_url: string, three_ds_requestor_app_url: string>, use_billing_as_payment_method_billing: bool, extended_card_info_config: record<public_key: string, ttl_in_secs: int>, collect_shipping_details_from_wallet_connector_if_required: bool, collect_billing_details_from_wallet_connector_if_required: bool, always_collect_shipping_details_from_wallet_connector: bool, always_collect_billing_details_from_wallet_connector: bool, is_connector_agnostic_mit_enabled: bool, payout_link_config: record, outgoing_webhook_custom_http_headers: record, order_fulfillment_time: int, order_fulfillment_time_origin: record, tax_connector_id: string, is_tax_connector_enabled: bool, is_network_tokenization_enabled: bool, should_collect_cvv_during_payment: bool, is_click_to_pay_enabled: bool, authentication_product_ids: record, card_testing_guard_config: record<card_ip_blocking_status: string, card_ip_blocking_threshold: int, guest_user_card_blocking_status: string, guest_user_card_blocking_threshold: int, customer_id_blocking_status: string, customer_id_blocking_threshold: int, card_testing_guard_expiry: int>, is_clear_pan_retries_enabled: bool, is_debit_routing_enabled: bool, merchant_business_country: record, is_iframe_redirection_enabled: bool, is_external_vault_enabled: bool, external_vault_connector_details: record<vault_connector_id: string, vault_sdk: record, vault_token_selector: list<record>>, merchant_category_code: record, merchant_country_code: record, split_txns_enabled: record, revenue_recovery_retry_algorithm_type: record, billing_processor_id: string, surcharge_connector_details: record<surcharge_connector_id: string>, is_l2_l3_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/profiles/($id)")
  let extra_headers = {"X-Merchant-Id": $X_Merchant_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Profile - Update
#
# PUT /v2/profiles/{id}
# operationId: Update a Profile
export def "profiles Update-a-Profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Merchant-Id: string # Merchant ID of the profile. (e.g. {X-Merchant-Id: abc_iG5VNjsN9xuCg7Xx0uWh})
  profile_name: string # The name of profile
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://www.example.com/success)
  --enable-payment-response-hash: oneof<nothing, bool> # A boolean value to indicate if payment response hash needs to be enabled (nullable, default: true, e.g. true)
  --payment-response-hash-key: string # Refers to the hash key used for calculating the signature for webhooks and redirect response. If the value is not provided, a value is automatically generated. (nullable)
  --redirect-to-merchant-with-http-post: oneof<nothing, bool> # A boolean value to indicate if redirect to merchant with http post needs to be enabled (nullable, default: false, e.g. true)
  --webhook-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --order-fulfillment-time: int # Will be used to determine the time till which your payment will be active once the payment session starts (nullable, format: int32, e.g. 900)
  --order-fulfillment-time-origin: any # nullable
  --applepay-verified-domains: list # Verified Apple Pay domains for a particular profile (nullable)
  --session-expiry: int # Client Secret Default expiry for all payments created under this profile (nullable, format: int32, e.g. 900)
  --payment-link-config: any # nullable
  --authentication-connector-details: any # nullable
  --use-billing-as-payment-method-billing: oneof<nothing, bool> # Whether to use the billing details passed when creating the intent as payment method billing (nullable)
  --collect-shipping-details-from-wallet-connector-if-required: oneof<nothing, bool> # A boolean value to indicate if customer shipping details needs to be collected from wallet connector only if it is required field for connector (Eg. Apple Pay, Google Pay etc) (nullable, default: false, e.g. false)
  --collect-billing-details-from-wallet-connector-if-required: oneof<nothing, bool> # A boolean value to indicate if customer billing details needs to be collected from wallet connector only if it is required field for connector (Eg. Apple Pay, Google Pay etc) (nullable, default: false, e.g. false)
  --always-collect-shipping-details-from-wallet-connector: oneof<nothing, bool> # A boolean value to indicate if customer shipping details needs to be collected from wallet connector irrespective of connector required fields (Eg. Apple pay, Google pay etc) (nullable, default: false, e.g. false)
  --always-collect-billing-details-from-wallet-connector: oneof<nothing, bool> # A boolean value to indicate if customer billing details needs to be collected from wallet connector irrespective of connector required fields (Eg. Apple pay, Google pay etc) (nullable, default: false, e.g. false)
  --is-connector-agnostic-mit-enabled: oneof<nothing, bool> # Indicates if the MIT (merchant initiated transaction) payments can be made connector agnostic, i.e., MITs may be processed through different connector than CIT (customer initiated transaction) based on the routing rules. If set to `false`, MIT will go through the same connector as the CIT. (nullable)
  --payout-link-config: any # nullable
  --outgoing-webhook-custom-http-headers: record # These key-value pairs are sent as additional custom headers in the outgoing webhook request. It is recommended not to use more than four key-value pairs. (nullable)
  --tax-connector-id: string # Merchant Connector id to be stored for tax_calculator connector (nullable)
  --is-tax-connector-enabled: oneof<nothing, bool> # Indicates if tax_calculator connector is enabled or not. If set to `true` tax_connector_id will be checked.
  --is-network-tokenization-enabled: oneof<nothing, bool> # Indicates if network tokenization is enabled or not.
  --is-click-to-pay-enabled: oneof<nothing, bool> # Indicates if click to pay is enabled or not. (default: false, e.g. false)
  --authentication-product-ids: record # Product authentication ids (nullable)
  --card-testing-guard-config: any # nullable
  --is-clear-pan-retries-enabled: oneof<nothing, bool> # Indicates if clear pan retries is enabled or not. (nullable)
  --is-debit-routing-enabled: oneof<nothing, bool> # Indicates if debit routing is enabled or not (nullable)
  --merchant-business-country: any # nullable
  --is-iframe-redirection-enabled: oneof<nothing, bool> # Indicates if the redirection has to open in the iframe (nullable, e.g. false)
  --is-external-vault-enabled: oneof<nothing, bool> # Indicates if external vault is enabled or not. (nullable)
  --external-vault-connector-details: any # nullable
  --merchant-category-code: any # nullable
  --merchant-country-code: any # nullable
  --split-txns-enabled: any # nullable, default: skip
  --billing-processor-id: string # Merchant Connector id to be stored for billing_processor connector (nullable)
  --surcharge-connector-details: any # nullable
  --is-l2-l3-enabled: oneof<nothing, bool> # Flag to enable Level 2 and Level 3 processing data for card transactions (nullable)
]: any -> record<merchant_id: string, id: string, profile_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, metadata: record, applepay_verified_domains: list<string>, session_expiry: int, payment_link_config: record, authentication_connector_details: record<authentication_connectors: list<string>, three_ds_requestor_url: string, three_ds_requestor_app_url: string>, use_billing_as_payment_method_billing: bool, extended_card_info_config: record<public_key: string, ttl_in_secs: int>, collect_shipping_details_from_wallet_connector_if_required: bool, collect_billing_details_from_wallet_connector_if_required: bool, always_collect_shipping_details_from_wallet_connector: bool, always_collect_billing_details_from_wallet_connector: bool, is_connector_agnostic_mit_enabled: bool, payout_link_config: record, outgoing_webhook_custom_http_headers: record, order_fulfillment_time: int, order_fulfillment_time_origin: record, tax_connector_id: string, is_tax_connector_enabled: bool, is_network_tokenization_enabled: bool, should_collect_cvv_during_payment: bool, is_click_to_pay_enabled: bool, authentication_product_ids: record, card_testing_guard_config: record<card_ip_blocking_status: string, card_ip_blocking_threshold: int, guest_user_card_blocking_status: string, guest_user_card_blocking_threshold: int, customer_id_blocking_status: string, customer_id_blocking_threshold: int, card_testing_guard_expiry: int>, is_clear_pan_retries_enabled: bool, is_debit_routing_enabled: bool, merchant_business_country: record, is_iframe_redirection_enabled: bool, is_external_vault_enabled: bool, external_vault_connector_details: record<vault_connector_id: string, vault_sdk: record, vault_token_selector: list<record>>, merchant_category_code: record, merchant_country_code: record, split_txns_enabled: record, revenue_recovery_retry_algorithm_type: record, billing_processor_id: string, surcharge_connector_details: record<surcharge_connector_id: string>, is_l2_l3_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/profiles/($id)")
  let body = {profile_name: $profile_name, return_url: $return_url, enable_payment_response_hash: $enable_payment_response_hash, payment_response_hash_key: $payment_response_hash_key, redirect_to_merchant_with_http_post: $redirect_to_merchant_with_http_post, webhook_details: $webhook_details, metadata: $metadata, order_fulfillment_time: $order_fulfillment_time, order_fulfillment_time_origin: $order_fulfillment_time_origin, applepay_verified_domains: $applepay_verified_domains, session_expiry: $session_expiry, payment_link_config: $payment_link_config, authentication_connector_details: $authentication_connector_details, use_billing_as_payment_method_billing: $use_billing_as_payment_method_billing, collect_shipping_details_from_wallet_connector_if_required: $collect_shipping_details_from_wallet_connector_if_required, collect_billing_details_from_wallet_connector_if_required: $collect_billing_details_from_wallet_connector_if_required, always_collect_shipping_details_from_wallet_connector: $always_collect_shipping_details_from_wallet_connector, always_collect_billing_details_from_wallet_connector: $always_collect_billing_details_from_wallet_connector, is_connector_agnostic_mit_enabled: $is_connector_agnostic_mit_enabled, payout_link_config: $payout_link_config, outgoing_webhook_custom_http_headers: $outgoing_webhook_custom_http_headers, tax_connector_id: $tax_connector_id, is_tax_connector_enabled: $is_tax_connector_enabled, is_network_tokenization_enabled: $is_network_tokenization_enabled, is_click_to_pay_enabled: $is_click_to_pay_enabled, authentication_product_ids: $authentication_product_ids, card_testing_guard_config: $card_testing_guard_config, is_clear_pan_retries_enabled: $is_clear_pan_retries_enabled, is_debit_routing_enabled: $is_debit_routing_enabled, merchant_business_country: $merchant_business_country, is_iframe_redirection_enabled: $is_iframe_redirection_enabled, is_external_vault_enabled: $is_external_vault_enabled, external_vault_connector_details: $external_vault_connector_details, merchant_category_code: $merchant_category_code, merchant_country_code: $merchant_country_code, split_txns_enabled: $split_txns_enabled, billing_processor_id: $billing_processor_id, surcharge_connector_details: $surcharge_connector_details, is_l2_l3_enabled: $is_l2_l3_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Merchant-Id": $X_Merchant_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Profile - Connector Accounts List
#
# GET /v2/profiles/{id}/connector-accounts
# operationId: List all Merchant Connectors for Profile
export def "profiles-connector-accounts List-all-Merchant-Connectors-for-Profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Merchant-Id: string # Merchant ID of the profile. (e.g. {X-Merchant-Id: abc_iG5VNjsN9xuCg7Xx0uWh})
]: nothing -> table<connector_type: string, connector_name: string, connector_label: string, id: string, profile_id: string, connector_account_details: record<connector_account_details: record, metadata: record>, payment_methods_enabled: list<record>, connector_webhook_details: record<merchant_secret: string, additional_secret: string>, metadata: record, disabled: bool, frm_configs: list<record>, applepay_verified_domains: list<string>, pm_auth_config: record, status: string, additional_merchant_data: record, connector_wallets_details: record<apple_pay_combined: record, apple_pay: record, amazon_pay: record, samsung_pay: record, paze: record, google_pay: record>, feature_metadata: record<revenue_recovery: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/profiles/($id)/connector-accounts")
  let extra_headers = {"X-Merchant-Id": $X_Merchant_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Profile - Activate routing algorithm
#
# PATCH /v2/profiles/{id}/activate-routing-algorithm
# operationId: Activates a routing algorithm under a profile
export def "profiles-activate-routing-algorithm Activates-a-routing-algorithm-under-a-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  routing_algorithm_id: string
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/profiles/($id)/activate-routing-algorithm")
  let body = {routing_algorithm_id: $routing_algorithm_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Profile - Deactivate routing algorithm
#
# PATCH /v2/profiles/{id}/deactivate-routing-algorithm
# operationId:  Deactivates a routing algorithm under a profile
export def "profiles-deactivate-routing-algorithm Deactivates-a-routing-algorithm-under-a-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/profiles/($id)/deactivate-routing-algorithm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Profile - Update Default Fallback Routing Algorithm
#
# PATCH /v2/profiles/{id}/fallback-routing
# operationId: Update the default fallback routing algorithm for the profile
export def "profiles-fallback-routing Update-the-default-fallback-routing-algorithm-for-the-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<connector: string, merchant_connector_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/profiles/($id)/fallback-routing")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Profile - Retrieve Default Fallback Routing Algorithm
#
# GET /v2/profiles/{id}/fallback-routing
# operationId: Retrieve the default fallback routing algorithm for the profile
export def "profiles-fallback-routing Retrieve-the-default-fallback-routing-algorithm-for-the-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<connector: string, merchant_connector_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/profiles/($id)/fallback-routing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Profile - Retrieve Active Routing Algorithm
#
# GET /v2/profiles/{id}/routing-algorithm
# operationId: Retrieve the active routing algorithm under the profile
export def "profiles-routing-algorithm Retrieve-the-active-routing-algorithm-under-the-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of records of the algorithms to be returned (nullable, format: int32)
  --offset: int # The record offset of the algorithm from which to start gathering the results (nullable, format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/profiles/($id)/routing-algorithm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Create
#
# POST /v2/routing-algorithms
# operationId: Create a routing algorithm
export def "routing-algorithms Create-a-routing-algorithm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  description: string
  algorithm: any
  profile_id: string
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/routing-algorithms")
  let body = {name: $name, description: $description, algorithm: $algorithm, profile_id: $profile_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Retrieve
#
# GET /v2/routing-algorithms/{id}
# operationId: Retrieve a routing algorithm with its algorithm id
export def "routing-algorithms Retrieve-a-routing-algorithm-with-its-algorithm-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, profile_id: string, name: string, description: string, algorithm: any, created_at: int, modified_at: int, algorithm_for: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/routing-algorithms/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Key - Create
#
# POST /v2/api-keys
# operationId: Create an API Key
export def "api-keys Create-an-API-Key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A unique name for the API Key to help you identify it. (e.g. Sandbox integration key)
  --description: string # A description to provide more context about the API Key. (nullable, e.g. Key used by our developers to integrate with the sandbox environment)
  expiration: any
]: any -> record<key_id: string, merchant_id: string, name: string, description: string, api_key: string, created: string, expiration: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/api-keys")
  let body = {name: $name, description: $description, expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# API Key - Retrieve
#
# GET /v2/api-keys/{id}
# operationId: Retrieve an API Key
export def "api-keys Retrieve-an-API-Key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key_id: string, merchant_id: string, name: string, description: string, prefix: string, created: string, expiration: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/api-keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Key - Update
#
# PUT /v2/api-keys/{id}
# operationId: Update an API Key
export def "api-keys Update-an-API-Key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A unique name for the API Key to help you identify it. (nullable, e.g. Sandbox integration key)
  --description: string # A description to provide more context about the API Key. (nullable, e.g. Key used by our developers to integrate with the sandbox environment)
  --expiration: any # nullable
]: any -> record<key_id: string, merchant_id: string, name: string, description: string, prefix: string, created: string, expiration: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/api-keys/($id)")
  let body = {name: $name, description: $description, expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# API Key - Revoke
#
# DELETE /v2/api-keys/{id}
# operationId: Revoke an API Key
export def "api-keys Revoke-an-API-Key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<merchant_id: string, key_id: string, revoked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/api-keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Key - List
#
# GET /v2/api-keys/list
# operationId: List all API Keys associated with a merchant account
export def "api-keys-list List-all-API-Keys-associated-with-a-merchant-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of API Keys to include in the response (nullable, format: int64)
  --skip: int # The number of API Keys to skip when retrieving the list of API keys. (nullable, format: int64)
]: nothing -> table<key_id: string, merchant_id: string, name: string, description: string, prefix: string, created: string, expiration: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/api-keys/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - Create
#
# POST /v2/customers
# operationId: Create a Customer
export def "customers Create-a-Customer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
  --merchant-reference-id: string # The merchant identifier for the customer object. (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  name: string # The customer's name (e.g. Jon Test)
  email: string # The customer's email address (e.g. JonTest@test.com)
  --phone: string # The customer's phone number (nullable, e.g. 9123456789)
  --description: string # An arbitrary string that you can attach to a customer object. (nullable, e.g. First Customer)
  --phone-country-code: string # The country code for the customer phone number (nullable, e.g. +65)
  --default-billing-address: any # nullable
  --default-shipping-address: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --tax-registration-id: string # The customer's tax registration number. (nullable, e.g. 123456789)
  --document-details: any # nullable
]: any -> record<id: string, merchant_reference_id: string, connector_customer_ids: record, name: string, email: string, phone: string, phone_country_code: string, description: string, default_billing_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, default_shipping_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers")
  let body = {merchant_reference_id: $merchant_reference_id, name: $name, email: $email, phone: $phone, description: $description, phone_country_code: $phone_country_code, default_billing_address: $default_billing_address, default_shipping_address: $default_shipping_address, metadata: $metadata, tax_registration_id: $tax_registration_id, document_details: $document_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Customers - Create
#
# POST /v1/customers
# operationId: Create a Customer
export def "customers Create-a-Customer-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
  --merchant-reference-id: string # The merchant identifier for the customer object. (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  name: string # The customer's name (e.g. Jon Test)
  email: string # The customer's email address (e.g. JonTest@test.com)
  --phone: string # The customer's phone number (nullable, e.g. 9123456789)
  --description: string # An arbitrary string that you can attach to a customer object. (nullable, e.g. First Customer)
  --phone-country-code: string # The country code for the customer phone number (nullable, e.g. +65)
  --default-billing-address: any # nullable
  --default-shipping-address: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --tax-registration-id: string # The customer's tax registration number. (nullable, e.g. 123456789)
  --document-details: any # nullable
]: any -> record<id: string, merchant_reference_id: string, connector_customer_ids: record, name: string, email: string, phone: string, phone_country_code: string, description: string, default_billing_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, default_shipping_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers")
  let body = {merchant_reference_id: $merchant_reference_id, name: $name, email: $email, phone: $phone, description: $description, phone_country_code: $phone_country_code, default_billing_address: $default_billing_address, default_shipping_address: $default_shipping_address, metadata: $metadata, tax_registration_id: $tax_registration_id, document_details: $document_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Customers - Retrieve
#
# GET /v2/customers/{id}
# operationId: Retrieve a Customer
export def "customers Retrieve-a-Customer-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, merchant_reference_id: string, connector_customer_ids: record, name: string, email: string, phone: string, phone_country_code: string, description: string, default_billing_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, default_shipping_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - Update
#
# PUT /v2/customers/{id}
# operationId: Update a Customer
export def "customers Update-a-Customer-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
  name: string # The customer's name (e.g. Jon Test)
  email: string # The customer's email address (e.g. JonTest@test.com)
  --phone: string # The customer's phone number (nullable, e.g. 9123456789)
  --description: string # An arbitrary string that you can attach to a customer object. (nullable, e.g. First Customer)
  --phone-country-code: string # The country code for the customer phone number (nullable, e.g. +65)
  --default-billing-address: any # nullable
  --default-shipping-address: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --default-payment-method-id: string # The unique identifier of the payment method (nullable, e.g. 0a_pm_01926c58bc6e77c09e809964e72af8c8)
  --tax-registration-id: string # The customer's tax registration number. (nullable, e.g. 123456789)
  --document-details: any # nullable
]: any -> record<id: string, merchant_reference_id: string, connector_customer_ids: record, name: string, email: string, phone: string, phone_country_code: string, description: string, default_billing_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, default_shipping_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($id)")
  let body = {name: $name, email: $email, phone: $phone, description: $description, phone_country_code: $phone_country_code, default_billing_address: $default_billing_address, default_shipping_address: $default_shipping_address, metadata: $metadata, default_payment_method_id: $default_payment_method_id, tax_registration_id: $tax_registration_id, document_details: $document_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Customers - Delete
#
# DELETE /v2/customers/{id}
# operationId: Delete a Customer
export def "customers Delete-a-Customer-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, merchant_reference_id: string, customer_deleted: bool, address_deleted: bool, payment_methods_deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - Retrieve
#
# GET /v1/customers/{id}
# operationId: Retrieve a Customer
export def "customers Retrieve-a-Customer-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, merchant_reference_id: string, connector_customer_ids: record, name: string, email: string, phone: string, phone_country_code: string, description: string, default_billing_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, default_shipping_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - Update
#
# PUT /v1/customers/{id}
# operationId: Update a Customer
export def "customers Update-a-Customer-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
  name: string # The customer's name (e.g. Jon Test)
  email: string # The customer's email address (e.g. JonTest@test.com)
  --phone: string # The customer's phone number (nullable, e.g. 9123456789)
  --description: string # An arbitrary string that you can attach to a customer object. (nullable, e.g. First Customer)
  --phone-country-code: string # The country code for the customer phone number (nullable, e.g. +65)
  --default-billing-address: any # nullable
  --default-shipping-address: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --default-payment-method-id: string # The unique identifier of the payment method (nullable, e.g. 0a_pm_01926c58bc6e77c09e809964e72af8c8)
  --tax-registration-id: string # The customer's tax registration number. (nullable, e.g. 123456789)
  --document-details: any # nullable
]: any -> record<id: string, merchant_reference_id: string, connector_customer_ids: record, name: string, email: string, phone: string, phone_country_code: string, description: string, default_billing_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, default_shipping_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($id)")
  let body = {name: $name, email: $email, phone: $phone, description: $description, phone_country_code: $phone_country_code, default_billing_address: $default_billing_address, default_shipping_address: $default_shipping_address, metadata: $metadata, default_payment_method_id: $default_payment_method_id, tax_registration_id: $tax_registration_id, document_details: $document_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Customers - Delete
#
# DELETE /v1/customers/{id}
# operationId: Delete a Customer
export def "customers Delete-a-Customer-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, merchant_reference_id: string, customer_deleted: bool, address_deleted: bool, payment_methods_deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - List
#
# GET /v2/customers/list
# operationId: List all Customers for a Merchant
export def "customers-list List-all-Customers-for-a-Merchant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
]: nothing -> table<id: string, merchant_reference_id: string, connector_customer_ids: record, name: string, email: string, phone: string, phone_country_code: string, description: string, default_billing_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, default_shipping_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/list")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - List
#
# GET /v1/customers/list
# operationId: List all Customers for a Merchant
export def "customers-list List-all-Customers-for-a-Merchant-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the customer (e.g. pro_abcdefghijklmnop)
]: nothing -> table<id: string, merchant_reference_id: string, connector_customer_ids: record, name: string, email: string, phone: string, phone_country_code: string, description: string, default_billing_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, default_shipping_address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers/list")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - Create Intent
#
# POST /v2/payments/create-intent
# operationId: Create a Payment Intent
# --amount_details shape: {order_amount?: int, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VES"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZWL", shipping_cost?: any, order_tax_amount?: any, skip_external_tax_calculation?: "skip"|"calculate", skip_surcharge_calculation?: "skip"|"calculate", surcharge_amount?: any, tax_on_surcharge?: any}
# --order_details item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
export def "payments-create-intent Create-a-Payment-Intent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount_details: record # shape: {order_amount?: int, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VES"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZWL", shipping_cost?: any, order_tax_amount?: any, skip_external_tax_calculation?: "skip"|"calculate", skip_surcharge_calculation?: "skip"|"calculate", surcharge_amount?: any, tax_on_surcharge?: any}
  --merchant-reference-id: string # Unique identifier for the payment. This ensures idempotency for multiple payments that have been done by a single merchant. (nullable, e.g. pay_mbabizu24mvu3mela5njyhpit4)
  --routing-algorithm-id: string # The routing algorithm id to be used for the payment (nullable)
  --capture-method: any # nullable
  --authentication-type: any # nullable, default: no_three_ds
  --billing: any # nullable
  --shipping: any # nullable
  customer_id: string # The identifier for the customer (e.g. 0a_cus_01926c58bc6e77c09e809964e72af8c8)
  --customer-present: any # nullable
  --description: string # A description for the payment (nullable, e.g. It's my first payment request)
  --return-url: string # The URL to which you want the user to be redirected after the completion of the payment operation (nullable, e.g. https://hyperswitch.io)
  --setup-future-usage: any # nullable
  --apply-mit-exemption: any # nullable
  --statement-descriptor: string # For non-card charges, you can use this value as the complete description that appears on your customers’ statements. Must contain at least one letter, maximum 22 characters. (nullable, e.g. Hyperswitch Router)
  --order-details: list # Use this object to capture the details about the different products for which the payment is being made. The sum of amount across different products here should be equal to the overall payment amount (nullable, e.g. [{         "product_name": "Apple iPhone 16",         "quantity": 1,         "amount" : 69000         "product_img_link" : "https://dummy-img-link.com"     }]) — item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
  --allowed-payment-method-types: list # Use this parameter to restrict the Payment Method Types to show for a given PaymentIntent (nullable)
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --connector-metadata: any # nullable
  --feature-metadata: any # nullable
  --payment-link-enabled: any # nullable
  --payment-link-config: any # nullable
  --request-incremental-authorization: any # nullable
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds, if not sent it will be taken from profile config (900) for 15 mins (nullable, format: int32, e.g. 900)
  --frm-metadata: record # Additional data related to some frm(Fraud Risk Management) connectors (nullable)
  --request-external-three-ds-authentication: any # nullable
  --force-3ds-challenge: oneof<nothing, bool> # Indicates if 3ds challenge is forced (nullable)
  --merchant-connector-details: any # nullable
  --enable-partial-authorization: oneof<nothing, bool> # Allow partial authorization for this payment (nullable, default: false)
]: any -> record<id: string, status: string, amount_details: record<order_amount: int, currency: string, shipping_cost: record, order_tax_amount: record, external_tax_calculation: string, surcharge_calculation: string, surcharge_amount: record, tax_on_surcharge: record, amount_captured: record>, client_secret: string, profile_id: string, merchant_reference_id: string, routing_algorithm_id: string, capture_method: string, authentication_type: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, customer_id: string, customer_present: string, description: string, return_url: string, setup_future_usage: string, apply_mit_exemption: string, statement_descriptor: string, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, allowed_payment_method_types: list<string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, revenue_recovery: record<total_retry_count: int, payment_connector_transmission: record, billing_connector_id: string, active_attempt_payment_connector_id: string, billing_connector_payment_details: record, payment_method_type: string, payment_method_subtype: string, connector: string, billing_connector_payment_method_details: any, invoice_next_billing_time: string, invoice_billing_started_at_time: string, first_payment_attempt_pg_error_code: string, first_payment_attempt_network_decline_code: string, first_payment_attempt_network_advice_code: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, payment_link_enabled: string, payment_link_config: record<theme: string, logo: string, seller_name: string, sdk_layout: string, display_sdk_only: bool, enabled_saved_payment_method: bool, hide_card_nickname_field: bool, show_card_form_by_default: bool, transaction_details: list<record>, background_image: record<url: string, position: record, size: record>, details_layout: record, payment_button_text: string, custom_message_for_card_terms: string, custom_message_for_payment_method_types: record, payment_button_colour: string, skip_status_screen: bool, payment_button_text_colour: string, background_colour: string, sdk_ui_rules: record, payment_link_ui_rules: record, enable_button_only_on_form_ready: bool, payment_form_header_text: string, payment_form_label_type: record, show_card_terms: record, is_setup_mandate_flow: bool, color_icon_card_cvc_error: string, show_merchant_name: bool>, request_incremental_authorization: string, split_txns_enabled: record, expires_on: string, frm_metadata: record, request_external_three_ds_authentication: string, payment_type: string, enable_partial_authorization: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payments/create-intent")
  let body = {amount_details: $amount_details, merchant_reference_id: $merchant_reference_id, routing_algorithm_id: $routing_algorithm_id, capture_method: $capture_method, authentication_type: $authentication_type, billing: $billing, shipping: $shipping, customer_id: $customer_id, customer_present: $customer_present, description: $description, return_url: $return_url, setup_future_usage: $setup_future_usage, apply_mit_exemption: $apply_mit_exemption, statement_descriptor: $statement_descriptor, order_details: $order_details, allowed_payment_method_types: $allowed_payment_method_types, metadata: $metadata, connector_metadata: $connector_metadata, feature_metadata: $feature_metadata, payment_link_enabled: $payment_link_enabled, payment_link_config: $payment_link_config, request_incremental_authorization: $request_incremental_authorization, session_expiry: $session_expiry, frm_metadata: $frm_metadata, request_external_three_ds_authentication: $request_external_three_ds_authentication, force_3ds_challenge: $force_3ds_challenge, merchant_connector_details: $merchant_connector_details, enable_partial_authorization: $enable_partial_authorization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Get Intent
#
# GET /v2/payments/{id}/get-intent
# operationId: Get the Payment Intent details
export def "payments-get-intent Get-the-Payment-Intent-details" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, amount_details: record<order_amount: int, currency: string, shipping_cost: record, order_tax_amount: record, external_tax_calculation: string, surcharge_calculation: string, surcharge_amount: record, tax_on_surcharge: record, amount_captured: record>, client_secret: string, profile_id: string, merchant_reference_id: string, routing_algorithm_id: string, capture_method: string, authentication_type: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, customer_id: string, customer_present: string, description: string, return_url: string, setup_future_usage: string, apply_mit_exemption: string, statement_descriptor: string, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, allowed_payment_method_types: list<string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, revenue_recovery: record<total_retry_count: int, payment_connector_transmission: record, billing_connector_id: string, active_attempt_payment_connector_id: string, billing_connector_payment_details: record, payment_method_type: string, payment_method_subtype: string, connector: string, billing_connector_payment_method_details: any, invoice_next_billing_time: string, invoice_billing_started_at_time: string, first_payment_attempt_pg_error_code: string, first_payment_attempt_network_decline_code: string, first_payment_attempt_network_advice_code: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, payment_link_enabled: string, payment_link_config: record<theme: string, logo: string, seller_name: string, sdk_layout: string, display_sdk_only: bool, enabled_saved_payment_method: bool, hide_card_nickname_field: bool, show_card_form_by_default: bool, transaction_details: list<record>, background_image: record<url: string, position: record, size: record>, details_layout: record, payment_button_text: string, custom_message_for_card_terms: string, custom_message_for_payment_method_types: record, payment_button_colour: string, skip_status_screen: bool, payment_button_text_colour: string, background_colour: string, sdk_ui_rules: record, payment_link_ui_rules: record, enable_button_only_on_form_ready: bool, payment_form_header_text: string, payment_form_label_type: record, show_card_terms: record, is_setup_mandate_flow: bool, color_icon_card_cvc_error: string, show_merchant_name: bool>, request_incremental_authorization: string, split_txns_enabled: record, expires_on: string, frm_metadata: record, request_external_three_ds_authentication: string, payment_type: string, enable_partial_authorization: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($id)/get-intent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - Update Intent
#
# PUT /v2/payments/{id}/update-intent
# operationId: Update a Payment Intent
# --order_details item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
export def "payments-update-intent Update-a-Payment-Intent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment intent (e.g. pro_abcdefghijklmnop)
  --amount-details: any # nullable
  --routing-algorithm-id: string # The routing algorithm id to be used for the payment (nullable)
  --capture-method: any # nullable
  --authentication-type: any # nullable, default: no_three_ds
  --billing: any # nullable
  --shipping: any # nullable
  --customer-present: any # nullable
  --description: string # A description for the payment (nullable, e.g. It's my first payment request)
  --return-url: string # The URL to which you want the user to be redirected after the completion of the payment operation (nullable, e.g. https://hyperswitch.io)
  --setup-future-usage: any # nullable
  --apply-mit-exemption: any # nullable
  --statement-descriptor: string # For non-card charges, you can use this value as the complete description that appears on your customers’ statements. Must contain at least one letter, maximum 22 characters. (nullable, e.g. Hyperswitch Router)
  --order-details: list # Use this object to capture the details about the different products for which the payment is being made. The sum of amount across different products here should be equal to the overall payment amount (nullable, e.g. [{         "product_name": "Apple iPhone 16",         "quantity": 1,         "amount" : 69000         "product_img_link" : "https://dummy-img-link.com"     }]) — item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
  --allowed-payment-method-types: list # Use this parameter to restrict the Payment Method Types to show for a given PaymentIntent (nullable)
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. This metadata will override the metadata that was passed in payments (nullable)
  --connector-metadata: any # nullable
  --feature-metadata: any # nullable
  --payment-link-config: any # nullable
  --request-incremental-authorization: any # nullable
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds, if not sent it will be taken from profile config (900) for 15 mins (nullable, format: int32, e.g. 900)
  --frm-metadata: record # Additional data related to some frm(Fraud Risk Management) connectors (nullable)
  --request-external-three-ds-authentication: any # nullable
  --set-active-attempt-id: any # nullable
  --enable-partial-authorization: oneof<nothing, bool> # Allow partial authorization for this payment (nullable, default: false)
]: any -> record<id: string, status: string, amount_details: record<order_amount: int, currency: string, shipping_cost: record, order_tax_amount: record, external_tax_calculation: string, surcharge_calculation: string, surcharge_amount: record, tax_on_surcharge: record, amount_captured: record>, client_secret: string, profile_id: string, merchant_reference_id: string, routing_algorithm_id: string, capture_method: string, authentication_type: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, customer_id: string, customer_present: string, description: string, return_url: string, setup_future_usage: string, apply_mit_exemption: string, statement_descriptor: string, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, allowed_payment_method_types: list<string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, revenue_recovery: record<total_retry_count: int, payment_connector_transmission: record, billing_connector_id: string, active_attempt_payment_connector_id: string, billing_connector_payment_details: record, payment_method_type: string, payment_method_subtype: string, connector: string, billing_connector_payment_method_details: any, invoice_next_billing_time: string, invoice_billing_started_at_time: string, first_payment_attempt_pg_error_code: string, first_payment_attempt_network_decline_code: string, first_payment_attempt_network_advice_code: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, payment_link_enabled: string, payment_link_config: record<theme: string, logo: string, seller_name: string, sdk_layout: string, display_sdk_only: bool, enabled_saved_payment_method: bool, hide_card_nickname_field: bool, show_card_form_by_default: bool, transaction_details: list<record>, background_image: record<url: string, position: record, size: record>, details_layout: record, payment_button_text: string, custom_message_for_card_terms: string, custom_message_for_payment_method_types: record, payment_button_colour: string, skip_status_screen: bool, payment_button_text_colour: string, background_colour: string, sdk_ui_rules: record, payment_link_ui_rules: record, enable_button_only_on_form_ready: bool, payment_form_header_text: string, payment_form_label_type: record, show_card_terms: record, is_setup_mandate_flow: bool, color_icon_card_cvc_error: string, show_merchant_name: bool>, request_incremental_authorization: string, split_txns_enabled: record, expires_on: string, frm_metadata: record, request_external_three_ds_authentication: string, payment_type: string, enable_partial_authorization: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($id)/update-intent")
  let body = {amount_details: $amount_details, routing_algorithm_id: $routing_algorithm_id, capture_method: $capture_method, authentication_type: $authentication_type, billing: $billing, shipping: $shipping, customer_present: $customer_present, description: $description, return_url: $return_url, setup_future_usage: $setup_future_usage, apply_mit_exemption: $apply_mit_exemption, statement_descriptor: $statement_descriptor, order_details: $order_details, allowed_payment_method_types: $allowed_payment_method_types, metadata: $metadata, connector_metadata: $connector_metadata, feature_metadata: $feature_metadata, payment_link_config: $payment_link_config, request_incremental_authorization: $request_incremental_authorization, session_expiry: $session_expiry, frm_metadata: $frm_metadata, request_external_three_ds_authentication: $request_external_three_ds_authentication, set_active_attempt_id: $set_active_attempt_id, enable_partial_authorization: $enable_partial_authorization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Confirm Intent
#
# POST /v2/payments/{id}/confirm-intent
# operationId: Confirm Payment Intent
# --split_payment_method_data item shape: {payment_method_data: any, payment_method_type: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_subtype: "ach"|"affirm"|"afterpay_clearpay"|"alfamart"|"ali_pay"|"ali_pay_hk"|"alma"|"amazon_pay"|"paysera"|"apple_pay"|"atome"|"bacs"|"bancontact_card"|"becs"|"benefit"|"bizum"|"blik"|"bluecode"|"boleto"|"bca_bank_transfer"|"bni_va"|"breadpay"|"bri_va"|"bhn_card_network"|"card_redirect"|"cimb_va"|"classic"|"credit"|"crypto_currency"|"cashapp"|"dana"|"danamon_va"|"debit"|"duit_now"|"efecty"|"eft"|"eft_debit_order"|"eps"|"flexiti"|"fps"|"evoucher"|"giropay"|"givex"|"google_pay"|"go_pay"|"gcash"|"ideal"|"interac"|"indomaret"|"klarna"|"kakao_pay"|"local_bank_redirect"|"mandiri_va"|"knet"|"mb_way"|"mobile_pay"|"momo"|"momo_atm"|"multibanco"|"online_banking_thailand"|"online_banking_czech_republic"|"online_banking_finland"|"online_banking_fpx"|"online_banking_poland"|"online_banking_slovakia"|"oxxo"|"pago_efectivo"|"permata_bank_transfer"|"open_banking_uk"|"pay_bright"|"payjustnow"|"paypal"|"paze"|"pix"|"pix_key"|"pix_emv"|"pix_automatico_qr"|"pix_automatico_push"|"pay_safe_card"|"przelewy24"|"prompt_pay"|"pse"|"qris"|"red_compra"|"red_pagos"|"samsung_pay"|"sepa"|"sepa_bank_transfer"|"sepa_guarenteed_debit"|"skrill"|"sofort"|"swish"|"touch_n_go"|"trustly"|"twint"|"upi_collect"|"upi_intent"|"upi_qr"|"vipps"|"viet_qr"|"venmo"|"walley"|"we_chat_pay"|"seven_eleven"|"lawson"|"mini_stop"|"family_mart"|"seicomart"|"pay_easy"|"local_bank_transfer"|"mifinity"|"open_banking_pis"|"direct_carrier_billing"|"instant_bank_transfer"|"instant_bank_transfer_finland"|"instant_bank_transfer_poland"|"revolut_pay"|"indonesian_bank_transfer"|"open_banking"|"network_token"}
export def "payments-confirm-intent Confirm-Payment-Intent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment intent (e.g. pro_abcdefghijklmnop)
  --return-url: string # The URL to which you want the user to be redirected after the completion of the payment operation If this url is not passed, the url configured in the business profile will be used (nullable, e.g. https://hyperswitch.io)
  payment_method_data: any # The payment method information provided for making a payment
  --split-payment-method-data: list # The payment instrument data to be used for the payment in case of split payments (nullable) — item shape: {payment_method_data: any, payment_method_type: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_subtype: "ach"|"affirm"|"afterpay_clearpay"|"alfamart"|"ali_pay"|"ali_pay_hk"|"alma"|"amazon_pay"|"paysera"|"apple_pay"|"atome"|"bacs"|"bancontact_card"|"becs"|"benefit"|"bizum"|"blik"|"bluecode"|"boleto"|"bca_bank_transfer"|"bni_va"|"breadpay"|"bri_va"|"bhn_card_network"|"card_redirect"|"cimb_va"|"classic"|"credit"|"crypto_currency"|"cashapp"|"dana"|"danamon_va"|"debit"|"duit_now"|"efecty"|"eft"|"eft_debit_order"|"eps"|"flexiti"|"fps"|"evoucher"|"giropay"|"givex"|"google_pay"|"go_pay"|"gcash"|"ideal"|"interac"|"indomaret"|"klarna"|"kakao_pay"|"local_bank_redirect"|"mandiri_va"|"knet"|"mb_way"|"mobile_pay"|"momo"|"momo_atm"|"multibanco"|"online_banking_thailand"|"online_banking_czech_republic"|"online_banking_finland"|"online_banking_fpx"|"online_banking_poland"|"online_banking_slovakia"|"oxxo"|"pago_efectivo"|"permata_bank_transfer"|"open_banking_uk"|"pay_bright"|"payjustnow"|"paypal"|"paze"|"pix"|"pix_key"|"pix_emv"|"pix_automatico_qr"|"pix_automatico_push"|"pay_safe_card"|"przelewy24"|"prompt_pay"|"pse"|"qris"|"red_compra"|"red_pagos"|"samsung_pay"|"sepa"|"sepa_bank_transfer"|"sepa_guarenteed_debit"|"skrill"|"sofort"|"swish"|"touch_n_go"|"trustly"|"twint"|"upi_collect"|"upi_intent"|"upi_qr"|"vipps"|"viet_qr"|"venmo"|"walley"|"we_chat_pay"|"seven_eleven"|"lawson"|"mini_stop"|"family_mart"|"seicomart"|"pay_easy"|"local_bank_transfer"|"mifinity"|"open_banking_pis"|"direct_carrier_billing"|"instant_bank_transfer"|"instant_bank_transfer_finland"|"instant_bank_transfer_poland"|"revolut_pay"|"indonesian_bank_transfer"|"open_banking"|"network_token"}
  payment_method_type: string@payment-method-type-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-subtype: any # nullable
  --shipping: any # nullable
  --customer-acceptance: any # nullable
  --browser-info: any # nullable
  --payment-method-id: string # The payment_method_id to be associated with the payment (nullable)
  --payment-token: string # nullable, e.g. 187282ab-40ef-47a9-9206-5099ba31e432
  --merchant-connector-details: any # nullable
  --return-raw-connector-response: oneof<nothing, bool> # If true, returns stringified connector raw response body (nullable)
  --webhook-url: string # The webhook endpoint URL to receive payment status notifications (nullable, e.g. https://merchant.example.com/webhooks/payment)
]: any -> record<id: string, status: string, amount: record<order_amount: int, currency: string, shipping_cost: record, order_tax_amount: record, external_tax_calculation: string, surcharge_calculation: string, surcharge_amount: record, tax_on_surcharge: record, net_amount: int, amount_to_capture: record, amount_capturable: int, amount_captured: record>, customer_id: string, processor_merchant_id: string, initiator: record, connector: string, created: string, modified_at: string, payment_method_data: record, payment_method_type: record, payment_method_subtype: record, connector_transaction_id: string, connector_reference_id: string, merchant_connector_id: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, attempts: table<id: string, status: string, amount: record, connector: string, error: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, payment_token: string, connector_metadata: record, payment_experience: record, payment_method_type: record, connector_reference_id: string, payment_method_subtype: record, connector_payment_id: string, payment_method_id: string, client_source: string, client_version: string, feature_metadata: record, payment_method_data: record>, connector_token_details: record<token: string, connector_token_request_reference_id: string>, payment_method_id: string, next_action: record, return_url: string, authentication_type: record, authentication_type_applied: record, is_iframe_redirection_enabled: bool, merchant_reference_id: string, raw_connector_response: string, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, revenue_recovery: record<total_retry_count: int, payment_connector_transmission: record, billing_connector_id: string, active_attempt_payment_connector_id: string, billing_connector_payment_details: record, payment_method_type: string, payment_method_subtype: string, connector: string, billing_connector_payment_method_details: any, invoice_next_billing_time: string, invoice_billing_started_at_time: string, first_payment_attempt_pg_error_code: string, first_payment_attempt_network_decline_code: string, first_payment_attempt_network_advice_code: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($id)/confirm-intent")
  let body = {return_url: $return_url, payment_method_data: $payment_method_data, split_payment_method_data: $split_payment_method_data, payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype, shipping: $shipping, customer_acceptance: $customer_acceptance, browser_info: $browser_info, payment_method_id: $payment_method_id, payment_token: $payment_token, merchant_connector_details: $merchant_connector_details, return_raw_connector_response: $return_raw_connector_response, webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Get
#
# GET /v2/payments/{id}
# operationId: Retrieve a Payment
export def "payments Retrieve-a-Payment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-sync: string@force-sync-completer # A boolean to indicate whether to force sync the payment status. Value can be true or false
]: nothing -> record<id: string, status: string, amount: record<order_amount: int, currency: string, shipping_cost: record, order_tax_amount: record, external_tax_calculation: string, surcharge_calculation: string, surcharge_amount: record, tax_on_surcharge: record, net_amount: int, amount_to_capture: record, amount_capturable: int, amount_captured: record>, customer_id: string, processor_merchant_id: string, initiator: record, connector: string, created: string, modified_at: string, payment_method_data: record, payment_method_type: record, payment_method_subtype: record, connector_transaction_id: string, connector_reference_id: string, merchant_connector_id: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, attempts: table<id: string, status: string, amount: record, connector: string, error: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, payment_token: string, connector_metadata: record, payment_experience: record, payment_method_type: record, connector_reference_id: string, payment_method_subtype: record, connector_payment_id: string, payment_method_id: string, client_source: string, client_version: string, feature_metadata: record, payment_method_data: record>, connector_token_details: record<token: string, connector_token_request_reference_id: string>, payment_method_id: string, next_action: record, return_url: string, authentication_type: record, authentication_type_applied: record, is_iframe_redirection_enabled: bool, merchant_reference_id: string, raw_connector_response: string, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, revenue_recovery: record<total_retry_count: int, payment_connector_transmission: record, billing_connector_id: string, active_attempt_payment_connector_id: string, billing_connector_payment_details: record, payment_method_type: string, payment_method_subtype: string, connector: string, billing_connector_payment_method_details: any, invoice_next_billing_time: string, invoice_billing_started_at_time: string, first_payment_attempt_pg_error_code: string, first_payment_attempt_network_decline_code: string, first_payment_attempt_network_advice_code: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_sync" $force_sync "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/payments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - Create and Confirm Intent
#
# POST /v2/payments
# operationId: Create and Confirm Payment Intent
# --amount_details shape: {order_amount?: int, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VES"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZWL", shipping_cost?: any, order_tax_amount?: any, skip_external_tax_calculation?: "skip"|"calculate", skip_surcharge_calculation?: "skip"|"calculate", surcharge_amount?: any, tax_on_surcharge?: any}
# --order_details item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
export def "payments Create-and-Confirm-Payment-Intent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment intent (e.g. pro_abcdefghijklmnop)
  amount_details: record # shape: {order_amount?: int, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VES"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZWL", shipping_cost?: any, order_tax_amount?: any, skip_external_tax_calculation?: "skip"|"calculate", skip_surcharge_calculation?: "skip"|"calculate", surcharge_amount?: any, tax_on_surcharge?: any}
  --merchant-reference-id: string # Unique identifier for the payment. This ensures idempotency for multiple payments that have been done by a single merchant. (nullable, e.g. pay_mbabizu24mvu3mela5njyhpit4)
  --routing-algorithm-id: string # The routing algorithm id to be used for the payment (nullable)
  --capture-method: any # nullable
  --authentication-type: any # nullable, default: no_three_ds
  --billing: any # nullable
  --shipping: any # nullable
  customer_id: string # The identifier for the customer (e.g. 0a_cus_01926c58bc6e77c09e809964e72af8c8)
  --customer-present: any # nullable
  --description: string # A description for the payment (nullable, e.g. It's my first payment request)
  --return-url: string # The URL to which you want the user to be redirected after the completion of the payment operation (nullable, e.g. https://hyperswitch.io)
  --setup-future-usage: any # nullable
  --apply-mit-exemption: any # nullable
  --statement-descriptor: string # For non-card charges, you can use this value as the complete description that appears on your customers’ statements. Must contain at least one letter, maximum 22 characters. (nullable, e.g. Hyperswitch Router)
  --order-details: list # Use this object to capture the details about the different products for which the payment is being made. The sum of amount across different products here should be equal to the overall payment amount (nullable, e.g. [{         "product_name": "Apple iPhone 16",         "quantity": 1,         "amount" : 69000         "product_img_link" : "https://dummy-img-link.com"     }]) — item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
  --allowed-payment-method-types: list # Use this parameter to restrict the Payment Method Types to show for a given PaymentIntent (nullable)
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --connector-metadata: any # nullable
  --feature-metadata: any # nullable
  --payment-link-enabled: any # nullable
  --payment-link-config: any # nullable
  --request-incremental-authorization: any # nullable
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds, if not sent it will be taken from profile config (900) for 15 mins (nullable, format: int32, e.g. 900)
  --frm-metadata: record # Additional data related to some frm(Fraud Risk Management) connectors (nullable)
  --request-external-three-ds-authentication: any # nullable
  payment_method_data: any # The payment method information provided for making a payment
  payment_method_type: string@payment-method-type-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-subtype: any # nullable
  --customer-acceptance: any # nullable
  --browser-info: any # nullable
  --payment-method-id: string # The payment_method_id to be associated with the payment (nullable)
  --force-3ds-challenge: oneof<nothing, bool> # Indicates if 3ds challenge is forced (nullable)
  --is-iframe-redirection-enabled: oneof<nothing, bool> # Indicates if the redirection has to open in the iframe (nullable)
  --merchant-connector-details: any # nullable
  --return-raw-connector-response: oneof<nothing, bool> # Stringified connector raw response body. Only returned if `return_raw_connector_response` is true (nullable)
  --enable-partial-authorization: oneof<nothing, bool> # Allow partial authorization for this payment (nullable, default: false)
  --webhook-url: string # The webhook endpoint URL to receive payment status notifications (nullable, e.g. https://merchant.example.com/webhooks/payment)
]: any -> record<id: string, status: string, amount: record<order_amount: int, currency: string, shipping_cost: record, order_tax_amount: record, external_tax_calculation: string, surcharge_calculation: string, surcharge_amount: record, tax_on_surcharge: record, net_amount: int, amount_to_capture: record, amount_capturable: int, amount_captured: record>, customer_id: string, processor_merchant_id: string, initiator: record, connector: string, created: string, modified_at: string, payment_method_data: record, payment_method_type: record, payment_method_subtype: record, connector_transaction_id: string, connector_reference_id: string, merchant_connector_id: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, attempts: table<id: string, status: string, amount: record, connector: string, error: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, payment_token: string, connector_metadata: record, payment_experience: record, payment_method_type: record, connector_reference_id: string, payment_method_subtype: record, connector_payment_id: string, payment_method_id: string, client_source: string, client_version: string, feature_metadata: record, payment_method_data: record>, connector_token_details: record<token: string, connector_token_request_reference_id: string>, payment_method_id: string, next_action: record, return_url: string, authentication_type: record, authentication_type_applied: record, is_iframe_redirection_enabled: bool, merchant_reference_id: string, raw_connector_response: string, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, revenue_recovery: record<total_retry_count: int, payment_connector_transmission: record, billing_connector_id: string, active_attempt_payment_connector_id: string, billing_connector_payment_details: record, payment_method_type: string, payment_method_subtype: string, connector: string, billing_connector_payment_method_details: any, invoice_next_billing_time: string, invoice_billing_started_at_time: string, first_payment_attempt_pg_error_code: string, first_payment_attempt_network_decline_code: string, first_payment_attempt_network_advice_code: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payments")
  let body = {amount_details: $amount_details, merchant_reference_id: $merchant_reference_id, routing_algorithm_id: $routing_algorithm_id, capture_method: $capture_method, authentication_type: $authentication_type, billing: $billing, shipping: $shipping, customer_id: $customer_id, customer_present: $customer_present, description: $description, return_url: $return_url, setup_future_usage: $setup_future_usage, apply_mit_exemption: $apply_mit_exemption, statement_descriptor: $statement_descriptor, order_details: $order_details, allowed_payment_method_types: $allowed_payment_method_types, metadata: $metadata, connector_metadata: $connector_metadata, feature_metadata: $feature_metadata, payment_link_enabled: $payment_link_enabled, payment_link_config: $payment_link_config, request_incremental_authorization: $request_incremental_authorization, session_expiry: $session_expiry, frm_metadata: $frm_metadata, request_external_three_ds_authentication: $request_external_three_ds_authentication, payment_method_data: $payment_method_data, payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype, customer_acceptance: $customer_acceptance, browser_info: $browser_info, payment_method_id: $payment_method_id, force_3ds_challenge: $force_3ds_challenge, is_iframe_redirection_enabled: $is_iframe_redirection_enabled, merchant_connector_details: $merchant_connector_details, return_raw_connector_response: $return_raw_connector_response, enable_partial_authorization: $enable_partial_authorization, webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Session token
#
# POST /v2/payments/{payment_id}/create-external-sdk-tokens
# operationId: Create V2 Session tokens for a Payment
export def "payments-create-external-sdk-tokens Create-V2-Session-tokens-for-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<payment_id: string, session_token: list<any>, vault_details: record<internal_vault: record<sdk_authorization: string>, external_vault_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($payment_id)/create-external-sdk-tokens")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Payment Methods List
#
# GET /v2/payments/{id}/payment-methods
# operationId: Retrieve Payment methods for a Payment
export def "payments-payment-methods Retrieve-Payment-methods-for-a-Payment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment intent (e.g. pro_abcdefghijklmnop)
]: nothing -> record<payment_methods_enabled: table<payment_method_type: string, payment_method_subtype: string, payment_experience: list, required_fields: record, surcharge_details: record>, customer_payment_methods: table<payment_method_token: string, customer_id: string, payment_method_type: string, payment_method_subtype: string, recurring_enabled: bool, payment_method_data: record, bank: record, created: string, requires_cvv: bool, last_used_at: string, is_default: bool, billing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($id)/payment-methods")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - List
#
# GET /v2/payments/list
# operationId: List all Payments
export def "payments-list List-all-Payments" [
  payment_id: string
  profile_id: string
  customer_id: string
  starting_after: string
  ending_before: string
  limit: int
  offset: int
  created: string
  created.lt: string
  created.gt: string
  created.lte: string
  created.gte: string
  start_amount: int
  end_amount: int
  connector: list
  currency: list
  status: list
  payment_method_type: list
  payment_method_subtype: list
  authentication_type: list
  merchant_connector_id: list
  order_on: string
  order_by: string
  card_network: list
  merchant_order_reference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, total_count: int, data: table<id: string, merchant_id: string, profile_id: string, customer_id: string, payment_method_id: string, status: record, amount: record, created: string, payment_method_type: record, payment_method_subtype: record, connector: record, merchant_connector_id: string, customer: record, merchant_reference_id: string, connector_payment_id: string, connector_response_reference_id: string, metadata: record, description: string, authentication_type: record, capture_method: record, setup_future_usage: record, attempt_count: int, error: record, cancellation_reason: string, order_details: list, return_url: string, statement_descriptor: string, allowed_payment_method_types: list, authorization_count: int, modified_at: string, is_split_payment: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - Check Balance and Apply PM Data
#
# POST /v2/payments/{id}/eligibility/check-balance-and-apply-pm-data
# operationId: Apply Payment Method Data
export def "payments-eligibility-check-balance-and-apply-pm-data Apply-Payment-Method-Data" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment intent (e.g. pro_abcdefghijklmnop)
  payment_methods: list
]: any -> record<balances: table<payment_method_data: any, eligibility: any>, remaining_amount: int, currency: string, requires_additional_pm_data: bool, surcharge_details: table<payment_method_type: string, payment_method_subtype: string, surcharge_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payments/($id)/eligibility/check-balance-and-apply-pm-data")
  let body = {payment_methods: $payment_methods} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method - Create
#
# POST /v2/payment-methods
# operationId: Create Payment Method
export def "payment-methods Create-Payment-Method" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
  payment_method_type: string@payment-method-type-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-subtype: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  customer_id: string # The unique identifier of the customer. (e.g. 0a_cus_01926c58bc6e77c09e809964e72af8c8)
  payment_method_data: any
  --billing: any # nullable
  --network-tokenization: any # nullable
  storage_type: string@storage-type-completer
]: any -> record<id: string, merchant_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record, recurring_enabled: bool, created: string, last_used_at: string, payment_method_data: record, connector_tokens: table<token: string, connector_token_request_reference_id: string>, network_token: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, network_transaction_id: string, raw_payment_method_data: any, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, acknowledgement_status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payment-methods")
  let body = {payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype, metadata: $metadata, customer_id: $customer_id, payment_method_data: $payment_method_data, billing: $billing, network_tokenization: $network_tokenization, storage_type: $storage_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method - Create
#
# POST /v1/payment-methods
# operationId: Create Payment Method
export def "payment-methods Create-Payment-Method-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
  payment_method_type: string@payment-method-type-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-subtype: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  customer_id: string # The unique identifier of the customer. (e.g. 0a_cus_01926c58bc6e77c09e809964e72af8c8)
  payment_method_data: any
  --billing: any # nullable
  --network-tokenization: any # nullable
  storage_type: string@storage-type-completer
]: any -> record<id: string, merchant_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record, recurring_enabled: bool, created: string, last_used_at: string, payment_method_data: record, connector_tokens: table<token: string, connector_token_request_reference_id: string>, network_token: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, network_transaction_id: string, raw_payment_method_data: any, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, acknowledgement_status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payment-methods")
  let body = {payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype, metadata: $metadata, customer_id: $customer_id, payment_method_data: $payment_method_data, billing: $billing, network_tokenization: $network_tokenization, storage_type: $storage_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method - Create Intent
#
# POST /v2/payment-methods/create-intent
# operationId: Create Payment Method Intent
export def "payment-methods-create-intent Create-Payment-Method-Intent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --billing: any # nullable
  customer_id: string # The unique identifier of the customer. (e.g. 0a_cus_01926c58bc6e77c09e809964e72af8c8)
]: any -> record<id: string, merchant_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record, recurring_enabled: bool, created: string, last_used_at: string, payment_method_data: record, connector_tokens: table<token: string, connector_token_request_reference_id: string>, network_token: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, network_transaction_id: string, raw_payment_method_data: any, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, acknowledgement_status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-methods/create-intent")
  let body = {metadata: $metadata, billing: $billing, customer_id: $customer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method - Confirm Intent
#
# POST /v2/payment-methods/{id}/confirm-intent
# operationId: Confirm Payment Method Intent
export def "payment-methods-confirm-intent Confirm-Payment-Method-Intent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
  --customer-id: string # The unique identifier of the customer. (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  payment_method_data: any
  payment_method_type: string@payment-method-type-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  payment_method_subtype: string@payment-method-subtype-completer # Indicates the sub type of payment method. Eg: 'google_pay' & 'apple_pay' for wallets.
]: any -> record<id: string, merchant_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record, recurring_enabled: bool, created: string, last_used_at: string, payment_method_data: record, connector_tokens: table<token: string, connector_token_request_reference_id: string>, network_token: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, network_transaction_id: string, raw_payment_method_data: any, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, acknowledgement_status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-methods/($id)/confirm-intent")
  let body = {customer_id: $customer_id, payment_method_data: $payment_method_data, payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method - Update
#
# PUT /v2/payment-methods/{id}/update-saved-payment-method
# operationId: Update Payment Method
export def "payment-methods-update-saved-payment-method Update-Payment-Method-by-id" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
  --payment-method-data: any # nullable
  --connector-token-details: any # nullable
  --network-transaction-id: string # The network transaction ID provided by the card network during a Customer Initiated Transaction (CIT) when `setup_future_usage` is set to `off_session`. (nullable)
  --acknowledgement-status: any # nullable
]: any -> record<id: string, merchant_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record, recurring_enabled: bool, created: string, last_used_at: string, payment_method_data: record, connector_tokens: table<token: string, connector_token_request_reference_id: string>, network_token: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, network_transaction_id: string, raw_payment_method_data: any, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, acknowledgement_status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-methods/($id)/update-saved-payment-method")
  let body = {payment_method_data: $payment_method_data, connector_token_details: $connector_token_details, network_transaction_id: $network_transaction_id, acknowledgement_status: $acknowledgement_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method - Update
#
# PUT /v1/payment-methods/{id}/update-saved-payment-method
# operationId: Update Payment Method
export def "payment-methods-update-saved-payment-method Update-Payment-Method-by-id-1" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
  --payment-method-data: any # nullable
  --connector-token-details: any # nullable
  --network-transaction-id: string # The network transaction ID provided by the card network during a Customer Initiated Transaction (CIT) when `setup_future_usage` is set to `off_session`. (nullable)
  --acknowledgement-status: any # nullable
]: any -> record<id: string, merchant_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record, recurring_enabled: bool, created: string, last_used_at: string, payment_method_data: record, connector_tokens: table<token: string, connector_token_request_reference_id: string>, network_token: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, network_transaction_id: string, raw_payment_method_data: any, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, acknowledgement_status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-methods/($id)/update-saved-payment-method")
  let body = {payment_method_data: $payment_method_data, connector_token_details: $connector_token_details, network_transaction_id: $network_transaction_id, acknowledgement_status: $acknowledgement_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method - Retrieve
#
# GET /v2/payment-methods/{id}
# operationId: Retrieve Payment Method
export def "payment-methods Retrieve-Payment-Method-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, merchant_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record, recurring_enabled: bool, created: string, last_used_at: string, payment_method_data: record, connector_tokens: table<token: string, connector_token_request_reference_id: string>, network_token: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, network_transaction_id: string, raw_payment_method_data: any, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, acknowledgement_status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-methods/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Delete
#
# DELETE /v2/payment-methods/{id}
# operationId: Delete Payment Method
export def "payment-methods Delete-Payment-Method-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-methods/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/payment-methods/{id}
#
# operationId: Retrieve Payment Method
export def "payment-methods Retrieve-Payment-Method-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, merchant_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record, recurring_enabled: bool, created: string, last_used_at: string, payment_method_data: record, connector_tokens: table<token: string, connector_token_request_reference_id: string>, network_token: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, network_transaction_id: string, raw_payment_method_data: any, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, acknowledgement_status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-methods/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Delete
#
# DELETE /v1/payment-methods/{id}
# operationId: Delete Payment Method
export def "payment-methods Delete-Payment-Method-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-methods/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Check Network Token Status
#
# GET /v2/payment-methods/{payment_method_id}/check-network-token-status
# Discriminator (response): type
# operationId: Check Network Token Status
export def "payment-methods-check-network-token-status Check-Network-Token-Status" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-methods/($payment_method_id)/check-network-token-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - List Customer Saved Payment Methods
#
# GET /v2/customers/{id}/saved-payment-methods
# operationId: List Customer Saved Payment Methods
export def "customers-saved-payment-methods List-Customer-Saved-Payment-Methods-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
]: nothing -> record<customer_payment_methods: table<id: string, customer_id: string, payment_method_type: string, payment_method_subtype: string, recurring_enabled: bool, payment_method_data: record, created: string, requires_cvv: bool, last_used_at: string, is_default: bool, billing: record, network_tokenization: record, connector_tokens: list, network_transaction_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($id)/saved-payment-methods")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - List Customer Saved Payment Methods
#
# GET /v1/customers/{id}/saved-payment-methods
# operationId: List Customer Saved Payment Methods
export def "customers-saved-payment-methods List-Customer-Saved-Payment-Methods-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
]: nothing -> record<customer_payment_methods: table<id: string, customer_id: string, payment_method_type: string, payment_method_subtype: string, recurring_enabled: bool, payment_method_data: record, created: string, requires_cvv: bool, last_used_at: string, is_default: bool, billing: record, network_tokenization: record, connector_tokens: list, network_transaction_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($id)/saved-payment-methods")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Get Payment Method Token Data
#
# GET /v2/payment-methods/token/{payment_method_temporary_token}/details
# operationId: Get Payment Method Token Data
export def "payment-methods-token-details Get-Payment-Method-Token-Data-by-payment_method_temporary_token" [
  payment_method_temporary_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, payment_method_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-methods/token/($payment_method_temporary_token)/details")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Get Payment Method Token Data
#
# GET /v1/payment-methods/token/{payment_method_temporary_token}/details
# operationId: Get Payment Method Token Data
export def "payment-methods-token-details Get-Payment-Method-Token-Data-by-payment_method_temporary_token-1" [
  payment_method_temporary_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, payment_method_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-methods/token/($payment_method_temporary_token)/details")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Set Default Payment Method for Customer
#
# POST /v1/{customer_id}/payment-methods/{payment_method_id}/default
# operationId: Set the Payment Method as Default
export def "payment-methods-default Set-the-Payment-Method-as-Default" [
  customer_id: string
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<default_payment_method_id: string, customer_id: string, payment_method_type: string, payment_method_subtype: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($customer_id)/payment-methods/($payment_method_id)/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method Session - Create
#
# POST /v2/payment-method-sessions
# operationId: Create a payment method session
export def "payment-method-sessions Create-a-payment-method-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
  --customer-id: string # The customer id for which the payment methods session is to be created (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --billing: any # nullable
  --return-url: string # The return url to which the customer should be redirected to after adding the payment method (nullable)
  --network-tokenization: any # nullable
  --expires-in: int # The time (seconds ) when the session will expire If not provided, the session will expire in 15 minutes (nullable, format: int32, default: 900, e.g. 900)
  --tokenization-data: any # Contains data to be passed on to tokenization service ( if present ) to create token_id for given JSON data (nullable)
  storage_type: string@storage-type-completer
  --keep-alive: oneof<nothing, bool> # Whether the card with new status should be listed in the session (nullable)
]: any -> record<id: string, customer_id: string, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, network_tokenization: record<enable: string>, tokenization_data: any, expires_at: string, client_secret: string, return_url: string, next_action: record, authentication_details: record<status: string, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>>, associated_payment_methods: table<payment_method_token: any>, associated_token_id: string, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, payment_method_data: record, sdk_authorization: string, keep_alive: bool, network_tokenization_data: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, external_vault_details: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/payment-method-sessions")
  let body = {customer_id: $customer_id, billing: $billing, return_url: $return_url, network_tokenization: $network_tokenization, expires_in: $expires_in, tokenization_data: $tokenization_data, storage_type: $storage_type, keep_alive: $keep_alive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method Session - Create
#
# POST /v1/payment-method-sessions
# operationId: Create a payment method session
export def "payment-method-sessions Create-a-payment-method-session-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
  --customer-id: string # The customer id for which the payment methods session is to be created (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --billing: any # nullable
  --return-url: string # The return url to which the customer should be redirected to after adding the payment method (nullable)
  --network-tokenization: any # nullable
  --expires-in: int # The time (seconds ) when the session will expire If not provided, the session will expire in 15 minutes (nullable, format: int32, default: 900, e.g. 900)
  --tokenization-data: any # Contains data to be passed on to tokenization service ( if present ) to create token_id for given JSON data (nullable)
  storage_type: string@storage-type-completer
  --keep-alive: oneof<nothing, bool> # Whether the card with new status should be listed in the session (nullable)
]: any -> record<id: string, customer_id: string, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, network_tokenization: record<enable: string>, tokenization_data: any, expires_at: string, client_secret: string, return_url: string, next_action: record, authentication_details: record<status: string, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>>, associated_payment_methods: table<payment_method_token: any>, associated_token_id: string, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, payment_method_data: record, sdk_authorization: string, keep_alive: bool, network_tokenization_data: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, external_vault_details: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payment-method-sessions")
  let body = {customer_id: $customer_id, billing: $billing, return_url: $return_url, network_tokenization: $network_tokenization, expires_in: $expires_in, tokenization_data: $tokenization_data, storage_type: $storage_type, keep_alive: $keep_alive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method Session - Retrieve
#
# GET /v2/payment-method-sessions/{id}
# operationId: Retrieve the payment method session
export def "payment-method-sessions Retrieve-the-payment-method-session-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, customer_id: string, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, network_tokenization: record<enable: string>, tokenization_data: any, expires_at: string, client_secret: string, return_url: string, next_action: record, authentication_details: record<status: string, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>>, associated_payment_methods: table<payment_method_token: any>, associated_token_id: string, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, payment_method_data: record, sdk_authorization: string, keep_alive: bool, network_tokenization_data: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, external_vault_details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-method-sessions/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method Session - Delete a saved payment method
#
# DELETE /v2/payment-method-sessions/{id}
# operationId: Delete a saved payment method
export def "payment-method-sessions Delete-a-saved-payment-method-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
  payment_method_token: string # The payment method token associated with the payment method to be deleted (e.g. token_9wcXDRVkfEtLEsSnYKgQ)
]: any -> record<payment_method_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-method-sessions/($id)")
  let body = {payment_method_token: $payment_method_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method Session - Retrieve
#
# GET /v1/payment-method-sessions/{id}
# operationId: Retrieve the payment method session
export def "payment-method-sessions Retrieve-the-payment-method-session-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
]: nothing -> record<id: string, customer_id: string, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, network_tokenization: record<enable: string>, tokenization_data: any, expires_at: string, client_secret: string, return_url: string, next_action: record, authentication_details: record<status: string, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>>, associated_payment_methods: table<payment_method_token: any>, associated_token_id: string, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, payment_method_data: record, sdk_authorization: string, keep_alive: bool, network_tokenization_data: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, external_vault_details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-method-sessions/($id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method Session - Delete a saved payment method
#
# DELETE /v1/payment-method-sessions/{id}
# operationId: Delete a saved payment method
export def "payment-method-sessions Delete-a-saved-payment-method-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
  payment_method_token: string # The payment method token associated with the payment method to be deleted (e.g. token_9wcXDRVkfEtLEsSnYKgQ)
]: any -> record<payment_method_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-method-sessions/($id)")
  let body = {payment_method_token: $payment_method_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method Session - List Payment Methods
#
# GET /v2/payment-method-sessions/{id}/list-payment-methods
# operationId: List Payment methods for a Payment Method Session
export def "payment-method-sessions-list-payment-methods List-Payment-methods-for-a-Payment-Method-Session-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
]: nothing -> record<payment_methods_enabled: table<payment_method_type: string, payment_method_subtype: string, required_fields: list>, customer_payment_methods: table<payment_method_token: string, customer_id: string, payment_method_type: string, payment_method_subtype: string, recurring_enabled: bool, payment_method_data: record, bank: record, created: string, requires_cvv: bool, last_used_at: string, is_default: bool, billing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-method-sessions/($id)/list-payment-methods")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method Session - List Payment Methods
#
# GET /v1/payment-method-sessions/{id}/list-payment-methods
# operationId: List Payment methods for a Payment Method Session
export def "payment-method-sessions-list-payment-methods List-Payment-methods-for-a-Payment-Method-Session-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
]: nothing -> record<payment_methods_enabled: table<payment_method_type: string, payment_method_subtype: string, required_fields: list>, customer_payment_methods: table<payment_method_token: string, customer_id: string, payment_method_type: string, payment_method_subtype: string, recurring_enabled: bool, payment_method_data: record, bank: record, created: string, requires_cvv: bool, last_used_at: string, is_default: bool, billing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-method-sessions/($id)/list-payment-methods")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method Session - Update a saved payment method
#
# PUT /v2/payment-method-sessions/{id}/update-saved-payment-method
# operationId: Update a saved payment method
export def "payment-method-sessions-update-saved-payment-method Update-a-saved-payment-method-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
  --payment-method-data: any # nullable
  --connector-token-details: any # nullable
  --network-transaction-id: string # The network transaction ID provided by the card network during a Customer Initiated Transaction (CIT) when `setup_future_usage` is set to `off_session`. (nullable)
  --acknowledgement-status: any # nullable
  --payment-method-token: string # The payment method token associated with the payment method session. If not provided, a new token will be generated. (nullable, e.g. token_9wcXDRVkfEtLEsSnYKgQ)
]: any -> record<id: string, customer_id: string, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, network_tokenization: record<enable: string>, tokenization_data: any, expires_at: string, client_secret: string, return_url: string, next_action: record, authentication_details: record<status: string, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>>, associated_payment_methods: table<payment_method_token: any>, associated_token_id: string, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, payment_method_data: record, sdk_authorization: string, keep_alive: bool, network_tokenization_data: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, external_vault_details: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-method-sessions/($id)/update-saved-payment-method")
  let body = {payment_method_data: $payment_method_data, connector_token_details: $connector_token_details, network_transaction_id: $network_transaction_id, acknowledgement_status: $acknowledgement_status, payment_method_token: $payment_method_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method Session - Update a saved payment method
#
# PUT /v1/payment-method-sessions/{id}/update-saved-payment-method
# operationId: Update a saved payment method
export def "payment-method-sessions-update-saved-payment-method Update-a-saved-payment-method-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment method session (e.g. pro_abcdefghijklmnop)
  --payment-method-data: any # nullable
  --connector-token-details: any # nullable
  --network-transaction-id: string # The network transaction ID provided by the card network during a Customer Initiated Transaction (CIT) when `setup_future_usage` is set to `off_session`. (nullable)
  --acknowledgement-status: any # nullable
  --payment-method-token: string # The payment method token associated with the payment method session. If not provided, a new token will be generated. (nullable, e.g. token_9wcXDRVkfEtLEsSnYKgQ)
]: any -> record<id: string, customer_id: string, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, network_tokenization: record<enable: string>, tokenization_data: any, expires_at: string, client_secret: string, return_url: string, next_action: record, authentication_details: record<status: string, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>>, associated_payment_methods: table<payment_method_token: any>, associated_token_id: string, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, payment_method_data: record, sdk_authorization: string, keep_alive: bool, network_tokenization_data: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, external_vault_details: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-method-sessions/($id)/update-saved-payment-method")
  let body = {payment_method_data: $payment_method_data, connector_token_details: $connector_token_details, network_transaction_id: $network_transaction_id, acknowledgement_status: $acknowledgement_status, payment_method_token: $payment_method_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method Session - Confirm a payment method session
#
# POST /v2/payment-method-sessions/{id}/confirm
# operationId: Confirm the payment method session
export def "payment-method-sessions-confirm Confirm-the-payment-method-session-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment intent (e.g. pro_abcdefghijklmnop)
  payment_method_type: string@payment-method-type-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-subtype: any # nullable
  payment_method_data: any # The payment method information provided for making a payment
  --return-url: string # The return url to which the customer should be redirected to after adding the payment method (nullable)
  --customer-acceptance: any # nullable
]: any -> record<id: string, customer_id: string, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, network_tokenization: record<enable: string>, tokenization_data: any, expires_at: string, client_secret: string, return_url: string, next_action: record, authentication_details: record<status: string, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>>, associated_payment_methods: table<payment_method_token: any>, associated_token_id: string, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, payment_method_data: record, sdk_authorization: string, keep_alive: bool, network_tokenization_data: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, external_vault_details: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payment-method-sessions/($id)/confirm")
  let body = {payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype, payment_method_data: $payment_method_data, return_url: $return_url, customer_acceptance: $customer_acceptance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payment Method Session - Confirm a payment method session
#
# POST /v1/payment-method-sessions/{id}/confirm
# operationId: Confirm the payment method session
export def "payment-method-sessions-confirm Confirm-the-payment-method-session-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID associated to the payment intent (e.g. pro_abcdefghijklmnop)
  payment_method_type: string@payment-method-type-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-subtype: any # nullable
  payment_method_data: any # The payment method information provided for making a payment
  --return-url: string # The return url to which the customer should be redirected to after adding the payment method (nullable)
  --customer-acceptance: any # nullable
]: any -> record<id: string, customer_id: string, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, network_tokenization: record<enable: string>, tokenization_data: any, expires_at: string, client_secret: string, return_url: string, next_action: record, authentication_details: record<status: string, error: record<code: string, message: string, reason: string, unified_code: string, unified_message: string, network_advice_code: string, network_decline_code: string, network_error_message: string>>, associated_payment_methods: table<payment_method_token: any>, associated_token_id: string, storage_type: string, card_cvc_token_storage: record<is_stored: bool, expires_at: string>, payment_method_data: record, sdk_authorization: string, keep_alive: bool, network_tokenization_data: record<payment_method_data: record<last4_digits: string, issuer_country: record, network_token_expiry_month: string, network_token_expiry_year: string, nick_name: string, card_holder_name: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, saved_to_locker: bool, par: string>>, external_vault_details: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payment-method-sessions/($id)/confirm")
  let body = {payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype, payment_method_data: $payment_method_data, return_url: $return_url, customer_acceptance: $customer_acceptance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refunds - Create
#
# POST /v2/refunds
# operationId: Create a Refund
export def "refunds Create-a-Refund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_id: string # The payment id against which refund is initiated (e.g. pay_mbabizu24mvu3mela5njyhpit4)
  merchant_reference_id: string # Unique Identifier for the Refund given by the Merchant. (e.g. ref_mbabizu24mvu3mela5njyhpit4)
  --merchant-id: string # The identifier for the Merchant Account (nullable, e.g. y3oqhf46pyzuxjbcn2giaqnb44)
  --amount: int # Total amount for which the refund is to be initiated. Amount for the payment in lowest denomination of the currency. (i.e) in cents for USD denomination, in paisa for INR denomination etc., If not provided, this will default to the amount_captured of the payment (nullable, format: int64, e.g. 6540)
  --reason: string # Reason for the refund. Often useful for displaying to users and your customer support executive. (nullable, e.g. Customer returned the product)
  --refund-type: any # nullable, default: Instant
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --merchant-connector-details: any # nullable
  --return-raw-connector-response: oneof<nothing, bool> # If true, returns stringified connector raw response body (nullable)
]: any -> record<id: string, payment_id: string, merchant_reference_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_details: record<code: string, message: string>, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, connector_refund_reference_id: string, raw_connector_response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/refunds")
  let body = {payment_id: $payment_id, merchant_reference_id: $merchant_reference_id, merchant_id: $merchant_id, amount: $amount, reason: $reason, refund_type: $refund_type, metadata: $metadata, merchant_connector_details: $merchant_connector_details, return_raw_connector_response: $return_raw_connector_response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refunds - Metadata Update
#
# PUT /v2/refunds/{id}/update-metadata
# operationId: Update Refund Metadata and Reason
export def "refunds-update-metadata Update-Refund-Metadata-and-Reason" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # An arbitrary string attached to the object. Often useful for displaying to users and your customer support executive (nullable, e.g. Customer returned the product)
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
]: any -> record<id: string, payment_id: string, merchant_reference_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_details: record<code: string, message: string>, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, connector_refund_reference_id: string, raw_connector_response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/refunds/($id)/update-metadata")
  let body = {reason: $reason, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refunds - Retrieve
#
# GET /v2/refunds/{id}
# operationId: Retrieve a Refund
export def "refunds Retrieve-a-Refund" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, payment_id: string, merchant_reference_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_details: record<code: string, message: string>, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, connector_refund_reference_id: string, raw_connector_response: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/refunds/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refunds - List
#
# POST /v2/refunds/list
# operationId: List all Refunds
export def "refunds-list List-all-Refunds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment-id: string # The identifier for the payment (nullable)
  refund_id: string # The identifier for the refund
  --limit: int # Limit on the number of objects to return (nullable, format: int64)
  --offset: int # The starting point within a list of objects (nullable, format: int64)
  --amount-filter: any # nullable
  --connector: list # The list of connectors to filter refunds list (nullable)
  --connector-id-list: list # The list of merchant connector ids to filter the refunds list for selected label (nullable)
  --currency: list # The list of currencies to filter refunds list (nullable)
  --refund-status: list # The list of refund statuses to filter refunds list (nullable)
]: any -> record<count: int, total_count: int, data: table<id: string, payment_id: string, merchant_reference_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_details: record, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, connector_refund_reference_id: string, raw_connector_response: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/refunds/list")
  let body = {payment_id: $payment_id, refund_id: $refund_id, limit: $limit, offset: $offset, amount_filter: $amount_filter, connector: $connector, connector_id_list: $connector_id_list, currency: $currency, refund_status: $refund_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revenue Recovery - Retrieve
#
# GET /v2/process-trackers/revenue-recovery-workflow/{revenue_recovery_id}
# operationId: Retrieve Revenue Recovery Info
export def "process-trackers-revenue-recovery-workflow Retrieve-Revenue-Recovery-Info" [
  recovery_recovery_id: string
  revenue_recovery_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, schedule_time_for_payment: string, schedule_time_for_psync: string, status: string, business_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/process-trackers/revenue-recovery-workflow/($revenue_recovery_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Proxy
#
# POST /v2/proxy
# operationId: Proxy Request
export def "proxy Proxy-Request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  request_body: any # The request body that needs to be forwarded
  destination_url: string # The destination URL where the request needs to be forwarded (e.g. https://api.example.com/endpoint)
  headers: record # The headers that need to be forwarded
  method: string@method-completer
  --body-token: string # The vault token that is used to fetch sensitive data from the vault
  token_type: string@token-type-completer
]: any -> record<response: any, status_code: int, response_headers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/proxy")
  let body = {request_body: $request_body, destination_url: $destination_url, headers: $headers, method: $method, token: $body_token, token_type: $token_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Proxy
#
# POST /v1/proxy
# operationId: Proxy Request
export def "proxy Proxy-Request-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  request_body: any # The request body that needs to be forwarded
  destination_url: string # The destination URL where the request needs to be forwarded (e.g. https://api.example.com/endpoint)
  headers: record # The headers that need to be forwarded
  method: string@method-completer
  --body-token: string # The vault token that is used to fetch sensitive data from the vault
  token_type: string@token-type-completer
]: any -> record<response: any, status_code: int, response_headers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/proxy")
  let body = {request_body: $request_body, destination_url: $destination_url, headers: $headers, method: $method, token: $body_token, token_type: $token_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Tokenization - Create
#
# POST /v2/tokenize
# operationId: create_token_vault_api
export def "tokenize api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer_id: string # Customer ID for which the tokenization is requested (e.g. 0a_cus_01926c58bc6e77c09e809964e72af8c8)
  token_request: record # Request for tokenization which contains the data to be tokenized
]: any -> record<id: string, created_at: string, flag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tokenize")
  let body = {customer_id: $customer_id, token_request: $token_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Tokenization - Delete
#
# DELETE /v2/tokenize/{id}
# operationId: delete_tokenized_data_api
export def "tokenize api-by-id" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer_id: string # Customer ID for which the tokenization is requested (e.g. 0a_cus_01926c58bc6e77c09e809964e72af8c8)
  session_id: string # Session ID associated with the tokenization request (e.g. 0a_pms_01926c58bc6e77c09e809964e72af8c8)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tokenize/($id)")
  let body = {customer_id: $customer_id, session_id: $session_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
