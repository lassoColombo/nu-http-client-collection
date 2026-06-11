# Auto-generated client for Rebilly REST API v2.1
# Source: https://api.apis.guru/v2/specs/rebilly.com/2.1/openapi.json
# Auth: --token flag or $env.REBILLY_REST_API_TOKEN

const BASE_URL = "https://api-sandbox.rebilly.com"
const DEFAULT_AUTH = "reb-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REBILLY_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "reb-apikey" => { {headers: {REB-APIKEY: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://api-sandbox.rebilly.com" "https://api.rebilly.com"] }
def auth-scheme-completer [] { ["bearer" "reb-apikey"] }

# Completers for enum parameters
def enrolled-completer [] { ["N" "U" "Y"] }
def payerAuthResponseStatus-completer [] { ["A" "N" "U" "Y"] }
def signatureVerification-completer [] { ["N" "Y"] }
def relatedType-completer [] { ["customer" "customer-timeline-comment" "dispute" "gateway-timeline-comment" "invoice" "order-timeline-comment" "organization" "payment" "plan" "product" "subscription" "transaction" "transaction-timeline-comment"] }
def mode-completer [] { ["password" "passwordless"] }
def accountType-completer [] { ["checking" "other" "savings"] }
def type-completer [] { ["address" "bank-account" "bin" "country" "customer-id" "email" "email-domain" "fingerprint" "ip-address" "payment-card"] }
def type-completer-1 [] { ["array" "boolean" "datetime" "integer" "monetary" "number" "string"] }
def type-completer-2 [] { ["aml-list-was-possibly-matched" "coupon-applied" "coupon-redeemed" "coupon-redemption-canceled" "custom-event" "custom-event-processed" "custom-fields-changed" "customer-bank-account-blocked" "customer-blocked" "customer-comment-created" "customer-created" "customer-payment-card-blocked" "default-payment-instrument-changed" "email-message-sent" "experian-check-performed" "invoice-abandoned" "invoice-created" "invoice-disputed" "invoice-issued" "invoice-paid" "invoice-partially-paid" "invoice-partially-refunded" "invoice-past-due" "invoice-refunded" "invoice-voided" "kyc-document-accepted" "kyc-document-created" "kyc-document-manually-accepted" "kyc-document-manually-rejected" "kyc-document-modified" "kyc-document-rejected" "lead-source-changed" "order-activated" "order-canceled" "order-churned" "order-completed" "order-created" "order-downgraded" "order-paid-early" "order-reactivated" "order-renewed" "order-upgraded" "payment-card-expired" "payment-instrument-created" "payment-instrument-deactivated" "primary-address-changed" "transaction-abandoned" "transaction-amount-discrepancy-found" "transaction-approved" "transaction-canceled" "transaction-declined" "transaction-discrepancy-found" "transaction-refunded" "transaction-voided" "transaction-waiting-gateway"] }
def type-completer-3 [] { ["Apple Pay"] }
def reasonCode-completer [] { ["0" "00" "1" "10.1" "10.2" "10.3" "10.4" "10.5" "1000" "11.1" "11.2" "11.3" "12" "12.1" "12.2" "12.3" "12.4" "12.5" "12.6" "12.7" "13.1" "13.2" "13.3" "13.4" "13.5" "13.6" "13.7" "13.8" "13.9" "2" "2" "3" "30" "31" "35" "37" "4" "40" "41" "42" "46" "47" "49" "5" "50" "51" "53" "54" "55" "57" "59" "6" "60" "62" "63" "7" "7" "70" "71" "72" "73" "74" "75" "76" "77" "79" "8" "80" "81" "82" "83" "85" "86" "9" "93" "A" "A01" "A02" "A08" "AL" "AP" "AW" "B" "C02" "C04" "C05" "C08" "C14" "C18" "C28" "C31" "C32" "CA" "CD" "CR" "DA" "DP" "DP1" "EX" "F10" "F14" "F22" "F24" "F29" "FR1" "FR4" "FR6" "IC" "IN" "IS" "LP" "M01" "M10" "M49" "N" "NA" "NC" "P" "P01" "P03" "P04" "P05" "P07" "P08" "P22" "P23" "R03" "R13" "RG" "RM" "RN1" "RN2" "SV" "TF" "TNM" "UA01" "UA02" "UA03" "UA10" "UA11" "UA12" "UA18" "UA20" "UA21" "UA22" "UA23" "UA28" "UA30" "UA31" "UA32" "UA38" "UA99" "bank_cannot_process" "credit_not_processed" "customer_initiated" "debit_not_authorized" "duplicate" "fraudulent" "general" "incorrect_account_details" "insufficient_funds" "pre-chargeback-alert" "product_not_received" "product_unacceptable" "subscription_canceled" "unrecognized"] }
def status-completer [] { ["forfeited" "lost" "response-needed" "under-review" "unknown" "won"] }
def type-completer-4 [] { ["arbitration" "ethoca-alert" "first-chargeback" "fraud" "information-request" "second-chargeback" "verifi-alert"] }
def Accept-completer [] { ["application/json" "application/pdf"] }
def accept-completer [] { ["application/json" "application/pdf"] }
def type-completer-5 [] { ["credit" "debit"] }
def type-completer-6 [] { ["document-expired" "document-not-matching" "document-unreadable" "other" "underage-person"] }
def method-completer [] { ["payment-card"] }
def method-completer-1 [] { ["paypal"] }
def taxCategoryId-completer [] { ["00000" "20010" "30070" "31000" "40030" "51010" "51020" "99999"] }
def canceledBy-completer [] { ["customer" "merchant"] }
def reason-completer [] { ["billing-failure" "bugs-or-problems" "contract-expired" "did-not-use" "did-not-want" "do-not-remember" "missing-features" "other" "risk-warning" "too-expensive"] }
def status-completer-1 [] { ["completed" "confirmed" "draft" "revoked"] }
def orderType-completer [] { ["one-time-order" "subscription-order"] }
def renewalPolicy-completer [] { ["reset" "retain"] }
def type-completer-7 [] { ["3ds-authentication" "authorize" "sale"] }
def result-completer [] { ["abandoned" "approved" "canceled" "declined"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "3dsecure Get3DSecureCollection" } } | get name | first)
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

# Retrieve a list of ThreeDSecure entries
#
# GET /3dsecure
# operationId: Get3DSecureCollection
export def "3dsecure Get3DSecureCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<record>, amount: float, cavv: string, createdTime: record, currency: record, customerId: record, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: record, id: record, payerAuthResponseStatus: string, paymentCardId: record, signatureVerification: string, websiteId: record, xid: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/3dsecure" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a ThreeDSecure entry
#
# POST /3dsecure
# operationId: Post3DSecure
# --_links item shape: {rel: "self", href: string}
export def "3dsecure Post3DSecure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # Transaction amount. (format: double)
  --cavv: string # The 3D Secure entry cardholder authentication verification value.
  --createdTime: any # The 3D Secure entry created time.
  currency: any
  customerId: any # Related customer ID.
  --eci: int # The 3D Secure entry electronic commerce indicator.
  enrolled: string@enrolled-completer # Is the cardholder enrolled in 3DSecure.
  enrollmentEci: string # The 3D Secure entry enrollment eci.
  gatewayAccountId: any # Related gateway account ID.
  --payerAuthResponseStatus: string@payerAuthResponseStatus-completer # The 3D Secure entry Auth Response Status.
  paymentCardId: any # Related payment card ID.
  --signatureVerification: string@signatureVerification-completer # If signature was verified.
  websiteId: any # Related Website ID.
  --xid: string # The 3D Secure entry transaction Id.
]: any -> record<_links: table<rel: string>, amount: float, cavv: string, createdTime: record, currency: record, customerId: record, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: record, id: record, payerAuthResponseStatus: string, paymentCardId: record, signatureVerification: string, websiteId: record, xid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/3dsecure")
  let body = {amount: $amount, cavv: $cavv, createdTime: $createdTime, currency: $currency, customerId: $customerId, eci: $eci, enrolled: $enrolled, enrollmentEci: $enrollmentEci, gatewayAccountId: $gatewayAccountId, payerAuthResponseStatus: $payerAuthResponseStatus, paymentCardId: $paymentCardId, signatureVerification: $signatureVerification, websiteId: $websiteId, xid: $xid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a ThreeDSecure entry
#
# GET /3dsecure/{id}
# operationId: Get3DSecure
export def "3dsecure Get3DSecure" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, amount: float, cavv: string, createdTime: record, currency: record, customerId: record, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: record, id: record, payerAuthResponseStatus: string, paymentCardId: record, signatureVerification: string, websiteId: record, xid: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/3dsecure/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search PEP/Sanctions/Adverse Media lists
#
# GET /aml
# operationId: GetAmlEntry
export def "aml GetAmlEntry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --firstName: string # First name of individual to search.
  --lastName: string # Last name of individual to search.
  --dob: string # Date of birth in format YYYY-MM-DD.
  --country: string # Country of individual as an ISO Alpha-2 code.
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> table<_links: list<record>, address: list<record>, aliases: list<record>, comments: string, confidence: string, dob: list<string>, firstName: string, gender: string, lastName: string, legalBasis: list<string>, nationality: string, passport: list<record>, regime: string, source: string, sourceType: string, title: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $firstName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "dob" $dob "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aml" $qp)
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of Attachments
#
# GET /attachments
# operationId: GetAttachmentCollection
export def "attachments GetAttachmentCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --qp-fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, fileId: string, id: record, name: string, relatedId: string, relatedType: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Attachment
#
# POST /attachments
# operationId: PostAttachment
export def "attachments PostAttachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Creation date/time.
  --description: string # The Attachment description.
  fileId: string # Linked File object id.
  --name: string # The Original Attachment name.
  relatedId: string # Linked object Id.
  relatedType: string@relatedType-completer # Linked object type.
  --updatedTime: any # Latest update date/time.
]: any -> record<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, fileId: string, id: record, name: string, relatedId: string, relatedType: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attachments")
  let body = {createdTime: $createdTime, description: $description, fileId: $fileId, name: $name, relatedId: $relatedId, relatedType: $relatedType, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Attachment
#
# DELETE /attachments/{id}
# operationId: DeleteAttachment
export def "attachments DeleteAttachment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an Attachment
#
# GET /attachments/{id}
# operationId: GetAttachment
export def "attachments GetAttachment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, fileId: string, id: record, name: string, relatedId: string, relatedType: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Attachment with predefined ID
#
# PUT /attachments/{id}
# operationId: PutAttachment
export def "attachments PutAttachment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Creation date/time.
  --description: string # The Attachment description.
  fileId: string # Linked File object id.
  --name: string # The Original Attachment name.
  relatedId: string # Linked object Id.
  relatedType: string@relatedType-completer # Linked object type.
  --updatedTime: any # Latest update date/time.
]: any -> record<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, fileId: string, id: record, name: string, relatedId: string, relatedType: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($id)")
  let body = {createdTime: $createdTime, description: $description, fileId: $fileId, name: $name, relatedId: $relatedId, relatedType: $relatedType, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read current authentication options
#
# GET /authentication-options
# operationId: GetAuthenticationOption
export def "authentication-options GetAuthenticationOption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> table<authTokenTtl: int, credentialTtl: int, otpRequired: bool, passwordPattern: string, resetTokenTtl: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication-options")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change authentication options
#
# PUT /authentication-options
# operationId: PutAuthenticationOption
export def "authentication-options PutAuthenticationOption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --authTokenTtl: int # The default lifetime of the auth-token in seconds.
  --credentialTtl: int # The default lifetime of the credential in seconds.
  --otpRequired: string@bool-completer # Should OTP be required to exchange token.
  --passwordPattern: string # Allowed password pattern.
  --resetTokenTtl: int # The default lifetime of the reset-token in seconds.
]: any -> record<authTokenTtl: int, credentialTtl: int, otpRequired: bool, passwordPattern: string, resetTokenTtl: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication-options")
  let body = {authTokenTtl: $authTokenTtl, credentialTtl: $credentialTtl, otpRequired: $otpRequired, passwordPattern: $passwordPattern, resetTokenTtl: $resetTokenTtl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of auth tokens
#
# GET /authentication-tokens
# operationId: GetAuthenticationTokenCollection
export def "authentication-tokens GetAuthenticationTokenCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<credentialId: record, mode: string, otpRequired: bool, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Login
#
# POST /authentication-tokens
# Discriminator (request): mode = password, passwordless
# operationId: PostAuthenticationToken
export def "authentication-tokens PostAuthenticationToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  mode: string@mode-completer # The token's generation mode. (default: password)
  --otpRequired: string@bool-completer # Should OTP be required to exchange this token.
]: any -> record<credentialId: record, mode: string, otpRequired: bool, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication-tokens")
  let body = {mode: $mode, otpRequired: $otpRequired} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Logout a customer
