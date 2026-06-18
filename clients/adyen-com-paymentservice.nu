# Auto-generated client for Adyen Payment API v68
# Source: https://api.apis.guru/v2/specs/adyen.com/PaymentService/68/openapi.json
# Auth: --token flag or $env.ADYEN_PAYMENT_API_TOKEN

const BASE_URL = "https://pal-test.adyen.com/pal/servlet/Payment/v68"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADYEN_PAYMENT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://pal-test.adyen.com/pal/servlet/Payment/v68"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def entity-type-completer [] { ["CompanyName" "NaturalPerson"] }
def funding-source-completer [] { ["debit"] }
def recurring-processing-model-completer [] { ["CardOnFile" "Subscription" "UnscheduledCardOnFile"] }
def shopper-interaction-completer [] { ["ContAuth" "Ecommerce" "Moto" "POS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "adjust-authorisation create" } } | get name | first)
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

# Change the authorised amount
#
# POST /adjustAuthorisation
# operationId: post-adjustAuthorisation
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
export def "adjust-authorisation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  modification_amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/adjustAuthorisation")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "modificationAmount": $modification_amount, "mpiData": $mpi_data, "originalMerchantReference": $original_merchant_reference, "originalReference": $original_reference, "platformChargebackLogic": $platform_chargeback_logic, "reference": $reference, "splits": $splits, "tenderReference": $tender_reference, "uniqueTerminalId": $unique_terminal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create an authorisation
#
# POST /authorise
# operationId: post-authorise
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
# --additionalAmount shape: {currency: string, value: int}
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --bankAccount shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --card shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
# --dccQuote shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
# --deliveryAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --fundDestination shape: {additionalData?: record, billingAddress?: record, card?: record, selectedRecurringDetailReference?: string, shopperEmail?: string, shopperName?: record, shopperReference?: string, subMerchant?: record, telephoneNumber?: string}
# --fundSource shape: {additionalData?: record, billingAddress?: record, card?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string}
# --installments shape: {plan?: "regular"|"revolving", value: int}
# --mandate shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
# --merchantRiskIndicator shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --recurring shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
# --shopperName shape: {firstName: string, lastName: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
# --threeDS2RequestData shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
export def "authorise create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --bank-account: record # shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browser-info: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --card: record # shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --device-fingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --entity-type: string@entity-type-completer # The type of the entity the payment is processed for.
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --fund-destination: record # shape: {additionalData?: record, billingAddress?: record, card?: record, selectedRecurringDetailReference?: string, shopperEmail?: string, shopperName?: record, shopperReference?: string, subMerchant?: record, telephoneNumber?: string}
  --fund-source: record # shape: {additionalData?: record, billingAddress?: record, card?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string}
  --funding-source: string@funding-source-completer # The funding source that should be used when multiple sources are available. For Brazilian combo cards, by default the funding source is credit. To use debit, set this value to **debit**.
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --nationality: string # The two-character country code of the shopper's nationality.
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selected-brand: string # Some payment methods require defining a value for this field to specify how to process the transaction. For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selected-recurring-detail-reference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --session-id: string # A session ID used to identify a payment session.
  --shopper-email: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > For 3D Secure 2 transactions, schemes require `shopperEmail` for all browser-based and mobile implementations.
  --shopper-ip: string # The shopper's IP address. In general, we recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > For 3D Secure 2 transactions, schemes require `shopperIP` for all browser-based implementations. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopper-interaction: string@shopper-interaction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default. This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopper-locale: string # The combination of a language code and a country code to specify the language to be used in the payment.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Required for recurring payments. Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopper-statement: string # The text to be shown on the shopper's bank statement. We recommend sending a maximum of 22 characters, otherwise banks might truncate the string. Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --social-security-number: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using [Adyen for Platforms](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information) or [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --store: string # The ecommerce or point-of-sale store that is processing the payment. Used in [partner model integrations](https://docs.adyen.com/marketplaces-and-platforms/classic/platforms-for-partners#route-payments) for Adyen for Platforms.
  --telephone-number: string # The shopper's telephone number.
  --three-ds2-request-data: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (default: false)
  --totals-group: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorise")
  let req_body = {"accountInfo": $account_info, "additionalAmount": $additional_amount, "additionalData": $additional_data, "amount": $amount, "applicationInfo": $application_info, "bankAccount": $bank_account, "billingAddress": $billing_address, "browserInfo": $browser_info, "captureDelayHours": $capture_delay_hours, "card": $card, "dateOfBirth": $date_of_birth, "dccQuote": $dcc_quote, "deliveryAddress": $delivery_address, "deliveryDate": $delivery_date, "deviceFingerprint": $device_fingerprint, "entityType": $entity_type, "fraudOffset": $fraud_offset, "fundDestination": $fund_destination, "fundSource": $fund_source, "fundingSource": $funding_source, "installments": $installments, "localizedShopperStatement": $localized_shopper_statement, "mandate": $mandate, "mcc": $mcc, "merchantAccount": $merchant_account, "merchantOrderReference": $merchant_order_reference, "merchantRiskIndicator": $merchant_risk_indicator, "metadata": $metadata, "mpiData": $mpi_data, "nationality": $nationality, "orderReference": $order_reference, "platformChargebackLogic": $platform_chargeback_logic, "recurring": $recurring, "recurringProcessingModel": $recurring_processing_model, "reference": $reference, "selectedBrand": $selected_brand, "selectedRecurringDetailReference": $selected_recurring_detail_reference, "sessionId": $session_id, "shopperEmail": $shopper_email, "shopperIP": $shopper_ip, "shopperInteraction": $shopper_interaction, "shopperLocale": $shopper_locale, "shopperName": $shopper_name, "shopperReference": $shopper_reference, "shopperStatement": $shopper_statement, "socialSecurityNumber": $social_security_number, "splits": $splits, "store": $store, "telephoneNumber": $telephone_number, "threeDS2RequestData": $three_ds2_request_data, "threeDSAuthenticationOnly": $three_ds_authentication_only, "totalsGroup": $totals_group, "trustedShopper": $trusted_shopper} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Complete a 3DS authorisation
#
# POST /authorise3d
# operationId: post-authorise3d
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
# --additionalAmount shape: {currency: string, value: int}
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --dccQuote shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
# --deliveryAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --installments shape: {plan?: "regular"|"revolving", value: int}
# --merchantRiskIndicator shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
# --recurring shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
# --shopperName shape: {firstName: string, lastName: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
# --threeDS2RequestData shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
export def "authorise3d create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  --amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browser-info: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --device-fingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  md: string # The payment session identifier returned by the card issuer.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  pa_response: string # Payment authorisation response returned by the card issuer. The `paResponse` field holds the PaRes value received from the card issuer.
  --recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selected-brand: string # Some payment methods require defining a value for this field to specify how to process the transaction. For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selected-recurring-detail-reference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --session-id: string # A session ID used to identify a payment session.
  --shopper-email: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > For 3D Secure 2 transactions, schemes require `shopperEmail` for all browser-based and mobile implementations.
  --shopper-ip: string # The shopper's IP address. In general, we recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > For 3D Secure 2 transactions, schemes require `shopperIP` for all browser-based implementations. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopper-interaction: string@shopper-interaction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default. This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopper-locale: string # The combination of a language code and a country code to specify the language to be used in the payment.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Required for recurring payments. Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopper-statement: string # The text to be shown on the shopper's bank statement. We recommend sending a maximum of 22 characters, otherwise banks might truncate the string. Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --social-security-number: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using [Adyen for Platforms](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information) or [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --store: string # The ecommerce or point-of-sale store that is processing the payment. Used in [partner model integrations](https://docs.adyen.com/marketplaces-and-platforms/classic/platforms-for-partners#route-payments) for Adyen for Platforms.
  --telephone-number: string # The shopper's telephone number.
  --three-ds2-request-data: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (default: false)
  --totals-group: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorise3d")
  let req_body = {"accountInfo": $account_info, "additionalAmount": $additional_amount, "additionalData": $additional_data, "amount": $amount, "applicationInfo": $application_info, "billingAddress": $billing_address, "browserInfo": $browser_info, "captureDelayHours": $capture_delay_hours, "dateOfBirth": $date_of_birth, "dccQuote": $dcc_quote, "deliveryAddress": $delivery_address, "deliveryDate": $delivery_date, "deviceFingerprint": $device_fingerprint, "fraudOffset": $fraud_offset, "installments": $installments, "localizedShopperStatement": $localized_shopper_statement, "mcc": $mcc, "md": $md, "merchantAccount": $merchant_account, "merchantOrderReference": $merchant_order_reference, "merchantRiskIndicator": $merchant_risk_indicator, "metadata": $metadata, "orderReference": $order_reference, "paResponse": $pa_response, "recurring": $recurring, "recurringProcessingModel": $recurring_processing_model, "reference": $reference, "selectedBrand": $selected_brand, "selectedRecurringDetailReference": $selected_recurring_detail_reference, "sessionId": $session_id, "shopperEmail": $shopper_email, "shopperIP": $shopper_ip, "shopperInteraction": $shopper_interaction, "shopperLocale": $shopper_locale, "shopperName": $shopper_name, "shopperReference": $shopper_reference, "shopperStatement": $shopper_statement, "socialSecurityNumber": $social_security_number, "splits": $splits, "store": $store, "telephoneNumber": $telephone_number, "threeDS2RequestData": $three_ds2_request_data, "threeDSAuthenticationOnly": $three_ds_authentication_only, "totalsGroup": $totals_group, "trustedShopper": $trusted_shopper} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Complete a 3DS2 authorisation
#
# POST /authorise3ds2
# operationId: post-authorise3ds2
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
# --additionalAmount shape: {currency: string, value: int}
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --dccQuote shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
# --deliveryAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --installments shape: {plan?: "regular"|"revolving", value: int}
# --merchantRiskIndicator shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
# --recurring shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
# --shopperName shape: {firstName: string, lastName: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
# --threeDS2RequestData shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
# --threeDS2Result shape: {authenticationValue?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", dsTransID?: string, eci?: string, exemptionIndicator?: "lowValue"|"secureCorporate"|"trustedBeneficiary"|"transactionRiskAnalysis", messageVersion?: string, riskScore?: string, threeDSServerTransID?: string, timestamp?: string, transStatus?: string, transStatusReason?: string, ... (1 more fields)}
export def "authorise3ds2 create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-info: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, ... (10 more fields)}
  --additional-amount: record # shape: {currency: string, value: int}
  --additional-data: record # This field contains additional data, which may be required for a particular payment request. The `additionalData` object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (180 more fields)}
  amount: record # shape: {currency: string, value: int}
  --application-info: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billing-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browser-info: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --capture-delay-hours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --date-of-birth: string # The shopper's date of birth. Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dcc-quote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --delivery-address: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --delivery-date: string # The date and time the purchased goods should be delivered. Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --device-fingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --fraud-offset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --installments: record # shape: {plan?: "regular"|"revolving", value: int}
  --localized-shopper-statement: record # This field allows merchants to use dynamic shopper statement in local character sets. The local shopper statement field can be supplied in markets where localized merchant descriptors are used. Currently, Adyen only supports this in the Japanese market .The available character sets at the moment are: * Processing in Japan: **ja-Kana** The character set **ja-Kana** supports UTF-8 based Katakana and alphanumeric and special characters. Merchants can use half-width or full-width characters. An example request would be: > { "shopperStatement" : "ADYEN - SELLER-A", "localizedShopperStatement" : { "ja-Kana" : "ADYEN - セラーA" } } We recommend merchants to always supply the field localizedShopperStatement in addition to the field shopperStatement.It is issuer dependent whether the localized shopper statement field is supported. In the case of non-domestic transactions (e.g. US-issued cards processed in JP) the field `shopperStatement` is used to modify the statement of the shopper. Adyen handles the complexity of ensuring the correct descriptors are assigned. Please note, this field can be used for only Visa and Mastercard transactions.
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  --merchant-order-reference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchant-risk-indicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, ... (2 more fields)}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value.
  --order-reference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --recurring: record # shape: {contract?: "ONECLICK"|"RECURRING"|"PAYOUT", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"}
  --recurring-processing-model: string@recurring-processing-model-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selected-brand: string # Some payment methods require defining a value for this field to specify how to process the transaction. For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selected-recurring-detail-reference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --session-id: string # A session ID used to identify a payment session.
  --shopper-email: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > For 3D Secure 2 transactions, schemes require `shopperEmail` for all browser-based and mobile implementations.
  --shopper-ip: string # The shopper's IP address. In general, we recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > For 3D Secure 2 transactions, schemes require `shopperIP` for all browser-based implementations. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopper-interaction: string@shopper-interaction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default. This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopper-locale: string # The combination of a language code and a country code to specify the language to be used in the payment.
  --shopper-name: record # shape: {firstName: string, lastName: string}
  --shopper-reference: string # Required for recurring payments. Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopper-statement: string # The text to be shown on the shopper's bank statement. We recommend sending a maximum of 22 characters, otherwise banks might truncate the string. Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --social-security-number: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using [Adyen for Platforms](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information) or [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --store: string # The ecommerce or point-of-sale store that is processing the payment. Used in [partner model integrations](https://docs.adyen.com/marketplaces-and-platforms/classic/platforms-for-partners#route-payments) for Adyen for Platforms.
  --telephone-number: string # The shopper's telephone number.
  --three-ds2-request-data: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, ... (22 more fields)}
  --three-ds2-result: record # shape: {authenticationValue?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", dsTransID?: string, eci?: string, exemptionIndicator?: "lowValue"|"secureCorporate"|"trustedBeneficiary"|"transactionRiskAnalysis", messageVersion?: string, riskScore?: string, threeDSServerTransID?: string, timestamp?: string, transStatus?: string, transStatusReason?: string, ... (1 more fields)}
  --three-ds2-token: string # The ThreeDS2Token that was returned in the /authorise call.
  --three-ds-authentication-only: oneof<nothing, bool> # If set to true, you will only perform the [3D Secure 2 authentication](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only), and not the payment authorisation. (default: false)
  --totals-group: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trusted-shopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorise3ds2")
  let req_body = {"accountInfo": $account_info, "additionalAmount": $additional_amount, "additionalData": $additional_data, "amount": $amount, "applicationInfo": $application_info, "billingAddress": $billing_address, "browserInfo": $browser_info, "captureDelayHours": $capture_delay_hours, "dateOfBirth": $date_of_birth, "dccQuote": $dcc_quote, "deliveryAddress": $delivery_address, "deliveryDate": $delivery_date, "deviceFingerprint": $device_fingerprint, "fraudOffset": $fraud_offset, "installments": $installments, "localizedShopperStatement": $localized_shopper_statement, "mcc": $mcc, "merchantAccount": $merchant_account, "merchantOrderReference": $merchant_order_reference, "merchantRiskIndicator": $merchant_risk_indicator, "metadata": $metadata, "orderReference": $order_reference, "recurring": $recurring, "recurringProcessingModel": $recurring_processing_model, "reference": $reference, "selectedBrand": $selected_brand, "selectedRecurringDetailReference": $selected_recurring_detail_reference, "sessionId": $session_id, "shopperEmail": $shopper_email, "shopperIP": $shopper_ip, "shopperInteraction": $shopper_interaction, "shopperLocale": $shopper_locale, "shopperName": $shopper_name, "shopperReference": $shopper_reference, "shopperStatement": $shopper_statement, "socialSecurityNumber": $social_security_number, "splits": $splits, "store": $store, "telephoneNumber": $telephone_number, "threeDS2RequestData": $three_ds2_request_data, "threeDS2Result": $three_ds2_result, "threeDS2Token": $three_ds2_token, "threeDSAuthenticationOnly": $three_ds_authentication_only, "totalsGroup": $totals_group, "trustedShopper": $trusted_shopper} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancel an authorisation
