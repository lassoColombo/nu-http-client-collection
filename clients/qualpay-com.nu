# Auto-generated client for Qualpay Payment Gateway API v1.7.0
# Source: https://api.apis.guru/v2/specs/qualpay.com/1.7.0/swagger.json
# Auth: --token flag or $env.QUALPAY_PAYMENT_GATEWAY_API_TOKEN

const BASE_URL = "https://api-test.qualpay.com/pg"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o QUALPAY_PAYMENT_GATEWAY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api-test.qualpay.com/pg"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ardef get-card-type-information" } } | get name | first)
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

# Get Card type Information for Visa, Mastercard, and Discover
#
# POST /ardef
# operationId: Get Card Type Information 
export def "ardef get-card-type-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number. (e.g. 4111111111111111)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
]: any -> record<funding_source: string, ind_comm_level2: string, ind_comm_level3: string, issuer_country: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ardef")
  let req_body = {"card_number": $card_number, "merchant_id": $merchant_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Authorize Transaction
#
# POST /auth
# operationId: Authorization
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "auth create-authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # Format: Variable length, up to 12,2 NDescription: Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.Conditional Requirement: Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # Format: Fixed length, 6 ANDescription: This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.Conditional Requirement: This field is required in force request type. (e.g. 620376)
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 ANDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # Format: Fixed length, 28 ANDescription: Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # Format: Variable lengthDescription: [Deprecated use email_address] Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # Format: Variable length, up to 32 ANDescription: Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. JOECUSTOMER_12)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # Format: Variable length, up to 21 ANDescription: When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # Format: Fixed length, 9 ANDescription: For use by merchants using negative option marketing. This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: END DSCNTEND OFFEREND PROMOEND TRIAL (e.g. END PROMO)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --duplicate-seconds: int # Format: Variable length, up to 5 NDescription: Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # Default: falseDescription: When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # Format: Variable length, up to 36 ANDescription: Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --fbo-id: int # Format: Variable length, up to 16 NDescription: For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # Format: Variable lengthDescription: JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: quantity (7N) description (26AN) unit_of_measure (12AN) product_code (12AN) - cannot be all zeroes debit_credit_ind (1 AN) unit_cost (12,2N) Optional subfields: type_of_supply (2AN) - visa onlycommodity_code - visa only(12AN)Conditional Requirement: This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # Format: Variable length, up to 32 ANDescription: Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # Format: Fixed length, 1 ANDescription: MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --partial-auth: oneof<nothing, bool> # Default: falseDescription: This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request on a different card is needed to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # Format: Fixed length, 32 ANDescription: PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # Format: Variable length, up to 25 ANDescription: Purchase Identifier (also referred to as the invoice number generated by the merchant).Conditional Requirement: This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # Format: Variable length, up to 10 NDescription: Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --tran-currency: int # Format: Fixed length, 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # Format: Fixed length, 28 ANDescription: Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let req_body = {"amt_convenience_fee": $amt_convenience_fee, "amt_fbo": $amt_fbo, "amt_tax": $amt_tax, "amt_tran": $amt_tran, "amt_tran_fee": $amt_tran_fee, "auth_code": $auth_code, "avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "cavv_3ds": $cavv_3ds, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "customer_email": $customer_email, "customer_id": $customer_id, "cvv2": $cvv2, "dba_name": $dba_name, "dba_suffix": $dba_suffix, "dda_number": $dda_number, "developer_id": $developer_id, "duplicate_seconds": $duplicate_seconds, "echo_fields": $echo_fields, "email_address": $email_address, "email_receipt": $email_receipt, "emv_tran_id": $emv_tran_id, "exp_date": $exp_date, "fbo_id": $fbo_id, "line_items": $line_items, "loc_id": $loc_id, "mc_ucaf_data": $mc_ucaf_data, "mc_ucaf_ind": $mc_ucaf_ind, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "partial_auth": $partial_auth, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "pg_id": $pg_id, "profile_id": $profile_id, "purchase_id": $purchase_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "subscription_id": $subscription_id, "tokenize": $tokenize, "tr_number": $tr_number, "tran_currency": $tran_currency, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id, "xid_3ds": $xid_3ds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Close Batch
#
# POST /batchClose
# operationId: Batch Close
export def "batch-close close" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --tran-currency: int # Format: Variable length, up to 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> record<batch_info: string, echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batchClose")
  let req_body = {"developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "tran_currency": $tran_currency, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Capture an Authorized Transaction
#
# POST /capture/{pgIdOrig}
# operationId: Capture
export def "capture create" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # Format: Variable length, up to 12,2 NDescription: Total amount to capture. The amount must be less than or equal to the authorized amount. (format: double, e.g. 1193.5)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id_orig: (encode-path-segment $pg_id_orig)} | format pattern "/capture/{pg_id_orig}"))
  let req_body = {"amt_tran": $amt_tran, "developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Issue Credit to Cardholder
#
# POST /credit
# operationId: Credit
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "credit create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # Format: Variable length, up to 12,2 NDescription: Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.Conditional Requirement: Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # Format: Fixed length, 6 ANDescription: This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.Conditional Requirement: This field is required in force request type. (e.g. 620376)
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 ANDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # Format: Fixed length, 28 ANDescription: Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # Format: Variable lengthDescription: [Deprecated use email_address] Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # Format: Variable length, up to 32 ANDescription: Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. JOECUSTOMER_12)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # Format: Variable length, up to 21 ANDescription: When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # Format: Fixed length, 9 ANDescription: For use by merchants using negative option marketing. This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: END DSCNTEND OFFEREND PROMOEND TRIAL (e.g. END PROMO)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --duplicate-seconds: int # Format: Variable length, up to 5 NDescription: Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # Default: falseDescription: When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # Format: Variable length, up to 36 ANDescription: Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --fbo-id: int # Format: Variable length, up to 16 NDescription: For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # Format: Variable lengthDescription: JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: quantity (7N) description (26AN) unit_of_measure (12AN) product_code (12AN) - cannot be all zeroes debit_credit_ind (1 AN) unit_cost (12,2N) Optional subfields: type_of_supply (2AN) - visa onlycommodity_code - visa only(12AN)Conditional Requirement: This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # Format: Variable length, up to 32 ANDescription: Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # Format: Fixed length, 1 ANDescription: MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --partial-auth: oneof<nothing, bool> # Default: falseDescription: This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request on a different card is needed to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # Format: Fixed length, 32 ANDescription: PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # Format: Variable length, up to 25 ANDescription: Purchase Identifier (also referred to as the invoice number generated by the merchant).Conditional Requirement: This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # Format: Variable length, up to 10 NDescription: Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --tran-currency: int # Format: Fixed length, 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # Format: Fixed length, 28 ANDescription: Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit")
  let req_body = {"amt_convenience_fee": $amt_convenience_fee, "amt_fbo": $amt_fbo, "amt_tax": $amt_tax, "amt_tran": $amt_tran, "amt_tran_fee": $amt_tran_fee, "auth_code": $auth_code, "avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "cavv_3ds": $cavv_3ds, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "customer_email": $customer_email, "customer_id": $customer_id, "cvv2": $cvv2, "dba_name": $dba_name, "dba_suffix": $dba_suffix, "dda_number": $dda_number, "developer_id": $developer_id, "duplicate_seconds": $duplicate_seconds, "echo_fields": $echo_fields, "email_address": $email_address, "email_receipt": $email_receipt, "emv_tran_id": $emv_tran_id, "exp_date": $exp_date, "fbo_id": $fbo_id, "line_items": $line_items, "loc_id": $loc_id, "mc_ucaf_data": $mc_ucaf_data, "mc_ucaf_ind": $mc_ucaf_ind, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "partial_auth": $partial_auth, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "pg_id": $pg_id, "profile_id": $profile_id, "purchase_id": $purchase_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "subscription_id": $subscription_id, "tokenize": $tokenize, "tr_number": $tr_number, "tran_currency": $tran_currency, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id, "xid_3ds": $xid_3ds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Send Transaction Receipt Email
#
# POST /emailReceipt/{pgId}
# operationId: Send Receipt
export def "email-receipt send" [
  pg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  email_address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --logo-url: string # ANDescription: A link to the logo image that will be included in the transaction receipt. (e.g. https://app.qualpay.com/shared/images/qp-icon.png)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this email receipt request applies. (format: int64, e.g. 212100026512)
]: any -> record<pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id: (encode-path-segment $pg_id)} | format pattern "/emailReceipt/{pg_id}"))
  let req_body = {"developer_id": $developer_id, "email_address": $email_address, "logo_url": $logo_url, "merchant_id": $merchant_id, "vendor_id": $vendor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Expire Token
#
# POST /expireToken
# operationId: Expire
export def "expire-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this expire token request applies. (format: int64, e.g. 212100026512)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/expireToken")
  let req_body = {"card_id": $card_id, "developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Force Transaction Approval
#
# POST /force
# operationId: Force
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "force create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # Format: Variable length, up to 12,2 NDescription: Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.Conditional Requirement: Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # Format: Fixed length, 6 ANDescription: This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.Conditional Requirement: This field is required in force request type. (e.g. 620376)
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 ANDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # Format: Fixed length, 28 ANDescription: Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # Format: Variable lengthDescription: [Deprecated use email_address] Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # Format: Variable length, up to 32 ANDescription: Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. JOECUSTOMER_12)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # Format: Variable length, up to 21 ANDescription: When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # Format: Fixed length, 9 ANDescription: For use by merchants using negative option marketing. This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: END DSCNTEND OFFEREND PROMOEND TRIAL (e.g. END PROMO)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --duplicate-seconds: int # Format: Variable length, up to 5 NDescription: Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # Default: falseDescription: When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # Format: Variable length, up to 36 ANDescription: Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --fbo-id: int # Format: Variable length, up to 16 NDescription: For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # Format: Variable lengthDescription: JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: quantity (7N) description (26AN) unit_of_measure (12AN) product_code (12AN) - cannot be all zeroes debit_credit_ind (1 AN) unit_cost (12,2N) Optional subfields: type_of_supply (2AN) - visa onlycommodity_code - visa only(12AN)Conditional Requirement: This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # Format: Variable length, up to 32 ANDescription: Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # Format: Fixed length, 1 ANDescription: MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --partial-auth: oneof<nothing, bool> # Default: falseDescription: This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request on a different card is needed to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # Format: Fixed length, 32 ANDescription: PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # Format: Variable length, up to 25 ANDescription: Purchase Identifier (also referred to as the invoice number generated by the merchant).Conditional Requirement: This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # Format: Variable length, up to 10 NDescription: Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --tran-currency: int # Format: Fixed length, 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # Format: Fixed length, 28 ANDescription: Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/force")
  let req_body = {"amt_convenience_fee": $amt_convenience_fee, "amt_fbo": $amt_fbo, "amt_tax": $amt_tax, "amt_tran": $amt_tran, "amt_tran_fee": $amt_tran_fee, "auth_code": $auth_code, "avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "cavv_3ds": $cavv_3ds, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "customer_email": $customer_email, "customer_id": $customer_id, "cvv2": $cvv2, "dba_name": $dba_name, "dba_suffix": $dba_suffix, "dda_number": $dda_number, "developer_id": $developer_id, "duplicate_seconds": $duplicate_seconds, "echo_fields": $echo_fields, "email_address": $email_address, "email_receipt": $email_receipt, "emv_tran_id": $emv_tran_id, "exp_date": $exp_date, "fbo_id": $fbo_id, "line_items": $line_items, "loc_id": $loc_id, "mc_ucaf_data": $mc_ucaf_data, "mc_ucaf_ind": $mc_ucaf_ind, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "partial_auth": $partial_auth, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "pg_id": $pg_id, "profile_id": $profile_id, "purchase_id": $purchase_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "subscription_id": $subscription_id, "tokenize": $tokenize, "tr_number": $tr_number, "tran_currency": $tran_currency, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id, "xid_3ds": $xid_3ds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Recharge Previously Settled Transaction
#
# POST /recharge/{pgIdOrig}
# operationId: Recharge
export def "recharge create" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # Format: Variable length, up to 12,2 NDescription: Amount to recharge using the payment data from a previous transaction. (format: double, e.g. 1139.5)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id_orig: (encode-path-segment $pg_id_orig)} | format pattern "/recharge/{pg_id_orig}"))
  let req_body = {"amt_tran": $amt_tran, "developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Refund Previously Captured Transaction
#
# POST /refund/{pgIdOrig}
# operationId: Refund
export def "refund create" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # Format: Variable length, up to 12,2 NDescription: Total amount to refund. Partial refunds are allowed by providing an amount in this field that is less than the total original transaction amount. (format: double, e.g. 1193.5)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this refund request applies. (format: int64, e.g. 212100026512)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id_orig: (encode-path-segment $pg_id_orig)} | format pattern "/refund/{pg_id_orig}"))
  let req_body = {"amt_tran": $amt_tran, "developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Sale (Auth + Capture)
#
# POST /sale
# operationId: Sale
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "sale create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # Format: Variable length, up to 12,2 NDescription: Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.Conditional Requirement: Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # Format: Variable length, up to 12,2 NDescription: Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # Format: Variable length, up to 8,2 NDescription: Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # Format: Fixed length, 6 ANDescription: This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.Conditional Requirement: This field is required in force request type. (e.g. 620376)
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 ANDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # Format: Fixed length, 28 ANDescription: Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # Format: Variable lengthDescription: [Deprecated use email_address] Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # Format: Variable length, up to 32 ANDescription: Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. JOECUSTOMER_12)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # Format: Variable length, up to 21 ANDescription: When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # Format: Fixed length, 9 ANDescription: For use by merchants using negative option marketing. This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: END DSCNTEND OFFEREND PROMOEND TRIAL (e.g. END PROMO)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --duplicate-seconds: int # Format: Variable length, up to 5 NDescription: Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of email addresses to which the transaction receipt should be sent to. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # Default: falseDescription: When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # Format: Variable length, up to 36 ANDescription: Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --fbo-id: int # Format: Variable length, up to 16 NDescription: For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # Format: Variable lengthDescription: JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: quantity (7N) description (26AN) unit_of_measure (12AN) product_code (12AN) - cannot be all zeroes debit_credit_ind (1 AN) unit_cost (12,2N) Optional subfields: type_of_supply (2AN) - visa onlycommodity_code - visa only(12AN)Conditional Requirement: This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # Format: Variable length, up to 32 ANDescription: Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # Format: Fixed length, 1 ANDescription: MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --partial-auth: oneof<nothing, bool> # Default: falseDescription: This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request on a different card is needed to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # Format: Fixed length, 32 ANDescription: PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # Format: Variable length, up to 25 ANDescription: Purchase Identifier (also referred to as the invoice number generated by the merchant).Conditional Requirement: This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # Format: Variable length, up to 10 NDescription: Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --tran-currency: int # Format: Fixed length, 3 NDefault: 840Description: ISO numeric currency code for the transaction. Refer to Country Codes (/developer/api/reference#country-codes) for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # Format: Fixed length, 28 ANDescription: Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sale")
  let req_body = {"amt_convenience_fee": $amt_convenience_fee, "amt_fbo": $amt_fbo, "amt_tax": $amt_tax, "amt_tran": $amt_tran, "amt_tran_fee": $amt_tran_fee, "auth_code": $auth_code, "avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "cavv_3ds": $cavv_3ds, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "customer_email": $customer_email, "customer_id": $customer_id, "cvv2": $cvv2, "dba_name": $dba_name, "dba_suffix": $dba_suffix, "dda_number": $dda_number, "developer_id": $developer_id, "duplicate_seconds": $duplicate_seconds, "echo_fields": $echo_fields, "email_address": $email_address, "email_receipt": $email_receipt, "emv_tran_id": $emv_tran_id, "exp_date": $exp_date, "fbo_id": $fbo_id, "line_items": $line_items, "loc_id": $loc_id, "mc_ucaf_data": $mc_ucaf_data, "mc_ucaf_ind": $mc_ucaf_ind, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "partial_auth": $partial_auth, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "pg_id": $pg_id, "profile_id": $profile_id, "purchase_id": $purchase_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "subscription_id": $subscription_id, "tokenize": $tokenize, "tr_number": $tr_number, "tran_currency": $tran_currency, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id, "xid_3ds": $xid_3ds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Tokenize Card
#
# POST /tokenize
# operationId: Tokenize
export def "tokenize create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 NDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Fixed length, 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number in requests requiring cardholder account data.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79Description: Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of account holder email addresses. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  exp_date: string # Format: Fixed length, 4 N(MMYY format)Description: Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --single-use: oneof<nothing, bool> # Default: falseDescription: In a tokenize request, setting the single_use field to "true" will cause a single-use token to be generated. This token will expire in 10 minutes or when first used. (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this tokenize request applies. (format: int64, e.g. 212100026512)
]: any -> record<card_id: string, card_number: string, echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokenize")
  let req_body = {"avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "client_ip": $client_ip, "cvv2": $cvv2, "dda_number": $dda_number, "developer_id": $developer_id, "echo_fields": $echo_fields, "email_address": $email_address, "exp_date": $exp_date, "loc_id": $loc_id, "merchant_id": $merchant_id, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "single_use": $single_use, "tr_number": $tr_number, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Verify Card
#
# POST /verify
# operationId: Verify
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "verify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avs-address: string # Format: Variable length, up to 20 ANDescription: Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # Format: Variable length, up to 9 NDescription: Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.Conditional Requirement: This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # Format: Variable length, up to 32 ANDescription: Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 86e1b00d9b0811e68df3069d8f743581)
  card_number: string # Format: Variable length, up to 19 NDescription: Cardholder's card number. Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 4111111111111111)
  --card-swipe: string # Format: Variable length, up to 79 ANDescription: Contains either track 1 or track 2 data magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # Format: Variable length, up to 64 ANDescription: When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --client-ip: string # Format: Variable length ANDescription: Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # Format: Variable length, up to 17 ANDescription: Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --cvv2: string # Format: Variable length, up to 4 NDescription: CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dda-number: string # Format: Variable length, up to 17 NDescription: Owner's account number at the bank. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 3456776866)
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list<string> # ANDescription: An array of account holder email addresses. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --exp-date: string # Format: Fixed length, 4 N, MMYY formatDescription: Expiration date of cardholder card number. Required when the field card_number is present. If card_swipe is present in the request, this field must NOT be present. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 0921)
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --merch-ref-num: string # Format: Variable length, up to 128 ANDescription: Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # Format: Fixed length, 1 NDefault: 7Description: Indicates type of MOTO transaction: 0 = Card Present (not MOTO/e-Commerce) 1 = One Time MOTO transaction2 = Recurring 3 = Installment 5 = Full 3D-Secure transaction6 = Merchant 3D-Secure transaction7 = e-Commerce Channel Encrypted (SSL) (e.g. 1)
  --payload-apple-pay: string # Format: Variable lengthDescription: Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # Format: Variable lengthDescription: Google Pay payload (e.g. xxxxxxx)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --tokenize: oneof<nothing, bool> # Default: falseDescription: In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present. (e.g. true)
  --tr-number: string # Format: Fixed length, 9 NDescription: Bank transit/routing number. Applicable for ACH payments.Conditional Requirement: Refer to Card or Bank Account Data Sources and Conditional Requirements (/developer/api/reference#card-source-conditional-requirements) (e.g. 011111111)
  --type-id: string # Format: Fixed length, 1 ANDefault: CDescription: Bank Account Type. Applicable for ACH payments. Possible values are: C = Personal checking accountS = Personal savings accountK = Business checking accountV = Business savings account (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> record<auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, card_number: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verify")
  let req_body = {"avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "cvv2": $cvv2, "dda_number": $dda_number, "developer_id": $developer_id, "echo_fields": $echo_fields, "email_address": $email_address, "exp_date": $exp_date, "loc_id": $loc_id, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "tokenize": $tokenize, "tr_number": $tr_number, "type_id": $type_id, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Void a Previously Authorized Transaction
#
# POST /void/{pgIdOrig}
# operationId: Void
export def "void create" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # Format: Variable length, up to 32 ANDescription: Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay. Suggested usage is softwareABCv1.0 or companyXYZv2.0. (e.g. QualpayV1.2)
  --echo-fields: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # Format: Variable length, up to 4 NDescription: When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # Format: Variable length, up to 12 NDescription: Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # Format: Fixed length, 20 NDescription: Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # Format: Variable lengthDescription: This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # Format: Variable length, up to 4 NDescription: This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.Conditional Requirement: This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # Format: Variable length, up to 15 NDescription: This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # Format: Variable length, up to 12 NDescription: Identifies the vendor to which this void request applies. (format: int64, e.g. 212100026512)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id_orig: (encode-path-segment $pg_id_orig)} | format pattern "/void/{pg_id_orig}"))
  let req_body = {"developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
