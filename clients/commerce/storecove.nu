# Auto-generated client for Storecove API v2.0.1
# Source: https://api.apis.guru/v2/specs/storecove.com/2.0.1/openapi.json
# Auth: --token flag or $env.STORECOVE_API_TOKEN

const BASE_URL = "https://api.storecove.com/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STORECOVE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.storecove.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def mode-completer [] { ["direct"] }
def country-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XI" "YE" "YT" "ZA" "ZM" "ZW"] }
def package-version-completer [] { ["aunz" "peppol_bis_v3" "sg"] }
def packaging-completer [] { ["ubl"] }
def parseStrategy-completer [] { ["rfc822"] }
def syntax-completer [] { ["json" "original"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "discovery-exists exists" } } | get name | first)
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

# Discover Network Participant Existence
#
# POST /discovery/exists
# operationId: discovery_exists
export def "discovery-exists exists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentTypes: list # An array of document types to discover. The default is '["invoice", "creditnote"]'. This is ignored when only checking existence.
  identifier: string # The actual identifier.
  --metaScheme: string # The meta scheme of the identifier. For Peppol this is always 'iso6523-actorid-upis'. (default: iso6523-actorid-upis)
  --network: string # The network to check. Currently only 'peppol' is supported. (default: peppol)
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
]: any -> record<code: string, email: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/discovery/exists")
  let body = {documentTypes: $documentTypes, identifier: $identifier, metaScheme: $metaScheme, network: $network, scheme: $scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Discover Country Identifiers ** EXPERIMENTAL
#
# GET /discovery/identifiers
# operationId: discovery_identifiers
export def "discovery-identifiers identifiers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<country: string, receiver: record, region: string, sender: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/discovery/identifiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disover Network Participant
#
# POST /discovery/receives
# operationId: discovery_receives
export def "discovery-receives receives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentTypes: list # An array of document types to discover. The default is '["invoice", "creditnote"]'. This is ignored when only checking existence.
  identifier: string # The actual identifier.
  --metaScheme: string # The meta scheme of the identifier. For Peppol this is always 'iso6523-actorid-upis'. (default: iso6523-actorid-upis)
  --network: string # The network to check. Currently only 'peppol' is supported. (default: peppol)
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
]: any -> record<code: string, email: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/discovery/receives")
  let body = {documentTypes: $documentTypes, identifier: $identifier, metaScheme: $metaScheme, network: $network, scheme: $scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit a new document.
#
# POST /document_submissions
# operationId: create_document_submission
# --attachments item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
# --document shape: {documentType: "invoice"|"invoice_response"|"order", invoice?: record, invoiceResponse?: record, order?: record, rawDocumentData?: record}
# --routing shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list}
export def "document-submissions submission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # DEPRECATED. Use the attachments array inside the 'document' property. An array of attachments. You may provide up to 10 attchments, but the total size must not exceed 10MB after Base64 encoding. — item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
  --createPrimaryImage: oneof<nothing, bool> # DEPRECATED. In the future we will no longer support creating PDF invoices. Whether or not to create a primary image (PDF) if one is not provided. For customers who started from December 1st 2022, the default is false. For customers who started before that, the default is true.
  --document: record # The document to send. — shape: {documentType: "invoice"|"invoice_response"|"order", invoice?: record, invoiceResponse?: record, order?: record, rawDocumentData?: record}
  --idempotencyGuid: string # A guid that you generated for this DocumentSubmission to achieve idempotency. If you submit multiple documents with the same idempotencyGuid, only the first one will be processed and any subsequent ones will trigger an HTTP 422 Unprocessable Entity response.
  --legalEntityId: int # The id of the LegalEntity this document should be sent on behalf of. Either legalEntityId or receiveGuid is mandatory.
  --receiveGuid: string # The GUID that was in the received_document webhook. Either legalEntityId or receiveGuid is mandatory. This field is used for sending response documents, such as InvoiceReponse and OrderResponse.
  --routing: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list}
]: any -> record<guid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document_submissions")
  let body = {attachments: $attachments, createPrimaryImage: $createPrimaryImage, document: $document, idempotencyGuid: $idempotencyGuid, legalEntityId: $legalEntityId, receiveGuid: $receiveGuid, routing: $routing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get DocumentSubmission Evidence
#
# GET /document_submissions/{guid}/evidence/{evidence_type}
# operationId: show_document_submission_evidence
export def "document-submissions-evidence evidence" [
  guid: string
  evidence_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<documents: table<document: string, expires_at: string, mime_type: string>, evidence: record<message_id: string, receiving_accesspoint: string, remote_mta_ip: string, reporting_mta: string, smtp_response: string, timestamp: string, transmission_id: string, xml: string>, network: string, receiver: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document_submissions/($guid)/evidence/($evidence_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a new invoice
#
# POST /invoice_submissions
# operationId: create_invoice_submission
# --attachments item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
# --invoice shape: {accountingCost?: string, accountingCurrencyTaxAmount?: float, accountingCurrencyTaxAmountCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XFU"|"XOF"|"XPD"|"XPF"|"XPT"|"XSU"|"XTS"|"XUA"|"XXX"|"YER"|"ZAR"|"ZMW", accountingCustomerParty: record, accountingSupplierParty?: record, allowanceCharges?: list, amountIncludingVat: float, attachments?: list, billingReference?: string, buyerReference?: string, consumerTaxMode?: bool, contractDocumentReference?: string, delivery?: record, documentCurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XFU"|"XOF"|"XPD"|"XPF"|"XPT"|"XSU"|"XTS"|"XUA"|"XXX"|"YER"|"ZAR"|"ZMW", dueDate?: string, invoiceLines: list, invoiceNumber: string, invoicePeriod?: string, invoiceType?: "380"|"381"|"384", issueDate: string, issueReasons?: list, note?: string, orderReference?: string, paymentMeansArray?: list, paymentMeansBic?: string, paymentMeansCode?: "online_payment_service"|"bank_card"|"direct_debit"|"standing_agreement"|"credit_transfer"|"se_bankgiro"|"se_plusgiro"|"aunz_npp"|""|"1"|"30"|"31"|"42"|"48"|"49"|"57"|"58", paymentMeansIban?: string, paymentMeansPaymentId?: string, paymentTerms?: record, preferredInvoiceType?: "prefer_autodetect"|"prefer_invoice"|"prefer_creditnote", prepaidAmount?: float, projectReference?: string, references?: list, salesOrderId?: string, selfBillingMode?: bool, taxExemptReason?: "export"|"reverse_charge"|"zero_rated"|"exempt"|"outside_scope"|"intra_community", taxPointDate?: string, taxSubtotals?: list, taxSystem?: "tax_line_amounts"|"tax_line_percentages", taxesDutiesFees?: list, transactionType?: "b2b"|"sezwp"|"sezwop"|"expwp"|"expwop"|"dexp", ublExtensions?: list, vatReverseCharge?: bool, x2y?: "b2b"|"b2g"|"b2c"|"b2b_sez"}
# --invoiceData shape: {conversionStrategy?: "ubl"|"cii"|"idoc", document?: string}
# --invoiceRecipient shape: {emails?: list, publicIdentifiers?: list}
# --routing shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list}
export def "invoice-submissions submission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # An array of attachments. You may provide up to 10 attchments, but the total size must not exceed 10MB after Base64 encoding. — item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
  --createPrimaryImage: oneof<nothing, bool> # DEPRECATED. In the future we will no longer support creating PDF invoices. Whether or not to create a primary image (PDF) if one is not provided. For customers who started from December 1st 2022, the default is false. For customers who started before that, the default is true.
  --document: string # DEPRECATED. Use attachments.
  --documentUrl: string # DEPRECATED. Use attachments. (format: uri)
  --idempotencyGuid: string # A guid that you generated for this InvoiceSubmission to achieve idempotency. If you submit multiple documents with the same idempotencyGuid, only the first one will be processed.
  --invoice: record # The invoice to send. Provide either invoice, or invoiceData, but not both. — shape: {accountingCost?: string, accountingCurrencyTaxAmount?: float, accountingCurrencyTaxAmountCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XFU"|"XOF"|"XPD"|"XPF"|"XPT"|"XSU"|"XTS"|"XUA"|"XXX"|"YER"|"ZAR"|"ZMW", accountingCustomerParty: record, accountingSupplierParty?: record, allowanceCharges?: list, amountIncludingVat: float, attachments?: list, billingReference?: string, buyerReference?: string, consumerTaxMode?: bool, contractDocumentReference?: string, delivery?: record, documentCurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLE"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XFU"|"XOF"|"XPD"|"XPF"|"XPT"|"XSU"|"XTS"|"XUA"|"XXX"|"YER"|"ZAR"|"ZMW", dueDate?: string, invoiceLines: list, invoiceNumber: string, invoicePeriod?: string, invoiceType?: "380"|"381"|"384", issueDate: string, issueReasons?: list, note?: string, orderReference?: string, paymentMeansArray?: list, paymentMeansBic?: string, paymentMeansCode?: "online_payment_service"|"bank_card"|"direct_debit"|"standing_agreement"|"credit_transfer"|"se_bankgiro"|"se_plusgiro"|"aunz_npp"|""|"1"|"30"|"31"|"42"|"48"|"49"|"57"|"58", paymentMeansIban?: string, paymentMeansPaymentId?: string, paymentTerms?: record, preferredInvoiceType?: "prefer_autodetect"|"prefer_invoice"|"prefer_creditnote", prepaidAmount?: float, projectReference?: string, references?: list, salesOrderId?: string, selfBillingMode?: bool, taxExemptReason?: "export"|"reverse_charge"|"zero_rated"|"exempt"|"outside_scope"|"intra_community", taxPointDate?: string, taxSubtotals?: list, taxSystem?: "tax_line_amounts"|"tax_line_percentages", taxesDutiesFees?: list, transactionType?: "b2b"|"sezwp"|"sezwop"|"expwp"|"expwop"|"dexp", ublExtensions?: list, vatReverseCharge?: bool, x2y?: "b2b"|"b2g"|"b2c"|"b2b_sez"}
  --invoiceData: record # The invoice to send, in base64 encoded format. Provide either invoice, or invoiceData, but not both. — shape: {conversionStrategy?: "ubl"|"cii"|"idoc", document?: string}
  --invoiceRecipient: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {emails?: list, publicIdentifiers?: list}
  --legalEntityId: int # The id of the LegalEntity this invoice should be sent for.
  --legalSupplierId: int # DEPRECATED. Use legalEntityId
  --mode: string@mode-completer # DEPRECATED.
  --routing: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list}
  --supplierId: int # DEPRECATED.
]: any -> record<guid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice_submissions")
  let body = {attachments: $attachments, createPrimaryImage: $createPrimaryImage, document: $document, documentUrl: $documentUrl, idempotencyGuid: $idempotencyGuid, invoice: $invoice, invoiceData: $invoiceData, invoiceRecipient: $invoiceRecipient, legalEntityId: $legalEntityId, legalSupplierId: $legalSupplierId, mode: $mode, routing: $routing, supplierId: $supplierId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEPRECATED. Preflight an invoice recipient
#
# POST /invoice_submissions/preflight
# operationId: preflight_invoice_recipient
# --publicIdentifiers item shape: {id: string, scheme: string}
export def "invoice-submissions-preflight recipient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --publicIdentifiers: list # A list of public identifiers that uniquely identify this customer. — item shape: {id: string, scheme: string}
]: any -> record<code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice_submissions/preflight")
  let body = {publicIdentifiers: $publicIdentifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEPRECATED. Get InvoiceSubmission Evidence
#
# GET /invoice_submissions/{guid}/evidence
# operationId: show_invoice_submission_evidence
export def "invoice-submissions-evidence evidence" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<receiver_response: string, transmission_datetime: string, transmission_result: string, transmission_type: string, transmitted_document: string>, guid: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoice_submissions/($guid)/evidence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new LegalEntity
#
# POST /legal_entities
# operationId: create_legal_entity
# --rea shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", province?: "AG"|"AL"|"AN"|"AO"|"AQ"|"AR"|"AP"|"AT"|"AV"|"BA"|"BT"|"BL"|"BN"|"BG"|"BI"|"BO"|"BZ"|"BS"|"BR"|"CA"|"CL"|"CB"|"CI"|"CE"|"CT"|"CZ"|"CH"|"CO"|"CS"|"CR"|"KR"|"CN"|"EN"|"FM"|"FE"|"FI"|"FG"|"FC"|"FR"|"GE"|"GO"|"GR"|"IM"|"IS"|"SP"|"LT"|"LE"|"LC"|"LI"|"LO"|"LU"|"MC"|"MN"|"MS"|"MT"|"VS"|"ME"|"MI"|"MO"|"MB"|"NA"|"NO"|"NU"|"OG"|"OT"|"OR"|"PD"|"PA"|"PR"|"PV"|"PG"|"PU"|"PE"|"PC"|"PI"|"PT"|"PN"|"PZ"|"PO"|"RG"|"RA"|"RC"|"RE"|"RI"|"RN"|"RO"|"SA"|"SS"|"SV"|"SI"|"SR"|"SO"|"TA"|"TE"|"TR"|"TO"|"TP"|"TN"|"TV"|"TS"|"UD"|"VA"|"VE"|"VB"|"VC"|"VR"|"VV"|"VI"|"VT"}
export def "legal-entities entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertisements: list # A list of document types to advertise. Use if this LegalEntity needs the ability to receive more than only invoice documents. (default: [invoice])
  city: string # The city.
  country: string@country-completer # An ISO 3166-1 alpha-2 country code.
  --county: string # County, if applicable
  line1: string # The first address line.
  --line2: string # The second address line, if applicable
  party_name: string # The name of the company.
  --public: oneof<nothing, bool> # Whether or not this LegalEntity is public. Public means it will be entered into the PEPPOL directory at https://directory.peppol.eu/ (default: true)
  --rea: any # shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", province?: "AG"|"AL"|"AN"|"AO"|"AQ"|"AR"|"AP"|"AT"|"AV"|"BA"|"BT"|"BL"|"BN"|"BG"|"BI"|"BO"|"BZ"|"BS"|"BR"|"CA"|"CL"|"CB"|"CI"|"CE"|"CT"|"CZ"|"CH"|"CO"|"CS"|"CR"|"KR"|"CN"|"EN"|"FM"|"FE"|"FI"|"FG"|"FC"|"FR"|"GE"|"GO"|"GR"|"IM"|"IS"|"SP"|"LT"|"LE"|"LC"|"LI"|"LO"|"LU"|"MC"|"MN"|"MS"|"MT"|"VS"|"ME"|"MI"|"MO"|"MB"|"NA"|"NO"|"NU"|"OG"|"OT"|"OR"|"PD"|"PA"|"PR"|"PV"|"PG"|"PU"|"PE"|"PC"|"PI"|"PT"|"PN"|"PZ"|"PO"|"RG"|"RA"|"RC"|"RE"|"RI"|"RN"|"RO"|"SA"|"SS"|"SV"|"SI"|"SR"|"SO"|"TA"|"TE"|"TR"|"TO"|"TP"|"TN"|"TV"|"TS"|"UD"|"VA"|"VE"|"VB"|"VC"|"VR"|"VV"|"VI"|"VT"}
  --tenant-id: string # The id of the tenant, to be used in case of single-tenant solutions that share webhook URLs. This property will included in webhook events.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  zip: string # The zipcode.
]: any -> record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legal_entities")
  let body = {advertisements: $advertisements, city: $city, country: $country, county: $county, line1: $line1, line2: $line2, party_name: $party_name, public: $public, rea: $rea, tenant_id: $tenant_id, third_party_password: $third_party_password, third_party_username: $third_party_username, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete LegalEntity
#
# DELETE /legal_entities/{id}
# operationId: delete_legal_entity
export def "legal-entities entity-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get LegalEntity
#
# GET /legal_entities/{id}
# operationId: get_legal_entity
export def "legal-entities entity-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update LegalEntity
#
# PATCH /legal_entities/{id}
# operationId: update_legal_entity
# --rea shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", province?: "AG"|"AL"|"AN"|"AO"|"AQ"|"AR"|"AP"|"AT"|"AV"|"BA"|"BT"|"BL"|"BN"|"BG"|"BI"|"BO"|"BZ"|"BS"|"BR"|"CA"|"CL"|"CB"|"CI"|"CE"|"CT"|"CZ"|"CH"|"CO"|"CS"|"CR"|"KR"|"CN"|"EN"|"FM"|"FE"|"FI"|"FG"|"FC"|"FR"|"GE"|"GO"|"GR"|"IM"|"IS"|"SP"|"LT"|"LE"|"LC"|"LI"|"LO"|"LU"|"MC"|"MN"|"MS"|"MT"|"VS"|"ME"|"MI"|"MO"|"MB"|"NA"|"NO"|"NU"|"OG"|"OT"|"OR"|"PD"|"PA"|"PR"|"PV"|"PG"|"PU"|"PE"|"PC"|"PI"|"PT"|"PN"|"PZ"|"PO"|"RG"|"RA"|"RC"|"RE"|"RI"|"RN"|"RO"|"SA"|"SS"|"SV"|"SI"|"SR"|"SO"|"TA"|"TE"|"TR"|"TO"|"TP"|"TN"|"TV"|"TS"|"UD"|"VA"|"VE"|"VB"|"VC"|"VR"|"VV"|"VI"|"VT"}
export def "legal-entities entity-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertisements: list # A list of document types to advertise. Use if this LegalEntity needs the ability to receive more than only invoice documents. (default: [invoice])
  --city: string # The city.
  --country: string@country-completer # An ISO 3166-1 alpha-2 country code.
  --county: string # County, if applicable
  --body-id: int # The Storecove assigned id for the LegalEntity. (format: int64)
  --line1: string # The first address line.
  --line2: string # The second address line, if applicable
  --party-name: string # The name of the company.
  --public: oneof<nothing, bool> # Whether or not this LegalEntity is public. Public means it will be listed in the PEPPOL directory at https://directory.peppol.eu/ which is normally what you want. If you have a good reason to not want the LegalEntity listed, provide false. This property is ignored when for country SG, where it is always true. (default: true)
  --rea: any # shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", province?: "AG"|"AL"|"AN"|"AO"|"AQ"|"AR"|"AP"|"AT"|"AV"|"BA"|"BT"|"BL"|"BN"|"BG"|"BI"|"BO"|"BZ"|"BS"|"BR"|"CA"|"CL"|"CB"|"CI"|"CE"|"CT"|"CZ"|"CH"|"CO"|"CS"|"CR"|"KR"|"CN"|"EN"|"FM"|"FE"|"FI"|"FG"|"FC"|"FR"|"GE"|"GO"|"GR"|"IM"|"IS"|"SP"|"LT"|"LE"|"LC"|"LI"|"LO"|"LU"|"MC"|"MN"|"MS"|"MT"|"VS"|"ME"|"MI"|"MO"|"MB"|"NA"|"NO"|"NU"|"OG"|"OT"|"OR"|"PD"|"PA"|"PR"|"PV"|"PG"|"PU"|"PE"|"PC"|"PI"|"PT"|"PN"|"PZ"|"PO"|"RG"|"RA"|"RC"|"RE"|"RI"|"RN"|"RO"|"SA"|"SS"|"SV"|"SI"|"SR"|"SO"|"TA"|"TE"|"TR"|"TO"|"TP"|"TN"|"TV"|"TS"|"UD"|"VA"|"VE"|"VB"|"VC"|"VR"|"VV"|"VI"|"VT"}
  --smart-inbox: string # DEPRECATED. Use the <<_openapi_receiveddocuments_resource>> endpoint. The email address of the Smart Inbox for this LegalEntity.
  --tenant-id: string # The id of the tenant, to be used in case of multi-tenant solutions. This property will included in webhook events.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --zip: string # The zipcode.
]: any -> record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($id)")
  let body = {advertisements: $advertisements, city: $city, country: $country, county: $county, id: $body_id, line1: $line1, line2: $line2, party_name: $party_name, public: $public, rea: $rea, smart_inbox: $smart_inbox, tenant_id: $tenant_id, third_party_password: $third_party_password, third_party_username: $third_party_username, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new AdditionalTaxIdentifier
#
# POST /legal_entities/{legal_entity_id}/additional_tax_identifiers
# operationId: create_additional_tax_identifier
export def "legal-entities-additional-tax-identifiers identifier-by-legal_entity_id" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string # The ISO3166 country code to use this identifier for in case of consumerTaxMode.
  --county: string # The county/state inside the country code to use this identifier for in case of consumerTaxMode. Leave empty to create an additional tax identifier for the entire country. For India, use the two last characters of ISO 3166-2:IN (https://en.wikipedia.org/wiki/States_and_union_territories_of_India).
  identifier: string # The identifier.
  scheme: string # The scheme of the identifier.
  superscheme: string # The superscheme of the identifier. Should always be "iso6523-actorid-upis".
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
]: any -> record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/additional_tax_identifiers")
  let body = {country: $country, county: $county, identifier: $identifier, scheme: $scheme, superscheme: $superscheme, third_party_password: $third_party_password, third_party_username: $third_party_username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete AdditionalTaxIdentifier
#
# DELETE /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# operationId: delete_additional_tax_identifier
export def "legal-entities-additional-tax-identifiers identifier-by-legal_entity_id-id" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/additional_tax_identifiers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get AdditionalTaxIdentifier
#
# GET /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# operationId: get_additional_tax_identifier
export def "legal-entities-additional-tax-identifiers identifier-by-legal_entity_id-id-1" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/additional_tax_identifiers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update AdditionalTaxIdentifier
#
# PATCH /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# operationId: update_additional_tax_identifier
export def "legal-entities-additional-tax-identifiers identifier-by-legal_entity_id-id-2" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string # The identifier.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
]: any -> record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/additional_tax_identifiers/($id)")
  let body = {identifier: $identifier, third_party_password: $third_party_password, third_party_username: $third_party_username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new Administration
#
# POST /legal_entities/{legal_entity_id}/administrations
# operationId: create_administration
export def "legal-entities-administrations administration-by-legal_entity_id" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address to send the received document to
  --body-legal-entity-id: int # The LegalEntity the Administration belongs to. (format: int64)
  --package-version: string@package-version-completer # The version of the package. (default: peppol_bis_v3)
  --packaging: string@packaging-completer # How to package the purchase invoice. (default: ubl)
  --sender-email-identity-id: int # The id of the SenderEmailIdentity. If not provided, the Storecove default sender will be used (format: int64)
]: any -> record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/administrations")
  let body = {email: $email, legal_entity_id: $body_legal_entity_id, package_version: $package_version, packaging: $packaging, sender_email_identity_id: $sender_email_identity_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Administration
#
# DELETE /legal_entities/{legal_entity_id}/administrations/{id}
# operationId: delete_administration
export def "legal-entities-administrations administration-by-legal_entity_id-id" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/administrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Administration
#
# GET /legal_entities/{legal_entity_id}/administrations/{id}
# operationId: get_administration
export def "legal-entities-administrations administration-by-legal_entity_id-id-1" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/administrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Administration
#
# PATCH /legal_entities/{legal_entity_id}/administrations/{id}
# operationId: update_administration
export def "legal-entities-administrations administration-by-legal_entity_id-id-2" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address to send the received document to
  --package-version: string@package-version-completer # The version of the package.
  --packaging: string@packaging-completer # How to package the purchase invoice.
  --sender-email-identity-id: int # The id of the SenderEmailIdentity. If not provided, the Storecove default sender will be used (format: int64)
]: any -> record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/administrations/($id)")
  let body = {email: $email, package_version: $package_version, packaging: $packaging, sender_email_identity_id: $sender_email_identity_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new PeppolIdentifier
#
# POST /legal_entities/{legal_entity_id}/peppol_identifiers
# operationId: create_peppol_identifier
# --corppass shape: {client_redirect_fail_url?: string, client_redirect_success_url?: string, enabled?: bool, flow_type: "corppass_flow_redirect"|"corppass_flow_email", signer_email?: string, signer_name?: string, simulate_corppass?: bool}
export def "legal-entities-peppol-identifiers identifier-by-legal_entity_id" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --corppass: any # shape: {client_redirect_fail_url?: string, client_redirect_success_url?: string, enabled?: bool, flow_type: "corppass_flow_redirect"|"corppass_flow_email", signer_email?: string, signer_name?: string, simulate_corppass?: bool}
  identifier: string # The identifier.
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
  superscheme: string # The superscheme of the identifier. Should always be "iso6523-actorid-upis".
]: any -> record<corppass: record<client_redirect_fail_url: string, client_redirect_success_url: string, corppass_url: string, enabled: bool, flow_type: string, signer_email: string, signer_name: string, simulate_corppass: bool, status: string>, identifier: string, scheme: string, superscheme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/peppol_identifiers")
  let body = {corppass: $corppass, identifier: $identifier, scheme: $scheme, superscheme: $superscheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete PeppolIdentifier
#
# DELETE /legal_entities/{legal_entity_id}/peppol_identifiers/{superscheme}/{scheme}/{identifier}
# operationId: delete_peppol_identifier
export def "legal-entities-peppol-identifiers identifier-by-legal_entity_id-superscheme-scheme-identifier" [
  legal_entity_id: int
  superscheme: string
  scheme: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/peppol_identifiers/($superscheme)/($scheme)/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Receive a new Document
#
# POST /legal_entities/{legal_entity_id}/received_documents
# operationId: receive_documenht
export def "legal-entities-received-documents documenht" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: string # The Base64 encoded document.
  --body-legal-entity-id: int # The of the LegalEntity this document was received for. (format: int64)
  --parseStrategy: string@parseStrategy-completer # The attachment content type (mime type).
]: any -> record<guid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_entities/($legal_entity_id)/received_documents")
  let body = {document: $document, legal_entity_id: $body_legal_entity_id, parseStrategy: $parseStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Purchase invoice data as JSON
#
# GET /purchase_invoices/{guid}
# operationId: get_invoice_json
export def "purchase-invoices json" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pmv: string # The PaymentMeans version. The default (and deprecated) version 1.0 will give BankPaymentMean, DirectDebitPaymentMean, CardPaymentMean, NppPaymentMean, SeBankGiroPaymentMean, SePlusGiroPaymentMean, SgCardPaymentMean, SgGiroPaymentMean, SgPaynowPaymentMean.  Version 2.0 deprecates BankPaymentMean (now CreditTransferPaymentMean), CardPaymentMean (now CreditCardPaymentMean), NppPaymentMean (now AunzNppPayidPaymentMean), SeBankGiroPaymentMean (now SeBankgiroPaymentMean  -- note the lower 'g' in 'bankgiro'). It also adds OnlinePaymentServicePaymentMean, StandingAgreementPaymentMean, AunzNppPaytoPaymentMean, AunzBpayPaymentMean, AunzPostbillpayPaymentMean, AunzUriPaymentMean. (default: 1.0)
]: nothing -> record<accounting: record<code: string, list: string, list_version: string, name: string>, accounting_cost: string, allowance_charge: float, allowance_charges: table<amount_excluding_tax: float, amount_excluding_vat: string, reason: string, tax: record, vat: record>, amount_including_vat: float, attachments: table<content_type: string, document: string>, billing_reference: string, buyer_reference: string, contract_document_reference: string, delivery: record<actual_date: string, location: record<building_number: string, city: string, country: string, county: string, department: string, id: string, line1: string, line2: string, neighborhood: string, scheme_id: string, secondary_number: string, zip: string>, party: record<name: string>>, document: string, document_currency_code: string, document_totals: record<payable: float, prepaid: float, rounding: float, total: float>, document_type: string, due_date: string, external_key: string, external_user_id: string, guid: string, invoice_lines: table<accounting: record, allowance_charge: float, allowance_charge_array: list, allowance_charges: list, amount_excluding_tax: float, amount_excluding_vat: float, description: string, name: string, period_end: string, period_start: string, price: record, tax: record, units: record, vat: record>, invoice_number: string, invoice_type: string, issue_date: string, legal_entity_id: int, note: string, order_reference: string, payment_means: record<iban: string, id: string>, payment_means_array: table<account: string, branch_code: string, holder: string, mandate: string, network: string, payment_id: string, type: any>, payment_means_payment_id: string, payment_terms_note: string, period_end: string, period_start: string, project_reference: string, sender: record<billing_contact: record<email: string, first_name: string, last_name: string>, building_number: string, city: string, country: string, county: string, department: string, identifiers: list<record>, legal_name: string, line1: string, line2: string, neighborhood: string, party_name: string, peppol_identifiers: record<corppass: record, identifier: string, scheme: string, superscheme: string>, secondary_number: string, zip: string>, source: string, sub_type: string, system_generated_primary_image: bool, tax_point_date: string, tax_subtotals: table<amount_excluding_tax: float, amount_excluding_vat: string, tax: record, vat: record>, tax_system: string, vat_reverse_charge: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pmv" $pmv "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/purchase_invoices/($guid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Purchase invoice data in a selectable format
#
# GET /purchase_invoices/{guid}/{packaging}
# operationId: get_invoice_ubl
export def "purchase-invoices ubl" [
  guid: string
  packaging: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pmv: string # The PaymentMeans version. The default (and deprecated) version 1.0 will give BankPaymentMean, DirectDebitPaymentMean, CardPaymentMean, NppPaymentMean, SeBankGiroPaymentMean, SePlusGiroPaymentMean, SgCardPaymentMean, SgGiroPaymentMean, SgPaynowPaymentMean.  Version 2.0 deprecates BankPaymentMean (now CreditTransferPaymentMean), CardPaymentMean (now CreditCardPaymentMean), NppPaymentMean (now AunzNppPayidPaymentMean), SeBankGiroPaymentMean (now SeBankgiroPaymentMean  -- note the lower 'g' in 'bankgiro'). It also adds OnlinePaymentServicePaymentMean, StandingAgreementPaymentMean, AunzNppPaytoPaymentMean, AunzBpayPaymentMean, AunzPostbillpayPaymentMean, AunzUriPaymentMean. (default: 1.0)
]: nothing -> record<external_key: string, external_user_id: string, guid: string, legal_entity_id: int, system_generated_primary_image: bool, tax_system: string, ubl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pmv" $pmv "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/purchase_invoices/($guid)/($packaging)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Purchase invoice data as JSON with a Base64-encoded UBL string in the specified version
#
# GET /purchase_invoices/{guid}/{packaging}/{package_version}
# operationId: get_invoice_ubl_versioned
export def "purchase-invoices versioned" [
  guid: string
  packaging: string
  package_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<external_key: string, external_user_id: string, guid: string, legal_entity_id: int, system_generated_primary_image: bool, tax_system: string, ubl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/purchase_invoices/($guid)/($packaging)/($package_version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new received document
#
# POST /received_documents
# operationId: create_received_document
export def "received-documents document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: string # The Base64 encoded document.
  --legal-entity-id: int # The of the LegalEntity this document was received for. (format: int64)
  --parseStrategy: string@parseStrategy-completer # The attachment content type (mime type).
]: any -> record<guid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/received_documents")
  let body = {document: $document, legal_entity_id: $legal_entity_id, parseStrategy: $parseStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a new ReceivedDocument
#
# GET /received_documents/{guid}/{format}
# operationId: get_received_document
export def "received-documents document-by-guid-format" [
  guid: string
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --syntax: string@syntax-completer # The syntax in which to receive the received document. (default: json)
]: nothing -> record<guid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "syntax" $syntax "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/received_documents/($guid)/($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET a WebhookInstance
#
# GET /webhook_instances/
# operationId: get_webhook_instances
export def "webhook-instances instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: string, guid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_instances/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE a WebhookInstance
#
# DELETE /webhook_instances/{guid}
# operationId: delete_webhook_instance
export def "webhook-instances instance" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_instances/($guid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
