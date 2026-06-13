# Auto-generated client for Payments Gateway API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Payments-Gateway-API/1.0/openapi.json
# Auth: --token flag or $env.PAYMENTS_GATEWAY_API_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYMENTS_GATEWAY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-vtex-api-appkey" => { {headers: {X-VTEX-API-AppKey: $token_val}, query: ""} }
    "x-vtex-api-apptoken" => { {headers: {X-VTEX-API-AppToken: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.vtexpayments.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "pub-transactions-payments 2SendPaymentsPublic" } } | get name | first)
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

# 2.1 Send Payments Information Public
#
# POST /api/pub/transactions/{transactionId}/payments
# operationId: 2.SendPaymentsPublic
export def "pub-transactions-payments 2SendPaymentsPublic" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderId: string # e.g. {{orderId}}
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/pub/transactions/($transactionId)/payments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Affiliations
#
# GET /api/pvt/affiliations
# operationId: Affiliations
export def "pvt-affiliations Affiliations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/affiliations")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert Affiliation
#
# POST /api/pvt/affiliations
# operationId: InsertAffiliation
# --configuration item shape: {name: string, value: string}
export def "pvt-affiliations InsertAffiliation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  configuration: list # item shape: {name: string, value: string}
  implementation: string
  --isConfigured: oneof<nothing, bool>
  --isdelivered: oneof<nothing, bool>
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/affiliations")
  let body = {configuration: $configuration, implementation: $implementation, isConfigured: $isConfigured, isdelivered: $isdelivered, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Affiliation By Id
#
# GET /api/pvt/affiliations/{affiliationId}
# operationId: AffiliationById
export def "pvt-affiliations AffiliationById" [
  affiliationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/affiliations/($affiliationId)")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Affiliation
#
# PUT /api/pvt/affiliations/{affiliationId}
# operationId: UpdateAffiliation
# --configuration item shape: {name: string, value: string}
export def "pvt-affiliations UpdateAffiliation" [
  affiliationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  configuration: list # item shape: {name: string, value: string}
  id: string
  implementation: string
  --isConfigured: oneof<nothing, bool>
  --isdelivered: oneof<nothing, bool>
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/affiliations/($affiliationId)")
  let body = {configuration: $configuration, id: $id, implementation: $implementation, isConfigured: $isConfigured, isdelivered: $isdelivered, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Installments options
#
# GET /api/pvt/installments
# operationId: Installmentsoptions
export def "pvt-installments Installmentsoptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requestvalue: int # format: int32, e.g. 10
  --requestsalesChannel: int # format: int32, e.g. 1
  --requestpaymentDetails0id: int # format: int32, e.g. 2
  --requestpaymentDetails0value: int # format: int32, e.g. 10
  --requestpaymentDetails0bin: int # format: int32, e.g. 411111
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request.value" $requestvalue "scalar") (serialize-qp "request.salesChannel" $requestsalesChannel "scalar") (serialize-qp "request.paymentDetails[0].id" $requestpaymentDetails0id "scalar") (serialize-qp "request.paymentDetails[0].value" $requestpaymentDetails0value "scalar") (serialize-qp "request.paymentDetails[0].bin" $requestpaymentDetails0bin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/pvt/installments" $qp)
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Available Payment Methods
#
# GET /api/pvt/merchants/payment-systems
# operationId: AvailablePaymentMethods
export def "pvt-merchants-payment-systems AvailablePaymentMethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/merchants/payment-systems")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rules
#
# GET /api/pvt/rules
# operationId: Rules
export def "pvt-rules Rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/rules")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert Rule
#
# POST /api/pvt/rules
# operationId: InsertRule
# --antifraud shape: {affiliationId: string, implementation: string}
# --connector shape: {affiliationId: string, implementation: string}
# --issuer shape: {name: string}
# --paymentSystem shape: {id: int, implementation: string, name: string}
# --salesChannels item shape: {id: string}
export def "pvt-rules InsertRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  antifraud: record # e.g. {affiliationId: , implementation: } — shape: {affiliationId: string, implementation: string}
  --beginDate: string # nullable
  --condition: string # nullable
  connector: record # e.g. {affiliationId: e046d326-5421-45ab-95ae-f13d37f260b5, implementation: Vtex.PaymentGateway.Connectors.PromissoryConnector} — shape: {affiliationId: string, implementation: string}
  --country: string # nullable
  --dateIntervals: string # nullable
  --enabled: oneof<nothing, bool>
  --endDate: string # nullable
  --installmentOptions: string # nullable
  --installmentsService: string # nullable
  --isDefault: oneof<nothing, bool>
  --isSelfAuthorized: string # nullable
  issuer: record # e.g. {name: } — shape: {name: string}
  --multiMerchantList: string # nullable
  name: string
  paymentSystem: record # e.g. {id: 47, implementation: , name: Cash} — shape: {id: int, implementation: string, name: string}
  --requiresAuthentication: string # nullable
  salesChannels: list # item shape: {id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/rules")
  let body = {antifraud: $antifraud, beginDate: $beginDate, condition: $condition, connector: $connector, country: $country, dateIntervals: $dateIntervals, enabled: $enabled, endDate: $endDate, installmentOptions: $installmentOptions, installmentsService: $installmentsService, isDefault: $isDefault, isSelfAuthorized: $isSelfAuthorized, issuer: $issuer, multiMerchantList: $multiMerchantList, name: $name, paymentSystem: $paymentSystem, requiresAuthentication: $requiresAuthentication, salesChannels: $salesChannels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Rule
#
# DELETE /api/pvt/rules/{ruleId}
# operationId: Rule
export def "pvt-rules Rule" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/rules/($ruleId)")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rule By Id
#
# GET /api/pvt/rules/{ruleId}
# operationId: RuleById
export def "pvt-rules RuleById" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/rules/($ruleId)")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rule By Id
#
# PUT /api/pvt/rules/{ruleId}
# operationId: PutRuleById
# --antifraud shape: {affiliationId: string}
# --connector shape: {affiliationId: string, implementation: string}
# --installmentOptions shape: {interestRateMethod: string}
# --issuer shape: {name: string}
# --paymentSystem shape: {id: int, implementation: string, name: string}
# --salesChannels item shape: {id: string}
export def "pvt-rules PutRuleById" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  antifraud: record # e.g. {affiliationId: f952588c-8b41-41cc-a06f-c0f48f7320ef} — shape: {affiliationId: string}
  beginDate: string
  --condition: string # nullable
  connector: record # e.g. {affiliationId: e046d326-5421-45ab-95ae-f13d37f260b5, implementation: Vtex.PaymentGateway.Connectors.PromissoryConnector} — shape: {affiliationId: string, implementation: string}
  --country: string # nullable
  --dateIntervals: string # nullable
  --enabled: oneof<nothing, bool>
  endDate: string
  id: string
  installmentOptions: record # e.g. {interestRateMethod: } — shape: {interestRateMethod: string}
  --isDefault: string # nullable
  --isSelfAuthorized: string # nullable
  issuer: record # e.g. {name: } — shape: {name: string}
  --multiMerchantList: string # nullable
  name: string
  paymentSystem: record # e.g. {id: 47, implementation: , name: Cash} — shape: {id: int, implementation: string, name: string}
  salesChannels: list # item shape: {id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/rules/($ruleId)")
  let body = {antifraud: $antifraud, beginDate: $beginDate, condition: $condition, connector: $connector, country: $country, dateIntervals: $dateIntervals, enabled: $enabled, endDate: $endDate, id: $id, installmentOptions: $installmentOptions, isDefault: $isDefault, isSelfAuthorized: $isSelfAuthorized, issuer: $issuer, multiMerchantList: $multiMerchantList, name: $name, paymentSystem: $paymentSystem, salesChannels: $salesChannels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 1. Starts a new transaction
#
# POST /api/pvt/transactions
# operationId: 1.Createanewtransaction
export def "pvt-transactions 1Createanewtransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  channel: string
  referenceId: string
  salesChannel: string
  --urn: string
  value: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/transactions")
  let body = {channel: $channel, referenceId: $referenceId, salesChannel: $salesChannel, urn: $urn, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transaction Details
#
# GET /api/pvt/transactions/{transactionId}
# operationId: TransactionDetails
export def "pvt-transactions TransactionDetails" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 3. Send Additional Data
#
# POST /api/pvt/transactions/{transactionId}/additional-data
# operationId: 3.SendAdditionalData
export def "pvt-transactions-additional-data 3SendAdditionalData" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --name: string # Type of data that will be added to the transaction.
  --value: string # Data to be added to the transaction.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)/additional-data")
  let body = {name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Do authorization
#
# POST /api/pvt/transactions/{transactionId}/authorization-request
# operationId: 4.Doauthorization
export def "pvt-transactions-authorization-request 4Doauthorization" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --prepareForRecurrency: oneof<nothing, bool>
  softDescriptor: string
  --body-transactionId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)/authorization-request")
  let body = {prepareForRecurrency: $prepareForRecurrency, softDescriptor: $softDescriptor, transactionId: $body_transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel the transaction
#
# POST /api/pvt/transactions/{transactionId}/cancellation-request
# operationId: Cancelthetransaction
# --minicart shape: {freight?: int, items?: list, tax?: int}
export def "pvt-transactions-cancellation-request Cancelthetransaction" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --minicart: record # This field is filled with the content of the cart of the transaction, which can be obtained using [Get Orders](https://developers.vtex.com/vtex-rest-api/reference/orders#getorder) or [Transaction Details](https://developers.vtex.com/vtex-rest-api/reference/transaction-process#transactiondetails) endpoints. It should only be included for transactions with split payment. (default: {minicart: {freight: 200, items: [{discount: 50, id: 122323, name: Tenis Preto I, quantity: 1, shippingDiscount: 0, value: 1000}, {discount: 50, id: 122324, name: Tenis Nike Azul, quantity: 1, shippingDiscount: 0, value: 1100}], tax: 0}, value: 2300}) — shape: {freight?: int, items?: list, tax?: int}
  value: int # Value of the purchase. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)/cancellation-request")
  let body = {minicart: $minicart, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2.2 Send Payments With Saved Credit Card
#
# POST /api/pvt/transactions/{transactionId}/payments
# operationId: 2.SendPaymentsWithSavedCreditCard
export def "pvt-transactions-payments 2SendPaymentsWithSavedCreditCard" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)/payments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Payment Details
#
# GET /api/pvt/transactions/{transactionId}/payments/{paymentId}
# operationId: PaymentDetails
export def "pvt-transactions-payments PaymentDetails" [
  transactionId: string
  paymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)/payments/($paymentId)")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refund the transaction
#
# POST /api/pvt/transactions/{transactionId}/refunding-request
# operationId: Refundthetransaction
# --minicart shape: {freight?: int, items?: list, tax?: int}
export def "pvt-transactions-refunding-request Refundthetransaction" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --minicart: record # This field is filled with the content of the cart of the transaction, which can be obtained using [Get Orders](https://developers.vtex.com/vtex-rest-api/reference/orders#getorder) or [Transaction Details](https://developers.vtex.com/vtex-rest-api/reference/transaction-process#transactiondetails) endpoints. It should only be included for transactions with split payment. (default: {minicart: {freight: 200, items: [{discount: 50, id: 122323, name: Tenis Preto I, quantity: 1, shippingDiscount: 0, value: 1000}, {discount: 50, id: 122324, name: Tenis Nike Azul, quantity: 1, shippingDiscount: 0, value: 1100}], tax: 0}, value: 2300}) — shape: {freight?: int, items?: list, tax?: int}
  value: int # Value of the purchase. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)/refunding-request")
  let body = {minicart: $minicart, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Settle the transaction
#
# POST /api/pvt/transactions/{transactionId}/settlement-request
# operationId: Settlethetransaction
export def "pvt-transactions-settlement-request Settlethetransaction" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  value: int # format: int32
]: any -> record<cancelledValue: int, connectorRefundedValue: int, message: string, processingDate: string, refundedToken: string, refundedValue: int, status: int, statusDetail: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)/settlement-request")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transaction Settlement  Details
#
# GET /api/pvt/transactions/{transactionId}/settlements
# operationId: TransactionSettlementDetails
export def "pvt-transactions-settlements TransactionSettlementDetails" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-PROVIDER-API-AppKey: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --X-PROVIDER-API-AppToken: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --Content-Type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --Accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> record<actions: table<connectorResponse: string, date: string, payment: record, paymentId: string, type: string, value: int>, requests: table<date: string, id: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pvt/transactions/($transactionId)/settlements")
  let extra_headers = {"X-PROVIDER-API-AppKey": $X_PROVIDER_API_AppKey, "X-PROVIDER-API-AppToken": $X_PROVIDER_API_AppToken, "Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
