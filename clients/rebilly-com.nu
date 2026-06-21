# Auto-generated client for Rebilly REST API v2.1
# Source: https://api.apis.guru/v2/specs/rebilly.com/2.1/openapi.json
# Auth: --token flag or $env.REBILLY_REST_API_TOKEN

const BASE_URL = "https://api-sandbox.rebilly.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REBILLY_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "reb-apikey" => { {scheme: $scheme, headers: {REB-APIKEY: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api-sandbox.rebilly.com" "https://api.rebilly.com"] }
def auth-scheme-completer [] { ["bearer" "reb-apikey"] }

# Completers for enum parameters
def enrolled-completer [] { ["N" "U" "Y"] }
def payer-auth-response-status-completer [] { ["A" "N" "U" "Y"] }
def signature-verification-completer [] { ["N" "Y"] }
def related-type-completer [] { ["customer" "customer-timeline-comment" "dispute" "gateway-timeline-comment" "invoice" "order-timeline-comment" "organization" "payment" "plan" "product" "subscription" "transaction" "transaction-timeline-comment"] }
def mode-completer [] { ["password" "passwordless"] }
def account-type-completer [] { ["checking" "other" "savings"] }
def type-completer [] { ["address" "bank-account" "bin" "country" "customer-id" "email" "email-domain" "fingerprint" "ip-address" "payment-card"] }
def type-completer-1 [] { ["array" "boolean" "datetime" "integer" "monetary" "number" "string"] }
def type-completer-2 [] { ["aml-list-was-possibly-matched" "coupon-applied" "coupon-redeemed" "coupon-redemption-canceled" "custom-event" "custom-event-processed" "custom-fields-changed" "customer-bank-account-blocked" "customer-blocked" "customer-comment-created" "customer-created" "customer-payment-card-blocked" "default-payment-instrument-changed" "email-message-sent" "experian-check-performed" "invoice-abandoned" "invoice-created" "invoice-disputed" "invoice-issued" "invoice-paid" "invoice-partially-paid" "invoice-partially-refunded" "invoice-past-due" "invoice-refunded" "invoice-voided" "kyc-document-accepted" "kyc-document-created" "kyc-document-manually-accepted" "kyc-document-manually-rejected" "kyc-document-modified" "kyc-document-rejected" "lead-source-changed" "order-activated" "order-canceled" "order-churned" "order-completed" "order-created" "order-downgraded" "order-paid-early" "order-reactivated" "order-renewed" "order-upgraded" "payment-card-expired" "payment-instrument-created" "payment-instrument-deactivated" "primary-address-changed" "transaction-abandoned" "transaction-amount-discrepancy-found" "transaction-approved" "transaction-canceled" "transaction-declined" "transaction-discrepancy-found" "transaction-refunded" "transaction-voided" "transaction-waiting-gateway"] }
def type-completer-3 [] { ["Apple Pay"] }
def reason-code-completer [] { ["0" "00" "1" "10.1" "10.2" "10.3" "10.4" "10.5" "1000" "11.1" "11.2" "11.3" "12" "12.1" "12.2" "12.3" "12.4" "12.5" "12.6" "12.7" "13.1" "13.2" "13.3" "13.4" "13.5" "13.6" "13.7" "13.8" "13.9" "2" "2" "3" "30" "31" "35" "37" "4" "40" "41" "42" "46" "47" "49" "5" "50" "51" "53" "54" "55" "57" "59" "6" "60" "62" "63" "7" "7" "70" "71" "72" "73" "74" "75" "76" "77" "79" "8" "80" "81" "82" "83" "85" "86" "9" "93" "A" "A01" "A02" "A08" "AL" "AP" "AW" "B" "C02" "C04" "C05" "C08" "C14" "C18" "C28" "C31" "C32" "CA" "CD" "CR" "DA" "DP" "DP1" "EX" "F10" "F14" "F22" "F24" "F29" "FR1" "FR4" "FR6" "IC" "IN" "IS" "LP" "M01" "M10" "M49" "N" "NA" "NC" "P" "P01" "P03" "P04" "P05" "P07" "P08" "P22" "P23" "R03" "R13" "RG" "RM" "RN1" "RN2" "SV" "TF" "TNM" "UA01" "UA02" "UA03" "UA10" "UA11" "UA12" "UA18" "UA20" "UA21" "UA22" "UA23" "UA28" "UA30" "UA31" "UA32" "UA38" "UA99" "bank_cannot_process" "credit_not_processed" "customer_initiated" "debit_not_authorized" "duplicate" "fraudulent" "general" "incorrect_account_details" "insufficient_funds" "pre-chargeback-alert" "product_not_received" "product_unacceptable" "subscription_canceled" "unrecognized"] }
def status-completer [] { ["forfeited" "lost" "response-needed" "under-review" "unknown" "won"] }
def type-completer-4 [] { ["arbitration" "ethoca-alert" "first-chargeback" "fraud" "information-request" "second-chargeback" "verifi-alert"] }
def accept-completer [] { ["application/json" "application/pdf"] }
def type-completer-5 [] { ["credit" "debit"] }
def type-completer-6 [] { ["document-expired" "document-not-matching" "document-unreadable" "other" "underage-person"] }
def method-completer [] { ["payment-card"] }
def method-completer-1 [] { ["paypal"] }
def tax-category-id-completer [] { ["00000" "20010" "30070" "31000" "40030" "51010" "51020" "99999"] }
def canceled-by-completer [] { ["customer" "merchant"] }
def reason-completer [] { ["billing-failure" "bugs-or-problems" "contract-expired" "did-not-use" "did-not-want" "do-not-remember" "missing-features" "other" "risk-warning" "too-expensive"] }
def status-completer-1 [] { ["completed" "confirmed" "draft" "revoked"] }
def order-type-completer [] { ["one-time-order" "subscription-order"] }
def renewal-policy-completer [] { ["reset" "retain"] }
def type-completer-7 [] { ["3ds-authentication" "authorize" "sale"] }
def result-completer [] { ["abandoned" "approved" "canceled" "declined"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "3dsecure get-get3-d-secure-collection" } } | get name | first)
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
export def "3dsecure get-get3-d-secure-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<record>, amount: float, cavv: string, createdTime: record, currency: record, customerId: record, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: record, id: record, payerAuthResponseStatus: string, paymentCardId: record, signatureVerification: string, websiteId: record, xid: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/3dsecure" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Create a ThreeDSecure entry
#
# POST /3dsecure
# operationId: Post3DSecure
# --_links item shape: {rel: "self", href: string}
export def "3dsecure create-post3-d-secure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # Transaction amount. (format: double)
  --cavv: string # The 3D Secure entry cardholder authentication verification value.
  --created-time: any # The 3D Secure entry created time.
  currency: any
  customer_id: any # Related customer ID.
  --eci: int # The 3D Secure entry electronic commerce indicator.
  enrolled: string@enrolled-completer # Is the cardholder enrolled in 3DSecure.
  enrollment_eci: string # The 3D Secure entry enrollment eci.
  gateway_account_id: any # Related gateway account ID.
  --payer-auth-response-status: string@payer-auth-response-status-completer # The 3D Secure entry Auth Response Status.
  payment_card_id: any # Related payment card ID.
  --signature-verification: string@signature-verification-completer # If signature was verified.
  website_id: any # Related Website ID.
  --xid: string # The 3D Secure entry transaction Id.
]: any -> record<_links: table<rel: string>, amount: float, cavv: string, createdTime: record, currency: record, customerId: record, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: record, id: record, payerAuthResponseStatus: string, paymentCardId: record, signatureVerification: string, websiteId: record, xid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/3dsecure")
  let req_body = {"amount": $amount, "cavv": $cavv, "createdTime": $created_time, "currency": $currency, "customerId": $customer_id, "eci": $eci, "enrolled": $enrolled, "enrollmentEci": $enrollment_eci, "gatewayAccountId": $gateway_account_id, "payerAuthResponseStatus": $payer_auth_response_status, "paymentCardId": $payment_card_id, "signatureVerification": $signature_verification, "websiteId": $website_id, "xid": $xid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a ThreeDSecure entry
#
# GET /3dsecure/{id}
# operationId: Get3DSecure
export def "3dsecure get-get3-d-secure" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, amount: float, cavv: string, createdTime: record, currency: record, customerId: record, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: record, id: record, payerAuthResponseStatus: string, paymentCardId: record, signatureVerification: string, websiteId: record, xid: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/3dsecure/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search PEP/Sanctions/Adverse Media lists
#
# GET /aml
# operationId: GetAmlEntry
export def "aml get-entry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string # First name of individual to search.
  --last-name: string # Last name of individual to search.
  --dob: string # Date of birth in format YYYY-MM-DD.
  --country: string # Country of individual as an ISO Alpha-2 code.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> table<_links: list<record>, address: list<record>, aliases: list<record>, comments: string, confidence: string, dob: list<string>, firstName: string, gender: string, lastName: string, legalBasis: list<string>, nationality: string, passport: list<record>, regime: string, source: string, sourceType: string, title: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $first_name "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "dob" $dob "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aml" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"firstName": $first_name, "lastName": $last_name, "dob": $dob, "country": $country} | compact), body: null}
}

# Retrieve a list of Attachments
#
# GET /attachments
# operationId: GetAttachmentCollection
export def "attachments get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, fileId: string, id: record, name: string, relatedId: string, relatedType: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "q": $q, "expand": $expand, "fields": $fields, "sort": $qp_sort} | compact), body: null}
}

# Create an Attachment
#
# POST /attachments
# operationId: PostAttachment
export def "attachments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Creation date/time.
  --description: string # The Attachment description.
  file_id: string # Linked File object id.
  --name: string # The Original Attachment name.
  related_id: string # Linked object Id.
  related_type: string@related-type-completer # Linked object type.
  --updated-time: any # Latest update date/time.
]: any -> record<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, fileId: string, id: record, name: string, relatedId: string, relatedType: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attachments")
  let req_body = {"createdTime": $created_time, "description": $description, "fileId": $file_id, "name": $name, "relatedId": $related_id, "relatedType": $related_type, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an Attachment
#
# DELETE /attachments/{id}
# operationId: DeleteAttachment
export def "attachments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/attachments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an Attachment
#
# GET /attachments/{id}
# operationId: GetAttachment
export def "attachments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, fileId: string, id: record, name: string, relatedId: string, relatedType: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/attachments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the Attachment with predefined ID
#
# PUT /attachments/{id}
# operationId: PutAttachment
export def "attachments update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Creation date/time.
  --description: string # The Attachment description.
  file_id: string # Linked File object id.
  --name: string # The Original Attachment name.
  related_id: string # Linked object Id.
  related_type: string@related-type-completer # Linked object type.
  --updated-time: any # Latest update date/time.
]: any -> record<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, fileId: string, id: record, name: string, relatedId: string, relatedType: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/attachments/{id}"))
  let req_body = {"createdTime": $created_time, "description": $description, "fileId": $file_id, "name": $name, "relatedId": $related_id, "relatedType": $related_type, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Read current authentication options
#
# GET /authentication-options
# operationId: GetAuthenticationOption
export def "authentication-options get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> table<authTokenTtl: int, credentialTtl: int, otpRequired: bool, passwordPattern: string, resetTokenTtl: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication-options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Change authentication options
#
# PUT /authentication-options
# operationId: PutAuthenticationOption
export def "authentication-options update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --auth-token-ttl: int # The default lifetime of the auth-token in seconds.
  --credential-ttl: int # The default lifetime of the credential in seconds.
  --otp-required: oneof<nothing, bool> # Should OTP be required to exchange token.
  --password-pattern: string # Allowed password pattern.
  --reset-token-ttl: int # The default lifetime of the reset-token in seconds.
]: any -> record<authTokenTtl: int, credentialTtl: int, otpRequired: bool, passwordPattern: string, resetTokenTtl: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication-options")
  let req_body = {"authTokenTtl": $auth_token_ttl, "credentialTtl": $credential_ttl, "otpRequired": $otp_required, "passwordPattern": $password_pattern, "resetTokenTtl": $reset_token_ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of auth tokens
#
# GET /authentication-tokens
# operationId: GetAuthenticationTokenCollection
export def "authentication-tokens get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<credentialId: record, mode: string, otpRequired: bool, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Login
#
# POST /authentication-tokens
# Discriminator (request): mode = password, passwordless
# operationId: PostAuthenticationToken
export def "authentication-tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  mode: string@mode-completer # The token's generation mode. (default: password)
  --otp-required: oneof<nothing, bool> # Should OTP be required to exchange this token.
]: any -> record<credentialId: record, mode: string, otpRequired: bool, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication-tokens")
  let req_body = {"mode": $mode, "otpRequired": $otp_required} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Logout a customer