#
# DELETE /authentication-tokens/{token}
# operationId: DeleteAuthenticationToken
export def "authentication-tokens DeleteAuthenticationToken" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication-tokens/($token)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify
#
# GET /authentication-tokens/{token}
# Discriminator (response): mode = password, passwordless
# operationId: GetAuthenticationTokenVerification
export def "authentication-tokens GetAuthenticationTokenVerification" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<credentialId: record, mode: string, otpRequired: bool, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication-tokens/($token)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange
#
# POST /authentication-tokens/{token}/exchange
# operationId: PostAuthenticationTokenExchange
# --_links item shape: {rel: "customer"|"targetCustomer", href: string}
# --acl item shape: {permissions: any, scope: any}
export def "authentication-tokens-exchange PostAuthenticationTokenExchange" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acl: list # item shape: {permissions: any, scope: any}
  --customClaims: record # e.g. {documents: [identity-proof, address-proof], redirectUrl: https://mywebsite.com}
  --expiredTime: string # Session expired time. Defaults to one hour. (format: date-time)
  --invalidate: string@bool-completer # Whether to invalidate token after exchange or not. (default: true, e.g. true)
  --oneTimePassword: string # The one time password sent via an email. Should contain digits only. (e.g. 123456)
  --updatedTime: any # Session updated time.
]: any -> record<_links: table<rel: string>, acl: table<permissions: record, scope: record>, createdTime: string, customClaims: record, customerId: record, expiredTime: string, id: record, invalidate: bool, oneTimePassword: string, token: string, type: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authentication-tokens/($token)/exchange")
  let body = {acl: $acl, customClaims: $customClaims, expiredTime: $expiredTime, invalidate: $invalidate, oneTimePassword: $oneTimePassword, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of bank accounts
#
# GET /bank-accounts
# operationId: GetBankAccountCollection
export def "bank-accounts GetBankAccountCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bank-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Bank Account
#
# POST /bank-accounts
# operationId: PostBankAccount
export def "bank-accounts PostBankAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --customerId: any # The Customer's ID.
  --body-token: string # BankAccountToken ID.
]: any -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank-accounts")
  let body = {customFields: $customFields, customerId: $customerId, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Bank Account
#
# GET /bank-accounts/{id}
# operationId: GetBankAccount
export def "bank-accounts GetBankAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bank-accounts/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a bank account's values
#
# PATCH /bank-accounts/{id}
# operationId: PatchBankAccount
export def "bank-accounts PatchBankAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --accountType: string@accountType-completer # Bank's account type.
  --bankName: string # Bank's name.
  --billingAddress: any # The billing address.
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
]: any -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bank-accounts/($id)")
  let body = {accountType: $accountType, bankName: $bankName, billingAddress: $billingAddress, customFields: $customFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Bank Account with predefined ID
#
# PUT /bank-accounts/{id}
# operationId: PutBankAccount
export def "bank-accounts PutBankAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --customerId: any # The Customer's ID.
  --body-token: string # BankAccountToken ID.
]: any -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bank-accounts/($id)")
  let body = {customFields: $customFields, customerId: $customerId, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate a Bank Account
#
# POST /bank-accounts/{id}/deactivation
# operationId: PostBankAccountDeactivation
export def "bank-accounts-deactivation PostBankAccountDeactivation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bank-accounts/($id)/deactivation")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of blocklists
#
# GET /blocklists
# operationId: GetBlocklistCollection
export def "blocklists GetBlocklistCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, createdTime: record, expirationTime: string, id: record, type: string, updatedTime: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocklists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a blocklist
#
# POST /blocklists
# operationId: PostBlocklist
# --_links item shape: {rel: "self", href: string}
export def "blocklists PostBlocklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The blocklist created time.
  --expirationTime: string # The blocklist expiration time. (format: date-time)
  type: string@type-completer # The blocklist type.
  --updatedTime: any # The blocklist updated time.
  value: string # The blocklist value.
]: any -> record<_links: table<rel: string>, createdTime: record, expirationTime: string, id: record, type: string, updatedTime: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocklists")
  let body = {createdTime: $createdTime, expirationTime: $expirationTime, type: $type, updatedTime: $updatedTime, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a blocklist
#
# DELETE /blocklists/{id}
# operationId: DeleteBlocklist
export def "blocklists DeleteBlocklist" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/blocklists/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a blocklist
#
# GET /blocklists/{id}
# operationId: GetBlocklist
export def "blocklists GetBlocklist" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, createdTime: record, expirationTime: string, id: record, type: string, updatedTime: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/blocklists/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a blocklist with predefined ID
#
# PUT /blocklists/{id}
# operationId: PutBlocklist
# --_links item shape: {rel: "self", href: string}
export def "blocklists PutBlocklist" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The blocklist created time.
  --expirationTime: string # The blocklist expiration time. (format: date-time)
  type: string@type-completer # The blocklist type.
  --updatedTime: any # The blocklist updated time.
  value: string # The blocklist value.
]: any -> record<_links: table<rel: string>, createdTime: record, expirationTime: string, id: record, type: string, updatedTime: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/blocklists/($id)")
  let body = {createdTime: $createdTime, expirationTime: $expirationTime, type: $type, updatedTime: $updatedTime, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of coupons
#
# GET /coupons
# operationId: GetCouponCollection
export def "coupons GetCouponCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<record>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: list<record>, status: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/coupons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a coupon
#
# POST /coupons
# operationId: PostCoupon
# --_links item shape: {rel: "self", href: string}
# --discount shape: {type: "fixed"|"percent"}
# --restrictions item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
export def "coupons PostCoupon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Coupon created time.
  --description: string # Your coupon description. When it is not empty this is used for invoice discount item description, otherwise the item's description uses coupon's ID like 'Coupon "COUPON-ID"'.
  discount: record # shape: {type: "fixed"|"percent"}
  --expiredTime: string # Coupon's expire time (end time). (format: date-time)
  issuedTime: string # Coupon's issued time (start time). (format: date-time)
  --restrictions: list # Coupon restrictions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
  --updatedTime: any # Coupon updated time.
]: any -> record<_links: table<rel: string>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coupons")
  let body = {createdTime: $createdTime, description: $description, discount: $discount, expiredTime: $expiredTime, issuedTime: $issuedTime, restrictions: $restrictions, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of coupon redemptions
#
# GET /coupons-redemptions
# operationId: GetCouponRedemptionCollection
export def "coupons-redemptions GetCouponRedemptionCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<record>, additionalRestrictions: list<record>, canceledTime: record, couponId: record, createdTime: record, customerId: record, id: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/coupons-redemptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeem a coupon
#
# POST /coupons-redemptions
# operationId: PostCouponRedemption
# --_links item shape: {rel: "self", href: string}
# --additionalRestrictions item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"}
export def "coupons-redemptions PostCouponRedemption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --additionalRestrictions: list # Additional restrictions for coupon's redemptions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"}
  --couponId: any # Coupon's ID.
  --customerId: any # Customer's ID.
]: any -> record<_links: table<rel: string>, additionalRestrictions: table<type: string>, canceledTime: record, couponId: record, createdTime: record, customerId: record, id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coupons-redemptions")
  let body = {additionalRestrictions: $additionalRestrictions, couponId: $couponId, customerId: $customerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a coupon redemption with specified identifier string
#
# GET /coupons-redemptions/{id}
# operationId: GetCouponRedemption
export def "coupons-redemptions GetCouponRedemption" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, additionalRestrictions: table<type: string>, canceledTime: record, couponId: record, createdTime: record, customerId: record, id: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons-redemptions/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a coupon redemption
#
# POST /coupons-redemptions/{id}/cancel
# operationId: PostCouponRedemptionCancellation
export def "coupons-redemptions-cancel PostCouponRedemptionCancellation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons-redemptions/($id)/cancel")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a coupon
#
# GET /coupons/{id}
# operationId: GetCoupon
export def "coupons GetCoupon" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a coupon with predefined coupon ID
#
# PUT /coupons/{id}
# operationId: PutCoupon
# --_links item shape: {rel: "self", href: string}
# --discount shape: {type: "fixed"|"percent"}
# --restrictions item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
export def "coupons PutCoupon" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Coupon created time.
  --description: string # Your coupon description. When it is not empty this is used for invoice discount item description, otherwise the item's description uses coupon's ID like 'Coupon "COUPON-ID"'.
  discount: record # shape: {type: "fixed"|"percent"}
  --expiredTime: string # Coupon's expire time (end time). (format: date-time)
  issuedTime: string # Coupon's issued time (start time). (format: date-time)
  --restrictions: list # Coupon restrictions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
  --updatedTime: any # Coupon updated time.
]: any -> record<_links: table<rel: string>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($id)")
  let body = {createdTime: $createdTime, description: $description, discount: $discount, expiredTime: $expiredTime, issuedTime: $issuedTime, restrictions: $restrictions, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set a coupon's expiration time
#
# POST /coupons/{id}/expiration
# operationId: PostCouponExpiration
export def "coupons-expiration PostCouponExpiration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  expiredTime: string # The coupon's expiry time, must be greater than the issued time. Null or empty string will immediately expire the coupon. (format: date-time)
]: any -> record<_links: table<rel: string>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coupons/($id)/expiration")
  let body = {expiredTime: $expiredTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of credentials
#
# GET /credentials
# operationId: GetCredentialCollection
export def "credentials GetCredentialCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<any>, customerId: string, expiredTime: string, id: record, password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a credential
#
# POST /credentials
# operationId: PostCredential
export def "credentials PostCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customerId: string # The credential's customer ID.
  --expiredTime: string # The credential's expired time. (format: date-time)
  password: string # The credential's password. (format: password)
  username: string # Credential's username.
]: any -> record<_links: list<any>, customerId: string, expiredTime: string, id: record, password: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credentials")
  let body = {customerId: $customerId, expiredTime: $expiredTime, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a credential
#
# DELETE /credentials/{id}
# operationId: DeleteCredential
export def "credentials DeleteCredential" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a credential
#
# GET /credentials/{id}
# operationId: GetCredential
export def "credentials GetCredential" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: list<any>, customerId: string, expiredTime: string, id: record, password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a credential with predefined ID
#
# PUT /credentials/{id}
# operationId: PutCredential
export def "credentials PutCredential" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customerId: string # The credential's customer ID.
  --expiredTime: string # The credential's expired time. (format: date-time)
  password: string # The credential's password. (format: password)
  username: string # Credential's username.
]: any -> record<_links: list<any>, customerId: string, expiredTime: string, id: record, password: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/($id)")
  let body = {customerId: $customerId, expiredTime: $expiredTime, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Custom Fields
#
# GET /custom-fields/{resource}
# operationId: GetCustomFieldCollection
export def "custom-fields GetCustomFieldCollection" [
  resource: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<record>, additionalSchema: any, description: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-fields/($resource)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Custom Field
#
# GET /custom-fields/{resource}/{name}
# operationId: GetCustomField
export def "custom-fields GetCustomField" [
  resource: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, additionalSchema: any, description: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-fields/($resource)/($name)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or alter a Custom Field
#
# PUT /custom-fields/{resource}/{name}
# operationId: PutCustomField
# --_links item shape: {rel: "self", href: string}
export def "custom-fields PutCustomField" [
  resource: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --additionalSchema: any # Additional parameters which can be added according to type: Parameter Name | Types         | Description -------------- | ------------- | ------------- allowedValues  | string, array | List of allowed values maxLength      | string        | Maximum allowed length for the string, 255 by default, up to 4000 The additional schema adds additional constrains for values.
  --description: string # The custom field description.
  type: string@type-completer-1 # Type value    | Description ------------- | ------------- array         | An array of strings up to 255 characters, maximum size is 1000 elements boolean       | true or false date          | String of format "full-date" (YYYY-MM-DD) from RFC-3339 (full-date) datetime      | String of format "date-time" (YYYY-MM-DDTHH:MM:SSZ) from RFC-3339 (date-time) integer       | Cardinal value of -2^31..2^31-1 number        | Float value. It can take cardinal values also which are interpreted as float string        | Regular string up to 255 characters monetary      | A map of 3-letters currency code and amount, e.g. {"currency": "EUR", "amount": 25.30} The type cannot be changed.
]: any -> record<_links: table<rel: string>, additionalSchema: any, description: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-fields/($resource)/($name)")
  let body = {additionalSchema: $additionalSchema, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of customer timeline custom event types
#
# GET /customer-timeline-custom-events
# operationId: GetCustomerTimelineCustomEventTypeCollection
export def "customer-timeline-custom-events GetCustomerTimelineCustomEventTypeCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
]: nothing -> table<_links: list<record>, createdTime: record, id: record, name: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer-timeline-custom-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Customer Timeline custom event type
#
# POST /customer-timeline-custom-events
# operationId: PostCustomerTimelineCustomEventType
# --_links item shape: {rel: "self", href: string}
export def "customer-timeline-custom-events PostCustomerTimelineCustomEventType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Customer Timeline Custom event created time.
  name: string # Customer Timeline Custom Event type name. It must not be similar to any Rebilly system event.
  --updatedTime: any # Customer Timeline Custom event updated time.
]: any -> record<_links: table<rel: string>, createdTime: record, id: record, name: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer-timeline-custom-events")
  let body = {createdTime: $createdTime, name: $name, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve customer timeline custom event type with specified identifier string
#
# GET /customer-timeline-custom-events/{id}
# operationId: GetCustomerTimelineCustomEventType
export def "customer-timeline-custom-events GetCustomerTimelineCustomEventType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, createdTime: record, id: record, name: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer-timeline-custom-events/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of customer timeline messages for all customers
#
# GET /customer-timeline-events
# operationId: GetCustomerTimelineEventCollection
export def "customer-timeline-events GetCustomerTimelineEventCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
]: nothing -> table<_links: list<record>, customData: record, customEventType: string, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer-timeline-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of customers
#
# GET /customers
# operationId: GetCustomerCollection
export def "customers GetCustomerCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --qp-fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: record>, createdTime: record, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: record, invoiceCount: int, lastName: string, lastPaymentTime: record, lifetimeRevenue: record<amount: float, amountUsd: float, currency: record>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, revision: int, tags: list<record>, updatedTime: record, websiteId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a customer (without an ID)
#
# POST /customers
# operationId: PostCustomer
# --averageValue shape: {amount?: float, amountUsd?: float, currency?: any}
# --defaultPaymentInstrument shape: {method?: "payment-card"|"ach"|"paypal", paymentInstrumentId?: any, receivedBy?: string, reference?: string}
# --lifetimeRevenue shape: {amount?: float, amountUsd?: float, currency?: any}
# --primaryAddress shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
# --tags item shape: {createdTime?: any, name: string, updatedTime?: any}
export def "customers PostCustomer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The customer created time.
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --defaultPaymentInstrument: record # shape: {method?: "payment-card"|"ach"|"paypal", paymentInstrumentId?: any, receivedBy?: string, reference?: string}
  --lastPaymentTime: any # The most recent time of an approved payment for the customer.
  --paymentToken: string # A write-only payment token; if supplied, it will be converted into a payment instrument and be set as the `defaultPaymentInstrument`. The value of this property will override the `defaultPaymentInstrument` in the case that both are supplied. The token may only be used once before it is expired.
  --primaryAddress: record # shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --updatedTime: any # The customer updated time.
  --websiteId: any # The website's ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers")
  let body = {createdTime: $createdTime, customFields: $customFields, defaultPaymentInstrument: $defaultPaymentInstrument, lastPaymentTime: $lastPaymentTime, paymentToken: $paymentToken, primaryAddress: $primaryAddress, updatedTime: $updatedTime, websiteId: $websiteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge and delete a customer
#
# DELETE /customers/{id}
# operationId: DeleteCustomer
export def "customers DeleteCustomer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetCustomerId: string # The customer identifier to get the data of the deleted duplicate customer.
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetCustomerId" $targetCustomerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($id)" $qp)
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a customer
#
# GET /customers/{id}
# operationId: GetCustomer
export def "customers GetCustomer" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --qp-fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
]: nothing -> record<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: record>, createdTime: record, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: record, invoiceCount: int, lastName: string, lastPaymentTime: record, lifetimeRevenue: record<amount: float, amountUsd: float, currency: record>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, revision: int, tags: table<_links: list, createdTime: record, id: record, name: string, updatedTime: record>, updatedTime: record, websiteId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert a customer with predefined ID
#
# PUT /customers/{id}
# operationId: PutCustomer
# --averageValue shape: {amount?: float, amountUsd?: float, currency?: any}
# --defaultPaymentInstrument shape: {method?: "payment-card"|"ach"|"paypal", paymentInstrumentId?: any, receivedBy?: string, reference?: string}
# --lifetimeRevenue shape: {amount?: float, amountUsd?: float, currency?: any}
# --primaryAddress shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
# --tags item shape: {createdTime?: any, name: string, updatedTime?: any}
export def "customers PutCustomer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The customer created time.
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --defaultPaymentInstrument: record # shape: {method?: "payment-card"|"ach"|"paypal", paymentInstrumentId?: any, receivedBy?: string, reference?: string}
  --lastPaymentTime: any # The most recent time of an approved payment for the customer.
  --paymentToken: string # A write-only payment token; if supplied, it will be converted into a payment instrument and be set as the `defaultPaymentInstrument`. The value of this property will override the `defaultPaymentInstrument` in the case that both are supplied. The token may only be used once before it is expired.
  --primaryAddress: record # shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --updatedTime: any # The customer updated time.
  --websiteId: any # The website's ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)")
  let body = {createdTime: $createdTime, customFields: $customFields, defaultPaymentInstrument: $defaultPaymentInstrument, lastPaymentTime: $lastPaymentTime, paymentToken: $paymentToken, primaryAddress: $primaryAddress, updatedTime: $updatedTime, websiteId: $websiteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Lead Source for a customer
#
# DELETE /customers/{id}/lead-source
# operationId: DeleteCustomerLeadSource
export def "customers-lead-source DeleteCustomerLeadSource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)/lead-source")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a customer's Lead Source
#
# GET /customers/{id}/lead-source
# operationId: GetCustomerLeadSource
export def "customers-lead-source GetCustomerLeadSource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: record, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string, original: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: record, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)/lead-source")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Lead Source for a customer
#
# PUT /customers/{id}/lead-source
# operationId: PutCustomerLeadSource
export def "customers-lead-source PutCustomerLeadSource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --affiliate: string # Lead source affiliate (eg 123, Bob Smith).
  --campaign: string # Lead source campaign (eg go-big-123).
  --clickId: string # Lead source click id (may come from an ad server).
  --content: string # Lead source content (eg smiley faces).
  --createdTime: any # Lead source created time.
  --medium: string # Lead source medium (eg search, display).
  --path: string # Lead source path url (eg www.example.com/some/landing/path).
  --referrer: string # Lead source [`referer` url](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer) as determined (eg www.example.com/some/landing/path).
  --salesAgent: string # Lead source sales agent (eg James Bond).
  --body-source: string # Lead source origin (eg google, yahoo).
  --subAffiliate: string # Lead source sub-affiliate also called a sub-id or click id in some circles (eg 123456).
  --term: string # Lead source term (eg salt shakers).
]: any -> record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: record, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string, original: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: record, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)/lead-source")
  let body = {affiliate: $affiliate, campaign: $campaign, clickId: $clickId, content: $content, createdTime: $createdTime, medium: $medium, path: $path, referrer: $referrer, salesAgent: $salesAgent, source: $body_source, subAffiliate: $subAffiliate, term: $term} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of customer timeline messages
