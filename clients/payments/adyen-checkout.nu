# Auto-generated client for Adyen Checkout API v71
# Source: https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/CheckoutService-v71.yaml
# Auth: --token flag or $env.ADYEN_API_KEY

const BASE_URL = "https://checkout-test.adyen.com/v71"
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

def base-url-completer [] { ["https://checkout-test.adyen.com/v71"] }
def auth-scheme-completer [] { ["x-api-key" "basic"] }

# Completers for enum parameters
def channel-completer [] { ["Android" "Web" "iOS"] }
def recurringProcessingModel-completer [] { ["CardOnFile" "Subscription" "UnscheduledCardOnFile"] }
def shopperInteraction-completer [] { ["ContAuth" "Ecommerce" "Moto" "POS"] }
def storePaymentMethodMode-completer [] { ["askForConsent" "disabled" "enabled"] }
def status-completer [] { ["expired"] }
def storeFiltrationMode-completer [] { ["exclusive" "inclusive" "skipFilter"] }
def entityType-completer [] { ["CompanyName" "NaturalPerson"] }
def industryUsage-completer [] { ["delayedCharge" "installment" "noShow"] }
def merchantRefundReason-completer [] { ["CUSTOMER REQUEST" "DUPLICATE" "FRAUD" "OTHER" "RETURN"] }
def mode-completer [] { ["embedded" "hosted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apple-pay-sessions post-applePay-sessions" } } | get name | first)
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

# Get an Apple Pay session
#
# POST /applePay/sessions
# operationId: post-applePay-sessions
export def "apple-pay-sessions post-applePay-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  displayName: string # This is the name that your shoppers will see in the Apple Pay interface.  The value returned as `configuration.merchantName` field from the [`/paymentMethods`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/paymentMethods) response.
  domainName: string # The domain name you provided when you added Apple Pay in your Customer Area.  This must match the `window.location.hostname` of the web shop.
  merchantIdentifier: string # Your merchant identifier registered with Apple Pay.  Use the value of the `configuration.merchantId` field from the [`/paymentMethods`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/paymentMethods) response.
]: any -> record<data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/applePay/sessions")
  let body = {displayName: $displayName, domainName: $domainName, merchantIdentifier: $merchantIdentifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel an authorised payment
#
# POST /cancels
# operationId: post-cancels
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --enhancedSchemeData shape: {airline?: record, levelTwoThree?: record}
export def "cancels post-cancels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --enhancedSchemeData: record # shape: {airline?: record, levelTwoThree?: record}
  merchantAccount: string # The merchant account that is used to process the payment.
  paymentReference: string # The [`reference`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/payments__reqParam_reference) of the payment that you want to cancel.
  --reference: string # Your reference for the cancel request. Maximum length: 80 characters.
]: any -> record<merchantAccount: string, paymentReference: string, pspReference: string, reference: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cancels")
  let body = {applicationInfo: $applicationInfo, enhancedSchemeData: $enhancedSchemeData, merchantAccount: $merchantAccount, paymentReference: $paymentReference, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the brands and other details of a card
#
# POST /cardDetails
# operationId: post-cardDetails
export def "card-details post-cardDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --cardNumber: string # A minimum of the first six digits of the card number. The full card number gives the best result.   You must be [fully PCI compliant](https://docs.adyen.com/development-resources/pci-dss-compliance-guide) to collect raw card data. Alternatively, you can use the `encryptedCardNumber` field.
  --countryCode: string # The shopper country code.  Format: [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) Example: NL or DE
  --encryptedCardNumber: string # The encrypted card number.
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  --supportedBrands: list # The card brands you support. This is the [`brands`](https://docs.adyen.com/api-explorer/Checkout/latest/post/paymentMethods#responses-200-paymentMethods-brands) array from your [`/paymentMethods`](https://docs.adyen.com/api-explorer/#/CheckoutService/latest/post/paymentMethods) response.   If not included, our API uses the ones configured for your merchant account and, if provided, the country code.
]: any -> record<brands: table<supported: bool, type: string>, fundingSource: string, isCardCommercial: bool, issuingCountryCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cardDetails")
  let body = {cardNumber: $cardNumber, countryCode: $countryCode, encryptedCardNumber: $encryptedCardNumber, merchantAccount: $merchantAccount, supportedBrands: $supportedBrands} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of donation campaigns.
#
# POST /donationCampaigns
# operationId: post-donationCampaigns
export def "donation-campaigns post-donationCampaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  currency: string # The three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes/).
  --locale: string # Locale on the shopper interaction device.
  merchantAccount: string # Your merchant account identifier.
  --store: string # Required for Adyen for Platforms integrations if you are a platform model. This is your [reference](https://docs.adyen.com/api-explorer/Management/3/post/merchants/(merchantId)/stores#request-reference) (on [balance platform](https://docs.adyen.com/platforms)) or the [storeReference](https://docs.adyen.com/api-explorer/Account/latest/post/updateAccountHolder#request-accountHolderDetails-storeDetails-storeReference) (in the [classic integration](https://docs.adyen.com/classic-platforms/processing-payments/route-payment-to-store/#route-a-payment-to-a-store)) for the ecommerce or point-of-sale store that is processing the payment.
]: any -> record<donationCampaigns: table<amounts: record, bannerUrl: string, campaignName: string, causeName: string, donation: record, id: string, logoUrl: string, nonprofitDescription: string, nonprofitName: string, nonprofitUrl: string, termsAndConditionsUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/donationCampaigns")
  let body = {currency: $currency, locale: $locale, merchantAccount: $merchantAccount, store: $store} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Make a donation