#
# DELETE /authentication-tokens/{token}
# operationId: DeleteAuthenticationToken
export def "authentication-tokens delete" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/authentication-tokens/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Verify
#
# GET /authentication-tokens/{token}
# Discriminator (response): mode = password, passwordless
# operationId: GetAuthenticationTokenVerification
export def "authentication-tokens get-verification" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<credentialId: record, mode: string, otpRequired: bool, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/authentication-tokens/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Exchange
#
# POST /authentication-tokens/{token}/exchange
# operationId: PostAuthenticationTokenExchange
# --_links item shape: {rel: "customer"|"targetCustomer", href: string}
# --acl item shape: {permissions: any, scope: any}
export def "authentication-tokens-exchange create" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acl: list # item shape: {permissions: any, scope: any}
  --custom-claims: record # e.g. {documents: [identity-proof, address-proof], redirectUrl: https://mywebsite.com}
  --expired-time: string # Session expired time. Defaults to one hour. (format: date-time)
  --invalidate: oneof<nothing, bool> # Whether to invalidate token after exchange or not. (default: true, e.g. true)
  --one-time-password: string # The one time password sent via an email. Should contain digits only. (e.g. 123456)
  --updated-time: any # Session updated time.
]: any -> record<_links: table<rel: string>, acl: table<permissions: record, scope: record>, createdTime: string, customClaims: record, customerId: record, expiredTime: string, id: record, invalidate: bool, oneTimePassword: string, token: string, type: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/authentication-tokens/{token_arg}/exchange"))
  let req_body = {"acl": $acl, "customClaims": $custom_claims, "expiredTime": $expired_time, "invalidate": $invalidate, "oneTimePassword": $one_time_password, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of bank accounts
#
# GET /bank-accounts
# operationId: GetBankAccountCollection
export def "bank-accounts get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bank-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "q": $q, "sort": $qp_sort, "filter": $filter, "expand": $expand} | compact), body: null}
}

# Create a Bank Account
#
# POST /bank-accounts
# operationId: PostBankAccount
export def "bank-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --customer-id: any # The Customer's ID.
  --body-token: string # BankAccountToken ID.
]: any -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank-accounts")
  let req_body = {"customFields": $custom_fields, "customerId": $customer_id, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a Bank Account
#
# GET /bank-accounts/{id}
# operationId: GetBankAccount
export def "bank-accounts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bank-accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a bank account's values
#
# PATCH /bank-accounts/{id}
# operationId: PatchBankAccount
export def "bank-accounts update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --account-type: string@account-type-completer # Bank's account type.
  --bank-name: string # Bank's name.
  --billing-address: any # The billing address.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
]: any -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bank-accounts/{id}"))
  let req_body = {"accountType": $account_type, "bankName": $bank_name, "billingAddress": $billing_address, "customFields": $custom_fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a Bank Account with predefined ID
#
# PUT /bank-accounts/{id}
# operationId: PutBankAccount
export def "bank-accounts update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --customer-id: any # The Customer's ID.
  --body-token: string # BankAccountToken ID.
]: any -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bank-accounts/{id}"))
  let req_body = {"customFields": $custom_fields, "customerId": $customer_id, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deactivate a Bank Account
#
# POST /bank-accounts/{id}/deactivation
# operationId: PostBankAccountDeactivation
export def "bank-accounts-deactivation create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, fingerprint: string, id: record, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bank-accounts/{id}/deactivation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of blocklists
#
# GET /blocklists
# operationId: GetBlocklistCollection
export def "blocklists get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, createdTime: record, expirationTime: string, id: record, type: string, updatedTime: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocklists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "sort": $qp_sort, "filter": $filter, "q": $q} | compact), body: null}
}

# Create a blocklist
#
# POST /blocklists
# operationId: PostBlocklist
# --_links item shape: {rel: "self", href: string}
export def "blocklists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The blocklist created time.
  --expiration-time: string # The blocklist expiration time. (format: date-time)
  type: string@type-completer # The blocklist type.
  --updated-time: any # The blocklist updated time.
  value: string # The blocklist value.
]: any -> record<_links: table<rel: string>, createdTime: record, expirationTime: string, id: record, type: string, updatedTime: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocklists")
  let req_body = {"createdTime": $created_time, "expirationTime": $expiration_time, "type": $type, "updatedTime": $updated_time, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a blocklist
#
# DELETE /blocklists/{id}
# operationId: DeleteBlocklist
export def "blocklists delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/blocklists/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a blocklist
#
# GET /blocklists/{id}
# operationId: GetBlocklist
export def "blocklists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, createdTime: record, expirationTime: string, id: record, type: string, updatedTime: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/blocklists/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a blocklist with predefined ID
#
# PUT /blocklists/{id}
# operationId: PutBlocklist
# --_links item shape: {rel: "self", href: string}
export def "blocklists update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The blocklist created time.
  --expiration-time: string # The blocklist expiration time. (format: date-time)
  type: string@type-completer # The blocklist type.
  --updated-time: any # The blocklist updated time.
  value: string # The blocklist value.
]: any -> record<_links: table<rel: string>, createdTime: record, expirationTime: string, id: record, type: string, updatedTime: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/blocklists/{id}"))
  let req_body = {"createdTime": $created_time, "expirationTime": $expiration_time, "type": $type, "updatedTime": $updated_time, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of coupons
#
# GET /coupons
# operationId: GetCouponCollection
export def "coupons get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<record>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: list<record>, status: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/coupons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "q": $q, "sort": $qp_sort} | compact), body: null}
}

# Create a coupon
#
# POST /coupons
# operationId: PostCoupon
# --_links item shape: {rel: "self", href: string}
# --discount shape: {type: "fixed"|"percent"}
# --restrictions item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
export def "coupons create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Coupon created time.
  --description: string # Your coupon description. When it is not empty this is used for invoice discount item description, otherwise the item's description uses coupon's ID like 'Coupon "COUPON-ID"'.
  discount: record # shape: {type: "fixed"|"percent"}
  --expired-time: string # Coupon's expire time (end time). (format: date-time)
  issued_time: string # Coupon's issued time (start time). (format: date-time)
  --restrictions: list # Coupon restrictions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
  --updated-time: any # Coupon updated time.
]: any -> record<_links: table<rel: string>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coupons")
  let req_body = {"createdTime": $created_time, "description": $description, "discount": $discount, "expiredTime": $expired_time, "issuedTime": $issued_time, "restrictions": $restrictions, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of coupon redemptions
#
# GET /coupons-redemptions
# operationId: GetCouponRedemptionCollection
export def "coupons-redemptions get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<record>, additionalRestrictions: list<record>, canceledTime: record, couponId: record, createdTime: record, customerId: record, id: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/coupons-redemptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "q": $q, "sort": $qp_sort} | compact), body: null}
}

# Redeem a coupon
#
# POST /coupons-redemptions
# operationId: PostCouponRedemption
# --_links item shape: {rel: "self", href: string}
# --additionalRestrictions item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"}
export def "coupons-redemptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --additional-restrictions: list # Additional restrictions for coupon's redemptions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"}
  --coupon-id: any # Coupon's ID.
  --customer-id: any # Customer's ID.
]: any -> record<_links: table<rel: string>, additionalRestrictions: table<type: string>, canceledTime: record, couponId: record, createdTime: record, customerId: record, id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coupons-redemptions")
  let req_body = {"additionalRestrictions": $additional_restrictions, "couponId": $coupon_id, "customerId": $customer_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a coupon redemption with specified identifier string
#
# GET /coupons-redemptions/{id}
# operationId: GetCouponRedemption
export def "coupons-redemptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, additionalRestrictions: table<type: string>, canceledTime: record, couponId: record, createdTime: record, customerId: record, id: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/coupons-redemptions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel a coupon redemption
#
# POST /coupons-redemptions/{id}/cancel
# operationId: PostCouponRedemptionCancellation
export def "coupons-redemptions-cancel create-cancellation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/coupons-redemptions/{id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a coupon
#
# GET /coupons/{id}
# operationId: GetCoupon
export def "coupons get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/coupons/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a coupon with predefined coupon ID
#
# PUT /coupons/{id}
# operationId: PutCoupon
# --_links item shape: {rel: "self", href: string}
# --discount shape: {type: "fixed"|"percent"}
# --restrictions item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
export def "coupons update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Coupon created time.
  --description: string # Your coupon description. When it is not empty this is used for invoice discount item description, otherwise the item's description uses coupon's ID like 'Coupon "COUPON-ID"'.
  discount: record # shape: {type: "fixed"|"percent"}
  --expired-time: string # Coupon's expire time (end time). (format: date-time)
  issued_time: string # Coupon's issued time (start time). (format: date-time)
  --restrictions: list # Coupon restrictions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
  --updated-time: any # Coupon updated time.
]: any -> record<_links: table<rel: string>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/coupons/{id}"))
  let req_body = {"createdTime": $created_time, "description": $description, "discount": $discount, "expiredTime": $expired_time, "issuedTime": $issued_time, "restrictions": $restrictions, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Set a coupon's expiration time
#
# POST /coupons/{id}/expiration
# operationId: PostCouponExpiration
export def "coupons-expiration create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  expired_time: string # The coupon's expiry time, must be greater than the issued time. Null or empty string will immediately expire the coupon. (format: date-time)
]: any -> record<_links: table<rel: string>, createdTime: record, description: string, discount: record<type: string>, expiredTime: string, id: record, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/coupons/{id}/expiration"))
  let req_body = {"expiredTime": $expired_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of credentials
#
# GET /credentials
# operationId: GetCredentialCollection
export def "credentials get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<any>, customerId: string, expiredTime: string, id: record, password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Create a credential
#
# POST /credentials
# operationId: PostCredential
export def "credentials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_id: string # The credential's customer ID.
  --expired-time: string # The credential's expired time. (format: date-time)
  password: string # The credential's password. (format: password)
  username: string # Credential's username.
]: any -> record<_links: list<any>, customerId: string, expiredTime: string, id: record, password: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credentials")
  let req_body = {"customerId": $customer_id, "expiredTime": $expired_time, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a credential
#
# DELETE /credentials/{id}
# operationId: DeleteCredential
export def "credentials delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/credentials/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a credential
#
# GET /credentials/{id}
# operationId: GetCredential
export def "credentials get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: list<any>, customerId: string, expiredTime: string, id: record, password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/credentials/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a credential with predefined ID
#
# PUT /credentials/{id}
# operationId: PutCredential
export def "credentials update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_id: string # The credential's customer ID.
  --expired-time: string # The credential's expired time. (format: date-time)
  password: string # The credential's password. (format: password)
  username: string # Credential's username.
]: any -> record<_links: list<any>, customerId: string, expiredTime: string, id: record, password: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/credentials/{id}"))
  let req_body = {"customerId": $customer_id, "expiredTime": $expired_time, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve Custom Fields
#
# GET /custom-fields/{resource}
# operationId: GetCustomFieldCollection
export def "custom-fields get-collection" [
  resource: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<record>, additionalSchema: any, description: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/custom-fields/{resource}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Retrieve a Custom Field
#
# GET /custom-fields/{resource}/{name}
# operationId: GetCustomField
export def "custom-fields get" [
  resource: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, additionalSchema: any, description: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({resource: (encode-path-segment $resource), name: (encode-path-segment $name)} | format pattern "/custom-fields/{resource}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or alter a Custom Field
#
# PUT /custom-fields/{resource}/{name}
# operationId: PutCustomField
# --_links item shape: {rel: "self", href: string}
export def "custom-fields update" [
  resource: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --additional-schema: any # Additional parameters which can be added according to type: Parameter Name | Types | Description -------------- | ------------- | ------------- allowedValues | string, array | List of allowed values maxLength | string | Maximum allowed length for the string, 255 by default, up to 4000 The additional schema adds additional constrains for values.
  --description: string # The custom field description.
  type: string@type-completer-1 # Type value | Description ------------- | ------------- array | An array of strings up to 255 characters, maximum size is 1000 elements boolean | true or false date | String of format "full-date" (YYYY-MM-DD) from RFC-3339 (full-date) datetime | String of format "date-time" (YYYY-MM-DDTHH:MM:SSZ) from RFC-3339 (date-time) integer | Cardinal value of -2^31..2^31-1 number | Float value. It can take cardinal values also which are interpreted as float string | Regular string up to 255 characters monetary | A map of 3-letters currency code and amount, e.g. {"currency": "EUR", "amount": 25.30} The type cannot be changed.
]: any -> record<_links: table<rel: string>, additionalSchema: any, description: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({resource: (encode-path-segment $resource), name: (encode-path-segment $name)} | format pattern "/custom-fields/{resource}/{name}"))
  let req_body = {"additionalSchema": $additional_schema, "description": $description, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of customer timeline custom event types
#
# GET /customer-timeline-custom-events
# operationId: GetCustomerTimelineCustomEventTypeCollection
export def "customer-timeline-custom-events get-type-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
]: nothing -> table<_links: list<record>, createdTime: record, id: record, name: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer-timeline-custom-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter} | compact), body: null}
}

