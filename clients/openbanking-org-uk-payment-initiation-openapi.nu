# Auto-generated client for Payment Initiation API v3.1.7
# Source: https://api.apis.guru/v2/specs/openbanking.org.uk/payment-initiation-openapi/3.1.7/openapi.json
# Auth: --token flag or $env.PAYMENT_INITIATION_API_TOKEN

const BASE_URL = "https://openbanking.org.uk"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYMENT_INITIATION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://openbanking.org.uk" "http://localhost/open-banking/v3.1/pisp"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domestic-payment-consents create" } } | get name | first)
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

# Create Domestic Payment Consents
#
# POST /domestic-payment-consents
# operationId: CreateDomesticPaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-payment-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {Authorisation?: record, Initiation: record, ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-payment-consents")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Domestic Payment Consents
#
# GET /domestic-payment-consents/{ConsentId}
# operationId: GetDomesticPaymentConsentsConsentId
export def "domestic-payment-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/domestic-payment-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Domestic Payment Consents Funds Confirmation
#
# GET /domestic-payment-consents/{ConsentId}/funds-confirmation
# operationId: GetDomesticPaymentConsentsConsentIdFundsConfirmation
export def "domestic-payment-consents-funds-confirmation get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/domestic-payment-consents/{consent_id}/funds-confirmation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Domestic Payments
#
# POST /domestic-payments
# operationId: CreateDomesticPayments
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {ConsentId: string, Initiation: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-payments")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Domestic Payments
#
# GET /domestic-payments/{DomesticPaymentId}
# operationId: GetDomesticPaymentsDomesticPaymentId
export def "domestic-payments get" [
  domestic_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domestic_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'DomesticPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({domestic_payment_id: (encode-path-segment $domestic_payment_id)} | format pattern "/domestic-payments/{domestic_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Payment Details
#
# GET /domestic-payments/{DomesticPaymentId}/payment-details
# operationId: GetDomesticPaymentsDomesticPaymentIdPaymentDetails
export def "domestic-payments-payment-details get" [
  domestic_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domestic_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'DomesticPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({domestic_payment_id: (encode-path-segment $domestic_payment_id)} | format pattern "/domestic-payments/{domestic_payment_id}/payment-details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Domestic Scheduled Payment Consents
#
# POST /domestic-scheduled-payment-consents
# operationId: CreateDomesticScheduledPaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-scheduled-payment-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-scheduled-payment-consents")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Domestic Scheduled Payment Consents
#
# GET /domestic-scheduled-payment-consents/{ConsentId}
# operationId: GetDomesticScheduledPaymentConsentsConsentId
export def "domestic-scheduled-payment-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/domestic-scheduled-payment-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Domestic Scheduled Payments
#
# POST /domestic-scheduled-payments
# operationId: CreateDomesticScheduledPayments
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-scheduled-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {ConsentId: string, Initiation: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-scheduled-payments")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Domestic Scheduled Payments
#
# GET /domestic-scheduled-payments/{DomesticScheduledPaymentId}
# operationId: GetDomesticScheduledPaymentsDomesticScheduledPaymentId
export def "domestic-scheduled-payments get" [
  domestic_scheduled_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domestic_scheduled_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'DomesticScheduledPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({domestic_scheduled_payment_id: (encode-path-segment $domestic_scheduled_payment_id)} | format pattern "/domestic-scheduled-payments/{domestic_scheduled_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Payment Details
#
# GET /domestic-scheduled-payments/{DomesticScheduledPaymentId}/payment-details
# operationId: GetDomesticScheduledPaymentsDomesticScheduledPaymentIdPaymentDetails
export def "domestic-scheduled-payments-payment-details get" [
  domestic_scheduled_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domestic_scheduled_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'DomesticScheduledPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({domestic_scheduled_payment_id: (encode-path-segment $domestic_scheduled_payment_id)} | format pattern "/domestic-scheduled-payments/{domestic_scheduled_payment_id}/payment-details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Domestic Standing Order Consents
#
# POST /domestic-standing-order-consents
# operationId: CreateDomesticStandingOrderConsents
# --Data shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-standing-order-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-standing-order-consents")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Domestic Standing Order Consents
#
# GET /domestic-standing-order-consents/{ConsentId}
# operationId: GetDomesticStandingOrderConsentsConsentId
export def "domestic-standing-order-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/domestic-standing-order-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Domestic Standing Orders
#
# POST /domestic-standing-orders
# operationId: CreateDomesticStandingOrders
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-standing-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {ConsentId: string, Initiation: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-standing-orders")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Domestic Standing Orders
#
# GET /domestic-standing-orders/{DomesticStandingOrderId}
# operationId: GetDomesticStandingOrdersDomesticStandingOrderId
export def "domestic-standing-orders get" [
  domestic_standing_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domestic_standing_order_id | is-empty) { error make --unspanned { msg: "path parameter 'DomesticStandingOrderId' must be non-empty" } }
  let full_url = (build-url $base ({domestic_standing_order_id: (encode-path-segment $domestic_standing_order_id)} | format pattern "/domestic-standing-orders/{domestic_standing_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Payment Details
#
# GET /domestic-standing-orders/{DomesticStandingOrderId}/payment-details
# operationId: GetDomesticStandingOrdersDomesticStandingOrderIdPaymentDetails
export def "domestic-standing-orders-payment-details get" [
  domestic_standing_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domestic_standing_order_id | is-empty) { error make --unspanned { msg: "path parameter 'DomesticStandingOrderId' must be non-empty" } }
  let full_url = (build-url $base ({domestic_standing_order_id: (encode-path-segment $domestic_standing_order_id)} | format pattern "/domestic-standing-orders/{domestic_standing_order_id}/payment-details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create File Payment Consents
#
# POST /file-payment-consents
# operationId: CreateFilePaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, SCASupportData?: record}
export def "file-payment-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {Authorisation?: record, Initiation: record, SCASupportData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/file-payment-consents")
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get File Payment Consents
#
# GET /file-payment-consents/{ConsentId}
# operationId: GetFilePaymentConsentsConsentId
export def "file-payment-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/file-payment-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get File Payment Consents
#
# GET /file-payment-consents/{ConsentId}/file
# operationId: GetFilePaymentConsentsConsentIdFile
export def "file-payment-consents-file get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/file-payment-consents/{consent_id}/file"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create File Payment Consents
#
# POST /file-payment-consents/{ConsentId}/file
# operationId: CreateFilePaymentConsentsConsentIdFile
export def "file-payment-consents-file create" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/file-payment-consents/{consent_id}/file"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create File Payments
#
# POST /file-payments
# operationId: CreateFilePayments
# --Data shape: {ConsentId: string, Initiation: record}
export def "file-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {ConsentId: string, Initiation: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/file-payments")
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get File Payments
#
# GET /file-payments/{FilePaymentId}
# operationId: GetFilePaymentsFilePaymentId
export def "file-payments get" [
  file_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'FilePaymentId' must be non-empty" } }
  let full_url = (build-url $base ({file_payment_id: (encode-path-segment $file_payment_id)} | format pattern "/file-payments/{file_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Payment Details
#
# GET /file-payments/{FilePaymentId}/payment-details
# operationId: GetFilePaymentsFilePaymentIdPaymentDetails
export def "file-payments-payment-details get" [
  file_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'FilePaymentId' must be non-empty" } }
  let full_url = (build-url $base ({file_payment_id: (encode-path-segment $file_payment_id)} | format pattern "/file-payments/{file_payment_id}/payment-details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get File Payments
#
# GET /file-payments/{FilePaymentId}/report-file
# operationId: GetFilePaymentsFilePaymentIdReportFile
export def "file-payments-report-file get" [
  file_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'FilePaymentId' must be non-empty" } }
  let full_url = (build-url $base ({file_payment_id: (encode-path-segment $file_payment_id)} | format pattern "/file-payments/{file_payment_id}/report-file"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create International Payment Consents
#
# POST /international-payment-consents
# operationId: CreateInternationalPaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-payment-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {Authorisation?: record, Initiation: record, ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-payment-consents")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get International Payment Consents
#
# GET /international-payment-consents/{ConsentId}
# operationId: GetInternationalPaymentConsentsConsentId
export def "international-payment-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/international-payment-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get International Payment Consents Funds Confirmation
#
# GET /international-payment-consents/{ConsentId}/funds-confirmation
# operationId: GetInternationalPaymentConsentsConsentIdFundsConfirmation
export def "international-payment-consents-funds-confirmation get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/international-payment-consents/{consent_id}/funds-confirmation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create International Payments
#
# POST /international-payments
# operationId: CreateInternationalPayments
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {ConsentId: string, Initiation: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-payments")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get International Payments
#
# GET /international-payments/{InternationalPaymentId}
# operationId: GetInternationalPaymentsInternationalPaymentId
export def "international-payments get" [
  international_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($international_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'InternationalPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({international_payment_id: (encode-path-segment $international_payment_id)} | format pattern "/international-payments/{international_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Payment Details
#
# GET /international-payments/{InternationalPaymentId}/payment-details
# operationId: GetInternationalPaymentsInternationalPaymentIdPaymentDetails
export def "international-payments-payment-details get" [
  international_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($international_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'InternationalPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({international_payment_id: (encode-path-segment $international_payment_id)} | format pattern "/international-payments/{international_payment_id}/payment-details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create International Scheduled Payment Consents
#
# POST /international-scheduled-payment-consents
# operationId: CreateInternationalScheduledPaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-scheduled-payment-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-scheduled-payment-consents")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get International Scheduled Payment Consents
#
# GET /international-scheduled-payment-consents/{ConsentId}
# operationId: GetInternationalScheduledPaymentConsentsConsentId
export def "international-scheduled-payment-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/international-scheduled-payment-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get International Scheduled Payment Consents Funds Confirmation
#
# GET /international-scheduled-payment-consents/{ConsentId}/funds-confirmation
# operationId: GetInternationalScheduledPaymentConsentsConsentIdFundsConfirmation
export def "international-scheduled-payment-consents-funds-confirmation get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/international-scheduled-payment-consents/{consent_id}/funds-confirmation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create International Scheduled Payments
#
# POST /international-scheduled-payments
# operationId: CreateInternationalScheduledPayments
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-scheduled-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {ConsentId: string, Initiation: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-scheduled-payments")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get International Scheduled Payments
#
# GET /international-scheduled-payments/{InternationalScheduledPaymentId}
# operationId: GetInternationalScheduledPaymentsInternationalScheduledPaymentId
export def "international-scheduled-payments get" [
  international_scheduled_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($international_scheduled_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'InternationalScheduledPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({international_scheduled_payment_id: (encode-path-segment $international_scheduled_payment_id)} | format pattern "/international-scheduled-payments/{international_scheduled_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Payment Details
#
# GET /international-scheduled-payments/{InternationalScheduledPaymentId}/payment-details
# operationId: GetInternationalScheduledPaymentsInternationalScheduledPaymentIdPaymentDetails
export def "international-scheduled-payments-payment-details get" [
  international_scheduled_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($international_scheduled_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'InternationalScheduledPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({international_scheduled_payment_id: (encode-path-segment $international_scheduled_payment_id)} | format pattern "/international-scheduled-payments/{international_scheduled_payment_id}/payment-details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create International Standing Order Consents
#
# POST /international-standing-order-consents
# operationId: CreateInternationalStandingOrderConsents
# --Data shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-standing-order-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-standing-order-consents")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get International Standing Order Consents
#
# GET /international-standing-order-consents/{ConsentId}
# operationId: GetInternationalStandingOrderConsentsConsentId
export def "international-standing-order-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/international-standing-order-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create International Standing Orders
#
# POST /international-standing-orders
# operationId: CreateInternationalStandingOrders
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-standing-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key. The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {ConsentId: string, Initiation: record}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-standing-orders")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get International Standing Orders
#
# GET /international-standing-orders/{InternationalStandingOrderPaymentId}
# operationId: GetInternationalStandingOrdersInternationalStandingOrderPaymentId
export def "international-standing-orders get-payment" [
  international_standing_order_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($international_standing_order_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'InternationalStandingOrderPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({international_standing_order_payment_id: (encode-path-segment $international_standing_order_payment_id)} | format pattern "/international-standing-orders/{international_standing_order_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Payment Details
#
# GET /international-standing-orders/{InternationalStandingOrderPaymentId}/payment-details
# operationId: GetInternationalStandingOrdersInternationalStandingOrderPaymentIdPaymentDetails
export def "international-standing-orders-payment-details get" [
  international_standing_order_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($international_standing_order_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'InternationalStandingOrderPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({international_standing_order_payment_id: (encode-path-segment $international_standing_order_payment_id)} | format pattern "/international-standing-orders/{international_standing_order_payment_id}/payment-details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