#
# POST /donations
# operationId: post-donations
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --authenticationData shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --deliveryAddress shape: {city: string, country: string, firstName?: string, houseNumberOrName: string, lastName?: string, postalCode: string, stateOrProvince?: string, street: string}
# --lineItems item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
# --merchantRiskIndicator shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --shopperName shape: {firstName: string, lastName: string}
# --threeDS2RequestData shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
@deprecated --flag conversionId
@deprecated --flag threeDSAuthenticationOnly
export def "donations post-donations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --accountInfo: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
  --additionalData: record # This field contains additional data, which may be required for a particular payment request.  The `additionalData` object consists of entries, each of which includes the key and value.
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --authenticationData: record # shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
  --billingAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browserInfo: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field is optional for filtering out payment methods that are only available on specific platforms. If this value is not set, then we will try to infer it from the `sdkVersion` or `token`.  Possible values: * iOS * Android * Web
  --checkoutAttemptId: string # Checkout attempt ID that corresponds to the Id generated by the client SDK for tracking user payment journey.
  --conversionId: string # Conversion ID that corresponds to the Id generated by the client SDK for tracking user payment journey. (DEPRECATED)
  --countryCode: string # The shopper country code.  Format: [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) Example: NL or DE
  --dateOfBirth: string # The shopper's date of birth.  Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date-time)
  --deliverAt: string # The date and time the purchased goods should be delivered.  Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD  Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --deliveryAddress: record # shape: {city: string, country: string, firstName?: string, houseNumberOrName: string, lastName?: string, postalCode: string, stateOrProvince?: string, street: string}
  --deviceFingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --donationAccount: string # Donation account to which the transaction is credited.
  --donationCampaignId: string # The donation campaign ID received in the `/donationCampaigns` call.
  --donationOriginalPspReference: string # PSP reference of the transaction from which the donation token is generated. Required when `donationToken` is provided.
  --donationToken: string # Donation token received in the `/payments` call.
  --lineItems: list # Price and product information about the purchased items, to be included on the invoice sent to the shopper. > This field is required for 3x 4x Oney, Affirm, Afterpay, Clearpay, Klarna, Ratepay, and Riverty. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  --merchantRiskIndicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value. 
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --origin: string # > Required for browser-based (`channel` **Web**) 3D Secure 2 transactions.Set this to the origin URL of the page where you are rendering the Drop-in/Component. Do not include subdirectories and a trailing slash.
  --paymentMethod: any # The type and required details of a payment method to use.  When `donationToken` is provided, the payment method is derived from the token and this field becomes optional.  If you are [PCI compliant](https://docs.adyen.com/development-resources/pci-dss-compliance-guide), and make donations using raw card details, you must explicitly provide the payment method details.
  --recurringProcessingModel: string@recurringProcessingModel-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --redirectFromIssuerMethod: string # Specifies the redirect method (GET or POST) when redirecting back from the issuer.
  --redirectToIssuerMethod: string # Specifies the redirect method (GET or POST) when redirecting to the issuer.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.
  returnUrl: string # The URL to return to in case of a redirection. The format depends on the channel.  * For web, include the protocol `http://` or `https://`. You can also include your own additional query parameters, for example, shopper ID or order reference number. Example: `https://your-company.example.com/checkout?shopperOrder=12xy` * For iOS, use the custom URL for your app. To know more about setting custom URL schemes, refer to the [Apple Developer documentation](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app). Example: `my-app://` * For Android, use a custom URL handled by an Activity on your app. You can configure it with an [intent filter](https://developer.android.com/guide/components/intents-filters). Example: `my-app://your.package.name`  If the URL to return to includes non-ASCII characters, like spaces or special letters, URL encode the value.  We strongly recommend that you use a maximum of 1024 characters.  > The URL must not include personally identifiable information (PII), for example name or email address.
  --sessionValidity: string # The date and time until when the session remains valid, in [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format.  For example: 2020-07-18T15:42:40.428+01:00
  --shopperEmail: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > Required for Visa and JCB transactions that require 3D Secure 2 authentication if you did not include the `telephoneNumber`.
  --shopperIP: string # The shopper's IP address. We recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > Required for Visa and JCB transactions that require 3D Secure 2 authentication for all web and mobile integrations, if you did not include the `shopperEmail`. For native mobile integrations, the field is required to support cases where authentication is routed to the redirect flow. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopperInteraction: string@shopperInteraction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default.  This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorization rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorization (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopperLocale: string # The language for the payment. The value combines the two-letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) language code with the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) country code. For example, **nl-NL**.  When using Drop-in/Components, the specified language appears if your front-end global configuration does not set the `locale`.
  --shopperName: record # shape: {firstName: string, lastName: string}
  --shopperReference: string # Required for recurring payments.  Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --socialSecurityNumber: string # The shopper's social security number.
  --store: string # Required for Adyen for Platforms integrations if you are a platform model. This is your [reference](https://docs.adyen.com/api-explorer/Management/3/post/merchants/(merchantId)/stores#request-reference) (on [balance platform](https://docs.adyen.com/platforms)) or the [storeReference](https://docs.adyen.com/api-explorer/Account/latest/post/updateAccountHolder#request-accountHolderDetails-storeDetails-storeReference) (in the [classic integration](https://docs.adyen.com/classic-platforms/processing-payments/route-payment-to-store/#route-a-payment-to-a-store)) for the ecommerce or point-of-sale store that is processing the payment.
  --telephoneNumber: string # The shopper's telephone number.  The phone number must include a plus sign (+) and a country code (1-3 digits), followed by the number (4-15 digits). If the value you provide does not follow the guidelines, we do not submit it for authentication. > Required for Visa and JCB transactions that require 3D Secure 2 authentication, if you did not include the `shopperEmail`.
  --threeDS2RequestData: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
  --threeDSAuthenticationOnly: oneof<nothing, bool> # Required to trigger the [authentication-only flow](https://docs.adyen.com/online-payments/3d-secure/authentication-only/). If set to **true**, you will only perform the 3D Secure 2 authentication, and will not proceed to the payment authorization.Default: **false**. (DEPRECATED, default: false)
]: any -> record<amount: record<currency: string, value: int>, donationAccount: string, id: string, merchantAccount: string, payment: record<action: any, additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list>, merchantReference: string, order: record<amount: record, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record>, paymentMethod: record<brand: string, type: string>, paymentValidations: record<name: record>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSRequestorChallengeInd: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string>, reference: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/donations")
  let body = {accountInfo: $accountInfo, additionalData: $additionalData, amount: $amount, applicationInfo: $applicationInfo, authenticationData: $authenticationData, billingAddress: $billingAddress, browserInfo: $browserInfo, channel: $channel, checkoutAttemptId: $checkoutAttemptId, conversionId: $conversionId, countryCode: $countryCode, dateOfBirth: $dateOfBirth, deliverAt: $deliverAt, deliveryAddress: $deliveryAddress, deviceFingerprint: $deviceFingerprint, donationAccount: $donationAccount, donationCampaignId: $donationCampaignId, donationOriginalPspReference: $donationOriginalPspReference, donationToken: $donationToken, lineItems: $lineItems, merchantAccount: $merchantAccount, merchantRiskIndicator: $merchantRiskIndicator, metadata: $metadata, mpiData: $mpiData, origin: $origin, paymentMethod: $paymentMethod, recurringProcessingModel: $recurringProcessingModel, redirectFromIssuerMethod: $redirectFromIssuerMethod, redirectToIssuerMethod: $redirectToIssuerMethod, reference: $reference, returnUrl: $returnUrl, sessionValidity: $sessionValidity, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperInteraction: $shopperInteraction, shopperLocale: $shopperLocale, shopperName: $shopperName, shopperReference: $shopperReference, socialSecurityNumber: $socialSecurityNumber, store: $store, telephoneNumber: $telephoneNumber, threeDS2RequestData: $threeDS2RequestData, threeDSAuthenticationOnly: $threeDSAuthenticationOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Forward stored payment details
#
# POST /forward
# operationId: post-forward
# --amount shape: {currency: string, value: int}
# --options shape: {accountUpdate?: bool, dryRun?: bool, networkToken?: record, networkTxReferencePaths?: list, tokenize?: bool, transactionLinkIdPaths?: list}
# --paymentMethod shape: {cvc?: string, encryptedCardNumber?: string, encryptedExpiryMonth?: string, encryptedExpiryYear?: string, encryptedSecurityCode?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, number?: string, type?: "scheme"}
# --request shape: {body: string, credentials?: string, headers?: record, httpMethod: "post"|"put"|"patch", urlSuffix?: string}
export def "forward post-forward" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --amount: record # shape: {currency: string, value: int}
  baseUrl: string # The base URL of the third party API, where Adyen will send the request to forward the payment details.
  merchantAccount: string # Your merchant account.
  --merchantReference: string # Merchant defined payment reference.
  --options: record # shape: {accountUpdate?: bool, dryRun?: bool, networkToken?: record, networkTxReferencePaths?: list, tokenize?: bool, transactionLinkIdPaths?: list}
  --paymentMethod: record # shape: {cvc?: string, encryptedCardNumber?: string, encryptedExpiryMonth?: string, encryptedExpiryYear?: string, encryptedSecurityCode?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, number?: string, type?: "scheme"}
  request: record # shape: {body: string, credentials?: string, headers?: record, httpMethod: "post"|"put"|"patch", urlSuffix?: string}
  shopperReference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. The value is case-sensitive and must be at least three characters. > Your reference must not include personally identifiable information (PII) such as name or email address.
  --storedPaymentMethodId: string # The unique identifier of the token that you want to forward to the third party. This is the `storedPaymentMethodId` you received in the webhook after you created the token.
]: any -> record<merchantReference: string, pspReference: string, response: record<body: string, headers: record, status: int>, storedPaymentMethodId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/forward")
  let body = {amount: $amount, baseUrl: $baseUrl, merchantAccount: $merchantAccount, merchantReference: $merchantReference, options: $options, paymentMethod: $paymentMethod, request: $request, shopperReference: $shopperReference, storedPaymentMethodId: $storedPaymentMethodId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an order
#
# POST /orders
# operationId: post-orders
# --amount shape: {currency: string, value: int}
export def "orders post-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  amount: record # shape: {currency: string, value: int}
  --expiresAt: string # The date when the order should expire. If not provided, the default expiry duration is 1 day.  [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format: YYYY-MM-DDThh:mm:ss+TZD, for example, **2020-12-18T10:15:30+01:00**.
  merchantAccount: string # The merchant account identifier, with which you want to process the order.
  reference: string # A custom reference identifying the order.
]: any -> record<additionalData: record, amount: record<currency: string, value: int>, expiresAt: string, fraudResult: record<accountScore: int, results: list<record>>, orderData: string, pspReference: string, reference: string, refusalReason: string, remainingAmount: record<currency: string, value: int>, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let body = {amount: $amount, expiresAt: $expiresAt, merchantAccount: $merchantAccount, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel an order
#
# POST /orders/cancel
# operationId: post-orders-cancel
# --order shape: {orderData: string, pspReference: string}
export def "orders-cancel post-orders-cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  merchantAccount: string # The merchant account identifier that orderData belongs to.
  order: record # shape: {orderData: string, pspReference: string}
]: any -> record<pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/cancel")
  let body = {merchantAccount: $merchantAccount, order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create originKey values for domains
#
# POST /originKeys
# DEPRECATED
# operationId: post-originKeys
@deprecated
export def "origin-keys post-originKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  originDomains: list # The list of origin domains, for which origin keys are requested.
]: any -> record<originKeys: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/originKeys")
  let body = {originDomains: $originDomains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a payment link
#
# POST /paymentLinks
# operationId: post-paymentLinks
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --deliveryAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --fundOrigin shape: {billingAddress?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string, walletIdentifier?: string}
# --fundRecipient shape: {IBAN?: string, billingAddress?: record, paymentMethod?: record, shopperEmail?: string, shopperName?: record, shopperReference?: string, storedPaymentMethodId?: string, subMerchant?: record, telephoneNumber?: string, walletIdentifier?: string, walletOwnerTaxId?: string, walletPurpose?: "identifiedBoleto"|"transferDifferentWallet"|"transferOwnWallet"|"transferSameWallet"|"unidentifiedBoleto"}
# --lineItems item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
# --platformChargebackLogic shape: {behavior?: "deductFromOneBalanceAccount"|"deductAccordingToSplitRatio"|"deductFromLiableAccount", costAllocationAccount?: string, targetAccount?: string}
# --riskData shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
# --shopperName shape: {firstName: string, lastName: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
# --threeDS2RequestData shape: {homePhone?: record, mobilePhone?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", workPhone?: record}
export def "payment-links post-paymentLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --allowedPaymentMethods: list # List of payment methods to be presented to the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types).  Example: `"allowedPaymentMethods":["ideal","applepay"]`
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --billingAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --blockedPaymentMethods: list # List of payment methods to be hidden from the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types).  Example: `"blockedPaymentMethods":["ideal","applepay"]`
  --captureDelayHours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --countryCode: string # The shopper's two-letter country code.
  --dateOfBirth: string # The shopper's date of birth.  Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --deliverAt: string # The date and time when the purchased goods should be delivered.  [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format: YYYY-MM-DDThh:mm:ss+TZD, for example, **2020-12-18T10:15:30+01:00**. (format: date-time)
  --deliveryAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --description: string # A short description visible on the payment page. Maximum length: 280 characters.
  --expiresAt: string # The date when the payment link expires.  [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format with time zone offset: YYYY-MM-DDThh:mm:ss+TZD, for example, **2020-12-18T10:15:30+01:00**.  The maximum expiry date is 70 days after the payment link is created.  If not provided, the payment link expires 24 hours after it was created. (format: date-time)
  --fundOrigin: record # shape: {billingAddress?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string, walletIdentifier?: string}
  --fundRecipient: record # shape: {IBAN?: string, billingAddress?: record, paymentMethod?: record, shopperEmail?: string, shopperName?: record, shopperReference?: string, storedPaymentMethodId?: string, subMerchant?: record, telephoneNumber?: string, walletIdentifier?: string, walletOwnerTaxId?: string, walletPurpose?: "identifiedBoleto"|"transferDifferentWallet"|"transferOwnWallet"|"transferSameWallet"|"unidentifiedBoleto"}
  --installmentOptions: record # A set of key-value pairs that specifies the installment options available per payment method. The key must be a payment method name in lowercase. For example, **card** to specify installment options for all cards, or **visa** or **mc**. The value must be an object containing the installment options.
  --lineItems: list # Price and product information about the purchased items, to be included on the invoice sent to the shopper. > This field is required for 3x 4x Oney, Affirm, Afterpay, Clearpay, Klarna, Ratepay, and Riverty. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  --manualCapture: oneof<nothing, bool> # Indicates if the payment must be [captured manually](https://docs.adyen.com/online-payments/capture).
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchantAccount: string # The merchant account identifier for which the payment link is created.
  --merchantOrderReference: string # This reference allows linking multiple transactions to each other for reporting purposes (for example, order auth-rate). The reference should be unique per billing cycle.
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limitations: * Maximum 20 key-value pairs per request. Otherwise, error "177" occurs: "Metadata size exceeds limit" * Maximum 20 characters per key. Otherwise, error "178" occurs: "Metadata key size exceeds limit" * A key cannot have the name `checkout.linkId`. Any value that you provide with this key is going to be replaced by the real payment link ID.
  --platformChargebackLogic: record # shape: {behavior?: "deductFromOneBalanceAccount"|"deductAccordingToSplitRatio"|"deductFromLiableAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurringProcessingModel: string@recurringProcessingModel-completer # Defines a recurring payment type. Required when `storePaymentMethodMode` is set to **askForConsent** or **enabled**. Possible values: * **Subscription** – A transaction for a fixed or variable amount, which follows a fixed schedule. * **CardOnFile** – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * **UnscheduledCardOnFile** – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or has variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  reference: string # A reference that is used to uniquely identify the payment in future communications about the payment status.
  --requiredShopperFields: list # List of fields that the shopper has to provide on the payment page before completing the payment. For more information, refer to [Provide shopper information](https://docs.adyen.com/unified-commerce/pay-by-link/payment-links/api#shopper-information).  Possible values: * **billingAddress** – The address where to send the invoice. * **deliveryAddress** – The address where the purchased goods should be delivered. * **shopperEmail** – The shopper's email address. * **shopperName** – The shopper's full name. * **telephoneNumber** – The shopper's phone number.
  --returnUrl: string # Website URL used for redirection after payment is completed. If provided, a **Continue** button will be shown on the payment page. If shoppers select the button, they are redirected to the specified URL.
  --reusable: oneof<nothing, bool> # Indicates whether the payment link can be reused for multiple payments. If not provided, this defaults to **false** which means the link can be used for one successful payment only.
  --riskData: record # shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
  --shopperEmail: string # The shopper's email address.
  --shopperLocale: string # The language to be used in the payment page, specified by a combination of a language and country code. For example, `en-US`.  For a list of shopper locales that Pay by Link supports, refer to [Language and localization](https://docs.adyen.com/unified-commerce/pay-by-link/payment-links/api#language).
  --shopperName: record # shape: {firstName: string, lastName: string}
  --shopperReference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. The value is case-sensitive and must be at least three characters. > Your reference must not include personally identifiable information (PII) such as name or email address.
  --shopperStatement: string # The text to be shown on the shopper's bank statement.  We recommend sending a maximum of 22 characters, otherwise banks might truncate the string.  Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --showRemovePaymentMethodButton: oneof<nothing, bool> # Set to **false** to hide the button that lets the shopper remove a stored payment method. (default: true)
  --socialSecurityNumber: string # The shopper's social security number.
  --splitCardFundingSources: oneof<nothing, bool> # Boolean value indicating whether the card payment method should be split into separate debit and credit options. (default: false)
  --splits: list # An array of objects specifying how to split a payment when using [Adyen for Platforms](https://docs.adyen.com/platforms/process-payments#providing-split-information), [Classic Platforms integration](https://docs.adyen.com/classic-platforms/processing-payments#providing-split-information), or [Issuing](https://docs.adyen.com/issuing/manage-funds#split). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --store: string # The physical store, for which this payment is processed.
  --storePaymentMethodMode: string@storePaymentMethodMode-completer # Indicates if the details of the payment method will be stored for the shopper. Possible values: * **disabled** – No details will be stored (default). * **askForConsent** – If the `shopperReference` is provided, the Drop-in/Component shows a checkbox where the shopper can select to store their payment details for card payments. * **enabled** – If the `shopperReference` is provided, the details will be stored without asking the shopper for consent.   When set to **askForConsent** or **enabled**, you must also include the `recurringProcessingModel` parameter.
  --telephoneNumber: string # The shopper's telephone number.  The phone number must include a plus sign (+) and a country code (1-3 digits), followed by the number (4-15 digits). If the value you provide does not follow the guidelines, we do not submit it for authentication. > Required for Visa and JCB transactions that require 3D Secure 2 authentication, if you did not include the `shopperEmail`.
  --themeId: string # A [theme](https://docs.adyen.com/unified-commerce/pay-by-link/payment-links/api#themes) to customize the appearance of the payment page. If not specified, the payment page is rendered according to the theme set as default in your Customer Area.
  --threeDS2RequestData: record # shape: {homePhone?: record, mobilePhone?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", workPhone?: record}
]: any -> record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, fundOrigin: record<billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, telephoneNumber: string, walletIdentifier: string>, fundRecipient: record<IBAN: string, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, paymentMethod: record<billingSequenceNumber: string, brand: string, checkoutAttemptId: string, cupsecureplus_smscode: string, cvc: string, encryptedCard: string, encryptedCardNumber: string, encryptedExpiryMonth: string, encryptedExpiryYear: string, encryptedPassword: string, encryptedSecurityCode: string, expiryMonth: string, expiryYear: string, fastlaneData: string, fundingSource: string, holderName: string, networkPaymentReference: string, number: string, recurringDetailReference: string, sdkData: string, shopperNotificationReference: string, srcCorrelationId: string, srcDigitalCardId: string, srcScheme: string, srcTokenReference: string, storedPaymentMethodId: string, threeDS2SdkVersion: string, type: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, storedPaymentMethodId: string, subMerchant: record<city: string, country: string, mcc: string, name: string, taxId: string>, telephoneNumber: string, walletIdentifier: string, walletOwnerTaxId: string, walletPurpose: string>, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, marketplaceSellerId: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, platformChargebackLogic: record<behavior: string, costAllocationAccount: string, targetAccount: string>, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, threeDS2RequestData: record<homePhone: record<cc: string, subscriber: string>, mobilePhone: record<cc: string, subscriber: string>, threeDSRequestorChallengeInd: string, workPhone: record<cc: string, subscriber: string>>, updatedAt: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentLinks")
  let body = {allowedPaymentMethods: $allowedPaymentMethods, amount: $amount, applicationInfo: $applicationInfo, billingAddress: $billingAddress, blockedPaymentMethods: $blockedPaymentMethods, captureDelayHours: $captureDelayHours, countryCode: $countryCode, dateOfBirth: $dateOfBirth, deliverAt: $deliverAt, deliveryAddress: $deliveryAddress, description: $description, expiresAt: $expiresAt, fundOrigin: $fundOrigin, fundRecipient: $fundRecipient, installmentOptions: $installmentOptions, lineItems: $lineItems, manualCapture: $manualCapture, mcc: $mcc, merchantAccount: $merchantAccount, merchantOrderReference: $merchantOrderReference, metadata: $metadata, platformChargebackLogic: $platformChargebackLogic, recurringProcessingModel: $recurringProcessingModel, reference: $reference, requiredShopperFields: $requiredShopperFields, returnUrl: $returnUrl, reusable: $reusable, riskData: $riskData, shopperEmail: $shopperEmail, shopperLocale: $shopperLocale, shopperName: $shopperName, shopperReference: $shopperReference, shopperStatement: $shopperStatement, showRemovePaymentMethodButton: $showRemovePaymentMethodButton, socialSecurityNumber: $socialSecurityNumber, splitCardFundingSources: $splitCardFundingSources, splits: $splits, store: $store, storePaymentMethodMode: $storePaymentMethodMode, telephoneNumber: $telephoneNumber, themeId: $themeId, threeDS2RequestData: $threeDS2RequestData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a payment link
#
# GET /paymentLinks/{linkId}
# operationId: get-paymentLinks-linkId
export def "payment-links get-paymentLinks-linkId" [
  linkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, fundOrigin: record<billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, telephoneNumber: string, walletIdentifier: string>, fundRecipient: record<IBAN: string, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, paymentMethod: record<billingSequenceNumber: string, brand: string, checkoutAttemptId: string, cupsecureplus_smscode: string, cvc: string, encryptedCard: string, encryptedCardNumber: string, encryptedExpiryMonth: string, encryptedExpiryYear: string, encryptedPassword: string, encryptedSecurityCode: string, expiryMonth: string, expiryYear: string, fastlaneData: string, fundingSource: string, holderName: string, networkPaymentReference: string, number: string, recurringDetailReference: string, sdkData: string, shopperNotificationReference: string, srcCorrelationId: string, srcDigitalCardId: string, srcScheme: string, srcTokenReference: string, storedPaymentMethodId: string, threeDS2SdkVersion: string, type: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, storedPaymentMethodId: string, subMerchant: record<city: string, country: string, mcc: string, name: string, taxId: string>, telephoneNumber: string, walletIdentifier: string, walletOwnerTaxId: string, walletPurpose: string>, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, marketplaceSellerId: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, platformChargebackLogic: record<behavior: string, costAllocationAccount: string, targetAccount: string>, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, threeDS2RequestData: record<homePhone: record<cc: string, subscriber: string>, mobilePhone: record<cc: string, subscriber: string>, threeDSRequestorChallengeInd: string, workPhone: record<cc: string, subscriber: string>>, updatedAt: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentLinks/($linkId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the status of a payment link
#
# PATCH /paymentLinks/{linkId}
# operationId: patch-paymentLinks-linkId
export def "payment-links patch-paymentLinks-linkId" [
  linkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer # Status of the payment link. Possible values: * **expired**
]: any -> record<allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, description: string, expiresAt: string, fundOrigin: record<billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, telephoneNumber: string, walletIdentifier: string>, fundRecipient: record<IBAN: string, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, paymentMethod: record<billingSequenceNumber: string, brand: string, checkoutAttemptId: string, cupsecureplus_smscode: string, cvc: string, encryptedCard: string, encryptedCardNumber: string, encryptedExpiryMonth: string, encryptedExpiryYear: string, encryptedPassword: string, encryptedSecurityCode: string, expiryMonth: string, expiryYear: string, fastlaneData: string, fundingSource: string, holderName: string, networkPaymentReference: string, number: string, recurringDetailReference: string, sdkData: string, shopperNotificationReference: string, srcCorrelationId: string, srcDigitalCardId: string, srcScheme: string, srcTokenReference: string, storedPaymentMethodId: string, threeDS2SdkVersion: string, type: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, storedPaymentMethodId: string, subMerchant: record<city: string, country: string, mcc: string, name: string, taxId: string>, telephoneNumber: string, walletIdentifier: string, walletOwnerTaxId: string, walletPurpose: string>, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, marketplaceSellerId: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, manualCapture: bool, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, platformChargebackLogic: record<behavior: string, costAllocationAccount: string, targetAccount: string>, recurringProcessingModel: string, reference: string, requiredShopperFields: list<string>, returnUrl: string, reusable: bool, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, shopperEmail: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, threeDS2RequestData: record<homePhone: record<cc: string, subscriber: string>, mobilePhone: record<cc: string, subscriber: string>, threeDSRequestorChallengeInd: string, workPhone: record<cc: string, subscriber: string>>, updatedAt: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentLinks/($linkId)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of available payment methods
#
# POST /paymentMethods
# operationId: post-paymentMethods
# --amount shape: {currency: string, value: int}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --order shape: {orderData: string, pspReference: string}
export def "payment-methods post-paymentMethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --additionalData: record # This field contains additional data, which may be required for a particular payment request.  The `additionalData` object consists of entries, each of which includes the key and value.
  --allowedPaymentMethods: list # List of payment methods to be presented to the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types).  Example: `"allowedPaymentMethods":["ideal","applepay"]`
  --amount: record # shape: {currency: string, value: int}
  --blockedPaymentMethods: list # List of payment methods to be hidden from the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types).  Example: `"blockedPaymentMethods":["ideal","applepay"]`
  --browserInfo: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field can be used for filtering out payment methods that are only available on specific platforms. Possible values: * iOS * Android * Web
  --countryCode: string # The shopper's country code.
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  --order: record # shape: {orderData: string, pspReference: string}
  --shopperConversionId: string # A unique ID to [connect the shopper to a single checkout session](https://docs.adyen.com/online-payments/checkout-settings#checkout-shopper-conversion-id) that uses multiple API requests. You can use this to get insights into conversion rates.
  --shopperEmail: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > Required for Visa and JCB transactions that require 3D Secure 2 authentication if you did not include the `telephoneNumber`.
  --shopperIP: string # The shopper's IP address. We recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > Required for Visa and JCB transactions that require 3D Secure 2 authentication for all web and mobile integrations, if you did not include the `shopperEmail`. For native mobile integrations, the field is required to support cases where authentication is routed to the redirect flow. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopperLocale: string # The language for the payment. The value combines the two-letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) language code with the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) country code. For example, **nl-NL**.  When using Drop-in/Components, the specified language appears if your front-end global configuration does not set the `locale`.
  --shopperReference: string # Required for recurring payments.  Your reference to uniquely identify this shopper, for example user ID or account ID. The value is case-sensitive and must be at least three characters. > Your reference must not include personally identifiable information (PII) such as name or email address.
  --splitCardFundingSources: oneof<nothing, bool> # Boolean value indicating whether the card payment method should be split into separate debit and credit options. (default: false)
  --store: string # Required for Adyen for Platforms integrations if you are a platform model. This is your [reference](https://docs.adyen.com/api-explorer/Management/3/post/merchants/(merchantId)/stores#request-reference) (on [balance platform](https://docs.adyen.com/platforms)) or the [storeReference](https://docs.adyen.com/api-explorer/Account/latest/post/updateAccountHolder#request-accountHolderDetails-storeDetails-storeReference) (in the [classic integration](https://docs.adyen.com/classic-platforms/processing-payments/route-payment-to-store/#route-a-payment-to-a-store)) for the ecommerce or point-of-sale store that is processing the payment.
  --storeFiltrationMode: string@storeFiltrationMode-completer # Specifies how payment methods should be filtered based on the `store` parameter:   - **exclusive**: Only payment methods belonging to the specified `store` are returned.   - **inclusive**: Payment methods from the `store` and those not associated with any other store are returned.
  --telephoneNumber: string # The shopper's telephone number.  The phone number must include a plus sign (+) and a country code (1-3 digits), followed by the number (4-15 digits). If the value you provide does not follow the guidelines, we do not submit it for authentication. > Required for Visa and JCB transactions that require 3D Secure 2 authentication, if you did not include the `shopperEmail`.
]: any -> record<paymentMethods: table<apps: list, brand: string, brands: list, configuration: record, fundingSource: string, group: record, inputDetails: list, issuers: list, name: string, promoted: bool, type: string>, storedPaymentMethods: table<bankAccountNumber: string, bankLocationId: string, brand: string, cashtag: string, expiryMonth: string, expiryYear: string, holderName: string, iban: string, id: string, label: string, lastFour: string, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, supportedRecurringProcessingModels: list, supportedShopperInteractions: list, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentMethods")
  let body = {additionalData: $additionalData, allowedPaymentMethods: $allowedPaymentMethods, amount: $amount, blockedPaymentMethods: $blockedPaymentMethods, browserInfo: $browserInfo, channel: $channel, countryCode: $countryCode, merchantAccount: $merchantAccount, order: $order, shopperConversionId: $shopperConversionId, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperLocale: $shopperLocale, shopperReference: $shopperReference, splitCardFundingSources: $splitCardFundingSources, store: $store, storeFiltrationMode: $storeFiltrationMode, telephoneNumber: $telephoneNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the balance of a gift card
#
# POST /paymentMethods/balance
# operationId: post-paymentMethods-balance
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
@deprecated --flag threeDSAuthenticationOnly
export def "payment-methods-balance post-paymentMethods-balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
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
  paymentMethod: record # The collection that contains the type of the payment method and its specific information.
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
  --threeDSAuthenticationOnly: oneof<nothing, bool> # Required to trigger the [authentication-only flow](https://docs.adyen.com/online-payments/3d-secure/authentication-only/). If set to **true**, you will only perform the 3D Secure 2 authentication, and will not proceed to the payment authorization.Default: **false**. (DEPRECATED, default: false)
  --totalsGroup: string # The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).
  --trustedShopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> record<additionalData: record, balance: record<currency: string, value: int>, fraudResult: record<accountScore: int, results: list<record>>, pspReference: string, refusalReason: string, resultCode: string, transactionLimit: record<currency: string, value: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentMethods/balance")
  let body = {accountInfo: $accountInfo, additionalAmount: $additionalAmount, additionalData: $additionalData, amount: $amount, applicationInfo: $applicationInfo, billingAddress: $billingAddress, browserInfo: $browserInfo, captureDelayHours: $captureDelayHours, dateOfBirth: $dateOfBirth, dccQuote: $dccQuote, deliveryAddress: $deliveryAddress, deliveryDate: $deliveryDate, deviceFingerprint: $deviceFingerprint, fraudOffset: $fraudOffset, installments: $installments, localizedShopperStatement: $localizedShopperStatement, mcc: $mcc, merchantAccount: $merchantAccount, merchantOrderReference: $merchantOrderReference, merchantRiskIndicator: $merchantRiskIndicator, metadata: $metadata, orderReference: $orderReference, paymentMethod: $paymentMethod, recurring: $recurring, recurringProcessingModel: $recurringProcessingModel, reference: $reference, selectedBrand: $selectedBrand, selectedRecurringDetailReference: $selectedRecurringDetailReference, sessionId: $sessionId, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperInteraction: $shopperInteraction, shopperLocale: $shopperLocale, shopperName: $shopperName, shopperReference: $shopperReference, shopperStatement: $shopperStatement, socialSecurityNumber: $socialSecurityNumber, splits: $splits, store: $store, telephoneNumber: $telephoneNumber, threeDS2RequestData: $threeDS2RequestData, threeDSAuthenticationOnly: $threeDSAuthenticationOnly, totalsGroup: $totalsGroup, trustedShopper: $trustedShopper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start a transaction
#
# POST /payments
# operationId: post-payments
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
# --additionalAmount shape: {currency: string, value: int}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --authenticationData shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
# --bankAccount shape: {accountType?: "balance"|"checking"|"deposit"|"general"|"other"|"payment"|"savings", bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --browserInfo shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
# --company shape: {homepage?: string, name?: string, registrationNumber?: string, registryLocation?: string, taxId?: string, type?: string}
# --dccQuote shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
# --deliveryAddress shape: {city: string, country: string, firstName?: string, houseNumberOrName: string, lastName?: string, postalCode: string, stateOrProvince?: string, street: string}
# --enhancedSchemeData shape: {airline?: record, levelTwoThree?: record}
# --fundOrigin shape: {billingAddress?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string, walletIdentifier?: string}
# --fundRecipient shape: {IBAN?: string, billingAddress?: record, paymentMethod?: record, shopperEmail?: string, shopperName?: record, shopperReference?: string, storedPaymentMethodId?: string, subMerchant?: record, telephoneNumber?: string, walletIdentifier?: string, walletOwnerTaxId?: string, walletPurpose?: "identifiedBoleto"|"transferDifferentWallet"|"transferOwnWallet"|"transferSameWallet"|"unidentifiedBoleto"}
# --installments shape: {extra?: int, plan?: "bonus"|"buynow_paylater"|"interes_refund_prctg"|"interest_bonus"|"nointeres_refund_prctg"|"nointerest_bonus"|"refund_prctg"|"regular"|"revolving"|"with_interest", value: int}
# --lineItems item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
# --mandate shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, count?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
# --merchantRiskIndicator shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --order shape: {orderData: string, pspReference: string}
# --paymentValidations shape: {name?: record}
# --platformChargebackLogic shape: {behavior?: "deductFromOneBalanceAccount"|"deductAccordingToSplitRatio"|"deductFromLiableAccount", costAllocationAccount?: string, targetAccount?: string}
# --riskData shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
# --shopperName shape: {firstName: string, lastName: string}
# --shopperTaxInfo shape: {taxCountryCode: string, taxIdentificationNumber: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
# --subMerchants item shape: {address?: record, amount?: record, email?: string, id?: string, mcc?: string, name?: string, phoneNumber?: string, registeredSince?: string, taxId?: string, url?: string}
# --surcharge shape: {value: int}
# --threeDS2RequestData shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
@deprecated --flag conversionId
@deprecated --flag deliveryDate
@deprecated --flag threeDSAuthenticationOnly
export def "payments post-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --accountInfo: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
  --additionalAmount: record # shape: {currency: string, value: int}
  --additionalData: record # This field contains additional data, which may be required for a particular payment request.  The `additionalData` object consists of entries, each of which includes the key and value.
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --authenticationData: record # shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
  --bankAccount: record # shape: {accountType?: "balance"|"checking"|"deposit"|"general"|"other"|"payment"|"savings", bankAccountNumber?: string, bankCity?: string, bankLocationId?: string, bankName?: string, bic?: string, countryCode?: string, iban?: string, ownerName?: string, taxId?: string}
  --billingAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --browserInfo: record # shape: {acceptHeader: string, colorDepth: int, javaEnabled: bool, javaScriptEnabled?: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int, userAgent: string}
  --captureDelayHours: int # The [delay between the authorization and automatic capture](https://docs.adyen.com/online-payments/capture?tab=delayed-individual_2#delayed-automatic-capture) of the payment, specified in hours.  Maximum value: **672** (28 days). (format: int32)
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field is optional for filtering out payment methods that are only available on specific platforms. If this value is not set, then we will try to infer it from the `sdkVersion` or `token`.  Possible values: * iOS * Android * Web
  --checkoutAttemptId: string # Checkout attempt ID that corresponds to the Id generated by the client SDK for tracking user payment journey.
  --company: record # shape: {homepage?: string, name?: string, registrationNumber?: string, registryLocation?: string, taxId?: string, type?: string}
  --conversionId: string # Conversion ID that corresponds to the Id generated by the client SDK for tracking user payment journey. (DEPRECATED)
  --countryCode: string # The shopper country code.  Format: [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) Example: NL or DE
  --dateOfBirth: string # The shopper's date of birth.  Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date-time)
  --dccQuote: record # shape: {account?: string, accountType?: string, baseAmount?: record, basePoints: int, buy?: record, interbank?: record, reference?: string, sell?: record, signature?: string, source?: string, type?: string, validTill: string}
  --deliverAt: string # The date and time the purchased goods should be delivered.  Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD  Example: 2017-07-17T13:42:40.428+01:00 (format: date-time)
  --deliveryAddress: record # shape: {city: string, country: string, firstName?: string, houseNumberOrName: string, lastName?: string, postalCode: string, stateOrProvince?: string, street: string}
  --deliveryDate: string # The date and time the purchased goods should be delivered.  Format [ISO 8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DDThh:mm:ss.sssTZD  Example: 2017-07-17T13:42:40.428+01:00 (DEPRECATED, format: date-time)
  --deviceFingerprint: string # A string containing the shopper's device fingerprint. For more information, refer to [Device fingerprinting](https://docs.adyen.com/risk-management/device-fingerprinting).
  --enableOneClick: oneof<nothing, bool> # When true and `shopperReference` is provided, the shopper will be asked if the payment details should be stored for future [one-click payments](https://docs.adyen.com/get-started-with-adyen/payment-glossary/#one-click-payments-definition).
  --enablePayOut: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for payouts.
  --enableRecurring: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be stored for [recurring payments](https://docs.adyen.com/online-payments/tokenization/#recurring-payment-types) where the shopper is not present, such as subscription or automatic top-up payments.
  --enhancedSchemeData: record # shape: {airline?: record, levelTwoThree?: record}
  --entityType: string@entityType-completer # The type of the entity the payment is processed for.
  --fraudOffset: int # An integer value that is added to the normal fraud score. The value can be either positive or negative. (format: int32)
  --fundOrigin: record # shape: {billingAddress?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string, walletIdentifier?: string}
  --fundRecipient: record # shape: {IBAN?: string, billingAddress?: record, paymentMethod?: record, shopperEmail?: string, shopperName?: record, shopperReference?: string, storedPaymentMethodId?: string, subMerchant?: record, telephoneNumber?: string, walletIdentifier?: string, walletOwnerTaxId?: string, walletPurpose?: "identifiedBoleto"|"transferDifferentWallet"|"transferOwnWallet"|"transferSameWallet"|"unidentifiedBoleto"}
  --industryUsage: string@industryUsage-completer # The reason for the amount update. Possible values:  * **delayedCharge**  * **noShow**  * **installment**
  --installments: record # shape: {extra?: int, plan?: "bonus"|"buynow_paylater"|"interes_refund_prctg"|"interest_bonus"|"nointeres_refund_prctg"|"nointerest_bonus"|"refund_prctg"|"regular"|"revolving"|"with_interest", value: int}
  --lineItems: list # Price and product information about the purchased items, to be included on the invoice sent to the shopper. > This field is required for 3x 4x Oney, Affirm, Afterpay, Clearpay, Klarna, Ratepay, and Riverty. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  --localizedShopperStatement: record # The `localizedShopperStatement` field lets you use dynamic values for your shopper statement in a local character set. If this parameter is left empty, not provided, or not applicable (in case of cross-border transactions), then **shopperStatement** is used.  Currently, `localizedShopperStatement` is only supported for payments with Visa, Mastercard, JCB, Diners, and Discover.  **Supported characters**: Hiragana, Katakana, Kanji, and alphanumeric.
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, count?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  --merchantOrderReference: string # You can use this reference to link multiple transactions to one another (for example, to track order authorization rate).For each billing cycle, this reference should be unique. After the first authorized payment attempt, do not reuse the reference. If you use this parameter, include it in all of the payment requests that you make.   We strongly recommend that you: * Always include this parameter, so that you can benefit from linking payment requests to one another, in case of authorization retries.  * Additionally include the following parameters in the `additionalData` object: [`retry.orderAttemptNumber`](https://docs.adyen.com/api-explorer/Checkout/latest/post/sessions#request-additionalData-AdditionalDataRetry-retry-orderAttemptNumber), [`retry.chainAttemptNumber`](https://docs.adyen.com/api-explorer/Checkout/latest/post/sessions#request-additionalData-AdditionalDataRetry-retry-chainAttemptNumber), and [`retry.skipRetry`](https://docs.adyen.com/api-explorer/Checkout/latest/post/sessions#request-additionalData-AdditionalDataRetry-retry-skipRetry)
  --merchantRiskIndicator: record # shape: {addressMatch?: bool, deliveryAddressIndicator?: "shipToBillingAddress"|"shipToVerifiedAddress"|"shipToNewAddress"|"shipToStore"|"digitalGoods"|"goodsNotShipped"|"other", deliveryEmail?: string, deliveryEmailAddress?: string, deliveryTimeframe?: "electronicDelivery"|"sameDayShipping"|"overnightShipping"|"twoOrMoreDaysShipping", giftCardAmount?: record, giftCardCount?: int, giftCardCurr?: string, preOrderDate?: string, preOrderPurchase?: bool, preOrderPurchaseInd?: string, reorderItems?: bool, reorderItemsInd?: string, shipIndicator?: string}
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. When exceeding, the "177" error occurs: "Metadata size exceeds limit". * Maximum 20 characters per key. * Maximum 80 characters per value. 
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --order: record # shape: {orderData: string, pspReference: string}
  --orderReference: string # When you are doing multiple partial (gift card) payments, this is the `pspReference` of the first payment. We use this to link the multiple payments to each other. As your own reference for linking multiple payments, use the `merchantOrderReference`instead.
  --origin: string # > Required for browser-based (`channel` **Web**) 3D Secure 2 transactions.Set this to the origin URL of the page where you are rendering the Drop-in/Component. Do not include subdirectories and a trailing slash.
  paymentMethod: any # The type and required details of a payment method to use.
  --paymentValidations: record # shape: {name?: record}
  --platformChargebackLogic: record # shape: {behavior?: "deductFromOneBalanceAccount"|"deductAccordingToSplitRatio"|"deductFromLiableAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurringExpiry: string # Date after which no further authorisations shall be performed. Only for 3D Secure 2.
  --recurringFrequency: string # Minimum number of days between authorisations. Only for 3D Secure 2.
  --recurringProcessingModel: string@recurringProcessingModel-completer # Defines a recurring payment type. Required when creating a token to store payment details or using stored payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --redirectFromIssuerMethod: string # Specifies the redirect method (GET or POST) when redirecting back from the issuer.
  --redirectToIssuerMethod: string # Specifies the redirect method (GET or POST) when redirecting to the issuer.
  reference: string # The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. To provide multiple references for one transaction, separate the reference values with the hyphen (`-`) character.We strongly recommend that you use a unique value for each transaction. Maximum length: 80 characters.
  returnUrl: string # The URL to return to in case of a redirection. The format depends on the channel.  * For web, include the protocol `http://` or `https://`. You can also include your own additional query parameters, for example, shopper ID or order reference number. Example: `https://your-company.example.com/checkout?shopperOrder=12xy` * For iOS, use the custom URL for your app. To know more about setting custom URL schemes, refer to the [Apple Developer documentation](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app). Example: `my-app://` * For Android, use a custom URL handled by an Activity on your app. You can configure it with an [intent filter](https://developer.android.com/guide/components/intents-filters). Example: `my-app://your.package.name`  If the URL to return to includes non-ASCII characters, like spaces or special letters, URL encode the value.  We strongly recommend that you use a maximum of 1024 characters.  > The URL must not include personally identifiable information (PII), for example name or email address.
  --riskData: record # shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
  --sessionValidity: string # The date and time until when the session remains valid, in [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format.  For example: 2020-07-18T15:42:40.428+01:00
  --shopperConversionId: string # A unique ID to [connect the shopper to a single checkout session](https://docs.adyen.com/online-payments/checkout-settings#checkout-shopper-conversion-id) that uses multiple API requests. You can use this to get insights into conversion rates.
  --shopperEmail: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks. > Required for Visa and JCB transactions that require 3D Secure 2 authentication if you did not include the `telephoneNumber`.
  --shopperIP: string # The shopper's IP address. We recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > Required for Visa and JCB transactions that require 3D Secure 2 authentication for all web and mobile integrations, if you did not include the `shopperEmail`. For native mobile integrations, the field is required to support cases where authentication is routed to the redirect flow. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopperInteraction: string@shopperInteraction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default.  This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopperLocale: string # The language for the payment. The value combines the two-letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) language code with the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) country code. For example, **nl-NL**.  When using Drop-in/Components, the specified language appears if your front-end global configuration does not set the `locale`.
  --shopperName: record # shape: {firstName: string, lastName: string}
  --shopperReference: string # Required for recurring payments.  Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --shopperStatement: string # The text to be shown on the shopper's bank statement.  We recommend sending a maximum of 22 characters, otherwise banks might truncate the string.  Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --shopperTaxInfo: record # shape: {taxCountryCode: string, taxIdentificationNumber: string}
  --socialSecurityNumber: string # The shopper's social security number.
  --splits: list # An array of objects specifying how to split a payment when using [Adyen for Platforms](https://docs.adyen.com/platforms/process-payments#providing-split-information), [Classic Platforms integration](https://docs.adyen.com/classic-platforms/processing-payments#providing-split-information), or [Issuing](https://docs.adyen.com/issuing/manage-funds#split). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --store: string # Required for Adyen for Platforms integrations if you are a platform model. This is your [reference](https://docs.adyen.com/api-explorer/Management/3/post/merchants/(merchantId)/stores#request-reference) (on [balance platform](https://docs.adyen.com/platforms)) or the [storeReference](https://docs.adyen.com/api-explorer/Account/latest/post/updateAccountHolder#request-accountHolderDetails-storeDetails-storeReference) (in the [classic integration](https://docs.adyen.com/classic-platforms/processing-payments/route-payment-to-store/#route-a-payment-to-a-store)) for the ecommerce or point-of-sale store that is processing the payment.
  --storePaymentMethod: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be stored for future [recurring payments](https://docs.adyen.com/online-payments/tokenization/#recurring-payment-types).
  --subMerchants: list # This field contains additional information on the submerchant, who is onboarded to an acquirer through a payment facilitator or aggregator — item shape: {address?: record, amount?: record, email?: string, id?: string, mcc?: string, name?: string, phoneNumber?: string, registeredSince?: string, taxId?: string, url?: string}
  --surcharge: record # shape: {value: int}
  --telephoneNumber: string # The shopper's telephone number.  The phone number must include a plus sign (+) and a country code (1-3 digits), followed by the number (4-15 digits). If the value you provide does not follow the guidelines, we do not submit it for authentication. > Required for Visa and JCB transactions that require 3D Secure 2 authentication, if you did not include the `shopperEmail`.
  --threeDS2RequestData: record # shape: {acctInfo?: record, acctType?: "01"|"02"|"03", acquirerBIN?: string, acquirerMerchantID?: string, addrMatch?: "Y"|"N", authenticationOnly?: bool, challengeIndicator?: "noPreference"|"requestNoChallenge"|"requestChallenge"|"requestChallengeAsMandate", deviceRenderOptions?: record, homePhone?: record, mcc?: string, merchantName?: string, messageVersion?: string, mobilePhone?: record, notificationURL?: string, payTokenInd?: bool, paymentAuthenticationUseCase?: string, purchaseInstalData?: string, recurringExpiry?: string, recurringFrequency?: string, sdkAppID?: string, sdkEphemPubKey?: record, sdkMaxTimeout?: int, sdkReferenceNumber?: string, sdkTransID?: string, threeDSCompInd?: string, threeDSRequestorAuthenticationInd?: string, threeDSRequestorAuthenticationInfo?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", threeDSRequestorID?: string, threeDSRequestorName?: string, threeDSRequestorPriorAuthenticationInfo?: record, threeDSRequestorURL?: string, transType?: "01"|"03"|"10"|"11"|"28", transactionType?: "goodsOrServicePurchase"|"checkAcceptance"|"accountFunding"|"quasiCashTransaction"|"prepaidActivationAndLoad", whiteListStatus?: string, workPhone?: record}
  --threeDSAuthenticationOnly: oneof<nothing, bool> # Required to trigger the [authentication-only flow](https://docs.adyen.com/online-payments/3d-secure/authentication-only/). If set to **true**, you will only perform the 3D Secure 2 authentication, and will not proceed to the payment authorisation.Default: **false**. (DEPRECATED, default: false)
  --trustedShopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> record<action: any, additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list<record>>, merchantReference: string, order: record<amount: record<currency: string, value: int>, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record<currency: string, value: int>>, paymentMethod: record<brand: string, type: string>, paymentValidations: record<name: record<rawResponse: record, result: record, status: string>>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSRequestorChallengeInd: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments")
  let body = {accountInfo: $accountInfo, additionalAmount: $additionalAmount, additionalData: $additionalData, amount: $amount, applicationInfo: $applicationInfo, authenticationData: $authenticationData, bankAccount: $bankAccount, billingAddress: $billingAddress, browserInfo: $browserInfo, captureDelayHours: $captureDelayHours, channel: $channel, checkoutAttemptId: $checkoutAttemptId, company: $company, conversionId: $conversionId, countryCode: $countryCode, dateOfBirth: $dateOfBirth, dccQuote: $dccQuote, deliverAt: $deliverAt, deliveryAddress: $deliveryAddress, deliveryDate: $deliveryDate, deviceFingerprint: $deviceFingerprint, enableOneClick: $enableOneClick, enablePayOut: $enablePayOut, enableRecurring: $enableRecurring, enhancedSchemeData: $enhancedSchemeData, entityType: $entityType, fraudOffset: $fraudOffset, fundOrigin: $fundOrigin, fundRecipient: $fundRecipient, industryUsage: $industryUsage, installments: $installments, lineItems: $lineItems, localizedShopperStatement: $localizedShopperStatement, mandate: $mandate, mcc: $mcc, merchantAccount: $merchantAccount, merchantOrderReference: $merchantOrderReference, merchantRiskIndicator: $merchantRiskIndicator, metadata: $metadata, mpiData: $mpiData, order: $order, orderReference: $orderReference, origin: $origin, paymentMethod: $paymentMethod, paymentValidations: $paymentValidations, platformChargebackLogic: $platformChargebackLogic, recurringExpiry: $recurringExpiry, recurringFrequency: $recurringFrequency, recurringProcessingModel: $recurringProcessingModel, redirectFromIssuerMethod: $redirectFromIssuerMethod, redirectToIssuerMethod: $redirectToIssuerMethod, reference: $reference, returnUrl: $returnUrl, riskData: $riskData, sessionValidity: $sessionValidity, shopperConversionId: $shopperConversionId, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperInteraction: $shopperInteraction, shopperLocale: $shopperLocale, shopperName: $shopperName, shopperReference: $shopperReference, shopperStatement: $shopperStatement, shopperTaxInfo: $shopperTaxInfo, socialSecurityNumber: $socialSecurityNumber, splits: $splits, store: $store, storePaymentMethod: $storePaymentMethod, subMerchants: $subMerchants, surcharge: $surcharge, telephoneNumber: $telephoneNumber, threeDS2RequestData: $threeDS2RequestData, threeDSAuthenticationOnly: $threeDSAuthenticationOnly, trustedShopper: $trustedShopper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit details for a payment
#
# POST /payments/details
# operationId: post-payments-details
# --authenticationData shape: {authenticationOnly?: bool}
# --details shape: {MD?: string, PaReq?: string, PaRes?: string, authorization_token?: string, billingToken?: string, cupsecureplus.smscode?: string, facilitatorAccessToken?: string, oneTimePasscode?: string, orderID?: string, payerID?: string, payload?: string, paymentID?: string, paymentStatus?: string, redirectResult?: string, resultCode?: string, returnUrlQueryString?: string, threeDSResult?: string, threeds2.challengeResult?: string, threeds2.fingerprint?: string, vaultToken?: string}
@deprecated --flag threeDSAuthenticationOnly
export def "payments-details post-payments-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --authenticationData: record # shape: {authenticationOnly?: bool}
  details: record # shape: {MD?: string, PaReq?: string, PaRes?: string, authorization_token?: string, billingToken?: string, cupsecureplus.smscode?: string, facilitatorAccessToken?: string, oneTimePasscode?: string, orderID?: string, payerID?: string, payload?: string, paymentID?: string, paymentStatus?: string, redirectResult?: string, resultCode?: string, returnUrlQueryString?: string, threeDSResult?: string, threeds2.challengeResult?: string, threeds2.fingerprint?: string, vaultToken?: string}
  --paymentData: string # Encoded payment data. For [authorizing a payment after using 3D Secure 2 Authentication-only](https://docs.adyen.com/online-payments/3d-secure/other-3ds-flows/authentication-only/#authorise-the-payment-with-adyen):  If you received `resultCode`: **AuthenticationNotRequired** in the `/payments` response, use the `threeDSPaymentData` from the same response.  If you received `resultCode`: **AuthenticationFinished** in the `/payments` response, use the `action.paymentData` from the same response.
  --threeDSAuthenticationOnly: oneof<nothing, bool> # Change the `authenticationOnly` indicator originally set in the `/payments` request. Only needs to be set if you want to modify the value set previously. (DEPRECATED)
]: any -> record<action: any, additionalData: record, amount: record<currency: string, value: int>, donationToken: string, fraudResult: record<accountScore: int, results: list<record>>, merchantReference: string, order: record<amount: record<currency: string, value: int>, expiresAt: string, orderData: string, pspReference: string, reference: string, remainingAmount: record<currency: string, value: int>>, paymentMethod: record<brand: string, type: string>, paymentValidations: record<name: record<rawResponse: record, result: record, status: string>>, pspReference: string, refusalReason: string, refusalReasonCode: string, resultCode: string, shopperLocale: string, threeDS2ResponseData: record<acsChallengeMandated: string, acsOperatorID: string, acsReferenceNumber: string, acsSignedContent: string, acsTransID: string, acsURL: string, authenticationType: string, cardHolderInfo: string, cavvAlgorithm: string, challengeIndicator: string, dsReferenceNumber: string, dsTransID: string, exemptionIndicator: string, messageVersion: string, riskScore: string, sdkEphemPubKey: string, threeDSServerTransID: string, transStatus: string, transStatusReason: string>, threeDS2Result: record<authenticationValue: string, cavvAlgorithm: string, challengeCancel: string, dsTransID: string, eci: string, exemptionIndicator: string, messageVersion: string, riskScore: string, threeDSRequestorChallengeInd: string, threeDSServerTransID: string, timestamp: string, transStatus: string, transStatusReason: string, whiteListStatus: string>, threeDSPaymentData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/details")
  let body = {authenticationData: $authenticationData, details: $details, paymentData: $paymentData, threeDSAuthenticationOnly: $threeDSAuthenticationOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an authorised amount
#
# POST /payments/{paymentPspReference}/amountUpdates
# operationId: post-payments-paymentPspReference-amountUpdates
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --enhancedSchemeData shape: {airline?: record, levelTwoThree?: record}
# --lineItems item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
export def "payments-amount-updates post-payments-paymentPspReference-amountUpdates" [
  paymentPspReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --enhancedSchemeData: record # shape: {airline?: record, levelTwoThree?: record}
  --industryUsage: string@industryUsage-completer # The reason for the amount update. Possible values:  * **delayedCharge**  * **noShow**  * **installment**
  --lineItems: list # Price and product information of the refunded items, required for [partial refunds](https://docs.adyen.com/online-payments/refund#refund-a-payment). > This field is required for partial refunds with 3x 4x Oney, Affirm, Afterpay, Atome, Clearpay, Klarna, Ratepay, Walley, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  merchantAccount: string # The merchant account that is used to process the payment.
  --reference: string # Your reference for the amount update request. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to process payments for [marketplaces](https://docs.adyen.com/marketplaces/process-payments) or [platforms](https://docs.adyen.com/platforms/process-payments). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
]: any -> record<amount: record<currency: string, value: int>, industryUsage: string, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, marketplaceSellerId: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($paymentPspReference)/amountUpdates")
  let body = {amount: $amount, applicationInfo: $applicationInfo, enhancedSchemeData: $enhancedSchemeData, industryUsage: $industryUsage, lineItems: $lineItems, merchantAccount: $merchantAccount, reference: $reference, splits: $splits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel an authorised payment
#
# POST /payments/{paymentPspReference}/cancels
# operationId: post-payments-paymentPspReference-cancels
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --enhancedSchemeData shape: {airline?: record, levelTwoThree?: record}
export def "payments-cancels post-payments-paymentPspReference-cancels" [
  paymentPspReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --enhancedSchemeData: record # shape: {airline?: record, levelTwoThree?: record}
  merchantAccount: string # The merchant account that is used to process the payment.
  --reference: string # Your reference for the cancel request. Maximum length: 80 characters.
]: any -> record<merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($paymentPspReference)/cancels")
  let body = {applicationInfo: $applicationInfo, enhancedSchemeData: $enhancedSchemeData, merchantAccount: $merchantAccount, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Capture an authorised payment
#
# POST /payments/{paymentPspReference}/captures
# operationId: post-payments-paymentPspReference-captures
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --enhancedSchemeData shape: {airline?: record, levelTwoThree?: record}
# --lineItems item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
# --platformChargebackLogic shape: {behavior?: "deductFromOneBalanceAccount"|"deductAccordingToSplitRatio"|"deductFromLiableAccount", costAllocationAccount?: string, targetAccount?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
# --subMerchants item shape: {address?: record, amount?: record, email?: string, id?: string, mcc?: string, name?: string, phoneNumber?: string, registeredSince?: string, taxId?: string, url?: string}
export def "payments-captures post-payments-paymentPspReference-captures" [
  paymentPspReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --enhancedSchemeData: record # shape: {airline?: record, levelTwoThree?: record}
  --lineItems: list # Price and product information of the refunded items, required for [partial refunds](https://docs.adyen.com/online-payments/refund#refund-a-payment). > This field is required for partial refunds with 3x 4x Oney, Affirm, Afterpay, Atome, Clearpay, Klarna, Ratepay, Walley, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  merchantAccount: string # The merchant account that is used to process the payment.
  --platformChargebackLogic: record # shape: {behavior?: "deductFromOneBalanceAccount"|"deductAccordingToSplitRatio"|"deductFromLiableAccount", costAllocationAccount?: string, targetAccount?: string}
  --reference: string # Your reference for the capture request. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to process payments for [marketplaces](https://docs.adyen.com/marketplaces/split-payments) or [platforms](https://docs.adyen.com/platforms/online-payments/split-payments/). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --subMerchants: list # A List of sub-merchants. — item shape: {address?: record, amount?: record, email?: string, id?: string, mcc?: string, name?: string, phoneNumber?: string, registeredSince?: string, taxId?: string, url?: string}
]: any -> record<amount: record<currency: string, value: int>, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, marketplaceSellerId: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, merchantAccount: string, paymentPspReference: string, platformChargebackLogic: record<behavior: string, costAllocationAccount: string, targetAccount: string>, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, subMerchants: table<address: record, amount: record, email: string, id: string, mcc: string, name: string, phoneNumber: string, registeredSince: string, taxId: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($paymentPspReference)/captures")
  let body = {amount: $amount, applicationInfo: $applicationInfo, enhancedSchemeData: $enhancedSchemeData, lineItems: $lineItems, merchantAccount: $merchantAccount, platformChargebackLogic: $platformChargebackLogic, reference: $reference, splits: $splits, subMerchants: $subMerchants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refund a captured payment
#
# POST /payments/{paymentPspReference}/refunds
# operationId: post-payments-paymentPspReference-refunds
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --enhancedSchemeData shape: {airline?: record, levelTwoThree?: record}
# --lineItems item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
export def "payments-refunds post-payments-paymentPspReference-refunds" [
  paymentPspReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --capturePspReference: string # This is only available for PayPal refunds. The [`pspReference`](https://docs.adyen.com/api-explorer/Checkout/latest/post/payments#responses-200-pspReference) of the specific capture to refund.
  --enhancedSchemeData: record # shape: {airline?: record, levelTwoThree?: record}
  --lineItems: list # Price and product information of the refunded items, required for [partial refunds](https://docs.adyen.com/online-payments/refund#refund-a-payment). > This field is required for partial refunds with 3x 4x Oney, Affirm, Afterpay, Atome, Clearpay, Klarna, Ratepay, Walley, and Zip. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  merchantAccount: string # The merchant account that is used to process the payment.
  --merchantRefundReason: string@merchantRefundReason-completer # The reason for the refund request.  Possible values:  * **FRAUD**  * **CUSTOMER REQUEST**  * **RETURN**  * **DUPLICATE**  * **OTHER**   (nullable)
  --reference: string # Your reference for the refund request. Maximum length: 80 characters.
  --splits: list # An array of objects specifying how the amount should be split between accounts when using Adyen for Platforms. For more information, see how to process payments for [marketplaces](https://docs.adyen.com/marketplaces/split-payments) or [platforms](https://docs.adyen.com/platforms/online-payments/split-payments/). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --store: string # The online store or [physical store](https://docs.adyen.com/point-of-sale/design-your-integration/determine-account-structure/#create-stores) that is processing the refund. This must be the same as the store name configured in your Customer Area.  Otherwise, you get an error and the refund fails.
]: any -> record<amount: record<currency: string, value: int>, capturePspReference: string, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, marketplaceSellerId: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, merchantAccount: string, merchantRefundReason: string, paymentPspReference: string, pspReference: string, reference: string, splits: table<account: string, amount: record, description: string, reference: string, type: string>, status: string, store: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($paymentPspReference)/refunds")
  let body = {amount: $amount, applicationInfo: $applicationInfo, capturePspReference: $capturePspReference, enhancedSchemeData: $enhancedSchemeData, lineItems: $lineItems, merchantAccount: $merchantAccount, merchantRefundReason: $merchantRefundReason, reference: $reference, splits: $splits, store: $store} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refund or cancel a payment
#
# POST /payments/{paymentPspReference}/reversals
# operationId: post-payments-paymentPspReference-reversals
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --enhancedSchemeData shape: {airline?: record, levelTwoThree?: record}
export def "payments-reversals post-payments-paymentPspReference-reversals" [
  paymentPspReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --enhancedSchemeData: record # shape: {airline?: record, levelTwoThree?: record}
  merchantAccount: string # The merchant account that is used to process the payment.
  --reference: string # Your reference for the reversal request. Maximum length: 80 characters.
]: any -> record<merchantAccount: string, paymentPspReference: string, pspReference: string, reference: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($paymentPspReference)/reversals")
  let body = {applicationInfo: $applicationInfo, enhancedSchemeData: $enhancedSchemeData, merchantAccount: $merchantAccount, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the order for PayPal Express Checkout
#
# POST /paypal/updateOrder
# operationId: post-paypal-updateOrder
# --amount shape: {currency: string, value: int}
# --deliveryMethods item shape: {amount?: record, description?: string, reference?: string, selected?: bool, type?: "Shipping"}
# --taxTotal shape: {amount?: record}
export def "paypal-update-order post-paypal-updateOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --amount: record # shape: {currency: string, value: int}
  --deliveryMethods: list # The list of new delivery methods and the cost of each. — item shape: {amount?: record, description?: string, reference?: string, selected?: bool, type?: "Shipping"}
  --paymentData: string # The `paymentData` from the client side. This value changes every time you make a `/paypal/updateOrder` request.
  --pspReference: string # The original `pspReference` from the `/payments` response.
  --sessionId: string # The original `sessionId` from the `/sessions` response.
  --taxTotal: record # shape: {amount?: record}
]: any -> record<paymentData: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paypal/updateOrder")
  let body = {amount: $amount, deliveryMethods: $deliveryMethods, paymentData: $paymentData, pspReference: $pspReference, sessionId: $sessionId, taxTotal: $taxTotal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a payment session
#
# POST /sessions
# operationId: post-sessions
# --accountInfo shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
# --additionalAmount shape: {currency: string, value: int}
# --amount shape: {currency: string, value: int}
# --applicationInfo shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
# --authenticationData shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
# --billingAddress shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
# --company shape: {homepage?: string, name?: string, registrationNumber?: string, registryLocation?: string, taxId?: string, type?: string}
# --deliveryAddress shape: {city: string, country: string, firstName?: string, houseNumberOrName: string, lastName?: string, postalCode: string, stateOrProvince?: string, street: string}
# --fundOrigin shape: {billingAddress?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string, walletIdentifier?: string}
# --fundRecipient shape: {IBAN?: string, billingAddress?: record, paymentMethod?: record, shopperEmail?: string, shopperName?: record, shopperReference?: string, storedPaymentMethodId?: string, subMerchant?: record, telephoneNumber?: string, walletIdentifier?: string, walletOwnerTaxId?: string, walletPurpose?: "identifiedBoleto"|"transferDifferentWallet"|"transferOwnWallet"|"transferSameWallet"|"unidentifiedBoleto"}
# --lineItems item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
# --mandate shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, count?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
# --mpiData shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
# --platformChargebackLogic shape: {behavior?: "deductFromOneBalanceAccount"|"deductAccordingToSplitRatio"|"deductFromLiableAccount", costAllocationAccount?: string, targetAccount?: string}
# --riskData shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
# --shopperName shape: {firstName: string, lastName: string}
# --splits item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
# --threeDS2RequestData shape: {homePhone?: record, mobilePhone?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", workPhone?: record}
@deprecated --flag threeDSAuthenticationOnly
export def "sessions post-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  --accountInfo: record # shape: {accountAgeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountChangeDate?: string, accountChangeIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", accountCreationDate?: string, accountType?: "notApplicable"|"credit"|"debit", addCardAttemptsDay?: int, deliveryAddressUsageDate?: string, deliveryAddressUsageIndicator?: "thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", homePhone?: string, mobilePhone?: string, passwordChangeDate?: string, passwordChangeIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", pastTransactionsDay?: int, pastTransactionsYear?: int, paymentAccountAge?: string, paymentAccountIndicator?: "notApplicable"|"thisTransaction"|"lessThan30Days"|"from30To60Days"|"moreThan60Days", purchasesLast6Months?: int, suspiciousActivity?: bool, workPhone?: string}
  --additionalAmount: record # shape: {currency: string, value: int}
  --additionalData: record # This field contains additional data, which may be required for a particular payment request.  The `additionalData` object consists of entries, each of which includes the key and value.
  --allowedPaymentMethods: list # List of payment methods to be presented to the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types).  Example: `"allowedPaymentMethods":["ideal","applepay"]`
  amount: record # shape: {currency: string, value: int}
  --applicationInfo: record # shape: {adyenLibrary?: record, adyenPaymentSource?: record, externalPlatform?: record, merchantApplication?: record, merchantDevice?: record, shopperInteractionDevice?: record}
  --authenticationData: record # shape: {attemptAuthentication?: "always"|"never", authenticationOnly?: bool, threeDSRequestData?: record}
  --billingAddress: record # shape: {city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince?: string, street: string}
  --blockedPaymentMethods: list # List of payment methods to be hidden from the shopper. To refer to payment methods, use their [payment method type](https://docs.adyen.com/payment-methods/payment-method-types).  Example: `"blockedPaymentMethods":["ideal","applepay"]`
  --captureDelayHours: int # The delay between the authorisation and scheduled auto-capture, specified in hours. (format: int32)
  --channel: string@channel-completer # The platform where a payment transaction takes place. This field is optional for filtering out payment methods that are only available on specific platforms. If this value is not set, then we will try to infer it from the `sdkVersion` or `token`.  Possible values: * **iOS** * **Android** * **Web**
  --company: record # shape: {homepage?: string, name?: string, registrationNumber?: string, registryLocation?: string, taxId?: string, type?: string}
  --countryCode: string # The shopper's two-letter country code.
  --dateOfBirth: string # The shopper's date of birth.  Format [ISO-8601](https://www.w3.org/TR/NOTE-datetime): YYYY-MM-DD (format: date)
  --deliverAt: string # The date and time when the purchased goods should be delivered.  [ISO 8601](https://www.w3.org/TR/NOTE-datetime) format: YYYY-MM-DDThh:mm:ss+TZD, for example, **2020-12-18T10:15:30+01:00**. (format: date-time)
  --deliveryAddress: record # shape: {city: string, country: string, firstName?: string, houseNumberOrName: string, lastName?: string, postalCode: string, stateOrProvince?: string, street: string}
  --enableOneClick: oneof<nothing, bool> # When true and `shopperReference` is provided, the shopper will be asked if the payment details should be stored for future [one-click payments](https://docs.adyen.com/get-started-with-adyen/payment-glossary/#one-click-payments-definition).
  --enablePayOut: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be tokenized for payouts.
  --enableRecurring: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be stored for [recurring payments](https://docs.adyen.com/online-payments/tokenization/#recurring-payment-types) where the shopper is not present, such as subscription or automatic top-up payments.
  --expiresAt: string # The date the session expires in [ISO8601](https://www.iso.org/iso-8601-date-and-time-format.html) format. When not specified, the expiry date is set to 1 hour after session creation. You cannot set the session expiry to more than 24 hours after session creation. (format: date-time)
  --fundOrigin: record # shape: {billingAddress?: record, shopperEmail?: string, shopperName?: record, telephoneNumber?: string, walletIdentifier?: string}
  --fundRecipient: record # shape: {IBAN?: string, billingAddress?: record, paymentMethod?: record, shopperEmail?: string, shopperName?: record, shopperReference?: string, storedPaymentMethodId?: string, subMerchant?: record, telephoneNumber?: string, walletIdentifier?: string, walletOwnerTaxId?: string, walletPurpose?: "identifiedBoleto"|"transferDifferentWallet"|"transferOwnWallet"|"transferSameWallet"|"unidentifiedBoleto"}
  --installmentOptions: record # A set of key-value pairs that specifies the installment options available per payment method. The key must be a payment method name in lowercase. For example, **card** to specify installment options for all cards, or **visa** or **mc**. The value must be an object containing the installment options.
  --lineItems: list # Price and product information about the purchased items, to be included on the invoice sent to the shopper. > This field is required for 3x 4x Oney, Affirm, Afterpay, Clearpay, Klarna, Ratepay, and Riverty. — item shape: {amountExcludingTax?: int, amountIncludingTax?: int, brand?: string, color?: string, description?: string, id?: string, imageUrl?: string, itemCategory?: string, manufacturer?: string, marketplaceSellerId?: string, productUrl?: string, quantity?: int, receiverEmail?: string, size?: string, sku?: string, taxAmount?: int, taxPercentage?: int, upc?: string}
  --mandate: record # shape: {amount: string, amountRule?: "max"|"exact", billingAttemptsRule?: "on"|"before"|"after", billingDay?: string, count?: string, endsAt: string, frequency: "adhoc"|"daily"|"weekly"|"biWeekly"|"monthly"|"quarterly"|"halfYearly"|"yearly", remarks?: string, startsAt?: string}
  --mcc: string # The [merchant category code](https://en.wikipedia.org/wiki/Merchant_category_code) (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  --merchantOrderReference: string # This reference allows linking multiple transactions to each other for reporting purposes (i.e. order auth-rate). The reference should be unique per billing cycle. The same merchant order reference should never be reused after the first authorised attempt. If used, this field should be supplied for all incoming authorisations. > We strongly recommend you send the `merchantOrderReference` value to benefit from linking payment requests when authorisation retries take place. In addition, we recommend you provide `retry.orderAttemptNumber`, `retry.chainAttemptNumber`, and `retry.skipRetry` values in `PaymentRequest.additionalData`.
  --metadata: record # Metadata consists of entries, each of which includes a key and a value. Limits: * Maximum 20 key-value pairs per request. * Maximum 20 characters per key. * Maximum 80 characters per value. 
  --mode: string@mode-completer # Indicates the type of front end integration. Possible values: * **embedded** (default): Drop-in or Components integration * **hosted**: Hosted Checkout integration (default: embedded)
  --mpiData: record # shape: {authenticationResponse?: "Y"|"N"|"U"|"A", cavv?: string, cavvAlgorithm?: string, challengeCancel?: "01"|"02"|"03"|"04"|"05"|"06"|"07", directoryResponse?: "A"|"C"|"D"|"I"|"N"|"R"|"U"|"Y", dsTransID?: string, eci?: string, riskScore?: string, threeDSVersion?: string, tokenAuthenticationVerificationValue?: string, transStatusReason?: string, xid?: string}
  --platformChargebackLogic: record # shape: {behavior?: "deductFromOneBalanceAccount"|"deductAccordingToSplitRatio"|"deductFromLiableAccount", costAllocationAccount?: string, targetAccount?: string}
  --recurringExpiry: string # Date after which no further authorisations shall be performed. Only for 3D Secure 2.
  --recurringFrequency: string # Minimum number of days between authorisations. Only for 3D Secure 2.
  --recurringProcessingModel: string@recurringProcessingModel-completer # Defines a recurring payment type. Required when creating a token to store payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --redirectFromIssuerMethod: string # Specifies the redirect method (GET or POST) when redirecting back from the issuer.
  --redirectToIssuerMethod: string # Specifies the redirect method (GET or POST) when redirecting to the issuer.
  reference: string # The reference to uniquely identify a payment.
  returnUrl: string # The URL to return to in case of a redirection. The format depends on the channel.  * For web, include the protocol `http://` or `https://`. You can also include your own additional query parameters, for example, shopper ID or order reference number. Example: `https://your-company.example.com/checkout?shopperOrder=12xy` * For iOS, use the custom URL for your app. To know more about setting custom URL schemes, refer to the [Apple Developer documentation](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app). Example: `my-app://` * For Android, use a custom URL handled by an Activity on your app. You can configure it with an [intent filter](https://developer.android.com/guide/components/intents-filters). Example: `my-app://your.package.name`  If the URL to return to includes non-ASCII characters, like spaces or special letters, URL encode the value.  We strongly recommend that you use a maximum of 1024 characters.  > The URL must not include personally identifiable information (PII), for example name or email address.
  --riskData: record # shape: {clientData?: string, customFields?: record, fraudOffset?: int, profileReference?: string}
  --shopperEmail: string # The shopper's email address.
  --shopperIP: string # The shopper's IP address. We recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks). > Required for Visa and JCB transactions that require 3D Secure 2 authentication for all web and mobile integrations, if you did not include the `shopperEmail`. For native mobile integrations, the field is required to support cases where authentication is routed to the redirect flow. This field is also mandatory for some merchants depending on your business model. For more information, [contact Support](https://www.adyen.help/hc/en-us/requests/new).
  --shopperInteraction: string@shopperInteraction-completer # Specifies the sales channel, through which the shopper gives their card details, and whether the shopper is a returning customer. For the web service API, Adyen assumes Ecommerce shopper interaction by default.  This field has the following possible values: * `Ecommerce` - Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request. * `ContAuth` - Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment). * `Moto` - Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone. * `POS` - Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  --shopperLocale: string # The language for the payment. The value combines the two-letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) language code with the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) country code. For example, **nl-NL**.  When using Drop-in/Components, the specified language appears if your front-end global configuration does not set the `locale`.
  --shopperName: record # shape: {firstName: string, lastName: string}
  --shopperReference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. The value is case-sensitive and must be at least three characters. > Your reference must not include personally identifiable information (PII) such as name or email address.
  --shopperStatement: string # The text to be shown on the shopper's bank statement.  We recommend sending a maximum of 22 characters, otherwise banks might truncate the string.  Allowed characters: **a-z**, **A-Z**, **0-9**, spaces, and special characters **. , ' _ - ? + * /**.
  --showInstallmentAmount: oneof<nothing, bool> # Set to true to show the payment amount per installment.
  --showRemovePaymentMethodButton: oneof<nothing, bool> # Set to **true** to show a button that lets the shopper remove a stored payment method.
  --socialSecurityNumber: string # The shopper's social security number.
  --splitCardFundingSources: oneof<nothing, bool> # Boolean value indicating whether the card payment method should be split into separate debit and credit options. (default: false)
  --splits: list # An array of objects specifying how to split a payment when using [Adyen for Platforms](https://docs.adyen.com/platforms/process-payments#providing-split-information), [Classic Platforms integration](https://docs.adyen.com/classic-platforms/processing-payments#providing-split-information), or [Issuing](https://docs.adyen.com/issuing/manage-funds#split). — item shape: {account?: string, amount?: record, description?: string, reference?: string, type: "AcquiringFees"|"AdyenCommission"|"AdyenFees"|"AdyenMarkup"|"BalanceAccount"|"Commission"|"Default"|"Interchange"|"MarketPlace"|"PaymentFee"|"Remainder"|"SchemeFee"|"Surcharge"|"Tip"|"TopUp"|"VAT"}
  --store: string # Required for Adyen for Platforms integrations if you are a platform model. This is your [reference](https://docs.adyen.com/api-explorer/Management/3/post/merchants/(merchantId)/stores#request-reference) (on [balance platform](https://docs.adyen.com/platforms)) or the [storeReference](https://docs.adyen.com/api-explorer/Account/latest/post/updateAccountHolder#request-accountHolderDetails-storeDetails-storeReference) (in the [classic integration](https://docs.adyen.com/classic-platforms/processing-payments/route-payment-to-store/#route-a-payment-to-a-store)) for the ecommerce or point-of-sale store that is processing the payment.
  --storeFiltrationMode: string@storeFiltrationMode-completer # Specifies how payment methods should be filtered based on the 'store' parameter:   - 'exclusive': Only payment methods belonging to the specified 'store' are returned.   - 'inclusive': Payment methods from the 'store' and those not associated with any other store are returned.
  --storePaymentMethod: oneof<nothing, bool> # When true and `shopperReference` is provided, the payment details will be stored for future [recurring payments](https://docs.adyen.com/online-payments/tokenization/#recurring-payment-types).
  --storePaymentMethodMode: string@storePaymentMethodMode-completer # Indicates if the details of the payment method will be stored for the shopper. Possible values: * **disabled** – No details will be stored (default). * **askForConsent** – If the `shopperReference` is provided, the Drop-in/Component shows a checkbox where the shopper can select to store their payment details for card payments. * **enabled** – If the `shopperReference` is provided, the details will be stored without asking the shopper for consent.
  --telephoneNumber: string # The shopper's telephone number.  The phone number must include a plus sign (+) and a country code (1-3 digits), followed by the number (4-15 digits). If the value you provide does not follow the guidelines, we do not submit it for authentication. > Required for Visa and JCB transactions that require 3D Secure 2 authentication, if you did not include the `shopperEmail`.
  --themeId: string # Sets a custom theme for [Hosted Checkout](https://docs.adyen.com/online-payments/build-your-integration/?platform=Web&integration=Hosted+Checkout). The value can be any of the **Theme ID** values from your Customer Area.
  --threeDS2RequestData: record # shape: {homePhone?: record, mobilePhone?: record, threeDSRequestorChallengeInd?: "01"|"02"|"03"|"04"|"05"|"06", workPhone?: record}
  --threeDSAuthenticationOnly: oneof<nothing, bool> # Required to trigger the [authentication-only flow](https://docs.adyen.com/online-payments/3d-secure/authentication-only/). If set to **true**, you will only perform the 3D Secure 2 authentication, and will not proceed to the payment authorization.Default: **false**. (DEPRECATED, default: false)
  --trustedShopper: oneof<nothing, bool> # Set to true if the payment should be routed to a trusted MID.
]: any -> record<accountInfo: record<accountAgeIndicator: string, accountChangeDate: string, accountChangeIndicator: string, accountCreationDate: string, accountType: string, addCardAttemptsDay: int, deliveryAddressUsageDate: string, deliveryAddressUsageIndicator: string, homePhone: string, mobilePhone: string, passwordChangeDate: string, passwordChangeIndicator: string, pastTransactionsDay: int, pastTransactionsYear: int, paymentAccountAge: string, paymentAccountIndicator: string, purchasesLast6Months: int, suspiciousActivity: bool, workPhone: string>, additionalAmount: record<currency: string, value: int>, additionalData: record, allowedPaymentMethods: list<string>, amount: record<currency: string, value: int>, applicationInfo: record<adyenLibrary: record<name: string, version: string>, adyenPaymentSource: record<name: string, version: string>, externalPlatform: record<integrator: string, name: string, version: string>, merchantApplication: record<name: string, version: string>, merchantDevice: record<os: string, osVersion: string, reference: string>, shopperInteractionDevice: record<locale: string, os: string, osVersion: string>>, authenticationData: record<attemptAuthentication: string, authenticationOnly: bool, threeDSRequestData: record<challengeWindowSize: string, dataOnly: string, nativeThreeDS: string, threeDSVersion: string>>, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, blockedPaymentMethods: list<string>, captureDelayHours: int, channel: string, company: record<homepage: string, name: string, registrationNumber: string, registryLocation: string, taxId: string, type: string>, countryCode: string, dateOfBirth: string, deliverAt: string, deliveryAddress: record<city: string, country: string, firstName: string, houseNumberOrName: string, lastName: string, postalCode: string, stateOrProvince: string, street: string>, enableOneClick: bool, enablePayOut: bool, enableRecurring: bool, expiresAt: string, fundOrigin: record<billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, telephoneNumber: string, walletIdentifier: string>, fundRecipient: record<IBAN: string, billingAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, paymentMethod: record<billingSequenceNumber: string, brand: string, checkoutAttemptId: string, cupsecureplus_smscode: string, cvc: string, encryptedCard: string, encryptedCardNumber: string, encryptedExpiryMonth: string, encryptedExpiryYear: string, encryptedPassword: string, encryptedSecurityCode: string, expiryMonth: string, expiryYear: string, fastlaneData: string, fundingSource: string, holderName: string, networkPaymentReference: string, number: string, recurringDetailReference: string, sdkData: string, shopperNotificationReference: string, srcCorrelationId: string, srcDigitalCardId: string, srcScheme: string, srcTokenReference: string, storedPaymentMethodId: string, threeDS2SdkVersion: string, type: string>, shopperEmail: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, storedPaymentMethodId: string, subMerchant: record<city: string, country: string, mcc: string, name: string, taxId: string>, telephoneNumber: string, walletIdentifier: string, walletOwnerTaxId: string, walletPurpose: string>, id: string, installmentOptions: record, lineItems: table<amountExcludingTax: int, amountIncludingTax: int, brand: string, color: string, description: string, id: string, imageUrl: string, itemCategory: string, manufacturer: string, marketplaceSellerId: string, productUrl: string, quantity: int, receiverEmail: string, size: string, sku: string, taxAmount: int, taxPercentage: int, upc: string>, mandate: record<amount: string, amountRule: string, billingAttemptsRule: string, billingDay: string, count: string, endsAt: string, frequency: string, remarks: string, startsAt: string>, mcc: string, merchantAccount: string, merchantOrderReference: string, metadata: record, mode: string, mpiData: record<authenticationResponse: string, cavv: string, cavvAlgorithm: string, challengeCancel: string, directoryResponse: string, dsTransID: string, eci: string, riskScore: string, threeDSVersion: string, tokenAuthenticationVerificationValue: string, transStatusReason: string, xid: string>, platformChargebackLogic: record<behavior: string, costAllocationAccount: string, targetAccount: string>, recurringExpiry: string, recurringFrequency: string, recurringProcessingModel: string, redirectFromIssuerMethod: string, redirectToIssuerMethod: string, reference: string, returnUrl: string, riskData: record<clientData: string, customFields: record, fraudOffset: int, profileReference: string>, sessionData: string, shopperEmail: string, shopperIP: string, shopperInteraction: string, shopperLocale: string, shopperName: record<firstName: string, lastName: string>, shopperReference: string, shopperStatement: string, showInstallmentAmount: bool, showRemovePaymentMethodButton: bool, socialSecurityNumber: string, splitCardFundingSources: bool, splits: table<account: string, amount: record, description: string, reference: string, type: string>, store: string, storeFiltrationMode: string, storePaymentMethod: bool, storePaymentMethodMode: string, telephoneNumber: string, themeId: string, threeDS2RequestData: record<homePhone: record<cc: string, subscriber: string>, mobilePhone: record<cc: string, subscriber: string>, threeDSRequestorChallengeInd: string, workPhone: record<cc: string, subscriber: string>>, threeDSAuthenticationOnly: bool, trustedShopper: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sessions")
  let body = {accountInfo: $accountInfo, additionalAmount: $additionalAmount, additionalData: $additionalData, allowedPaymentMethods: $allowedPaymentMethods, amount: $amount, applicationInfo: $applicationInfo, authenticationData: $authenticationData, billingAddress: $billingAddress, blockedPaymentMethods: $blockedPaymentMethods, captureDelayHours: $captureDelayHours, channel: $channel, company: $company, countryCode: $countryCode, dateOfBirth: $dateOfBirth, deliverAt: $deliverAt, deliveryAddress: $deliveryAddress, enableOneClick: $enableOneClick, enablePayOut: $enablePayOut, enableRecurring: $enableRecurring, expiresAt: $expiresAt, fundOrigin: $fundOrigin, fundRecipient: $fundRecipient, installmentOptions: $installmentOptions, lineItems: $lineItems, mandate: $mandate, mcc: $mcc, merchantAccount: $merchantAccount, merchantOrderReference: $merchantOrderReference, metadata: $metadata, mode: $mode, mpiData: $mpiData, platformChargebackLogic: $platformChargebackLogic, recurringExpiry: $recurringExpiry, recurringFrequency: $recurringFrequency, recurringProcessingModel: $recurringProcessingModel, redirectFromIssuerMethod: $redirectFromIssuerMethod, redirectToIssuerMethod: $redirectToIssuerMethod, reference: $reference, returnUrl: $returnUrl, riskData: $riskData, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperInteraction: $shopperInteraction, shopperLocale: $shopperLocale, shopperName: $shopperName, shopperReference: $shopperReference, shopperStatement: $shopperStatement, showInstallmentAmount: $showInstallmentAmount, showRemovePaymentMethodButton: $showRemovePaymentMethodButton, socialSecurityNumber: $socialSecurityNumber, splitCardFundingSources: $splitCardFundingSources, splits: $splits, store: $store, storeFiltrationMode: $storeFiltrationMode, storePaymentMethod: $storePaymentMethod, storePaymentMethodMode: $storePaymentMethodMode, telephoneNumber: $telephoneNumber, themeId: $themeId, threeDS2RequestData: $threeDS2RequestData, threeDSAuthenticationOnly: $threeDSAuthenticationOnly, trustedShopper: $trustedShopper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the result of a payment session
#
# GET /sessions/{sessionId}
# operationId: get-sessions-sessionId
export def "sessions get-sessions-sessionId" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sessionResult: string # The `sessionResult` value from the Drop-in or Component.
]: nothing -> record<additionalData: record, id: string, payments: table<amount: record, paymentMethod: record, pspReference: string, resultCode: string>, reference: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sessionResult" $sessionResult "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sessions/($sessionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tokens for stored payment details
#
# GET /storedPaymentMethods
# operationId: get-storedPaymentMethods
export def "stored-payment-methods get-storedPaymentMethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shopperReference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --merchantAccount: string # Your merchant account.
]: nothing -> record<merchantAccount: string, shopperReference: string, storedPaymentMethods: table<alias: string, aliasType: string, brand: string, cardBin: string, expiryMonth: string, expiryYear: string, externalResponseCode: string, externalTokenReference: string, holderName: string, iban: string, id: string, issuerName: string, lastFour: string, mandate: record, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, shopperReference: string, supportedRecurringProcessingModels: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shopperReference" $shopperReference "scalar") (serialize-qp "merchantAccount" $merchantAccount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storedPaymentMethods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a token to store payment details
#
# POST /storedPaymentMethods
# operationId: post-storedPaymentMethods
# --paymentMethod shape: {brand?: string, cvc?: string, encryptedCard?: string, encryptedCardNumber?: string, encryptedExpiryMonth?: string, encryptedExpiryYear?: string, encryptedSecurityCode?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, number?: string, type?: string}
export def "stored-payment-methods post-storedPaymentMethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique identifier for the message with a maximum of 64 characters (we recommend a UUID). (e.g. 37ca9c97-d1d1-4c62-89e8-706891a563ed)
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  paymentMethod: record # shape: {brand?: string, cvc?: string, encryptedCard?: string, encryptedCardNumber?: string, encryptedExpiryMonth?: string, encryptedExpiryYear?: string, encryptedSecurityCode?: string, expiryMonth?: string, expiryYear?: string, holderName?: string, number?: string, type?: string}
  recurringProcessingModel: string@recurringProcessingModel-completer # Defines a recurring payment type. Required when creating a token to store payment details. Allowed values: * `Subscription` – A transaction for a fixed or variable amount, which follows a fixed schedule. * `CardOnFile` – With a card-on-file (CoF) transaction, card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction. * `UnscheduledCardOnFile` – An unscheduled card-on-file (UCoF) transaction is a transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  --shopperEmail: string # The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks.
  --shopperIP: string # The IP address of a shopper.
  shopperReference: string # A unique identifier for the shopper (for example, user ID or account ID).
]: any -> record<alias: string, aliasType: string, brand: string, cardBin: string, expiryMonth: string, expiryYear: string, externalResponseCode: string, externalTokenReference: string, holderName: string, iban: string, id: string, issuerName: string, lastFour: string, mandate: record<accountIdType: string, amount: string, amountRule: string, billingAttemptsRule: string, billingDay: string, count: string, currency: string, endsAt: string, frequency: string, mandateId: string, maskedAccountId: string, minAmount: string, providerId: string, recurringAmount: string, recurringStatement: string, remarks: string, retryPolicy: string, startsAt: string, status: string, txVariant: string>, name: string, networkTxReference: string, ownerName: string, shopperEmail: string, shopperReference: string, supportedRecurringProcessingModels: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storedPaymentMethods")
  let body = {merchantAccount: $merchantAccount, paymentMethod: $paymentMethod, recurringProcessingModel: $recurringProcessingModel, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperReference: $shopperReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a token for stored payment details
#
# DELETE /storedPaymentMethods/{storedPaymentMethodId}
# operationId: delete-storedPaymentMethods-storedPaymentMethodId
export def "stored-payment-methods delete-storedPaymentMethods-storedPaymentMethodId" [
  storedPaymentMethodId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shopperReference: string # Your reference to uniquely identify this shopper, for example user ID or account ID. Minimum length: 3 characters. > Your reference must not include personally identifiable information (PII), for example name or email address.
  --merchantAccount: string # Your merchant account.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shopperReference" $shopperReference "scalar") (serialize-qp "merchantAccount" $merchantAccount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storedPaymentMethods/($storedPaymentMethodId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validates shopper Id
#
# POST /validateShopperId
# operationId: post-validateShopperId
# --paymentMethod shape: {type: "payTo"|"upi_collect"}
export def "validate-shopper-id post-validateShopperId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  merchantAccount: string # The merchant account identifier, with which you want to process the transaction.
  paymentMethod: record # shape: {type: "payTo"|"upi_collect"}
  --shopperEmail: string
  --shopperIP: string
  --shopperReference: string
]: any -> record<reason: string, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/validateShopperId")
  let body = {merchantAccount: $merchantAccount, paymentMethod: $paymentMethod, shopperEmail: $shopperEmail, shopperIP: $shopperIP, shopperReference: $shopperReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
