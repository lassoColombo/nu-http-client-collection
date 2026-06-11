# Auto-generated client for Adyen Payment API v68
# Source: https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/PaymentService-v68.yaml
# Auth: --token flag or $env.ADYEN_API_KEY

const BASE_URL = "https://pal-test.adyen.com/pal/servlet/Payment/v68"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADYEN_API_KEY | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://pal-test.adyen.com/pal/servlet/Payment/v68"] }
def auth-scheme-completer [] { ["x-api-key" "basic"] }

# Completers for enum parameters
def entityType-completer [] { ["CompanyName" "NaturalPerson"] }
def fundingSource-completer [] { ["credit" "debit" "prepaid"] }
def recurringProcessingModel-completer [] { ["CardOnFile" "Subscription" "UnscheduledCardOnFile"] }
def shopperInteraction-completer [] { ["ContAuth" "Ecommerce" "Moto" "POS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "adjust-authorisation post-adjustAuthorisation" } } | get name | first)
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
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
export def "adjust-authorisation post-adjustAuthorisation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalData: record # This field contains additional data, which may be required for a particular modification request.  The additionalData object consists of entries, each of which includes the key and value.
  merchantAccount: string # The merchant account that is used to process the payment.
  modificationAmount: record # shape: {currency: string, value: int}
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --originalMerchantReference: string # The original merchant reference to cancel.
  originalReference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification 
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to split payments for [platforms](https://docs.adyen.com/platforms/automatic-split-configuration/). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --tenderReference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --uniqueTerminalId: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/adjustAuthorisation")
  let body = {additionalData: $additionalData, merchantAccount: $merchantAccount, modificationAmount: $modificationAmount, mpiData: $mpiData, originalMerchantReference: $originalMerchantReference, originalReference: $originalReference, platformChargebackLogic: $platformChargebackLogic, reference: $reference, splits: $splits, tenderReference: $tenderReference, uniqueTerminalId: $uniqueTerminalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an authorisation
#
# POST /authorise
# operationId: post-authorise
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
# --additionalAmount shape: {currency: string, value: int}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --bankAccount shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --card shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
# --dccQuote shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
# --deliveryAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --fundDestination shape: {IBAN?: string, additionalData?: record, billingAddress?: record, card?: record, selectedRecurringDetailReference?: string, shopperEmail?: string, shopperName?: record, shopperReference?: string, subMerchant?: record, telephoneNumber?: string, walletPurpose?: string}
# --fundSource shape: {additionalData?: record, billingAddress?: record, card?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string}
# --installments shape: {extra?: int, plan?: "bonus"|"buynow_paylater"|"interes_refund_prctg"|"interest_bonus"|"nointeres_refund_prctg"|"nointerest_bonus"|"refund_prctg"|"regular"|"revolving"|"with_interest", value: int}
# --mandate shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, count?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
# --merchantRiskIndicator shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --recurring shape: {contract?: "ONECLICK"|"ONECLICK,RECURRING"|"RECURRING"|"PAYOUT"|"EXTERNAL", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"|"AMEXTOKENSERVICE"|"TOKEN_SHARING"}
# --secureRemoteCommerceCheckoutData shape: {checkoutPayload?: string, correlationId?: string, cvc?: string, digitalCardId?: string, scheme?: "mc"|"visa", tokenReference?: string}
# --shopperName shape: {firstName: string, lastName: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
# --threeDS2RequestData shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEncData?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, sdkVersion?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
export def "authorise post-authorise" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountInfo: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
  --additionalAmount: record # shape: {currency: string, value: int}
  --additionalData: record # This field contains additional data, which may be required for a particular payment request.  The `additionalData` object consists of entries, each of which includes the key and value.
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --bankAccount: record # shape: {bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
  --billingAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browserInfo: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --captureDelayHours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --card: record # shape: {cvc?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, issueNumber?: string, number?: string, startMonth?: string, startYear?: string}
  --dateOfBirth: string # The shopper's date of birth.  Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dccQuote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --deliveryAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --deliveryDate: string # The date and time the purchased goods should be delivered.  Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD  Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --deviceFingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --entityType: string@entityType-completer # The type of the entity the payment is processed for.
  --fraudOffset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --fundDestination: record # shape: {IBAN?: string, additionalData?: record, billingAddress?: record, card?: record, selectedRecurringDetailReference?: string, shopperEmail?: string, shopperName?: record, shopperReference?: string, subMerchant?: record, telephoneNumber?: string, walletPurpose?: string}
  --fundSource: record # shape: {additionalData?: record, billingAddress?: record, card?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string}
  --fundingSource: string@fundingSource-completer # The funding source that should be used when multiple sources are available. For Brazilian combo cards, by default the funding source is credit. To use debit, set this value to **debit**.
  --installments: record # shape: {extra?: int, plan?: "bonus"|"buynow_paylater"|"interes_refund_prctg"|"interest_bonus"|"nointeres_refund_prctg"|"nointerest_bonus"|"refund_prctg"|"regular"|"revolving"|"with_interest", value: int}
  --localizedShopperStatement: record # The `localizedShopperStatement` field lets you use dynamic values for your shopper statement in a local character set. If this parameter is left empty, not provided, or not applicable (in case of cross-border transactions), then **shopperStatement** is used.  Currently, `localizedShopperStatement` is only supported for payments with Visa, Mastercard, JCB, Diners, and Discover.  **Supported characters**: Hiragana, Katakana, Kanji, and alphanumeric.
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, count?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  --merchantOrderReference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchantRiskIndicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value. 
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --nationality: string # The two-character country code of the shopper's nationality.
  --orderReference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurring: record # shape: {contract?: "ONECLICK"|"ONECLICK,RECURRING"|"RECURRING"|"PAYOUT"|"EXTERNAL", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"|"AMEXTOKENSERVICE"|"TOKEN_SHARING"}
  --recurringProcessingModel: string@recurringProcessingModel-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --secureRemoteCommerceCheckoutData: record # shape: {checkoutPayload?: string, correlationId?: string, cvc?: string, digitalCardId?: string, scheme?: "mc"|"visa", tokenReference?: string}
  --selectedBrand: string # Some payment methods require defining a value for this field to specify how to process the transaction.  For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selectedRecurringDetailReference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --sessionId: string # A session ID used to identify a payment session.
  --shopperEmail: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > Required for Visa and JCB transactions that require 3D Secure 2 authentication if you did not include the `telephoneNumber`.
  --shopperIP: string # The shopper's IP address. We recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > Required for Visa and JCB transactions that require 3D Secure 2 authentication for all web and mobile integrations, if you did not include the `shopperEmail`. For native mobile integrations, the field is required to support cases where authentication is routed to the redirect flow. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopperInteraction: string@shopperInteraction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default.  This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopperLocale: string # The language for the payment. The value combines the two-letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) language code with the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) country code. For example, **nl-NL**.  When using Drop-in/Components, the specified language appears if your front-end global configuration does not set the `locale`.
  --shopperName: record # shape: {firstName: string, lastName: string}
  --shopperReference: string # Required for recurring payments.  Your reference to uniquely identify this shopper, for example user ID or account ID. The value is case-sensitive and must be at least three characters. > Your reference must not include personally identifiable information (PII) such as name or email address.
  --shopperStatement: string # The text to be shown on the shopper's bank statement.  We recommend sending a maximum of 22 characters, otherwise banks might truncate the string.  Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --socialSecurityNumber: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using either Adyen for Platforms for [marketplaces](https://docs.adyen.com/marketplaces/split-payments) or [platforms](https://docs.adyen.com/platforms/split-payments), or standalone [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --store: string # Required for Adyen for Platforms integrations if you are a platform model. This is your [reference](https://docs.adyen.com/api-explorer/Management/3/post/merchants/(merchantId)/stores#request-reference) (on [balance platform](https://docs.adyen.com/platforms)) or the [storeReference](https://docs.adyen.com/api-explorer/Account/latest/post/updateAccountHolder#request-accountHolderDetails-storeDetails-storeReference) (in the [classic integration](https://docs.adyen.com/classic-platforms/processing-payments/route-payment-to-store/#route-a-payment-to-a-store)) for the ecommerce or point-of-sale store that is processing the payment.
  --telephoneNumber: string # The shopper's telephone number.  The phone number must include a plus sign (+) and a country code (1-3 digits), followed by the number (4-15 digits). If the value you provide does not follow the guidelines, we do not submit it for authentication. > Required for Visa and JCB transactions that require 3D Secure 2 authentication, if you did not include the `shopperEmail`.
  --threeDS2RequestData: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEncData?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, sdkVersion?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
  --threeDSAuthenticationOnly: string@bool-completer # Required to trigger the [authentication-only flow](https://docs.adyen.com/online-payments/3d-secure/authentication-only/). If set to **true**, you will only perform the 3D Secure 2 authentication, and will not proceed to the payment authorization.Default: **false**. (default: false)
  --totalsGroup: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trustedShopper: string@bool-completer # Set to true if the payment should be routed to a trusted MID.
]: any -> record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorise")
  let body = {accountInfo: $accountInfo, additionalAmount: $additionalAmount, additionalData: $additionalData, amount: $amount, applicationInfo: $applicationInfo, bankAccount: $bankAccount, billingAddress: $billingAddress, browserInfo: $browserInfo, captureDelayHours: $captureDelayHours, card: $card, dateOfBirth: $dateOfBirth, dccQuote: $dccQuote, deliveryAddress: $deliveryAddress, deliveryDate: $deliveryDate, deviceFingerprint: $deviceFingerprint, entityType: $entityType, fraudOffset: $fraudOffset, fundDestination: $fundDestination, fundSource: $fundSource, fundingSource: $fundingSource, installments: $installments, localizedShopperStatement: $localizedShopperStatement, mandate: $mandate, mcc: $mcc, merchantAccount: $merchantAccount, merchantOrderReference: $merchantOrderReference, merchantRiskIndicator: $merchantRiskIndicator, metadata: $metadata, mpiData: $mpiData, nationality: $nationality, orderReference: $orderReference, platformChargebackLogic: $platformChargebackLogic, recurring: $recurring, recurringProcessingModel: $recurringProcessingModel, reference: $reference, secureRemoteCommerceCheckoutData: $secureRemoteCommerceCheckoutData, selectedBrand: $selectedBrand, selectedRecurringDetailReference: $selectedRecurringDetailReference, sessionId: $sessionId, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperInteraction: $shopperInteraction, shopperLocale: $shopperLocale, shopperName: $shopperName, shopperReference: $shopperReference, shopperStatement: $shopperStatement, socialSecurityNumber: $socialSecurityNumber, splits: $splits, store: $store, telephoneNumber: $telephoneNumber, threeDS2RequestData: $threeDS2RequestData, threeDSAuthenticationOnly: $threeDSAuthenticationOnly, totalsGroup: $totalsGroup, trustedShopper: $trustedShopper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete a 3DS authorisation
#
# POST /authorise3d
# operationId: post-authorise3d
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
# --additionalAmount shape: {currency: string, value: int}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --dccQuote shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
# --deliveryAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --installments shape: {extra?: int, plan?: "bonus"|"buynow_paylater"|"interes_refund_prctg"|"interest_bonus"|"nointeres_refund_prctg"|"nointerest_bonus"|"refund_prctg"|"regular"|"revolving"|"with_interest", value: int}
# --merchantRiskIndicator shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
# --recurring shape: {contract?: "ONECLICK"|"ONECLICK,RECURRING"|"RECURRING"|"PAYOUT"|"EXTERNAL", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"|"AMEXTOKENSERVICE"|"TOKEN_SHARING"}
# --shopperName shape: {firstName: string, lastName: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
# --threeDS2RequestData shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEncData?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, sdkVersion?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
export def "authorise3d post-authorise3d" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountInfo: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
  --additionalAmount: record # shape: {currency: string, value: int}
  --additionalData: record # This field contains additional data, which may be required for a particular payment request.  The `additionalData` object consists of entries, each of which includes the key and value.
  --amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billingAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browserInfo: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --captureDelayHours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --dateOfBirth: string # The shopper's date of birth.  Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dccQuote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --deliveryAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --deliveryDate: string # The date and time the purchased goods should be delivered.  Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD  Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --deviceFingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --fraudOffset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --installments: record # shape: {extra?: int, plan?: "bonus"|"buynow_paylater"|"interes_refund_prctg"|"interest_bonus"|"nointeres_refund_prctg"|"nointerest_bonus"|"refund_prctg"|"regular"|"revolving"|"with_interest", value: int}
  --localizedShopperStatement: record # The `localizedShopperStatement` field lets you use dynamic values for your shopper statement in a local character set. If this parameter is left empty, not provided, or not applicable (in case of cross-border transactions), then **shopperStatement** is used.  Currently, `localizedShopperStatement` is only supported for payments with Visa, Mastercard, JCB, Diners, and Discover.  **Supported characters**: Hiragana, Katakana, Kanji, and alphanumeric.
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  md: string # The payment session identifier returned by the card issuer.
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  --merchantOrderReference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchantRiskIndicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value. 
  --orderReference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  paResponse: string # Payment authorisation response returned by the card issuer. The `paResponse` field holds the PaRes value received from the card issuer.
  --recurring: record # shape: {contract?: "ONECLICK"|"ONECLICK,RECURRING"|"RECURRING"|"PAYOUT"|"EXTERNAL", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"|"AMEXTOKENSERVICE"|"TOKEN_SHARING"}
  --recurringProcessingModel: string@recurringProcessingModel-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selectedBrand: string # Some payment methods require defining a value for this field to specify how to process the transaction.  For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selectedRecurringDetailReference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --sessionId: string # A session ID used to identify a payment session.
  --shopperEmail: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > Required for Visa and JCB transactions that require 3D Secure 2 authentication if you did not include the `telephoneNumber`.
  --shopperIP: string # The shopper's IP address. We recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > Required for Visa and JCB transactions that require 3D Secure 2 authentication for all web and mobile integrations, if you did not include the `shopperEmail`. For native mobile integrations, the field is required to support cases where authentication is routed to the redirect flow. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopperInteraction: string@shopperInteraction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default.  This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopperLocale: string # The language for the payment. The value combines the two-letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) language code with the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) country code. For example, **nl-NL**.  When using Drop-in/Components, the specified language appears if your front-end global configuration does not set the `locale`.
  --shopperName: record # shape: {firstName: string, lastName: string}
  --shopperReference: string # Required for recurring payments.  Your reference to uniquely identify this shopper, for example user ID or account ID. The value is case-sensitive and must be at least three characters. > Your reference must not include personally identifiable information (PII) such as name or email address.
  --shopperStatement: string # The text to be shown on the shopper's bank statement.  We recommend sending a maximum of 22 characters, otherwise banks might truncate the string.  Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --socialSecurityNumber: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using either Adyen for Platforms for [marketplaces](https://docs.adyen.com/marketplaces/split-payments) or [platforms](https://docs.adyen.com/platforms/split-payments), or standalone [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --store: string # Required for Adyen for Platforms integrations if you are a platform model. This is your [reference](https://docs.adyen.com/api-explorer/Management/3/post/merchants/(merchantId)/stores#request-reference) (on [balance platform](https://docs.adyen.com/platforms)) or the [storeReference](https://docs.adyen.com/api-explorer/Account/latest/post/updateAccountHolder#request-accountHolderDetails-storeDetails-storeReference) (in the [classic integration](https://docs.adyen.com/classic-platforms/processing-payments/route-payment-to-store/#route-a-payment-to-a-store)) for the ecommerce or point-of-sale store that is processing the payment.
  --telephoneNumber: string # The shopper's telephone number.  The phone number must include a plus sign (+) and a country code (1-3 digits), followed by the number (4-15 digits). If the value you provide does not follow the guidelines, we do not submit it for authentication. > Required for Visa and JCB transactions that require 3D Secure 2 authentication, if you did not include the `shopperEmail`.
  --threeDS2RequestData: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEncData?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, sdkVersion?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
  --threeDSAuthenticationOnly: string@bool-completer # Required to trigger the [authentication-only flow](https://docs.adyen.com/online-payments/3d-secure/authentication-only/). If set to **true**, you will only perform the 3D Secure 2 authentication, and will not proceed to the payment authorization.Default: **false**. (default: false)
  --totalsGroup: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trustedShopper: string@bool-completer # Set to true if the payment should be routed to a trusted MID.
]: any -> record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorise3d")
  let body = {accountInfo: $accountInfo, additionalAmount: $additionalAmount, additionalData: $additionalData, amount: $amount, applicationInfo: $applicationInfo, billingAddress: $billingAddress, browserInfo: $browserInfo, captureDelayHours: $captureDelayHours, dateOfBirth: $dateOfBirth, dccQuote: $dccQuote, deliveryAddress: $deliveryAddress, deliveryDate: $deliveryDate, deviceFingerprint: $deviceFingerprint, fraudOffset: $fraudOffset, installments: $installments, localizedShopperStatement: $localizedShopperStatement, mcc: $mcc, md: $md, merchantAccount: $merchantAccount, merchantOrderReference: $merchantOrderReference, merchantRiskIndicator: $merchantRiskIndicator, metadata: $metadata, orderReference: $orderReference, paResponse: $paResponse, recurring: $recurring, recurringProcessingModel: $recurringProcessingModel, reference: $reference, selectedBrand: $selectedBrand, selectedRecurringDetailReference: $selectedRecurringDetailReference, sessionId: $sessionId, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperInteraction: $shopperInteraction, shopperLocale: $shopperLocale, shopperName: $shopperName, shopperReference: $shopperReference, shopperStatement: $shopperStatement, socialSecurityNumber: $socialSecurityNumber, splits: $splits, store: $store, telephoneNumber: $telephoneNumber, threeDS2RequestData: $threeDS2RequestData, threeDSAuthenticationOnly: $threeDSAuthenticationOnly, totalsGroup: $totalsGroup, trustedShopper: $trustedShopper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete a 3DS2 authorisation
#
# POST /authorise3ds2
# operationId: post-authorise3ds2
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
# --additionalAmount shape: {currency: string, value: int}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --dccQuote shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
# --deliveryAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --installments shape: {extra?: int, plan?: "bonus"|"buynow_paylater"|"interes_refund_prctg"|"interest_bonus"|"nointeres_refund_prctg"|"nointerest_bonus"|"refund_prctg"|"regular"|"revolving"|"with_interest", value: int}
# --merchantRiskIndicator shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
# --recurring shape: {contract?: "ONECLICK"|"ONECLICK,RECURRING"|"RECURRING"|"PAYOUT"|"EXTERNAL", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"|"AMEXTOKENSERVICE"|"TOKEN_SHARING"}
# --shopperName shape: {firstName: string, lastName: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
# --threeDS2RequestData shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEncData?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, sdkVersion?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
# --threeDS2Result shape: {authenticationValue?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", dsTransID?: string, eci?: string, exemptionIndicator?: "lowValue"|"secureCorporate"|"trustedBeneficiary"|"transactionRiskAnalysis", messageVersion?: string, riskScore?: string, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSServerTransID?: string, timestamp?: string, transStatus?: string, transStatusReason?: string, whiteListStatus?: string}
export def "authorise3ds2 post-authorise3ds2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountInfo: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
  --additionalAmount: record # shape: {currency: string, value: int}
  --additionalData: record # This field contains additional data, which may be required for a particular payment request.  The `additionalData` object consists of entries, each of which includes the key and value.
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billingAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browserInfo: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --captureDelayHours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --dateOfBirth: string # The shopper's date of birth.  Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --dccQuote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --deliveryAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --deliveryDate: string # The date and time the purchased goods should be delivered.  Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD  Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --deviceFingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --fraudOffset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --installments: record # shape: {extra?: int, plan?: "bonus"|"buynow_paylater"|"interes_refund_prctg"|"interest_bonus"|"nointeres_refund_prctg"|"nointerest_bonus"|"refund_prctg"|"regular"|"revolving"|"with_interest", value: int}
  --localizedShopperStatement: record # The `localizedShopperStatement` field lets you use dynamic values for your shopper statement in a local character set. If this parameter is left empty, not provided, or not applicable (in case of cross-border transactions), then **shopperStatement** is used.  Currently, `localizedShopperStatement` is only supported for payments with Visa, Mastercard, JCB, Diners, and Discover.  **Supported characters**: Hiragana, Katakana, Kanji, and alphanumeric.
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  --merchantOrderReference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --merchantRiskIndicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value. 
  --orderReference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --recurring: record # shape: {contract?: "ONECLICK"|"ONECLICK,RECURRING"|"RECURRING"|"PAYOUT"|"EXTERNAL", recurringDetailName?: string, recurringExpiry?: string, recurringFrequency?: string, tokenService?: "VISATOKENSERVICE"|"MCTOKENSERVICE"|"AMEXTOKENSERVICE"|"TOKEN_SHARING"}
  --recurringProcessingModel: string@recurringProcessingModel-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  --selectedBrand: string # Some payment methods require defining a value for this field to specify how to process the transaction.  For the Bancontact payment method, it can be set to: * `maestro` (default), to be processed like a Maestro card, or * `bcmc`, to be processed like a Bancontact card.
  --selectedRecurringDetailReference: string # The `recurringDetailReference` you want to use for this payment. The value `LATEST` can be used to select the most recently stored recurring detail.
  --sessionId: string # A session ID used to identify a payment session.
  --shopperEmail: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > Required for Visa and JCB transactions that require 3D Secure 2 authentication if you did not include the `telephoneNumber`.
  --shopperIP: string # The shopper's IP address. We recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > Required for Visa and JCB transactions that require 3D Secure 2 authentication for all web and mobile integrations, if you did not include the `shopperEmail`. For native mobile integrations, the field is required to support cases where authentication is routed to the redirect flow. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopperInteraction: string@shopperInteraction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default.  This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopperLocale: string # The language for the payment. The value combines the two-letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) language code with the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) country code. For example, **nl-NL**.  When using Drop-in/Components, the specified language appears if your front-end global configuration does not set the `locale`.
  --shopperName: record # shape: {firstName: string, lastName: string}
  --shopperReference: string # Required for recurring payments.  Your reference to uniquely identify this shopper, for example user ID or account ID. The value is case-sensitive and must be at least three characters. > Your reference must not include personally identifiable information (PII) such as name or email address.
  --shopperStatement: string # The text to be shown on the shopper's bank statement.  We recommend sending a maximum of 22 characters, otherwise banks might truncate the string.  Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --socialSecurityNumber: string # The shopper's social security number.
  --splits: list # An array of objects specifying how the payment should be split when using either Adyen for Platforms for [marketplaces](https://docs.adyen.com/marketplaces/split-payments) or [platforms](https://docs.adyen.com/platforms/split-payments), or standalone [Issuing](https://docs.adyen.com/issuing/add-manage-funds#split). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --store: string # Required for Adyen for Platforms integrations if you are a platform model. This is your [reference](https://docs.adyen.com/api-explorer/Management/3/post/merchants/(merchantId)/stores#request-reference) (on [balance platform](https://docs.adyen.com/platforms)) or the [storeReference](https://docs.adyen.com/api-explorer/Account/latest/post/updateAccountHolder#request-accountHolderDetails-storeDetails-storeReference) (in the [classic integration](https://docs.adyen.com/classic-platforms/processing-payments/route-payment-to-store/#route-a-payment-to-a-store)) for the ecommerce or point-of-sale store that is processing the payment.
  --telephoneNumber: string # The shopper's telephone number.  The phone number must include a plus sign (+) and a country code (1-3 digits), followed by the number (4-15 digits). If the value you provide does not follow the guidelines, we do not submit it for authentication. > Required for Visa and JCB transactions that require 3D Secure 2 authentication, if you did not include the `shopperEmail`.
  --threeDS2RequestData: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceChannel: string, deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEncData?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, sdkVersion?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
  --threeDS2Result: record # shape: {authenticationValue?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", dsTransID?: string, eci?: string, exemptionIndicator?: "lowValue"|"secureCorporate"|"trustedBeneficiary"|"transactionRiskAnalysis", messageVersion?: string, riskScore?: string, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSServerTransID?: string, timestamp?: string, transStatus?: string, transStatusReason?: string, whiteListStatus?: string}
  --threeDS2Token: string # The ThreeDS2Token that was returned in the /authorise call.
  --threeDSAuthenticationOnly: string@bool-completer # Required to trigger the [authentication-only flow](https://docs.adyen.com/online-payments/3d-secure/authentication-only/). If set to **true**, you will only perform the 3D Secure 2 authentication, and will not proceed to the payment authorization.Default: **false**. (default: false)
  --totalsGroup: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trustedShopper: string@bool-completer # Set to true if the payment should be routed to a trusted MID.
]: any -> record<additionalData: record, authCode: string, dccAmount: record<currency: string, value: int>, dccSignature: string, fraudResult: record<accountScore: int, results: list<record>>, issuerUrl: string, md: string, paRequest: string, pspReference: string, refusalReason: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorise3ds2")
  let body = {accountInfo: $accountInfo, additionalAmount: $additionalAmount, additionalData: $additionalData, amount: $amount, applicationInfo: $applicationInfo, billingAddress: $billingAddress, browserInfo: $browserInfo, captureDelayHours: $captureDelayHours, dateOfBirth: $dateOfBirth, dccQuote: $dccQuote, deliveryAddress: $deliveryAddress, deliveryDate: $deliveryDate, deviceFingerprint: $deviceFingerprint, fraudOffset: $fraudOffset, installments: $installments, localizedShopperStatement: $localizedShopperStatement, mcc: $mcc, merchantAccount: $merchantAccount, merchantOrderReference: $merchantOrderReference, merchantRiskIndicator: $merchantRiskIndicator, metadata: $metadata, orderReference: $orderReference, recurring: $recurring, recurringProcessingModel: $recurringProcessingModel, reference: $reference, selectedBrand: $selectedBrand, selectedRecurringDetailReference: $selectedRecurringDetailReference, sessionId: $sessionId, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperInteraction: $shopperInteraction, shopperLocale: $shopperLocale, shopperName: $shopperName, shopperReference: $shopperReference, shopperStatement: $shopperStatement, socialSecurityNumber: $socialSecurityNumber, splits: $splits, store: $store, telephoneNumber: $telephoneNumber, threeDS2RequestData: $threeDS2RequestData, threeDS2Result: $threeDS2Result, threeDS2Token: $threeDS2Token, threeDSAuthenticationOnly: $threeDSAuthenticationOnly, totalsGroup: $totalsGroup, trustedShopper: $trustedShopper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel an authorisation
#
# POST /cancel
# operationId: post-cancel
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
export def "cancel post-cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalData: record # This field contains additional data, which may be required for a particular modification request.  The additionalData object consists of entries, each of which includes the key and value.
  merchantAccount: string # The merchant account that is used to process the payment.
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --originalMerchantReference: string # The original merchant reference to cancel.
  originalReference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification 
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to split payments for [platforms](https://docs.adyen.com/platforms/automatic-split-configuration/). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --tenderReference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --uniqueTerminalId: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cancel")
  let body = {additionalData: $additionalData, merchantAccount: $merchantAccount, mpiData: $mpiData, originalMerchantReference: $originalMerchantReference, originalReference: $originalReference, platformChargebackLogic: $platformChargebackLogic, reference: $reference, splits: $splits, tenderReference: $tenderReference, uniqueTerminalId: $uniqueTerminalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel or refund a payment
#
# POST /cancelOrRefund
# operationId: post-cancelOrRefund
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
export def "cancel-or-refund post-cancelOrRefund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalData: record # This field contains additional data, which may be required for a particular modification request.  The additionalData object consists of entries, each of which includes the key and value.
  merchantAccount: string # The merchant account that is used to process the payment.
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --originalMerchantReference: string # The original merchant reference to cancel.
  originalReference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification 
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --tenderReference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --uniqueTerminalId: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cancelOrRefund")
  let body = {additionalData: $additionalData, merchantAccount: $merchantAccount, mpiData: $mpiData, originalMerchantReference: $originalMerchantReference, originalReference: $originalReference, platformChargebackLogic: $platformChargebackLogic, reference: $reference, tenderReference: $tenderReference, uniqueTerminalId: $uniqueTerminalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Capture an authorisation
#
# POST /capture
# operationId: post-capture
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
export def "capture post-capture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalData: record # This field contains additional data, which may be required for a particular modification request.  The additionalData object consists of entries, each of which includes the key and value.
  merchantAccount: string # The merchant account that is used to process the payment.
  modificationAmount: record # shape: {currency: string, value: int}
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --originalMerchantReference: string # The original merchant reference to cancel.
  originalReference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification 
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to split payments for [platforms](https://docs.adyen.com/platforms/automatic-split-configuration/). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --tenderReference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --uniqueTerminalId: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/capture")
  let body = {additionalData: $additionalData, merchantAccount: $merchantAccount, modificationAmount: $modificationAmount, mpiData: $mpiData, originalMerchantReference: $originalMerchantReference, originalReference: $originalReference, platformChargebackLogic: $platformChargebackLogic, reference: $reference, splits: $splits, tenderReference: $tenderReference, uniqueTerminalId: $uniqueTerminalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a donation
#
# POST /donate
# DEPRECATED
# operationId: post-donate
# --modificationAmount shape: {currency: string, value: int}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
@deprecated
export def "donate post-donate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  donationAccount: string # The Adyen account name of the charity.
  merchantAccount: string # The merchant account that is used to process the payment.
  modificationAmount: record # shape: {currency: string, value: int}
  --originalReference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification 
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/donate")
  let body = {donationAccount: $donationAccount, merchantAccount: $merchantAccount, modificationAmount: $modificationAmount, originalReference: $originalReference, platformChargebackLogic: $platformChargebackLogic, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the 3DS authentication result
#
# POST /getAuthenticationResult
# operationId: post-getAuthenticationResult
export def "get-authentication-result post-getAuthenticationResult" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merchantAccount: string # The merchant account identifier, with which the authentication was processed.
  pspReference: string # The pspReference identifier for the transaction.
]: any -> record<threeDS1Result: record<cavv: string, cavvAlgorithm: string, eci: string, threeDAuthenticatedResponse: string, threeDOfferedResponse: string, xid: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSRequestorChallengeInd: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getAuthenticationResult")
  let body = {merchantAccount: $merchantAccount, pspReference: $pspReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refund a captured payment
#
# POST /refund
# operationId: post-refund
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
export def "refund post-refund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalData: record # This field contains additional data, which may be required for a particular modification request.  The additionalData object consists of entries, each of which includes the key and value.
  merchantAccount: string # The merchant account that is used to process the payment.
  modificationAmount: record # shape: {currency: string, value: int}
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --originalMerchantReference: string # The original merchant reference to cancel.
  originalReference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification 
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to split payments for [platforms](https://docs.adyen.com/platforms/automatic-split-configuration/). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --tenderReference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --uniqueTerminalId: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refund")
  let body = {additionalData: $additionalData, merchantAccount: $merchantAccount, modificationAmount: $modificationAmount, mpiData: $mpiData, originalMerchantReference: $originalMerchantReference, originalReference: $originalReference, platformChargebackLogic: $platformChargebackLogic, reference: $reference, splits: $splits, tenderReference: $tenderReference, uniqueTerminalId: $uniqueTerminalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the 3DS2 authentication result
#
# POST /retrieve3ds2Result
# operationId: post-retrieve3ds2Result
export def "retrieve3ds2-result post-retrieve3ds2Result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  pspReference: string # The pspReference returned in the /authorise call.
]: any -> record<threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSRequestorChallengeInd: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retrieve3ds2Result")
  let body = {merchantAccount: $merchantAccount, pspReference: $pspReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel an authorisation using your reference
#
# POST /technicalCancel
# operationId: post-technicalCancel
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
export def "technical-cancel post-technicalCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalData: record # This field contains additional data, which may be required for a particular modification request.  The additionalData object consists of entries, each of which includes the key and value.
  merchantAccount: string # The merchant account that is used to process the payment.
  --modificationAmount: record # shape: {currency: string, value: int}
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  originalMerchantReference: string # The original merchant reference to cancel.
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to split payments for [platforms](https://docs.adyen.com/platforms/automatic-split-configuration/). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --tenderReference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --uniqueTerminalId: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/technicalCancel")
  let body = {additionalData: $additionalData, merchantAccount: $merchantAccount, modificationAmount: $modificationAmount, mpiData: $mpiData, originalMerchantReference: $originalMerchantReference, platformChargebackLogic: $platformChargebackLogic, reference: $reference, splits: $splits, tenderReference: $tenderReference, uniqueTerminalId: $uniqueTerminalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel an in-person refund
#
# POST /voidPendingRefund
# operationId: post-voidPendingRefund
# --modificationAmount shape: {currency: string, value: int}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
export def "void-pending-refund post-voidPendingRefund" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalData: record # This field contains additional data, which may be required for a particular modification request.  The additionalData object consists of entries, each of which includes the key and value.
  merchantAccount: string # The merchant account that is used to process the payment.
  --modificationAmount: record # shape: {currency: string, value: int}
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --originalMerchantReference: string # The original merchant reference to cancel.
  --originalReference: string # The original pspReference of the payment to modify. This reference is returned in: * authorisation response * authorisation notification 
  --platformChargebackLogic: record # shape: {behavior?: "deductAccordingToSplitRatio"|"deductFromLiableAccount"|"deductFromOneBalanceAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the payment modification. This reference is visible in Customer Area and in reports. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to split payments for [platforms](https://docs.adyen.com/platforms/automatic-split-configuration/). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --tenderReference: string # The transaction reference provided by the PED. For point-of-sale integrations only.
  --uniqueTerminalId: string # Unique terminal ID for the PED that originally processed the request. For point-of-sale integrations only.
]: any -> record<additionalData: record, pspReference: string, response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/voidPendingRefund")
  let body = {additionalData: $additionalData, merchantAccount: $merchantAccount, modificationAmount: $modificationAmount, mpiData: $mpiData, originalMerchantReference: $originalMerchantReference, originalReference: $originalReference, platformChargebackLogic: $platformChargebackLogic, reference: $reference, splits: $splits, tenderReference: $tenderReference, uniqueTerminalId: $uniqueTerminalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