# Create Customer Timeline custom event type
#
# POST /customer-timeline-custom-events
# operationId: PostCustomerTimelineCustomEventType
# --_links item shape: {rel: "self", href: string}
export def "customer-timeline-custom-events create-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Customer Timeline Custom event created time.
  name: string # Customer Timeline Custom Event type name. It must not be similar to any Rebilly system event.
  --updated-time: any # Customer Timeline Custom event updated time.
]: any -> record<_links: table<rel: string>, createdTime: record, id: record, name: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer-timeline-custom-events")
  let req_body = {"createdTime": $created_time, "name": $name, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve customer timeline custom event type with specified identifier string
#
# GET /customer-timeline-custom-events/{id}
# operationId: GetCustomerTimelineCustomEventType
export def "customer-timeline-custom-events get-type" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, createdTime: record, id: record, name: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customer-timeline-custom-events/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of customer timeline messages for all customers
#
# GET /customer-timeline-events
# operationId: GetCustomerTimelineEventCollection
export def "customer-timeline-events get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
]: nothing -> table<_links: list<record>, customData: record, customEventType: string, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer-timeline-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter} | compact), body: null}
}

# Retrieve a list of customers
#
# GET /customers
# operationId: GetCustomerCollection
export def "customers get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: record>, createdTime: record, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: record, invoiceCount: int, lastName: string, lastPaymentTime: record, lifetimeRevenue: record<amount: float, amountUsd: float, currency: record>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, revision: int, tags: list<record>, updatedTime: record, websiteId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "q": $q, "expand": $expand, "fields": $fields, "sort": $qp_sort} | compact), body: null}
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
export def "customers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The customer created time.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --default-payment-instrument: record # shape: {method?: "payment-card"|"ach"|"paypal", paymentInstrumentId?: any, receivedBy?: string, reference?: string}
  --last-payment-time: any # The most recent time of an approved payment for the customer.
  --payment-token: string # A write-only payment token; if supplied, it will be converted into a payment instrument and be set as the `defaultPaymentInstrument`. The value of this property will override the `defaultPaymentInstrument` in the case that both are supplied. The token may only be used once before it is expired.
  --primary-address: record # shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --updated-time: any # The customer updated time.
  --website-id: any # The website's ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers")
  let req_body = {"createdTime": $created_time, "customFields": $custom_fields, "defaultPaymentInstrument": $default_payment_instrument, "lastPaymentTime": $last_payment_time, "paymentToken": $payment_token, "primaryAddress": $primary_address, "updatedTime": $updated_time, "websiteId": $website_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Merge and delete a customer
#
# DELETE /customers/{id}
# operationId: DeleteCustomer
export def "customers delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-customer-id: string # The customer identifier to get the data of the deleted duplicate customer.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "targetCustomerId" $target_customer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"targetCustomerId": $target_customer_id} | compact), body: null}
}

# Retrieve a customer
#
# GET /customers/{id}
# operationId: GetCustomer
export def "customers get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
]: nothing -> record<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: record>, createdTime: record, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: record, invoiceCount: int, lastName: string, lastPaymentTime: record, lifetimeRevenue: record<amount: float, amountUsd: float, currency: record>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, revision: int, tags: table<_links: list, createdTime: record, id: record, name: string, updatedTime: record>, updatedTime: record, websiteId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
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
export def "customers update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The customer created time.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --default-payment-instrument: record # shape: {method?: "payment-card"|"ach"|"paypal", paymentInstrumentId?: any, receivedBy?: string, reference?: string}
  --last-payment-time: any # The most recent time of an approved payment for the customer.
  --payment-token: string # A write-only payment token; if supplied, it will be converted into a payment instrument and be set as the `defaultPaymentInstrument`. The value of this property will override the `defaultPaymentInstrument` in the case that both are supplied. The token may only be used once before it is expired.
  --primary-address: record # shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --updated-time: any # The customer updated time.
  --website-id: any # The website's ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}"))
  let req_body = {"createdTime": $created_time, "customFields": $custom_fields, "defaultPaymentInstrument": $default_payment_instrument, "lastPaymentTime": $last_payment_time, "paymentToken": $payment_token, "primaryAddress": $primary_address, "updatedTime": $updated_time, "websiteId": $website_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Lead Source for a customer
#
# DELETE /customers/{id}/lead-source
# operationId: DeleteCustomerLeadSource
export def "customers-lead-source delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/lead-source"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a customer's Lead Source
#
# GET /customers/{id}/lead-source
# operationId: GetCustomerLeadSource
export def "customers-lead-source get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: record, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string, original: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: record, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/lead-source"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a Lead Source for a customer
#
# PUT /customers/{id}/lead-source
# operationId: PutCustomerLeadSource
export def "customers-lead-source update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --affiliate: string # Lead source affiliate (eg 123, Bob Smith).
  --campaign: string # Lead source campaign (eg go-big-123).
  --click-id: string # Lead source click id (may come from an ad server).
  --content: string # Lead source content (eg smiley faces).
  --created-time: any # Lead source created time.
  --medium: string # Lead source medium (eg search, display).
  --path: string # Lead source path url (eg www.example.com/some/landing/path).
  --referrer: string # Lead source [`referer` url](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer) as determined (eg www.example.com/some/landing/path).
  --sales-agent: string # Lead source sales agent (eg James Bond).
  --body-source: string # Lead source origin (eg google, yahoo).
  --sub-affiliate: string # Lead source sub-affiliate also called a sub-id or click id in some circles (eg 123456).
  --term: string # Lead source term (eg salt shakers).
]: any -> record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: record, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string, original: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: record, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/lead-source"))
  let req_body = {"affiliate": $affiliate, "campaign": $campaign, "clickId": $click_id, "content": $content, "createdTime": $created_time, "medium": $medium, "path": $path, "referrer": $referrer, "salesAgent": $sales_agent, "source": $body_source, "subAffiliate": $sub_affiliate, "term": $term} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of customer timeline messages
#
# GET /customers/{id}/timeline
# operationId: GetCustomerTimelineCollection
export def "customers-timeline get-collection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, customData: record, customEventType: string, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/timeline") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort, "q": $q} | compact), body: null}
}

# Create a customer Timeline comment or custom defined event
#
# POST /customers/{id}/timeline
# operationId: PostCustomerTimeline
# --_links item shape: {rel: "self", href: string}
# --extraData shape: {actions?: list, author?: record, links?: list, mentions?: record, tables?: list}
export def "customers-timeline create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-data: record # Timeline custom event data. Used with `custom-event` type. Will be transformed to `extraData` two-column table in response. (e.g. {customAttribute: customValue, otherAttribute: otherValue})
  --custom-event-type: string # Timeline custom event type. Used with `custom-event` type. Must be defined using [Customer Timeline custom event API](#operation/PostCustomerTimelineCustomEventType). (nullable)
  --message: string # The message that describes the message details.
  --occurred-time: any # Timeline message time.
  --type: string@type-completer-2 # Timeline message type.
]: any -> record<_links: table<rel: string>, customData: record, customEventType: string, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/timeline"))
  let req_body = {"customData": $custom_data, "customEventType": $custom_event_type, "message": $message, "occurredTime": $occurred_time, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Customer Timeline message
#
# DELETE /customers/{id}/timeline/{messageId}
# operationId: DeleteCustomerTimeline
export def "customers-timeline delete" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/customers/{id}/timeline/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a customer Timeline message
#
# GET /customers/{id}/timeline/{messageId}
# operationId: GetCustomerTimeline
export def "customers-timeline get" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, customData: record, customEventType: string, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/customers/{id}/timeline/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve customer's upcoming invoices
#
# GET /customers/{id}/upcoming-invoices
# operationId: GetCustomerUpcomingInvoiceCollection
export def "customers-upcoming-invoices get-collection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: list<record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/upcoming-invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand} | compact), body: null}
}

# Validate a digital wallet session
#
# POST /digital-wallets/validation
# Discriminator (request): type = Apple Pay
# operationId: PostDigitalWalletValidation
export def "digital-wallets-validation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-3 # Type of the digital wallet to validate.
]: any -> record<type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/digital-wallets/validation")
  let req_body = {"type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of disputes
#
# GET /disputes
# operationId: GetDisputeCollection
export def "disputes get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "sort": $qp_sort, "limit": $limit, "offset": $offset, "q": $q, "expand": $expand} | compact), body: null}
}

# Create a dispute
#
# POST /disputes
# operationId: PostDispute
export def "disputes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acquirer-reference-number: string # The dispute's acquirer reference number.
  amount: float # The dispute amount. (format: double)
  --case-id: string # The case ID for the dispute.
  --created-time: any # Dispute created time.
  currency: any
  --deadline-time: string # Dispute deadline time. (format: date-time)
  posted_time: string # Dispute posted time. (format: date-time)
  reason_code: string@reason-code-completer # The dispute's reason code.
  --resolved-time: any # Dispute resolved time.
  status: string@status-completer # The dispute's status.
  transaction_id: string # The dispute's transaction ID.
  type: string@type-completer-4 # The dispute's type.
  --updated-time: any # Dispute updated time.
]: any -> record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: record, currency: record, customerId: string, deadlineTime: string, id: record, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: record, status: string, transactionId: string, type: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/disputes")
  let req_body = {"acquirerReferenceNumber": $acquirer_reference_number, "amount": $amount, "caseId": $case_id, "createdTime": $created_time, "currency": $currency, "deadlineTime": $deadline_time, "postedTime": $posted_time, "reasonCode": $reason_code, "resolvedTime": $resolved_time, "status": $status, "transactionId": $transaction_id, "type": $type, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a dispute
#
# GET /disputes/{id}
# operationId: GetDispute
export def "disputes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: record, currency: record, customerId: string, deadlineTime: string, id: record, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: record, status: string, transactionId: string, type: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/disputes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a Dispute with predefined ID
#
# PUT /disputes/{id}
# operationId: PutDispute
export def "disputes update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acquirer-reference-number: string # The dispute's acquirer reference number.
  amount: float # The dispute amount. (format: double)
  --case-id: string # The case ID for the dispute.
  --created-time: any # Dispute created time.
  currency: any
  --deadline-time: string # Dispute deadline time. (format: date-time)
  posted_time: string # Dispute posted time. (format: date-time)
  reason_code: string@reason-code-completer # The dispute's reason code.
  --resolved-time: any # Dispute resolved time.
  status: string@status-completer # The dispute's status.
  transaction_id: string # The dispute's transaction ID.
  type: string@type-completer-4 # The dispute's type.
  --updated-time: any # Dispute updated time.
]: any -> record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: record, currency: record, customerId: string, deadlineTime: string, id: record, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: record, status: string, transactionId: string, type: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/disputes/{id}"))
  let req_body = {"acquirerReferenceNumber": $acquirer_reference_number, "amount": $amount, "caseId": $case_id, "createdTime": $created_time, "currency": $currency, "deadlineTime": $deadline_time, "postedTime": $posted_time, "reasonCode": $reason_code, "resolvedTime": $resolved_time, "status": $status, "transactionId": $transaction_id, "type": $type, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of files
#
# GET /files
# operationId: GetFileCollection
export def "files get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<any>, createdTime: record, description: string, extension: string, height: int, id: record, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: record, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "q": $q, "expand": $expand, "fields": $fields, "sort": $qp_sort} | compact), body: null}
}

