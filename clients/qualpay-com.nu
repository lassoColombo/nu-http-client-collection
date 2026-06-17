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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://api-test.qualpay.com/pg"] }
def auth-scheme-completer [] { ["basic"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ardef post" } } | get name | first)
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
export def "ardef post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  card_number: string # <strong>Format: </strong>Variable length, up to 19 N<br><strong>Description: </strong>Cardholder's card number. (e.g. 4111111111111111)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
]: any -> record<funding_source: string, ind_comm_level2: string, ind_comm_level3: string, issuer_country: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ardef")
  let body = {"card_number": $card_number, "merchant_id": $merchant_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorize Transaction
#
# POST /auth
# operationId: Authorization
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "auth post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # <strong>Format: </strong>Variable length, up to 8,2 N<br><strong>Description: </strong>Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.<br><strong>Conditional Requirement: </strong>Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # <strong>Format: </strong>Variable length, up to 8,2 N<br><strong>Description: </strong>Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # <strong>Format: </strong>Fixed length, 6 AN<br><strong>Description: </strong>This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.<br><strong>Conditional Requirement: </strong>This field is required in force request type. (e.g. 620376)
  --avs-address: string # <strong>Format: </strong>Variable length, up to 20 AN<br><strong>Description: </strong>Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # <strong>Format: </strong>Variable length, up to 9 AN<br><strong>Description: </strong>Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.<br><strong>Conditional Requirement: </strong>This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # <strong>Format: </strong>Variable length, up to 19 N<br><strong>Description: </strong>Cardholder's card number.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 4111111111111111)
  --card-swipe: string # <strong>Format: </strong>Variable length, up to 79 AN<br><strong>Description: </strong>Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # <strong>Format: </strong>Variable length, up to 64 AN<br><strong>Description: </strong>When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # <strong>Format: </strong>Fixed length, 28 AN<br><strong>Description: </strong>Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # <strong>Format: </strong>Variable length AN<br><strong>Description: </strong>Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # <strong>Format: </strong>Variable length, up to 17 AN<br><strong>Description: </strong>Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong><strong>[Deprecated use email_address]</strong> Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. <br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. JOECUSTOMER_12)
  --cvv2: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # <strong>Format: </strong>Variable length, up to 21 AN<br><strong>Description: </strong>When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.<br>Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # <strong>Format: </strong>Fixed length, 9 AN<br><strong>Description: </strong>For use by merchants using negative option marketing.  This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: <ul><li>END DSCNT</li><li>END OFFER</li><li>END PROMO</li><li>END TRIAL</li></ul> (e.g. END PROMO)
  --dda-number: string # <strong>Format: </strong>Variable length, up to 17 N<br><strong>Description: </strong>Owner's account number at the bank. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 3456776866)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --duplicate-seconds: int # <strong>Format: </strong>Variable length, up to 5 N<br><strong>Description: </strong>Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list #  AN<br><strong>Description: </strong>An array of email addresses to which the transaction receipt should be sent to.  (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # <strong>Format: </strong>Variable length, up to 36 AN<br><strong>Description: </strong>Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # <strong>Format: </strong>Fixed length, 4 N, MMYY format<br><strong>Description: </strong>Expiration date of cardholder card number.  When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 0921)
  --fbo-id: int # <strong>Format: </strong>Variable length, up to 16 N<br><strong>Description: </strong>For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: <br>quantity (7N)<br> description (26AN)<br> unit_of_measure (12AN)<br> product_code (12AN) - cannot be all zeroes<br> debit_credit_ind (1 AN)<br> unit_cost (12,2N)<br> Optional subfields: <br>type_of_supply (2AN) - visa only<br>commodity_code - visa only(12AN)<br><strong>Conditional Requirement: </strong> This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Description: </strong>MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # <strong>Format: </strong>Variable length, up to 128 AN<br><strong>Description: </strong>Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # <strong>Format: </strong>Fixed length, 1 N<br><strong>Default: </strong>7<br><strong>Description: </strong>Indicates type of MOTO transaction: <ul><li>0 = Card Present (not MOTO/e-Commerce)</li><li> 1 = One Time MOTO transaction</li><li>2 = Recurring </li><li>3 = Installment </li><li>5 = Full 3D-Secure transaction</li><li>6 = Merchant 3D-Secure transaction</li><li>7 = e-Commerce Channel Encrypted (SSL)</li></ul> (e.g. 1)
  --partial-auth: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request  on a different card is needed  to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # <strong>Format: </strong>Variable length, up to 25 AN<br><strong>Description: </strong>Purchase Identifier (also referred to as the invoice number generated by the merchant).<br><strong>Conditional Requirement: </strong> This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # <strong>Format: </strong>Variable length, up to 10 N<br><strong>Description: </strong>Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. true)
  --tr-number: string # <strong>Format: </strong>Fixed length, 9 N<br><strong>Description: </strong>Bank transit/routing number. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 011111111)
  --tran-currency: int # <strong>Format: </strong>Fixed length, 3 N<br><strong>Default: </strong>840<br><strong>Description: </strong>ISO numeric currency code for the transaction. Refer to <a href="/developer/api/reference#country-codes"target="_blank">Country Codes</a> for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Default: </strong>C<br><strong>Description: </strong>Bank Account Type. Applicable for ACH payments. Possible values are: <ul><li>C = Personal checking account</li><li>S = Personal savings account</li><li>K = Business checking account</li><li>V = Business savings account</li></ul> (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # <strong>Format: </strong>Fixed length, 28 AN<br><strong>Description: </strong>Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let body = {"amt_convenience_fee": $amt_convenience_fee, "amt_fbo": $amt_fbo, "amt_tax": $amt_tax, "amt_tran": $amt_tran, "amt_tran_fee": $amt_tran_fee, "auth_code": $auth_code, "avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "cavv_3ds": $cavv_3ds, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "customer_email": $customer_email, "customer_id": $customer_id, "cvv2": $cvv2, "dba_name": $dba_name, "dba_suffix": $dba_suffix, "dda_number": $dda_number, "developer_id": $developer_id, "duplicate_seconds": $duplicate_seconds, "echo_fields": $echo_fields, "email_address": $email_address, "email_receipt": $email_receipt, "emv_tran_id": $emv_tran_id, "exp_date": $exp_date, "fbo_id": $fbo_id, "line_items": $line_items, "loc_id": $loc_id, "mc_ucaf_data": $mc_ucaf_data, "mc_ucaf_ind": $mc_ucaf_ind, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "partial_auth": $partial_auth, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "pg_id": $pg_id, "profile_id": $profile_id, "purchase_id": $purchase_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "subscription_id": $subscription_id, "tokenize": $tokenize, "tr_number": $tr_number, "tran_currency": $tran_currency, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id, "xid_3ds": $xid_3ds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Close Batch
#
# POST /batchClose
# operationId: Batch Close
export def "batch-close post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --tran-currency: int # <strong>Format: </strong>Variable length, up to 3 N<br><strong>Default: </strong>840<br><strong>Description: </strong>ISO numeric currency code for the transaction. Refer to <a href="/developer/api/reference#country-codes"target="_blank">Country Codes</a> for a list of currency codes. (format: int32, e.g. 840)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> record<batch_info: string, echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batchClose")
  let body = {"developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "tran_currency": $tran_currency, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Capture an Authorized Transaction
#
# POST /capture/{pgIdOrig}
# operationId: Capture
export def "capture post" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount to capture. The amount must be less than or equal to the authorized amount. (format: double, e.g. 1193.5)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id_orig: $pg_id_orig} | format pattern "/capture/{pg_id_orig}"))
  let body = {"amt_tran": $amt_tran, "developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Issue Credit to Cardholder
#
# POST /credit
# operationId: Credit
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "credit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # <strong>Format: </strong>Variable length, up to 8,2 N<br><strong>Description: </strong>Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.<br><strong>Conditional Requirement: </strong>Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # <strong>Format: </strong>Variable length, up to 8,2 N<br><strong>Description: </strong>Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # <strong>Format: </strong>Fixed length, 6 AN<br><strong>Description: </strong>This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.<br><strong>Conditional Requirement: </strong>This field is required in force request type. (e.g. 620376)
  --avs-address: string # <strong>Format: </strong>Variable length, up to 20 AN<br><strong>Description: </strong>Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # <strong>Format: </strong>Variable length, up to 9 AN<br><strong>Description: </strong>Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.<br><strong>Conditional Requirement: </strong>This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # <strong>Format: </strong>Variable length, up to 19 N<br><strong>Description: </strong>Cardholder's card number.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 4111111111111111)
  --card-swipe: string # <strong>Format: </strong>Variable length, up to 79 AN<br><strong>Description: </strong>Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # <strong>Format: </strong>Variable length, up to 64 AN<br><strong>Description: </strong>When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # <strong>Format: </strong>Fixed length, 28 AN<br><strong>Description: </strong>Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # <strong>Format: </strong>Variable length AN<br><strong>Description: </strong>Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # <strong>Format: </strong>Variable length, up to 17 AN<br><strong>Description: </strong>Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong><strong>[Deprecated use email_address]</strong> Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. <br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. JOECUSTOMER_12)
  --cvv2: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # <strong>Format: </strong>Variable length, up to 21 AN<br><strong>Description: </strong>When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.<br>Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # <strong>Format: </strong>Fixed length, 9 AN<br><strong>Description: </strong>For use by merchants using negative option marketing.  This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: <ul><li>END DSCNT</li><li>END OFFER</li><li>END PROMO</li><li>END TRIAL</li></ul> (e.g. END PROMO)
  --dda-number: string # <strong>Format: </strong>Variable length, up to 17 N<br><strong>Description: </strong>Owner's account number at the bank. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 3456776866)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --duplicate-seconds: int # <strong>Format: </strong>Variable length, up to 5 N<br><strong>Description: </strong>Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list #  AN<br><strong>Description: </strong>An array of email addresses to which the transaction receipt should be sent to.  (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # <strong>Format: </strong>Variable length, up to 36 AN<br><strong>Description: </strong>Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # <strong>Format: </strong>Fixed length, 4 N, MMYY format<br><strong>Description: </strong>Expiration date of cardholder card number.  When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 0921)
  --fbo-id: int # <strong>Format: </strong>Variable length, up to 16 N<br><strong>Description: </strong>For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: <br>quantity (7N)<br> description (26AN)<br> unit_of_measure (12AN)<br> product_code (12AN) - cannot be all zeroes<br> debit_credit_ind (1 AN)<br> unit_cost (12,2N)<br> Optional subfields: <br>type_of_supply (2AN) - visa only<br>commodity_code - visa only(12AN)<br><strong>Conditional Requirement: </strong> This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Description: </strong>MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # <strong>Format: </strong>Variable length, up to 128 AN<br><strong>Description: </strong>Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # <strong>Format: </strong>Fixed length, 1 N<br><strong>Default: </strong>7<br><strong>Description: </strong>Indicates type of MOTO transaction: <ul><li>0 = Card Present (not MOTO/e-Commerce)</li><li> 1 = One Time MOTO transaction</li><li>2 = Recurring </li><li>3 = Installment </li><li>5 = Full 3D-Secure transaction</li><li>6 = Merchant 3D-Secure transaction</li><li>7 = e-Commerce Channel Encrypted (SSL)</li></ul> (e.g. 1)
  --partial-auth: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request  on a different card is needed  to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # <strong>Format: </strong>Variable length, up to 25 AN<br><strong>Description: </strong>Purchase Identifier (also referred to as the invoice number generated by the merchant).<br><strong>Conditional Requirement: </strong> This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # <strong>Format: </strong>Variable length, up to 10 N<br><strong>Description: </strong>Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. true)
  --tr-number: string # <strong>Format: </strong>Fixed length, 9 N<br><strong>Description: </strong>Bank transit/routing number. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 011111111)
  --tran-currency: int # <strong>Format: </strong>Fixed length, 3 N<br><strong>Default: </strong>840<br><strong>Description: </strong>ISO numeric currency code for the transaction. Refer to <a href="/developer/api/reference#country-codes"target="_blank">Country Codes</a> for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Default: </strong>C<br><strong>Description: </strong>Bank Account Type. Applicable for ACH payments. Possible values are: <ul><li>C = Personal checking account</li><li>S = Personal savings account</li><li>K = Business checking account</li><li>V = Business savings account</li></ul> (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # <strong>Format: </strong>Fixed length, 28 AN<br><strong>Description: </strong>Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit")
  let body = {"amt_convenience_fee": $amt_convenience_fee, "amt_fbo": $amt_fbo, "amt_tax": $amt_tax, "amt_tran": $amt_tran, "amt_tran_fee": $amt_tran_fee, "auth_code": $auth_code, "avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "cavv_3ds": $cavv_3ds, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "customer_email": $customer_email, "customer_id": $customer_id, "cvv2": $cvv2, "dba_name": $dba_name, "dba_suffix": $dba_suffix, "dda_number": $dda_number, "developer_id": $developer_id, "duplicate_seconds": $duplicate_seconds, "echo_fields": $echo_fields, "email_address": $email_address, "email_receipt": $email_receipt, "emv_tran_id": $emv_tran_id, "exp_date": $exp_date, "fbo_id": $fbo_id, "line_items": $line_items, "loc_id": $loc_id, "mc_ucaf_data": $mc_ucaf_data, "mc_ucaf_ind": $mc_ucaf_ind, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "partial_auth": $partial_auth, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "pg_id": $pg_id, "profile_id": $profile_id, "purchase_id": $purchase_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "subscription_id": $subscription_id, "tokenize": $tokenize, "tr_number": $tr_number, "tran_currency": $tran_currency, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id, "xid_3ds": $xid_3ds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send Transaction Receipt Email
#
# POST /emailReceipt/{pgId}
# operationId: Send Receipt
export def "email-receipt post" [
  pg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  email_address: list #  AN<br><strong>Description: </strong>An array of email addresses to which the transaction receipt should be sent to.  (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --logo-url: string #  AN<br><strong>Description: </strong>A link to the logo image that will be included in the transaction receipt.  (e.g. https://app.qualpay.com/shared/images/qp-icon.png)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this email receipt request applies. (format: int64, e.g. 212100026512)
]: any -> record<pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id: $pg_id} | format pattern "/emailReceipt/{pg_id}"))
  let body = {"developer_id": $developer_id, "email_address": $email_address, "logo_url": $logo_url, "merchant_id": $merchant_id, "vendor_id": $vendor_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Expire Token
#
# POST /expireToken
# operationId: Expire
export def "expire-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  card_id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>Card ID received from a tokenization request. (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this expire token request applies. (format: int64, e.g. 212100026512)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/expireToken")
  let body = {"card_id": $card_id, "developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Force Transaction Approval
#
# POST /force
# operationId: Force
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "force post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # <strong>Format: </strong>Variable length, up to 8,2 N<br><strong>Description: </strong>Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.<br><strong>Conditional Requirement: </strong>Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # <strong>Format: </strong>Variable length, up to 8,2 N<br><strong>Description: </strong>Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # <strong>Format: </strong>Fixed length, 6 AN<br><strong>Description: </strong>This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.<br><strong>Conditional Requirement: </strong>This field is required in force request type. (e.g. 620376)
  --avs-address: string # <strong>Format: </strong>Variable length, up to 20 AN<br><strong>Description: </strong>Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # <strong>Format: </strong>Variable length, up to 9 AN<br><strong>Description: </strong>Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.<br><strong>Conditional Requirement: </strong>This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # <strong>Format: </strong>Variable length, up to 19 N<br><strong>Description: </strong>Cardholder's card number.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 4111111111111111)
  --card-swipe: string # <strong>Format: </strong>Variable length, up to 79 AN<br><strong>Description: </strong>Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # <strong>Format: </strong>Variable length, up to 64 AN<br><strong>Description: </strong>When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # <strong>Format: </strong>Fixed length, 28 AN<br><strong>Description: </strong>Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # <strong>Format: </strong>Variable length AN<br><strong>Description: </strong>Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # <strong>Format: </strong>Variable length, up to 17 AN<br><strong>Description: </strong>Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong><strong>[Deprecated use email_address]</strong> Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. <br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. JOECUSTOMER_12)
  --cvv2: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # <strong>Format: </strong>Variable length, up to 21 AN<br><strong>Description: </strong>When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.<br>Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # <strong>Format: </strong>Fixed length, 9 AN<br><strong>Description: </strong>For use by merchants using negative option marketing.  This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: <ul><li>END DSCNT</li><li>END OFFER</li><li>END PROMO</li><li>END TRIAL</li></ul> (e.g. END PROMO)
  --dda-number: string # <strong>Format: </strong>Variable length, up to 17 N<br><strong>Description: </strong>Owner's account number at the bank. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 3456776866)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --duplicate-seconds: int # <strong>Format: </strong>Variable length, up to 5 N<br><strong>Description: </strong>Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list #  AN<br><strong>Description: </strong>An array of email addresses to which the transaction receipt should be sent to.  (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # <strong>Format: </strong>Variable length, up to 36 AN<br><strong>Description: </strong>Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # <strong>Format: </strong>Fixed length, 4 N, MMYY format<br><strong>Description: </strong>Expiration date of cardholder card number.  When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 0921)
  --fbo-id: int # <strong>Format: </strong>Variable length, up to 16 N<br><strong>Description: </strong>For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: <br>quantity (7N)<br> description (26AN)<br> unit_of_measure (12AN)<br> product_code (12AN) - cannot be all zeroes<br> debit_credit_ind (1 AN)<br> unit_cost (12,2N)<br> Optional subfields: <br>type_of_supply (2AN) - visa only<br>commodity_code - visa only(12AN)<br><strong>Conditional Requirement: </strong> This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Description: </strong>MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # <strong>Format: </strong>Variable length, up to 128 AN<br><strong>Description: </strong>Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # <strong>Format: </strong>Fixed length, 1 N<br><strong>Default: </strong>7<br><strong>Description: </strong>Indicates type of MOTO transaction: <ul><li>0 = Card Present (not MOTO/e-Commerce)</li><li> 1 = One Time MOTO transaction</li><li>2 = Recurring </li><li>3 = Installment </li><li>5 = Full 3D-Secure transaction</li><li>6 = Merchant 3D-Secure transaction</li><li>7 = e-Commerce Channel Encrypted (SSL)</li></ul> (e.g. 1)
  --partial-auth: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request  on a different card is needed  to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # <strong>Format: </strong>Variable length, up to 25 AN<br><strong>Description: </strong>Purchase Identifier (also referred to as the invoice number generated by the merchant).<br><strong>Conditional Requirement: </strong> This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # <strong>Format: </strong>Variable length, up to 10 N<br><strong>Description: </strong>Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. true)
  --tr-number: string # <strong>Format: </strong>Fixed length, 9 N<br><strong>Description: </strong>Bank transit/routing number. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 011111111)
  --tran-currency: int # <strong>Format: </strong>Fixed length, 3 N<br><strong>Default: </strong>840<br><strong>Description: </strong>ISO numeric currency code for the transaction. Refer to <a href="/developer/api/reference#country-codes"target="_blank">Country Codes</a> for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Default: </strong>C<br><strong>Description: </strong>Bank Account Type. Applicable for ACH payments. Possible values are: <ul><li>C = Personal checking account</li><li>S = Personal savings account</li><li>K = Business checking account</li><li>V = Business savings account</li></ul> (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # <strong>Format: </strong>Fixed length, 28 AN<br><strong>Description: </strong>Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/force")
  let body = {"amt_convenience_fee": $amt_convenience_fee, "amt_fbo": $amt_fbo, "amt_tax": $amt_tax, "amt_tran": $amt_tran, "amt_tran_fee": $amt_tran_fee, "auth_code": $auth_code, "avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "cavv_3ds": $cavv_3ds, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "customer_email": $customer_email, "customer_id": $customer_id, "cvv2": $cvv2, "dba_name": $dba_name, "dba_suffix": $dba_suffix, "dda_number": $dda_number, "developer_id": $developer_id, "duplicate_seconds": $duplicate_seconds, "echo_fields": $echo_fields, "email_address": $email_address, "email_receipt": $email_receipt, "emv_tran_id": $emv_tran_id, "exp_date": $exp_date, "fbo_id": $fbo_id, "line_items": $line_items, "loc_id": $loc_id, "mc_ucaf_data": $mc_ucaf_data, "mc_ucaf_ind": $mc_ucaf_ind, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "partial_auth": $partial_auth, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "pg_id": $pg_id, "profile_id": $profile_id, "purchase_id": $purchase_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "subscription_id": $subscription_id, "tokenize": $tokenize, "tr_number": $tr_number, "tran_currency": $tran_currency, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id, "xid_3ds": $xid_3ds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Recharge Previously Settled Transaction
#
# POST /recharge/{pgIdOrig}
# operationId: Recharge
export def "recharge post" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Amount to recharge using the payment data from a previous transaction. (format: double, e.g. 1139.5)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id_orig: $pg_id_orig} | format pattern "/recharge/{pg_id_orig}"))
  let body = {"amt_tran": $amt_tran, "developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refund Previously Captured Transaction
#
# POST /refund/{pgIdOrig}
# operationId: Refund
export def "refund post" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amt_tran: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount to refund. Partial refunds are allowed by providing an amount in this field that is less than the total original transaction amount. (format: double, e.g. 1193.5)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this refund request applies. (format: int64, e.g. 212100026512)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id_orig: $pg_id_orig} | format pattern "/refund/{pg_id_orig}"))
  let body = {"amt_tran": $amt_tran, "developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sale (Auth + Capture)
#
# POST /sale
# operationId: Sale
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "sale post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amt-convenience-fee: float # <strong>Format: </strong>Variable length, up to 8,2 N<br><strong>Description: </strong>Amount of convenience fee. A convenience fee is a fee charged to your customer for the "convenience" of being able to pay using an alternative payment channel outside your merchant's customary payment channel. Must be a flat/fixed fee amount per transaction. This field tracks the convenience fee amount for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2)
  --amt-fbo: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount of transaction to be transferred to the "for benefit of" (FBO) account. (format: double, e.g. 1.5)
  --amt-tax: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Amount of sales tax included in the total transaction amount. This field tracks the tax amount for display and interchange purposes, but the amount of the tax must be included in amt_tran.<br><strong>Conditional Requirement: </strong>Required for Level 2 and Level 3 interchange qualification. (format: double, e.g. 93.5)
  --amt-tran: float # <strong>Format: </strong>Variable length, up to 12,2 N<br><strong>Description: </strong>Total amount of transaction including sales tax (amt_tax), convenience fee (amt_convenience_fee), and/or surcharge (amt_tran_fee) if applicable. (format: double, e.g. 1193.5)
  --amt-tran-fee: float # <strong>Format: </strong>Variable length, up to 8,2 N<br><strong>Description: </strong>Amount of transaction surcharge fee. A surcharge is a fee added to the cost of a purchase for the "privilege" of using a credit card instead of another form of payment, and can be a percentage of the transaction amount or fixed amount of up to 4% of amt_tran. This field tracks the surcharge amount of the transaction for display purposes, but the amount of the fee must be included in amt_tran. (format: double, e.g. 2.35)
  --auth-code: string # <strong>Format: </strong>Fixed length, 6 AN<br><strong>Description: </strong>This field should contain the 6-character authorization code that was received during a voice or Automated Response Unit(ARU) authorization for force request type. This is field is applicable to only force request type.<br><strong>Conditional Requirement: </strong>This field is required in force request type. (e.g. 620376)
  --avs-address: string # <strong>Format: </strong>Variable length, up to 20 AN<br><strong>Description: </strong>Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # <strong>Format: </strong>Variable length, up to 9 AN<br><strong>Description: </strong>Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.<br><strong>Conditional Requirement: </strong>This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # <strong>Format: </strong>Variable length, up to 19 N<br><strong>Description: </strong>Cardholder's card number.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 4111111111111111)
  --card-swipe: string # <strong>Format: </strong>Variable length, up to 79 AN<br><strong>Description: </strong>Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # <strong>Format: </strong>Variable length, up to 64 AN<br><strong>Description: </strong>When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --cavv-3ds: string # <strong>Format: </strong>Fixed length, 28 AN<br><strong>Description: </strong>Base 64 encoded CAVV returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for Visa 3D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
  --client-ip: string # <strong>Format: </strong>Variable length AN<br><strong>Description: </strong>Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # <strong>Format: </strong>Variable length, up to 17 AN<br><strong>Description: </strong>Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --customer-email: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong><strong>[Deprecated use email_address]</strong> Comma-separated list of e-mail addresses to which a receipt should be sent. (e.g. testme@qualpay.com)
  --customer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Customer ID value established by the merchant. The customer_id may be used in place of a card number in requests requiring cardholder account data. When used with a card_id or card_number or card_swipe, the request will be tied to the customer_id in Qualpay reporting. <br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. JOECUSTOMER_12)
  --cvv2: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dba-name: string # <strong>Format: </strong>Variable length, up to 21 AN<br><strong>Description: </strong>When the merchant has been authorized to send dynamic DBA information, this field will contain the DBA name used by Qulapay in the authorization and clearing messages.<br>Note: the payment gateway will automatically add a prefix plus an asterisk (*) to the dba_name value. For example, if the prefix is ABC and the dba_name value is SHOE CO, the DBA name will show as "ABC*SHOE CO" on the cardholder's credit card statement. (e.g. SHOE CO)
  --dba-suffix: string # <strong>Format: </strong>Fixed length, 9 AN<br><strong>Description: </strong>For use by merchants using negative option marketing.  This field must be used in the first transaction at the conclusion of the free or reduced trial. This suffix will be appended to the end of your DBA and the result will appear on the cardholder statement. (If your DBA and suffix contain more that 25 characters, your DBA will be truncated.) Possible values are: <ul><li>END DSCNT</li><li>END OFFER</li><li>END PROMO</li><li>END TRIAL</li></ul> (e.g. END PROMO)
  --dda-number: string # <strong>Format: </strong>Variable length, up to 17 N<br><strong>Description: </strong>Owner's account number at the bank. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 3456776866)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --duplicate-seconds: int # <strong>Format: </strong>Variable length, up to 5 N<br><strong>Description: </strong>Duplicate transaction window in seconds. Qualpay will reject any transactions after a successful transaction within the duplicate_seconds window with a duplicate Account Number and optionally Purchase ID or, and, Merchant Reference Number. This value overrides any value set for a merchant on Qualpay Manager. (format: int64, e.g. 300)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list #  AN<br><strong>Description: </strong>An array of email addresses to which the transaction receipt should be sent to.  (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --email-receipt: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>When this field is provided and set to true, a customer_email must also be provided. When these two fields are provided, a transaction receipt will be sent via e-mail to the address(es) provided in the customer_email field. (e.g. true)
  --emv-tran-id: string # <strong>Format: </strong>Variable length, up to 36 AN<br><strong>Description: </strong>Base64 encoded MasterCard UCAF Transaction ID returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjR1We3I85BI70V9nifASNFZ4jwHyL0U=)
  --exp-date: string # <strong>Format: </strong>Fixed length, 4 N, MMYY format<br><strong>Description: </strong>Expiration date of cardholder card number.  When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 0921)
  --fbo-id: int # <strong>Format: </strong>Variable length, up to 16 N<br><strong>Description: </strong>For Benefit Of (FBO) merchant account identifier on the Qualpay system. Contact Qualpay customer support to obtain your FBO information. (format: int64, e.g. 999000000001)
  --line-items: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>JSON array of JSON objects. Each object represents a single line item detail element related to the transaction. Each detail element has required subfields: <br>quantity (7N)<br> description (26AN)<br> unit_of_measure (12AN)<br> product_code (12AN) - cannot be all zeroes<br> debit_credit_ind (1 AN)<br> unit_cost (12,2N)<br> Optional subfields: <br>type_of_supply (2AN) - visa only<br>commodity_code - visa only(12AN)<br><strong>Conditional Requirement: </strong> This field is required for Level 3 interchange qualification. (e.g. [{"quantity": "1","description": "Traffic Cones", "unit_of_measure": "each", "product_code": "SKU-123", "debit_credit_ind": "D", "unit_cost": "14.99"},{"quantity": "3", "description": "Spray Paint", "unit_of_measure": "EA", "product_code": "SKU-456", "debit_credit_ind": "D", "unit_cost": "5.00"}])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --mc-ucaf-data: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Base64 encoded MasterCard UCAF Field Data returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. ASNFZ4nwEjRWeI8BI0VnifASNFZ4jwHyL0U=)
  --mc-ucaf-ind: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Description: </strong>MasterCard UCAF Collection Indicator returned from the merchant’s third-party 3-D Secure Merchant Plug-in (MPI). Use for MasterCard 3-D Secure transactions. (e.g. 2)
  --merch-ref-num: string # <strong>Format: </strong>Variable length, up to 128 AN<br><strong>Description: </strong>Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # <strong>Format: </strong>Fixed length, 1 N<br><strong>Default: </strong>7<br><strong>Description: </strong>Indicates type of MOTO transaction: <ul><li>0 = Card Present (not MOTO/e-Commerce)</li><li> 1 = One Time MOTO transaction</li><li>2 = Recurring </li><li>3 = Installment </li><li>5 = Full 3D-Secure transaction</li><li>6 = Merchant 3D-Secure transaction</li><li>7 = e-Commerce Channel Encrypted (SSL)</li></ul> (e.g. 1)
  --partial-auth: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>This field must be present and set to a value of 'true' in order for the request to allow for approval of a partial amount. This would be used to allow a merchant to accept a partial payment from pre-paid or debit cards. When only part of the requested amount is available, the response code will be 010 and the amt_tran field in the response will contain the amount that was approved. A second sale request  on a different card is needed  to capture the remaining amount. Applicable to auth and sale request types. (e.g. true)
  --payload-apple-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Google Pay payload (e.g. xxxxxxx)
  --pg-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>PG ID of previously authorized transaction. This field is required when sending a capture, refund, or void request. (e.g. d24ac6189b0b11e6966ca68d5edbef41)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --purchase-id: string # <strong>Format: </strong>Variable length, up to 25 AN<br><strong>Description: </strong>Purchase Identifier (also referred to as the invoice number generated by the merchant).<br><strong>Conditional Requirement: </strong> This field is required for Level 2 and Level 3 interchange qualification. (e.g. 55-1212)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --subscription-id: int # <strong>Format: </strong>Variable length, up to 10 N<br><strong>Description: </strong>Identifies the recurring subscription that applies to this transaction. (format: int64, e.g. 1234)
  --tokenize: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. true)
  --tr-number: string # <strong>Format: </strong>Fixed length, 9 N<br><strong>Description: </strong>Bank transit/routing number. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 011111111)
  --tran-currency: int # <strong>Format: </strong>Fixed length, 3 N<br><strong>Default: </strong>840<br><strong>Description: </strong>ISO numeric currency code for the transaction. Refer to <a href="/developer/api/reference#country-codes"target="_blank">Country Codes</a> for a list of currency codes. (format: int32, e.g. 840)
  --type-id: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Default: </strong>C<br><strong>Description: </strong>Bank Account Type. Applicable for ACH payments. Possible values are: <ul><li>C = Personal checking account</li><li>S = Personal savings account</li><li>K = Business checking account</li><li>V = Business savings account</li></ul> (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this capture request applies. (format: int64, e.g. 212100026512)
  --xid-3ds: string # <strong>Format: </strong>Fixed length, 28 AN<br><strong>Description: </strong>Base64 encoded transaction ID (XID) returned from the merchant’s third-party 3D Secure Merchant Plug-in (MPI). Use for Visa 3-D Secure transactions. (e.g. ASNFZ4kBI0VniQEjRWeJASNFZ4k=)
]: any -> record<amt_tran: float, auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sale")
  let body = {"amt_convenience_fee": $amt_convenience_fee, "amt_fbo": $amt_fbo, "amt_tax": $amt_tax, "amt_tran": $amt_tran, "amt_tran_fee": $amt_tran_fee, "auth_code": $auth_code, "avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "cavv_3ds": $cavv_3ds, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "customer_email": $customer_email, "customer_id": $customer_id, "cvv2": $cvv2, "dba_name": $dba_name, "dba_suffix": $dba_suffix, "dda_number": $dda_number, "developer_id": $developer_id, "duplicate_seconds": $duplicate_seconds, "echo_fields": $echo_fields, "email_address": $email_address, "email_receipt": $email_receipt, "emv_tran_id": $emv_tran_id, "exp_date": $exp_date, "fbo_id": $fbo_id, "line_items": $line_items, "loc_id": $loc_id, "mc_ucaf_data": $mc_ucaf_data, "mc_ucaf_ind": $mc_ucaf_ind, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "partial_auth": $partial_auth, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "pg_id": $pg_id, "profile_id": $profile_id, "purchase_id": $purchase_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "subscription_id": $subscription_id, "tokenize": $tokenize, "tr_number": $tr_number, "tran_currency": $tran_currency, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id, "xid_3ds": $xid_3ds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tokenize Card
#
# POST /tokenize
# operationId: Tokenize
export def "tokenize post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avs-address: string # <strong>Format: </strong>Variable length, up to 20 AN<br><strong>Description: </strong>Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # <strong>Format: </strong>Variable length, up to 9 N<br><strong>Description: </strong>Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.<br><strong>Conditional Requirement: </strong>This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # <strong>Format: </strong>Fixed length, 32 AN<br><strong>Description: </strong>Card ID received from a tokenization request. The card_id may be used in place of a card number in requests requiring cardholder account data.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 86e1b00d9b0811e68df3069d8f743581)
  --card-number: string # <strong>Format: </strong>Variable length, up to 19 N<br><strong>Description: </strong>Cardholder's card number.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 4111111111111111)
  --card-swipe: string # <strong>Format: </strong>Variable length, up to 79<br><strong>Description: </strong>Contains either track 1 or track 2 magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # <strong>Format: </strong>Variable length, up to 64 AN<br><strong>Description: </strong>When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --client-ip: string # <strong>Format: </strong>Variable length AN<br><strong>Description: </strong>Client IP address. (e.g. 10.1.1.4)
  --cvv2: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dda-number: string # <strong>Format: </strong>Variable length, up to 17 N<br><strong>Description: </strong>Owner's account number at the bank. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 3456776866)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list #  AN<br><strong>Description: </strong>An array of account holder email addresses. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  exp_date: string # <strong>Format: </strong>Fixed length, 4 N(MMYY format)<br><strong>Description: </strong>Expiration date of cardholder card number. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 0921)
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --payload-apple-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Google Pay payload (e.g. xxxxxxx)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --single-use: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>In a tokenize request, setting the single_use field to "true" will cause a single-use token to be generated. This token will expire in 10 minutes or when first used. (e.g. true)
  --tr-number: string # <strong>Format: </strong>Fixed length, 9 N<br><strong>Description: </strong>Bank transit/routing number. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 011111111)
  --type-id: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Default: </strong>C<br><strong>Description: </strong>Bank Account Type. Applicable for ACH payments. Possible values are: <ul><li>C = Personal checking account</li><li>S = Personal savings account</li><li>K = Business checking account</li><li>V = Business savings account</li></ul> (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this tokenize request applies. (format: int64, e.g. 212100026512)
]: any -> record<card_id: string, card_number: string, echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokenize")
  let body = {"avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "client_ip": $client_ip, "cvv2": $cvv2, "dda_number": $dda_number, "developer_id": $developer_id, "echo_fields": $echo_fields, "email_address": $email_address, "exp_date": $exp_date, "loc_id": $loc_id, "merchant_id": $merchant_id, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "single_use": $single_use, "tr_number": $tr_number, "type_id": $type_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify Card
#
# POST /verify
# operationId: Verify
# --customer shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
export def "verify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avs-address: string # <strong>Format: </strong>Variable length, up to 20 AN<br><strong>Description: </strong>Street address of the cardholder. If present, it will be included in the authorization request sent to the issuing bank. (e.g. 123 Main St)
  --avs-zip: string # <strong>Format: </strong>Variable length, up to 9 N<br><strong>Description: </strong>Zip code of the cardholder. If present, it will be included in the authorization request sent to the issuing bank.<br><strong>Conditional Requirement: </strong>This field is required if avs_address is present. (e.g. 94402)
  --card-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Card ID received from a tokenization request. The card_id may be used in place of a card number or card swipe.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 86e1b00d9b0811e68df3069d8f743581)
  card_number: string # <strong>Format: </strong>Variable length, up to 19 N<br><strong>Description: </strong>Cardholder's card number. <br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 4111111111111111)
  --card-swipe: string # <strong>Format: </strong>Variable length, up to 79 AN<br><strong>Description: </strong>Contains either track 1 or track 2 data magnetic stripe data. If the magnetic stripe reader provides both track 1 and track 2 data in a single read, it is the responsibility of the implementer to send data for only one of the two tracks.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. ;4111111111111111=08051010912345678901?8)
  --cardholder-name: string # <strong>Format: </strong>Variable length, up to 64 AN<br><strong>Description: </strong>When provided in a tokenize request, the cardholder name will be stored in the Card Vault along with the cardholder card number and expiration date. (e.g. JOHN CUSTOMER)
  --client-ip: string # <strong>Format: </strong>Variable length AN<br><strong>Description: </strong>Client IP address. (e.g. 10.1.1.4)
  --customer: record # shape: {billing_addr1?: string, billing_addr2?: string, billing_city?: string, billing_country?: string, billing_country_code?: string, billing_state?: string, billing_zip?: string, billing_zip4?: string, customer_email?: string, customer_firm_name?: string, customer_first_name?: string, customer_last_name?: string, customer_phone?: string, shipping_addresses?: list}
  --customer-code: string # <strong>Format: </strong>Variable length, up to 17 AN<br><strong>Description: </strong>Reference code supplied by the cardholder to the merchant. (e.g. PO # abc123)
  --cvv2: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>CVV2 or CID value from the signature panel on the back of the cardholder's card. If present during a request that requires authorization, the value will be sent to the issuer for validation. (e.g. 152)
  --dda-number: string # <strong>Format: </strong>Variable length, up to 17 N<br><strong>Description: </strong>Owner's account number at the bank. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 3456776866)
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --email-address: list #  AN<br><strong>Description: </strong>An array of account holder email addresses. (e.g. [jdoe@qualpay.com, john.doe@qualpay.com])
  --exp-date: string # <strong>Format: </strong>Fixed length, 4 N, MMYY format<br><strong>Description: </strong>Expiration date of cardholder card number. Required when the field card_number is present. If card_swipe is present in the request, this field must NOT be present. When card_id or customer_id is present in the request this field may also be present; if it is not, then the expiration date from the Card Vault will be used.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 0921)
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  --merch-ref-num: string # <strong>Format: </strong>Variable length, up to 128 AN<br><strong>Description: </strong>Merchant provided reference value that will be stored with the transaction data and included with transaction data in reports within Qualpay Manager. This value will also be attached to any lifecycle transactions (e.g. retrieval requests and chargebacks) that may occur. (e.g. ITEM 16126 Purchased 12-15-2016)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --moto-ecomm-ind: string # <strong>Format: </strong>Fixed length, 1 N<br><strong>Default: </strong>7<br><strong>Description: </strong>Indicates type of MOTO transaction: <ul><li>0 = Card Present (not MOTO/e-Commerce)</li><li> 1 = One Time MOTO transaction</li><li>2 = Recurring </li><li>3 = Installment </li><li>5 = Full 3D-Secure transaction</li><li>6 = Merchant 3D-Secure transaction</li><li>7 = e-Commerce Channel Encrypted (SSL)</li></ul> (e.g. 1)
  --payload-apple-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Apple Pay payload (e.g. xxxxxxx)
  --payload-google-pay: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>Google Pay payload (e.g. xxxxxxx)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --tokenize: oneof<nothing, bool> # <br><strong>Default: </strong>false<br><strong>Description: </strong>In an authorization, credit, force, sale, or verify request the merchant can set tokenize to "true" and the payment gateway will store the cardholder data in the Card Vault and provide a card_id in the response. If the card_number or card_id in the request is already in the Card Vault, this flag instructs the payment gateway to update the associated data (e.g. avs_address, avs_zip, exp_date) if present. (e.g. true)
  --tr-number: string # <strong>Format: </strong>Fixed length, 9 N<br><strong>Description: </strong>Bank transit/routing number. Applicable for ACH payments.<br><strong>Conditional Requirement: </strong>Refer to <a href="/developer/api/reference#card-source-conditional-requirements"target="_blank">Card or Bank Account Data Sources and Conditional Requirements</a> (e.g. 011111111)
  --type-id: string # <strong>Format: </strong>Fixed length, 1 AN<br><strong>Default: </strong>C<br><strong>Description: </strong>Bank Account Type. Applicable for ACH payments. Possible values are: <ul><li>C = Personal checking account</li><li>S = Personal savings account</li><li>K = Business checking account</li><li>V = Business savings account</li></ul> (e.g. S)
  --user-id: int # INTERNAL USE ONLY. (format: int64)
]: any -> record<auth_avs_result: string, auth_code: string, auth_cvv2_result: string, card_id: string, card_number: string, echo_fields: string, merchant_advice_code: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verify")
  let body = {"avs_address": $avs_address, "avs_zip": $avs_zip, "card_id": $card_id, "card_number": $card_number, "card_swipe": $card_swipe, "cardholder_name": $cardholder_name, "client_ip": $client_ip, "customer": $customer, "customer_code": $customer_code, "cvv2": $cvv2, "dda_number": $dda_number, "developer_id": $developer_id, "echo_fields": $echo_fields, "email_address": $email_address, "exp_date": $exp_date, "loc_id": $loc_id, "merch_ref_num": $merch_ref_num, "merchant_id": $merchant_id, "moto_ecomm_ind": $moto_ecomm_ind, "payload_apple_pay": $payload_apple_pay, "payload_google_pay": $payload_google_pay, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "tokenize": $tokenize, "tr_number": $tr_number, "type_id": $type_id, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Void a Previously Authorized Transaction
#
# POST /void/{pgIdOrig}
# operationId: Void
export def "void post" [
  pg_id_orig: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # <strong>Format: </strong>Variable length, up to 32 AN<br><strong>Description: </strong>Use to indicate which company developed the integration to Qualpay or the name of the payment solution that is connected to Qualpay.  Suggested usage is softwareABCv1.0 or companyXYZv2.0.  (e.g. QualpayV1.2)
  --echo-fields: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be echoed back in the response message. (e.g. [ {"product" : "lawnmower"},{"purchase" : "1 yr maintenance"} ])
  --loc-id: string # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>When a merchant has more than one location using the same currency, this value is used to specify the specific location for this request. (e.g. 0001)
  merchant_id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Unique identifier on the Qualpay system. (format: int64, e.g. <Provide merchant id that links to API Key>)
  --profile-id: string # <strong>Format: </strong>Fixed length, 20 N<br><strong>Description: </strong>Explicitly identifies which Payment Gateway profile should be used for the request. (e.g. 21200001000300000978)
  --report-data: string # <strong>Format: </strong>Variable length<br><strong>Description: </strong>This field contains a JSON array of field data that will be included with the transaction data reported in Qualpay Manager. (e.g. [ {"shipping address" : "123 Main St."},{"shipping city, state zip" : "San Mateo, CA 94402"} ])
  --retry-attempt: int # <strong>Format: </strong>Variable length, up to 4 N<br><strong>Description: </strong>This field contains a number greater than zero (0). When the value is one (1), the payment gateway treats the message as a new message. If the value is greater than one (1), then the payment gateway will return the result of the original message. If the original message did not complete, the payment gateway treats the message as a new message.<br><strong>Conditional Requirement: </strong>This field is required when the retry_id is present in the request message. (format: int64, e.g. 1)
  --retry-id: int # <strong>Format: </strong>Variable length, up to 15 N<br><strong>Description: </strong>This field contains a merchant generated number used to identify the request. This value must be unique within the last 24 hours. When present, the payment gateway will use the retry_attempt to determine whether the message is new or a retry of a previous message. (format: int64, e.g. 1234)
  --session-id: string # INTERNAL USE ONLY.
  --user-id: int # INTERNAL USE ONLY. (format: int64)
  --vendor-id: int # <strong>Format: </strong>Variable length, up to 12 N<br><strong>Description: </strong>Identifies the vendor to which this void request applies. (format: int64, e.g. 212100026512)
]: any -> record<echo_fields: string, pg_id: string, rcode: string, rmsg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pg_id_orig: $pg_id_orig} | format pattern "/void/{pg_id_orig}"))
  let body = {"developer_id": $developer_id, "echo_fields": $echo_fields, "loc_id": $loc_id, "merchant_id": $merchant_id, "profile_id": $profile_id, "report_data": $report_data, "retry_attempt": $retry_attempt, "retry_id": $retry_id, "session_id": $session_id, "user_id": $user_id, "vendor_id": $vendor_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