#
# POST /cancel
# operationId: post-cancel
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
export def "cancel create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cancel")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "mpiData": $mpi_data, "originalMerchantReference": $original_merchant_reference, "originalReference": $original_reference, "platformChargebackLogic": $platform_chargeback_logic, "reference": $reference, "splits": $splits, "tenderReference": $tender_reference, "uniqueTerminalId": $unique_terminal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancel or refund a payment
#
# POST /cancelOrRefund
# operationId: post-cancelOrRefund
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
export def "cancel-or-refund create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cancelOrRefund")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "mpiData": $mpi_data, "originalMerchantReference": $original_merchant_reference, "originalReference": $original_reference, "platformChargebackLogic": $platform_chargeback_logic, "reference": $reference, "tenderReference": $tender_reference, "uniqueTerminalId": $unique_terminal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Capture an authorisation
#
# POST /capture
# operationId: post-capture
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
export def "capture create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  modification_amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/capture")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "modificationAmount": $modification_amount, "mpiData": $mpi_data, "originalMerchantReference": $original_merchant_reference, "originalReference": $original_reference, "platformChargebackLogic": $platform_chargeback_logic, "reference": $reference, "splits": $splits, "tenderReference": $tender_reference, "uniqueTerminalId": $unique_terminal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create a donation
#
# POST /donate
# operationId: post-donate
# --modificationAmount shape: {currency: string, value: int}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
export def "donate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  donation_account: string # The Adyen account name of the charity.
  merchant_account: string # The merchant account that is used to process the payment.
  modification_amount: record # shape: {currency: string, value: int}
  --original-reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/donate")
  let req_body = {"donationAccount": $donation_account, "merchantAccount": $merchant_account, "modificationAmount": $modification_amount, "originalReference": $original_reference, "platformChargebackLogic": $platform_chargeback_logic, "reference": $reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get the 3DS authentication result
#
# POST /getAuthenticationResult
# operationId: post-getAuthenticationResult
export def "get-authentication-result create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  merchant_account: string # The merchant account identifier, with which the authentication was processed.
  psp_reference: string # The pspReference identifier for the transaction.
]: any -> record<threeDS1Result: record<cavv: string, cavvAlgorithm: string, eci: string, threeDAuthenticatedResponse: string, threeDOfferedResponse: string, xid: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getAuthenticationResult")
  let req_body = {"merchantAccount": $merchant_account, "pspReference": $psp_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Refund a captured payment
#
# POST /refund
# operationId: post-refund
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
export def "refund create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  modification_amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  original_reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refund")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "modificationAmount": $modification_amount, "mpiData": $mpi_data, "originalMerchantReference": $original_merchant_reference, "originalReference": $original_reference, "platformChargebackLogic": $platform_chargeback_logic, "reference": $reference, "splits": $splits, "tenderReference": $tender_reference, "uniqueTerminalId": $unique_terminal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get the 3DS2 authentication result
#
# POST /retrieve3ds2Result
# operationId: post-retrieve3ds2Result
export def "retrieve3ds2-result create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  merchant_account: string # The merchant account identifier, with which you want to process the transaction.
  psp_reference: string # The pspReference returned in the /authorise call.
]: any -> record<threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, challengeIndicator: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retrieve3ds2Result")
  let req_body = {"merchantAccount": $merchant_account, "pspReference": $psp_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancel an authorisation using your reference
#
# POST /technicalCancel
# operationId: post-technicalCancel
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
export def "technical-cancel create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  --modification-amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  original_merchant_reference: string # The original merchant reference to cancel.
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/technicalCancel")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "modificationAmount": $modification_amount, "mpiData": $mpi_data, "originalMerchantReference": $original_merchant_reference, "platformChargebackLogic": $platform_chargeback_logic, "reference": $reference, "splits": $splits, "tenderReference": $tender_reference, "uniqueTerminalId": $unique_terminal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancel an in-person refund
#
# POST /voidPendingRefund
# operationId: post-voidPendingRefund
# --additionalData shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
export def "void-pending-refund create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-data: record # This field contains additional data, which may be required for a particular modification request. The additionalData object consists of entries, each of which includes the key and value. — shape: {allow3DS2?: string, challengeWindowSize?: "01"|"02"|"03"|"04"|"05", executeThreeD?: string, mpiImplementationType?: string, scaExemption?: string, threeDSVersion?: string, airline.agency_invoice_number?: string, airline.agency_plan_name?: string, airline.airline_code?: string, airline.airline_designator_code?: string, airline.boarding_fee?: string, airline.computerized_reservation_system?: string, airline.customer_reference_number?: string, airline.document_type?: string, ... (181 more fields)}
  merchant_account: string # The merchant account that is used to process the payment.
  --modification-amount: record # shape: {currency: string, value: int}
  --mpi-data: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --original-merchant-reference: string # The original merchant reference to cancel.
  --original-reference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification
  --platform-chargeback-logic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For details, refer to [Providing split information](https://docs.adyen.com/marketplaces-and-platforms/processing-payments#providing-split-information). — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
  --tender-reference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --unique-terminal-id: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/voidPendingRefund")
  let req_body = {"additionalData": $additional_data, "merchantAccount": $merchant_account, "modificationAmount": $modification_amount, "mpiData": $mpi_data, "originalMerchantReference": $original_merchant_reference, "originalReference": $original_reference, "platformChargebackLogic": $platform_chargeback_logic, "reference": $reference, "splits": $splits, "tenderReference": $tender_reference, "uniqueTerminalId": $unique_terminal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