#
# GET /customers/{id}/timeline
# operationId: GetCustomerTimelineCollection
export def "customers-timeline GetCustomerTimelineCollection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, customData: record, customEventType: string, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($id)/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a customer Timeline comment or custom defined event
#
# POST /customers/{id}/timeline
# operationId: PostCustomerTimeline
# --_links item shape: {rel: "self", href: string}
# --extraData shape: {actions?: list, author?: record, links?: list, mentions?: record, tables?: list}
export def "customers-timeline PostCustomerTimeline" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customData: record # Timeline custom event data. Used with `custom-event` type. Will be transformed to `extraData` two-column table in response. (e.g. {customAttribute: customValue, otherAttribute: otherValue})
  --customEventType: string # Timeline custom event type. Used with `custom-event` type. Must be defined using [Customer Timeline custom event API](#operation/PostCustomerTimelineCustomEventType). (nullable)
  --message: string # The message that describes the message details.
  --occurredTime: any # Timeline message time.
  --type: string@type-completer-2 # Timeline message type.
]: any -> record<_links: table<rel: string>, customData: record, customEventType: string, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)/timeline")
  let body = {customData: $customData, customEventType: $customEventType, message: $message, occurredTime: $occurredTime, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Customer Timeline message
#
# DELETE /customers/{id}/timeline/{messageId}
# operationId: DeleteCustomerTimeline
export def "customers-timeline DeleteCustomerTimeline" [
  id: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)/timeline/($messageId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a customer Timeline message
#
# GET /customers/{id}/timeline/{messageId}
# operationId: GetCustomerTimeline
export def "customers-timeline GetCustomerTimeline" [
  id: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, customData: record, customEventType: string, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)/timeline/($messageId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve customer's upcoming invoices
#
# GET /customers/{id}/upcoming-invoices
# operationId: GetCustomerUpcomingInvoiceCollection
export def "customers-upcoming-invoices GetCustomerUpcomingInvoiceCollection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: list<record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($id)/upcoming-invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate a digital wallet session
#
# POST /digital-wallets/validation
# Discriminator (request): type = Apple Pay
# operationId: PostDigitalWalletValidation
export def "digital-wallets-validation PostDigitalWalletValidation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3 # Type of the digital wallet to validate.
]: any -> record<type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/digital-wallets/validation")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of disputes
#
# GET /disputes
# operationId: GetDisputeCollection
export def "disputes GetDisputeCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: record, currency: record, customerId: string, deadlineTime: string, id: record, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: record, status: string, transactionId: string, type: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/disputes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a dispute
#
# POST /disputes
# operationId: PostDispute
export def "disputes PostDispute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acquirerReferenceNumber: string # The dispute's acquirer reference number.
  amount: float # The dispute amount. (format: double)
  --caseId: string # The case ID for the dispute.
  --createdTime: any # Dispute created time.
  currency: any
  --deadlineTime: string # Dispute deadline time. (format: date-time)
  postedTime: string # Dispute posted time. (format: date-time)
  reasonCode: string@reasonCode-completer # The dispute's reason code.
  --resolvedTime: any # Dispute resolved time.
  status: string@status-completer # The dispute's status.
  transactionId: string # The dispute's transaction ID.
  type: string@type-completer-4 # The dispute's type.
  --updatedTime: any # Dispute updated time.
]: any -> record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: record, currency: record, customerId: string, deadlineTime: string, id: record, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: record, status: string, transactionId: string, type: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/disputes")
  let body = {acquirerReferenceNumber: $acquirerReferenceNumber, amount: $amount, caseId: $caseId, createdTime: $createdTime, currency: $currency, deadlineTime: $deadlineTime, postedTime: $postedTime, reasonCode: $reasonCode, resolvedTime: $resolvedTime, status: $status, transactionId: $transactionId, type: $type, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a dispute
#
# GET /disputes/{id}
# operationId: GetDispute
export def "disputes GetDispute" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: record, currency: record, customerId: string, deadlineTime: string, id: record, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: record, status: string, transactionId: string, type: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/disputes/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a Dispute with predefined ID
#
# PUT /disputes/{id}
# operationId: PutDispute
export def "disputes PutDispute" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acquirerReferenceNumber: string # The dispute's acquirer reference number.
  amount: float # The dispute amount. (format: double)
  --caseId: string # The case ID for the dispute.
  --createdTime: any # Dispute created time.
  currency: any
  --deadlineTime: string # Dispute deadline time. (format: date-time)
  postedTime: string # Dispute posted time. (format: date-time)
  reasonCode: string@reasonCode-completer # The dispute's reason code.
  --resolvedTime: any # Dispute resolved time.
  status: string@status-completer # The dispute's status.
  transactionId: string # The dispute's transaction ID.
  type: string@type-completer-4 # The dispute's type.
  --updatedTime: any # Dispute updated time.
]: any -> record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: record, currency: record, customerId: string, deadlineTime: string, id: record, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: record, status: string, transactionId: string, type: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/disputes/($id)")
  let body = {acquirerReferenceNumber: $acquirerReferenceNumber, amount: $amount, caseId: $caseId, createdTime: $createdTime, currency: $currency, deadlineTime: $deadlineTime, postedTime: $postedTime, reasonCode: $reasonCode, resolvedTime: $resolvedTime, status: $status, transactionId: $transactionId, type: $type, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of files
#
# GET /files
# operationId: GetFileCollection
export def "files GetFileCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --qp-fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<any>, createdTime: record, description: string, extension: string, height: int, id: record, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: record, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a file
#
# POST /files
# operationId: PostFile
export def "files PostFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --description: string # The file description. (e.g. My file description)
  --file: string # The file in base64 encoded format. (e.g. R0lGODlhAQABAIAAAAUEBAAAACwAAAAAAQABAAACAkQBADs=)
  --isPublic: string@bool-completer # The File visibility. If public a permalink is provided. (e.g. false)
  --name: string # The file name used for downloading. (e.g. logo.png)
  --tags: list # The tags list. (e.g. [test, tags])
  --body-url: string # The URL of the file to upload. (e.g. https://blog.rebilly.com/wp-content/uploads/2017/09/rb_LogoInverted_Small.png)
]: any -> record<_links: list<any>, createdTime: record, description: string, extension: string, height: int, id: record, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: record, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let body = {description: $description, file: $file, isPublic: $isPublic, name: $name, tags: $tags, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a File
#
# DELETE /files/{id}
# operationId: DeleteFile
export def "files DeleteFile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a File Record
#
# GET /files/{id}
# operationId: GetFile
export def "files GetFile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: list<any>, createdTime: record, description: string, extension: string, height: int, id: record, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: record, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the File with predefined ID
#
# PUT /files/{id}
# operationId: PutFile
export def "files PutFile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The upload date/time.
  --description: string # The File description.
  --extension: string # The File extension.
  --isPublic: string@bool-completer # Is the file available publicly (without authentication). If true, the permalink in the _links section contains the public URL.
  --name: string # Original File name.
  --tags: list # The tags list.
  --updatedTime: any # The latest update date/time.
]: any -> record<_links: list<any>, createdTime: record, description: string, extension: string, height: int, id: record, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: record, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)")
  let body = {createdTime: $createdTime, description: $description, extension: $extension, isPublic: $isPublic, name: $name, tags: $tags, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download a file
#
# GET /files/{id}/download
# operationId: GetFileDownload
export def "files-download GetFileDownload" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imageSize: string # Resize image to specified size. Supports any sizes from 10x10 to 2000x2000 (format `{width}x{height}`). The image will be returned in the original size if the value is invalid. This parameter will be ignored for non-image files. (e.g. 700x700)
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageSize" $imageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($id)/download" $qp)
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download image in specific format
#
# GET /files/{id}/download{extension}
# operationId: GetFileDownloadExtension
export def "files-download-extension GetFileDownloadExtension" [
  id: string
  extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)/download($extension)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of invoices