# Create a file
#
# POST /files
# operationId: PostFile
export def "files create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --description: string # The file description. (e.g. My file description)
  --file: string # The file in base64 encoded format. (e.g. R0lGODlhAQABAIAAAAUEBAAAACwAAAAAAQABAAACAkQBADs=)
  --is-public: oneof<nothing, bool> # The File visibility. If public a permalink is provided. (e.g. false)
  --name: string # The file name used for downloading. (e.g. logo.png)
  --tags: list<string> # The tags list. (e.g. [test, tags])
  --url: string # The URL of the file to upload. (e.g. https://blog.rebilly.com/wp-content/uploads/2017/09/rb_LogoInverted_Small.png)
]: any -> record<_links: list<any>, createdTime: record, description: string, extension: string, height: int, id: record, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: record, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let req_body = {"description": $description, "file": $file, "isPublic": $is_public, "name": $name, "tags": $tags, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a File
#
# DELETE /files/{id}
# operationId: DeleteFile
export def "files delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/files/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a File Record
#
# GET /files/{id}
# operationId: GetFile
export def "files get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: list<any>, createdTime: record, description: string, extension: string, height: int, id: record, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: record, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/files/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the File with predefined ID
#
# PUT /files/{id}
# operationId: PutFile
export def "files update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The upload date/time.
  --description: string # The File description.
  --extension: string # The File extension.
  --is-public: oneof<nothing, bool> # Is the file available publicly (without authentication). If true, the permalink in the _links section contains the public URL.
  --name: string # Original File name.
  --tags: list<string> # The tags list.
  --updated-time: any # The latest update date/time.
]: any -> record<_links: list<any>, createdTime: record, description: string, extension: string, height: int, id: record, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: record, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/files/{id}"))
  let req_body = {"createdTime": $created_time, "description": $description, "extension": $extension, "isPublic": $is_public, "name": $name, "tags": $tags, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download a file
#
# GET /files/{id}/download
# operationId: GetFileDownload
export def "files-download get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-size: string # Resize image to specified size. Supports any sizes from 10x10 to 2000x2000 (format `{width}x{height}`). The image will be returned in the original size if the value is invalid. This parameter will be ignored for non-image files. (e.g. 700x700)
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "imageSize" $image_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/files/{id}/download") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"imageSize": $image_size} | compact), body: null}
}

# Download image in specific format
#
# GET /files/{id}/download{extension}
# operationId: GetFileDownloadExtension
export def "files-downloadextension get-download" [
  id: string
  extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($extension | is-empty) { error make --unspanned { msg: "path parameter 'extension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), extension: (encode-path-segment $extension)} | format pattern "/files/{id}/download{extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of invoices
#
# GET /invoices
# operationId: GetInvoiceCollection
export def "invoices get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "sort": $qp_sort, "limit": $limit, "offset": $offset, "q": $q, "expand": $expand} | compact), body: null}
}

# Create an invoice
#
# POST /invoices
# operationId: PostInvoice
# --discounts item shape: {amount?: float, couponId?: any, description?: string, redemptionId?: any}
# --items item shape: {createdTime?: any, description?: string, periodEndTime?: string, periodNumber?: int, periodStartTime?: string, productId?: any, quantity?: int, type: "debit"|"credit", unitPrice: float, updatedTime?: any}
# --shipping shape: {calculator: "manual"|"rebilly"}
# --tax shape: {amount?: int, calculator: "manual"|"rebilly"}
# --retryInstruction shape: {afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list}
# --transactions item shape: {3ds?: any, billingAddress?: any, createdTime?: any, customFields?: record, customerId?: any, description?: string, paymentInstrument?: record, processedTime?: any, redirectUrl?: string, requestId?: string, updatedTime?: any, isMerchantInitiated?: bool, isProcessedOutside?: bool, method?: any, notificationUrl?: string, orderId?: string, retryInstruction?: record, riskMetadata?: any, scheduledTime?: string, velocity?: int}
export def "invoices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --abandoned-time: any # Invoice abandoned time.
  --autopay-scheduled-time: string # Invoice autopay scheduled time. (format: date-time)
  --billing-address: any # Invoice's billing address.
  --created-time: any # Invoice created time.
  currency: any
  --delivery-address: any # Invoice's delivery address.
  --due-time: any # Invoice due time.
  --issued-time: any # Invoice issued time.
  --notes: string # Notes for the customer which will be displayed on the invoice.
  --paid-time: any # Invoice paid time.
  --po-number: string # Purchase order number which will be displayed on the invoice. (nullable, e.g. PO123456)
  --shipping: record # Invoice shipping. — shape: {calculator: "manual"|"rebilly"}
  --tax: record # Invoice taxes. — shape: {amount?: int, calculator: "manual"|"rebilly"}
  --updated-time: any # Invoice updated time.
  --voided-time: any # Invoice voided time.
  website_id: any # The website ID.
  customer_id: any # The сustomer's ID.
  --due-reminder-time: any # Time past due reminder event will be triggered. (nullable)
  --retry-instruction: record # The invoice retry instruction. — shape: {afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list}
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoices")
  let req_body = {"abandonedTime": $abandoned_time, "autopayScheduledTime": $autopay_scheduled_time, "billingAddress": $billing_address, "createdTime": $created_time, "currency": $currency, "deliveryAddress": $delivery_address, "dueTime": $due_time, "issuedTime": $issued_time, "notes": $notes, "paidTime": $paid_time, "poNumber": $po_number, "shipping": $shipping, "tax": $tax, "updatedTime": $updated_time, "voidedTime": $voided_time, "websiteId": $website_id, "customerId": $customer_id, "dueReminderTime": $due_reminder_time, "retryInstruction": $retry_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve an invoice
#
# GET /invoices/{id}
# operationId: GetInvoice
export def "invoices get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --hdr-accept: string@accept-completer # The response media type.
]: nothing -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand} | compact), body: null}
}

# Create or update an invoice with predefined ID
#
# PUT /invoices/{id}
# operationId: PutInvoice
# --discounts item shape: {amount?: float, couponId?: any, description?: string, redemptionId?: any}
# --items item shape: {createdTime?: any, description?: string, periodEndTime?: string, periodNumber?: int, periodStartTime?: string, productId?: any, quantity?: int, type: "debit"|"credit", unitPrice: float, updatedTime?: any}
# --shipping shape: {calculator: "manual"|"rebilly"}
# --tax shape: {amount?: int, calculator: "manual"|"rebilly"}
# --retryInstruction shape: {afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list}
# --transactions item shape: {3ds?: any, billingAddress?: any, createdTime?: any, customFields?: record, customerId?: any, description?: string, paymentInstrument?: record, processedTime?: any, redirectUrl?: string, requestId?: string, updatedTime?: any, isMerchantInitiated?: bool, isProcessedOutside?: bool, method?: any, notificationUrl?: string, orderId?: string, retryInstruction?: record, riskMetadata?: any, scheduledTime?: string, velocity?: int}
export def "invoices update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --abandoned-time: any # Invoice abandoned time.
  --autopay-scheduled-time: string # Invoice autopay scheduled time. (format: date-time)
  --billing-address: any # Invoice's billing address.
  --created-time: any # Invoice created time.
  currency: any
  --delivery-address: any # Invoice's delivery address.
  --due-time: any # Invoice due time.
  --issued-time: any # Invoice issued time.
  --notes: string # Notes for the customer which will be displayed on the invoice.
  --paid-time: any # Invoice paid time.
  --po-number: string # Purchase order number which will be displayed on the invoice. (nullable, e.g. PO123456)
  --shipping: record # Invoice shipping. — shape: {calculator: "manual"|"rebilly"}
  --tax: record # Invoice taxes. — shape: {amount?: int, calculator: "manual"|"rebilly"}
  --updated-time: any # Invoice updated time.
  --voided-time: any # Invoice voided time.
  website_id: any # The website ID.
  customer_id: any # The сustomer's ID.
  --due-reminder-time: any # Time past due reminder event will be triggered. (nullable)
  --retry-instruction: record # The invoice retry instruction. — shape: {afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list}
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}"))
  let req_body = {"abandonedTime": $abandoned_time, "autopayScheduledTime": $autopay_scheduled_time, "billingAddress": $billing_address, "createdTime": $created_time, "currency": $currency, "deliveryAddress": $delivery_address, "dueTime": $due_time, "issuedTime": $issued_time, "notes": $notes, "paidTime": $paid_time, "poNumber": $po_number, "shipping": $shipping, "tax": $tax, "updatedTime": $updated_time, "voidedTime": $voided_time, "websiteId": $website_id, "customerId": $customer_id, "dueReminderTime": $due_reminder_time, "retryInstruction": $retry_instruction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Abandon an invoice
#
# POST /invoices/{id}/abandon
# operationId: PostInvoiceAbandonment
export def "invoices-abandon create-abandonment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/abandon"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Issue an invoice
#
# POST /invoices/{id}/issue
# operationId: PostInvoiceIssuance
export def "invoices-issue create-issuance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --due-time: string # Invoice due time. Will be set same as `issuedTime` if `null` or omitted. (nullable, format: date-time)
  --issued-time: string # Invoice issued time. Will be issued immediately if `null` or omitted. (nullable, format: date-time)
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/issue"))
  let req_body = {"dueTime": $due_time, "issuedTime": $issued_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve invoice items
#
# GET /invoices/{id}/items
# operationId: GetInvoiceItemCollection
export def "invoices-items get-collection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "expand": $expand} | compact), body: null}
}

# Create an invoice item
#
# POST /invoices/{id}/items
# operationId: PostInvoiceItem
export def "invoices-items create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Invoice item created time.
  --description: string # Invoice item's description.
  --period-end-time: string # End time. (format: date-time)
  --period-number: int # Invoice item subscription order period number.
  --period-start-time: string # Start time. (format: date-time)
  --product-id: any # The product's ID.
  --quantity: int # Invoice item's quantity.
  type: string@type-completer-5 # Invoice item's type.
  unit_price: float # Invoice item's price. (format: double)
  --updated-time: any # Invoice item updated time.
]: any -> record<_embedded: list<any>, _links: list<any>, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/items"))
  let req_body = {"createdTime": $created_time, "description": $description, "periodEndTime": $period_end_time, "periodNumber": $period_number, "periodStartTime": $period_start_time, "productId": $product_id, "quantity": $quantity, "type": $type, "unitPrice": $unit_price, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Recalculate an invoice
#
# POST /invoices/{id}/recalculate
# operationId: PostInvoiceRecalculation
export def "invoices-recalculate create-recalculation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/recalculate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reissue an invoice
#
# POST /invoices/{id}/reissue
# operationId: PostInvoiceReissuance
export def "invoices-reissue create-reissuance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --due-time: string # Invoice due time. Will be set as current date-time if `null` or omitted. (nullable, format: date-time)
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/reissue"))
  let req_body = {"dueTime": $due_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of invoice timeline messages
#
# GET /invoices/{id}/timeline
# operationId: GetInvoiceTimelineCollection
export def "invoices-timeline get-collection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/timeline") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort, "q": $q} | compact), body: null}
}

