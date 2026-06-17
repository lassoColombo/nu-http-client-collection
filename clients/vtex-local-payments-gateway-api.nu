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
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # e.g. {{orderId}}
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $order_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pub/transactions/{transaction_id}/payments") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Affiliations
#
# GET /api/pvt/affiliations
# operationId: Affiliations
export def "pvt-affiliations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/affiliations")
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
export def "pvt-affiliations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  configuration: list # item shape: {name: string, value: string}
  implementation: string
  --is-configured: oneof<nothing, bool>
  --isdelivered: oneof<nothing, bool>
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/affiliations")
  let body = {"configuration": $configuration, "implementation": $implementation, "isConfigured": $is_configured, "isdelivered": $isdelivered, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Affiliation By Id
#
# GET /api/pvt/affiliations/{affiliationId}
# operationId: AffiliationById
export def "pvt-affiliations get" [
  affiliation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({affiliation_id: $affiliation_id} | format pattern "/api/pvt/affiliations/{affiliation_id}"))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
export def "pvt-affiliations update" [
  affiliation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  configuration: list # item shape: {name: string, value: string}
  id: string
  implementation: string
  --is-configured: oneof<nothing, bool>
  --isdelivered: oneof<nothing, bool>
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({affiliation_id: $affiliation_id} | format pattern "/api/pvt/affiliations/{affiliation_id}"))
  let body = {"configuration": $configuration, "id": $id, "implementation": $implementation, "isConfigured": $is_configured, "isdelivered": $isdelivered, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Installments options
#
# GET /api/pvt/installments
# operationId: Installmentsoptions
export def "pvt-installments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-value: int # format: int32, e.g. 10
  --request-sales-channel: int # format: int32, e.g. 1
  --request-payment-details-0-id: int # format: int32, e.g. 2
  --request-payment-details-0-value: int # format: int32, e.g. 10
  --request-payment-details-0-bin: int # format: int32, e.g. 411111
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request.value" $request_value "scalar") (serialize-qp "request.salesChannel" $request_sales_channel "scalar") (serialize-qp "request.paymentDetails[0].id" $request_payment_details_0_id "scalar") (serialize-qp "request.paymentDetails[0].value" $request_payment_details_0_value "scalar") (serialize-qp "request.paymentDetails[0].bin" $request_payment_details_0_bin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/pvt/installments" $qp)
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Available Payment Methods
#
# GET /api/pvt/merchants/payment-systems
# operationId: AvailablePaymentMethods
export def "pvt-merchants-payment-systems get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/merchants/payment-systems")
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rules
#
# GET /api/pvt/rules
# operationId: Rules
export def "pvt-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/rules")
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
export def "pvt-rules create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  antifraud: record # e.g. {affiliationId: , implementation: } — shape: {affiliationId: string, implementation: string}
  --begin-date: string # nullable
  --condition: string # nullable
  connector: record # e.g. {affiliationId: e046d326-5421-45ab-95ae-f13d37f260b5, implementation: Vtex.PaymentGateway.Connectors.PromissoryConnector} — shape: {affiliationId: string, implementation: string}
  --country: string # nullable
  --date-intervals: string # nullable
  --enabled: oneof<nothing, bool>
  --end-date: string # nullable
  --installment-options: string # nullable
  --installments-service: string # nullable
  --is-default: oneof<nothing, bool>
  --is-self-authorized: string # nullable
  issuer: record # e.g. {name: } — shape: {name: string}
  --multi-merchant-list: string # nullable
  name: string
  payment_system: record # e.g. {id: 47, implementation: , name: Cash} — shape: {id: int, implementation: string, name: string}
  --requires-authentication: string # nullable
  sales_channels: list # item shape: {id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/rules")
  let body = {"antifraud": $antifraud, "beginDate": $begin_date, "condition": $condition, "connector": $connector, "country": $country, "dateIntervals": $date_intervals, "enabled": $enabled, "endDate": $end_date, "installmentOptions": $installment_options, "installmentsService": $installments_service, "isDefault": $is_default, "isSelfAuthorized": $is_self_authorized, "issuer": $issuer, "multiMerchantList": $multi_merchant_list, "name": $name, "paymentSystem": $payment_system, "requiresAuthentication": $requires_authentication, "salesChannels": $sales_channels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Rule
#
# DELETE /api/pvt/rules/{ruleId}
# operationId: Rule
export def "pvt-rules delete" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/api/pvt/rules/{rule_id}"))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rule By Id
#
# GET /api/pvt/rules/{ruleId}
# operationId: RuleById
export def "pvt-rules get" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/api/pvt/rules/{rule_id}"))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
export def "pvt-rules update" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  antifraud: record # e.g. {affiliationId: f952588c-8b41-41cc-a06f-c0f48f7320ef} — shape: {affiliationId: string}
  begin_date: string
  --condition: string # nullable
  connector: record # e.g. {affiliationId: e046d326-5421-45ab-95ae-f13d37f260b5, implementation: Vtex.PaymentGateway.Connectors.PromissoryConnector} — shape: {affiliationId: string, implementation: string}
  --country: string # nullable
  --date-intervals: string # nullable
  --enabled: oneof<nothing, bool>
  end_date: string
  id: string
  installment_options: record # e.g. {interestRateMethod: } — shape: {interestRateMethod: string}
  --is-default: string # nullable
  --is-self-authorized: string # nullable
  issuer: record # e.g. {name: } — shape: {name: string}
  --multi-merchant-list: string # nullable
  name: string
  payment_system: record # e.g. {id: 47, implementation: , name: Cash} — shape: {id: int, implementation: string, name: string}
  sales_channels: list # item shape: {id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/api/pvt/rules/{rule_id}"))
  let body = {"antifraud": $antifraud, "beginDate": $begin_date, "condition": $condition, "connector": $connector, "country": $country, "dateIntervals": $date_intervals, "enabled": $enabled, "endDate": $end_date, "id": $id, "installmentOptions": $installment_options, "isDefault": $is_default, "isSelfAuthorized": $is_self_authorized, "issuer": $issuer, "multiMerchantList": $multi_merchant_list, "name": $name, "paymentSystem": $payment_system, "salesChannels": $sales_channels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type, "X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token} | compact
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
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  channel: string
  reference_id: string
  sales_channel: string
  --urn: string
  value: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pvt/transactions")
  let body = {"channel": $channel, "referenceId": $reference_id, "salesChannel": $sales_channel, "urn": $urn, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transaction Details
#
# GET /api/pvt/transactions/{transactionId}
# operationId: TransactionDetails
export def "pvt-transactions get" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pvt/transactions/{transaction_id}"))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --name: string # Type of data that will be added to the transaction.
  --value: string # Data to be added to the transaction.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pvt/transactions/{transaction_id}/additional-data"))
  let body = {"name": $name, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
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
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --prepare-for-recurrency: oneof<nothing, bool>
  soft_descriptor: string
  --body-transaction-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pvt/transactions/{transaction_id}/authorization-request"))
  let body = {"prepareForRecurrency": $prepare_for_recurrency, "softDescriptor": $soft_descriptor, "transactionId": $body_transaction_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
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
export def "pvt-transactions-cancellation-request cancel-thetransaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --minicart: record # This field is filled with the content of the cart of the transaction, which can be obtained using [Get Orders](https://developers.vtex.com/vtex-rest-api/reference/orders#getorder) or [Transaction Details](https://developers.vtex.com/vtex-rest-api/reference/transaction-process#transactiondetails) endpoints. It should only be included for transactions with split payment. (default: {minicart: {freight: 200, items: [{discount: 50, id: 122323, name: Tenis Preto I, quantity: 1, shippingDiscount: 0, value: 1000}, {discount: 50, id: 122324, name: Tenis Nike Azul, quantity: 1, shippingDiscount: 0, value: 1100}], tax: 0}, value: 2300}) — shape: {freight?: int, items?: list, tax?: int}
  value: int # Value of the purchase. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pvt/transactions/{transaction_id}/cancellation-request"))
  let body = {"minicart": $minicart, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
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
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pvt/transactions/{transaction_id}/payments"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Payment Details
#
# GET /api/pvt/transactions/{transactionId}/payments/{paymentId}
# operationId: PaymentDetails
export def "pvt-transactions-payments get" [
  transaction_id: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id, payment_id: $payment_id} | format pattern "/api/pvt/transactions/{transaction_id}/payments/{payment_id}"))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
export def "pvt-transactions-refunding-request post" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --minicart: record # This field is filled with the content of the cart of the transaction, which can be obtained using [Get Orders](https://developers.vtex.com/vtex-rest-api/reference/orders#getorder) or [Transaction Details](https://developers.vtex.com/vtex-rest-api/reference/transaction-process#transactiondetails) endpoints. It should only be included for transactions with split payment. (default: {minicart: {freight: 200, items: [{discount: 50, id: 122323, name: Tenis Preto I, quantity: 1, shippingDiscount: 0, value: 1000}, {discount: 50, id: 122324, name: Tenis Nike Azul, quantity: 1, shippingDiscount: 0, value: 1100}], tax: 0}, value: 2300}) — shape: {freight?: int, items?: list, tax?: int}
  value: int # Value of the purchase. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pvt/transactions/{transaction_id}/refunding-request"))
  let body = {"minicart": $minicart, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Settle the transaction
#
# POST /api/pvt/transactions/{transactionId}/settlement-request
# operationId: Settlethetransaction
export def "pvt-transactions-settlement-request post" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  value: int # format: int32
]: any -> record<cancelledValue: int, connectorRefundedValue: int, message: string, processingDate: string, refundedToken: string, refundedValue: int, status: int, statusDetail: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pvt/transactions/{transaction_id}/settlement-request"))
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transaction Settlement  Details
#
# GET /api/pvt/transactions/{transactionId}/settlements
# operationId: TransactionSettlementDetails
export def "pvt-transactions-settlements get" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-provider-api-app-key: string # The AppKey configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppKey}})
  --x-provider-api-app-token: string # The AppToken configured by the merchant (optional configuration) (e.g. {{X-PROVIDER-API-AppToken}})
  --content-type: string # The Media type of the body of the request.  Default value for payment provider protocol is application/json (e.g. application/json)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json (e.g. application/json)
]: nothing -> record<actions: table<connectorResponse: string, date: string, payment: record, paymentId: string, type: string, value: int>, requests: table<date: string, id: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/api/pvt/transactions/{transaction_id}/settlements"))
  let extra_headers = {"X-PROVIDER-API-AppKey": $x_provider_api_app_key, "X-PROVIDER-API-AppToken": $x_provider_api_app_token, "Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