#
# GET /invoices
# operationId: GetInvoiceCollection
export def "invoices GetInvoiceCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: list<record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invoice
#
# POST /invoices
# operationId: PostInvoice
# --discounts item shape: {amount?: float, couponId?: any, description?: string, redemptionId?: any}
# --items item shape: {createdTime?: any, description?: string, periodEndTime?: string, periodNumber?: int, periodStartTime?: string, productId?: any, quantity?: int, type: "debit"|"credit", unitPrice: float, updatedTime?: any}
# --shipping shape: {calculator: "manual"|"rebilly"}
# --tax shape: {amount?: int, calculator: "manual"|"rebilly"}
# --retryInstruction shape: {afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list}
# --transactions item shape: {3ds?: any, billingAddress?: any, createdTime?: any, customFields?: record, customerId?: any, description?: string, paymentInstrument?: record, processedTime?: any, redirectUrl?: string, requestId?: string, updatedTime?: any, isMerchantInitiated?: bool, isProcessedOutside?: bool, method?: any, notificationUrl?: string, orderId?: string, retryInstruction?: record, riskMetadata?: any, scheduledTime?: string, velocity?: int}
export def "invoices PostInvoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --abandonedTime: any # Invoice abandoned time.
  --autopayScheduledTime: string # Invoice autopay scheduled time. (format: date-time)
  --billingAddress: any # Invoice's billing address.
  --createdTime: any # Invoice created time.
  currency: any
  --deliveryAddress: any # Invoice's delivery address.
  --dueTime: any # Invoice due time.
  --issuedTime: any # Invoice issued time.
  --notes: string # Notes for the customer which will be displayed on the invoice.
  --paidTime: any # Invoice paid time.
  --poNumber: string # Purchase order number which will be displayed on the invoice. (nullable, e.g. PO123456)
  --shipping: record # Invoice shipping. — shape: {calculator: "manual"|"rebilly"}
  --tax: record # Invoice taxes. — shape: {amount?: int, calculator: "manual"|"rebilly"}
  --updatedTime: any # Invoice updated time.
  --voidedTime: any # Invoice voided time.
  websiteId: any # The website ID.
  customerId: any # The сustomer's ID.
  --dueReminderTime: any # Time past due reminder event will be triggered. (nullable)
  --retryInstruction: record # The invoice retry instruction. — shape: {afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list}
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoices")
  let body = {abandonedTime: $abandonedTime, autopayScheduledTime: $autopayScheduledTime, billingAddress: $billingAddress, createdTime: $createdTime, currency: $currency, deliveryAddress: $deliveryAddress, dueTime: $dueTime, issuedTime: $issuedTime, notes: $notes, paidTime: $paidTime, poNumber: $poNumber, shipping: $shipping, tax: $tax, updatedTime: $updatedTime, voidedTime: $voidedTime, websiteId: $websiteId, customerId: $customerId, dueReminderTime: $dueReminderTime, retryInstruction: $retryInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an invoice
#
# GET /invoices/{id}
# operationId: GetInvoice
export def "invoices GetInvoice" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --Accept: string@Accept-completer # The response media type.
]: nothing -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invoices/($id)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update an invoice with predefined ID
#
# PUT /invoices/{id}
# operationId: PutInvoice
# --discounts item shape: {amount?: float, couponId?: any, description?: string, redemptionId?: any}
# --items item shape: {createdTime?: any, description?: string, periodEndTime?: string, periodNumber?: int, periodStartTime?: string, productId?: any, quantity?: int, type: "debit"|"credit", unitPrice: float, updatedTime?: any}
# --shipping shape: {calculator: "manual"|"rebilly"}
# --tax shape: {amount?: int, calculator: "manual"|"rebilly"}
# --retryInstruction shape: {afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list}
# --transactions item shape: {3ds?: any, billingAddress?: any, createdTime?: any, customFields?: record, customerId?: any, description?: string, paymentInstrument?: record, processedTime?: any, redirectUrl?: string, requestId?: string, updatedTime?: any, isMerchantInitiated?: bool, isProcessedOutside?: bool, method?: any, notificationUrl?: string, orderId?: string, retryInstruction?: record, riskMetadata?: any, scheduledTime?: string, velocity?: int}
export def "invoices PutInvoice" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --abandonedTime: any # Invoice abandoned time.
  --autopayScheduledTime: string # Invoice autopay scheduled time. (format: date-time)
  --billingAddress: any # Invoice's billing address.
  --createdTime: any # Invoice created time.
  currency: any
  --deliveryAddress: any # Invoice's delivery address.
  --dueTime: any # Invoice due time.
  --issuedTime: any # Invoice issued time.
  --notes: string # Notes for the customer which will be displayed on the invoice.
  --paidTime: any # Invoice paid time.
  --poNumber: string # Purchase order number which will be displayed on the invoice. (nullable, e.g. PO123456)
  --shipping: record # Invoice shipping. — shape: {calculator: "manual"|"rebilly"}
  --tax: record # Invoice taxes. — shape: {amount?: int, calculator: "manual"|"rebilly"}
  --updatedTime: any # Invoice updated time.
  --voidedTime: any # Invoice voided time.
  websiteId: any # The website ID.
  customerId: any # The сustomer's ID.
  --dueReminderTime: any # Time past due reminder event will be triggered. (nullable)
  --retryInstruction: record # The invoice retry instruction. — shape: {afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list}
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)")
  let body = {abandonedTime: $abandonedTime, autopayScheduledTime: $autopayScheduledTime, billingAddress: $billingAddress, createdTime: $createdTime, currency: $currency, deliveryAddress: $deliveryAddress, dueTime: $dueTime, issuedTime: $issuedTime, notes: $notes, paidTime: $paidTime, poNumber: $poNumber, shipping: $shipping, tax: $tax, updatedTime: $updatedTime, voidedTime: $voidedTime, websiteId: $websiteId, customerId: $customerId, dueReminderTime: $dueReminderTime, retryInstruction: $retryInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Abandon an invoice
#
# POST /invoices/{id}/abandon
# operationId: PostInvoiceAbandonment
export def "invoices-abandon PostInvoiceAbandonment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/abandon")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issue an invoice
#
# POST /invoices/{id}/issue
# operationId: PostInvoiceIssuance
export def "invoices-issue PostInvoiceIssuance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --dueTime: string # Invoice due time. Will be set same as `issuedTime` if `null` or omitted. (nullable, format: date-time)
  --issuedTime: string # Invoice issued time. Will be issued immediately if `null` or omitted. (nullable, format: date-time)
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/issue")
  let body = {dueTime: $dueTime, issuedTime: $issuedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve invoice items
#
# GET /invoices/{id}/items
# operationId: GetInvoiceItemCollection
export def "invoices-items GetInvoiceItemCollection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invoices/($id)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invoice item
#
# POST /invoices/{id}/items
# operationId: PostInvoiceItem
export def "invoices-items PostInvoiceItem" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Invoice item created time.
  --description: string # Invoice item's description.
  --periodEndTime: string # End time. (format: date-time)
  --periodNumber: int # Invoice item subscription order period number.
  --periodStartTime: string # Start time. (format: date-time)
  --productId: any # The product's ID.
  --quantity: int # Invoice item's quantity.
  type: string@type-completer-5 # Invoice item's type.
  unitPrice: float # Invoice item's price. (format: double)
  --updatedTime: any # Invoice item updated time.
]: any -> record<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/items")
  let body = {createdTime: $createdTime, description: $description, periodEndTime: $periodEndTime, periodNumber: $periodNumber, periodStartTime: $periodStartTime, productId: $productId, quantity: $quantity, type: $type, unitPrice: $unitPrice, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recalculate an invoice
#
# POST /invoices/{id}/recalculate
# operationId: PostInvoiceRecalculation
export def "invoices-recalculate PostInvoiceRecalculation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/recalculate")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reissue an invoice
#
# POST /invoices/{id}/reissue
# operationId: PostInvoiceReissuance
export def "invoices-reissue PostInvoiceReissuance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --dueTime: string # Invoice due time. Will be set as current date-time if `null` or omitted. (nullable, format: date-time)
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/reissue")
  let body = {dueTime: $dueTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of invoice timeline messages
#
# GET /invoices/{id}/timeline
# operationId: GetInvoiceTimelineCollection
export def "invoices-timeline GetInvoiceTimelineCollection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invoices/($id)/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invoice Timeline comment
#
# POST /invoices/{id}/timeline
# operationId: PostInvoiceTimeline
# --_links item shape: {rel: "self", href: string}
# --extraData shape: {actions?: list, author?: record, links?: list, mentions?: record, tables?: list}
export def "invoices-timeline PostInvoiceTimeline" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/timeline")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Invoice Timeline message
#
# DELETE /invoices/{id}/timeline/{messageId}
# operationId: DeleteInvoiceTimeline
export def "invoices-timeline DeleteInvoiceTimeline" [
  id: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/timeline/($messageId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an Invoice Timeline message
#
# GET /invoices/{id}/timeline/{messageId}
# operationId: GetInvoiceTimeline
export def "invoices-timeline GetInvoiceTimeline" [
  id: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/timeline/($messageId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply a transaction to an invoice
#
# POST /invoices/{id}/transaction
# operationId: PostInvoiceTransaction
export def "invoices-transaction PostInvoiceTransaction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --amount: float # Amount which needs to be applied to the invoice. Can't be more than the transaction's amount. If omitted, the lesser of the transaction's unused amount or the invoice's amount due will be used.  (format: double)
  transactionId: string # Transaction to be applied to the invoice.
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/transaction")
  let body = {amount: $amount, transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get transaction amounts allocated to an invoice
#
# GET /invoices/{id}/transaction-allocations
# operationId: GetInvoiceTransactionAllocationCollection
export def "invoices-transaction-allocations GetInvoiceTransactionAllocationCollection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<any>, amount: float, currency: record, invoiceId: string, transactionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invoices/($id)/transaction-allocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Void an invoice
#
# POST /invoices/{id}/void
# operationId: PostInvoiceVoid
export def "invoices-void PostInvoiceVoid" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoices/($id)/void")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of KYC documents
#
# GET /kyc-documents
# operationId: GetKycDocumentCollection
export def "kyc-documents GetKycDocumentCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/kyc-documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a KYC Document
#
# POST /kyc-documents
# Discriminator (request): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocument
export def "kyc-documents PostKycDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kyc-documents")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a KYC Document
#
# GET /kyc-documents/{id}
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: GetKycDocument
export def "kyc-documents GetKycDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-documents/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a KYC document with predefined ID
#
# PUT /kyc-documents/{id}
# Discriminator (request): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PutKycDocument
export def "kyc-documents PutKycDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-documents/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Accept a KYC document
#
# POST /kyc-documents/{id}/acceptance
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentAcceptance
export def "kyc-documents-acceptance PostKycDocumentAcceptance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-documents/($id)/acceptance")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a KYC document's documentMatches
#
# POST /kyc-documents/{id}/matches
# operationId: PostKycDocumentMatches
export def "kyc-documents-matches PostKycDocumentMatches" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --containsImage: string@bool-completer # Flag that indicates if there is an image that contains a face on it. (e.g. true)
  --dateOfBirth: string # The date of birth found on the document, null if not found. (format: date-time)
  --expiryDate: string # The expiry date found on the document, null if not found. (format: date-time)
  --firstName: string # The customer first name if it was matched, null otherwise. (e.g. John)
  --isIdentityDocument: string@bool-completer # Flag that indicates if this looks like and ID. (e.g. true)
  --isPublishedOnline: string@bool-completer # If there is an exact match found online. (e.g. false)
  --issueDate: string # The issued date found on the document, null if not found. (format: date-time)
  --lastName: string # The customer last name if it was matched, null otherwise. (e.g. Doe)
  --nationality: string # The nationality found on the document, null otherwise. (e.g. US)
  --city: string # The customer city if it was matched, null otherwise. (e.g. London)
  --date: string # The date on the document proving the document is recent. (format: date, e.g. 2021-01-01T00:00:00.000Z)
  --line1: string # The customer address if it was matched, null otherwise. (e.g. 36 Craven St)
  --phone: string # The phone of the company or agency that sent the document. (e.g. (123) 456-7890)
  --postalCode: string # The customer postal code if it was matched, null otherwise. (e.g. WC2N 5NF)
  --region: string # The customer region if it was matched, null otherwise. (e.g. London)
  --uniqueWords: int # The number of unique words in the document. (e.g. 175)
  --wordCount: int # The number of words in the document. (e.g. 350)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-documents/($id)/matches")
  let body = {containsImage: $containsImage, dateOfBirth: $dateOfBirth, expiryDate: $expiryDate, firstName: $firstName, isIdentityDocument: $isIdentityDocument, isPublishedOnline: $isPublishedOnline, issueDate: $issueDate, lastName: $lastName, nationality: $nationality, city: $city, date: $date, line1: $line1, phone: $phone, postalCode: $postalCode, region: $region, uniqueWords: $uniqueWords, wordCount: $wordCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reject a KYC document
#
# POST /kyc-documents/{id}/rejection
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentRejection
export def "kyc-documents-rejection PostKycDocumentRejection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The rejection message. (e.g. Provided document is unreadable)
  --type: string@type-completer-6
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-documents/($id)/rejection")
  let body = {message: $message, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Review a KYC document
#
# POST /kyc-documents/{id}/review
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentReview
export def "kyc-documents-review PostKycDocumentReview" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-documents/($id)/review")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of KYC requests
#
# GET /kyc-requests
# operationId: GetKycRequestCollection
export def "kyc-requests GetKycRequestCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<createdTime: record, documents: list<record>, expirationTime: string, id: record, redirectUrl: string, updatedTime: record, _links: list<any>, customerId: record, matchLevel: int, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/kyc-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a KYC Request
#
# POST /kyc-requests
# operationId: PostKycRequest
# --documents item shape: {maxAttempts?: int, subtypes?: list, type: any}
export def "kyc-requests PostKycRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Creation date/time.
  documents: list # Documents to be requested from customer. — item shape: {maxAttempts?: int, subtypes?: list, type: any}
  --expirationTime: string # Expiration date/time. (format: date-time)
  --redirectUrl: string # The URL to redirect the customer when an upload is completed. (format: uri)
  --updatedTime: any # Latest update date/time.
  customerId: any # The сustomer's ID.
  --matchLevel: int # The level of strictness for the document matches. (e.g. 2)
  --reason: string # Reason for uploading.
]: any -> record<createdTime: record, documents: table<maxAttempts: int, subtypes: list, type: record>, expirationTime: string, id: record, redirectUrl: string, updatedTime: record, _links: list<any>, customerId: record, matchLevel: int, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kyc-requests")
  let body = {createdTime: $createdTime, documents: $documents, expirationTime: $expirationTime, redirectUrl: $redirectUrl, updatedTime: $updatedTime, customerId: $customerId, matchLevel: $matchLevel, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the KYC request
#
# DELETE /kyc-requests/{id}
# operationId: DeleteKycRequest
export def "kyc-requests DeleteKycRequest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-requests/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a KYC request
#
# GET /kyc-requests/{id}
# operationId: GetKycRequest
export def "kyc-requests GetKycRequest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<createdTime: record, documents: table<maxAttempts: int, subtypes: list, type: record>, expirationTime: string, id: record, redirectUrl: string, updatedTime: record, _links: list<any>, customerId: record, matchLevel: int, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-requests/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a KYC request
#
# PATCH /kyc-requests/{id}
# operationId: PatchKycRequest
export def "kyc-requests PatchKycRequest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --body: record
]: any -> record<createdTime: record, documents: table<maxAttempts: int, subtypes: list, type: record>, expirationTime: string, id: record, redirectUrl: string, updatedTime: record, _links: list<any>, customerId: record, matchLevel: int, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kyc-requests/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of tokens
#
# GET /password-tokens
# operationId: GetPasswordTokenCollection
export def "password-tokens GetPasswordTokenCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<record>, credentialId: string, expiredTime: string, token: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/password-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Reset Password Token
#
# POST /password-tokens
# operationId: PostPasswordToken
# --_links item shape: {rel: "self", href: string}
export def "password-tokens PostPasswordToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --expiredTime: string # Password expired time. (format: date-time)
  username: string # The token's username.
]: any -> record<_links: table<rel: string>, credentialId: string, expiredTime: string, token: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/password-tokens")
  let body = {expiredTime: $expiredTime, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Reset Password Token
#
# DELETE /password-tokens/{id}
# operationId: DeletePasswordToken
export def "password-tokens DeletePasswordToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/password-tokens/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Reset Password Token
#
# GET /password-tokens/{id}
# operationId: GetPasswordToken
export def "password-tokens GetPasswordToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, credentialId: string, expiredTime: string, token: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/password-tokens/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of Payment Cards
#
# GET /payment-cards
# operationId: GetPaymentCardCollection
export def "payment-cards GetPaymentCardCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment-cards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Payment Card
#
# POST /payment-cards
# operationId: PostPaymentCard
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "payment-cards PostPaymentCard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --customerId: any # The Customer's ID.
  --body-token: string # PaymentCardToken ID.
  --billingAddress: any # The billing address.
  --cvv: string # Card's cvv (card verification value).
  --expMonth: int # Card's expiration month.
  --expYear: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --riskMetadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
]: any -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment-cards")
  let body = {customFields: $customFields, customerId: $customerId, token: $body_token, billingAddress: $billingAddress, cvv: $cvv, expMonth: $expMonth, expYear: $expYear, method: $method, pan: $pan, riskMetadata: $riskMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Payment Card
#
# GET /payment-cards/{id}
# operationId: GetPaymentCard
export def "payment-cards GetPaymentCard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment-cards/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a payment card's values
#
# PATCH /payment-cards/{id}
# operationId: PatchPaymentCard
export def "payment-cards PatchPaymentCard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billingAddress: any # The billing address.
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --cvv: string # Card's cvv (card verification value).
  --expMonth: int # Card's expiration month.
  --expYear: int # Card's expiration year.
  --stickyGatewayAccountId: any # Sticky gateway account ID.
]: any -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment-cards/($id)")
  let body = {billingAddress: $billingAddress, customFields: $customFields, cvv: $cvv, expMonth: $expMonth, expYear: $expYear, stickyGatewayAccountId: $stickyGatewayAccountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a payment card with predefined ID
#
# PUT /payment-cards/{id}
# operationId: PutPaymentCard
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "payment-cards PutPaymentCard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --customerId: any # The Customer's ID.
  --body-token: string # PaymentCardToken ID.
  --billingAddress: any # The billing address.
  --cvv: string # Card's cvv (card verification value).
  --expMonth: int # Card's expiration month.
  --expYear: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --riskMetadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
]: any -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment-cards/($id)")
  let body = {customFields: $customFields, customerId: $customerId, token: $body_token, billingAddress: $billingAddress, cvv: $cvv, expMonth: $expMonth, expYear: $expYear, method: $method, pan: $pan, riskMetadata: $riskMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate a Payment Card
#
# POST /payment-cards/{id}/deactivation
# operationId: PostPaymentCardDeactivation
export def "payment-cards-deactivation PostPaymentCardDeactivation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment-cards/($id)/deactivation")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of payment instruments
#
# GET /payment-instruments
# operationId: GetPaymentInstrumentCollection
export def "payment-instruments GetPaymentInstrumentCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment-instruments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Payment Instrument
#
# POST /payment-instruments
# operationId: PostPaymentInstrument
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "payment-instruments PostPaymentInstrument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --customerId: any # The customer's ID.
  --body-token: string # Payment token ID.
  --billingAddress: any # The billing address.
  --cvv: string # Card's cvv (card verification value).
  --expMonth: int # Card's expiration month.
  --expYear: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --riskMetadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment-instruments")
  let body = {customFields: $customFields, customerId: $customerId, token: $body_token, billingAddress: $billingAddress, cvv: $cvv, expMonth: $expMonth, expYear: $expYear, method: $method, pan: $pan, riskMetadata: $riskMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Payment Instrument
#
# GET /payment-instruments/{id}
# operationId: GetPaymentInstrument
export def "payment-instruments GetPaymentInstrument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment-instruments/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Payment Instrument's values
#
# PATCH /payment-instruments/{id}
# operationId: PatchPaymentInstrument
export def "payment-instruments PatchPaymentInstrument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billingAddress: any # The billing address (if supplied – overrides billing address from token).
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --body-token: string # Payment token ID.
  --cvv: string # Card's cvv (card verification value).
  --expMonth: int # Card's expiration month.
  --expYear: int # Card's expiration year.
  --stickyGatewayAccountId: any # Sticky gateway account ID.
  --accountType: string@accountType-completer # Bank's account type.
  --bankName: string # Bank's name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment-instruments/($id)")
  let body = {billingAddress: $billingAddress, customFields: $customFields, token: $body_token, cvv: $cvv, expMonth: $expMonth, expYear: $expYear, stickyGatewayAccountId: $stickyGatewayAccountId, accountType: $accountType, bankName: $bankName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate a payment instrument
#
# POST /payment-instruments/{id}/deactivation
# operationId: PostPaymentInstrumentDeactivation
export def "payment-instruments-deactivation PostPaymentInstrumentDeactivation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment-instruments/($id)/deactivation")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a credit transaction
#
# POST /payouts
# operationId: PostPayout
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
@deprecated --flag paymentInstrument
export def "payouts PostPayout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # The transaction amount. (format: double, e.g. 97.97)
  --billingAddress: any # Billing address. If not supplied, we use the billing address associated with the payment instrument, and then customer. (nullable)
  currency: any
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  customerId: any # The customer identifier string.
  --description: string # The payment description. (nullable)
  --gatewayAccountId: any # Rebilly will select the appropriate payment gateway account for the transaction based on the properties of the transaction and the `gateway-account-requested` event rules configurations. If you wish to prevent Rebilly from making the gateway account selection, you may supply a gateway account id here, and it will be used instead. Only use this field if you intend to override the settings. (nullable)
  --invoiceIds: list # The array of invoice identifiers. (nullable)
  --isMerchantInitiated: string@bool-completer # True if the transaction was initiated by the merchant. (default: false)
  --isProcessedOutside: string@bool-completer # True if transaction was processed outside Rebilly. (default: false)
  --notificationUrl: string # The URL where a server-to-server notification request type `POST` with a transaction payload will be sent when the transaction's result is finalized. Do not trust the notification; follow with a `GET` request to confirm the result of the transaction. Please respond with a `2xx` HTTP status code, or we will reattempt the request again. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly.  (nullable, format: uri)
  --paymentInstruction: any # Payment instruction. If not supplied, customer's default payment instrument will be used.
  --paymentInstrument: any # DEPRECATED
  --processedTime: string # The time the transaction was processed. Can be specified only if transaction was processed outside Rebilly. (format: date-time)
  --redirectUrl: string # The URL to redirect the end-user when an offsite transaction is completed. Defaults to the website's configured URL. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --requestId: string # The request id is **recommended**. It prevents duplicate transaction requests within a short period of time. If a duplicate request is sent with the same `requestId` it will be ignored to prevent double-billing anyone.  It must be unique within a 24-hour period.  We recommend generating a UUID v4 as its value. (nullable, e.g. 44433322-2c4y-483z-a0a9-158621f77a21)
  --riskMetadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  websiteId: any # The website identifier string.
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payouts")
  let body = {amount: $amount, billingAddress: $billingAddress, currency: $currency, customFields: $customFields, customerId: $customerId, description: $description, gatewayAccountId: $gatewayAccountId, invoiceIds: $invoiceIds, isMerchantInitiated: $isMerchantInitiated, isProcessedOutside: $isProcessedOutside, notificationUrl: $notificationUrl, paymentInstruction: $paymentInstruction, paymentInstrument: $paymentInstrument, processedTime: $processedTime, redirectUrl: $redirectUrl, requestId: $requestId, riskMetadata: $riskMetadata, websiteId: $websiteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of PayPal accounts
#
# GET /paypal-accounts
# operationId: GetPayPalAccountCollection
export def "paypal-accounts GetPayPalAccountCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paypal-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a PayPal Account
#
# POST /paypal-accounts
# operationId: PostPayPalAccount
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "paypal-accounts PostPayPalAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  billingAddress: any # The billing address.
  --createdTime: any # PayPal account created time.
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  customerId: any # The customer's ID.
  method: string@method-completer-1 # The method of payment instrument.
  --riskMetadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  --updatedTime: any # PayPal account updated time.
]: any -> record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paypal-accounts")
  let body = {billingAddress: $billingAddress, createdTime: $createdTime, customFields: $customFields, customerId: $customerId, method: $method, riskMetadata: $riskMetadata, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a PayPal Account
#
# GET /paypal-accounts/{id}
# operationId: GetPayPalAccount
export def "paypal-accounts GetPayPalAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paypal-accounts/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a PayPal account with predefined ID
#
# PUT /paypal-accounts/{id}
# operationId: PutPayPalAccount
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "paypal-accounts PutPayPalAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  billingAddress: any # The billing address.
  --createdTime: any # PayPal account created time.
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  customerId: any # The customer's ID.
  method: string@method-completer-1 # The method of payment instrument.
  --riskMetadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  --updatedTime: any # PayPal account updated time.
]: any -> record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paypal-accounts/($id)")
  let body = {billingAddress: $billingAddress, createdTime: $createdTime, customFields: $customFields, customerId: $customerId, method: $method, riskMetadata: $riskMetadata, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate a PayPal Account
#
# POST /paypal-accounts/{id}/deactivation
# operationId: PostPayPalAccountDeactivation
export def "paypal-accounts-deactivation PostPayPalAccountDeactivation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paypal-accounts/($id)/deactivation")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of plans
#
# GET /plans
# operationId: GetPlanCollection
export def "plans GetPlanCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
]: nothing -> table<createdTime: record, currency: record, currencySign: string, customFields: record, id: record, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: record, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record, price: float>, updatedTime: record, _links: list<record>, invoiceTimeShift: record<dueTimeShift: record, issueTimeShift: record>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a plan
#
# POST /plans
# operationId: PostPlan
# --pricing shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
# --setup shape: {price: float}
# --trial shape: {period: record, price: float}
# --_links item shape: {rel: "self", href: string}
export def "plans PostPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Plan created time.
  currency: any
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  name: string # The plan name, displayed on invoices and receipts.
  pricing: record # shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
  productId: any # The related product ID.
  --productOptions: record # Name-value pairs to specify the product options. (e.g. {color: red, size: xxl})
  --recurringInterval: any # The service interval. For a one-time item, use `null`.
  --setup: record # The setup. Set `null` if no setup. — shape: {price: float}
  --trial: record # The trial. Set `null` if no trial. — shape: {period: record, price: float}
  --updatedTime: any # Plan updated time.
  --invoiceTimeShift: any # You can shift issue time and due time of invoices for this plan.
]: any -> record<createdTime: record, currency: record, currencySign: string, customFields: record, id: record, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: record, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: record, _links: table<rel: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/plans")
  let body = {createdTime: $createdTime, currency: $currency, customFields: $customFields, name: $name, pricing: $pricing, productId: $productId, productOptions: $productOptions, recurringInterval: $recurringInterval, setup: $setup, trial: $trial, updatedTime: $updatedTime, invoiceTimeShift: $invoiceTimeShift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Plan
#
# DELETE /plans/{id}
# operationId: DeletePlan
export def "plans DeletePlan" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a plan
#
# GET /plans/{id}
# operationId: GetPlan
export def "plans GetPlan" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<createdTime: record, currency: record, currencySign: string, customFields: record, id: record, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: record, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: record, _links: table<rel: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a Plan with predefined ID
#
# PUT /plans/{id}
# operationId: PutPlan
# --pricing shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
# --setup shape: {price: float}
# --trial shape: {period: record, price: float}
# --_links item shape: {rel: "self", href: string}
export def "plans PutPlan" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # Plan created time.
  currency: any
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  name: string # The plan name, displayed on invoices and receipts.
  pricing: record # shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
  productId: any # The related product ID.
  --productOptions: record # Name-value pairs to specify the product options. (e.g. {color: red, size: xxl})
  --recurringInterval: any # The service interval. For a one-time item, use `null`.
  --setup: record # The setup. Set `null` if no setup. — shape: {price: float}
  --trial: record # The trial. Set `null` if no trial. — shape: {period: record, price: float}
  --updatedTime: any # Plan updated time.
  --invoiceTimeShift: any # You can shift issue time and due time of invoices for this plan.
]: any -> record<createdTime: record, currency: record, currencySign: string, customFields: record, id: record, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: record, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: record, _links: table<rel: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plans/($id)")
  let body = {createdTime: $createdTime, currency: $currency, customFields: $customFields, name: $name, pricing: $pricing, productId: $productId, productOptions: $productOptions, recurringInterval: $recurringInterval, setup: $setup, trial: $trial, updatedTime: $updatedTime, invoiceTimeShift: $invoiceTimeShift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of products
#
# GET /products
# operationId: GetProductCollection
export def "products GetProductCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
]: nothing -> table<createdTime: record, customFields: record, description: string, id: record, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: record, _links: list<record>, accountingCode: string, taxCategoryId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Product
#
# POST /products
# operationId: PostProduct
# --_links item shape: {rel: "self", href: string}
export def "products PostProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The product created time.
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --description: string # The product description.
  name: string # The product name. (e.g. Premium membership)
  --options: list # The product options such as color, size, etc. The product options definition does not include option values. Those are defined within the plans.
  --requiresShipping: string@bool-completer # If the product requires shipping, shipping calculations will be applied. (e.g. false)
  --unitLabel: string # The unit label, such as per `seat` or per `unit`. (default: unit, e.g. seat)
  --updatedTime: any # The product updated time.
  --accountingCode: string # The product accounting code. (e.g. 4010)
  --taxCategoryId: string@taxCategoryId-completer # The product's tax category identifier string.
]: any -> record<createdTime: record, customFields: record, description: string, id: record, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: record, _links: table<rel: string>, accountingCode: string, taxCategoryId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products")
  let body = {createdTime: $createdTime, customFields: $customFields, description: $description, name: $name, options: $options, requiresShipping: $requiresShipping, unitLabel: $unitLabel, updatedTime: $updatedTime, accountingCode: $accountingCode, taxCategoryId: $taxCategoryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a product
#
# DELETE /products/{id}
# operationId: DeleteProduct
export def "products DeleteProduct" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a product
#
# GET /products/{id}
# operationId: GetProduct
export def "products GetProduct" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<createdTime: record, customFields: record, description: string, id: record, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: record, _links: table<rel: string>, accountingCode: string, taxCategoryId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a product with predefined ID
#
# PUT /products/{id}
# operationId: PutProduct
# --_links item shape: {rel: "self", href: string}
export def "products PutProduct" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The product created time.
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  --description: string # The product description.
  name: string # The product name. (e.g. Premium membership)
  --options: list # The product options such as color, size, etc. The product options definition does not include option values. Those are defined within the plans.
  --requiresShipping: string@bool-completer # If the product requires shipping, shipping calculations will be applied. (e.g. false)
  --unitLabel: string # The unit label, such as per `seat` or per `unit`. (default: unit, e.g. seat)
  --updatedTime: any # The product updated time.
  --accountingCode: string # The product accounting code. (e.g. 4010)
  --taxCategoryId: string@taxCategoryId-completer # The product's tax category identifier string.
]: any -> record<createdTime: record, customFields: record, description: string, id: record, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: record, _links: table<rel: string>, accountingCode: string, taxCategoryId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)")
  let body = {createdTime: $createdTime, customFields: $customFields, description: $description, name: $name, options: $options, requiresShipping: $requiresShipping, unitLabel: $unitLabel, updatedTime: $updatedTime, accountingCode: $accountingCode, taxCategoryId: $taxCategoryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ready to Pay
#
# POST /ready-to-pay
# operationId: PostReadyToPay
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "ready-to-pay PostReadyToPay" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customerId: any # The customer identifier string.
  --billingAddress: any # The billing address.
  riskMetadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  websiteId: any # The website identifier string.
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ready-to-pay")
  let body = {customerId: $customerId, billingAddress: $billingAddress, riskMetadata: $riskMetadata, websiteId: $websiteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search merchant data
#
# GET /search
# operationId: GetSearch
export def "search GetSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The default search. It will search across resources and many fields.
]: nothing -> table<customers: list<record>, invoices: list<record>, orders: list<record>, searched: list<string>, transactions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of shipping zones
#
# GET /shipping-zones
# operationId: GetShippingZoneCollection
export def "shipping-zones GetShippingZoneCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, countries: list<string>, createdTime: record, id: record, isDefault: any, name: string, rates: list<record>, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipping-zones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Shipping Zone
#
# POST /shipping-zones
# operationId: PostShippingZone
# --_links item shape: {rel: "self", href: string}
# --rates item shape: {currency: any, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
export def "shipping-zones PostShippingZone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --countries: list # Countries covered by the shipping zone. A country can only belong to one shipping zone (no overlapping). This property can be empty or null to create a default shipping zone for countries that were not specified in other zones.
  --createdTime: any # The shipping zone created time.
  name: string # The shipping zone name.
  --rates: list # Price-based shipping rate instructions. — item shape: {currency: any, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
  --updatedTime: any # The shipping zone updated time.
]: any -> record<_links: table<rel: string>, countries: list<string>, createdTime: record, id: record, isDefault: any, name: string, rates: table<_links: list, currency: record, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipping-zones")
  let body = {countries: $countries, createdTime: $createdTime, name: $name, rates: $rates, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a shipping zone
#
# DELETE /shipping-zones/{id}
# operationId: DeleteShippingZone
export def "shipping-zones DeleteShippingZone" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipping-zones/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a shipping zone
#
# GET /shipping-zones/{id}
# operationId: GetShippingZone
export def "shipping-zones GetShippingZone" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, countries: list<string>, createdTime: record, id: record, isDefault: any, name: string, rates: table<_links: list, currency: record, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipping-zones/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a shipping zone with predefined ID
#
# PUT /shipping-zones/{id}
# operationId: PutShippingZone
# --_links item shape: {rel: "self", href: string}
# --rates item shape: {currency: any, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
export def "shipping-zones PutShippingZone" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --countries: list # Countries covered by the shipping zone. A country can only belong to one shipping zone (no overlapping). This property can be empty or null to create a default shipping zone for countries that were not specified in other zones.
  --createdTime: any # The shipping zone created time.
  name: string # The shipping zone name.
  --rates: list # Price-based shipping rate instructions. — item shape: {currency: any, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
  --updatedTime: any # The shipping zone updated time.
]: any -> record<_links: table<rel: string>, countries: list<string>, createdTime: record, id: record, isDefault: any, name: string, rates: table<_links: list, currency: record, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipping-zones/($id)")
  let body = {countries: $countries, createdTime: $createdTime, name: $name, rates: $rates, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of cancellations
#
# GET /subscription-cancellations
# operationId: GetSubscriptionCancellationCollection
export def "subscription-cancellations GetSubscriptionCancellationCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<record>, appliedInvoiceId: record, canceledBy: string, canceledTime: string, churnTime: string, createdTime: record, description: string, id: record, lineItemSubtotal: float, lineItems: record, prorated: bool, proratedInvoiceId: record, reason: string, status: string, subscriptionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/subscription-cancellations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an order
#
# POST /subscription-cancellations
# operationId: PostSubscriptionCancellation
# --_links item shape: {rel: "self", href: string}
export def "subscription-cancellations PostSubscriptionCancellation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --canceledBy: string@canceledBy-completer # Who did the cancellation. (default: customer)
  churnTime: string # The time when the subscription will be deactivated. (format: date-time)
  --createdTime: any # The time of resource creation (when it is posted).
  --description: string # Cancel reason description in free form.
  --lineItems: any # Items to be added to the new invoice. Proration item is generated and added automatically.
  --prorated: string@bool-completer # Defines if the customer gets a pro-rata credit for the time remaining between `churnTime` and subscription's next renewal time.  (default: false)
  --reason: string@reason-completer # Cancellation reason. (default: other)
  --status: string@status-completer-1 # "draft" defines that the cancellation isn't applied on an invoice and subscription but can be inspected to see the charge. "confirmed" will set a subscription to be canceled when the `churnTime` is reached. "completed" is a read-only status which is set by the system when the churnTime is reached. The cancellation may not be changed or deleted when the status is "completed".  (default: confirmed)
  subscriptionId: any # Identifier of the canceled subscription order.
]: any -> record<_links: table<rel: string>, appliedInvoiceId: record, canceledBy: string, canceledTime: string, churnTime: string, createdTime: record, description: string, id: record, lineItemSubtotal: float, lineItems: record, prorated: bool, proratedInvoiceId: record, reason: string, status: string, subscriptionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription-cancellations")
  let body = {canceledBy: $canceledBy, churnTime: $churnTime, createdTime: $createdTime, description: $description, lineItems: $lineItems, prorated: $prorated, reason: $reason, status: $status, subscriptionId: $subscriptionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a cancellation
#
# DELETE /subscription-cancellations/{id}
# operationId: DeleteSubscriptionCancellation
export def "subscription-cancellations DeleteSubscriptionCancellation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscription-cancellations/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an order сancellation
#
# GET /subscription-cancellations/{id}
# operationId: GetSubscriptionCancellation
export def "subscription-cancellations GetSubscriptionCancellation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, appliedInvoiceId: record, canceledBy: string, canceledTime: string, churnTime: string, createdTime: record, description: string, id: record, lineItemSubtotal: float, lineItems: record, prorated: bool, proratedInvoiceId: record, reason: string, status: string, subscriptionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscription-cancellations/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an order
#
# PUT /subscription-cancellations/{id}
# operationId: PutSubscriptionCancellation
# --_links item shape: {rel: "self", href: string}
export def "subscription-cancellations PutSubscriptionCancellation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --canceledBy: string@canceledBy-completer # Who did the cancellation. (default: customer)
  churnTime: string # The time when the subscription will be deactivated. (format: date-time)
  --createdTime: any # The time of resource creation (when it is posted).
  --description: string # Cancel reason description in free form.
  --lineItems: any # Items to be added to the new invoice. Proration item is generated and added automatically.
  --prorated: string@bool-completer # Defines if the customer gets a pro-rata credit for the time remaining between `churnTime` and subscription's next renewal time.  (default: false)
  --reason: string@reason-completer # Cancellation reason. (default: other)
  --status: string@status-completer-1 # "draft" defines that the cancellation isn't applied on an invoice and subscription but can be inspected to see the charge. "confirmed" will set a subscription to be canceled when the `churnTime` is reached. "completed" is a read-only status which is set by the system when the churnTime is reached. The cancellation may not be changed or deleted when the status is "completed".  (default: confirmed)
  subscriptionId: any # Identifier of the canceled subscription order.
]: any -> record<_links: table<rel: string>, appliedInvoiceId: record, canceledBy: string, canceledTime: string, churnTime: string, createdTime: record, description: string, id: record, lineItemSubtotal: float, lineItems: record, prorated: bool, proratedInvoiceId: record, reason: string, status: string, subscriptionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscription-cancellations/($id)")
  let body = {canceledBy: $canceledBy, churnTime: $churnTime, createdTime: $createdTime, description: $description, lineItems: $lineItems, prorated: $prorated, reason: $reason, status: $status, subscriptionId: $subscriptionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of reactivations
#
# GET /subscription-reactivations
# operationId: GetSubscriptionReactivationCollection
export def "subscription-reactivations GetSubscriptionReactivationCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<record>, cancellationId: record, createdTime: string, description: string, effectiveTime: string, id: record, renewalTime: string, subscriptionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/subscription-reactivations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reactivate an order
#
# POST /subscription-reactivations
# operationId: PostSubscriptionReactivation
# --_links item shape: {rel: "self", href: string}
export def "subscription-reactivations PostSubscriptionReactivation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --description: string # Reactivation reason description in free form.
  --effectiveTime: string # The date from which the service period would start, unless the subscription is canceled but still active. In case the susbcription is still active, the subscription will continue the current service period. If omitted, it will default to the current time.  (format: date-time)
  --renewalTime: string # The time of the next subscription renewal. If omitted then it is computed from the effective time. If the subscription is canceled but active it is ignored, so the next renewal will happen as scheduled.  (format: date-time)
  subscriptionId: any # Identifier of the reactivated subscription.
]: any -> record<_links: table<rel: string>, cancellationId: record, createdTime: string, description: string, effectiveTime: string, id: record, renewalTime: string, subscriptionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription-reactivations")
  let body = {description: $description, effectiveTime: $effectiveTime, renewalTime: $renewalTime, subscriptionId: $subscriptionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an order reactivation
#
# GET /subscription-reactivations/{id}
# operationId: GetSubscriptionReactivation
export def "subscription-reactivations GetSubscriptionReactivation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, cancellationId: record, createdTime: string, description: string, effectiveTime: string, id: record, renewalTime: string, subscriptionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscription-reactivations/($id)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of orders
#
# GET /subscriptions
# operationId: GetSubscriptionCollection
export def "subscriptions GetSubscriptionCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are:   - recentInvoice   - initialInvoice   - customer   - website  See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<orderType: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an order
#
# POST /subscriptions
# Discriminator (request): orderType = one-time-order, subscription-order
# operationId: PostSubscription
export def "subscriptions PostSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are:   - recentInvoice   - initialInvoice   - customer   - website  See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  orderType: string@orderType-completer # Specifies the type of order, a subscription or a one-time purchase.
]: any -> record<orderType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let body = {orderType: $orderType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an order
#
# GET /subscriptions/{id}
# Discriminator (response): orderType = one-time-order, subscription-order
# operationId: GetSubscription
export def "subscriptions GetSubscription" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are:   - recentInvoice   - initialInvoice   - customer   - website  See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> record<orderType: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert an order with predefined ID
#
# PUT /subscriptions/{id}
# Discriminator (request): orderType = one-time-order, subscription-order
# operationId: PutSubscription
export def "subscriptions PutSubscription" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are:   - recentInvoice   - initialInvoice   - customer   - website  See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  orderType: string@orderType-completer # Specifies the type of order, a subscription or a one-time purchase.
]: any -> record<orderType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($id)" $qp)
  let body = {orderType: $orderType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change an order's items
#
# POST /subscriptions/{id}/change-items
# Discriminator (response): orderType = one-time-order, subscription-order
# operationId: PostSubscriptionItemsChange
# --items item shape: {plan: any, quantity: int}
export def "subscriptions-change-items PostSubscriptionItemsChange" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --effectiveTime: string # The date from which the renewal time (for `reset` operations) and proration calculations are made.  If omitted, it will default to the current time. (format: date-time)
  items: list # item shape: {plan: any, quantity: int}
  --keepTrial: string@bool-completer # If set to true and the subscription order has an active trial, it will use that trial further. Works with 'retain' renewalPolicy only. (default: false)
  --preview: string@bool-completer # If set to true, it will not change the subscription.  It allows for a way to preview the changes that would be made to a subscription. (default: false)
  --prorated: string@bool-completer # Whether or not to give a pro rata credit for the amount of time remaining between the `effectiveTime` and the end of the current period. In addition, if the `renewalTime` is retained (by setting the `renewalPolicy` to `retain`), then a pro rata debit will occur as well, for the amount between the `effectiveTime` and the `renewalTime` as a percentage of the normal period size.
  renewalPolicy: string@renewalPolicy-completer # The value determines whether the subscription retains its current `renewalTime` or resets it to a newly calculated `renewalTime`.
]: any -> record<orderType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($id)/change-items")
  let body = {effectiveTime: $effectiveTime, items: $items, keepTrial: $keepTrial, preview: $preview, prorated: $prorated, renewalPolicy: $renewalPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Issue an interim invoice for a subscription order
#
# POST /subscriptions/{id}/interim-invoice
# operationId: PostSubscriptionInterimInvoice
export def "subscriptions-interim-invoice PostSubscriptionInterimInvoice" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --transactionId: any # If present, applies a payment to the invoice created.  If the payment is for the invoice total, it would be marked as paid.
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($id)/interim-invoice")
  let body = {transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of order timeline messages
#
# GET /subscriptions/{id}/timeline
# operationId: GetSubscriptionTimelineCollection
export def "subscriptions-timeline GetSubscriptionTimelineCollection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($id)/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an order Timeline comment
#
# POST /subscriptions/{id}/timeline
# operationId: PostSubscriptionTimeline
# --_links item shape: {rel: "self", href: string}
# --extraData shape: {actions?: list, author?: record, links?: list, mentions?: record, tables?: list}
export def "subscriptions-timeline PostSubscriptionTimeline" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($id)/timeline")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Order Timeline message
#
# DELETE /subscriptions/{id}/timeline/{messageId}
# operationId: DeleteSubscriptionTimeline
export def "subscriptions-timeline DeleteSubscriptionTimeline" [
  id: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($id)/timeline/($messageId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an Order Timeline message
#
# GET /subscriptions/{id}/timeline/{messageId}
# operationId: GetSubscriptionTimeline
export def "subscriptions-timeline GetSubscriptionTimeline" [
  id: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($id)/timeline/($messageId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve subscription order's upcoming invoice
#
# GET /subscriptions/{id}/upcoming-invoices
# operationId: GetSubscriptionUpcomingInvoiceCollection
export def "subscriptions-upcoming-invoices GetSubscriptionUpcomingInvoiceCollection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: list<record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($id)/upcoming-invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issue an upcoming invoice for early pay
#
# POST /subscriptions/{id}/upcoming-invoices/{invoiceId}/issue
# operationId: PostUpcomingInvoiceIssuance
export def "subscriptions-upcoming-invoices-issue PostUpcomingInvoiceIssuance" [
  id: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --dueTime: string # Invoice due time. Will be set same as `issuedTime` if `null` or omitted. (nullable, format: date-time)
  --issuedTime: string # Invoice issued time. Will be issued immediately if `null` or omitted. (nullable, format: date-time)
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($id)/upcoming-invoices/($invoiceId)/issue")
  let body = {dueTime: $dueTime, issuedTime: $issuedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of tags
#
# GET /tags
# operationId: GetTagCollection
export def "tags GetTagCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<any>, createdTime: record, id: record, name: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a tag
#
# POST /tags
# operationId: PostTag
export def "tags PostTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The tag's created time.
  name: string # The tag is unique name, which is case-insensitive. (e.g. New)
  --updatedTime: any # The tag's updated time.
]: any -> record<_links: list<any>, createdTime: record, id: record, name: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let body = {createdTime: $createdTime, name: $name, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tag
#
# DELETE /tags/{tag}
# operationId: DeleteTag
export def "tags DeleteTag" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a tag
#
# GET /tags/{tag}
# operationId: GetTag
export def "tags GetTag" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: list<any>, createdTime: record, id: record, name: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a tag
#
# PATCH /tags/{tag}
# operationId: PatchTag
export def "tags PatchTag" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --createdTime: any # The tag's created time.
  name: string # The tag is unique name, which is case-insensitive. (e.g. New)
  --updatedTime: any # The tag's updated time.
]: any -> record<_links: list<any>, createdTime: record, id: record, name: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag)")
  let body = {createdTime: $createdTime, name: $name, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Untag a list of customers
#
# DELETE /tags/{tag}/customers
# operationId: DeleteTagCustomerCollection
export def "tags-customers DeleteTagCustomerCollection" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customerIds: list # The list of customer IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag)/customers")
  let body = {customerIds: $customerIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Tag a list of customers
#
# POST /tags/{tag}/customers
# operationId: PostTagCustomerCollection
export def "tags-customers PostTagCustomerCollection" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customerIds: list # The list of customer IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag)/customers")
  let body = {customerIds: $customerIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Untag a customer
#
# DELETE /tags/{tag}/customers/{customerId}
# operationId: DeleteTagCustomer
export def "tags-customers DeleteTagCustomer" [
  tag: string
  customerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag)/customers/($customerId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tag a customer
#
# POST /tags/{tag}/customers/{customerId}
# operationId: PostTagCustomer
export def "tags-customers PostTagCustomer" [
  tag: string
  customerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag)/customers/($customerId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of tokens
#
# GET /tokens
# operationId: GetTokenCollection
export def "tokens GetTokenCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a payment token
#
# POST /tokens
# operationId: PostToken
# --paymentInstrument shape: {cvv?: string, expMonth?: int, expYear?: int, pan?: string}
export def "tokens PostToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billingAddress: any # The billing address object.
  --method: string@method-completer # The token payment method.
  --paymentInstrument: record # The payment card instrument details. — shape: {cvv?: string, expMonth?: int, expYear?: int, pan?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens")
  let body = {billingAddress: $billingAddress, method: $method, paymentInstrument: $paymentInstrument} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a token
#
# GET /tokens/{token}
# operationId: GetToken
export def "tokens GetToken" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tokens/($token)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of transactions
#
# GET /transactions
# operationId: GetTransactionCollection
export def "transactions GetTransactionCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --qp-sort: list # The collection items sort field and order (prefix with "-" for descending sort).
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record, outcome: string, presentedOffers: record, selectedOffer: record, version: record>, dcc: record<base: record, outcome: string, quote: record, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record, cvvResponse: record, response: record>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a transaction
#
# POST /transactions
# operationId: PostTransaction
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
@deprecated --flag paymentInstrument
export def "transactions PostTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  amount: float # The transaction amount. (format: double, e.g. 97.97)
  --billingAddress: any # Billing address. If not supplied, we use the billing address associated with the payment instrument, and then customer. (nullable)
  currency: any
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
  customerId: any # The customer identifier string.
  --description: string # The payment description. (nullable)
  --gatewayAccountId: any # Rebilly will select the appropriate payment gateway account for the transaction based on the properties of the transaction and the `gateway-account-requested` event rules configurations. If you wish to prevent Rebilly from making the gateway account selection, you may supply a gateway account id here, and it will be used instead. Only use this field if you intend to override the settings. (nullable)
  --invoiceIds: list # The array of invoice identifiers. (nullable)
  --isMerchantInitiated: string@bool-completer # True if the transaction was initiated by the merchant. (default: false)
  --isProcessedOutside: string@bool-completer # True if transaction was processed outside Rebilly. (default: false)
  --notificationUrl: string # The URL where a server-to-server notification request type `POST` with a transaction payload will be sent when the transaction's result is finalized. Do not trust the notification; follow with a `GET` request to confirm the result of the transaction. Please respond with a `2xx` HTTP status code, or we will reattempt the request again. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly.  (nullable, format: uri)
  --paymentInstruction: any # Payment instruction. If not supplied, customer's default payment instrument will be used.
  --paymentInstrument: any # DEPRECATED
  --processedTime: string # The time the transaction was processed. Can be specified only if transaction was processed outside Rebilly. (format: date-time)
  --redirectUrl: string # The URL to redirect the end-user when an offsite transaction is completed. Defaults to the website's configured URL. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --requestId: string # The request id is **recommended**. It prevents duplicate transaction requests within a short period of time. If a duplicate request is sent with the same `requestId` it will be ignored to prevent double-billing anyone.  It must be unique within a 24-hour period.  We recommend generating a UUID v4 as its value. (nullable, e.g. 44433322-2c4y-483z-a0a9-158621f77a21)
  --riskMetadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  websiteId: any # The website identifier string.
  type: string@type-completer-7 # The type of transaction requested. You should always include the type within your API request. This supports a limited subset of Transaction types.  To refund or void, use the refund endpoint. To `capture` use the `sale` type. If any existing `authorize` transactions are eligible, then they will be captured and the `sale` will be converted to a `capture` type.
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let body = {amount: $amount, billingAddress: $billingAddress, currency: $currency, customFields: $customFields, customerId: $customerId, description: $description, gatewayAccountId: $gatewayAccountId, invoiceIds: $invoiceIds, isMerchantInitiated: $isMerchantInitiated, isProcessedOutside: $isProcessedOutside, notificationUrl: $notificationUrl, paymentInstruction: $paymentInstruction, paymentInstrument: $paymentInstrument, processedTime: $processedTime, redirectUrl: $redirectUrl, requestId: $requestId, riskMetadata: $riskMetadata, websiteId: $websiteId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Transaction
#
# GET /transactions/{id}
# operationId: GetTransaction
export def "transactions GetTransaction" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/transactions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a transaction
#
# PATCH /transactions/{id}
# operationId: PatchTransaction
export def "transactions PatchTransaction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customFields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats).  (default: {}, e.g. {foo: bar})
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($id)")
  let body = {customFields: $customFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query a Transaction
#
# POST /transactions/{id}/query
# operationId: PostTransactionQuery
export def "transactions-query PostTransactionQuery" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<amount: float, currency: record, result: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($id)/query")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refund a Transaction
#
# POST /transactions/{id}/refund
# operationId: PostTransactionRefund
export def "transactions-refund PostTransactionRefund" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # Refund amount. (format: double)
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($id)/refund")
  let body = {amount: $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of transaction timeline messages
#
# GET /transactions/{id}/timeline
# operationId: GetTransactionTimelineCollection
export def "transactions-timeline GetTransactionTimelineCollection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values.  Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
]: nothing -> table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/transactions/($id)/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a transaction Timeline comment
#
# POST /transactions/{id}/timeline
# operationId: PostTransactionTimeline
# --_links item shape: {rel: "self", href: string}
# --extraData shape: {actions?: list, author?: record, links?: list, mentions?: record, tables?: list}
export def "transactions-timeline PostTransactionTimeline" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($id)/timeline")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Transaction Timeline message
#
# DELETE /transactions/{id}/timeline/{messageId}
# operationId: DeleteTransactionTimeline
export def "transactions-timeline DeleteTransactionTimeline" [
  id: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($id)/timeline/($messageId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a transaction Timeline message
#
# GET /transactions/{id}/timeline/{messageId}
# operationId: GetTransactionTimeline
export def "transactions-timeline GetTransactionTimeline" [
  id: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($id)/timeline/($messageId)")
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Transaction status
#
# POST /transactions/{id}/update
# operationId: PostTransactionUpdate
export def "transactions-update PostTransactionUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Organization-Id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --amount: float # The transaction amount. (format: double)
  --currency: any # The transaction currency.
  --body-result: string@result-completer # Transaction result.
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($id)/update")
  let body = {amount: $amount, currency: $currency, result: $body_result} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Organization-Id": $Organization_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