# Create an invoice Timeline comment
#
# POST /invoices/{id}/timeline
# operationId: PostInvoiceTimeline
# --_links item shape: {rel: "self", href: string}
# --extraData shape: {actions?: list, author?: record, links?: list, mentions?: record, tables?: list}
export def "invoices-timeline create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/timeline"))
  let req_body = {"message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an Invoice Timeline message
#
# DELETE /invoices/{id}/timeline/{messageId}
# operationId: DeleteInvoiceTimeline
export def "invoices-timeline delete" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/invoices/{id}/timeline/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an Invoice Timeline message
#
# GET /invoices/{id}/timeline/{messageId}
# operationId: GetInvoiceTimeline
export def "invoices-timeline get" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/invoices/{id}/timeline/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Apply a transaction to an invoice
#
# POST /invoices/{id}/transaction
# operationId: PostInvoiceTransaction
export def "invoices-transaction create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --amount: float # Amount which needs to be applied to the invoice. Can't be more than the transaction's amount. If omitted, the lesser of the transaction's unused amount or the invoice's amount due will be used. (format: double)
  transaction_id: string # Transaction to be applied to the invoice.
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/transaction"))
  let req_body = {"amount": $amount, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get transaction amounts allocated to an invoice
#
# GET /invoices/{id}/transaction-allocations
# operationId: GetInvoiceTransactionAllocationCollection
export def "invoices-transaction-allocations get-collection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<any>, amount: float, currency: record, invoiceId: string, transactionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/transaction-allocations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Void an invoice
#
# POST /invoices/{id}/void
# operationId: PostInvoiceVoid
export def "invoices-void create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}/void"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of KYC documents
#
# GET /kyc-documents
# operationId: GetKycDocumentCollection
export def "kyc-documents get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/kyc-documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort} | compact), body: null}
}

# Create a KYC Document
#
# POST /kyc-documents
# Discriminator (request): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocument
export def "kyc-documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kyc-documents")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a KYC Document
#
# GET /kyc-documents/{id}
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: GetKycDocument
export def "kyc-documents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a KYC document with predefined ID
#
# PUT /kyc-documents/{id}
# Discriminator (request): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PutKycDocument
export def "kyc-documents update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-documents/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Accept a KYC document
#
# POST /kyc-documents/{id}/acceptance
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentAcceptance
export def "kyc-documents-acceptance create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-documents/{id}/acceptance"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a KYC document's documentMatches
#
# POST /kyc-documents/{id}/matches
# operationId: PostKycDocumentMatches
export def "kyc-documents-matches create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --contains-image: oneof<nothing, bool> # Flag that indicates if there is an image that contains a face on it. (e.g. true)
  --date-of-birth: string # The date of birth found on the document, null if not found. (format: date-time)
  --expiry-date: string # The expiry date found on the document, null if not found. (format: date-time)
  --first-name: string # The customer first name if it was matched, null otherwise. (e.g. John)
  --is-identity-document: oneof<nothing, bool> # Flag that indicates if this looks like and ID. (e.g. true)
  --is-published-online: oneof<nothing, bool> # If there is an exact match found online. (e.g. false)
  --issue-date: string # The issued date found on the document, null if not found. (format: date-time)
  --last-name: string # The customer last name if it was matched, null otherwise. (e.g. Doe)
  --nationality: string # The nationality found on the document, null otherwise. (e.g. US)
  --city: string # The customer city if it was matched, null otherwise. (e.g. London)
  --date: string # The date on the document proving the document is recent. (format: date, e.g. 2021-01-01T00:00:00.000Z)
  --line1: string # The customer address if it was matched, null otherwise. (e.g. 36 Craven St)
  --phone: string # The phone of the company or agency that sent the document. (e.g. (123) 456-7890)
  --postal-code: string # The customer postal code if it was matched, null otherwise. (e.g. WC2N 5NF)
  --region: string # The customer region if it was matched, null otherwise. (e.g. London)
  --unique-words: int # The number of unique words in the document. (e.g. 175)
  --word-count: int # The number of words in the document. (e.g. 350)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-documents/{id}/matches"))
  let req_body = {"containsImage": $contains_image, "dateOfBirth": $date_of_birth, "expiryDate": $expiry_date, "firstName": $first_name, "isIdentityDocument": $is_identity_document, "isPublishedOnline": $is_published_online, "issueDate": $issue_date, "lastName": $last_name, "nationality": $nationality, "city": $city, "date": $date, "line1": $line1, "phone": $phone, "postalCode": $postal_code, "region": $region, "uniqueWords": $unique_words, "wordCount": $word_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reject a KYC document
#
# POST /kyc-documents/{id}/rejection
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentRejection
export def "kyc-documents-rejection create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The rejection message. (e.g. Provided document is unreadable)
  --type: string@type-completer-6
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-documents/{id}/rejection"))
  let req_body = {"message": $message, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Review a KYC document
#
# POST /kyc-documents/{id}/review
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentReview
export def "kyc-documents-review create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-documents/{id}/review"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of KYC requests
#
# GET /kyc-requests
# operationId: GetKycRequestCollection
export def "kyc-requests get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<createdTime: record, documents: list<record>, expirationTime: string, id: record, redirectUrl: string, updatedTime: record, _links: list<any>, customerId: record, matchLevel: int, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/kyc-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort} | compact), body: null}
}

# Create a KYC Request
#
# POST /kyc-requests
# operationId: PostKycRequest
# --documents item shape: {maxAttempts?: int, subtypes?: list<string>, type: any}
export def "kyc-requests create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Creation date/time.
  documents: list # Documents to be requested from customer. — item shape: {maxAttempts?: int, subtypes?: list<string>, type: any}
  --expiration-time: string # Expiration date/time. (format: date-time)
  --redirect-url: string # The URL to redirect the customer when an upload is completed. (format: uri)
  --updated-time: any # Latest update date/time.
  customer_id: any # The сustomer's ID.
  --match-level: int # The level of strictness for the document matches. (e.g. 2)
  --reason: string # Reason for uploading.
]: any -> record<createdTime: record, documents: table<maxAttempts: int, subtypes: list, type: record>, expirationTime: string, id: record, redirectUrl: string, updatedTime: record, _links: list<any>, customerId: record, matchLevel: int, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kyc-requests")
  let req_body = {"createdTime": $created_time, "documents": $documents, "expirationTime": $expiration_time, "redirectUrl": $redirect_url, "updatedTime": $updated_time, "customerId": $customer_id, "matchLevel": $match_level, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the KYC request
#
# DELETE /kyc-requests/{id}
# operationId: DeleteKycRequest
export def "kyc-requests delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-requests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a KYC request
#
# GET /kyc-requests/{id}
# operationId: GetKycRequest
export def "kyc-requests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<createdTime: record, documents: table<maxAttempts: int, subtypes: list, type: record>, expirationTime: string, id: record, redirectUrl: string, updatedTime: record, _links: list<any>, customerId: record, matchLevel: int, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-requests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a KYC request
#
# PATCH /kyc-requests/{id}
# operationId: PatchKycRequest
export def "kyc-requests update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --body: record
]: any -> record<createdTime: record, documents: table<maxAttempts: int, subtypes: list, type: record>, expirationTime: string, id: record, redirectUrl: string, updatedTime: record, _links: list<any>, customerId: record, matchLevel: int, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kyc-requests/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of tokens
#
# GET /password-tokens
# operationId: GetPasswordTokenCollection
export def "password-tokens get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> table<_links: list<record>, credentialId: string, expiredTime: string, token: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/password-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Create a Reset Password Token
#
# POST /password-tokens
# operationId: PostPasswordToken
# --_links item shape: {rel: "self", href: string}
export def "password-tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --expired-time: string # Password expired time. (format: date-time)
  username: string # The token's username.
]: any -> record<_links: table<rel: string>, credentialId: string, expiredTime: string, token: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/password-tokens")
  let req_body = {"expiredTime": $expired_time, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Reset Password Token
#
# DELETE /password-tokens/{id}
# operationId: DeletePasswordToken
export def "password-tokens delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/password-tokens/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a Reset Password Token
#
# GET /password-tokens/{id}
# operationId: GetPasswordToken
export def "password-tokens get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, credentialId: string, expiredTime: string, token: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/password-tokens/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of Payment Cards
#
# GET /payment-cards
# operationId: GetPaymentCardCollection
export def "payment-cards get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment-cards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort, "q": $q, "expand": $expand} | compact), body: null}
}

# Create a Payment Card
#
# POST /payment-cards
# operationId: PostPaymentCard
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "payment-cards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --customer-id: any # The Customer's ID.
  --body-token: string # PaymentCardToken ID.
  --billing-address: any # The billing address.
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
]: any -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment-cards")
  let req_body = {"customFields": $custom_fields, "customerId": $customer_id, "token": $body_token, "billingAddress": $billing_address, "cvv": $cvv, "expMonth": $exp_month, "expYear": $exp_year, "method": $method, "pan": $pan, "riskMetadata": $risk_metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a Payment Card
#
# GET /payment-cards/{id}
# operationId: GetPaymentCard
export def "payment-cards get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-cards/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a payment card's values
#
# PATCH /payment-cards/{id}
# operationId: PatchPaymentCard
export def "payment-cards update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billing-address: any # The billing address.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --sticky-gateway-account-id: any # Sticky gateway account ID.
]: any -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-cards/{id}"))
  let req_body = {"billingAddress": $billing_address, "customFields": $custom_fields, "cvv": $cvv, "expMonth": $exp_month, "expYear": $exp_year, "stickyGatewayAccountId": $sticky_gateway_account_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a payment card with predefined ID
#
# PUT /payment-cards/{id}
# operationId: PutPaymentCard
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "payment-cards update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --customer-id: any # The Customer's ID.
  --body-token: string # PaymentCardToken ID.
  --billing-address: any # The billing address.
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
]: any -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-cards/{id}"))
  let req_body = {"customFields": $custom_fields, "customerId": $customer_id, "token": $body_token, "billingAddress": $billing_address, "cvv": $cvv, "expMonth": $exp_month, "expYear": $exp_year, "method": $method, "pan": $pan, "riskMetadata": $risk_metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deactivate a Payment Card
#
# POST /payment-cards/{id}/deactivation
# operationId: PostPaymentCardDeactivation
export def "payment-cards-deactivation create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: record, createdTime: record, customFields: record, customerId: record, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: record, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: record, stickyGatewayAccountId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-cards/{id}/deactivation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of payment instruments
#
# GET /payment-instruments
# operationId: GetPaymentInstrumentCollection
export def "payment-instruments get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "sort": $qp_sort, "limit": $limit, "offset": $offset, "q": $q, "expand": $expand} | compact), body: null}
}

