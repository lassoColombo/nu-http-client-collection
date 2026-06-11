# Auto-generated client for Hyperswitch - API Documentation v0.1.0
# Source: https://raw.githubusercontent.com/juspay/hyperswitch/main/api-reference/v1/openapi_spec_v1.json
# Auth: --token flag or $env.HYPERSWITCH_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://sandbox.hyperswitch.io"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HYPERSWITCH_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {api-key: $token_val}, query: ""} }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://sandbox.hyperswitch.io"] }
def auth-scheme-completer [] { ["api-key" "bearer"] }

# Completers for enum parameters
def currency-completer [] { ["AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BZD" "CAD" "CDF" "CHF" "CLF" "CLP" "CNY" "COP" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "IQD" "IRR" "ISK" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRU" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLE" "SLL" "SOS" "SRD" "SSP" "STD" "STN" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VES" "VND" "VUV" "WST" "XAF" "XCD" "XOF" "XPF" "YER" "ZAR" "ZMW" "ZWL"] }
def device-channel-completer [] { ["APP" "BRW"] }
def threeds-method-comp-ind-completer [] { ["N" "U" "Y"] }
def payment-method-type-completer [] { ["ach" "affirm" "afterpay_clearpay" "alfamart" "ali_pay" "ali_pay_hk" "alma" "amazon_pay" "apple_pay" "atome" "bacs" "bancontact_card" "bca_bank_transfer" "becs" "benefit" "bhn_card_network" "bizum" "blik" "bluecode" "bni_va" "boleto" "breadpay" "bri_va" "card_redirect" "cashapp" "cimb_va" "classic" "credit" "crypto_currency" "dana" "danamon_va" "debit" "direct_carrier_billing" "duit_now" "efecty" "eft" "eft_debit_order" "eps" "evoucher" "family_mart" "flexiti" "fps" "gcash" "giropay" "givex" "go_pay" "google_pay" "ideal" "indomaret" "indonesian_bank_transfer" "instant_bank_transfer" "instant_bank_transfer_finland" "instant_bank_transfer_poland" "interac" "kakao_pay" "klarna" "knet" "lawson" "local_bank_redirect" "local_bank_transfer" "mandiri_va" "mb_way" "mifinity" "mini_stop" "mobile_pay" "momo" "momo_atm" "multibanco" "network_token" "online_banking_czech_republic" "online_banking_finland" "online_banking_fpx" "online_banking_poland" "online_banking_slovakia" "online_banking_thailand" "open_banking" "open_banking_pis" "open_banking_uk" "oxxo" "pago_efectivo" "pay_bright" "pay_easy" "pay_safe_card" "payjustnow" "paypal" "paysera" "paze" "permata_bank_transfer" "pix" "pix_automatico_push" "pix_automatico_qr" "pix_emv" "pix_key" "prompt_pay" "przelewy24" "pse" "qris" "red_compra" "red_pagos" "revolut_pay" "samsung_pay" "seicomart" "sepa" "sepa_bank_transfer" "sepa_guarenteed_debit" "seven_eleven" "skrill" "sofort" "swish" "touch_n_go" "trustly" "twint" "upi_collect" "upi_intent" "upi_qr" "venmo" "viet_qr" "vipps" "walley" "we_chat_pay"] }
def payment-method-completer [] { ["bank_debit" "bank_redirect" "bank_transfer" "card" "card_redirect" "crypto" "gift_card" "mobile_payment" "network_token" "open_banking" "pay_later" "real_time_payment" "reward" "upi" "voucher" "wallet"] }
def payment-method-type-completer-1 [] { ["bank_debit" "bank_redirect" "bank_transfer" "card" "card_redirect" "crypto" "gift_card" "mobile_payment" "network_token" "open_banking" "pay_later" "real_time_payment" "reward" "upi" "voucher" "wallet"] }
def type-completer [] { ["capture" "incremental_authorization" "refund" "unreferenced_refund" "void"] }
def connector-type-completer [] { ["authentication_processor" "banking_entities" "billing_processor" "fin_operations" "fiz_operations" "networks" "non_banking_finance" "payment_method_auth" "payment_processor" "payment_vas" "payout_processor" "surcharge_processor" "tax_processor" "vault_processor"] }
def connector-name-completer [] { ["absa_sanlam" "aci" "adyen" "adyen_test" "adyenplatform" "affirm" "airwallex" "amazonpay" "archipel" "authipay" "authorizedotnet" "bambora" "bamboraapac" "bankofamerica" "barclaycard" "billwerk" "bitpay" "blackhawknetwork" "bluesnap" "boku" "braintree" "breadpay" "calida" "cardinal" "cashtocode" "celero" "chargebee" "checkbook" "checkout" "checkout_test" "coinbase" "coingate" "cryptopay" "ctp_mastercard" "ctp_visa" "custombilling" "cybersource" "cybersourcedecisionmanager" "datatrans" "deutschebank" "digitalvirgo" "dlocal" "dwolla" "ebanx" "elavon" "envoy" "facilitapay" "fauxpay" "finix" "fiserv" "fiservcommercehub" "fiservemea" "fiuu" "flexiti" "forte" "getnet" "gigadat" "globalpay" "globepay" "gocardless" "gpayments" "helcim" "hipay" "hyperpg" "hyperswitch_vault" "iatapay" "imerchantsolutions" "inespay" "interpayments" "itaubank" "jpmorgan" "juspaythreedsserver" "klarna" "loonio" "mifinity" "mollie" "moneris" "multisafepay" "netcetera" "nexinets" "nexixpay" "nmi" "nomupay" "noon" "nordea" "novalnet" "nuvei" "opennode" "paybox" "payconex" "payjustnow" "payjustnowinstore" "payload" "payme" "payone" "paypal" "paypal_test" "paysafe" "paystack" "paytm" "payu" "peachpayments" "phonepe" "phonypay" "placetopay" "plaid" "powertranz" "pretendpay" "prophetpay" "rapyd" "razorpay" "recurly" "redsys" "revolv3" "riskified" "santander" "shift4" "signifyd" "silverflow" "square" "stax" "stripe" "stripe_billing_test" "stripe_test" "stripebilling" "taxjar" "tesouro" "threedsecureio" "tokenex" "tokenio" "truelayer" "trustly" "trustpay" "trustpayments" "tsys" "vgs" "volt" "wellsfargo" "wise" "worldline" "worldpay" "worldpaymodular" "worldpayvantiv" "worldpayxml" "xendit" "zen" "zift" "zsl"] }
def status-completer [] { ["active" "inactive"] }
def connector-completer [] { ["absa_sanlam" "aci" "adyen" "adyen_test" "adyenplatform" "affirm" "airwallex" "amazonpay" "archipel" "authipay" "authorizedotnet" "bambora" "bamboraapac" "bankofamerica" "barclaycard" "billwerk" "bitpay" "blackhawknetwork" "bluesnap" "boku" "braintree" "breadpay" "calida" "cardinal" "cashtocode" "celero" "chargebee" "checkbook" "checkout" "checkout_test" "coinbase" "coingate" "cryptopay" "ctp_mastercard" "ctp_visa" "custombilling" "cybersource" "cybersourcedecisionmanager" "datatrans" "deutschebank" "digitalvirgo" "dlocal" "dwolla" "ebanx" "elavon" "envoy" "facilitapay" "fauxpay" "finix" "fiserv" "fiservcommercehub" "fiservemea" "fiuu" "flexiti" "forte" "getnet" "gigadat" "globalpay" "globepay" "gocardless" "gpayments" "helcim" "hipay" "hyperpg" "hyperswitch_vault" "iatapay" "imerchantsolutions" "inespay" "interpayments" "itaubank" "jpmorgan" "juspaythreedsserver" "klarna" "loonio" "mifinity" "mollie" "moneris" "multisafepay" "netcetera" "nexinets" "nexixpay" "nmi" "nomupay" "noon" "nordea" "novalnet" "nuvei" "opennode" "paybox" "payconex" "payjustnow" "payjustnowinstore" "payload" "payme" "payone" "paypal" "paypal_test" "paysafe" "paystack" "paytm" "payu" "peachpayments" "phonepe" "phonypay" "placetopay" "plaid" "powertranz" "pretendpay" "prophetpay" "rapyd" "razorpay" "recurly" "redsys" "revolv3" "riskified" "santander" "shift4" "signifyd" "silverflow" "square" "stax" "stripe" "stripe_billing_test" "stripe_test" "stripebilling" "taxjar" "tesouro" "threedsecureio" "tokenex" "tokenio" "truelayer" "trustly" "trustpay" "trustpayments" "tsys" "vgs" "volt" "wellsfargo" "wise" "worldline" "worldpay" "worldpaymodular" "worldpayvantiv" "worldpayxml" "xendit" "zen" "zift" "zsl"] }
def decision-completer [] { ["do_default" "retry"] }
def enable-completer [] { ["dynamic_connector_selection" "metrics" "none"] }
def status-completer-1 [] { ["AUTHENTICATION_FAILED" "AUTHORIZATION_FAILED" "AUTHORIZED" "AUTHORIZING" "AUTO_REFUNDED" "CAPTURE_FAILED" "CAPTURE_INITIATED" "CHARGED" "C_O_D_INITIATED" "DECLINED" "FAILURE" "JUSPAY_DECLINED" "NOP" "PARTIAL_CHARGED" "PENDING" "PENDING_VBV" "STARTED" "TO_BE_CHARGED" "VOIDED" "VOIDED_POST_CHARGE" "VOID_FAILED" "VOID_INITIATED" "V_B_V_SUCCESSFUL"] }
def type-completer-1 [] { ["card_bin"] }
def data-kind-completer [] { ["card_bin" "extended_card_bin" "payment_method"] }
def entity-type-completer [] { ["Company" "Individual" "NaturalPerson" "NonProfit" "Personal" "PublicSector" "lowercase"] }
def item-type-completer [] { ["addon" "plan"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payments Create-a-Payment" } } | get name | first)
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

# Payments - Create
#
# POST /payments
# operationId: Create a Payment
# --order_details item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
# --installment_options item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", installments: list}
@deprecated --flag statement-descriptor-name
@deprecated --flag statement-descriptor-suffix
@deprecated --flag mandate-id
@deprecated --flag business-label
export def "payments Create-a-Payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # The primary amount for the payment, provided in the lowest denomination of the specified currency (e.g., 6540 for $65.40 USD). This field is mandatory for creating a payment. (format: int64)
  --order-tax-amount: int # Total tax amount applicable to the order, in the lowest denomination of the currency. (nullable, format: int64, e.g. 6540)
  currency: string@currency-completer # The three-letter ISO 4217 currency code (e.g., "USD", "EUR") for the payment amount. This field is mandatory for creating a payment.
  --amount-to-capture: int # The amount to be captured from the user's payment method, in the lowest denomination. If not provided, and `capture_method` is `automatic`, the full payment `amount` will be captured. If `capture_method` is `manual`, this can be specified in the `/capture` call. Must be less than or equal to the authorized amount. (nullable, format: int64, e.g. 6540)
  --shipping-cost: int # The shipping cost for the payment. This is required for tax calculation in some regions. (nullable, format: int64, e.g. 6540)
  --payment-id: string # Optional. A merchant-provided unique identifier for the payment, contains 30 characters long (e.g., "pay_mbabizu24mvu3mela5njyhpit4"). If provided, it ensures idempotency for the payment creation request. If omitted, Hyperswitch generates a unique ID for the payment. (nullable, e.g. pay_mbabizu24mvu3mela5njyhpit4)
  --routing: any # nullable
  --connector: list # This allows to manually select a connector with which the payment can go through. (nullable, e.g. [stripe, adyen])
  --capture-method: any # nullable
  --authentication-type: any # nullable, default: three_ds
  --billing: any # nullable
  --confirm: string@bool-completer # If set to `true`, Hyperswitch attempts to confirm and authorize the payment immediately after creation, provided sufficient payment method details are included. If `false` or omitted (default is `false`), the payment is created with a status such as `requires_payment_method` or `requires_confirmation`, and a separate `POST /payments/{payment_id}/confirm` call is necessary to proceed with authorization. (nullable, default: false, e.g. true)
  --customer: any # nullable
  --customer-id: string # The identifier for the customer (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --off-session: string@bool-completer # Set to true to indicate that the customer is not in your checkout flow during this payment, and therefore is unable to authenticate. This parameter is intended for scenarios where you collect card details and charge them later. When making a recurring payment by passing a mandate_id, this parameter is mandatory (nullable, e.g. true)
  --description: string # An arbitrary string attached to the payment. Often useful for displaying to users or for your own internal record-keeping. (nullable, e.g. It's my first payment request)
  --return-url: string # The URL to redirect the customer to after they complete the payment process or authentication. This is crucial for flows that involve off-site redirection (e.g., 3DS, some bank redirects, wallet payments). (nullable, e.g. https://hyperswitch.io)
  --setup-future-usage: any # nullable
  --payment-method-data: any # nullable
  --payment-method: any # nullable
  --payment-token: string # As Hyperswitch tokenises the sensitive details about the payments method, it provides the payment_token as a reference to a stored payment method, ensuring that the sensitive details are not exposed in any manner. (nullable, e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
  --shipping: any # nullable
  --statement-descriptor-name: string # For non-card charges, you can use this value as the complete description that appears on your customers’ statements. Must contain at least one letter, maximum 22 characters. To be deprecated soon, use billing_descriptor instead. (DEPRECATED, nullable, e.g. Hyperswitch Router)
  --statement-descriptor-suffix: string # Provides information about a card payment that customers see on their statements. Concatenated with the prefix (shortened descriptor) or statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters for the concatenated descriptor. To be deprecated soon, use billing_descriptor instead. (DEPRECATED, nullable, e.g. Payment for shoes purchase)
  --order-details: list # Use this object to capture the details about the different products for which the payment is being made. The sum of amount across different products here should be equal to the overall payment amount (nullable, e.g. [{         "product_name": "Apple iPhone 16",         "quantity": 1,         "amount" : 69000         "product_img_link" : "https://dummy-img-link.com"     }]) — item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
  --mandate-data: any # nullable
  --customer-acceptance: any # nullable
  --mandate-id: string # A unique identifier to link the payment to a mandate. To do Recurring payments after a mandate has been created, pass the mandate_id instead of payment_method_data (DEPRECATED, nullable, e.g. mandate_iwer89rnjef349dni3)
  --browser-info: any # nullable
  --payment-experience: any # nullable
  --payment-method-type: any # nullable
  --business-country: any # nullable
  --business-label: string # Business label of the merchant for this payment. To be deprecated soon. Pass the profile_id instead (DEPRECATED, nullable, e.g. food)
  --merchant-connector-details: any # nullable
  --allowed-payment-method-types: list # Use this parameter to restrict the Payment Method Types to show for a given PaymentIntent (nullable)
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --connector-metadata: any # nullable
  --payment-link: string@bool-completer # Whether to generate the payment link for this payment or not (if applicable) (nullable, default: false, e.g. true)
  --payment-link-config: any # nullable
  --payment-link-config-id: string # Custom payment link config id set at business profile, send only if business_specific_configs is configured (nullable)
  --profile-id: string # The business profile to be used for this payment, if not passed the default business profile associated with the merchant account will be used. It is mandatory in case multiple business profiles have been set up. (nullable)
  --surcharge-details: any # nullable
  --payment-type: any # nullable
  --request-incremental-authorization: string@bool-completer # Request an incremental authorization, i.e., increase the authorized amount on a confirmed payment before you capture it. (nullable)
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds (900) for 15 mins (nullable, format: int32, e.g. 900)
  --frm-metadata: record # Additional data related to some frm(Fraud Risk Management) connectors (nullable)
  --request-external-three-ds-authentication: string@bool-completer # Whether to perform external authentication (if applicable) (nullable, e.g. true)
  --three-ds-data: any # nullable
  --recurring-details: any # nullable
  --split-payments: any # nullable
  --request-extended-authorization: string@bool-completer # Optional boolean value to extent authorization period of this payment  capture method must be manual or manual_multiple (nullable, default: false)
  --merchant-order-reference-id: string # Your unique identifier for this payment or order. This ID helps you reconcile payments on your system. If provided, it is passed to the connector if supported. (nullable, e.g. Custom_Order_id_123)
  --skip-external-tax-calculation: string@bool-completer # Whether to calculate tax for this payment intent (nullable)
  --psd2-sca-exemption-type: any # nullable
  --ctp-service-details: any # nullable
  --force-3ds-challenge: string@bool-completer # Indicates if 3ds challenge is forced (nullable)
  --threeds-method-comp-ind: any # nullable
  --is-iframe-redirection-enabled: string@bool-completer # Indicates if the redirection has to open in the iframe (nullable)
  --all-keys-required: string@bool-completer # If enabled, provides whole connector response (nullable)
  --payment-channel: any # nullable
  --tax-status: any # nullable
  --discount-amount: int # Total amount of the discount you have applied to the order or transaction. (nullable, format: int64, e.g. 6540)
  --shipping-amount-tax: any # nullable
  --duty-amount: any # nullable
  --order-date: string # Date the payer placed the order. (nullable, format: date-time)
  --enable-partial-authorization: string@bool-completer # Allow partial authorization for this payment (nullable, default: false)
  --enable-overcapture: string@bool-completer # Boolean indicating whether to enable overcapture for this payment (nullable, e.g. true)
  --is-stored-credential: string@bool-completer # Boolean flag indicating whether this payment method is stored and has been previously used for payments (nullable, e.g. true)
  --mit-category: any # nullable
  --billing-descriptor: any # nullable
  --tokenization: any # nullable
  --partner-merchant-identifier-details: any # nullable
  --installment-options: list # Installment payment options grouped by payment method. When provided, the payment is treated as an installment payment. (nullable) — item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", installments: list}
  --installment-data: any # nullable
  --profile-acquirer-id: string # Identification for the profile acquirer to be used for this payment. (nullable)
  --external-surcharge-strategy: any # nullable
]: any -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments")
  let body = {amount: $amount, order_tax_amount: $order_tax_amount, currency: $currency, amount_to_capture: $amount_to_capture, shipping_cost: $shipping_cost, payment_id: $payment_id, routing: $routing, connector: $connector, capture_method: $capture_method, authentication_type: $authentication_type, billing: $billing, confirm: $confirm, customer: $customer, customer_id: $customer_id, off_session: $off_session, description: $description, return_url: $return_url, setup_future_usage: $setup_future_usage, payment_method_data: $payment_method_data, payment_method: $payment_method, payment_token: $payment_token, shipping: $shipping, statement_descriptor_name: $statement_descriptor_name, statement_descriptor_suffix: $statement_descriptor_suffix, order_details: $order_details, mandate_data: $mandate_data, customer_acceptance: $customer_acceptance, mandate_id: $mandate_id, browser_info: $browser_info, payment_experience: $payment_experience, payment_method_type: $payment_method_type, business_country: $business_country, business_label: $business_label, merchant_connector_details: $merchant_connector_details, allowed_payment_method_types: $allowed_payment_method_types, metadata: $metadata, connector_metadata: $connector_metadata, payment_link: $payment_link, payment_link_config: $payment_link_config, payment_link_config_id: $payment_link_config_id, profile_id: $profile_id, surcharge_details: $surcharge_details, payment_type: $payment_type, request_incremental_authorization: $request_incremental_authorization, session_expiry: $session_expiry, frm_metadata: $frm_metadata, request_external_three_ds_authentication: $request_external_three_ds_authentication, three_ds_data: $three_ds_data, recurring_details: $recurring_details, split_payments: $split_payments, request_extended_authorization: $request_extended_authorization, merchant_order_reference_id: $merchant_order_reference_id, skip_external_tax_calculation: $skip_external_tax_calculation, psd2_sca_exemption_type: $psd2_sca_exemption_type, ctp_service_details: $ctp_service_details, force_3ds_challenge: $force_3ds_challenge, threeds_method_comp_ind: $threeds_method_comp_ind, is_iframe_redirection_enabled: $is_iframe_redirection_enabled, all_keys_required: $all_keys_required, payment_channel: $payment_channel, tax_status: $tax_status, discount_amount: $discount_amount, shipping_amount_tax: $shipping_amount_tax, duty_amount: $duty_amount, order_date: $order_date, enable_partial_authorization: $enable_partial_authorization, enable_overcapture: $enable_overcapture, is_stored_credential: $is_stored_credential, mit_category: $mit_category, billing_descriptor: $billing_descriptor, tokenization: $tokenization, partner_merchant_identifier_details: $partner_merchant_identifier_details, installment_options: $installment_options, installment_data: $installment_data, profile_acquirer_id: $profile_acquirer_id, external_surcharge_strategy: $external_surcharge_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Update
#
# POST /payments/{payment_id}
# operationId: Update a Payment
# --order_details item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
# --installment_options item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", installments: list}
@deprecated --flag statement-descriptor-name
@deprecated --flag statement-descriptor-suffix
export def "payments Update-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amount: int # The primary amount for the payment, provided in the lowest denomination of the specified currency (e.g., 6540 for $65.40 USD). This field is mandatory for creating a payment. (nullable, format: int64, e.g. 6540)
  --order-tax-amount: int # Total tax amount applicable to the order, in the lowest denomination of the currency. (nullable, format: int64, e.g. 6540)
  --currency: any # nullable
  --amount-to-capture: int # The amount to be captured from the user's payment method, in the lowest denomination. If not provided, and `capture_method` is `automatic`, the full payment `amount` will be captured. If `capture_method` is `manual`, this can be specified in the `/capture` call. Must be less than or equal to the authorized amount. (nullable, format: int64, e.g. 6540)
  --shipping-cost: int # The shipping cost for the payment. This is required for tax calculation in some regions. (nullable, format: int64, e.g. 6540)
  --body-payment-id: string # Optional. A merchant-provided unique identifier for the payment, contains 30 characters long (e.g., "pay_mbabizu24mvu3mela5njyhpit4"). If provided, it ensures idempotency for the payment creation request. If omitted, Hyperswitch generates a unique ID for the payment. (nullable, e.g. pay_mbabizu24mvu3mela5njyhpit4)
  --routing: any # nullable
  --connector: list # This allows to manually select a connector with which the payment can go through. (nullable, e.g. [stripe, adyen])
  --capture-method: any # nullable
  --authentication-type: any # nullable, default: three_ds
  --billing: any # nullable
  --confirm: string@bool-completer # If set to `true`, Hyperswitch attempts to confirm and authorize the payment immediately after creation, provided sufficient payment method details are included. If `false` or omitted (default is `false`), the payment is created with a status such as `requires_payment_method` or `requires_confirmation`, and a separate `POST /payments/{payment_id}/confirm` call is necessary to proceed with authorization. (nullable, default: false, e.g. true)
  --customer: any # nullable
  --customer-id: string # The identifier for the customer (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --off-session: string@bool-completer # Set to true to indicate that the customer is not in your checkout flow during this payment, and therefore is unable to authenticate. This parameter is intended for scenarios where you collect card details and charge them later. When making a recurring payment by passing a mandate_id, this parameter is mandatory (nullable, e.g. true)
  --description: string # An arbitrary string attached to the payment. Often useful for displaying to users or for your own internal record-keeping. (nullable, e.g. It's my first payment request)
  --return-url: string # The URL to redirect the customer to after they complete the payment process or authentication. This is crucial for flows that involve off-site redirection (e.g., 3DS, some bank redirects, wallet payments). (nullable, e.g. https://hyperswitch.io)
  --setup-future-usage: any # nullable
  --payment-method-data: any # nullable
  --payment-method: any # nullable
  --payment-token: string # As Hyperswitch tokenises the sensitive details about the payments method, it provides the payment_token as a reference to a stored payment method, ensuring that the sensitive details are not exposed in any manner. (nullable, e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
  --shipping: any # nullable
  --statement-descriptor-name: string # For non-card charges, you can use this value as the complete description that appears on your customers’ statements. Must contain at least one letter, maximum 22 characters. To be deprecated soon, use billing_descriptor instead. (DEPRECATED, nullable, e.g. Hyperswitch Router)
  --statement-descriptor-suffix: string # Provides information about a card payment that customers see on their statements. Concatenated with the prefix (shortened descriptor) or statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters for the concatenated descriptor. To be deprecated soon, use billing_descriptor instead. (DEPRECATED, nullable, e.g. Payment for shoes purchase)
  --order-details: list # Use this object to capture the details about the different products for which the payment is being made. The sum of amount across different products here should be equal to the overall payment amount (nullable, e.g. [{         "product_name": "Apple iPhone 16",         "quantity": 1,         "amount" : 69000         "product_img_link" : "https://dummy-img-link.com"     }]) — item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
  --mandate-data: any # nullable
  --customer-acceptance: any # nullable
  --browser-info: any # nullable
  --payment-experience: any # nullable
  --payment-method-type: any # nullable
  --merchant-connector-details: any # nullable
  --allowed-payment-method-types: list # Use this parameter to restrict the Payment Method Types to show for a given PaymentIntent (nullable)
  --retry-action: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --connector-metadata: any # nullable
  --payment-link: string@bool-completer # Whether to generate the payment link for this payment or not (if applicable) (nullable, default: false, e.g. true)
  --payment-link-config: any # nullable
  --payment-link-config-id: string # Custom payment link config id set at business profile, send only if business_specific_configs is configured (nullable)
  --surcharge-details: any # nullable
  --payment-type: any # nullable
  --request-incremental-authorization: string@bool-completer # Request an incremental authorization, i.e., increase the authorized amount on a confirmed payment before you capture it. (nullable)
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds (900) for 15 mins (nullable, format: int32, e.g. 900)
  --frm-metadata: record # Additional data related to some frm(Fraud Risk Management) connectors (nullable)
  --request-external-three-ds-authentication: string@bool-completer # Whether to perform external authentication (if applicable) (nullable, e.g. true)
  --three-ds-data: any # nullable
  --recurring-details: any # nullable
  --split-payments: any # nullable
  --request-extended-authorization: string@bool-completer # Optional boolean value to extent authorization period of this payment  capture method must be manual or manual_multiple (nullable, default: false)
  --merchant-order-reference-id: string # Your unique identifier for this payment or order. This ID helps you reconcile payments on your system. If provided, it is passed to the connector if supported. (nullable, e.g. Custom_Order_id_123)
  --skip-external-tax-calculation: string@bool-completer # Whether to calculate tax for this payment intent (nullable)
  --psd2-sca-exemption-type: any # nullable
  --ctp-service-details: any # nullable
  --force-3ds-challenge: string@bool-completer # Indicates if 3ds challenge is forced (nullable)
  --threeds-method-comp-ind: any # nullable
  --is-iframe-redirection-enabled: string@bool-completer # Indicates if the redirection has to open in the iframe (nullable)
  --all-keys-required: string@bool-completer # If enabled, provides whole connector response (nullable)
  --payment-channel: any # nullable
  --tax-status: any # nullable
  --discount-amount: int # Total amount of the discount you have applied to the order or transaction. (nullable, format: int64, e.g. 6540)
  --shipping-amount-tax: any # nullable
  --duty-amount: any # nullable
  --order-date: string # Date the payer placed the order. (nullable, format: date-time)
  --enable-partial-authorization: string@bool-completer # Allow partial authorization for this payment (nullable, default: false)
  --enable-overcapture: string@bool-completer # Boolean indicating whether to enable overcapture for this payment (nullable, e.g. true)
  --is-stored-credential: string@bool-completer # Boolean flag indicating whether this payment method is stored and has been previously used for payments (nullable, e.g. true)
  --mit-category: any # nullable
  --billing-descriptor: any # nullable
  --tokenization: any # nullable
  --partner-merchant-identifier-details: any # nullable
  --installment-options: list # Installment payment options grouped by payment method. When provided, the payment is treated as an installment payment. (nullable) — item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", installments: list}
  --installment-data: any # nullable
  --profile-acquirer-id: string # Identification for the profile acquirer to be used for this payment. (nullable)
  --external-surcharge-strategy: any # nullable
]: any -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)")
  let body = {amount: $amount, order_tax_amount: $order_tax_amount, currency: $currency, amount_to_capture: $amount_to_capture, shipping_cost: $shipping_cost, payment_id: $body_payment_id, routing: $routing, connector: $connector, capture_method: $capture_method, authentication_type: $authentication_type, billing: $billing, confirm: $confirm, customer: $customer, customer_id: $customer_id, off_session: $off_session, description: $description, return_url: $return_url, setup_future_usage: $setup_future_usage, payment_method_data: $payment_method_data, payment_method: $payment_method, payment_token: $payment_token, shipping: $shipping, statement_descriptor_name: $statement_descriptor_name, statement_descriptor_suffix: $statement_descriptor_suffix, order_details: $order_details, mandate_data: $mandate_data, customer_acceptance: $customer_acceptance, browser_info: $browser_info, payment_experience: $payment_experience, payment_method_type: $payment_method_type, merchant_connector_details: $merchant_connector_details, allowed_payment_method_types: $allowed_payment_method_types, retry_action: $retry_action, metadata: $metadata, connector_metadata: $connector_metadata, payment_link: $payment_link, payment_link_config: $payment_link_config, payment_link_config_id: $payment_link_config_id, surcharge_details: $surcharge_details, payment_type: $payment_type, request_incremental_authorization: $request_incremental_authorization, session_expiry: $session_expiry, frm_metadata: $frm_metadata, request_external_three_ds_authentication: $request_external_three_ds_authentication, three_ds_data: $three_ds_data, recurring_details: $recurring_details, split_payments: $split_payments, request_extended_authorization: $request_extended_authorization, merchant_order_reference_id: $merchant_order_reference_id, skip_external_tax_calculation: $skip_external_tax_calculation, psd2_sca_exemption_type: $psd2_sca_exemption_type, ctp_service_details: $ctp_service_details, force_3ds_challenge: $force_3ds_challenge, threeds_method_comp_ind: $threeds_method_comp_ind, is_iframe_redirection_enabled: $is_iframe_redirection_enabled, all_keys_required: $all_keys_required, payment_channel: $payment_channel, tax_status: $tax_status, discount_amount: $discount_amount, shipping_amount_tax: $shipping_amount_tax, duty_amount: $duty_amount, order_date: $order_date, enable_partial_authorization: $enable_partial_authorization, enable_overcapture: $enable_overcapture, is_stored_credential: $is_stored_credential, mit_category: $mit_category, billing_descriptor: $billing_descriptor, tokenization: $tokenization, partner_merchant_identifier_details: $partner_merchant_identifier_details, installment_options: $installment_options, installment_data: $installment_data, profile_acquirer_id: $profile_acquirer_id, external_surcharge_strategy: $external_surcharge_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Retrieve
#
# GET /payments/{payment_id}
# operationId: Retrieve a Payment
export def "payments Retrieve-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-sync: string@bool-completer # Decider to enable or disable the connector call for retrieve request (nullable)
  --client-secret: string # This is a token which expires after 15 minutes, used from the client to authenticate and create sessions from the SDK (nullable)
  --expand-attempts: string@bool-completer # If enabled provides list of attempts linked to payment intent (nullable)
  --expand-captures: string@bool-completer # If enabled provides list of captures linked to latest attempt (nullable)
]: nothing -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_on: string, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, unified_code: string, unified_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_sync" $force_sync "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "expand_attempts" $expand_attempts "scalar") (serialize-qp "expand_captures" $expand_captures "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/payments/($payment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - Confirm
#
# POST /payments/{payment_id}/confirm
# operationId: Confirm a Payment
# --order_details item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
# --installment_options item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", installments: list}
@deprecated --flag statement-descriptor-name
@deprecated --flag statement-descriptor-suffix
@deprecated --flag mandate-id
export def "payments-confirm Confirm-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amount: int # The primary amount for the payment, provided in the lowest denomination of the specified currency (e.g., 6540 for $65.40 USD). This field is mandatory for creating a payment. (nullable, format: int64, e.g. 6540)
  --order-tax-amount: int # Total tax amount applicable to the order, in the lowest denomination of the currency. (nullable, format: int64, e.g. 6540)
  --currency: any # nullable
  --amount-to-capture: int # The amount to be captured from the user's payment method, in the lowest denomination. If not provided, and `capture_method` is `automatic`, the full payment `amount` will be captured. If `capture_method` is `manual`, this can be specified in the `/capture` call. Must be less than or equal to the authorized amount. (nullable, format: int64, e.g. 6540)
  --shipping-cost: int # The shipping cost for the payment. This is required for tax calculation in some regions. (nullable, format: int64, e.g. 6540)
  --body-payment-id: string # Optional. A merchant-provided unique identifier for the payment, contains 30 characters long (e.g., "pay_mbabizu24mvu3mela5njyhpit4"). If provided, it ensures idempotency for the payment creation request. If omitted, Hyperswitch generates a unique ID for the payment. (nullable, e.g. pay_mbabizu24mvu3mela5njyhpit4)
  --routing: any # nullable
  --connector: list # This allows to manually select a connector with which the payment can go through. (nullable, e.g. [stripe, adyen])
  --capture-method: any # nullable
  --authentication-type: any # nullable, default: three_ds
  --billing: any # nullable
  --confirm: string@bool-completer # If set to `true`, Hyperswitch attempts to confirm and authorize the payment immediately after creation, provided sufficient payment method details are included. If `false` or omitted (default is `false`), the payment is created with a status such as `requires_payment_method` or `requires_confirmation`, and a separate `POST /payments/{payment_id}/confirm` call is necessary to proceed with authorization. (nullable, default: false, e.g. true)
  --customer: any # nullable
  --customer-id: string # The identifier for the customer (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --off-session: string@bool-completer # Set to true to indicate that the customer is not in your checkout flow during this payment, and therefore is unable to authenticate. This parameter is intended for scenarios where you collect card details and charge them later. When making a recurring payment by passing a mandate_id, this parameter is mandatory (nullable, e.g. true)
  --description: string # An arbitrary string attached to the payment. Often useful for displaying to users or for your own internal record-keeping. (nullable, e.g. It's my first payment request)
  --return-url: string # The URL to redirect the customer to after they complete the payment process or authentication. This is crucial for flows that involve off-site redirection (e.g., 3DS, some bank redirects, wallet payments). (nullable, e.g. https://hyperswitch.io)
  --setup-future-usage: any # nullable
  --payment-method-data: any # nullable
  --payment-method: any # nullable
  --payment-token: string # As Hyperswitch tokenises the sensitive details about the payments method, it provides the payment_token as a reference to a stored payment method, ensuring that the sensitive details are not exposed in any manner. (nullable, e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
  --shipping: any # nullable
  --statement-descriptor-name: string # For non-card charges, you can use this value as the complete description that appears on your customers’ statements. Must contain at least one letter, maximum 22 characters. To be deprecated soon, use billing_descriptor instead. (DEPRECATED, nullable, e.g. Hyperswitch Router)
  --statement-descriptor-suffix: string # Provides information about a card payment that customers see on their statements. Concatenated with the prefix (shortened descriptor) or statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters for the concatenated descriptor. To be deprecated soon, use billing_descriptor instead. (DEPRECATED, nullable, e.g. Payment for shoes purchase)
  --order-details: list # Use this object to capture the details about the different products for which the payment is being made. The sum of amount across different products here should be equal to the overall payment amount (nullable, e.g. [{         "product_name": "Apple iPhone 16",         "quantity": 1,         "amount" : 69000         "product_img_link" : "https://dummy-img-link.com"     }]) — item shape: {product_name: string, quantity: int, amount: int, tax_rate?: float, total_tax_amount?: int, requires_shipping?: bool, product_img_link?: string, product_id?: string, category?: string, sub_category?: string, brand?: string, product_type?: any, product_tax_code?: string, description?: string, sku?: string, upc?: string, commodity_code?: string, unit_of_measure?: string, total_amount?: int, unit_discount_amount?: int}
  --client-secret: string # It's a token used for client side verification. (nullable, e.g. pay_U42c409qyHwOkWo3vK60_secret_el9ksDkiB8hi6j9N78yo)
  --mandate-data: any # nullable
  --customer-acceptance: any # nullable
  --mandate-id: string # A unique identifier to link the payment to a mandate. To do Recurring payments after a mandate has been created, pass the mandate_id instead of payment_method_data (DEPRECATED, nullable, e.g. mandate_iwer89rnjef349dni3)
  --browser-info: any # nullable
  --payment-experience: any # nullable
  --payment-method-type: any # nullable
  --merchant-connector-details: any # nullable
  --allowed-payment-method-types: list # Use this parameter to restrict the Payment Method Types to show for a given PaymentIntent (nullable)
  --retry-action: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --connector-metadata: any # nullable
  --payment-link: string@bool-completer # Whether to generate the payment link for this payment or not (if applicable) (nullable, default: false, e.g. true)
  --payment-link-config: any # nullable
  --payment-link-config-id: string # Custom payment link config id set at business profile, send only if business_specific_configs is configured (nullable)
  --payment-type: any # nullable
  --request-incremental-authorization: string@bool-completer # Request an incremental authorization, i.e., increase the authorized amount on a confirmed payment before you capture it. (nullable)
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds (900) for 15 mins (nullable, format: int32, e.g. 900)
  --frm-metadata: record # Additional data related to some frm(Fraud Risk Management) connectors (nullable)
  --request-external-three-ds-authentication: string@bool-completer # Whether to perform external authentication (if applicable) (nullable, e.g. true)
  --three-ds-data: any # nullable
  --recurring-details: any # nullable
  --split-payments: any # nullable
  --request-extended-authorization: string@bool-completer # Optional boolean value to extent authorization period of this payment  capture method must be manual or manual_multiple (nullable, default: false)
  --merchant-order-reference-id: string # Your unique identifier for this payment or order. This ID helps you reconcile payments on your system. If provided, it is passed to the connector if supported. (nullable, e.g. Custom_Order_id_123)
  --skip-external-tax-calculation: string@bool-completer # Whether to calculate tax for this payment intent (nullable)
  --psd2-sca-exemption-type: any # nullable
  --ctp-service-details: any # nullable
  --force-3ds-challenge: string@bool-completer # Indicates if 3ds challenge is forced (nullable)
  --threeds-method-comp-ind: any # nullable
  --is-iframe-redirection-enabled: string@bool-completer # Indicates if the redirection has to open in the iframe (nullable)
  --all-keys-required: string@bool-completer # If enabled, provides whole connector response (nullable)
  --payment-channel: any # nullable
  --tax-status: any # nullable
  --discount-amount: int # Total amount of the discount you have applied to the order or transaction. (nullable, format: int64, e.g. 6540)
  --shipping-amount-tax: any # nullable
  --duty-amount: any # nullable
  --order-date: string # Date the payer placed the order. (nullable, format: date-time)
  --enable-partial-authorization: string@bool-completer # Allow partial authorization for this payment (nullable, default: false)
  --is-stored-credential: string@bool-completer # Boolean flag indicating whether this payment method is stored and has been previously used for payments (nullable, e.g. true)
  --mit-category: any # nullable
  --billing-descriptor: any # nullable
  --tokenization: any # nullable
  --partner-merchant-identifier-details: any # nullable
  --installment-options: list # Installment payment options grouped by payment method. When provided, the payment is treated as an installment payment. (nullable) — item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", installments: list}
  --installment-data: any # nullable
  --profile-acquirer-id: string # Identification for the profile acquirer to be used for this payment. (nullable)
  --external-surcharge-strategy: any # nullable
]: any -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/confirm")
  let body = {amount: $amount, order_tax_amount: $order_tax_amount, currency: $currency, amount_to_capture: $amount_to_capture, shipping_cost: $shipping_cost, payment_id: $body_payment_id, routing: $routing, connector: $connector, capture_method: $capture_method, authentication_type: $authentication_type, billing: $billing, confirm: $confirm, customer: $customer, customer_id: $customer_id, off_session: $off_session, description: $description, return_url: $return_url, setup_future_usage: $setup_future_usage, payment_method_data: $payment_method_data, payment_method: $payment_method, payment_token: $payment_token, shipping: $shipping, statement_descriptor_name: $statement_descriptor_name, statement_descriptor_suffix: $statement_descriptor_suffix, order_details: $order_details, client_secret: $client_secret, mandate_data: $mandate_data, customer_acceptance: $customer_acceptance, mandate_id: $mandate_id, browser_info: $browser_info, payment_experience: $payment_experience, payment_method_type: $payment_method_type, merchant_connector_details: $merchant_connector_details, allowed_payment_method_types: $allowed_payment_method_types, retry_action: $retry_action, metadata: $metadata, connector_metadata: $connector_metadata, payment_link: $payment_link, payment_link_config: $payment_link_config, payment_link_config_id: $payment_link_config_id, payment_type: $payment_type, request_incremental_authorization: $request_incremental_authorization, session_expiry: $session_expiry, frm_metadata: $frm_metadata, request_external_three_ds_authentication: $request_external_three_ds_authentication, three_ds_data: $three_ds_data, recurring_details: $recurring_details, split_payments: $split_payments, request_extended_authorization: $request_extended_authorization, merchant_order_reference_id: $merchant_order_reference_id, skip_external_tax_calculation: $skip_external_tax_calculation, psd2_sca_exemption_type: $psd2_sca_exemption_type, ctp_service_details: $ctp_service_details, force_3ds_challenge: $force_3ds_challenge, threeds_method_comp_ind: $threeds_method_comp_ind, is_iframe_redirection_enabled: $is_iframe_redirection_enabled, all_keys_required: $all_keys_required, payment_channel: $payment_channel, tax_status: $tax_status, discount_amount: $discount_amount, shipping_amount_tax: $shipping_amount_tax, duty_amount: $duty_amount, order_date: $order_date, enable_partial_authorization: $enable_partial_authorization, is_stored_credential: $is_stored_credential, mit_category: $mit_category, billing_descriptor: $billing_descriptor, tokenization: $tokenization, partner_merchant_identifier_details: $partner_merchant_identifier_details, installment_options: $installment_options, installment_data: $installment_data, profile_acquirer_id: $profile_acquirer_id, external_surcharge_strategy: $external_surcharge_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Capture
#
# POST /payments/{payment_id}/capture
# operationId: Capture a Payment
export def "payments-capture Capture-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merchant-id: string # The unique identifier for the merchant. This is usually inferred from the API key. (nullable)
  --amount-to-capture: int # The amount to capture, in the lowest denomination of the currency. If omitted, the entire `amount_capturable` of the payment will be captured. Must be less than or equal to the current `amount_capturable`. (nullable, format: int64, e.g. 6540)
  --refund-uncaptured-amount: string@bool-completer # Decider to refund the uncaptured amount. (Currently not fully supported or behavior may vary by connector). (nullable)
  --statement-descriptor-suffix: string # A dynamic suffix that appears on your customer's credit card statement. This is concatenated with the (shortened) descriptor prefix set on your account to form the complete statement descriptor. The combined length should not exceed connector-specific limits (typically 22 characters). (nullable)
  --statement-descriptor-prefix: string # An optional prefix for the statement descriptor that appears on your customer's credit card statement. This can override the default prefix set on your merchant account. The combined length of prefix and suffix should not exceed connector-specific limits (typically 22 characters). (nullable)
  --merchant-connector-details: any # nullable
  --all-keys-required: string@bool-completer # If true, returns stringified connector raw response body (nullable)
]: any -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_on: string, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, unified_code: string, unified_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/capture")
  let body = {merchant_id: $merchant_id, amount_to_capture: $amount_to_capture, refund_uncaptured_amount: $refund_uncaptured_amount, statement_descriptor_suffix: $statement_descriptor_suffix, statement_descriptor_prefix: $statement_descriptor_prefix, merchant_connector_details: $merchant_connector_details, all_keys_required: $all_keys_required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Session token
#
# POST /payments/session_tokens
# operationId: Create Session tokens for a Payment
export def "payments-session-tokens Create-Session-tokens-for-a-Payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_id: string # The identifier for the payment
  --client-secret: string # This is a token which expires after 15 minutes, used from the client to authenticate and create sessions from the SDK (nullable)
  wallets: list # The list of the supported wallets
  --merchant-connector-details: any # nullable
]: any -> record<payment_id: string, client_secret: string, session_token: list<any>, vault_details: record<internal_vault: record<sdk_authorization: string>, external_vault_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/session_tokens")
  let body = {payment_id: $payment_id, client_secret: $client_secret, wallets: $wallets, merchant_connector_details: $merchant_connector_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Cancel
#
# POST /payments/{payment_id}/cancel
# operationId: Cancel a Payment
export def "payments-cancel Cancel-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cancellation-reason: string # The reason for the payment cancel (nullable)
  --merchant-connector-details: any # nullable
  --all-keys-required: string@bool-completer # If enabled, provides whole connector response (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/cancel")
  let body = {cancellation_reason: $cancellation_reason, merchant_connector_details: $merchant_connector_details, all_keys_required: $all_keys_required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Cancel Post Capture
#
# POST /payments/{payment_id}/cancel_post_capture
# operationId: Cancel a Payment Post Capture
export def "payments-cancel-post-capture Cancel-a-Payment-Post-Capture" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cancellation-reason: string # The reason for the payment cancel (nullable)
]: any -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_on: string, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, unified_code: string, unified_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/cancel_post_capture")
  let body = {cancellation_reason: $cancellation_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Cancel Post Capture Retrieve
#
# GET /payments/{payment_id}/cancel_post_capture
# operationId: Cancel a Payment Post Capture Retrieve
export def "payments-cancel-post-capture Cancel-a-Payment-Post-Capture-Retrieve" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_on: string, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, unified_code: string, unified_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/cancel_post_capture")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - Extended Authorization
#
# POST /payments/{payment_id}/extend_authorization
# operationId: Extend authorization period for a Payment
export def "payments-extend-authorization Extend-authorization-period-for-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/extend_authorization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - List
#
# GET /payments/list
# operationId: List all Payments
export def "payments-list List-all-Payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customer-id: string # The identifier for the customer (nullable)
  --starting-after: string # A cursor for use in pagination, fetch the next list after some object (nullable)
  --ending-before: string # A cursor for use in pagination, fetch the previous list before some object (nullable)
  --limit: int # Limit on the number of objects to return (nullable, format: int64)
  --created: string # The time at which payment is created (nullable, format: date-time)
  --created-lt: string # Time less than the payment created time (nullable, format: date-time)
  --created-gt: string # Time greater than the payment created time (nullable, format: date-time)
  --created-lte: string # Time less than or equals to the payment created time (nullable, format: date-time)
  --created-gte: string # Time greater than or equals to the payment created time (nullable, format: date-time)
]: nothing -> table<size: int, data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created_lt" $created_lt "scalar") (serialize-qp "created_gt" $created_gt "scalar") (serialize-qp "created_lte" $created_lte "scalar") (serialize-qp "created_gte" $created_gte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payments/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - Incremental Authorization
#
# POST /payments/{payment_id}/incremental_authorization
# operationId: Increment authorized amount for a Payment
export def "payments-incremental-authorization Increment-authorized-amount-for-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # The total amount including previously authorized amount and additional amount (format: int64, e.g. 6540)
  --reason: string # Reason for incremental authorization (nullable)
]: any -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_on: string, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, unified_code: string, unified_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/incremental_authorization")
  let body = {amount: $amount, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments Link - Retrieve
#
# GET /payment_link/{payment_link_id}
# operationId: Retrieve a Payment Link
export def "payment-link Retrieve-a-Payment-Link" [
  payment_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-secret: string # This is a token which expires after 15 minutes, used from the client to authenticate and create sessions from the SDK (nullable)
]: nothing -> record<payment_link_id: string, merchant_id: string, processor_merchant_id: string, link_to_pay: string, amount: int, created_at: string, expiry: string, description: string, status: string, currency: record, secure_link: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/payment_link/($payment_link_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payments - External 3DS Authentication
#
# POST /payments/{payment_id}/3ds/authentication
# operationId: Initiate external authentication for a Payment
export def "payments-3ds-authentication Initiate-external-authentication-for-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-secret: string # Client Secret (nullable)
  --sdk-information: any # nullable
  device_channel: string@device-channel-completer # Device Channel indicating whether request is coming from App or Browser
  threeds_method_comp_ind: string@threeds-method-comp-ind-completer # Indicates if 3DS method data was successfully completed or not
]: any -> record<trans_status: string, acs_url: string, challenge_request: string, challenge_request_key: string, acs_reference_number: string, acs_trans_id: string, three_dsserver_trans_id: string, acs_signed_content: string, three_ds_requestor_url: string, three_ds_requestor_app_url: string, error_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/3ds/authentication")
  let body = {client_secret: $client_secret, sdk_information: $sdk_information, device_channel: $device_channel, threeds_method_comp_ind: $threeds_method_comp_ind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Complete Authorize
#
# POST /payments/{payment_id}/complete_authorize
# operationId: Complete Authorize a Payment
export def "payments-complete-authorize Complete-Authorize-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --shipping: any # nullable
  --client-secret: string # Client Secret (nullable)
  --threeds-method-comp-ind: any # nullable
]: any -> record<payment_id: string, merchant_id: string, status: record, amount: int, net_amount: int, shipping_cost: int, amount_capturable: int, amount_received: int, processor_merchant_id: string, initiator: record, sdk_authorization: string, connector: string, state_metadata: record<total_refunded_amount: record, total_disputed_amount: record, post_capture_void: record<status: string, connector_reference_id: string, description: string, updated_at: string>>, client_secret: string, created: string, modified_at: string, connector_customer_id: string, currency: string, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, description: string, refunds: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>, disputes: table<dispute_id: string, amount: string, dispute_stage: string, dispute_status: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string>, attempts: table<attempt_id: string, status: string, amount: int, order_tax_amount: int, currency: record, connector: string, error_message: string, payment_method: record, connector_transaction_id: string, capture_method: record, authentication_type: record, created_at: string, modified_at: string, cancellation_reason: string, mandate_id: string, error_code: string, payment_token: string, connector_metadata: any, payment_experience: record, payment_method_type: record, reference_id: string, unified_code: string, unified_message: string, client_source: string, client_version: string, error_details: record>, captures: table<capture_id: string, status: string, amount: int, currency: record, connector: string, authorized_attempt_id: string, connector_capture_id: string, capture_sequence: int, error_message: string, error_code: string, error_reason: string, reference_id: string>, mandate_id: string, mandate_data: record<update_mandate_id: string, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>, mandate_type: record>, setup_future_usage: record, off_session: bool, capture_on: string, capture_method: record, payment_method: string, payment_method_data: record, payment_token: string, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, order_details: table<product_name: string, quantity: int, amount: int, tax_rate: float, total_tax_amount: int, requires_shipping: bool, product_img_link: string, product_id: string, category: string, sub_category: string, brand: string, product_type: record, product_tax_code: string, description: string, sku: string, upc: string, commodity_code: string, unit_of_measure: string, total_amount: int, unit_discount_amount: int>, email: string, name: string, phone: string, return_url: string, authentication_type: record, statement_descriptor_name: string, statement_descriptor_suffix: string, next_action: record, cancellation_reason: string, error_code: string, error_message: string, unified_code: string, unified_message: string, error_details: record<unified_details: record<category: record, message: string, standardised_code: record, description: string, user_guidance_message: string, recommended_action: record>, issuer_details: record<code: string, message: string, network_details: record>, connector_details: record<code: string, message: string, reason: string>>, payment_experience: record, payment_method_type: record, connector_label: string, business_country: record, business_label: string, business_sub_label: string, allowed_payment_method_types: list<string>, manual_retry_allowed: bool, connector_transaction_id: string, frm_message: record<frm_name: string, frm_transaction_id: string, frm_transaction_type: string, frm_status: string, frm_score: int, frm_reason: any, frm_error: string>, metadata: record, connector_metadata: record<apple_pay: record<session_token_data: record>, airwallex: record<payload: string>, noon: record<order_category: string>, braintree: record<merchant_account_id: string, merchant_config_currency: string>, adyen: record<testing: record>, peachpayments: record<rrn: string>, santander: record<boleto: record>>, connector_response_metadata: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>, reference_id: string, payment_link: record<link: string, secure_link: string, payment_link_id: string>, profile_id: string, surcharge_details: record<surcharge_amount: int, tax_amount: record>, attempt_count: int, merchant_decision: string, merchant_connector_id: string, incremental_authorization_allowed: bool, authorization_count: int, incremental_authorizations: table<authorization_id: string, amount: int, status: string, error_code: string, error_message: string, previously_authorized_amount: int>, external_authentication_details: record<authentication_flow: record, electronic_commerce_indicator: string, status: string, ds_transaction_id: string, version: string, error_code: string, error_message: string>, external_3ds_authentication_attempted: bool, expires_on: string, fingerprint: string, browser_info: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, payment_channel: record, payment_method_id: string, network_transaction_id: string, network_transaction_link_id: string, payment_method_status: record, updated: string, split_payments: record, frm_metadata: record, extended_authorization_applied: bool, extended_authorization_last_applied_at: string, request_extended_authorization: bool, capture_before: string, merchant_order_reference_id: string, order_tax_amount: record, connector_mandate_id: string, card_discovery: record, force_3ds_challenge: bool, force_3ds_challenge_trigger: bool, issuer_error_code: string, issuer_error_message: string, is_iframe_redirection_enabled: bool, whole_connector_response: string, enable_partial_authorization: bool, enable_overcapture: bool, is_overcapture_enabled: bool, network_details: record<network_advice_code: string>, is_stored_credential: bool, mit_category: record, billing_descriptor: record<name: string, city: string, phone: string, statement_descriptor: string, statement_descriptor_suffix: string, reference: string>, tokenization: record, partner_merchant_identifier_details: record<partner_details: record<name: string, version: string, integrator: string>, merchant_details: record<name: string, version: string>>, payment_method_tokenization_details: record<payment_method_id: string, payment_method_status: record, psp_tokenization: bool, network_tokenization: bool, network_transaction_id: string, network_transaction_link_id: string, is_eligible_for_mit_payment: bool>, installment_options: table<payment_method: string, installments: list>, installment_data: record<number_of_installments: int, billing_frequency: string, installment_interest: record>, sender_payment_instrument_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/complete_authorize")
  let body = {shipping: $shipping, client_secret: $client_secret, threeds_method_comp_ind: $threeds_method_comp_ind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Post Session Tokens
#
# POST /payments/{payment_id}/post_session_tokens
# operationId: Create Post Session Tokens for a Payment
export def "payments-post-session-tokens Create-Post-Session-Tokens-for-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-secret: string # It's a token used for client side verification. (nullable)
  payment_method_type: string@payment-method-type-completer # Indicates the sub type of payment method. Eg: 'google_pay' & 'apple_pay' for wallets.
  payment_method: string@payment-method-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
]: any -> record<payment_id: string, next_action: record, status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/post_session_tokens")
  let body = {client_secret: $client_secret, payment_method_type: $payment_method_type, payment_method: $payment_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Update Metadata
#
# POST /payments/{payment_id}/update_metadata
# operationId: Update Metadata for a Payment
export def "payments-update-metadata Update-Metadata-for-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metadata: record # Metadata is useful for storing additional, unstructured information on an object.
  --feature-metadata: any # nullable
]: any -> record<payment_id: string, metadata: record, status: record, feature_metadata: record<redirect_response: record<param: string, json_payload: record>, search_tags: list<string>, apple_pay_recurring_details: record<payment_description: string, regular_billing: record, billing_agreement: string, management_url: string>, pix_additional_details: record, boleto_additional_details: record<due_date: string, document_kind: record, payment_type: record, covenant_code: string, pix_key: record>, pix_automatico_additional_details: record, finix_additional_details: record<fraud_session_id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/update_metadata")
  let body = {metadata: $metadata, feature_metadata: $feature_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Submit Eligibility Check Data
#
# POST /payments/{payment_id}/eligibility_check
# operationId: Submit Eligibility Check data for a Payment
export def "payments-eligibility-check Submit-Eligibility-Check-data-for-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_secret: string # Token used for client side verification (e.g. pay_U42c409qyHwOkWo3vK60_secret_el9ksDkiB8hi6j9N78yo)
  payment_method_type: string@payment-method-type-completer-1 # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-subtype: any # nullable
  --payment-method-data: any # nullable
  --browser-info: any # nullable
  payment_token: string # The payment token to look up the saved payment method When provided, the system will fetch the payment method data from the locker/vault (e.g. token_abc123xyz)
]: any -> record<payment_id: string, sdk_next_action: record<next_action: any, should_block_confirm: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/eligibility_check")
  let body = {client_secret: $client_secret, payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype, payment_method_data: $payment_method_data, browser_info: $browser_info, payment_token: $payment_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payments - Submit Eligibility Data
#
# POST /payments/{payment_id}/eligibility
# operationId: Submit Eligibility data for a Payment
export def "payments-eligibility Submit-Eligibility-data-for-a-Payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_secret: string # Token used for client side verification (e.g. pay_U42c409qyHwOkWo3vK60_secret_el9ksDkiB8hi6j9N78yo)
  payment_method_type: string@payment-method-type-completer-1 # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-subtype: any # nullable
  --payment-method-data: any # nullable
  --browser-info: any # nullable
  payment_token: string # The payment token to look up the saved payment method (e.g. token_abc123xyz)
]: any -> record<payment_id: string, sdk_next_action: record<next_action: any, should_block_confirm: bool>, surcharge_details: record<surcharge: any, tax_on_surcharge: record<percentage: float>, display_surcharge_amount: float, display_tax_on_surcharge_amount: float, display_total_surcharge_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($payment_id)/eligibility")
  let body = {client_secret: $client_secret, payment_method_type: $payment_method_type, payment_method_subtype: $payment_method_subtype, payment_method_data: $payment_method_data, browser_info: $browser_info, payment_token: $payment_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Relay - Create
#
# POST /relay
# operationId: Relay Request
export def "relay Relay-Request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  --X-Idempotency-Key: string # Idempotency Key for relay request
  connector_resource_id: string # The identifier that is associated to a resource at the connector reference to which the relay request is being made (e.g. 7256228702616471803954)
  connector_id: string # Identifier of the connector ( merchant connector account ) which was chosen to make the payment (e.g. mca_5apGeP94tMts6rg3U3kR)
  type: string@type-completer
  --data: any # nullable
]: any -> record<id: string, status: string, connector_resource_id: string, error: record<code: string, message: string>, connector_reference_id: string, connector_id: string, profile_id: string, type: string, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/relay")
  let body = {connector_resource_id: $connector_resource_id, connector_id: $connector_id, type: $type, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id, "X-Idempotency-Key": $X_Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Relay - Retrieve
#
# GET /relay/{relay_id}
# operationId: Retrieve a Relay details
export def "relay Retrieve-a-Relay-details" [
  relay_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
]: nothing -> record<id: string, status: string, connector_resource_id: string, error: record<code: string, message: string>, connector_reference_id: string, connector_id: string, profile_id: string, type: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/relay/($relay_id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refunds - Create
#
# POST /refunds
# operationId: Create a Refund
export def "refunds Create-a-Refund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_id: string # The payment id against which refund is to be initiated (e.g. pay_mbabizu24mvu3mela5njyhpit4)
  --refund-id: string # Unique Identifier for the Refund. This is to ensure idempotency for multiple partial refunds initiated against the same payment. If this is not passed by the merchant, this field shall be auto generated and provided in the API response. It is recommended to generate uuid(v4) as the refund_id. (nullable, e.g. ref_mbabizu24mvu3mela5njyhpit4)
  --merchant-id: string # The identifier for the Merchant Account (nullable, e.g. y3oqhf46pyzuxjbcn2giaqnb44)
  --amount: int # Total amount for which the refund is to be initiated. Amount for the payment in lowest denomination of the currency. (i.e) in cents for USD denomination, in paisa for INR denomination etc., If not provided, this will default to the full payment amount (nullable, format: int64, e.g. 6540)
  --reason: string # Reason for the refund. Often useful for displaying to users and your customer support executive. In case the payment went through Stripe, this field needs to be passed with one of these enums: `duplicate`, `fraudulent`, or `requested_by_customer` (nullable, e.g. Customer returned the product)
  --refund-type: any # nullable, default: Instant
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --merchant-connector-details: any # nullable
  --split-refunds: any # nullable
  --all-keys-required: string@bool-completer # If true, returns stringified connector raw response body (nullable)
]: any -> record<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refunds")
  let body = {payment_id: $payment_id, refund_id: $refund_id, merchant_id: $merchant_id, amount: $amount, reason: $reason, refund_type: $refund_type, metadata: $metadata, merchant_connector_details: $merchant_connector_details, split_refunds: $split_refunds, all_keys_required: $all_keys_required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refunds - Retrieve
#
# GET /refunds/{refund_id}
# operationId: Retrieve a Refund
export def "refunds Retrieve-a-Refund" [
  refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/refunds/($refund_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refunds - Update
#
# POST /refunds/{refund_id}
# operationId: Update a Refund
export def "refunds Update-a-Refund" [
  refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # An arbitrary string attached to the object. Often useful for displaying to users and your customer support executive (nullable, e.g. Customer returned the product)
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
]: any -> record<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/refunds/($refund_id)")
  let body = {reason: $reason, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refunds - List
#
# POST /refunds/list
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
  --refund-id: string # The identifier for the refund (nullable)
  --profile-id: string # The identifier for business profile (nullable)
  --limit: int # Limit on the number of objects to return (nullable, format: int64)
  --offset: int # The starting point within a list of objects (nullable, format: int64)
  --amount-filter: any # nullable
  --connector: list # The list of connectors to filter refunds list (nullable)
  --merchant-connector-id: list # The list of merchant connector ids to filter the refunds list for selected label (nullable)
  --currency: list # The list of currencies to filter refunds list (nullable)
  --refund-status: list # The list of refund statuses to filter refunds list (nullable)
]: any -> record<count: int, total_count: int, data: table<refund_id: string, payment_id: string, amount: int, currency: string, status: string, reason: string, metadata: record, error_message: string, error_code: string, unified_code: string, unified_message: string, created_at: string, updated_at: string, connector: string, profile_id: string, merchant_connector_id: string, split_refunds: record, issuer_error_code: string, issuer_error_message: string, raw_connector_response: string, connector_refund_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refunds/list")
  let body = {payment_id: $payment_id, refund_id: $refund_id, profile_id: $profile_id, limit: $limit, offset: $offset, amount_filter: $amount_filter, connector: $connector, merchant_connector_id: $merchant_connector_id, currency: $currency, refund_status: $refund_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Organization - Create
#
# POST /organization
# operationId: Create an Organization
export def "organization Create-an-Organization" [
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
]: any -> record<organization_id: string, organization_name: string, organization_details: record, metadata: record, modified_at: string, created_at: string, organization_type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization")
  let body = {organization_name: $organization_name, organization_details: $organization_details, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Organization - Retrieve
#
# GET /organization/{id}
# operationId: Retrieve an Organization
export def "organization Retrieve-an-Organization" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_id: string, organization_name: string, organization_details: record, metadata: record, modified_at: string, created_at: string, organization_type: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization - Update
#
# PUT /organization/{id}
# operationId: Update an Organization
export def "organization Update-an-Organization" [
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
]: any -> record<organization_id: string, organization_name: string, organization_details: record, metadata: record, modified_at: string, created_at: string, organization_type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($id)")
  let body = {organization_name: $organization_name, organization_details: $organization_details, metadata: $metadata, platform_merchant_id: $platform_merchant_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Account - Create
#
# POST /accounts
# operationId: Create a Merchant Account
export def "accounts Create-a-Merchant-Account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merchant_id: string # The identifier for the Merchant Account (e.g. y3oqhf46pyzuxjbcn2giaqnb44)
  --merchant-name: string # Name of the Merchant Account (nullable, e.g. NewAge Retailer)
  --merchant-details: any # nullable
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://www.example.com/success)
  --webhook-details: any # nullable
  --payout-routing-algorithm: any # nullable
  --sub-merchants-enabled: string@bool-completer # A boolean value to indicate if the merchant is a sub-merchant under a master or a parent merchant. By default, its value is false. (nullable, default: false, e.g. false)
  --parent-merchant-id: string # Refers to the Parent Merchant ID if the merchant being created is a sub-merchant (nullable, e.g. xkkdf909012sdjki2dkh5sdf)
  --enable-payment-response-hash: string@bool-completer # A boolean value to indicate if payment response hash needs to be enabled (nullable, default: false, e.g. true)
  --payment-response-hash-key: string # Refers to the hash key used for calculating the signature for webhooks and redirect response. If the value is not provided, a value is automatically generated. (nullable)
  --redirect-to-merchant-with-http-post: string@bool-completer # A boolean value to indicate if redirect to merchant with http post needs to be enabled. (nullable, default: false, e.g. true)
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object (nullable)
  --publishable-key: string # API key that will be used for client side API access. A publishable key has to be always paired with a `client_secret`. A `client_secret` can be obtained by creating a payment with `confirm` set to false (nullable, e.g. AH3423bkjbkjdsfbkj)
  --locker-id: string # An identifier for the vault used to store payment method information. (nullable, e.g. locker_abc123)
  --primary-business-details: any # nullable
  --frm-routing-algorithm: record # The frm routing algorithm to be used for routing payments to desired FRM's (nullable)
  --organization-id: string # The id of the organization to which the merchant belongs to, if not passed an organization is created (nullable, e.g. org_q98uSGAYbjEwqs0mJwnz)
  --pm-collect-link-config: any # nullable
  --product-type: any # nullable
  --merchant-account-type: any # nullable
  --network-tokenization-credentials: any # nullable
]: any -> record<merchant_id: string, merchant_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, merchant_details: record<primary_contact_person: string, primary_phone: string, primary_email: string, secondary_contact_person: string, secondary_phone: string, secondary_email: string, website: string, about_business: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, merchant_tax_registration_id: string>, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, payout_routing_algorithm: record, sub_merchants_enabled: bool, parent_merchant_id: string, publishable_key: string, metadata: record, locker_id: string, primary_business_details: table<country: string, business: string>, frm_routing_algorithm: record, organization_id: string, is_recon_enabled: bool, default_profile: string, recon_status: string, pm_collect_link_config: record, product_type: record, merchant_account_type: string, network_tokenization_credentials: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let body = {merchant_id: $merchant_id, merchant_name: $merchant_name, merchant_details: $merchant_details, return_url: $return_url, webhook_details: $webhook_details, payout_routing_algorithm: $payout_routing_algorithm, sub_merchants_enabled: $sub_merchants_enabled, parent_merchant_id: $parent_merchant_id, enable_payment_response_hash: $enable_payment_response_hash, payment_response_hash_key: $payment_response_hash_key, redirect_to_merchant_with_http_post: $redirect_to_merchant_with_http_post, metadata: $metadata, publishable_key: $publishable_key, locker_id: $locker_id, primary_business_details: $primary_business_details, frm_routing_algorithm: $frm_routing_algorithm, organization_id: $organization_id, pm_collect_link_config: $pm_collect_link_config, product_type: $product_type, merchant_account_type: $merchant_account_type, network_tokenization_credentials: $network_tokenization_credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Account - Retrieve
#
# GET /accounts/{account_id}
# operationId: Retrieve a Merchant Account
export def "accounts Retrieve-a-Merchant-Account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<merchant_id: string, merchant_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, merchant_details: record<primary_contact_person: string, primary_phone: string, primary_email: string, secondary_contact_person: string, secondary_phone: string, secondary_email: string, website: string, about_business: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, merchant_tax_registration_id: string>, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, payout_routing_algorithm: record, sub_merchants_enabled: bool, parent_merchant_id: string, publishable_key: string, metadata: record, locker_id: string, primary_business_details: table<country: string, business: string>, frm_routing_algorithm: record, organization_id: string, is_recon_enabled: bool, default_profile: string, recon_status: string, pm_collect_link_config: record, product_type: record, merchant_account_type: string, network_tokenization_credentials: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merchant Account - Update
#
# POST /accounts/{account_id}
# operationId: Update a Merchant Account
# --primary_business_details item shape: {country: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CG"|"CD"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"US", business: string}
export def "accounts Update-a-Merchant-Account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merchant_id: string # The identifier for the Merchant Account (e.g. y3oqhf46pyzuxjbcn2giaqnb44)
  --merchant-name: string # Name of the Merchant Account (nullable, e.g. NewAge Retailer)
  --merchant-details: any # nullable
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://www.example.com/success)
  --webhook-details: any # nullable
  --payout-routing-algorithm: any # nullable
  --sub-merchants-enabled: string@bool-completer # A boolean value to indicate if the merchant is a sub-merchant under a master or a parent merchant. By default, its value is false. (nullable, default: false, e.g. false)
  --parent-merchant-id: string # Refers to the Parent Merchant ID if the merchant being created is a sub-merchant (nullable, e.g. xkkdf909012sdjki2dkh5sdf)
  --enable-payment-response-hash: string@bool-completer # A boolean value to indicate if payment response hash needs to be enabled (nullable, default: false, e.g. true)
  --payment-response-hash-key: string # Refers to the hash key used for calculating the signature for webhooks and redirect response. (nullable)
  --redirect-to-merchant-with-http-post: string@bool-completer # A boolean value to indicate if redirect to merchant with http post needs to be enabled (nullable, default: false, e.g. true)
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --publishable-key: string # API key that will be used for server side API access (nullable, e.g. AH3423bkjbkjdsfbkj)
  --locker-id: string # An identifier for the vault used to store payment method information. (nullable, e.g. locker_abc123)
  --primary-business-details: list # Details about the primary business unit of the merchant account (nullable) — item shape: {country: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CG"|"CD"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"US", business: string}
  --frm-routing-algorithm: record # The frm routing algorithm to be used for routing payments to desired FRM's (nullable)
  --default-profile: string # The default profile that must be used for creating merchant accounts and payments (nullable)
  --pm-collect-link-config: any # nullable
  --network-tokenization-credentials: any # nullable
]: any -> record<merchant_id: string, merchant_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, merchant_details: record<primary_contact_person: string, primary_phone: string, primary_email: string, secondary_contact_person: string, secondary_phone: string, secondary_email: string, website: string, about_business: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, merchant_tax_registration_id: string>, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, payout_routing_algorithm: record, sub_merchants_enabled: bool, parent_merchant_id: string, publishable_key: string, metadata: record, locker_id: string, primary_business_details: table<country: string, business: string>, frm_routing_algorithm: record, organization_id: string, is_recon_enabled: bool, default_profile: string, recon_status: string, pm_collect_link_config: record, product_type: record, merchant_account_type: string, network_tokenization_credentials: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let body = {merchant_id: $merchant_id, merchant_name: $merchant_name, merchant_details: $merchant_details, return_url: $return_url, webhook_details: $webhook_details, payout_routing_algorithm: $payout_routing_algorithm, sub_merchants_enabled: $sub_merchants_enabled, parent_merchant_id: $parent_merchant_id, enable_payment_response_hash: $enable_payment_response_hash, payment_response_hash_key: $payment_response_hash_key, redirect_to_merchant_with_http_post: $redirect_to_merchant_with_http_post, metadata: $metadata, publishable_key: $publishable_key, locker_id: $locker_id, primary_business_details: $primary_business_details, frm_routing_algorithm: $frm_routing_algorithm, default_profile: $default_profile, pm_collect_link_config: $pm_collect_link_config, network_tokenization_credentials: $network_tokenization_credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Account - Delete
#
# DELETE /accounts/{account_id}
# operationId: Delete a Merchant Account
export def "accounts Delete-a-Merchant-Account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<merchant_id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merchant Account - KV Status
#
# POST /accounts/{account_id}/kv
# operationId: Enable/Disable KV for a Merchant Account
export def "accounts-kv Enable/Disable-KV-for-a-Merchant-Account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kv-enabled: string@bool-completer # Status of KV for the specific merchant (e.g. true)
]: any -> record<merchant_id: string, kv_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/kv")
  let body = {kv_enabled: $kv_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Connector - Create
#
# POST /account/{account_id}/connectors
# operationId: Create a Merchant Connector
# --payment_methods_enabled item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_types?: list}
# --frm_configs item shape: {gateway: "payment_processor"|"payment_vas"|"fin_operations"|"fiz_operations"|"networks"|"banking_entities"|"non_banking_finance"|"payout_processor"|"payment_method_auth"|"authentication_processor"|"tax_processor"|"surcharge_processor"|"billing_processor"|"vault_processor", payment_methods: list}
@deprecated --flag business-label
@deprecated --flag business-sub-label
export def "account-connectors Create-a-Merchant-Connector" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector_type: string@connector-type-completer # Type of the Connector for the financial use case. Could range from Payments to Accounting to Banking.
  connector_name: string@connector-name-completer
  --connector-label: string # This is an unique label you can generate and pass in order to identify this connector account on your Hyperswitch dashboard and reports. Eg: if your profile label is `default`, connector label can be `stripe_default` (nullable, e.g. stripe_US_travel)
  --profile-id: string # Identifier for the profile, if not provided default will be chosen from merchant account (nullable)
  --connector-account-details: any # nullable
  --payment-methods-enabled: list # An object containing the details about the payment methods that need to be enabled under this merchant connector account (nullable, e.g. [{accepted_countries: {list: [FR, DE, IN], type: disable_only}, accepted_currencies: {list: [USD, EUR], type: enable_only}, installment_payment_enabled: true, maximum_amount: 68607706, minimum_amount: 1, payment_method: wallet, payment_method_issuers: [labore magna ipsum, aute], payment_method_types: [upi_collect, upi_intent], payment_schemes: [Discover, Discover], recurring_enabled: true}]) — item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_types?: list}
  --connector-webhook-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --test-mode: string@bool-completer # A boolean value to indicate if the connector is in Test mode. By default, its value is false. (nullable, default: false, e.g. false)
  --disabled: string@bool-completer # A boolean value to indicate if the connector is disabled. By default, its value is false. (nullable, default: false, e.g. false)
  --frm-configs: list # Contains the frm configs for the merchant connector (nullable, e.g.  [{"gateway":"stripe","payment_methods":[{"payment_method":"card","payment_method_types":[{"payment_method_type":"credit","card_networks":["Visa"],"flow":"pre","action":"cancel_txn"},{"payment_method_type":"debit","card_networks":["Visa"],"flow":"pre"}]}]}] ) — item shape: {gateway: "payment_processor"|"payment_vas"|"fin_operations"|"fiz_operations"|"networks"|"banking_entities"|"non_banking_finance"|"payout_processor"|"payment_method_auth"|"authentication_processor"|"tax_processor"|"surcharge_processor"|"billing_processor"|"vault_processor", payment_methods: list}
  --business-country: any # nullable
  --business-label: string # The business label to which the connector account is attached. To be deprecated soon. Use the 'profile_id' instead (DEPRECATED, nullable)
  --business-sub-label: string # The business sublabel to which the connector account is attached. To be deprecated soon. Use the 'profile_id' instead (DEPRECATED, nullable, e.g. chase)
  --merchant-connector-id: string # Unique ID of the connector (nullable, e.g. mca_5apGeP94tMts6rg3U3kR)
  --pm-auth-config: record # nullable
  --status: any # nullable
  --additional-merchant-data: any # nullable
  --connector-wallets-details: any # nullable
]: any -> record<connector_type: string, connector_name: string, connector_label: string, merchant_connector_id: string, profile_id: string, connector_account_details: record<connector_account_details: record, metadata: record>, payment_methods_enabled: table<payment_method: string, payment_method_types: list>, connector_webhook_details: record<merchant_secret: string, additional_secret: string>, metadata: record, test_mode: bool, disabled: bool, frm_configs: table<gateway: string, payment_methods: list>, business_country: record, business_label: string, business_sub_label: string, applepay_verified_domains: list<string>, pm_auth_config: record, status: string, additional_merchant_data: record, connector_wallets_details: record<apple_pay_combined: record, apple_pay: record, amazon_pay: record, samsung_pay: record, paze: record, google_pay: record>, webhook_setup_capabilities: record<is_webhook_auto_configuration_supported: bool, requires_webhook_secret: bool, config_type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/connectors")
  let body = {connector_type: $connector_type, connector_name: $connector_name, connector_label: $connector_label, profile_id: $profile_id, connector_account_details: $connector_account_details, payment_methods_enabled: $payment_methods_enabled, connector_webhook_details: $connector_webhook_details, metadata: $metadata, test_mode: $test_mode, disabled: $disabled, frm_configs: $frm_configs, business_country: $business_country, business_label: $business_label, business_sub_label: $business_sub_label, merchant_connector_id: $merchant_connector_id, pm_auth_config: $pm_auth_config, status: $status, additional_merchant_data: $additional_merchant_data, connector_wallets_details: $connector_wallets_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Connector - List
#
# GET /account/{account_id}/connectors
# operationId: List all Merchant Connectors
export def "account-connectors List-all-Merchant-Connectors" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<connector_type: string, connector_name: string, connector_label: string, merchant_connector_id: string, profile_id: string, payment_methods_enabled: list<record>, test_mode: bool, disabled: bool, frm_configs: list<record>, business_country: record, business_label: string, business_sub_label: string, applepay_verified_domains: list<string>, pm_auth_config: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/connectors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merchant Connector - Retrieve
#
# GET /account/{account_id}/connectors/{merchant_connector_id}
# operationId: Retrieve a Merchant Connector
export def "account-connectors Retrieve-a-Merchant-Connector" [
  account_id: string
  merchant_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connector_type: string, connector_name: string, connector_label: string, merchant_connector_id: string, profile_id: string, connector_account_details: record<connector_account_details: record, metadata: record>, payment_methods_enabled: table<payment_method: string, payment_method_types: list>, connector_webhook_details: record<merchant_secret: string, additional_secret: string>, metadata: record, test_mode: bool, disabled: bool, frm_configs: table<gateway: string, payment_methods: list>, business_country: record, business_label: string, business_sub_label: string, applepay_verified_domains: list<string>, pm_auth_config: record, status: string, additional_merchant_data: record, connector_wallets_details: record<apple_pay_combined: record, apple_pay: record, amazon_pay: record, samsung_pay: record, paze: record, google_pay: record>, webhook_setup_capabilities: record<is_webhook_auto_configuration_supported: bool, requires_webhook_secret: bool, config_type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/connectors/($merchant_connector_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merchant Connector - Update
#
# POST /account/{account_id}/connectors/{merchant_connector_id}
# operationId: Update a Merchant Connector
# --payment_methods_enabled item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_types?: list}
# --frm_configs item shape: {gateway: "payment_processor"|"payment_vas"|"fin_operations"|"fiz_operations"|"networks"|"banking_entities"|"non_banking_finance"|"payout_processor"|"payment_method_auth"|"authentication_processor"|"tax_processor"|"surcharge_processor"|"billing_processor"|"vault_processor", payment_methods: list}
export def "account-connectors Update-a-Merchant-Connector" [
  account_id: string
  merchant_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector_type: string@connector-type-completer # Type of the Connector for the financial use case. Could range from Payments to Accounting to Banking.
  --connector-label: string # This is an unique label you can generate and pass in order to identify this connector account on your Hyperswitch dashboard and reports. Eg: if your profile label is `default`, connector label can be `stripe_default` (nullable, e.g. stripe_US_travel)
  --connector-account-details: any # nullable
  --payment-methods-enabled: list # An object containing the details about the payment methods that need to be enabled under this merchant connector account (nullable, e.g. [{accepted_countries: {list: [FR, DE, IN], type: disable_only}, accepted_currencies: {list: [USD, EUR], type: enable_only}, installment_payment_enabled: true, maximum_amount: 68607706, minimum_amount: 1, payment_method: wallet, payment_method_issuers: [labore magna ipsum, aute], payment_method_types: [upi_collect, upi_intent], payment_schemes: [Discover, Discover], recurring_enabled: true}]) — item shape: {payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_types?: list}
  --connector-webhook-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --test-mode: string@bool-completer # A boolean value to indicate if the connector is in Test mode. By default, its value is false. (nullable, default: false, e.g. false)
  --disabled: string@bool-completer # A boolean value to indicate if the connector is disabled. By default, its value is false. (nullable, default: false, e.g. false)
  --frm-configs: list # Contains the frm configs for the merchant connector (nullable, e.g.  [{"gateway":"stripe","payment_methods":[{"payment_method":"card","payment_method_types":[{"payment_method_type":"credit","card_networks":["Visa"],"flow":"pre","action":"cancel_txn"},{"payment_method_type":"debit","card_networks":["Visa"],"flow":"pre"}]}]}] ) — item shape: {gateway: "payment_processor"|"payment_vas"|"fin_operations"|"fiz_operations"|"networks"|"banking_entities"|"non_banking_finance"|"payout_processor"|"payment_method_auth"|"authentication_processor"|"tax_processor"|"surcharge_processor"|"billing_processor"|"vault_processor", payment_methods: list}
  --pm-auth-config: record # pm_auth_config will relate MCA records to their respective chosen auth services, based on payment_method and pmt (nullable)
  status: string@status-completer
  --additional-merchant-data: any # nullable
  --connector-wallets-details: any # nullable
]: any -> record<connector_type: string, connector_name: string, connector_label: string, merchant_connector_id: string, profile_id: string, connector_account_details: record<connector_account_details: record, metadata: record>, payment_methods_enabled: table<payment_method: string, payment_method_types: list>, connector_webhook_details: record<merchant_secret: string, additional_secret: string>, metadata: record, test_mode: bool, disabled: bool, frm_configs: table<gateway: string, payment_methods: list>, business_country: record, business_label: string, business_sub_label: string, applepay_verified_domains: list<string>, pm_auth_config: record, status: string, additional_merchant_data: record, connector_wallets_details: record<apple_pay_combined: record, apple_pay: record, amazon_pay: record, samsung_pay: record, paze: record, google_pay: record>, webhook_setup_capabilities: record<is_webhook_auto_configuration_supported: bool, requires_webhook_secret: bool, config_type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/connectors/($merchant_connector_id)")
  let body = {connector_type: $connector_type, connector_label: $connector_label, connector_account_details: $connector_account_details, payment_methods_enabled: $payment_methods_enabled, connector_webhook_details: $connector_webhook_details, metadata: $metadata, test_mode: $test_mode, disabled: $disabled, frm_configs: $frm_configs, pm_auth_config: $pm_auth_config, status: $status, additional_merchant_data: $additional_merchant_data, connector_wallets_details: $connector_wallets_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merchant Connector - Delete
#
# DELETE /account/{account_id}/connectors/{merchant_connector_id}
# operationId: Delete a Merchant Connector
export def "account-connectors Delete-a-Merchant-Connector" [
  account_id: string
  merchant_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<merchant_id: string, merchant_connector_id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/connectors/($merchant_connector_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure Connector Webhook - Register
#
# POST /account/{account_id}/webhooks/{merchant_connector_id}
# operationId: Register a Connector Webhook
export def "account-webhooks Register-a-Connector-Webhook" [
  account_id: string
  merchant_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event-type: any # nullable
]: any -> record<event_type: record, connector_webhook_id: string, webhook_registration_status: record, error_code: string, error_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/webhooks/($merchant_connector_id)")
  let body = {event_type: $event_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gsm - Create
#
# POST /gsm
# operationId: Create Gsm Rule
@deprecated --flag step-up-possible
@deprecated --flag clear-pan-possible
export def "gsm Create-Gsm-Rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector: string@connector-completer
  flow: string # The flow in which the code and message occurred for a connector
  sub_flow: string # The sub_flow in which the code and message occurred  for a connector
  code: string # code received from the connector
  message: string # message received from the connector
  status: string # status provided by the router
  --router-error: string # optional error provided by the router (nullable)
  decision: string@decision-completer
  --step-up-possible: string@bool-completer # indicates if step_up retry is possible **Deprecated**: This field is now included as part of `feature_data` under the `Retry` variant. (DEPRECATED)
  --unified-code: string # error code unified across the connectors (nullable)
  --unified-message: string # error message unified across the connectors (nullable)
  --error-category: any # nullable
  --clear-pan-possible: string@bool-completer # indicates if retry with pan is possible **Deprecated**: This field is now included as part of `feature_data` under the `Retry` variant. (DEPRECATED)
  --feature: any # nullable
  --feature-data: any # nullable
  --standardised-code: any # nullable
  --description: string # A detailed description of the error intended for debugging, analytics, and support teams. (nullable)
  --user-guidance-message: string # A user-friendly message that can be safely displayed to the customer. This message provides guidance on what the user should do to resolve the issue. (nullable)
]: any -> record<connector: string, flow: string, sub_flow: string, code: string, message: string, status: string, router_error: string, decision: string, step_up_possible: bool, unified_code: string, unified_message: string, error_category: record, clear_pan_possible: bool, feature: string, feature_data: any, standardised_code: record, description: string, user_guidance_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gsm")
  let body = {connector: $connector, flow: $flow, sub_flow: $sub_flow, code: $code, message: $message, status: $status, router_error: $router_error, decision: $decision, step_up_possible: $step_up_possible, unified_code: $unified_code, unified_message: $unified_message, error_category: $error_category, clear_pan_possible: $clear_pan_possible, feature: $feature, feature_data: $feature_data, standardised_code: $standardised_code, description: $description, user_guidance_message: $user_guidance_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gsm - Get
#
# POST /gsm/get
# operationId: Retrieve Gsm Rule
export def "gsm-get Retrieve-Gsm-Rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector: string@connector-completer
  flow: string # The flow in which the code and message occurred for a connector
  sub_flow: string # The sub_flow in which the code and message occurred  for a connector
  code: string # code received from the connector
  message: string # message received from the connector
]: any -> record<connector: string, flow: string, sub_flow: string, code: string, message: string, status: string, router_error: string, decision: string, step_up_possible: bool, unified_code: string, unified_message: string, error_category: record, clear_pan_possible: bool, feature: string, feature_data: any, standardised_code: record, description: string, user_guidance_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gsm/get")
  let body = {connector: $connector, flow: $flow, sub_flow: $sub_flow, code: $code, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gsm - Update
#
# POST /gsm/update
# operationId: Update Gsm Rule
@deprecated --flag step-up-possible
@deprecated --flag clear-pan-possible
export def "gsm-update Update-Gsm-Rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector: string # The connector through which payment has gone through
  flow: string # The flow in which the code and message occurred for a connector
  sub_flow: string # The sub_flow in which the code and message occurred  for a connector
  code: string # code received from the connector
  message: string # message received from the connector
  --status: string # status provided by the router (nullable)
  --router-error: string # optional error provided by the router (nullable)
  --decision: any # nullable
  --step-up-possible: string@bool-completer # indicates if step_up retry is possible **Deprecated**: This field is now included as part of `feature_data` under the `Retry` variant. (DEPRECATED, nullable)
  --unified-code: string # error code unified across the connectors (nullable)
  --unified-message: string # error message unified across the connectors (nullable)
  --error-category: any # nullable
  --clear-pan-possible: string@bool-completer # indicates if retry with pan is possible **Deprecated**: This field is now included as part of `feature_data` under the `Retry` variant. (DEPRECATED, nullable)
  --feature: any # nullable
  --feature-data: any # nullable
  --standardised-code: any # nullable
  --description: string # A detailed description of the error intended for debugging, analytics, and support teams. (nullable)
  --user-guidance-message: string # A user-friendly message that can be safely displayed to the customer. This message provides guidance on what the user should do to resolve the issue. (nullable)
]: any -> record<connector: string, flow: string, sub_flow: string, code: string, message: string, status: string, router_error: string, decision: string, step_up_possible: bool, unified_code: string, unified_message: string, error_category: record, clear_pan_possible: bool, feature: string, feature_data: any, standardised_code: record, description: string, user_guidance_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gsm/update")
  let body = {connector: $connector, flow: $flow, sub_flow: $sub_flow, code: $code, message: $message, status: $status, router_error: $router_error, decision: $decision, step_up_possible: $step_up_possible, unified_code: $unified_code, unified_message: $unified_message, error_category: $error_category, clear_pan_possible: $clear_pan_possible, feature: $feature, feature_data: $feature_data, standardised_code: $standardised_code, description: $description, user_guidance_message: $user_guidance_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gsm - Delete
#
# POST /gsm/delete
# operationId: Delete Gsm Rule
export def "gsm-delete Delete-Gsm-Rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector: string # The connector through which payment has gone through
  flow: string # The flow in which the code and message occurred for a connector
  sub_flow: string # The sub_flow in which the code and message occurred  for a connector
  code: string # code received from the connector
  message: string # message received from the connector
]: any -> record<gsm_rule_delete: bool, connector: string, flow: string, sub_flow: string, code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gsm/delete")
  let body = {connector: $connector, flow: $flow, sub_flow: $sub_flow, code: $code, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mandates - Retrieve Mandate
#
# GET /mandates/{mandate_id}
# operationId: Retrieve a Mandate
export def "mandates Retrieve-a-Mandate" [
  mandate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<mandate_id: string, status: string, payment_method_id: string, payment_method: string, payment_method_type: string, card: record<last4_digits: string, card_exp_month: string, card_exp_year: string, card_holder_name: string, card_token: string, scheme: string, issuer_country: string, card_fingerprint: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, nick_name: string>, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record<ip_address: string, user_agent: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mandates/($mandate_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mandates - Revoke Mandate
#
# POST /mandates/revoke/{mandate_id}
# operationId: Revoke a Mandate
export def "mandates-revoke Revoke-a-Mandate" [
  mandate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<mandate_id: string, status: string, error_code: string, error_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mandates/revoke/($mandate_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mandates - Customer Mandates List
#
# GET /customers/{customer_id}/mandates
# operationId: List Mandates for a Customer
export def "customers-mandates List-Mandates-for-a-Customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<mandate_id: string, status: string, payment_method_id: string, payment_method: string, payment_method_type: string, card: record<last4_digits: string, card_exp_month: string, card_exp_year: string, card_holder_name: string, card_token: string, scheme: string, issuer_country: string, card_fingerprint: string, card_isin: string, card_issuer: string, card_network: record, card_type: string, nick_name: string>, customer_acceptance: record<acceptance_type: string, accepted_at: string, online: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/mandates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - Create
#
# POST /customers
# operationId: Create a Customer
export def "customers Create-a-Customer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customer-id: string # The identifier for the customer object. If not provided the customer ID will be autogenerated. (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --name: string # The customer's name (nullable, e.g. Jon Test)
  --email: string # The customer's email address (nullable, e.g. JonTest@test.com)
  --phone: string # The customer's phone number (nullable, e.g. 9123456789)
  --description: string # An arbitrary string that you can attach to a customer object. (nullable, e.g. First Customer)
  --phone-country-code: string # The country code for the customer phone number (nullable, e.g. +65)
  --address: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --tax-registration-id: string # Customer's tax registration ID (nullable, e.g. 123456789)
  --document-details: any # nullable
]: any -> record<customer_id: string, name: string, email: string, phone: string, phone_country_code: string, description: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers")
  let body = {customer_id: $customer_id, name: $name, email: $email, phone: $phone, description: $description, phone_country_code: $phone_country_code, address: $address, metadata: $metadata, tax_registration_id: $tax_registration_id, document_details: $document_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Customers - Retrieve
#
# GET /customers/{customer_id}
# operationId: Retrieve a Customer
export def "customers Retrieve-a-Customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customer_id: string, name: string, email: string, phone: string, phone_country_code: string, description: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - Update
#
# POST /customers/{customer_id}
# operationId: Update a Customer
export def "customers Update-a-Customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The customer's name (nullable, e.g. Jon Test)
  --email: string # The customer's email address (nullable, e.g. JonTest@test.com)
  --phone: string # The customer's phone number (nullable, e.g. 9123456789)
  --description: string # An arbitrary string that you can attach to a customer object. (nullable, e.g. First Customer)
  --phone-country-code: string # The country code for the customer phone number (nullable, e.g. +65)
  --address: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --tax-registration-id: string # Customer's tax registration ID (nullable, e.g. 123456789)
  --document-details: any # nullable
]: any -> record<customer_id: string, name: string, email: string, phone: string, phone_country_code: string, description: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)")
  let body = {name: $name, email: $email, phone: $phone, description: $description, phone_country_code: $phone_country_code, address: $address, metadata: $metadata, tax_registration_id: $tax_registration_id, document_details: $document_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Customers - Delete
#
# DELETE /customers/{customer_id}
# operationId: Delete a Customer
export def "customers Delete-a-Customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customer_id: string, customer_deleted: bool, address_deleted: bool, payment_methods_deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Customers - List
#
# GET /customers/list
# operationId: List all Customers for a Merchant
export def "customers-list List-all-Customers-for-a-Merchant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Offset for pagination (nullable, format: int32)
  --limit: int # Limit for pagination (nullable, format: int32)
]: nothing -> table<customer_id: string, name: string, email: string, phone: string, phone_country_code: string, description: string, address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, created_at: string, metadata: record, default_payment_method_id: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PaymentMethods - Create
#
# POST /payment_methods
# operationId: Create a Payment Method
export def "payment-methods Create-a-Payment-Method" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_method: string@payment-method-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-type: any # nullable
  --payment-method-issuer: string # The name of the bank/ provider issuing the payment method to the end user (nullable, e.g. Citibank)
  --payment-method-issuer-code: any # nullable
  --card: any # nullable
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --customer-id: string # The unique identifier of the customer. (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --card-network: string # The card network (nullable, e.g. Visa)
  --bank-transfer: any # nullable
  --bank-transfer-data: any # nullable
  --wallet: any # nullable
  --client-secret: string # For Client based calls, SDK will use the client_secret in order to call /payment_methods Client secret will be generated whenever a new payment method is created (nullable)
  --payment-method-data: any # nullable
  --billing: any # nullable
]: any -> record<merchant_id: string, customer_id: string, payment_method_id: string, payment_method: string, payment_method_type: record, card: record<scheme: string, issuer_country: string, issuer_country_code: string, last4_digits: string, expiry_month: string, expiry_year: string, card_token: string, card_holder_name: string, card_fingerprint: string, nick_name: string, card_network: record, card_isin: string, card_issuer: string, card_type: string, saved_to_locker: bool>, recurring_enabled: bool, installment_payment_enabled: bool, payment_experience: list<string>, metadata: record, created: string, bank_transfer: record, last_used_at: string, client_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_methods")
  let body = {payment_method: $payment_method, payment_method_type: $payment_method_type, payment_method_issuer: $payment_method_issuer, payment_method_issuer_code: $payment_method_issuer_code, card: $card, metadata: $metadata, customer_id: $customer_id, card_network: $card_network, bank_transfer: $bank_transfer, bank_transfer_data: $bank_transfer_data, wallet: $wallet, client_secret: $client_secret, payment_method_data: $payment_method_data, billing: $billing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List payment methods for a Merchant
#
# GET /account/payment_methods
# operationId: List all Payment Methods for a Merchant
export def "account-payment-methods List-all-Payment-Methods-for-a-Merchant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-secret: string # This is a token which expires after 15 minutes, used from the client to authenticate and create sessions from the SDK (nullable)
  --accepted-countries: list # The two-letter ISO currency code (nullable)
  --accepted-currencies: list # The three-letter ISO currency code (nullable)
  --amount: int # The amount accepted for processing by the particular payment method. (nullable, format: int64)
  --recurring-enabled: string@bool-completer # Indicates whether the payment method is eligible for recurring payments (nullable)
  --installment-payment-enabled: string@bool-completer # Indicates whether the payment method is eligible for installment payments (nullable)
  --limit: int # Indicates the limit of last used payment methods (nullable, format: int64)
  --card-networks: list # Indicates whether the payment method is eligible for card netwotks (nullable)
]: nothing -> record<redirect_url: string, currency: string, payment_methods: table<payment_method: string, payment_method_types: list>, mandate_payment: any, merchant_name: string, show_surcharge_breakup_screen: bool, payment_type: record, request_external_three_ds_authentication: bool, collect_shipping_details_from_wallets: bool, collect_billing_details_from_wallets: bool, is_tax_calculation_enabled: bool, sdk_next_action: record<next_action: any, should_block_confirm: bool>, is_guest_customer: bool, intent_data: record<payment_id: string, status: string, amount: int, currency: record, client_secret: string, description: string, customer_id: string, return_url: string, setup_future_usage: record, billing: record<address: record, phone: record, email: string>, shipping: record<address: record, phone: record, email: string>, metadata: record, order_details: list<record>, created: string, expires_on: string, profile_id: string, merchant_order_reference_id: string, attempt_count: int, installment_options: list<record>, capture_method: record, merchant_name: string, mandate_payment: record<update_mandate_id: string, customer_acceptance: record, mandate_type: record>, payment_type: record, request_external_three_ds_authentication: bool, is_tax_calculation_enabled: bool, is_guest_customer: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "accepted_countries" $accepted_countries "multi") (serialize-qp "accepted_currencies" $accepted_currencies "multi") (serialize-qp "amount" $amount "scalar") (serialize-qp "recurring_enabled" $recurring_enabled "scalar") (serialize-qp "installment_payment_enabled" $installment_payment_enabled "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "card_networks" $card_networks "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/account/payment_methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List payment methods for a Customer
#
# GET /customers/{customer_id}/payment_methods
# operationId: List all Payment Methods for a Customer
export def "customers-payment-methods List-all-Payment-Methods-for-a-Customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-secret: string # This is a token which expires after 15 minutes, used from the client to authenticate and create sessions from the SDK (nullable)
  --accepted-countries: list # The two-letter ISO currency code (nullable)
  --accepted-currencies: list # The three-letter ISO currency code (nullable)
  --amount: int # The amount accepted for processing by the particular payment method. (nullable, format: int64)
  --recurring-enabled: string@bool-completer # Indicates whether the payment method is eligible for recurring payments (nullable)
  --installment-payment-enabled: string@bool-completer # Indicates whether the payment method is eligible for installment payments (nullable)
  --limit: int # Indicates the limit of last used payment methods (nullable, format: int64)
  --card-networks: list # Indicates whether the payment method is eligible for card netwotks (nullable)
]: nothing -> record<customer_payment_methods: table<payment_token: string, payment_method_id: string, customer_id: string, payment_method: string, payment_method_type: record, payment_method_issuer: string, payment_method_issuer_code: record, recurring_enabled: bool, installment_payment_enabled: bool, payment_experience: list, card: record, metadata: record, created: string, bank_transfer: record, bank: record, surcharge_details: record, requires_cvv: bool, last_used_at: string, default_payment_method_set: bool, billing: record>, is_guest_customer: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "accepted_countries" $accepted_countries "multi") (serialize-qp "accepted_currencies" $accepted_currencies "multi") (serialize-qp "amount" $amount "scalar") (serialize-qp "recurring_enabled" $recurring_enabled "scalar") (serialize-qp "installment_payment_enabled" $installment_payment_enabled "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "card_networks" $card_networks "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($customer_id)/payment_methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List customer saved payment methods for a Payment
#
# GET /customers/payment_methods
# operationId: List Customer Payment Methods via Client Secret
export def "customers-payment-methods List-Customer-Payment-Methods-via-Client-Secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-secret: string # This is a token which expires after 15 minutes, used from the client to authenticate and create sessions from the SDK (nullable)
  --accepted-countries: list # The two-letter ISO currency code (nullable)
  --accepted-currencies: list # The three-letter ISO currency code (nullable)
  --amount: int # The amount accepted for processing by the particular payment method. (nullable, format: int64)
  --recurring-enabled: string@bool-completer # Indicates whether the payment method is eligible for recurring payments (nullable)
  --installment-payment-enabled: string@bool-completer # Indicates whether the payment method is eligible for installment payments (nullable)
  --limit: int # Indicates the limit of last used payment methods (nullable, format: int64)
  --card-networks: list # Indicates whether the payment method is eligible for card netwotks (nullable)
]: nothing -> record<customer_payment_methods: table<payment_token: string, payment_method_id: string, customer_id: string, payment_method: string, payment_method_type: record, payment_method_issuer: string, payment_method_issuer_code: record, recurring_enabled: bool, installment_payment_enabled: bool, payment_experience: list, card: record, metadata: record, created: string, bank_transfer: record, bank: record, surcharge_details: record, requires_cvv: bool, last_used_at: string, default_payment_method_set: bool, billing: record>, is_guest_customer: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "accepted_countries" $accepted_countries "multi") (serialize-qp "accepted_currencies" $accepted_currencies "multi") (serialize-qp "amount" $amount "scalar") (serialize-qp "recurring_enabled" $recurring_enabled "scalar") (serialize-qp "installment_payment_enabled" $installment_payment_enabled "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "card_networks" $card_networks "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/customers/payment_methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Set Default Payment Method for Customer
#
# POST /{customer_id}/payment_methods/{payment_method_id}/default
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
]: nothing -> record<default_payment_method_id: string, customer_id: string, payment_method: string, payment_method_type: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($customer_id)/payment_methods/($payment_method_id)/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Retrieve
#
# GET /payment_methods/{method_id}
# operationId: Retrieve a Payment method
export def "payment-methods Retrieve-a-Payment-method" [
  method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<merchant_id: string, customer_id: string, payment_method_id: string, payment_method: string, payment_method_type: record, card: record<scheme: string, issuer_country: string, issuer_country_code: string, last4_digits: string, expiry_month: string, expiry_year: string, card_token: string, card_holder_name: string, card_fingerprint: string, nick_name: string, card_network: record, card_isin: string, card_issuer: string, card_type: string, saved_to_locker: bool>, recurring_enabled: bool, installment_payment_enabled: bool, payment_experience: list<string>, metadata: record, created: string, bank_transfer: record, last_used_at: string, client_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($method_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Delete
#
# DELETE /payment_methods/{method_id}
# operationId: Delete a Payment method
export def "payment-methods Delete-a-Payment-method" [
  method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payment_method_id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($method_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Method - Update
#
# POST /payment_methods/{method_id}/update
# operationId: Update a Payment method
export def "payment-methods-update Update-a-Payment-method" [
  method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --card: any # nullable
  --wallet: any # nullable
  --client-secret: string # This is a 15 minute expiry token which shall be used from the client to authenticate and perform sessions from the SDK (nullable, e.g. secret_k2uj3he2893eiu2d)
]: any -> record<merchant_id: string, customer_id: string, payment_method_id: string, payment_method: string, payment_method_type: record, card: record<scheme: string, issuer_country: string, issuer_country_code: string, last4_digits: string, expiry_month: string, expiry_year: string, card_token: string, card_holder_name: string, card_fingerprint: string, nick_name: string, card_network: record, card_isin: string, card_issuer: string, card_type: string, saved_to_locker: bool>, recurring_enabled: bool, installment_payment_enabled: bool, payment_experience: list<string>, metadata: record, created: string, bank_transfer: record, last_used_at: string, client_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($method_id)/update")
  let body = {card: $card, wallet: $wallet, client_secret: $client_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Profile - Create
#
# POST /account/{account_id}/business_profile
# operationId: Create A Profile
export def "account-business-profile Create-A-Profile" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --profile-name: string # The name of profile (nullable)
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://www.example.com/success)
  --enable-payment-response-hash: string@bool-completer # A boolean value to indicate if payment response hash needs to be enabled (nullable, default: true, e.g. true)
  --payment-response-hash-key: string # Refers to the hash key used for calculating the signature for webhooks and redirect response. If the value is not provided, a value is automatically generated. (nullable)
  --redirect-to-merchant-with-http-post: string@bool-completer # A boolean value to indicate if redirect to merchant with http post needs to be enabled (nullable, default: false, e.g. true)
  --webhook-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --routing-algorithm: record # The routing algorithm to be used for routing payments to desired connectors (nullable)
  --intent-fulfillment-time: int # Will be used to determine the time till which your payment will be active once the payment session starts (nullable, format: int32, e.g. 900)
  --frm-routing-algorithm: record # The frm routing algorithm to be used for routing payments to desired FRM's (nullable)
  --payout-routing-algorithm: any # nullable
  --applepay-verified-domains: list # Verified Apple Pay domains for a particular profile (nullable)
  --session-expiry: int # Client Secret Default expiry for all payments created under this profile (nullable, format: int32, e.g. 900)
  --payment-link-config: any # nullable
  --authentication-connector-details: any # nullable
  --use-billing-as-payment-method-billing: string@bool-completer # Whether to use the billing details passed when creating the intent as payment method billing (nullable)
  --collect-shipping-details-from-wallet-connector: string@bool-completer # A boolean value to indicate if customer shipping details needs to be collected from wallet connector only if it is required field for connector (Eg. Apple Pay, Google Pay etc) (nullable, default: false, e.g. false)
  --collect-billing-details-from-wallet-connector: string@bool-completer # A boolean value to indicate if customer billing details needs to be collected from wallet connector only if it is required field for connector (Eg. Apple Pay, Google Pay etc) (nullable, default: false, e.g. false)
  --always-collect-shipping-details-from-wallet-connector: string@bool-completer # A boolean value to indicate if customer shipping details needs to be collected from wallet connector irrespective of connector required fields (Eg. Apple pay, Google pay etc) (nullable, default: false, e.g. false)
  --always-collect-billing-details-from-wallet-connector: string@bool-completer # A boolean value to indicate if customer billing details needs to be collected from wallet connector irrespective of connector required fields (Eg. Apple pay, Google pay etc) (nullable, default: false, e.g. false)
  --is-connector-agnostic-mit-enabled: string@bool-completer # Indicates if the MIT (merchant initiated transaction) payments can be made connector agnostic, i.e., MITs may be processed through different connector than CIT (customer initiated transaction) based on the routing rules. If set to `false`, MIT will go through the same connector as the CIT. (nullable)
  --payout-link-config: any # nullable
  --outgoing-webhook-custom-http-headers: record # These key-value pairs are sent as additional custom headers in the outgoing webhook request. It is recommended not to use more than four key-value pairs. (nullable)
  --tax-connector-id: string # Merchant Connector id to be stored for tax_calculator connector (nullable)
  --is-tax-connector-enabled: string@bool-completer # Indicates if tax_calculator connector is enabled or not. If set to `true` tax_connector_id will be checked.
  --is-network-tokenization-enabled: string@bool-completer # Indicates if network tokenization is enabled or not.
  --is-auto-retries-enabled: string@bool-completer # Indicates if is_auto_retries_enabled is enabled or not. (nullable)
  --max-auto-retries-enabled: int # Maximum number of auto retries allowed for a payment (nullable, format: int32)
  --always-request-extended-authorization: string@bool-completer # Bool indicating if extended authentication must be requested for all payments (nullable)
  --is-click-to-pay-enabled: string@bool-completer # Indicates if click to pay is enabled or not.
  --authentication-product-ids: record # Product authentication ids (nullable)
  --card-testing-guard-config: any # nullable
  --is-clear-pan-retries-enabled: string@bool-completer # Indicates if clear pan retries is enabled or not. (nullable)
  --force-3ds-challenge: string@bool-completer # Indicates if 3ds challenge is forced (nullable)
  --is-debit-routing-enabled: string@bool-completer # Indicates if debit routing is enabled or not (nullable)
  --merchant-business-country: any # nullable
  --is-iframe-redirection-enabled: string@bool-completer # Indicates if the redirection has to open in the iframe (nullable, e.g. false)
  --is-pre-network-tokenization-enabled: string@bool-completer # Indicates if pre network tokenization is enabled or not (nullable)
  --merchant-category-code: any # nullable
  --merchant-country-code: any # nullable
  --dispute-polling-interval: int # Time interval (in hours) for polling the connector to check  for new disputes (nullable, format: int32, e.g. 2)
  --is-manual-retry-enabled: string@bool-completer # Indicates if manual retry for payment is enabled or not (nullable)
  --always-enable-overcapture: string@bool-completer # Bool indicating if overcapture  must be requested for all payments (nullable)
  --is-external-vault-enabled: any # nullable
  --external-vault-connector-details: any # nullable
  --billing-processor-id: string # Merchant Connector id to be stored for billing_processor connector (nullable)
  --surcharge-connector-details: any # nullable
  --is-l2-l3-enabled: string@bool-completer # Flag to enable Level 2 and Level 3 processing data for card transactions (nullable)
  --network-tokenization-credentials: any # nullable
  --payment-method-blocking: any # nullable
]: any -> record<merchant_id: string, profile_id: string, profile_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, metadata: record, routing_algorithm: record, intent_fulfillment_time: int, frm_routing_algorithm: record, payout_routing_algorithm: record, applepay_verified_domains: list<string>, session_expiry: int, payment_link_config: record, authentication_connector_details: record<authentication_connectors: list<string>, three_ds_requestor_url: string, three_ds_requestor_app_url: string>, use_billing_as_payment_method_billing: bool, extended_card_info_config: record<public_key: string, ttl_in_secs: int>, collect_shipping_details_from_wallet_connector: bool, collect_billing_details_from_wallet_connector: bool, always_collect_shipping_details_from_wallet_connector: bool, always_collect_billing_details_from_wallet_connector: bool, is_connector_agnostic_mit_enabled: bool, payout_link_config: record, outgoing_webhook_custom_http_headers: record, tax_connector_id: string, is_tax_connector_enabled: bool, is_network_tokenization_enabled: bool, is_auto_retries_enabled: bool, max_auto_retries_enabled: int, always_request_extended_authorization: bool, is_click_to_pay_enabled: bool, authentication_product_ids: record, card_testing_guard_config: record<card_ip_blocking_status: string, card_ip_blocking_threshold: int, guest_user_card_blocking_status: string, guest_user_card_blocking_threshold: int, customer_id_blocking_status: string, customer_id_blocking_threshold: int, card_testing_guard_expiry: int>, is_clear_pan_retries_enabled: bool, force_3ds_challenge: bool, is_debit_routing_enabled: bool, merchant_business_country: record, is_pre_network_tokenization_enabled: bool, acquirer_configs: table<profile_acquirer_id: string, acquirer_assigned_merchant_id: string, merchant_name: string, network: string, acquirer_bin: string, acquirer_ica: string, acquirer_fraud_rate: float, acquirer_country_code: string, profile_id: string, is_default: bool>, acquirer_config_bucket: record<default_acquirer_config: string, configs: record>, is_iframe_redirection_enabled: bool, merchant_category_code: record, merchant_country_code: record, dispute_polling_interval: int, is_manual_retry_enabled: bool, always_enable_overcapture: bool, is_external_vault_enabled: record, external_vault_connector_details: record<vault_connector_id: string, vault_sdk: record, vault_token_selector: list<record>>, billing_processor_id: string, surcharge_connector_details: record<surcharge_connector_id: string>, is_l2_l3_enabled: bool, network_tokenization_credentials: record, payment_method_blocking: record<card: record<issuing_country: list, card_types: list, card_subtypes: list, issuers: list, block_if_bin_info_unavailable: bool>, wallet: record<card_types: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/business_profile")
  let body = {profile_name: $profile_name, return_url: $return_url, enable_payment_response_hash: $enable_payment_response_hash, payment_response_hash_key: $payment_response_hash_key, redirect_to_merchant_with_http_post: $redirect_to_merchant_with_http_post, webhook_details: $webhook_details, metadata: $metadata, routing_algorithm: $routing_algorithm, intent_fulfillment_time: $intent_fulfillment_time, frm_routing_algorithm: $frm_routing_algorithm, payout_routing_algorithm: $payout_routing_algorithm, applepay_verified_domains: $applepay_verified_domains, session_expiry: $session_expiry, payment_link_config: $payment_link_config, authentication_connector_details: $authentication_connector_details, use_billing_as_payment_method_billing: $use_billing_as_payment_method_billing, collect_shipping_details_from_wallet_connector: $collect_shipping_details_from_wallet_connector, collect_billing_details_from_wallet_connector: $collect_billing_details_from_wallet_connector, always_collect_shipping_details_from_wallet_connector: $always_collect_shipping_details_from_wallet_connector, always_collect_billing_details_from_wallet_connector: $always_collect_billing_details_from_wallet_connector, is_connector_agnostic_mit_enabled: $is_connector_agnostic_mit_enabled, payout_link_config: $payout_link_config, outgoing_webhook_custom_http_headers: $outgoing_webhook_custom_http_headers, tax_connector_id: $tax_connector_id, is_tax_connector_enabled: $is_tax_connector_enabled, is_network_tokenization_enabled: $is_network_tokenization_enabled, is_auto_retries_enabled: $is_auto_retries_enabled, max_auto_retries_enabled: $max_auto_retries_enabled, always_request_extended_authorization: $always_request_extended_authorization, is_click_to_pay_enabled: $is_click_to_pay_enabled, authentication_product_ids: $authentication_product_ids, card_testing_guard_config: $card_testing_guard_config, is_clear_pan_retries_enabled: $is_clear_pan_retries_enabled, force_3ds_challenge: $force_3ds_challenge, is_debit_routing_enabled: $is_debit_routing_enabled, merchant_business_country: $merchant_business_country, is_iframe_redirection_enabled: $is_iframe_redirection_enabled, is_pre_network_tokenization_enabled: $is_pre_network_tokenization_enabled, merchant_category_code: $merchant_category_code, merchant_country_code: $merchant_country_code, dispute_polling_interval: $dispute_polling_interval, is_manual_retry_enabled: $is_manual_retry_enabled, always_enable_overcapture: $always_enable_overcapture, is_external_vault_enabled: $is_external_vault_enabled, external_vault_connector_details: $external_vault_connector_details, billing_processor_id: $billing_processor_id, surcharge_connector_details: $surcharge_connector_details, is_l2_l3_enabled: $is_l2_l3_enabled, network_tokenization_credentials: $network_tokenization_credentials, payment_method_blocking: $payment_method_blocking} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Profile - List
#
# GET /account/{account_id}/business_profile
# operationId: List Profiles
export def "account-business-profile List-Profiles" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<merchant_id: string, profile_id: string, profile_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list, refund_statuses_enabled: list, payout_statuses_enabled: list>, metadata: record, routing_algorithm: record, intent_fulfillment_time: int, frm_routing_algorithm: record, payout_routing_algorithm: record, applepay_verified_domains: list<string>, session_expiry: int, payment_link_config: record, authentication_connector_details: record<authentication_connectors: list, three_ds_requestor_url: string, three_ds_requestor_app_url: string>, use_billing_as_payment_method_billing: bool, extended_card_info_config: record<public_key: string, ttl_in_secs: int>, collect_shipping_details_from_wallet_connector: bool, collect_billing_details_from_wallet_connector: bool, always_collect_shipping_details_from_wallet_connector: bool, always_collect_billing_details_from_wallet_connector: bool, is_connector_agnostic_mit_enabled: bool, payout_link_config: record, outgoing_webhook_custom_http_headers: record, tax_connector_id: string, is_tax_connector_enabled: bool, is_network_tokenization_enabled: bool, is_auto_retries_enabled: bool, max_auto_retries_enabled: int, always_request_extended_authorization: bool, is_click_to_pay_enabled: bool, authentication_product_ids: record, card_testing_guard_config: record<card_ip_blocking_status: string, card_ip_blocking_threshold: int, guest_user_card_blocking_status: string, guest_user_card_blocking_threshold: int, customer_id_blocking_status: string, customer_id_blocking_threshold: int, card_testing_guard_expiry: int>, is_clear_pan_retries_enabled: bool, force_3ds_challenge: bool, is_debit_routing_enabled: bool, merchant_business_country: record, is_pre_network_tokenization_enabled: bool, acquirer_configs: list<record>, acquirer_config_bucket: record<default_acquirer_config: string, configs: record>, is_iframe_redirection_enabled: bool, merchant_category_code: record, merchant_country_code: record, dispute_polling_interval: int, is_manual_retry_enabled: bool, always_enable_overcapture: bool, is_external_vault_enabled: record, external_vault_connector_details: record<vault_connector_id: string, vault_sdk: record, vault_token_selector: list>, billing_processor_id: string, surcharge_connector_details: record<surcharge_connector_id: string>, is_l2_l3_enabled: bool, network_tokenization_credentials: record, payment_method_blocking: record<card: record, wallet: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/business_profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Profile - Retrieve
#
# GET /account/{account_id}/business_profile/{profile_id}
# operationId: Retrieve a Profile
export def "account-business-profile Retrieve-a-Profile" [
  account_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<merchant_id: string, profile_id: string, profile_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, metadata: record, routing_algorithm: record, intent_fulfillment_time: int, frm_routing_algorithm: record, payout_routing_algorithm: record, applepay_verified_domains: list<string>, session_expiry: int, payment_link_config: record, authentication_connector_details: record<authentication_connectors: list<string>, three_ds_requestor_url: string, three_ds_requestor_app_url: string>, use_billing_as_payment_method_billing: bool, extended_card_info_config: record<public_key: string, ttl_in_secs: int>, collect_shipping_details_from_wallet_connector: bool, collect_billing_details_from_wallet_connector: bool, always_collect_shipping_details_from_wallet_connector: bool, always_collect_billing_details_from_wallet_connector: bool, is_connector_agnostic_mit_enabled: bool, payout_link_config: record, outgoing_webhook_custom_http_headers: record, tax_connector_id: string, is_tax_connector_enabled: bool, is_network_tokenization_enabled: bool, is_auto_retries_enabled: bool, max_auto_retries_enabled: int, always_request_extended_authorization: bool, is_click_to_pay_enabled: bool, authentication_product_ids: record, card_testing_guard_config: record<card_ip_blocking_status: string, card_ip_blocking_threshold: int, guest_user_card_blocking_status: string, guest_user_card_blocking_threshold: int, customer_id_blocking_status: string, customer_id_blocking_threshold: int, card_testing_guard_expiry: int>, is_clear_pan_retries_enabled: bool, force_3ds_challenge: bool, is_debit_routing_enabled: bool, merchant_business_country: record, is_pre_network_tokenization_enabled: bool, acquirer_configs: table<profile_acquirer_id: string, acquirer_assigned_merchant_id: string, merchant_name: string, network: string, acquirer_bin: string, acquirer_ica: string, acquirer_fraud_rate: float, acquirer_country_code: string, profile_id: string, is_default: bool>, acquirer_config_bucket: record<default_acquirer_config: string, configs: record>, is_iframe_redirection_enabled: bool, merchant_category_code: record, merchant_country_code: record, dispute_polling_interval: int, is_manual_retry_enabled: bool, always_enable_overcapture: bool, is_external_vault_enabled: record, external_vault_connector_details: record<vault_connector_id: string, vault_sdk: record, vault_token_selector: list<record>>, billing_processor_id: string, surcharge_connector_details: record<surcharge_connector_id: string>, is_l2_l3_enabled: bool, network_tokenization_credentials: record, payment_method_blocking: record<card: record<issuing_country: list, card_types: list, card_subtypes: list, issuers: list, block_if_bin_info_unavailable: bool>, wallet: record<card_types: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Profile - Update
#
# POST /account/{account_id}/business_profile/{profile_id}
# operationId: Update a Profile
export def "account-business-profile Update-a-Profile" [
  account_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --profile-name: string # The name of profile (nullable)
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://www.example.com/success)
  --enable-payment-response-hash: string@bool-completer # A boolean value to indicate if payment response hash needs to be enabled (nullable, default: true, e.g. true)
  --payment-response-hash-key: string # Refers to the hash key used for calculating the signature for webhooks and redirect response. If the value is not provided, a value is automatically generated. (nullable)
  --redirect-to-merchant-with-http-post: string@bool-completer # A boolean value to indicate if redirect to merchant with http post needs to be enabled (nullable, default: false, e.g. true)
  --webhook-details: any # nullable
  --metadata: record # Metadata is useful for storing additional, unstructured information on an object. (nullable)
  --routing-algorithm: record # The routing algorithm to be used for routing payments to desired connectors (nullable)
  --intent-fulfillment-time: int # Will be used to determine the time till which your payment will be active once the payment session starts (nullable, format: int32, e.g. 900)
  --frm-routing-algorithm: record # The frm routing algorithm to be used for routing payments to desired FRM's (nullable)
  --payout-routing-algorithm: any # nullable
  --applepay-verified-domains: list # Verified Apple Pay domains for a particular profile (nullable)
  --session-expiry: int # Client Secret Default expiry for all payments created under this profile (nullable, format: int32, e.g. 900)
  --payment-link-config: any # nullable
  --authentication-connector-details: any # nullable
  --use-billing-as-payment-method-billing: string@bool-completer # Whether to use the billing details passed when creating the intent as payment method billing (nullable)
  --collect-shipping-details-from-wallet-connector: string@bool-completer # A boolean value to indicate if customer shipping details needs to be collected from wallet connector only if it is required field for connector (Eg. Apple Pay, Google Pay etc) (nullable, default: false, e.g. false)
  --collect-billing-details-from-wallet-connector: string@bool-completer # A boolean value to indicate if customer billing details needs to be collected from wallet connector only if it is required field for connector (Eg. Apple Pay, Google Pay etc) (nullable, default: false, e.g. false)
  --always-collect-shipping-details-from-wallet-connector: string@bool-completer # A boolean value to indicate if customer shipping details needs to be collected from wallet connector irrespective of connector required fields (Eg. Apple pay, Google pay etc) (nullable, default: false, e.g. false)
  --always-collect-billing-details-from-wallet-connector: string@bool-completer # A boolean value to indicate if customer billing details needs to be collected from wallet connector irrespective of connector required fields (Eg. Apple pay, Google pay etc) (nullable, default: false, e.g. false)
  --is-connector-agnostic-mit-enabled: string@bool-completer # Indicates if the MIT (merchant initiated transaction) payments can be made connector agnostic, i.e., MITs may be processed through different connector than CIT (customer initiated transaction) based on the routing rules. If set to `false`, MIT will go through the same connector as the CIT. (nullable)
  --payout-link-config: any # nullable
  --outgoing-webhook-custom-http-headers: record # These key-value pairs are sent as additional custom headers in the outgoing webhook request. It is recommended not to use more than four key-value pairs. (nullable)
  --tax-connector-id: string # Merchant Connector id to be stored for tax_calculator connector (nullable)
  --is-tax-connector-enabled: string@bool-completer # Indicates if tax_calculator connector is enabled or not. If set to `true` tax_connector_id will be checked.
  --is-network-tokenization-enabled: string@bool-completer # Indicates if network tokenization is enabled or not.
  --is-auto-retries-enabled: string@bool-completer # Indicates if is_auto_retries_enabled is enabled or not. (nullable)
  --max-auto-retries-enabled: int # Maximum number of auto retries allowed for a payment (nullable, format: int32)
  --always-request-extended-authorization: string@bool-completer # Bool indicating if extended authentication must be requested for all payments (nullable)
  --is-click-to-pay-enabled: string@bool-completer # Indicates if click to pay is enabled or not.
  --authentication-product-ids: record # Product authentication ids (nullable)
  --card-testing-guard-config: any # nullable
  --is-clear-pan-retries-enabled: string@bool-completer # Indicates if clear pan retries is enabled or not. (nullable)
  --force-3ds-challenge: string@bool-completer # Indicates if 3ds challenge is forced (nullable)
  --is-debit-routing-enabled: string@bool-completer # Indicates if debit routing is enabled or not (nullable)
  --merchant-business-country: any # nullable
  --is-iframe-redirection-enabled: string@bool-completer # Indicates if the redirection has to open in the iframe (nullable, e.g. false)
  --is-pre-network-tokenization-enabled: string@bool-completer # Indicates if pre network tokenization is enabled or not (nullable)
  --merchant-category-code: any # nullable
  --merchant-country-code: any # nullable
  --dispute-polling-interval: int # Time interval (in hours) for polling the connector to check  for new disputes (nullable, format: int32, e.g. 2)
  --is-manual-retry-enabled: string@bool-completer # Indicates if manual retry for payment is enabled or not (nullable)
  --always-enable-overcapture: string@bool-completer # Bool indicating if overcapture  must be requested for all payments (nullable)
  --is-external-vault-enabled: any # nullable
  --external-vault-connector-details: any # nullable
  --billing-processor-id: string # Merchant Connector id to be stored for billing_processor connector (nullable)
  --surcharge-connector-details: any # nullable
  --is-l2-l3-enabled: string@bool-completer # Flag to enable Level 2 and Level 3 processing data for card transactions (nullable)
  --network-tokenization-credentials: any # nullable
  --payment-method-blocking: any # nullable
]: any -> record<merchant_id: string, profile_id: string, profile_name: string, return_url: string, enable_payment_response_hash: bool, payment_response_hash_key: string, redirect_to_merchant_with_http_post: bool, webhook_details: record<webhook_version: string, webhook_username: string, webhook_password: string, webhook_url: string, payment_created_enabled: bool, payment_succeeded_enabled: bool, payment_failed_enabled: bool, payment_statuses_enabled: list<string>, refund_statuses_enabled: list<string>, payout_statuses_enabled: list<string>>, metadata: record, routing_algorithm: record, intent_fulfillment_time: int, frm_routing_algorithm: record, payout_routing_algorithm: record, applepay_verified_domains: list<string>, session_expiry: int, payment_link_config: record, authentication_connector_details: record<authentication_connectors: list<string>, three_ds_requestor_url: string, three_ds_requestor_app_url: string>, use_billing_as_payment_method_billing: bool, extended_card_info_config: record<public_key: string, ttl_in_secs: int>, collect_shipping_details_from_wallet_connector: bool, collect_billing_details_from_wallet_connector: bool, always_collect_shipping_details_from_wallet_connector: bool, always_collect_billing_details_from_wallet_connector: bool, is_connector_agnostic_mit_enabled: bool, payout_link_config: record, outgoing_webhook_custom_http_headers: record, tax_connector_id: string, is_tax_connector_enabled: bool, is_network_tokenization_enabled: bool, is_auto_retries_enabled: bool, max_auto_retries_enabled: int, always_request_extended_authorization: bool, is_click_to_pay_enabled: bool, authentication_product_ids: record, card_testing_guard_config: record<card_ip_blocking_status: string, card_ip_blocking_threshold: int, guest_user_card_blocking_status: string, guest_user_card_blocking_threshold: int, customer_id_blocking_status: string, customer_id_blocking_threshold: int, card_testing_guard_expiry: int>, is_clear_pan_retries_enabled: bool, force_3ds_challenge: bool, is_debit_routing_enabled: bool, merchant_business_country: record, is_pre_network_tokenization_enabled: bool, acquirer_configs: table<profile_acquirer_id: string, acquirer_assigned_merchant_id: string, merchant_name: string, network: string, acquirer_bin: string, acquirer_ica: string, acquirer_fraud_rate: float, acquirer_country_code: string, profile_id: string, is_default: bool>, acquirer_config_bucket: record<default_acquirer_config: string, configs: record>, is_iframe_redirection_enabled: bool, merchant_category_code: record, merchant_country_code: record, dispute_polling_interval: int, is_manual_retry_enabled: bool, always_enable_overcapture: bool, is_external_vault_enabled: record, external_vault_connector_details: record<vault_connector_id: string, vault_sdk: record, vault_token_selector: list<record>>, billing_processor_id: string, surcharge_connector_details: record<surcharge_connector_id: string>, is_l2_l3_enabled: bool, network_tokenization_credentials: record, payment_method_blocking: record<card: record<issuing_country: list, card_types: list, card_subtypes: list, issuers: list, block_if_bin_info_unavailable: bool>, wallet: record<card_types: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)")
  let body = {profile_name: $profile_name, return_url: $return_url, enable_payment_response_hash: $enable_payment_response_hash, payment_response_hash_key: $payment_response_hash_key, redirect_to_merchant_with_http_post: $redirect_to_merchant_with_http_post, webhook_details: $webhook_details, metadata: $metadata, routing_algorithm: $routing_algorithm, intent_fulfillment_time: $intent_fulfillment_time, frm_routing_algorithm: $frm_routing_algorithm, payout_routing_algorithm: $payout_routing_algorithm, applepay_verified_domains: $applepay_verified_domains, session_expiry: $session_expiry, payment_link_config: $payment_link_config, authentication_connector_details: $authentication_connector_details, use_billing_as_payment_method_billing: $use_billing_as_payment_method_billing, collect_shipping_details_from_wallet_connector: $collect_shipping_details_from_wallet_connector, collect_billing_details_from_wallet_connector: $collect_billing_details_from_wallet_connector, always_collect_shipping_details_from_wallet_connector: $always_collect_shipping_details_from_wallet_connector, always_collect_billing_details_from_wallet_connector: $always_collect_billing_details_from_wallet_connector, is_connector_agnostic_mit_enabled: $is_connector_agnostic_mit_enabled, payout_link_config: $payout_link_config, outgoing_webhook_custom_http_headers: $outgoing_webhook_custom_http_headers, tax_connector_id: $tax_connector_id, is_tax_connector_enabled: $is_tax_connector_enabled, is_network_tokenization_enabled: $is_network_tokenization_enabled, is_auto_retries_enabled: $is_auto_retries_enabled, max_auto_retries_enabled: $max_auto_retries_enabled, always_request_extended_authorization: $always_request_extended_authorization, is_click_to_pay_enabled: $is_click_to_pay_enabled, authentication_product_ids: $authentication_product_ids, card_testing_guard_config: $card_testing_guard_config, is_clear_pan_retries_enabled: $is_clear_pan_retries_enabled, force_3ds_challenge: $force_3ds_challenge, is_debit_routing_enabled: $is_debit_routing_enabled, merchant_business_country: $merchant_business_country, is_iframe_redirection_enabled: $is_iframe_redirection_enabled, is_pre_network_tokenization_enabled: $is_pre_network_tokenization_enabled, merchant_category_code: $merchant_category_code, merchant_country_code: $merchant_country_code, dispute_polling_interval: $dispute_polling_interval, is_manual_retry_enabled: $is_manual_retry_enabled, always_enable_overcapture: $always_enable_overcapture, is_external_vault_enabled: $is_external_vault_enabled, external_vault_connector_details: $external_vault_connector_details, billing_processor_id: $billing_processor_id, surcharge_connector_details: $surcharge_connector_details, is_l2_l3_enabled: $is_l2_l3_enabled, network_tokenization_credentials: $network_tokenization_credentials, payment_method_blocking: $payment_method_blocking} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Profile - Delete
#
# DELETE /account/{account_id}/business_profile/{profile_id}
# operationId: Delete the Profile
export def "account-business-profile Delete-the-Profile" [
  account_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disputes - Retrieve Dispute
#
# GET /disputes/{dispute_id}
# operationId: Retrieve a Dispute
export def "disputes Retrieve-a-Dispute" [
  dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-sync: string@bool-completer # Decider to enable or disable the connector call for dispute retrieve request (nullable)
]: nothing -> record<dispute_id: string, payment_id: string, attempt_id: string, amount: string, currency: string, dispute_stage: string, dispute_status: string, connector: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string, profile_id: string, merchant_connector_id: string, is_already_refunded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_sync" $force_sync "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/disputes/($dispute_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disputes - List Disputes
#
# GET /disputes/list
# operationId: List Disputes
export def "disputes-list List-Disputes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of Dispute Objects to include in the response (nullable, format: int64)
  --dispute-status: string # The status of dispute (nullable)
  --dispute-stage: string # The stage of dispute (nullable)
  --reason: string # The reason for dispute (nullable)
  --connector: string # The connector linked to dispute (nullable)
  --received-time: string # The time at which dispute is received (nullable, format: date-time)
  --received-timelt: string # Time less than the dispute received time (nullable, format: date-time)
  --received-timegt: string # Time greater than the dispute received time (nullable, format: date-time)
  --received-timelte: string # Time less than or equals to the dispute received time (nullable, format: date-time)
  --received-timegte: string # Time greater than or equals to the dispute received time (nullable, format: date-time)
]: nothing -> table<dispute_id: string, payment_id: string, attempt_id: string, amount: string, currency: string, dispute_stage: string, dispute_status: string, connector: string, connector_status: string, connector_dispute_id: string, connector_reason: string, connector_reason_code: string, challenge_required_by: string, connector_created_at: string, connector_updated_at: string, created_at: string, profile_id: string, merchant_connector_id: string, is_already_refunded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "dispute_status" $dispute_status "scalar") (serialize-qp "dispute_stage" $dispute_stage "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "connector" $connector "scalar") (serialize-qp "received_time" $received_time "scalar") (serialize-qp "received_time.lt" $received_timelt "scalar") (serialize-qp "received_time.gt" $received_timegt "scalar") (serialize-qp "received_time.lte" $received_timelte "scalar") (serialize-qp "received_time.gte" $received_timegte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/disputes/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Create
#
# POST /routing
# operationId: Create a routing config
export def "routing Create-a-routing-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Unique name of the routing configuration.  This identifier is used to reference the routing config internally.  Example: ```json "default_card_routing" ``` (nullable, e.g. default_card_routing)
  --description: string # Optional human-readable description of the routing configuration.  Example: ```json "Primary routing strategy for card payments in India" ``` (nullable, e.g. Primary routing strategy for card payments in Middle east)
  --algorithm: any # nullable
  --profile-id: string # Profile ID associated with this routing configuration.  Routing configs can be scoped per business profile.  Example: ```json "profile_123" ``` (nullable, e.g. profile_123)
  --transaction-type: any # nullable
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing")
  let body = {name: $name, description: $description, algorithm: $algorithm, profile_id: $profile_id, transaction_type: $transaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - List
#
# GET /routing
# operationId: List routing configs
export def "routing List-routing-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of records to be returned (nullable, format: int32)
  --offset: int # The record offset from which to start gathering of results (nullable, format: int32)
  --profile-id: string # The unique identifier for a merchant profile (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "profile_id" $profile_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/routing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Activate config
#
# POST /routing/{routing_algorithm_id}/activate
# operationId: Activate a routing config
export def "routing-activate Activate-a-routing-config" [
  routing_algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/routing/($routing_algorithm_id)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Retrieve
#
# GET /routing/{routing_algorithm_id}
# operationId: Retrieve a routing config
export def "routing Retrieve-a-routing-config" [
  routing_algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, profile_id: string, name: string, description: string, algorithm: any, created_at: int, modified_at: int, algorithm_for: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/routing/($routing_algorithm_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Deactivate
#
# POST /routing/deactivate
# operationId: Deactivate a routing config
export def "routing-deactivate Deactivate-a-routing-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Unique name of the routing configuration.  This identifier is used to reference the routing config internally.  Example: ```json "default_card_routing" ``` (nullable, e.g. default_card_routing)
  --description: string # Optional human-readable description of the routing configuration.  Example: ```json "Primary routing strategy for card payments in India" ``` (nullable, e.g. Primary routing strategy for card payments in Middle east)
  --algorithm: any # nullable
  --profile-id: string # Profile ID associated with this routing configuration.  Routing configs can be scoped per business profile.  Example: ```json "profile_123" ``` (nullable, e.g. profile_123)
  --transaction-type: any # nullable
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing/deactivate")
  let body = {name: $name, description: $description, algorithm: $algorithm, profile_id: $profile_id, transaction_type: $transaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Update Default Config
#
# POST /routing/default
# operationId: Update default fallback config
export def "routing-default Update-default-fallback-config" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing/default")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Retrieve Default Config
#
# GET /routing/default
# operationId: Retrieve default fallback config
export def "routing-default Retrieve-default-fallback-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<connector: string, merchant_connector_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Retrieve Config
#
# GET /routing/active
# operationId: Retrieve active config
export def "routing-active Retrieve-active-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --profile-id: string # The unique identifier for a merchant profile (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile_id" $profile_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/routing/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Retrieve Default For Profile
#
# GET /routing/default/profile
# operationId: Retrieve default configs for all profiles
export def "routing-default-profile Retrieve-default-configs-for-all-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<profile_id: string, connectors: table<connector: string, merchant_connector_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing/default/profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Update Default For Profile
#
# POST /routing/default/profile/{profile_id}
# operationId: Update default configs for all profiles
export def "routing-default-profile Update-default-configs-for-all-profiles" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<profile_id: string, connectors: table<connector: string, merchant_connector_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/routing/default/profile/($profile_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Update success based dynamic routing config for profile
#
# PATCH /account/{account_id}/business_profile/{profile_id}/dynamic_routing/success_based/config/{algorithm_id}
# operationId: Update success based dynamic routing configs
# --decision_engine_configs shape: {defaultLatencyThreshold?: float, defaultBucketSize?: int, defaultHedgingPercent?: float, defaultLowerResetFactor?: float, defaultUpperResetFactor?: float, defaultGatewayExtraScore?: list, subLevelInputConfig?: list}
@deprecated --flag params
export def "account-business-profile-dynamic-routing-success-based-config Update-success-based-dynamic-routing-configs" [
  account_id: string
  profile_id: string
  algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --params: list # DEPRECATED, nullable
  --config: any # nullable
  decision_engine_configs: record # Configuration for Decision Engine success rate based routing — shape: {defaultLatencyThreshold?: float, defaultBucketSize?: int, defaultHedgingPercent?: float, defaultLowerResetFactor?: float, defaultUpperResetFactor?: float, defaultGatewayExtraScore?: list, subLevelInputConfig?: list}
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)/dynamic_routing/success_based/config/($algorithm_id)")
  let body = {params: $params, config: $config, decision_engine_configs: $decision_engine_configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Toggle success based dynamic routing for profile
#
# POST /account/{account_id}/business_profile/{profile_id}/dynamic_routing/success_based/toggle
# operationId: Toggle success based dynamic routing algorithm
export def "account-business-profile-dynamic-routing-success-based-toggle Toggle-success-based-dynamic-routing-algorithm" [
  account_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable: string@enable-completer # Feature to enable for success based routing
]: nothing -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable" $enable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)/dynamic_routing/success_based/toggle" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Toggle elimination routing for profile
#
# POST /account/{account_id}/business_profile/{profile_id}/dynamic_routing/elimination/toggle
# operationId: Toggle elimination routing algorithm
export def "account-business-profile-dynamic-routing-elimination-toggle Toggle-elimination-routing-algorithm" [
  account_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable: string@enable-completer # Feature to enable for elimination based routing
]: nothing -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable" $enable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)/dynamic_routing/elimination/toggle" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routing - Auth Rate Based
#
# POST /account/{account_id}/business_profile/{profile_id}/dynamic_routing/success_based/create
# operationId: Create success based dynamic routing algorithm
# --decision_engine_configs shape: {defaultLatencyThreshold?: float, defaultBucketSize?: int, defaultHedgingPercent?: float, defaultLowerResetFactor?: float, defaultUpperResetFactor?: float, defaultGatewayExtraScore?: list, subLevelInputConfig?: list}
@deprecated --flag params
export def "account-business-profile-dynamic-routing-success-based-create Create-success-based-dynamic-routing-algorithm" [
  account_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable: string@enable-completer # Feature to enable for success based routing
  --params: list # DEPRECATED, nullable
  --config: any # nullable
  decision_engine_configs: record # Configuration for Decision Engine success rate based routing — shape: {defaultLatencyThreshold?: float, defaultBucketSize?: int, defaultHedgingPercent?: float, defaultLowerResetFactor?: float, defaultUpperResetFactor?: float, defaultGatewayExtraScore?: list, subLevelInputConfig?: list}
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable" $enable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)/dynamic_routing/success_based/create" $qp)
  let body = {params: $params, config: $config, decision_engine_configs: $decision_engine_configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Elimination
#
# POST /account/{account_id}/business_profile/{profile_id}/dynamic_routing/elimination/create
# operationId: Create elimination routing algorithm
# --decision_engine_configs shape: {threshold: float}
@deprecated --flag params
export def "account-business-profile-dynamic-routing-elimination-create Create-elimination-routing-algorithm" [
  account_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable: string@enable-completer # Feature to enable for elimination based routing
  --params: list # DEPRECATED, nullable
  --elimination-analyser-config: any # nullable
  decision_engine_configs: record # shape: {threshold: float}
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable" $enable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)/dynamic_routing/elimination/create" $qp)
  let body = {params: $params, elimination_analyser_config: $elimination_analyser_config, decision_engine_configs: $decision_engine_configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Toggle Contract routing for profile
#
# POST /account/{account_id}/business_profile/{profile_id}/dynamic_routing/contracts/toggle
# operationId: Toggle contract routing algorithm
# --label_info item shape: {label: string, target_count: int, target_time: int, mca_id: string}
export def "account-business-profile-dynamic-routing-contracts-toggle Toggle-contract-routing-algorithm" [
  account_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable: string@enable-completer # Feature to enable for contract based routing
  --config: any # nullable
  --label-info: list # nullable — item shape: {label: string, target_count: int, target_time: int, mca_id: string}
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable" $enable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)/dynamic_routing/contracts/toggle" $qp)
  let body = {config: $config, label_info: $label_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Update contract based dynamic routing config for profile
#
# PATCH /account/{account_id}/business_profile/{profile_id}/dynamic_routing/contracts/config/{algorithm_id}
# operationId: Update contract based dynamic routing configs
# --label_info item shape: {label: string, target_count: int, target_time: int, mca_id: string}
export def "account-business-profile-dynamic-routing-contracts-config Update-contract-based-dynamic-routing-configs" [
  account_id: string
  profile_id: string
  algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: any # nullable
  --label-info: list # nullable — item shape: {label: string, target_count: int, target_time: int, mca_id: string}
]: any -> record<id: string, profile_id: string, name: string, kind: string, description: string, created_at: int, modified_at: int, algorithm_for: record, decision_engine_routing_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($account_id)/business_profile/($profile_id)/dynamic_routing/contracts/config/($algorithm_id)")
  let body = {config: $config, label_info: $label_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Evaluate
#
# POST /routing/evaluate
# operationId: Evaluate routing rules
# --paymentInfo shape: {paymentId: string, amount: int, currency: string, paymentType: string, metadata: string, paymentMethodType: string, paymentMethod: string, cardIsin: string}
export def "routing-evaluate Evaluate-routing-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  paymentInfo: record # Payment information used for routing decision-making — shape: {paymentId: string, amount: int, currency: string, paymentType: string, metadata: string, paymentMethodType: string, paymentMethod: string, cardIsin: string}
  merchantId: string # Profile ID of the merchant (e.g. pro_aMoPnEkgCVnh2WVsFe32)
  --eligibleGatewayList: list # List of eligible gateways for routing consideration (nullable, e.g. ["stripe:mca_123", "adyen:mca_456"])
  --rankingAlgorithm: any # nullable
  --eliminationEnabled: string@bool-completer # Whether elimination logic is enabled for filtering gateways (nullable, e.g. true)
]: any -> record<decided_gateway: string, gateway_priority_map: record, filter_wise_gateways: record, priority_logic_tag: string, routing_approach: string, gateway_before_evaluation: string, priority_logic_output: record<isEnforcement: bool, gws: list<string>, priorityLogicTag: string, gatewayReferenceIds: record, primaryLogic: record<name: string, status: string, failure_reason: string>, fallbackLogic: record<name: string, status: string, failure_reason: string>>, reset_approach: string, routing_dimension: string, routing_dimension_level: string, is_scheduled_outage: bool, is_dynamic_mga_enabled: bool, gateway_mga_id_map: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing/evaluate")
  let body = {paymentInfo: $paymentInfo, merchantId: $merchantId, eligibleGatewayList: $eligibleGatewayList, rankingAlgorithm: $rankingAlgorithm, eliminationEnabled: $eliminationEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Feedback
#
# POST /routing/feedback
# operationId: Update gateway scores
export def "routing-feedback Update-gateway-scores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merchantId: string # Profile ID of the merchant (e.g. pro_aMoPnEkgCVnh2WVsFe32)
  gateway: string # Payment Gateway identifier (e.g. stripe:mca1)
  status: string@status-completer-1
  paymentId: string # Payment ID associated with the transaction (e.g. pay_1234)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing/feedback")
  let body = {merchantId: $merchantId, gateway: $gateway, status: $status, paymentId: $paymentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routing - Rule Evaluate
#
# POST /routing/rule/evaluate
# operationId: Evaluate routing rules (alternative)
# --fallback_output item shape: {gateway_name: "absa_sanlam"|"authipay"|"adyenplatform"|"stripe_billing_test"|"phonypay"|"fauxpay"|"pretendpay"|"stripe_test"|"adyen_test"|"checkout_test"|"paypal_test"|"aci"|"adyen"|"affirm"|"airwallex"|"amazonpay"|"archipel"|"authorizedotnet"|"bankofamerica"|"barclaycard"|"billwerk"|"bitpay"|"bambora"|"blackhawknetwork"|"bamboraapac"|"bluesnap"|"calida"|"boku"|"braintree"|"breadpay"|"cashtocode"|"celero"|"chargebee"|"custombilling"|"checkbook"|"checkout"|"coinbase"|"coingate"|"cryptopay"|"cybersource"|"cybersourcedecisionmanager"|"datatrans"|"deutschebank"|"digitalvirgo"|"dlocal"|"dwolla"|"ebanx"|"elavon"|"envoy"|"facilitapay"|"finix"|"fiserv"|"fiservemea"|"fiservcommercehub"|"fiuu"|"flexiti"|"forte"|"getnet"|"gigadat"|"globalpay"|"globepay"|"gocardless"|"hipay"|"helcim"|"hyperpg"|"iatapay"|"imerchantsolutions"|"inespay"|"interpayments"|"itaubank"|"jpmorgan"|"klarna"|"loonio"|"mifinity"|"mollie"|"moneris"|"multisafepay"|"nexinets"|"nexixpay"|"nmi"|"nomupay"|"noon"|"nordea"|"novalnet"|"nuvei"|"opennode"|"paybox"|"payme"|"payload"|"payone"|"paypal"|"paysafe"|"paystack"|"paytm"|"payconex"|"payu"|"peachpayments"|"payjustnow"|"payjustnowinstore"|"phonepe"|"placetopay"|"powertranz"|"prophetpay"|"rapyd"|"razorpay"|"recurly"|"redsys"|"revolv3"|"riskified"|"santander"|"shift4"|"signifyd"|"silverflow"|"square"|"stax"|"stripe"|"stripebilling"|"tesouro"|"truelayer"|"trustly"|"trustpay"|"trustpayments"|"tokenio"|"tsys"|"volt"|"wellsfargo"|"wise"|"worldline"|"worldpay"|"worldpaymodular"|"worldpayvantiv"|"worldpayxml"|"xendit"|"zen"|"zift"|"plaid"|"zsl"|"juspaythreedsserver"|"ctp_mastercard"|"ctp_visa"|"netcetera"|"cardinal"|"threedsecureio", gateway_id: string}
export def "routing-rule-evaluate Evaluate-routing-rules-alternative" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  created_by: string # Identifier of the user/system triggering routing evaluation.  Example: ```json "created_by": "some_id" ``` (e.g. profile_123)
  --payment-id: string # Payment ID for debugging and tracing routing decisions.  Example: ```json "payment_id": "pay_abc123" ``` (nullable, e.g. pay_abc123)
  parameters: record # Dynamic parameters used during routing evaluation.  Each key represents a routing attribute.  Example fields:  - `payment_method` - `payment_method_type` - `amount` - `currency` - `authentication_type` - `card_bin` - `capture_method` - `business_country` - `billing_country` - `business_label` - `setup_future_usage` - `card_network` - `payment_type` - `mandate_type` - `mandate_acceptance_type` - `metadata`  Example: ```json { "payment_method": { "type": "enum_variant", "value": "card" }, "amount": { "type": "number", "value": 10 }, "currency": { "type": "str_value", "value": "INR" }, "authentication_type": { "type": "enum_variant", "value": "three_ds" }, "card_bin": { "type": "str_value", "value": "424242" }, "business_country": { "type": "str_value", "value": "IN" }, "setup_future_usage": { "type": "enum_variant", "value": "off_session" }, "card_network": { "type": "enum_variant", "value": "visa" }, "metadata": { "type": "metadata_variant", "value": { "key": "key1", "value": "value1" } } } ```  For the complete superset of supported routing keys, refer to `routing_configs.keys` in: https://github.com/juspay/decision-engine/blob/main/config/development.toml
  fallback_output: list # Fallback connectors used if routing rule evaluation fails.  These connectors will be returned if no rule matches.  Example: ```json [ { "gateway_name": "stripe", "gateway_id": "mca_123" } ] ``` — item shape: {gateway_name: "absa_sanlam"|"authipay"|"adyenplatform"|"stripe_billing_test"|"phonypay"|"fauxpay"|"pretendpay"|"stripe_test"|"adyen_test"|"checkout_test"|"paypal_test"|"aci"|"adyen"|"affirm"|"airwallex"|"amazonpay"|"archipel"|"authorizedotnet"|"bankofamerica"|"barclaycard"|"billwerk"|"bitpay"|"bambora"|"blackhawknetwork"|"bamboraapac"|"bluesnap"|"calida"|"boku"|"braintree"|"breadpay"|"cashtocode"|"celero"|"chargebee"|"custombilling"|"checkbook"|"checkout"|"coinbase"|"coingate"|"cryptopay"|"cybersource"|"cybersourcedecisionmanager"|"datatrans"|"deutschebank"|"digitalvirgo"|"dlocal"|"dwolla"|"ebanx"|"elavon"|"envoy"|"facilitapay"|"finix"|"fiserv"|"fiservemea"|"fiservcommercehub"|"fiuu"|"flexiti"|"forte"|"getnet"|"gigadat"|"globalpay"|"globepay"|"gocardless"|"hipay"|"helcim"|"hyperpg"|"iatapay"|"imerchantsolutions"|"inespay"|"interpayments"|"itaubank"|"jpmorgan"|"klarna"|"loonio"|"mifinity"|"mollie"|"moneris"|"multisafepay"|"nexinets"|"nexixpay"|"nmi"|"nomupay"|"noon"|"nordea"|"novalnet"|"nuvei"|"opennode"|"paybox"|"payme"|"payload"|"payone"|"paypal"|"paysafe"|"paystack"|"paytm"|"payconex"|"payu"|"peachpayments"|"payjustnow"|"payjustnowinstore"|"phonepe"|"placetopay"|"powertranz"|"prophetpay"|"rapyd"|"razorpay"|"recurly"|"redsys"|"revolv3"|"riskified"|"santander"|"shift4"|"signifyd"|"silverflow"|"square"|"stax"|"stripe"|"stripebilling"|"tesouro"|"truelayer"|"trustly"|"trustpay"|"trustpayments"|"tokenio"|"tsys"|"volt"|"wellsfargo"|"wise"|"worldline"|"worldpay"|"worldpaymodular"|"worldpayvantiv"|"worldpayxml"|"xendit"|"zen"|"zift"|"plaid"|"zsl"|"juspaythreedsserver"|"ctp_mastercard"|"ctp_visa"|"netcetera"|"cardinal"|"threedsecureio", gateway_id: string}
]: any -> record<status: string, output: any, evaluated_output: table<connector: string, merchant_connector_id: string>, eligible_connectors: table<connector: string, merchant_connector_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routing/rule/evaluate")
  let body = {created_by: $created_by, payment_id: $payment_id, parameters: $parameters, fallback_output: $fallback_output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /blocklist
#
# Discriminator (request): type
# operationId: Unblock a Fingerprint
export def "blocklist Unblock-a-Fingerprint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-1
  --data: string
]: any -> record<fingerprint_id: string, data_kind: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocklist")
  let body = {type: $type, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /blocklist
#
# operationId: List Blocked fingerprints of a particular kind
export def "blocklist List-Blocked-fingerprints-of-a-particular-kind" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data-kind: string@data-kind-completer # Kind of the fingerprint list requested
]: nothing -> record<fingerprint_id: string, data_kind: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data_kind" $data_kind "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocklist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /blocklist
#
# Discriminator (request): type
# operationId: Block a Fingerprint
export def "blocklist Block-a-Fingerprint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-1
  --data: string
]: any -> record<fingerprint_id: string, data_kind: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocklist")
  let body = {type: $type, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /blocklist/toggle
#
# operationId: Toggle blocklist guard for a particular merchant
export def "blocklist-toggle Toggle-blocklist-guard-for-a-particular-merchant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@bool-completer # Boolean value to enable/disable blocklist
]: nothing -> record<blocklist_guard_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocklist/toggle" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /blocklist/batch
#
# operationId: Upload a batch blocklist CSV
export def "blocklist-batch Upload-a-batch-blocklist-CSV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<job_id: string, total_rows: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocklist/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# GET /blocklist/batch
#
# operationId: List batch blocklist jobs
export def "blocklist-batch List-batch-blocklist-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of jobs to return (default 10, max 100) (nullable, format: int32)
  --offset: int # Zero-based offset for pagination (default 0) (nullable, format: int32)
]: nothing -> record<count: int, total_count: int, data: table<job_id: string, merchant_id: string, status: string, total_rows: int, succeeded_rows: int, failed_rows: int, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocklist/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /blocklist/batch/{job_id}
#
# operationId: Get batch blocklist job status
export def "blocklist-batch Get-batch-blocklist-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_id: string, merchant_id: string, status: string, total_rows: int, succeeded_rows: int, failed_rows: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/blocklist/batch/($job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payouts - Create
#
# POST /payouts/create
# operationId: Create a Payout
@deprecated --flag customer-id
@deprecated --flag business-label
@deprecated --flag email
@deprecated --flag name
@deprecated --flag phone
@deprecated --flag phone-country-code
export def "payouts-create Create-a-Payout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merchant-order-reference-id: string # Your unique identifier for this payout or order. This ID helps you reconcile payouts on your system. If provided, it is passed to the connector if supported. (nullable, e.g. merchant_order_ref_123)
  amount: int # The payout amount. Amount for the payout in lowest denomination of the currency. (i.e) in cents for USD denomination, in paisa for INR denomination etc., (format: int64)
  currency: string@currency-completer # The three-letter ISO 4217 currency code (e.g., "USD", "EUR") for the payment amount. This field is mandatory for creating a payment.
  --routing: any # nullable
  --connector: list # This field allows the merchant to manually select a connector with which the payout can go through. (nullable, e.g. [wise, adyen])
  --confirm: string@bool-completer # This field is used when merchant wants to confirm the payout, thus useful for the payout _Confirm_ request. Ideally merchants should _Create_ a payout, _Update_ it (if required), then _Confirm_ it. (nullable, default: false, e.g. true)
  --payout-type: any # nullable
  --payout-method-data: any # nullable
  --source-bank-data: any # nullable
  --billing: any # nullable
  --auto-fulfill: string@bool-completer # Set to true to confirm the payout without review, no further action required (nullable, default: false, e.g. true)
  --customer-id: string # The identifier for the customer object. If not provided the customer ID will be autogenerated. _Deprecated: Use customer_id instead._ (DEPRECATED, nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --customer: any # nullable
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://hyperswitch.io)
  --business-country: any # nullable
  --business-label: string # Business label of the merchant for this payout. _Deprecated: Use profile_id instead._ (DEPRECATED, nullable, e.g. food)
  --description: string # A description of the payout (nullable, e.g. It's my first payout request)
  --entity-type: any # nullable
  --recurring: string@bool-completer # Specifies whether or not the payout request is recurring (nullable, default: false)
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --payout-token: string # Provide a reference to a stored payout method, used to process the payout. (nullable, e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
  --profile-id: string # The business profile to use for this payout, especially if there are multiple business profiles associated with the account, otherwise default business profile associated with the merchant account will be used. (nullable)
  --priority: any # nullable
  --payout-link: string@bool-completer # Whether to get the payout link (if applicable). Merchant need to specify this during the Payout _Create_, this field can not be updated during Payout _Update_. (nullable, default: false, e.g. true)
  --payout-link-config: any # nullable
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds (900) for 15 mins (nullable, format: int32, e.g. 900)
  --email: string # Customer's email. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. johntest@test.com)
  --name: string # Customer's name. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. John Test)
  --phone: string # Customer's phone. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. 9123456789)
  --phone-country-code: string # Customer's phone country code. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. +1)
  --payout-method-id: string # Identifier for payout method (nullable)
  --browser-info: any # nullable
]: any -> record<payout_id: string, merchant_id: string, merchant_order_reference_id: string, amount: int, currency: string, connector: string, payout_type: record, payout_method_data: record, source_bank_data: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, auto_fulfill: bool, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, client_secret: string, return_url: string, business_country: string, business_label: string, description: string, entity_type: string, recurring: bool, metadata: record, merchant_connector_id: string, status: string, error_message: string, error_code: string, profile_id: string, created: string, connector_transaction_id: string, priority: record, attempts: table<attempt_id: string, status: string, amount: int, currency: record, connector: string, error_code: string, error_message: string, payment_method: record, payout_method_type: record, connector_transaction_id: string, cancellation_reason: string, unified_code: string, unified_message: string>, payout_link: record<payout_link_id: string, link: string>, email: string, name: string, phone: string, phone_country_code: string, unified_code: string, unified_message: string, payout_method_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payouts/create")
  let body = {merchant_order_reference_id: $merchant_order_reference_id, amount: $amount, currency: $currency, routing: $routing, connector: $connector, confirm: $confirm, payout_type: $payout_type, payout_method_data: $payout_method_data, source_bank_data: $source_bank_data, billing: $billing, auto_fulfill: $auto_fulfill, customer_id: $customer_id, customer: $customer, return_url: $return_url, business_country: $business_country, business_label: $business_label, description: $description, entity_type: $entity_type, recurring: $recurring, metadata: $metadata, payout_token: $payout_token, profile_id: $profile_id, priority: $priority, payout_link: $payout_link, payout_link_config: $payout_link_config, session_expiry: $session_expiry, email: $email, name: $name, phone: $phone, phone_country_code: $phone_country_code, payout_method_id: $payout_method_id, browser_info: $browser_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payouts - Retrieve
#
# GET /payouts/{payout_id}
# operationId: Retrieve a Payout
export def "payouts Retrieve-a-Payout" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-sync: string@bool-completer # Sync with the connector to get the payout details (defaults to false) (nullable)
]: nothing -> record<payout_id: string, merchant_id: string, merchant_order_reference_id: string, amount: int, currency: string, connector: string, payout_type: record, payout_method_data: record, source_bank_data: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, auto_fulfill: bool, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, client_secret: string, return_url: string, business_country: string, business_label: string, description: string, entity_type: string, recurring: bool, metadata: record, merchant_connector_id: string, status: string, error_message: string, error_code: string, profile_id: string, created: string, connector_transaction_id: string, priority: record, attempts: table<attempt_id: string, status: string, amount: int, currency: record, connector: string, error_code: string, error_message: string, payment_method: record, payout_method_type: record, connector_transaction_id: string, cancellation_reason: string, unified_code: string, unified_message: string>, payout_link: record<payout_link_id: string, link: string>, email: string, name: string, phone: string, phone_country_code: string, unified_code: string, unified_message: string, payout_method_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_sync" $force_sync "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/payouts/($payout_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payouts - Update
#
# POST /payouts/{payout_id}
# operationId: Update a Payout
@deprecated --flag customer-id
@deprecated --flag business-label
@deprecated --flag email
@deprecated --flag name
@deprecated --flag phone
@deprecated --flag phone-country-code
export def "payouts Update-a-Payout" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merchant-order-reference-id: string # Your unique identifier for this payout or order. This ID helps you reconcile payouts on your system. If provided, it is passed to the connector if supported. (nullable, e.g. merchant_order_ref_123)
  --amount: int # The payout amount. Amount for the payout in lowest denomination of the currency. (i.e) in cents for USD denomination, in paisa for INR denomination etc., (nullable, format: int64, e.g. 1000)
  --currency: any # nullable
  --routing: any # nullable
  --connector: list # This field allows the merchant to manually select a connector with which the payout can go through. (nullable, e.g. [wise, adyen])
  --confirm: string@bool-completer # This field is used when merchant wants to confirm the payout, thus useful for the payout _Confirm_ request. Ideally merchants should _Create_ a payout, _Update_ it (if required), then _Confirm_ it. (nullable, default: false, e.g. true)
  --payout-type: any # nullable
  --payout-method-data: any # nullable
  --source-bank-data: any # nullable
  --billing: any # nullable
  --auto-fulfill: string@bool-completer # Set to true to confirm the payout without review, no further action required (nullable, default: false, e.g. true)
  --customer-id: string # The identifier for the customer object. If not provided the customer ID will be autogenerated. _Deprecated: Use customer_id instead._ (DEPRECATED, nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --customer: any # nullable
  --client-secret: string # It's a token used for client side verification. (nullable, e.g. pay_U42c409qyHwOkWo3vK60_secret_el9ksDkiB8hi6j9N78yo)
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://hyperswitch.io)
  --business-country: any # nullable
  --business-label: string # Business label of the merchant for this payout. _Deprecated: Use profile_id instead._ (DEPRECATED, nullable, e.g. food)
  --description: string # A description of the payout (nullable, e.g. It's my first payout request)
  --entity-type: any # nullable
  --recurring: string@bool-completer # Specifies whether or not the payout request is recurring (nullable, default: false)
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --payout-token: string # Provide a reference to a stored payout method, used to process the payout. (nullable, e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
  --profile-id: string # The business profile to use for this payout, especially if there are multiple business profiles associated with the account, otherwise default business profile associated with the merchant account will be used. (nullable)
  --priority: any # nullable
  --payout-link: string@bool-completer # Whether to get the payout link (if applicable). Merchant need to specify this during the Payout _Create_, this field can not be updated during Payout _Update_. (nullable, default: false, e.g. true)
  --payout-link-config: any # nullable
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds (900) for 15 mins (nullable, format: int32, e.g. 900)
  --email: string # Customer's email. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. johntest@test.com)
  --name: string # Customer's name. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. John Test)
  --phone: string # Customer's phone. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. 9123456789)
  --phone-country-code: string # Customer's phone country code. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. +1)
  --payout-method-id: string # Identifier for payout method (nullable)
  --browser-info: any # nullable
]: any -> record<payout_id: string, merchant_id: string, merchant_order_reference_id: string, amount: int, currency: string, connector: string, payout_type: record, payout_method_data: record, source_bank_data: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, auto_fulfill: bool, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, client_secret: string, return_url: string, business_country: string, business_label: string, description: string, entity_type: string, recurring: bool, metadata: record, merchant_connector_id: string, status: string, error_message: string, error_code: string, profile_id: string, created: string, connector_transaction_id: string, priority: record, attempts: table<attempt_id: string, status: string, amount: int, currency: record, connector: string, error_code: string, error_message: string, payment_method: record, payout_method_type: record, connector_transaction_id: string, cancellation_reason: string, unified_code: string, unified_message: string>, payout_link: record<payout_link_id: string, link: string>, email: string, name: string, phone: string, phone_country_code: string, unified_code: string, unified_message: string, payout_method_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payouts/($payout_id)")
  let body = {merchant_order_reference_id: $merchant_order_reference_id, amount: $amount, currency: $currency, routing: $routing, connector: $connector, confirm: $confirm, payout_type: $payout_type, payout_method_data: $payout_method_data, source_bank_data: $source_bank_data, billing: $billing, auto_fulfill: $auto_fulfill, customer_id: $customer_id, customer: $customer, client_secret: $client_secret, return_url: $return_url, business_country: $business_country, business_label: $business_label, description: $description, entity_type: $entity_type, recurring: $recurring, metadata: $metadata, payout_token: $payout_token, profile_id: $profile_id, priority: $priority, payout_link: $payout_link, payout_link_config: $payout_link_config, session_expiry: $session_expiry, email: $email, name: $name, phone: $phone, phone_country_code: $phone_country_code, payout_method_id: $payout_method_id, browser_info: $browser_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payouts - Cancel
#
# POST /payouts/{payout_id}/cancel
# operationId: Cancel a Payout
export def "payouts-cancel Cancel-a-Payout" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-payout-id: string # Unique identifier for the payout. This ensures idempotency for multiple payouts that have been done by a single merchant. This field is auto generated and is returned in the API response. (e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
]: any -> record<payout_id: string, merchant_id: string, merchant_order_reference_id: string, amount: int, currency: string, connector: string, payout_type: record, payout_method_data: record, source_bank_data: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, auto_fulfill: bool, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, client_secret: string, return_url: string, business_country: string, business_label: string, description: string, entity_type: string, recurring: bool, metadata: record, merchant_connector_id: string, status: string, error_message: string, error_code: string, profile_id: string, created: string, connector_transaction_id: string, priority: record, attempts: table<attempt_id: string, status: string, amount: int, currency: record, connector: string, error_code: string, error_message: string, payment_method: record, payout_method_type: record, connector_transaction_id: string, cancellation_reason: string, unified_code: string, unified_message: string>, payout_link: record<payout_link_id: string, link: string>, email: string, name: string, phone: string, phone_country_code: string, unified_code: string, unified_message: string, payout_method_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payouts/($payout_id)/cancel")
  let body = {payout_id: $body_payout_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payouts - Fulfill
#
# POST /payouts/{payout_id}/fulfill
# operationId: Fulfill a Payout
export def "payouts-fulfill Fulfill-a-Payout" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-payout-id: string # Unique identifier for the payout. This ensures idempotency for multiple payouts that have been done by a single merchant. This field is auto generated and is returned in the API response. (e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
]: any -> record<payout_id: string, merchant_id: string, merchant_order_reference_id: string, amount: int, currency: string, connector: string, payout_type: record, payout_method_data: record, source_bank_data: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, auto_fulfill: bool, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, client_secret: string, return_url: string, business_country: string, business_label: string, description: string, entity_type: string, recurring: bool, metadata: record, merchant_connector_id: string, status: string, error_message: string, error_code: string, profile_id: string, created: string, connector_transaction_id: string, priority: record, attempts: table<attempt_id: string, status: string, amount: int, currency: record, connector: string, error_code: string, error_message: string, payment_method: record, payout_method_type: record, connector_transaction_id: string, cancellation_reason: string, unified_code: string, unified_message: string>, payout_link: record<payout_link_id: string, link: string>, email: string, name: string, phone: string, phone_country_code: string, unified_code: string, unified_message: string, payout_method_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payouts/($payout_id)/fulfill")
  let body = {payout_id: $body_payout_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payouts - List
#
# GET /payouts/list
# operationId: List payouts using generic constraints
export def "payouts-list List-payouts-using-generic-constraints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customer-id: string # The identifier for customer
  --starting-after: string # A cursor for use in pagination, fetch the next list after some object
  --ending-before: string # A cursor for use in pagination, fetch the previous list before some object
  --limit: string # limit on the number of objects to return
  --created: string # The time at which payout is created
  --time-range: string # The time range for which objects are needed. TimeRange has two fields start_time and end_time from which objects can be filtered as per required scenarios (created_at, time less than, greater than etc).
]: nothing -> record<size: int, data: table<payout_id: string, merchant_id: string, merchant_order_reference_id: string, amount: int, currency: string, connector: string, payout_type: record, payout_method_data: record, source_bank_data: record, billing: record, auto_fulfill: bool, customer_id: string, customer: record, client_secret: string, return_url: string, business_country: string, business_label: string, description: string, entity_type: string, recurring: bool, metadata: record, merchant_connector_id: string, status: string, error_message: string, error_code: string, profile_id: string, created: string, connector_transaction_id: string, priority: record, attempts: list, payout_link: record, email: string, name: string, phone: string, phone_country_code: string, unified_code: string, unified_message: string, payout_method_id: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "time_range" $time_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payouts/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payouts - List using filters
#
# POST /payouts/list
# operationId: Filter payouts using specific constraints
export def "payouts-list Filter-payouts-using-specific-constraints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payout-id: string # The identifier for payout (nullable, e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
  --merchant-order-reference-id: string # The merchant order reference ID for payout (nullable, e.g. merchant_order_ref_123)
  --profile-id: string # The identifier for business profile (nullable)
  --customer-id: string # The identifier for customer (nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --limit: int # The limit on the number of objects. The default limit is 10 and max limit is 20 (format: int32)
  --offset: int # The starting point within a list of objects (nullable, format: int32)
  --connector: list # The list of connectors to filter payouts list (nullable, e.g. [wise, adyen])
  currency: string@currency-completer # The three-letter ISO 4217 currency code (e.g., "USD", "EUR") for the payment amount. This field is mandatory for creating a payment.
  --status: list # The list of payout status to filter payouts list (nullable, e.g. [pending, failed])
  --payout-method: list # The list of payout methods to filter payouts list (nullable, e.g. [bank, card])
  entity_type: string@entity-type-completer # Type of entity to whom the payout is being carried out to, select from the given list of options
]: any -> record<size: int, data: table<payout_id: string, merchant_id: string, merchant_order_reference_id: string, amount: int, currency: string, connector: string, payout_type: record, payout_method_data: record, source_bank_data: record, billing: record, auto_fulfill: bool, customer_id: string, customer: record, client_secret: string, return_url: string, business_country: string, business_label: string, description: string, entity_type: string, recurring: bool, metadata: record, merchant_connector_id: string, status: string, error_message: string, error_code: string, profile_id: string, created: string, connector_transaction_id: string, priority: record, attempts: list, payout_link: record, email: string, name: string, phone: string, phone_country_code: string, unified_code: string, unified_message: string, payout_method_id: string>, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payouts/list")
  let body = {payout_id: $payout_id, merchant_order_reference_id: $merchant_order_reference_id, profile_id: $profile_id, customer_id: $customer_id, limit: $limit, offset: $offset, connector: $connector, currency: $currency, status: $status, payout_method: $payout_method, entity_type: $entity_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payouts - Confirm
#
# POST /payouts/{payout_id}/confirm
# operationId: Confirm a Payout
@deprecated --flag customer-id
@deprecated --flag business-label
@deprecated --flag email
@deprecated --flag name
@deprecated --flag phone
@deprecated --flag phone-country-code
export def "payouts-confirm Confirm-a-Payout" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merchant-order-reference-id: string # Your unique identifier for this payout or order. This ID helps you reconcile payouts on your system. If provided, it is passed to the connector if supported. (nullable, e.g. merchant_order_ref_123)
  --amount: int # The payout amount. Amount for the payout in lowest denomination of the currency. (i.e) in cents for USD denomination, in paisa for INR denomination etc., (nullable, format: int64, e.g. 1000)
  --currency: any # nullable
  --routing: any # nullable
  --connector: list # This field allows the merchant to manually select a connector with which the payout can go through. (nullable, e.g. [wise, adyen])
  --payout-type: any # nullable
  --payout-method-data: any # nullable
  --source-bank-data: any # nullable
  --billing: any # nullable
  --auto-fulfill: string@bool-completer # Set to true to confirm the payout without review, no further action required (nullable, default: false, e.g. true)
  --customer-id: string # The identifier for the customer object. If not provided the customer ID will be autogenerated. _Deprecated: Use customer_id instead._ (DEPRECATED, nullable, e.g. cus_y3oqhf46pyzuxjbcn2giaqnb44)
  --customer: any # nullable
  client_secret: string # It's a token used for client side verification.
  --return-url: string # The URL to redirect after the completion of the operation (nullable, e.g. https://hyperswitch.io)
  --business-country: any # nullable
  --business-label: string # Business label of the merchant for this payout. _Deprecated: Use profile_id instead._ (DEPRECATED, nullable, e.g. food)
  --description: string # A description of the payout (nullable, e.g. It's my first payout request)
  --entity-type: any # nullable
  --recurring: string@bool-completer # Specifies whether or not the payout request is recurring (nullable, default: false)
  --metadata: record # You can specify up to 50 keys, with key names up to 40 characters long and values up to 500 characters long. Metadata is useful for storing additional, structured information on an object. (nullable)
  --payout-token: string # Provide a reference to a stored payout method, used to process the payout. (nullable, e.g. 187282ab-40ef-47a9-9206-5099ba31e432)
  --profile-id: string # The business profile to use for this payout, especially if there are multiple business profiles associated with the account, otherwise default business profile associated with the merchant account will be used. (nullable)
  --priority: any # nullable
  --payout-link: string@bool-completer # Whether to get the payout link (if applicable). Merchant need to specify this during the Payout _Create_, this field can not be updated during Payout _Update_. (nullable, default: false, e.g. true)
  --payout-link-config: any # nullable
  --session-expiry: int # Will be used to expire client secret after certain amount of time to be supplied in seconds (900) for 15 mins (nullable, format: int32, e.g. 900)
  --email: string # Customer's email. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. johntest@test.com)
  --name: string # Customer's name. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. John Test)
  --phone: string # Customer's phone. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. 9123456789)
  --phone-country-code: string # Customer's phone country code. _Deprecated: Use customer object instead._ (DEPRECATED, nullable, e.g. +1)
  --payout-method-id: string # Identifier for payout method (nullable)
  --browser-info: any # nullable
]: any -> record<payout_id: string, merchant_id: string, merchant_order_reference_id: string, amount: int, currency: string, connector: string, payout_type: record, payout_method_data: record, source_bank_data: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, auto_fulfill: bool, customer_id: string, customer: record<id: string, name: string, email: string, phone: string, phone_country_code: string, customer_document_details: record<document_type: string, document_number: string>>, client_secret: string, return_url: string, business_country: string, business_label: string, description: string, entity_type: string, recurring: bool, metadata: record, merchant_connector_id: string, status: string, error_message: string, error_code: string, profile_id: string, created: string, connector_transaction_id: string, priority: record, attempts: table<attempt_id: string, status: string, amount: int, currency: record, connector: string, error_code: string, error_message: string, payment_method: record, payout_method_type: record, connector_transaction_id: string, cancellation_reason: string, unified_code: string, unified_message: string>, payout_link: record<payout_link_id: string, link: string>, email: string, name: string, phone: string, phone_country_code: string, unified_code: string, unified_message: string, payout_method_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payouts/($payout_id)/confirm")
  let body = {merchant_order_reference_id: $merchant_order_reference_id, amount: $amount, currency: $currency, routing: $routing, connector: $connector, payout_type: $payout_type, payout_method_data: $payout_method_data, source_bank_data: $source_bank_data, billing: $billing, auto_fulfill: $auto_fulfill, customer_id: $customer_id, customer: $customer, client_secret: $client_secret, return_url: $return_url, business_country: $business_country, business_label: $business_label, description: $description, entity_type: $entity_type, recurring: $recurring, metadata: $metadata, payout_token: $payout_token, profile_id: $profile_id, priority: $priority, payout_link: $payout_link, payout_link_config: $payout_link_config, session_expiry: $session_expiry, email: $email, name: $name, phone: $phone, phone_country_code: $phone_country_code, payout_method_id: $payout_method_id, browser_info: $browser_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Payouts - List available filters
#
# POST /payouts/filter
# operationId: List available payout filters
export def "payouts-filter List-available-payout-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  start_time: string # The start time to filter payments list or to get list of filters. To get list of filters start time is needed to be passed (format: date-time)
  --end-time: string # The end time to filter payments list or to get list of filters. If not passed the default time is now (nullable, format: date-time)
]: any -> record<connector: list<string>, currency: list<string>, status: list<string>, payout_method: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payouts/filter")
  let body = {start_time: $start_time, end_time: $end_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# API Key - Create
#
# POST /api_keys/{merchant_id}
# operationId: Create an API Key
export def "api-keys Create-an-API-Key" [
  merchant_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($merchant_id)")
  let body = {name: $name, description: $description, expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# API Key - Retrieve
#
# GET /api_keys/{merchant_id}/{key_id}
# operationId: Retrieve an API Key
export def "api-keys Retrieve-an-API-Key" [
  merchant_id: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key_id: string, merchant_id: string, name: string, description: string, prefix: string, created: string, expiration: any> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($merchant_id)/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Key - Update
#
# POST /api_keys/{merchant_id}/{key_id}
# operationId: Update an API Key
export def "api-keys Update-an-API-Key" [
  merchant_id: string
  key_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($merchant_id)/($key_id)")
  let body = {name: $name, description: $description, expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# API Key - Revoke
#
# DELETE /api_keys/{merchant_id}/{key_id}
# operationId: Revoke an API Key
export def "api-keys Revoke-an-API-Key" [
  merchant_id: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<merchant_id: string, key_id: string, revoked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($merchant_id)/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Key - List
#
# GET /api_keys/{merchant_id}/list
# operationId: List all API Keys associated with a merchant account
export def "api-keys-list List-all-API-Keys-associated-with-a-merchant-account" [
  merchant_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api_keys/($merchant_id)/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Events - List
#
# POST /events/{merchant_id}
# operationId: List all Events associated with a Merchant Account or Profile
export def "events List-all-Events-associated-with-a-Merchant-Account-or-Profile" [
  merchant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-after: string # Filter events created after the specified time. (nullable, format: date-time)
  --created-before: string # Filter events created before the specified time. (nullable, format: date-time)
  --limit: int # Include at most the specified number of events. (nullable, format: int32)
  --offset: int # Include events after the specified offset. (nullable, format: int32)
  --object-id: string # Filter all events associated with the specified object identifier (Payment Intent ID, Refund ID, etc.) (nullable)
  --event-id: string # Filter all events associated with the specified Event_id (nullable)
  --profile-id: string # Filter all events associated with the specified business profile ID. (nullable)
  --event-classes: list # Filter events by their class. (nullable)
  --event-types: list # Filter events by their type. (nullable)
  --is-delivered: string@bool-completer # Filter all events by `is_overall_delivery_successful` field of the event. (nullable)
]: any -> record<events: table<event_id: string, merchant_id: string, profile_id: string, object_id: string, event_type: string, event_class: string, is_delivery_successful: bool, initial_attempt_id: string, processor_merchant_id: string, created: string>, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($merchant_id)")
  let body = {created_after: $created_after, created_before: $created_before, limit: $limit, offset: $offset, object_id: $object_id, event_id: $event_id, profile_id: $profile_id, event_classes: $event_classes, event_types: $event_types, is_delivered: $is_delivered} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Events - List
#
# POST /events/profile/list
# operationId: List all Events associated with a Profile
export def "events-profile-list List-all-Events-associated-with-a-Profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-after: string # Filter events created after the specified time. (nullable, format: date-time)
  --created-before: string # Filter events created before the specified time. (nullable, format: date-time)
  --limit: int # Include at most the specified number of events. (nullable, format: int32)
  --offset: int # Include events after the specified offset. (nullable, format: int32)
  --object-id: string # Filter all events associated with the specified object identifier (Payment Intent ID, Refund ID, etc.) (nullable)
  --event-id: string # Filter all events associated with the specified Event_id (nullable)
  --profile-id: string # Filter all events associated with the specified business profile ID. (nullable)
  --event-classes: list # Filter events by their class. (nullable)
  --event-types: list # Filter events by their type. (nullable)
  --is-delivered: string@bool-completer # Filter all events by `is_overall_delivery_successful` field of the event. (nullable)
]: any -> record<events: table<event_id: string, merchant_id: string, profile_id: string, object_id: string, event_type: string, event_class: string, is_delivery_successful: bool, initial_attempt_id: string, processor_merchant_id: string, created: string>, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events/profile/list")
  let body = {created_after: $created_after, created_before: $created_before, limit: $limit, offset: $offset, object_id: $object_id, event_id: $event_id, profile_id: $profile_id, event_classes: $event_classes, event_types: $event_types, is_delivered: $is_delivered} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Events - Delivery Attempt List
#
# GET /events/{merchant_id}/{event_id}/attempts
# operationId: List all delivery attempts for an Event
export def "events-attempts List-all-delivery-attempts-for-an-Event" [
  merchant_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<event_id: string, merchant_id: string, profile_id: string, object_id: string, event_type: string, event_class: string, is_delivery_successful: bool, initial_attempt_id: string, processor_merchant_id: string, created: string, request: record<body: string, headers: list>, response: record<body: string, headers: list, status_code: int, error_message: string>, delivery_attempt: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($merchant_id)/($event_id)/attempts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Events - Manual Retry
#
# POST /events/{merchant_id}/{event_id}/retry
# operationId: Manually retry the delivery of an Event
export def "events-retry Manually-retry-the-delivery-of-an-Event" [
  merchant_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<event_id: string, merchant_id: string, profile_id: string, object_id: string, event_type: string, event_class: string, is_delivery_successful: bool, initial_attempt_id: string, processor_merchant_id: string, created: string, request: record<body: string, headers: list<list>>, response: record<body: string, headers: list<list>, status_code: int, error_message: string>, delivery_attempt: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($merchant_id)/($event_id)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Poll - Retrieve Poll Status
#
# GET /poll/status/{poll_id}
# operationId: Retrieve Poll Status
export def "poll-status Retrieve-Poll-Status" [
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<poll_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/poll/status/($poll_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Profile Acquirer - Create
#
# POST /profile_acquirers
# operationId: Create a Profile Acquirer
export def "profile-acquirers Create-a-Profile-Acquirer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  acquirer_assigned_merchant_id: string # The merchant id assigned by the acquirer (e.g. M123456789)
  merchant_name: string # merchant name (e.g. NewAge Retailer)
  network: string # Network provider (e.g. VISA)
  acquirer_bin: string # Acquirer bin (e.g. 456789)
  --acquirer-ica: string # Acquirer ica provided by acquirer (nullable, e.g. 401288)
  --acquirer-fraud-rate: float # Fraud rate for the particular acquirer configuration (nullable, format: double, e.g. 0.01)
  --acquirer-country-code: string # Acquirer country code (nullable, e.g. US)
  profile_id: string # Parent profile id to link the acquirer account with (e.g. pro_ky0yNyOXXlA5hF8JzE5q)
  --is-default: string@bool-completer # Whether this configuration bucket is the default fallback for the profile. (nullable)
]: any -> record<profile_acquirer_id: string, acquirer_assigned_merchant_id: string, merchant_name: string, network: string, acquirer_bin: string, acquirer_ica: string, acquirer_fraud_rate: float, acquirer_country_code: string, profile_id: string, is_default: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile_acquirers")
  let body = {acquirer_assigned_merchant_id: $acquirer_assigned_merchant_id, merchant_name: $merchant_name, network: $network, acquirer_bin: $acquirer_bin, acquirer_ica: $acquirer_ica, acquirer_fraud_rate: $acquirer_fraud_rate, acquirer_country_code: $acquirer_country_code, profile_id: $profile_id, is_default: $is_default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Profile Acquirer - Update
#
# POST /profile_acquirers/{profile_id}/{profile_acquirer_id}
# operationId: Update a Profile Acquirer
export def "profile-acquirers Update-a-Profile-Acquirer" [
  profile_id: string
  profile_acquirer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acquirer-assigned-merchant-id: string # nullable, e.g. M987654321
  --merchant-name: string # nullable, e.g. Updated Retailer Name
  --network: string # The card network this configuration entry targets — optional if updating just the default. (nullable, e.g. MASTERCARD)
  --acquirer-bin: string # nullable, e.g. 987654
  --acquirer-ica: string # nullable, e.g. 501299
  --acquirer-fraud-rate: float # nullable, format: double, e.g. 0.02
  --acquirer-country-code: string # nullable, e.g. US
  --is-default: string@bool-completer # Whether this configuration bucket is the default fallback for the profile. (nullable)
]: any -> record<profile_acquirer_id: string, acquirer_assigned_merchant_id: string, merchant_name: string, network: string, acquirer_bin: string, acquirer_ica: string, acquirer_fraud_rate: float, acquirer_country_code: string, profile_id: string, is_default: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/profile_acquirers/($profile_id)/($profile_acquirer_id)")
  let body = {acquirer_assigned_merchant_id: $acquirer_assigned_merchant_id, merchant_name: $merchant_name, network: $network, acquirer_bin: $acquirer_bin, acquirer_ica: $acquirer_ica, acquirer_fraud_rate: $acquirer_fraud_rate, acquirer_country_code: $acquirer_country_code, is_default: $is_default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# 3DS Decision - Execute
#
# POST /three_ds_decision/execute
# operationId: Execute 3DS Decision Rule
# --payment shape: {amount: int, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VES"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZWL"}
export def "three-ds-decision-execute Execute-3DS-Decision-Rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  routing_id: string # The ID of the routing algorithm to be executed.
  payment: record # Represents the payment data used in the 3DS decision rule. — shape: {amount: int, currency: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BZD"|"CAD"|"CDF"|"CHF"|"CLF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VES"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZWL"}
  --payment-method: any # nullable
  --customer-device: any # nullable
  --issuer: any # nullable
  --acquirer: any # nullable
]: any -> record<decision: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/three_ds_decision/execute")
  let body = {routing_id: $routing_id, payment: $payment, payment_method: $payment_method, customer_device: $customer_device, issuer: $issuer, acquirer: $acquirer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authentication - Create
#
# POST /authentication
# operationId: Create an Authentication
export def "authentication Create-an-Authentication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authentication-id: string # The unique identifier for this authentication. (nullable, e.g. auth_mbabizu24mvu3mela5njyhpit4)
  --profile-id: string # The business profile that is associated with this authentication (nullable)
  amount: int # This Unit struct represents MinorUnit in which core amount works (format: int64)
  --authentication-connector: any # nullable
  currency: string@currency-completer # The three-letter ISO 4217 currency code (e.g., "USD", "EUR") for the payment amount. This field is mandatory for creating a payment.
  --return-url: string # The URL to which the user should be redirected after authentication. (nullable, e.g. https://example.com/redirect)
  --force-3ds-challenge: string@bool-completer # Force 3DS challenge. (nullable)
  --psd2-sca-exemption-type: any # nullable
  --profile-acquirer-id: string # Profile Acquirer ID get from profile acquirer configuration (nullable)
  --acquirer-details: any # nullable
  --customer-details: any # nullable
]: any -> record<authentication_id: string, merchant_id: string, status: string, client_secret: string, amount: int, currency: string, authentication_connector: record, force_3ds_challenge: bool, return_url: string, created_at: string, error_code: string, error_message: string, profile_id: string, psd2_sca_exemption_type: record, acquirer_details: record<acquirer_bin: string, acquirer_merchant_id: string, merchant_country_code: string>, profile_acquirer_id: string, customer_details: record<id: string, name: string, email: string, phone: string, phone_country_code: string, tax_registration_id: string, document_details: record<document_type: string, document_number: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication")
  let body = {authentication_id: $authentication_id, profile_id: $profile_id, amount: $amount, authentication_connector: $authentication_connector, currency: $currency, return_url: $return_url, force_3ds_challenge: $force_3ds_challenge, psd2_sca_exemption_type: $psd2_sca_exemption_type, profile_acquirer_id: $profile_acquirer_id, acquirer_details: $acquirer_details, customer_details: $customer_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authentication - Eligibility
#
# POST /authentication/{authentication_id}/eligibility
# operationId: Check Authentication Eligibility
export def "authentication-eligibility Check-Authentication-Eligibility" [
  authentication_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_method_data: any
  payment_method: string@payment-method-completer # Indicates the type of payment method. Eg: 'card', 'wallet', etc.
  --payment-method-type: any # nullable
  --client-secret: string # Optional secret value used to identify and authorize the client making the request. This can help ensure that the payment session is secure and valid. (nullable)
  --profile-id: string # Optional identifier for the business profile associated with the payment. This determines which configurations, rules, and branding are applied to the transaction. (nullable)
  --billing: any # nullable
  --shipping: any # nullable
  --browser-information: any # nullable
  --email: string # Optional email address of the customer. Used for customer identification, communication, and possibly for 3DS or fraud checks. (nullable)
]: any -> record<authentication_id: string, next_action: record<url: string, http_method: string>, status: string, eligibility_response_params: record, connector_metadata: any, profile_id: string, error_message: string, error_code: string, authentication_connector: record, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, browser_information: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, email: string, acquirer_details: record<acquirer_bin: string, acquirer_merchant_id: string, merchant_country_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication/($authentication_id)/eligibility")
  let body = {payment_method_data: $payment_method_data, payment_method: $payment_method, payment_method_type: $payment_method_type, client_secret: $client_secret, profile_id: $profile_id, billing: $billing, shipping: $shipping, browser_information: $browser_information, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authentication - Authenticate
#
# POST /authentication/{authentication_id}/authenticate
# operationId: Authenticate an Authentication
export def "authentication-authenticate Authenticate-an-Authentication" [
  authentication_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_secret: string # Client secret for the authentication
  --sdk-information: any # nullable
  device_channel: string@device-channel-completer # Device Channel indicating whether request is coming from App or Browser
  threeds_method_comp_ind: string@threeds-method-comp-ind-completer # Indicates if 3DS method data was successfully completed or not
]: any -> record<trans_status: record, acs_url: string, challenge_request: string, acs_reference_number: string, acs_trans_id: string, three_ds_server_transaction_id: string, acs_signed_content: string, three_ds_requestor_url: string, three_ds_requestor_app_url: string, error_message: string, error_code: string, authentication_value: string, status: string, authentication_connector: record, authentication_id: string, eci: string, acquirer_details: record<acquirer_bin: string, acquirer_merchant_id: string, merchant_country_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication/($authentication_id)/authenticate")
  let body = {client_secret: $client_secret, sdk_information: $sdk_information, device_channel: $device_channel, threeds_method_comp_ind: $threeds_method_comp_ind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authentication - Redirect
#
# POST /authentication/{authentication_id}/redirect
# operationId: Redirect an Authentication
export def "authentication-redirect Redirect-an-Authentication" [
  authentication_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication/($authentication_id)/redirect")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authentication - Sync
#
# POST /authentication/{authentication_id}/sync
# operationId: Sync an Authentication
export def "authentication-sync Sync-an-Authentication" [
  authentication_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_secret: string # The client secret for this authentication.
  --payment-method-details: any # nullable
]: any -> record<authentication_id: string, merchant_id: string, status: string, client_secret: string, amount: int, currency: string, authentication_connector: record, force_3ds_challenge: bool, return_url: string, created_at: string, profile_id: string, psd2_sca_exemption_type: record, acquirer_details: record<acquirer_bin: string, acquirer_merchant_id: string, merchant_country_code: string>, threeds_server_transaction_id: string, maximum_supported_3ds_version: string, connector_authentication_id: string, three_ds_method_data: string, three_ds_method_url: string, message_version: string, connector_metadata: any, directory_server_id: string, payment_method_data: record, vault_token_data: record, authentication_details: record<three_ds_data: record<authentication_cryptogram: record, ds_trans_id: string, version: string, eci: string, transaction_status: string>>, billing: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, shipping: record<address: record<city: string, country: record, line1: string, line2: string, line3: string, zip: string, state: string, first_name: string, last_name: string, origin_zip: string>, phone: record<number: string, country_code: string>, email: string>, browser_information: record<color_depth: int, java_enabled: bool, java_script_enabled: bool, language: string, screen_height: int, screen_width: int, time_zone: int, ip_address: string, accept_header: string, user_agent: string, os_type: string, os_version: string, device_model: string, accept_language: string, referer: string>, email: string, trans_status: record, acs_url: string, challenge_request: string, acs_reference_number: string, acs_trans_id: string, acs_signed_content: string, three_ds_requestor_url: string, three_ds_requestor_app_url: string, eci: string, error_message: string, error_code: string, profile_acquirer_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication/($authentication_id)/sync")
  let body = {client_secret: $client_secret, payment_method_details: $payment_method_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authentication - Enable Authn Methods Token
#
# POST /authentication/{authentication_id}/enabled_authn_methods_token
# operationId: Enable Authentication Authn Methods Token
export def "authentication-enabled-authn-methods-token Enable-Authentication-Authn-Methods-Token" [
  authentication_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_secret: string # Client Secret for the authentication
]: any -> record<authentication_id: string, session_token: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication/($authentication_id)/enabled_authn_methods_token")
  let body = {client_secret: $client_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authentication - POST Eligibility Check
#
# POST /authentication/{authentication_id}/eligibility-check
# operationId: Submit Eligibility for an Authentication
export def "authentication-eligibility-check Submit-Eligibility-for-an-Authentication" [
  authentication_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-secret: string # Optional secret value used to identify and authorize the client making the request. This can help ensure that the payment session is secure and valid. (nullable)
  eligibility_check_data: any
]: any -> record<authentication_id: string, sdk_next_action: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication/($authentication_id)/eligibility-check")
  let body = {client_secret: $client_secret, eligibility_check_data: $eligibility_check_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authentication - GET Eligibility Check
#
# GET /authentication/{authentication_id}/eligibility-check
# operationId: Retrieve Eligibility Check data for an Authentication
export def "authentication-eligibility-check Retrieve-Eligibility-Check-data-for-an-Authentication" [
  authentication_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<eligibility_check_data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication/($authentication_id)/eligibility-check")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Platform - Create
#
# POST /user/create_platform
# operationId: Create a Platform Account
export def "user-create-platform Create-a-Platform-Account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_name: string # e.g. organization_abc
]: any -> record<org_id: string, org_name: string, org_type: string, merchant_id: string, merchant_account_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/create_platform")
  let body = {organization_name: $organization_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription - Create and Confirm
#
# POST /subscriptions
# operationId: Create and Confirm Subscription
# --payment_details shape: {payment_method?: any, payment_method_type?: any, payment_method_data?: any, setup_future_usage?: any, customer_acceptance?: any, return_url?: string, capture_method?: any, authentication_type?: any, payment_type?: any, payment_method_id?: string}
export def "subscriptions Create-and-Confirm-Subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  --plan-id: string # Identifier for the associated plan_id. (nullable)
  item_price_id: string # Identifier for the associated item_price_id for the subscription.
  --coupon-code: string # Identifier for the coupon code for the subscription. (nullable)
  customer_id: string # A type for customer_id that can be used for customer ids
  --billing: any # nullable
  --shipping: any # nullable
  payment_details: record # shape: {payment_method?: any, payment_method_type?: any, payment_method_data?: any, setup_future_usage?: any, customer_acceptance?: any, return_url?: string, capture_method?: any, authentication_type?: any, payment_type?: any, payment_method_id?: string}
  --merchant-reference-id: string # Merchant specific Unique identifier. (nullable)
]: any -> record<id: string, merchant_reference_id: string, status: string, plan_id: string, item_price_id: string, profile_id: string, client_secret: string, merchant_id: string, coupon_code: string, customer_id: string, payment: record<payment_id: string, status: string, amount: int, currency: string, profile_id: record, connector: string, payment_method_id: string, return_url: string, next_action: record, payment_experience: record, error_code: string, error_message: string, payment_method_type: record, client_secret: string, billing: record<address: record, phone: record, email: string>, shipping: record<address: record, phone: record, email: string>, payment_type: record, payment_token: string>, invoice: record<id: string, subscription_id: string, merchant_id: string, profile_id: string, merchant_connector_id: string, payment_intent_id: record, payment_method_id: string, customer_id: string, amount: int, currency: string, status: string, billing_processor_invoice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let body = {plan_id: $plan_id, item_price_id: $item_price_id, coupon_code: $coupon_code, customer_id: $customer_id, billing: $billing, shipping: $shipping, payment_details: $payment_details, merchant_reference_id: $merchant_reference_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription - Create
#
# POST /subscriptions/create
# operationId: Create Subscription
# --payment_details shape: {return_url: string, setup_future_usage?: any, capture_method?: any, authentication_type?: any, payment_type?: any}
export def "subscriptions-create Create-Subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  --merchant-reference-id: string # Merchant specific Unique identifier. (nullable)
  item_price_id: string # Identifier for the associated item_price_id for the subscription.
  --plan-id: string # Identifier for the subscription plan. (nullable)
  --coupon-code: string # Optional coupon code applied to the subscription. (nullable)
  customer_id: string # A type for customer_id that can be used for customer ids
  payment_details: record # shape: {return_url: string, setup_future_usage?: any, capture_method?: any, authentication_type?: any, payment_type?: any}
  --billing: any # nullable
  --shipping: any # nullable
]: any -> record<id: string, merchant_reference_id: string, status: string, plan_id: string, item_price_id: string, profile_id: string, client_secret: string, merchant_id: string, coupon_code: string, customer_id: string, payment: record<payment_id: string, status: string, amount: int, currency: string, profile_id: record, connector: string, payment_method_id: string, return_url: string, next_action: record, payment_experience: record, error_code: string, error_message: string, payment_method_type: record, client_secret: string, billing: record<address: record, phone: record, email: string>, shipping: record<address: record, phone: record, email: string>, payment_type: record, payment_token: string>, invoice: record<id: string, subscription_id: string, merchant_id: string, profile_id: string, merchant_connector_id: string, payment_intent_id: record, payment_method_id: string, customer_id: string, amount: int, currency: string, status: string, billing_processor_invoice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions/create")
  let body = {merchant_reference_id: $merchant_reference_id, item_price_id: $item_price_id, plan_id: $plan_id, coupon_code: $coupon_code, customer_id: $customer_id, payment_details: $payment_details, billing: $billing, shipping: $shipping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription - Confirm
#
# POST /subscriptions/{subscription_id}/confirm
# operationId: Confirm Subscription
# --payment_details shape: {shipping?: any, billing?: any, payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_type?: any, payment_method_data?: any, customer_acceptance?: any, payment_type?: any, payment_token?: string}
export def "subscriptions-confirm Confirm-Subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  --client-secret: string # This is a token which expires after 15 minutes, used from the client to authenticate and create sessions from the SDK (nullable)
  payment_details: record # shape: {shipping?: any, billing?: any, payment_method: "card"|"card_redirect"|"pay_later"|"wallet"|"bank_redirect"|"bank_transfer"|"crypto"|"bank_debit"|"reward"|"real_time_payment"|"upi"|"voucher"|"gift_card"|"open_banking"|"mobile_payment"|"network_token", payment_method_type?: any, payment_method_data?: any, customer_acceptance?: any, payment_type?: any, payment_token?: string}
]: any -> record<id: string, merchant_reference_id: string, status: string, plan_id: string, item_price_id: string, profile_id: string, client_secret: string, merchant_id: string, coupon_code: string, customer_id: string, payment: record<payment_id: string, status: string, amount: int, currency: string, profile_id: record, connector: string, payment_method_id: string, return_url: string, next_action: record, payment_experience: record, error_code: string, error_message: string, payment_method_type: record, client_secret: string, billing: record<address: record, phone: record, email: string>, shipping: record<address: record, phone: record, email: string>, payment_type: record, payment_token: string>, invoice: record<id: string, subscription_id: string, merchant_id: string, profile_id: string, merchant_connector_id: string, payment_intent_id: record, payment_method_id: string, customer_id: string, amount: int, currency: string, status: string, billing_processor_invoice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/confirm")
  let body = {client_secret: $client_secret, payment_details: $payment_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription - Retrieve
#
# GET /subscriptions/{subscription_id}
# operationId: Retrieve Subscription
export def "subscriptions Retrieve-Subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
]: nothing -> record<id: string, merchant_reference_id: string, status: string, plan_id: string, item_price_id: string, profile_id: string, client_secret: string, merchant_id: string, coupon_code: string, customer_id: string, payment: record<payment_id: string, status: string, amount: int, currency: string, profile_id: record, connector: string, payment_method_id: string, return_url: string, next_action: record, payment_experience: record, error_code: string, error_message: string, payment_method_type: record, client_secret: string, billing: record<address: record, phone: record, email: string>, shipping: record<address: record, phone: record, email: string>, payment_type: record, payment_token: string>, invoice: record<id: string, subscription_id: string, merchant_id: string, profile_id: string, merchant_connector_id: string, payment_intent_id: record, payment_method_id: string, customer_id: string, amount: int, currency: string, status: string, billing_processor_invoice_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)")
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription - Update
#
# PUT /subscriptions/{subscription_id}/update
# operationId: Update Subscription
export def "subscriptions-update Update-Subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  plan_id: string # Identifier for the associated plan_id.
  item_price_id: string # Identifier for the associated item_price_id for the subscription.
]: any -> record<id: string, merchant_reference_id: string, status: string, plan_id: string, item_price_id: string, profile_id: string, client_secret: string, merchant_id: string, coupon_code: string, customer_id: string, payment: record<payment_id: string, status: string, amount: int, currency: string, profile_id: record, connector: string, payment_method_id: string, return_url: string, next_action: record, payment_experience: record, error_code: string, error_message: string, payment_method_type: record, client_secret: string, billing: record<address: record, phone: record, email: string>, shipping: record<address: record, phone: record, email: string>, payment_type: record, payment_token: string>, invoice: record<id: string, subscription_id: string, merchant_id: string, profile_id: string, merchant_connector_id: string, payment_intent_id: record, payment_method_id: string, customer_id: string, amount: int, currency: string, status: string, billing_processor_invoice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/update")
  let body = {plan_id: $plan_id, item_price_id: $item_price_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription - Get Items
#
# GET /subscriptions/items
# operationId: Get Subscription Items
export def "subscriptions-items Get-Subscription-Items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of items to retrieve (nullable, format: int32)
  --offset: int # Number of items to skip (nullable, format: int32)
  --product-id: string # Filter by product ID (nullable)
  --item-type: string@item-type-completer # Filter by subscription item type plan or addon
  --X-Profile-Id: string # Profile ID for authentication
]: nothing -> table<item_id: string, name: string, description: string, price_id: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "item_type" $item_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions/items" $qp)
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription - Get Estimate
#
# GET /subscriptions/estimate
# operationId: Get Subscription Estimate
export def "subscriptions-estimate Get-Subscription-Estimate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plan-id: string # Plan ID for estimation
  --customer-id: string # Customer ID for personalized pricing (nullable)
  --coupon-id: string # Coupon ID to apply discount (nullable)
  --trial-days: int # Number of trial days (nullable, format: int32)
  --X-Profile-Id: string # Profile ID for authentication
]: nothing -> record<amount: int, currency: string, plan_id: string, item_price_id: string, coupon_code: string, customer_id: record, line_items: table<item_id: string, item_type: string, description: string, amount: int, currency: string, quantity: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plan_id" $plan_id "scalar") (serialize-qp "customer_id" $customer_id "scalar") (serialize-qp "coupon_id" $coupon_id "scalar") (serialize-qp "trial_days" $trial_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions/estimate" $qp)
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription - Pause Subscription
#
# POST /subscriptions/{subscription_id}/pause
# operationId: Pause Subscription
export def "subscriptions-pause Pause-Subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  --pause-option: any # nullable
  --pause-at: string # Optional date when the subscription should be paused (if not provided, pauses immediately) (nullable)
]: any -> record<id: string, status: string, merchant_reference_id: string, profile_id: string, merchant_id: string, customer_id: string, paused_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/pause")
  let body = {pause_option: $pause_option, pause_at: $pause_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription - Resume Subscription
#
# POST /subscriptions/{subscription_id}/resume
# operationId: Resume Subscription
export def "subscriptions-resume Resume-Subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  --resume-option: any # nullable
  --resume-date: string # Optional date when the subscription should be resumed (if not provided, resumes immediately) (nullable)
  --charges-handling: any # nullable
  --unpaid-invoices-handling: any # nullable
]: any -> record<id: string, status: string, merchant_reference_id: string, profile_id: string, merchant_id: string, customer_id: string, next_billing_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/resume")
  let body = {resume_option: $resume_option, resume_date: $resume_date, charges_handling: $charges_handling, unpaid_invoices_handling: $unpaid_invoices_handling} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription - Cancel Subscription
#
# POST /subscriptions/{subscription_id}/cancel
# operationId: Cancel Subscription
export def "subscriptions-cancel Cancel-Subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Profile-Id: string # Profile ID for authentication
  --cancel-option: any # nullable
  --cancel-at: string # Optional date when the subscription should be cancelled (if not provided, cancels immediately) (nullable)
  --unbilled-charges-option: any # nullable
  --credit-option-for-current-term-charges: any # nullable
  --account-receivables-handling: any # nullable
  --refundable-credits-handling: any # nullable
  --cancel-reason-code: string # Reason code for canceling the subscription (nullable)
]: any -> record<id: string, status: string, merchant_reference_id: string, profile_id: string, merchant_id: string, customer_id: string, cancelled_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/cancel")
  let body = {cancel_option: $cancel_option, cancel_at: $cancel_at, unbilled_charges_option: $unbilled_charges_option, credit_option_for_current_term_charges: $credit_option_for_current_term_charges, account_receivables_handling: $account_receivables_handling, refundable_credits_handling: $refundable_credits_handling, cancel_reason_code: $cancel_reason_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Profile-Id": $X_Profile_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Card Issuer - Create
#
# POST /card_issuers
# operationId: Create Card Issuer
export def "card-issuers Create-Card-Issuer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  issuer_name: string # The name of the card issuer to add (e.g. STATE BANK OF INDIA)
]: any -> record<id: string, issuer_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/card_issuers")
  let body = {issuer_name: $issuer_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Card Issuer - List
#
# GET /card_issuers
# operationId: List Card Issuers
export def "card-issuers List-Card-Issuers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Optional search term to filter issuers by name (nullable)
  --limit: int # Maximum number of results to return (nullable, format: int32)
]: nothing -> record<issuers: table<id: string, issuer_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/card_issuers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Card Issuer - Update
#
# PUT /card_issuers/{id}
# operationId: Update Card Issuer
export def "card-issuers Update-Card-Issuer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  issuer_name: string # The new name for the card issuer (e.g. STATE BANK OF INDIA UPDATED)
]: any -> record<id: string, issuer_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/card_issuers/($id)")
  let body = {issuer_name: $issuer_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Card Issuer - Delete
#
# DELETE /card_issuers/{id}
# operationId: Delete Card Issuer
export def "card-issuers Delete-Card-Issuer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/card_issuers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
