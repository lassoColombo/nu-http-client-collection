# Auto-generated client for Adyen Payout API v68
# Source: https://api.apis.guru/v2/specs/adyen.com/PayoutService/68/openapi.json
# Auth: --token flag or $env.ADYEN_PAYOUT_API_TOKEN

const BASE_URL = "https://pal-test.adyen.com/pal/servlet/Payout/v68"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADYEN_PAYOUT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

def base-url-completer [] { ["https://pal-test.adyen.com/pal/servlet/Payout/v68"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def shopper-interaction-completer [] { ["ContAuth" "Ecommerce" "Moto" "POS"] }
def entity-type-completer [] { ["Company" "NaturalPerson"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "confirm-third-party create" } } | get name | first)
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

# Confirm a payout
#
# POST /confirmThirdParty
# operationId: post-confirmThirdParty
export def "confirm-third-party create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular payout request.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  original_reference: string # The PSP reference received in the `/submitThirdParty` response.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/confirmThirdParty")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "originalReference": $original_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancel a payout
#
# POST /declineThirdParty
# operationId: post-declineThirdParty
export def "decline-third-party create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular payout request.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  original_reference: string # The PSP reference received in the `/submitThirdParty` response.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/declineThirdParty")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "originalReference": $original_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Make an instant card payout
#
# POST /payout
# operationId: post-payout
# --amount shape: {currency: string, value: int}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --card shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
# --fundSource shape: {additionalData?: record, billingAddress?: record, card?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string}
# --recurring shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
# --shopperName shape: {firstName: string, lastName: string}
export def "payout create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: record # shape: {currency: string, value: int}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --card: record # shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --fund-source: record # shape: {additionalData?: record, billingAddress?: record, card?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string}
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selected-recurring-detail-reference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --shopper-email: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > For 3D Secure 2 transactions, schemes require `shopperEmail` for all browser-based and mobile implementations.
  --shopper-interaction: string@shopper-interaction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default. This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Required for recurring payments. Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --telephone-number: string # The shopper's telephone number.
]: any -> record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payout")
  let req_body = {"amount": $amount, "billingAddress": $billing_address, "card": $card, "fraudOffset": $fraud_offset, "fundSource": $fund_source, "merchantAccount": $merchant_account, "recurring": $recurring, "reference": $reference, "selectedRecurringDetailReference": $selected_recurring_detail_reference, "shopperEmail": $shopper_email, "shopperInteraction": $shopper_interaction, "shopperName": $shopper_name, "shopperReference": $shopper_reference, "telephoneNumber": $telephone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Store payout details
#
# POST /storeDetail
# operationId: post-storeDetail
# --bank shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --card shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
# --recurring shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
# --shopperName shape: {firstName: string, lastName: string}
export def "store-detail create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular request.
  --bank: record # shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --card: record # shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
  date_of_birth: string # The date of birth. Format: [ISO-8601](https://www.w3.org/TR/NOTE-datetime); example: YYYY-MM-DD For Paysafecard it must be the same as used when registering the Paysafecard account. > This field is mandatory for natural persons. (format: date)
  entity_type: string@entity-type-completer # The type of the entity the payout is processed for.
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  nationality: string # The shopper's nationality. A valid value is an ISO 2-character country code (e.g. 'NL').
  recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  --selected-brand: string # The name of the brand to make a payout to. For Paysafecard it must be set to `paysafecard`.
  shopper_email: string # The shopper's email address.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  shopper_reference: string # The shopper's reference for the payment transaction.
  --social-security-number: string # The shopper's social security number.
  --telephone-number: string # The shopper's phone number.
]: any -> record<additionalData: record, pspReference: string, recurringDetailReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storeDetail")
  let req_body = {"additionalData": $additional_data, "bank": $bank, "billingAddress": $billing_address, "card": $card, "dateOfBirth": $date_of_birth, "entityType": $entity_type, "fraudOffset": $fraud_offset, "merchantAccount": $merchant_account, "nationality": $nationality, "recurring": $recurring, "selectedBrand": $selected_brand, "shopperEmail": $shopper_email, "shopperName": $shopper_name, "shopperReference": $shopper_reference, "socialSecurityNumber": $social_security_number, "telephoneNumber": $telephone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Store details and submit a payout
#
# POST /storeDetailAndSubmitThirdParty
# operationId: post-storeDetailAndSubmitThirdParty
# --amount shape: {currency: string, value: int}
# --bank shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --card shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
# --recurring shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
# --shopperName shape: {firstName: string, lastName: string}
export def "store-detail-and-submit-third-party create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular request.
  amount: record # shape: {currency: string, value: int}
  --bank: record # shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --card: record # shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
  date_of_birth: string # The date of birth. Format: [ISO-8601](https://www.w3.org/TR/NOTE-datetime); example: YYYY-MM-DD For Paysafecard it must be the same as used when registering the Paysafecard account. > This field is mandatory for natural persons. (format: date)
  entity_type: string@entity-type-completer # The type of the entity the payout is processed for.
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  nationality: string # The shopper's nationality. A valid value is an ISO 2-character country code (e.g. 'NL').
  recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  reference: string # The merchant reference for this payment. This reference will be used in all communication to the merchant about the status of the payout. Although it is a good idea to make sure it is unique, this is not a requirement.
  --selected-brand: string # The name of the brand to make a payout to. For Paysafecard it must be set to `paysafecard`.
  shopper_email: string # The shopper's email address.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  shopper_reference: string # The shopper's reference for the payment transaction.
  --shopper-statement: string # The description of this payout. This description is shown on the bank statement of the shopper (if this is supported by the chosen payment method).
  --social-security-number: string # The shopper's social security number.
  --telephone-number: string # The shopper's phone number.
]: any -> record<additionalData: record, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storeDetailAndSubmitThirdParty")
  let req_body = {"additionalData": $additional_data, "amount": $amount, "bank": $bank, "billingAddress": $billing_address, "card": $card, "dateOfBirth": $date_of_birth, "entityType": $entity_type, "fraudOffset": $fraud_offset, "merchantAccount": $merchant_account, "nationality": $nationality, "recurring": $recurring, "reference": $reference, "selectedBrand": $selected_brand, "shopperEmail": $shopper_email, "shopperName": $shopper_name, "shopperReference": $shopper_reference, "shopperStatement": $shopper_statement, "socialSecurityNumber": $social_security_number, "telephoneNumber": $telephone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Submit a payout
#
# POST /submitThirdParty
# operationId: post-submitThirdParty
# --amount shape: {currency: string, value: int}
# --recurring shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
# --shopperName shape: {firstName: string, lastName: string}
export def "submit-third-party create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular request.
  amount: record # shape: {currency: string, value: int}
  --date-of-birth: string # The date of birth. Format: ISO-8601; example: YYYY-MM-DD For Paysafecard it must be the same as used when registering the Paysafecard account. > This field is mandatory for natural persons. > This field is required to update the existing `dateOfBirth` that is associated with this recurring contract. (format: date)
  --entity-type: string@entity-type-completer # The type of the entity the payout is processed for. Allowed values: * NaturalPerson * Company > This field is required to update the existing `entityType` that is associated with this recurring contract.
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  merchant_account: string # The merchant account identifier you want to process the transaction request with.
  --nationality: string # The shopper's nationality. A valid value is an ISO 2-character country code (e.g. 'NL'). > This field is required to update the existing nationality that is associated with this recurring contract.
  recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  reference: string # The merchant reference for this payout. This reference will be used in all communication to the merchant about the status of the payout. Although it is a good idea to make sure it is unique, this is not a requirement.
  selected_recurring_detail_reference: string # This is the `recurringDetailReference` you want to use for this payout. You can use the value LATEST to select the most recently used recurring detail.
  shopper_email: string # The shopper's email address.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  shopper_reference: string # The shopper's reference for the payout transaction.
  --shopper-statement: string # The description of this payout. This description is shown on the bank statement of the shopper (if this is supported by the chosen payment method).
  --social-security-number: string # The shopper's social security number.
]: any -> record<additionalData: record, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submitThirdParty")
  let req_body = {"additionalData": $additional_data, "amount": $amount, "dateOfBirth": $date_of_birth, "entityType": $entity_type, "fraudOffset": $fraud_offset, "merchantAccount": $merchant_account, "nationality": $nationality, "recurring": $recurring, "reference": $reference, "selectedRecurringDetailReference": $selected_recurring_detail_reference, "shopperEmail": $shopper_email, "shopperName": $shopper_name, "shopperReference": $shopper_reference, "shopperStatement": $shopper_statement, "socialSecurityNumber": $social_security_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