# Create a Payment Instrument
#
# POST /payment-instruments
# operationId: PostPaymentInstrument
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "payment-instruments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --customer-id: any # The customer's ID.
  --body-token: string # Payment token ID.
  --billing-address: any # The billing address.
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment-instruments")
  let req_body = {"customFields": $custom_fields, "customerId": $customer_id, "token": $body_token, "billingAddress": $billing_address, "cvv": $cvv, "expMonth": $exp_month, "expYear": $exp_year, "method": $method, "pan": $pan, "riskMetadata": $risk_metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a Payment Instrument
#
# GET /payment-instruments/{id}
# operationId: GetPaymentInstrument
export def "payment-instruments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-instruments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Payment Instrument's values
#
# PATCH /payment-instruments/{id}
# operationId: PatchPaymentInstrument
export def "payment-instruments update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billing-address: any # The billing address (if supplied – overrides billing address from token).
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --body-token: string # Payment token ID.
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --sticky-gateway-account-id: any # Sticky gateway account ID.
  --account-type: string@account-type-completer # Bank's account type.
  --bank-name: string # Bank's name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-instruments/{id}"))
  let req_body = {"billingAddress": $billing_address, "customFields": $custom_fields, "token": $body_token, "cvv": $cvv, "expMonth": $exp_month, "expYear": $exp_year, "stickyGatewayAccountId": $sticky_gateway_account_id, "accountType": $account_type, "bankName": $bank_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deactivate a payment instrument
#
# POST /payment-instruments/{id}/deactivation
# operationId: PostPaymentInstrumentDeactivation
export def "payment-instruments-deactivation create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-instruments/{id}/deactivation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a credit transaction
#
# POST /payouts
# operationId: PostPayout
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
@deprecated --flag payment-instrument
export def "payouts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # The transaction amount. (format: double, e.g. 97.97)
  --billing-address: any # Billing address. If not supplied, we use the billing address associated with the payment instrument, and then customer. (nullable)
  currency: any
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: any # The customer identifier string.
  --description: string # The payment description. (nullable)
  --gateway-account-id: any # Rebilly will select the appropriate payment gateway account for the transaction based on the properties of the transaction and the `gateway-account-requested` event rules configurations. If you wish to prevent Rebilly from making the gateway account selection, you may supply a gateway account id here, and it will be used instead. Only use this field if you intend to override the settings. (nullable)
  --invoice-ids: list<string> # The array of invoice identifiers. (nullable)
  --is-merchant-initiated: oneof<nothing, bool> # True if the transaction was initiated by the merchant. (default: false)
  --is-processed-outside: oneof<nothing, bool> # True if transaction was processed outside Rebilly. (default: false)
  --notification-url: string # The URL where a server-to-server notification request type `POST` with a transaction payload will be sent when the transaction's result is finalized. Do not trust the notification; follow with a `GET` request to confirm the result of the transaction. Please respond with a `2xx` HTTP status code, or we will reattempt the request again. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --payment-instruction: any # Payment instruction. If not supplied, customer's default payment instrument will be used.
  --payment-instrument: any # DEPRECATED
  --processed-time: string # The time the transaction was processed. Can be specified only if transaction was processed outside Rebilly. (format: date-time)
  --redirect-url: string # The URL to redirect the end-user when an offsite transaction is completed. Defaults to the website's configured URL. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --request-id: string # The request id is **recommended**. It prevents duplicate transaction requests within a short period of time. If a duplicate request is sent with the same `requestId` it will be ignored to prevent double-billing anyone. It must be unique within a 24-hour period. We recommend generating a UUID v4 as its value. (nullable, e.g. 44433322-2c4y-483z-a0a9-158621f77a21)
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  website_id: any # The website identifier string.
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payouts")
  let req_body = {"amount": $amount, "billingAddress": $billing_address, "currency": $currency, "customFields": $custom_fields, "customerId": $customer_id, "description": $description, "gatewayAccountId": $gateway_account_id, "invoiceIds": $invoice_ids, "isMerchantInitiated": $is_merchant_initiated, "isProcessedOutside": $is_processed_outside, "notificationUrl": $notification_url, "paymentInstruction": $payment_instruction, "paymentInstrument": $payment_instrument, "processedTime": $processed_time, "redirectUrl": $redirect_url, "requestId": $request_id, "riskMetadata": $risk_metadata, "websiteId": $website_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of PayPal accounts
#
# GET /paypal-accounts
# operationId: GetPayPalAccountCollection
export def "paypal-accounts get-pay-pal-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "sort": $qp_sort, "limit": $limit, "offset": $offset, "q": $q, "expand": $expand} | compact), body: null}
}

# Create a PayPal Account
#
# POST /paypal-accounts
# operationId: PostPayPalAccount
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "paypal-accounts create-pay-pal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  billing_address: any # The billing address.
  --created-time: any # PayPal account created time.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: any # The customer's ID.
  method: string@method-completer-1 # The method of payment instrument.
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  --updated-time: any # PayPal account updated time.
]: any -> record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paypal-accounts")
  let req_body = {"billingAddress": $billing_address, "createdTime": $created_time, "customFields": $custom_fields, "customerId": $customer_id, "method": $method, "riskMetadata": $risk_metadata, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a PayPal Account
#
# GET /paypal-accounts/{id}
# operationId: GetPayPalAccount
export def "paypal-accounts get-pay-pal" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paypal-accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a PayPal account with predefined ID
#
# PUT /paypal-accounts/{id}
# operationId: PutPayPalAccount
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "paypal-accounts update-pay-pal" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  billing_address: any # The billing address.
  --created-time: any # PayPal account created time.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: any # The customer's ID.
  method: string@method-completer-1 # The method of payment instrument.
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  --updated-time: any # PayPal account updated time.
]: any -> record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paypal-accounts/{id}"))
  let req_body = {"billingAddress": $billing_address, "createdTime": $created_time, "customFields": $custom_fields, "customerId": $customer_id, "method": $method, "riskMetadata": $risk_metadata, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deactivate a PayPal Account
#
# POST /paypal-accounts/{id}/deactivation
# operationId: PostPayPalAccountDeactivation
export def "paypal-accounts-deactivation create-pay-pal" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: record, customFields: record, customerId: record, id: record, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: record, username: string, _embedded: list<any>, _links: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paypal-accounts/{id}/deactivation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of plans
#
# GET /plans
# operationId: GetPlanCollection
export def "plans get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "sort": $qp_sort, "limit": $limit, "offset": $offset, "q": $q} | compact), body: null}
}

# Create a plan
#
# POST /plans
# operationId: PostPlan
# --pricing shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
# --setup shape: {price: float}
# --trial shape: {period: record, price: float}
# --_links item shape: {rel: "self", href: string}
export def "plans create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Plan created time.
  currency: any
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  name: string # The plan name, displayed on invoices and receipts.
  pricing: record # shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
  product_id: any # The related product ID.
  --product-options: record # Name-value pairs to specify the product options. (e.g. {color: red, size: xxl})
  --recurring-interval: any # The service interval. For a one-time item, use `null`.
  --setup: record # The setup. Set `null` if no setup. — shape: {price: float}
  --trial: record # The trial. Set `null` if no trial. — shape: {period: record, price: float}
  --updated-time: any # Plan updated time.
  --invoice-time-shift: any # You can shift issue time and due time of invoices for this plan.
]: any -> record<createdTime: record, currency: record, currencySign: string, customFields: record, id: record, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: record, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: record, _links: table<rel: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/plans")
  let req_body = {"createdTime": $created_time, "currency": $currency, "customFields": $custom_fields, "name": $name, "pricing": $pricing, "productId": $product_id, "productOptions": $product_options, "recurringInterval": $recurring_interval, "setup": $setup, "trial": $trial, "updatedTime": $updated_time, "invoiceTimeShift": $invoice_time_shift} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Plan
#
# DELETE /plans/{id}
# operationId: DeletePlan
export def "plans delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/plans/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a plan
#
# GET /plans/{id}
# operationId: GetPlan
export def "plans get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<createdTime: record, currency: record, currencySign: string, customFields: record, id: record, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: record, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: record, _links: table<rel: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/plans/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a Plan with predefined ID
#
# PUT /plans/{id}
# operationId: PutPlan
# --pricing shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
# --setup shape: {price: float}
# --trial shape: {period: record, price: float}
# --_links item shape: {rel: "self", href: string}
export def "plans update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # Plan created time.
  currency: any
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  name: string # The plan name, displayed on invoices and receipts.
  pricing: record # shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
  product_id: any # The related product ID.
  --product-options: record # Name-value pairs to specify the product options. (e.g. {color: red, size: xxl})
  --recurring-interval: any # The service interval. For a one-time item, use `null`.
  --setup: record # The setup. Set `null` if no setup. — shape: {price: float}
  --trial: record # The trial. Set `null` if no trial. — shape: {period: record, price: float}
  --updated-time: any # Plan updated time.
  --invoice-time-shift: any # You can shift issue time and due time of invoices for this plan.
]: any -> record<createdTime: record, currency: record, currencySign: string, customFields: record, id: record, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: record, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: record, _links: table<rel: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/plans/{id}"))
  let req_body = {"createdTime": $created_time, "currency": $currency, "customFields": $custom_fields, "name": $name, "pricing": $pricing, "productId": $product_id, "productOptions": $product_options, "recurringInterval": $recurring_interval, "setup": $setup, "trial": $trial, "updatedTime": $updated_time, "invoiceTimeShift": $invoice_time_shift} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of products
#
# GET /products
# operationId: GetProductCollection
export def "products get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "sort": $qp_sort, "limit": $limit, "offset": $offset, "q": $q} | compact), body: null}
}

# Create a Product
#
# POST /products
# operationId: PostProduct
# --_links item shape: {rel: "self", href: string}
export def "products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The product created time.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --description: string # The product description.
  name: string # The product name. (e.g. Premium membership)
  --options: list<string> # The product options such as color, size, etc. The product options definition does not include option values. Those are defined within the plans.
  --requires-shipping: oneof<nothing, bool> # If the product requires shipping, shipping calculations will be applied. (e.g. false)
  --unit-label: string # The unit label, such as per `seat` or per `unit`. (default: unit, e.g. seat)
  --updated-time: any # The product updated time.
  --accounting-code: string # The product accounting code. (e.g. 4010)
  --tax-category-id: string@tax-category-id-completer # The product's tax category identifier string.
]: any -> record<createdTime: record, customFields: record, description: string, id: record, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: record, _links: table<rel: string>, accountingCode: string, taxCategoryId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products")
  let req_body = {"createdTime": $created_time, "customFields": $custom_fields, "description": $description, "name": $name, "options": $options, "requiresShipping": $requires_shipping, "unitLabel": $unit_label, "updatedTime": $updated_time, "accountingCode": $accounting_code, "taxCategoryId": $tax_category_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a product
#
# DELETE /products/{id}
# operationId: DeleteProduct
export def "products delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a product
#
# GET /products/{id}
# operationId: GetProduct
export def "products get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<createdTime: record, customFields: record, description: string, id: record, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: record, _links: table<rel: string>, accountingCode: string, taxCategoryId: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a product with predefined ID
#
# PUT /products/{id}
# operationId: PutProduct
# --_links item shape: {rel: "self", href: string}
export def "products update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The product created time.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --description: string # The product description.
  name: string # The product name. (e.g. Premium membership)
  --options: list<string> # The product options such as color, size, etc. The product options definition does not include option values. Those are defined within the plans.
  --requires-shipping: oneof<nothing, bool> # If the product requires shipping, shipping calculations will be applied. (e.g. false)
  --unit-label: string # The unit label, such as per `seat` or per `unit`. (default: unit, e.g. seat)
  --updated-time: any # The product updated time.
  --accounting-code: string # The product accounting code. (e.g. 4010)
  --tax-category-id: string@tax-category-id-completer # The product's tax category identifier string.
]: any -> record<createdTime: record, customFields: record, description: string, id: record, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: record, _links: table<rel: string>, accountingCode: string, taxCategoryId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}"))
  let req_body = {"createdTime": $created_time, "customFields": $custom_fields, "description": $description, "name": $name, "options": $options, "requiresShipping": $requires_shipping, "unitLabel": $unit_label, "updatedTime": $updated_time, "accountingCode": $accounting_code, "taxCategoryId": $tax_category_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Ready to Pay
#
# POST /ready-to-pay
# operationId: PostReadyToPay
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
export def "ready-to-pay create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customer-id: any # The customer identifier string.
  --billing-address: any # The billing address.
  risk_metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  website_id: any # The website identifier string.
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ready-to-pay")
  let req_body = {"customerId": $customer_id, "billingAddress": $billing_address, "riskMetadata": $risk_metadata, "websiteId": $website_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search merchant data
#
# GET /search
# operationId: GetSearch
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "limit": $limit, "offset": $offset, "q": $q} | compact), body: null}
}

# Retrieve a list of shipping zones
#
# GET /shipping-zones
# operationId: GetShippingZoneCollection
export def "shipping-zones get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, countries: list<string>, createdTime: record, id: record, isDefault: any, name: string, rates: list<record>, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipping-zones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort, "q": $q} | compact), body: null}
}

