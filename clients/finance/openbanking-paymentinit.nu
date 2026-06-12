# Auto-generated client for Payment Initiation API v3.1.7
# Source: https://api.apis.guru/v2/specs/openbanking.org.uk/payment-initiation-openapi/3.1.7/openapi.json
# Auth: --token flag or $env.PAYMENT_INITIATION_API_TOKEN

const BASE_URL = "https://openbanking.org.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYMENT_INITIATION_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://openbanking.org.uk" "http://localhost/open-banking/v3.1/pisp"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domestic-payment-consents CreateDomesticPaymentConsents" } } | get name | first)
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
export def "domestic-payment-consents CreateDomesticPaymentConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {Authorisation?: record, Initiation: record, ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-payment-consents")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Domestic Payment Consents
#
# GET /domestic-payment-consents/{ConsentId}
# operationId: GetDomesticPaymentConsentsConsentId
export def "domestic-payment-consents GetDomesticPaymentConsentsConsentId" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-payment-consents/($ConsentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Domestic Payment Consents Funds Confirmation
#
# GET /domestic-payment-consents/{ConsentId}/funds-confirmation
# operationId: GetDomesticPaymentConsentsConsentIdFundsConfirmation
export def "domestic-payment-consents-funds-confirmation GetDomesticPaymentConsentsConsentIdFundsConfirmation" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-payment-consents/($ConsentId)/funds-confirmation")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Domestic Payments
#
# POST /domestic-payments
# operationId: CreateDomesticPayments
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-payments CreateDomesticPayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {ConsentId: string, Initiation: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-payments")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Domestic Payments
#
# GET /domestic-payments/{DomesticPaymentId}
# operationId: GetDomesticPaymentsDomesticPaymentId
export def "domestic-payments GetDomesticPaymentsDomesticPaymentId" [
  DomesticPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-payments/($DomesticPaymentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Details
#
# GET /domestic-payments/{DomesticPaymentId}/payment-details
# operationId: GetDomesticPaymentsDomesticPaymentIdPaymentDetails
export def "domestic-payments-payment-details GetDomesticPaymentsDomesticPaymentIdPaymentDetails" [
  DomesticPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-payments/($DomesticPaymentId)/payment-details")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Domestic Scheduled Payment Consents
#
# POST /domestic-scheduled-payment-consents
# operationId: CreateDomesticScheduledPaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-scheduled-payment-consents CreateDomesticScheduledPaymentConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-scheduled-payment-consents")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Domestic Scheduled Payment Consents
#
# GET /domestic-scheduled-payment-consents/{ConsentId}
# operationId: GetDomesticScheduledPaymentConsentsConsentId
export def "domestic-scheduled-payment-consents GetDomesticScheduledPaymentConsentsConsentId" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-scheduled-payment-consents/($ConsentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Domestic Scheduled Payments
#
# POST /domestic-scheduled-payments
# operationId: CreateDomesticScheduledPayments
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-scheduled-payments CreateDomesticScheduledPayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {ConsentId: string, Initiation: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-scheduled-payments")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Domestic Scheduled Payments
#
# GET /domestic-scheduled-payments/{DomesticScheduledPaymentId}
# operationId: GetDomesticScheduledPaymentsDomesticScheduledPaymentId
export def "domestic-scheduled-payments GetDomesticScheduledPaymentsDomesticScheduledPaymentId" [
  DomesticScheduledPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-scheduled-payments/($DomesticScheduledPaymentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Details
#
# GET /domestic-scheduled-payments/{DomesticScheduledPaymentId}/payment-details
# operationId: GetDomesticScheduledPaymentsDomesticScheduledPaymentIdPaymentDetails
export def "domestic-scheduled-payments-payment-details GetDomesticScheduledPaymentsDomesticScheduledPaymentIdPaymentDetails" [
  DomesticScheduledPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-scheduled-payments/($DomesticScheduledPaymentId)/payment-details")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Domestic Standing Order Consents
#
# POST /domestic-standing-order-consents
# operationId: CreateDomesticStandingOrderConsents
# --Data shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-standing-order-consents CreateDomesticStandingOrderConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-standing-order-consents")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Domestic Standing Order Consents
#
# GET /domestic-standing-order-consents/{ConsentId}
# operationId: GetDomesticStandingOrderConsentsConsentId
export def "domestic-standing-order-consents GetDomesticStandingOrderConsentsConsentId" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-standing-order-consents/($ConsentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Domestic Standing Orders
#
# POST /domestic-standing-orders
# operationId: CreateDomesticStandingOrders
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "domestic-standing-orders CreateDomesticStandingOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {ConsentId: string, Initiation: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domestic-standing-orders")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Domestic Standing Orders
#
# GET /domestic-standing-orders/{DomesticStandingOrderId}
# operationId: GetDomesticStandingOrdersDomesticStandingOrderId
export def "domestic-standing-orders GetDomesticStandingOrdersDomesticStandingOrderId" [
  DomesticStandingOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-standing-orders/($DomesticStandingOrderId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Details
#
# GET /domestic-standing-orders/{DomesticStandingOrderId}/payment-details
# operationId: GetDomesticStandingOrdersDomesticStandingOrderIdPaymentDetails
export def "domestic-standing-orders-payment-details GetDomesticStandingOrdersDomesticStandingOrderIdPaymentDetails" [
  DomesticStandingOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domestic-standing-orders/($DomesticStandingOrderId)/payment-details")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create File Payment Consents
#
# POST /file-payment-consents
# operationId: CreateFilePaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, SCASupportData?: record}
export def "file-payment-consents CreateFilePaymentConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {Authorisation?: record, Initiation: record, SCASupportData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/file-payment-consents")
  let body = {Data: $Data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get File Payment Consents
#
# GET /file-payment-consents/{ConsentId}
# operationId: GetFilePaymentConsentsConsentId
export def "file-payment-consents GetFilePaymentConsentsConsentId" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-payment-consents/($ConsentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get File Payment Consents
#
# GET /file-payment-consents/{ConsentId}/file
# operationId: GetFilePaymentConsentsConsentIdFile
export def "file-payment-consents-file GetFilePaymentConsentsConsentIdFile" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-payment-consents/($ConsentId)/file")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create File Payment Consents
#
# POST /file-payment-consents/{ConsentId}/file
# operationId: CreateFilePaymentConsentsConsentIdFile
export def "file-payment-consents-file CreateFilePaymentConsentsConsentIdFile" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-payment-consents/($ConsentId)/file")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create File Payments
#
# POST /file-payments
# operationId: CreateFilePayments
# --Data shape: {ConsentId: string, Initiation: record}
export def "file-payments CreateFilePayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {ConsentId: string, Initiation: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/file-payments")
  let body = {Data: $Data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get File Payments
#
# GET /file-payments/{FilePaymentId}
# operationId: GetFilePaymentsFilePaymentId
export def "file-payments GetFilePaymentsFilePaymentId" [
  FilePaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-payments/($FilePaymentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Details
#
# GET /file-payments/{FilePaymentId}/payment-details
# operationId: GetFilePaymentsFilePaymentIdPaymentDetails
export def "file-payments-payment-details GetFilePaymentsFilePaymentIdPaymentDetails" [
  FilePaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-payments/($FilePaymentId)/payment-details")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get File Payments
#
# GET /file-payments/{FilePaymentId}/report-file
# operationId: GetFilePaymentsFilePaymentIdReportFile
export def "file-payments-report-file GetFilePaymentsFilePaymentIdReportFile" [
  FilePaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file-payments/($FilePaymentId)/report-file")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create International Payment Consents
#
# POST /international-payment-consents
# operationId: CreateInternationalPaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-payment-consents CreateInternationalPaymentConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {Authorisation?: record, Initiation: record, ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-payment-consents")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get International Payment Consents
#
# GET /international-payment-consents/{ConsentId}
# operationId: GetInternationalPaymentConsentsConsentId
export def "international-payment-consents GetInternationalPaymentConsentsConsentId" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-payment-consents/($ConsentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get International Payment Consents Funds Confirmation
#
# GET /international-payment-consents/{ConsentId}/funds-confirmation
# operationId: GetInternationalPaymentConsentsConsentIdFundsConfirmation
export def "international-payment-consents-funds-confirmation GetInternationalPaymentConsentsConsentIdFundsConfirmation" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-payment-consents/($ConsentId)/funds-confirmation")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create International Payments
#
# POST /international-payments
# operationId: CreateInternationalPayments
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-payments CreateInternationalPayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {ConsentId: string, Initiation: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-payments")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get International Payments
#
# GET /international-payments/{InternationalPaymentId}
# operationId: GetInternationalPaymentsInternationalPaymentId
export def "international-payments GetInternationalPaymentsInternationalPaymentId" [
  InternationalPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-payments/($InternationalPaymentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Details
#
# GET /international-payments/{InternationalPaymentId}/payment-details
# operationId: GetInternationalPaymentsInternationalPaymentIdPaymentDetails
export def "international-payments-payment-details GetInternationalPaymentsInternationalPaymentIdPaymentDetails" [
  InternationalPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-payments/($InternationalPaymentId)/payment-details")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create International Scheduled Payment Consents
#
# POST /international-scheduled-payment-consents
# operationId: CreateInternationalScheduledPaymentConsents
# --Data shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-scheduled-payment-consents CreateInternationalScheduledPaymentConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-scheduled-payment-consents")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get International Scheduled Payment Consents
#
# GET /international-scheduled-payment-consents/{ConsentId}
# operationId: GetInternationalScheduledPaymentConsentsConsentId
export def "international-scheduled-payment-consents GetInternationalScheduledPaymentConsentsConsentId" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-scheduled-payment-consents/($ConsentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get International Scheduled Payment Consents Funds Confirmation
#
# GET /international-scheduled-payment-consents/{ConsentId}/funds-confirmation
# operationId: GetInternationalScheduledPaymentConsentsConsentIdFundsConfirmation
export def "international-scheduled-payment-consents-funds-confirmation GetInternationalScheduledPaymentConsentsConsentIdFundsConfirmation" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-scheduled-payment-consents/($ConsentId)/funds-confirmation")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create International Scheduled Payments
#
# POST /international-scheduled-payments
# operationId: CreateInternationalScheduledPayments
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-scheduled-payments CreateInternationalScheduledPayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {ConsentId: string, Initiation: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-scheduled-payments")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get International Scheduled Payments
#
# GET /international-scheduled-payments/{InternationalScheduledPaymentId}
# operationId: GetInternationalScheduledPaymentsInternationalScheduledPaymentId
export def "international-scheduled-payments GetInternationalScheduledPaymentsInternationalScheduledPaymentId" [
  InternationalScheduledPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-scheduled-payments/($InternationalScheduledPaymentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Details
#
# GET /international-scheduled-payments/{InternationalScheduledPaymentId}/payment-details
# operationId: GetInternationalScheduledPaymentsInternationalScheduledPaymentIdPaymentDetails
export def "international-scheduled-payments-payment-details GetInternationalScheduledPaymentsInternationalScheduledPaymentIdPaymentDetails" [
  InternationalScheduledPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-scheduled-payments/($InternationalScheduledPaymentId)/payment-details")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create International Standing Order Consents
#
# POST /international-standing-order-consents
# operationId: CreateInternationalStandingOrderConsents
# --Data shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-standing-order-consents CreateInternationalStandingOrderConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {Authorisation?: record, Initiation: record, Permission: "Create", ReadRefundAccount?: "No"|"Yes", SCASupportData?: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-standing-order-consents")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get International Standing Order Consents
#
# GET /international-standing-order-consents/{ConsentId}
# operationId: GetInternationalStandingOrderConsentsConsentId
export def "international-standing-order-consents GetInternationalStandingOrderConsentsConsentId" [
  ConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-standing-order-consents/($ConsentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create International Standing Orders
#
# POST /international-standing-orders
# operationId: CreateInternationalStandingOrders
# --Data shape: {ConsentId: string, Initiation: record}
# --Risk shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
export def "international-standing-orders CreateInternationalStandingOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-idempotency-key: string # Every request will be processed only once per x-idempotency-key.  The Idempotency Key will be valid for 24 hours.
  --x-jws-signature: string # A detached JWS signature of the body of the payload.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  Data: record # shape: {ConsentId: string, Initiation: record}
  Risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Payments. — shape: {DeliveryAddress?: record, MerchantCategoryCode?: string, MerchantCustomerIdentification?: string, PaymentContextCode?: "BillPayment"|"EcommerceGoods"|"EcommerceServices"|"Other"|"PartyToParty"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/international-standing-orders")
  let body = {Data: $Data, Risk: $Risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-idempotency-key": $x_idempotency_key, "x-jws-signature": $x_jws_signature, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get International Standing Orders
#
# GET /international-standing-orders/{InternationalStandingOrderPaymentId}
# operationId: GetInternationalStandingOrdersInternationalStandingOrderPaymentId
export def "international-standing-orders GetInternationalStandingOrdersInternationalStandingOrderPaymentId" [
  InternationalStandingOrderPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-standing-orders/($InternationalStandingOrderPaymentId)")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment Details
#
# GET /international-standing-orders/{InternationalStandingOrderPaymentId}/payment-details
# operationId: GetInternationalStandingOrdersInternationalStandingOrderPaymentIdPaymentDetails
export def "international-standing-orders-payment-details GetInternationalStandingOrdersInternationalStandingOrderPaymentIdPaymentDetails" [
  InternationalStandingOrderPaymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP.  All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below:  Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --Authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/international-standing-orders/($InternationalStandingOrderPaymentId)/payment-details")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $Authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