# Create a Shipping Zone
#
# POST /shipping-zones
# operationId: PostShippingZone
# --_links item shape: {rel: "self", href: string}
# --rates item shape: {currency: any, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
export def "shipping-zones create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --countries: list<string> # Countries covered by the shipping zone. A country can only belong to one shipping zone (no overlapping). This property can be empty or null to create a default shipping zone for countries that were not specified in other zones.
  --created-time: any # The shipping zone created time.
  name: string # The shipping zone name.
  --rates: list # Price-based shipping rate instructions. — item shape: {currency: any, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
  --updated-time: any # The shipping zone updated time.
]: any -> record<_links: table<rel: string>, countries: list<string>, createdTime: record, id: record, isDefault: any, name: string, rates: table<_links: list, currency: record, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipping-zones")
  let req_body = {"countries": $countries, "createdTime": $created_time, "name": $name, "rates": $rates, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a shipping zone
#
# DELETE /shipping-zones/{id}
# operationId: DeleteShippingZone
export def "shipping-zones delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/shipping-zones/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a shipping zone
#
# GET /shipping-zones/{id}
# operationId: GetShippingZone
export def "shipping-zones get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, countries: list<string>, createdTime: record, id: record, isDefault: any, name: string, rates: table<_links: list, currency: record, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/shipping-zones/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a shipping zone with predefined ID
#
# PUT /shipping-zones/{id}
# operationId: PutShippingZone
# --_links item shape: {rel: "self", href: string}
# --rates item shape: {currency: any, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
export def "shipping-zones update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --countries: list<string> # Countries covered by the shipping zone. A country can only belong to one shipping zone (no overlapping). This property can be empty or null to create a default shipping zone for countries that were not specified in other zones.
  --created-time: any # The shipping zone created time.
  name: string # The shipping zone name.
  --rates: list # Price-based shipping rate instructions. — item shape: {currency: any, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
  --updated-time: any # The shipping zone updated time.
]: any -> record<_links: table<rel: string>, countries: list<string>, createdTime: record, id: record, isDefault: any, name: string, rates: table<_links: list, currency: record, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/shipping-zones/{id}"))
  let req_body = {"countries": $countries, "createdTime": $created_time, "name": $name, "rates": $rates, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of cancellations
#
# GET /subscription-cancellations
# operationId: GetSubscriptionCancellationCollection
export def "subscription-cancellations get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<record>, appliedInvoiceId: record, canceledBy: string, canceledTime: string, churnTime: string, createdTime: record, description: string, id: record, lineItemSubtotal: float, lineItems: record, prorated: bool, proratedInvoiceId: record, reason: string, status: string, subscriptionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/subscription-cancellations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort} | compact), body: null}
}

# Cancel an order
#
# POST /subscription-cancellations
# operationId: PostSubscriptionCancellation
# --_links item shape: {rel: "self", href: string}
export def "subscription-cancellations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --canceled-by: string@canceled-by-completer # Who did the cancellation. (default: customer)
  churn_time: string # The time when the subscription will be deactivated. (format: date-time)
  --created-time: any # The time of resource creation (when it is posted).
  --description: string # Cancel reason description in free form.
  --line-items: any # Items to be added to the new invoice. Proration item is generated and added automatically.
  --prorated: oneof<nothing, bool> # Defines if the customer gets a pro-rata credit for the time remaining between `churnTime` and subscription's next renewal time. (default: false)
  --reason: string@reason-completer # Cancellation reason. (default: other)
  --status: string@status-completer-1 # "draft" defines that the cancellation isn't applied on an invoice and subscription but can be inspected to see the charge. "confirmed" will set a subscription to be canceled when the `churnTime` is reached. "completed" is a read-only status which is set by the system when the churnTime is reached. The cancellation may not be changed or deleted when the status is "completed". (default: confirmed)
  subscription_id: any # Identifier of the canceled subscription order.
]: any -> record<_links: table<rel: string>, appliedInvoiceId: record, canceledBy: string, canceledTime: string, churnTime: string, createdTime: record, description: string, id: record, lineItemSubtotal: float, lineItems: record, prorated: bool, proratedInvoiceId: record, reason: string, status: string, subscriptionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription-cancellations")
  let req_body = {"canceledBy": $canceled_by, "churnTime": $churn_time, "createdTime": $created_time, "description": $description, "lineItems": $line_items, "prorated": $prorated, "reason": $reason, "status": $status, "subscriptionId": $subscription_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a cancellation
#
# DELETE /subscription-cancellations/{id}
# operationId: DeleteSubscriptionCancellation
export def "subscription-cancellations delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscription-cancellations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an order сancellation
#
# GET /subscription-cancellations/{id}
# operationId: GetSubscriptionCancellation
export def "subscription-cancellations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, appliedInvoiceId: record, canceledBy: string, canceledTime: string, churnTime: string, createdTime: record, description: string, id: record, lineItemSubtotal: float, lineItems: record, prorated: bool, proratedInvoiceId: record, reason: string, status: string, subscriptionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscription-cancellations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel an order
#
# PUT /subscription-cancellations/{id}
# operationId: PutSubscriptionCancellation
# --_links item shape: {rel: "self", href: string}
export def "subscription-cancellations update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --canceled-by: string@canceled-by-completer # Who did the cancellation. (default: customer)
  churn_time: string # The time when the subscription will be deactivated. (format: date-time)
  --created-time: any # The time of resource creation (when it is posted).
  --description: string # Cancel reason description in free form.
  --line-items: any # Items to be added to the new invoice. Proration item is generated and added automatically.
  --prorated: oneof<nothing, bool> # Defines if the customer gets a pro-rata credit for the time remaining between `churnTime` and subscription's next renewal time. (default: false)
  --reason: string@reason-completer # Cancellation reason. (default: other)
  --status: string@status-completer-1 # "draft" defines that the cancellation isn't applied on an invoice and subscription but can be inspected to see the charge. "confirmed" will set a subscription to be canceled when the `churnTime` is reached. "completed" is a read-only status which is set by the system when the churnTime is reached. The cancellation may not be changed or deleted when the status is "completed". (default: confirmed)
  subscription_id: any # Identifier of the canceled subscription order.
]: any -> record<_links: table<rel: string>, appliedInvoiceId: record, canceledBy: string, canceledTime: string, churnTime: string, createdTime: record, description: string, id: record, lineItemSubtotal: float, lineItems: record, prorated: bool, proratedInvoiceId: record, reason: string, status: string, subscriptionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscription-cancellations/{id}"))
  let req_body = {"canceledBy": $canceled_by, "churnTime": $churn_time, "createdTime": $created_time, "description": $description, "lineItems": $line_items, "prorated": $prorated, "reason": $reason, "status": $status, "subscriptionId": $subscription_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of reactivations
#
# GET /subscription-reactivations
# operationId: GetSubscriptionReactivationCollection
export def "subscription-reactivations get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<record>, cancellationId: record, createdTime: string, description: string, effectiveTime: string, id: record, renewalTime: string, subscriptionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/subscription-reactivations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort} | compact), body: null}
}

# Reactivate an order
#
# POST /subscription-reactivations
# operationId: PostSubscriptionReactivation
# --_links item shape: {rel: "self", href: string}
export def "subscription-reactivations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --description: string # Reactivation reason description in free form.
  --effective-time: string # The date from which the service period would start, unless the subscription is canceled but still active. In case the susbcription is still active, the subscription will continue the current service period. If omitted, it will default to the current time. (format: date-time)
  --renewal-time: string # The time of the next subscription renewal. If omitted then it is computed from the effective time. If the subscription is canceled but active it is ignored, so the next renewal will happen as scheduled. (format: date-time)
  subscription_id: any # Identifier of the reactivated subscription.
]: any -> record<_links: table<rel: string>, cancellationId: record, createdTime: string, description: string, effectiveTime: string, id: record, renewalTime: string, subscriptionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription-reactivations")
  let req_body = {"description": $description, "effectiveTime": $effective_time, "renewalTime": $renewal_time, "subscriptionId": $subscription_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve an order reactivation
#
# GET /subscription-reactivations/{id}
# operationId: GetSubscriptionReactivation
export def "subscription-reactivations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, cancellationId: record, createdTime: string, description: string, effectiveTime: string, id: record, renewalTime: string, subscriptionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscription-reactivations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of orders
#
# GET /subscriptions
# operationId: GetSubscriptionCollection
export def "subscriptions get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are: - recentInvoice - initialInvoice - customer - website See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<orderType: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "sort": $qp_sort, "limit": $limit, "offset": $offset, "q": $q, "expand": $expand} | compact), body: null}
}

# Create an order
#
# POST /subscriptions
# Discriminator (request): orderType = one-time-order, subscription-order
# operationId: PostSubscription
export def "subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are: - recentInvoice - initialInvoice - customer - website See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  order_type: string@order-type-completer # Specifies the type of order, a subscription or a one-time purchase.
]: any -> record<orderType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let req_body = {"orderType": $order_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"expand": $expand} | compact), body: $req_body}
}

# Retrieve an order
#
# GET /subscriptions/{id}
# Discriminator (response): orderType = one-time-order, subscription-order
# operationId: GetSubscription
export def "subscriptions get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are: - recentInvoice - initialInvoice - customer - website See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> record<orderType: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand} | compact), body: null}
}

# Upsert an order with predefined ID
#
# PUT /subscriptions/{id}
# Discriminator (request): orderType = one-time-order, subscription-order
# operationId: PutSubscription
export def "subscriptions update" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are: - recentInvoice - initialInvoice - customer - website See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  order_type: string@order-type-completer # Specifies the type of order, a subscription or a one-time purchase.
]: any -> record<orderType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}") $qp)
  let req_body = {"orderType": $order_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"expand": $expand} | compact), body: $req_body}
}

# Change an order's items
#
# POST /subscriptions/{id}/change-items
# Discriminator (response): orderType = one-time-order, subscription-order
# operationId: PostSubscriptionItemsChange
# --items item shape: {plan: any, quantity: int}
export def "subscriptions-change-items create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --effective-time: string # The date from which the renewal time (for `reset` operations) and proration calculations are made. If omitted, it will default to the current time. (format: date-time)
  items: list # item shape: {plan: any, quantity: int}
  --keep-trial: oneof<nothing, bool> # If set to true and the subscription order has an active trial, it will use that trial further. Works with 'retain' renewalPolicy only. (default: false)
  --preview: oneof<nothing, bool> # If set to true, it will not change the subscription. It allows for a way to preview the changes that would be made to a subscription. (default: false)
  --prorated: oneof<nothing, bool> # Whether or not to give a pro rata credit for the amount of time remaining between the `effectiveTime` and the end of the current period. In addition, if the `renewalTime` is retained (by setting the `renewalPolicy` to `retain`), then a pro rata debit will occur as well, for the amount between the `effectiveTime` and the `renewalTime` as a percentage of the normal period size.
  renewal_policy: string@renewal-policy-completer # The value determines whether the subscription retains its current `renewalTime` or resets it to a newly calculated `renewalTime`.
]: any -> record<orderType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}/change-items"))
  let req_body = {"effectiveTime": $effective_time, "items": $items, "keepTrial": $keep_trial, "preview": $preview, "prorated": $prorated, "renewalPolicy": $renewal_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Issue an interim invoice for a subscription order
#
# POST /subscriptions/{id}/interim-invoice
# operationId: PostSubscriptionInterimInvoice
export def "subscriptions-interim-invoice create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --transaction-id: any # If present, applies a payment to the invoice created. If the payment is for the invoice total, it would be marked as paid.
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}/interim-invoice"))
  let req_body = {"transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of order timeline messages
#
# GET /subscriptions/{id}/timeline
# operationId: GetSubscriptionTimelineCollection
export def "subscriptions-timeline get-collection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
]: nothing -> table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}/timeline") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort, "q": $q} | compact), body: null}
}

# Create an order Timeline comment
#
# POST /subscriptions/{id}/timeline
# operationId: PostSubscriptionTimeline
# --_links item shape: {rel: "self", href: string}
# --extraData shape: {actions?: list, author?: record, links?: list, mentions?: record, tables?: list}
export def "subscriptions-timeline create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}/timeline"))
  let req_body = {"message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an Order Timeline message
#
# DELETE /subscriptions/{id}/timeline/{messageId}
# operationId: DeleteSubscriptionTimeline
export def "subscriptions-timeline delete" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/subscriptions/{id}/timeline/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an Order Timeline message
#
# GET /subscriptions/{id}/timeline/{messageId}
# operationId: GetSubscriptionTimeline
export def "subscriptions-timeline get" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/subscriptions/{id}/timeline/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve subscription order's upcoming invoice
#
# GET /subscriptions/{id}/upcoming-invoices
# operationId: GetSubscriptionUpcomingInvoiceCollection
export def "subscriptions-upcoming-invoices get-collection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: list<record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}/upcoming-invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand} | compact), body: null}
}

# Issue an upcoming invoice for early pay
#
# POST /subscriptions/{id}/upcoming-invoices/{invoiceId}/issue
# operationId: PostUpcomingInvoiceIssuance
export def "subscriptions-upcoming-invoices-issue create-issuance" [
  id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --due-time: string # Invoice due time. Will be set same as `issuedTime` if `null` or omitted. (nullable, format: date-time)
  --issued-time: string # Invoice issued time. Will be issued immediately if `null` or omitted. (nullable, format: date-time)
]: any -> record<abandonedTime: record, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: record, currency: record, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: record, description: string, redemptionId: record>, dueTime: record, id: record, invoiceNumber: int, issuedTime: record, items: table<_embedded: list, _links: list, createdTime: record, description: string, discountAmount: float, id: record, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: record, quantity: int, type: string, unitPrice: float, updatedTime: record>, notes: string, paidTime: record, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: record, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: record, voidedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, customerId: record, dueReminderNumber: int, dueReminderTime: record, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<3ds: record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: record, websiteId: record, _embedded: list, _links: list, acquirerName: record, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/subscriptions/{id}/upcoming-invoices/{invoice_id}/issue"))
  let req_body = {"dueTime": $due_time, "issuedTime": $issued_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of tags
#
# GET /tags
# operationId: GetTagCollection
export def "tags get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
]: nothing -> table<_links: list<any>, createdTime: record, id: record, name: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "q": $q, "sort": $qp_sort} | compact), body: null}
}

# Create a tag
#
# POST /tags
# operationId: PostTag
export def "tags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The tag's created time.
  name: string # The tag is unique name, which is case-insensitive. (e.g. New)
  --updated-time: any # The tag's updated time.
]: any -> record<_links: list<any>, createdTime: record, id: record, name: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let req_body = {"createdTime": $created_time, "name": $name, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a tag
#
# DELETE /tags/{tag}
# operationId: DeleteTag
export def "tags delete" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({tag: (encode-path-segment $tag)} | format pattern "/tags/{tag}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a tag
#
# GET /tags/{tag}
# operationId: GetTag
export def "tags get" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: list<any>, createdTime: record, id: record, name: string, updatedTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({tag: (encode-path-segment $tag)} | format pattern "/tags/{tag}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a tag
#
# PATCH /tags/{tag}
# operationId: PatchTag
export def "tags update" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: any # The tag's created time.
  name: string # The tag is unique name, which is case-insensitive. (e.g. New)
  --updated-time: any # The tag's updated time.
]: any -> record<_links: list<any>, createdTime: record, id: record, name: string, updatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({tag: (encode-path-segment $tag)} | format pattern "/tags/{tag}"))
  let req_body = {"createdTime": $created_time, "name": $name, "updatedTime": $updated_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Untag a list of customers
#
# DELETE /tags/{tag}/customers
# operationId: DeleteTagCustomerCollection
export def "tags-customers delete-collection" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_ids: list<string> # The list of customer IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({tag: (encode-path-segment $tag)} | format pattern "/tags/{tag}/customers"))
  let req_body = {"customerIds": $customer_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Tag a list of customers
#
# POST /tags/{tag}/customers
# operationId: PostTagCustomerCollection
export def "tags-customers create-collection" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_ids: list<string> # The list of customer IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({tag: (encode-path-segment $tag)} | format pattern "/tags/{tag}/customers"))
  let req_body = {"customerIds": $customer_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Untag a customer
#
# DELETE /tags/{tag}/customers/{customerId}
# operationId: DeleteTagCustomer
export def "tags-customers delete" [
  tag: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({tag: (encode-path-segment $tag), customer_id: (encode-path-segment $customer_id)} | format pattern "/tags/{tag}/customers/{customer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Tag a customer
#
# POST /tags/{tag}/customers/{customerId}
# operationId: PostTagCustomer
export def "tags-customers create" [
  tag: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({tag: (encode-path-segment $tag), customer_id: (encode-path-segment $customer_id)} | format pattern "/tags/{tag}/customers/{customer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of tokens
#
# GET /tokens
# operationId: GetTokenCollection
export def "tokens get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Create a payment token
#
# POST /tokens
# operationId: PostToken
# --paymentInstrument shape: {cvv?: string, expMonth?: int, expYear?: int, pan?: string}
export def "tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billing-address: any # The billing address object.
  --method: string@method-completer # The token payment method.
  --payment-instrument: record # The payment card instrument details. — shape: {cvv?: string, expMonth?: int, expYear?: int, pan?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens")
  let req_body = {"billingAddress": $billing_address, "method": $method, "paymentInstrument": $payment_instrument} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a token
#
# GET /tokens/{token}
# operationId: GetToken
export def "tokens get" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/tokens/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of transactions
#
# GET /transactions
# operationId: GetTransactionCollection
export def "transactions get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --qp-sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> table<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record, outcome: string, presentedOffers: record, selectedOffer: record, version: record>, dcc: record<base: record, outcome: string, quote: record, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record, cvvResponse: record, response: record>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "q": $q, "sort": $qp_sort, "expand": $expand} | compact), body: null}
}

# Create a transaction
#
# POST /transactions
# operationId: PostTransaction
# --riskMetadata shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
@deprecated --flag payment-instrument
export def "transactions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  amount: float # The transaction amount. (format: double, e.g. 97.97)
  --billing-address: any # Billing address. If not supplied, we use the billing address associated with the payment instrument, and then customer. (nullable)
  currency: any
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: any # The customer identifier string.
  --description: string # The payment description. (nullable)
  --gateway-account-id: any # Rebilly will select the appropriate payment gateway account for the transaction based on the properties of the transaction and the `gateway-account-requested` event rules configurations. If you wish to prevent Rebilly from making the gateway account selection, you may supply a gateway account id here, and it will be used instead. Only use this field if you intend to override the settings. (nullable)
  --invoice-ids: list<string> # The array of invoice identifiers. (nullable)
  --is-merchant-initiated: oneof<nothing, bool> # True if the transaction was initiated by the merchant. (default: false)
  --is-processed-outside: oneof<nothing, bool> # True if transaction was processed outside Rebilly. (default: false)
  --notification-url: string # The URL where a server-to-server notification request type `POST` with a transaction payload will be sent when the transaction's result is finalized. Do not trust the notification; follow with a `GET` request to confirm the result of the transaction. Please respond with a `2xx` HTTP status code, or we will reattempt the request again. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --payment-instruction: any # Payment instruction. If not supplied, customer's default payment instrument will be used.
  --payment-instrument: any # DEPRECATED
  --processed-time: string # The time the transaction was processed. Can be specified only if transaction was processed outside Rebilly. (format: date-time)
  --redirect-url: string # The URL to redirect the end-user when an offsite transaction is completed. Defaults to the website's configured URL. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --request-id: string # The request id is **recommended**. It prevents duplicate transaction requests within a short period of time. If a duplicate request is sent with the same `requestId` it will be ignored to prevent double-billing anyone. It must be unique within a 24-hour period. We recommend generating a UUID v4 as its value. (nullable, e.g. 44433322-2c4y-483z-a0a9-158621f77a21)
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  website_id: any # The website identifier string.
  type: string@type-completer-7 # The type of transaction requested. You should always include the type within your API request. This supports a limited subset of Transaction types. To refund or void, use the refund endpoint. To `capture` use the `sale` type. If any existing `authorize` transactions are eligible, then they will be captured and the `sale` will be converted to a `capture` type.
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let req_body = {"amount": $amount, "billingAddress": $billing_address, "currency": $currency, "customFields": $custom_fields, "customerId": $customer_id, "description": $description, "gatewayAccountId": $gateway_account_id, "invoiceIds": $invoice_ids, "isMerchantInitiated": $is_merchant_initiated, "isProcessedOutside": $is_processed_outside, "notificationUrl": $notification_url, "paymentInstruction": $payment_instruction, "paymentInstrument": $payment_instrument, "processedTime": $processed_time, "redirectUrl": $redirect_url, "requestId": $request_id, "riskMetadata": $risk_metadata, "websiteId": $website_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"expand": $expand} | compact), body: $req_body}
}

# Retrieve a Transaction
#
# GET /transactions/{id}
# operationId: GetTransaction
export def "transactions get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
]: nothing -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand} | compact), body: null}
}

# Update a transaction
#
# PATCH /transactions/{id}
# operationId: PatchTransaction
export def "transactions update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}"))
  let req_body = {"customFields": $custom_fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Query a Transaction
#
# POST /transactions/{id}/query
# operationId: PostTransactionQuery
export def "transactions-query create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<amount: float, currency: record, result: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}/query"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Refund a Transaction
#
# POST /transactions/{id}/refund
# operationId: PostTransactionRefund
export def "transactions-refund create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # Refund amount. (format: double)
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}/refund"))
  let req_body = {"amount": $amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of transaction timeline messages
#
# GET /transactions/{id}/timeline
# operationId: GetTransactionTimelineCollection
export def "transactions-timeline get-collection" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
]: nothing -> table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}/timeline") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter} | compact), body: null}
}

# Create a transaction Timeline comment
#
# POST /transactions/{id}/timeline
# operationId: PostTransactionTimeline
# --_links item shape: {rel: "self", href: string}
# --extraData shape: {actions?: list, author?: record, links?: list, mentions?: record, tables?: list}
export def "transactions-timeline create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}/timeline"))
  let req_body = {"message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Transaction Timeline message
#
# DELETE /transactions/{id}/timeline/{messageId}
# operationId: DeleteTransactionTimeline
export def "transactions-timeline delete" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/transactions/{id}/timeline/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a transaction Timeline message
#
# GET /transactions/{id}/timeline/{messageId}
# operationId: GetTransactionTimeline
export def "transactions-timeline get" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> record<_links: table<rel: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: record, message: string, occurredTime: record, triggeredBy: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/transactions/{id}/timeline/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Transaction status
#
# POST /transactions/{id}/update
# operationId: PostTransactionUpdate
export def "transactions-update create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --amount: float # The transaction amount. (format: double)
  --currency: any # The transaction currency.
  result: string@result-completer # Transaction result.
]: any -> record<3ds: record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: record, currency: record, customFields: record, customerId: record, description: string, gatewayName: record, has3ds: bool, hasAmountAdjustment: bool, id: record, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: record, paymentInstrument: record, planIds: list<string>, processedTime: record, purchaseAmount: float, purchaseCurrency: record, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: record, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: record, websiteId: record, _embedded: list<any>, _links: list<any>, acquirerName: record, arn: string, bin: string, bumpOffer: record<language: record, order: record<amount: float, currency: string>, outcome: string, presentedOffers: record, selectedOffer: record<bumpAmount: record, bumpAmountInUsd: record, customFields: record, offerId: string, offerType: string>, version: record>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: record>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: record, gatewayTransactionId: record, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: record, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: record, retriedTransactionId: record, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "reb-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}/update"))
  let req_body = {"amount": $amount, "currency": $currency, "result": $result} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Organization-Id": $organization_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
