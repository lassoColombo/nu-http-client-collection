# Auto-generated client for Spreedly API vv1
# Source: https://raw.githubusercontent.com/venuenext/spreedly_openapi/master/spreedly.openapi3.yml
# Auth: --token flag or $env.SPREEDLY_API_TOKEN

const BASE_URL = "https://core.spreedly.com/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SPREEDLY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def base-url-completer [] { ["https://core.spreedly.com/v1"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def order-completer [] { ["asc" "desc"] }
def state-completer [] { ["failed" "gateway_processing_failed" "gateway_processing_result_unknown" "succeeded"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "gateways-optionsjson optionslist" } } | get name | first)
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

# List supported gateways
#
# GET /gateways_options.json
# operationId: gateways_options.list
export def "gateways-optionsjson optionslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<gateways: table<gateway_type: string, name: string, auth_modes: list, characteristics: list, payment_methods: list, gateway_specific_fields: list, supported_countries: list, supported_cardtypes: list, regions: list, homepage: string, company_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gateways_options.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List created gateways
#
# GET /gateways.json
# operationId: gateways.list
export def "gatewaysjson gatewayslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order of the returned list. Default is `asc`, which returns the oldest records first. To list newer records first, use `desc`.
  --since-token: string # The token of the item to start from (e.g., the last token received in the previous list if iterating through records)
]: nothing -> record<gateways: table<token: string, name: string, gateway_type: string, state: string, redacted: bool, credentials: list, characteristics: list, payment_methods: list, gateway_specific_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "since_token" $since_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gateways.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create gateway
#
# POST /gateways.json
# operationId: gateways.create
# --gateway shape: {gateway_type: string, description?: any}
export def "gatewaysjson gatewayscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gateway: record # shape: {gateway_type: string, description?: any}
]: any -> record<gateway: record<token: string, name: string, gateway_type: string, state: string, redacted: bool, credentials: list<any>, characteristics: list<string>, payment_methods: list<string>, gateway_specific_fields: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gateways.json")
  let body = {gateway: $gateway} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show gateway
#
# GET /gateways/{gateway_token}.json
# operationId: gateways.show
export def "gateways gatewaysshow" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<gateway: record<token: string, name: string, gateway_type: string, state: string, redacted: bool, credentials: list<any>, characteristics: list<string>, payment_methods: list<string>, gateway_specific_fields: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a gateway
#
# PUT /gateways/{gateway_token}.json
# operationId: gateways.update
# --gateway shape: {description?: any}
export def "gateways gatewaysupdate" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gateway: record # shape: {description?: any}
]: any -> record<gateway: record<token: string, name: string, gateway_type: string, state: string, redacted: bool, credentials: list<any>, characteristics: list<string>, payment_methods: list<string>, gateway_specific_fields: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token).json")
  let body = {gateway: $gateway} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retain
#
# PUT /gateways/{gateway_token}/retain.json
# operationId: gateways.retain
export def "gateways-retainjson gatewaysretain" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token)/retain.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redact
#
# PUT /gateways/{gateway_token}/redact.json
# operationId: gateways.redact
export def "gateways-redactjson gatewaysredact" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token)/redact.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transactions
#
# GET /gateways/{gateway_token}/transactions.json
# operationId: gateways.list_transactions
export def "gateways-transactionsjson transactions" [
  gateway_token: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order of the returned list. Default is `asc`, which returns the oldest records first. To list newer records first, use `desc`.
  --since-token: string # The token of the item to start from (e.g., the last token received in the previous list if iterating through records)
  --state: string@state-completer # The transaction state on which to filter the returned list. Can be one of `succeeded`, `failed`, `gateway_processing_failed`, `gateway_processing_result_unknown`.
]: nothing -> record<transactions: table<token: string, created_at: any, updated_at: any, succeeded: bool, transaction_type: any, retained: bool, state: any, message_key: any, message: string, amount: int, gateway_transaction_id: any, retain_on_success: any, payment_method_added: any, on_test_gateway: any, response: any, payment_methods_submitted: any, payment_methods_included: any, payment_methods_excluded: any, gateway: record, receiver: record, payment_method: record, basis_payment_method: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "since_token" $since_token "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/gateways/($gateway_token)/transactions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List supported receivers
#
# GET /receivers_options.json
# operationId: receivers_options.list
export def "receivers-optionsjson optionslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<receivers: table<name: any, receiver_type: any, hostnames: any, company_name: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/receivers_options.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List created receivers
#
# GET /receivers.json
# operationId: receivers.list
export def "receiversjson receiverslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order of the returned list. Default is `asc`, which returns the oldest records first. To list newer records first, use `desc`.
  --since-token: string # The token of the item to start from (e.g., the last token received in the previous list if iterating through records)
]: nothing -> record<receivers: table<company_name: any, token: any, receiver_type: any, hostnames: any, state: string, credentials: list, protocol_user: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "since_token" $since_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/receivers.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create receiver
#
# POST /receivers.json
# operationId: receivers.create
# --receiver shape: {receiver_type: any, hostnames?: any, credentials?: list, protocol?: record}
export def "receiversjson receiverscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --receiver: record # shape: {receiver_type: any, hostnames?: any, credentials?: list, protocol?: record}
]: any -> record<receiver: record<company_name: any, token: any, receiver_type: any, hostnames: any, state: string, credentials: list<record>, protocol_user: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/receivers.json")
  let body = {receiver: $receiver} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show receiver
#
# GET /receivers/{receiver_token}.json
# operationId: receivers.show
export def "receivers receiversshow" [
  receiver_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<receiver: record<company_name: any, token: any, receiver_type: any, hostnames: any, state: string, credentials: list<record>, protocol_user: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/receivers/($receiver_token).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update receiver
#
# PUT /receivers/{receiver_token}.json
# operationId: receivers.update
# --receiver shape: {credentials: list}
export def "receivers receiversupdate" [
  receiver_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --receiver: record # shape: {credentials: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/receivers/($receiver_token).json")
  let body = {receiver: $receiver} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Redact receiver
#
# PUT /receivers/{receiver_token}/redact.json
# operationId: receivers.redact
export def "receivers-redactjson receiversredact" [
  receiver_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/receivers/($receiver_token)/redact.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create payment method
#
# POST /payment_methods.json
# operationId: payment_methods.create
# --payment_method shape: {credit_card?: record, bank_account?: record, android_pay?: record, google_pay?: record, apple_pay?: record, payment_method_type?: any, reference?: any, gateway_type?: any, retained?: any, email?: any, first_name?: string, last_name?: string, address_1?: string, address_2?: string, city?: string, state?: string, zip?: string, country?: string, allow_blank_name?: bool, allow_expired_date?: bool, allow_blank_date?: bool, eligible_for_card_updater?: bool, metadata?: record, data?: any}
export def "payment-methodsjson methodscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment-method: record # shape: {credit_card?: record, bank_account?: record, android_pay?: record, google_pay?: record, apple_pay?: record, payment_method_type?: any, reference?: any, gateway_type?: any, retained?: any, email?: any, first_name?: string, last_name?: string, address_1?: string, address_2?: string, city?: string, state?: string, zip?: string, country?: string, allow_blank_name?: bool, allow_expired_date?: bool, allow_blank_date?: bool, eligible_for_card_updater?: bool, metadata?: record, data?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_methods.json")
  let body = {payment_method: $payment_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List
#
# GET /payment_methods.json
# operationId: payment_methods.list
export def "payment-methodsjson methodslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order of the returned list. Default is `asc`, which returns the oldest records first. To list newer records first, use `desc`.
  --since-token: string # The token of the item to start from (e.g., the last token received in the previous list if iterating through records)
  --metadata: string # A metadata key/value pair represented as a hash (e.g. `metadata[key]=value`).
  --count: int # The number of payment methods to return. By default returns 20, maximum allowed is 100. (default: 20)
]: nothing -> record<payment_methods: table<token: any, created_at: any, updated_at: any, email: any, data: any, metadata: record, storage_state: any, redacted: any, test: any, payment_method_type: any, errors: list, last_four_digits: any, first_six_digits: any, card_type: string, first_name: any, last_name: any, full_name: any, address1: any, address2: any, city: any, state: any, zip: any, country: any, phone_number: any, company: any, shipping_address1: any, shipping_address2: any, shipping_city: any, shipping_state: any, shipping_zip: any, shipping_country: any, shipping_phone_number: any, verification_value: any, number: any, month: any, year: any, account_type: any, account_holder_type: any, routing_number_display_digits: any, account_number_display_digits: any, third_party_token: any, gateway_type: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "since_token" $since_token "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment_methods.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show payment method
#
# GET /payment_methods/{payment_method_token}.json
# operationId: payment_methods.show
export def "payment-methods methodsshow" [
  payment_method_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payment_method: record<token: any, created_at: any, updated_at: any, email: any, data: any, metadata: record, storage_state: any, redacted: any, test: any, payment_method_type: any, errors: list<any>, last_four_digits: any, first_six_digits: any, card_type: string, first_name: any, last_name: any, full_name: any, address1: any, address2: any, city: any, state: any, zip: any, country: any, phone_number: any, company: any, shipping_address1: any, shipping_address2: any, shipping_city: any, shipping_state: any, shipping_zip: any, shipping_country: any, shipping_phone_number: any, verification_value: any, number: any, month: any, year: any, account_type: any, account_holder_type: any, routing_number_display_digits: any, account_number_display_digits: any, third_party_token: any, gateway_type: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($payment_method_token).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update payment method
#
# PUT /payment_methods/{payment_method_token}.json
# operationId: payment_methods.update
# --payment_method shape: {allow_blank_name?: bool, allow_expired_date?: bool, allow_blank_date?: bool, eligible_for_card_updater?: bool, metadata?: record}
export def "payment-methods methodsupdate" [
  payment_method_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment-method: record # shape: {allow_blank_name?: bool, allow_expired_date?: bool, allow_blank_date?: bool, eligible_for_card_updater?: bool, metadata?: record}
]: any -> record<payment_method: record<token: any, created_at: any, updated_at: any, email: any, data: any, metadata: record, storage_state: any, redacted: any, test: any, payment_method_type: any, errors: list<any>, last_four_digits: any, first_six_digits: any, card_type: string, first_name: any, last_name: any, full_name: any, address1: any, address2: any, city: any, state: any, zip: any, country: any, phone_number: any, company: any, shipping_address1: any, shipping_address2: any, shipping_city: any, shipping_state: any, shipping_zip: any, shipping_country: any, shipping_phone_number: any, verification_value: any, number: any, month: any, year: any, account_type: any, account_holder_type: any, routing_number_display_digits: any, account_number_display_digits: any, third_party_token: any, gateway_type: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($payment_method_token).json")
  let body = {payment_method: $payment_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete metadata
#
# DELETE /payment_methods/{payment_method_token}/metadata.json
# operationId: payment_methods.delete_metadata
export def "payment-methods-metadatajson metadata" [
  payment_method_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keys: list # An array of metadata key whose key/value pairs will be deleted. If a metadata key does not already exist, it will be ignored.
]: any -> record<payment_method: record<token: any, created_at: any, updated_at: any, email: any, data: any, metadata: record, storage_state: any, redacted: any, test: any, payment_method_type: any, errors: list<any>, last_four_digits: any, first_six_digits: any, card_type: string, first_name: any, last_name: any, full_name: any, address1: any, address2: any, city: any, state: any, zip: any, country: any, phone_number: any, company: any, shipping_address1: any, shipping_address2: any, shipping_city: any, shipping_state: any, shipping_zip: any, shipping_country: any, shipping_phone_number: any, verification_value: any, number: any, month: any, year: any, account_type: any, account_holder_type: any, routing_number_display_digits: any, account_number_display_digits: any, third_party_token: any, gateway_type: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($payment_method_token)/metadata.json")
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retain payment method
#
# PUT /payment_methods/{payment_method_token}/retain.json
# operationId: payment_methods.retain
export def "payment-methods-retainjson methodsretain" [
  payment_method_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($payment_method_token)/retain.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Store payment method
#
# PUT /gateways/{gateway_token}/store.json
# operationId: gateways.store
# --transaction shape: {payment_method_token: any, currency_code?: any}
export def "gateways-storejson gatewaysstore" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: record # shape: {payment_method_token: any, currency_code?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token)/store.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Redact payment method
#
# PUT /payment_methods/{payment_method_token}/redact.json
# operationId: payment_methods.redact
# --transaction shape: {remove_from_gateway?: any}
export def "payment-methods-redactjson methodsredact" [
  payment_method_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: record # shape: {remove_from_gateway?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($payment_method_token)/redact.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recache
#
# POST /payment_methods/{payment_method_token}/recache.json
# operationId: payment_methods.recache
# --payment_method shape: {credit_card?: record}
export def "payment-methods-recachejson methodsrecache" [
  payment_method_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment-method: record # shape: {credit_card?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment_methods/($payment_method_token)/recache.json")
  let body = {payment_method: $payment_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transactions
#
# GET /payment_methods/{payment_method_token}/transactions.json
# operationId: payment_methods.list_transactions
export def "payment-methods-transactionsjson transactions" [
  payment_method_token: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order of the returned list. Default is `asc`, which returns the oldest records first. To list newer records first, use `desc`.
  --since-token: string # The token of the item to start from (e.g., the last token received in the previous list if iterating through records)
]: nothing -> record<transactions: table<token: string, created_at: any, updated_at: any, succeeded: bool, transaction_type: any, retained: bool, state: any, message_key: any, message: string, amount: int, gateway_transaction_id: any, retain_on_success: any, payment_method_added: any, on_test_gateway: any, response: any, payment_methods_submitted: any, payment_methods_included: any, payment_methods_excluded: any, gateway: record, receiver: record, payment_method: record, basis_payment_method: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "since_token" $since_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/payment_methods/($payment_method_token)/transactions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List certificates
#
# GET /certificates.json
# operationId: certificates.list
export def "certificatesjson certificateslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order of the returned list. Default is `asc`, which returns the oldest records first. To list newer records first, use `desc`.
  --since-token: string # The token of the item to start from (e.g., the last token received in the previous list if iterating through records)
]: nothing -> record<certificates: table<token: any, created_at: any, updated_at: any, algorithm: any, cn: any, o: any, ou: any, c: any, st: any, l: any, email_address: any, public_key: any, public_key_hash: any, csr: any, pem: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "since_token" $since_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create certificate
#
# POST /certificates.json
# operationId: certificates.create
# --certificate shape: {algorithm: "ec-prime256v1", cn: any, o?: any, ou?: any, c?: any, st?: any, l?: any, email_address?: any}
export def "certificatesjson certificatescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --certificate: record # shape: {algorithm: "ec-prime256v1", cn: any, o?: any, ou?: any, c?: any, st?: any, l?: any, email_address?: any}
]: any -> record<certificate: record<token: any, created_at: any, updated_at: any, algorithm: any, cn: any, o: any, ou: any, c: any, st: any, l: any, email_address: any, public_key: any, public_key_hash: any, csr: any, pem: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/certificates.json")
  let body = {certificate: $certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update certificate
#
# PUT /certificates/{certificate_token}.json
# operationId: certificates.update
# --certificate shape: {pem: any}
export def "certificates certificatesupdate" [
  certificate_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --certificate: record # shape: {pem: any}
]: any -> record<certificate: record<token: any, created_at: any, updated_at: any, algorithm: any, cn: any, o: any, ou: any, c: any, st: any, l: any, email_address: any, public_key: any, public_key_hash: any, csr: any, pem: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/certificates/($certificate_token).json")
  let body = {certificate: $certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List transactions
#
# GET /transactions.json
# operationId: transactions.list
export def "transactionsjson transactionslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # The order of the returned list. Default is `asc`, which returns the oldest records first. To list newer records first, use `desc`.
  --since-token: string # The token of the item to start from (e.g., the last token received in the previous list if iterating through records)
  --state: string@state-completer # The transaction state on which to filter the returned list. Can be one of `succeeded`, `failed`, `gateway_processing_failed`, `gateway_processing_result_unknown`.
  --count: int # The number of transactions to return. By default returns 20, maximum allowed is 100. (default: 20)
]: nothing -> record<transactions: table<token: string, created_at: any, updated_at: any, succeeded: bool, transaction_type: any, retained: bool, state: any, message_key: any, message: string, amount: int, gateway_transaction_id: any, retain_on_success: any, payment_method_added: any, on_test_gateway: any, response: any, payment_methods_submitted: any, payment_methods_included: any, payment_methods_excluded: any, gateway: record, receiver: record, payment_method: record, basis_payment_method: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "since_token" $since_token "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show transaction
#
# GET /transactions/{transaction_token}.json
# operationId: transactions.show
export def "transactions transactionsshow" [
  transaction_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payment_method: record<token: string, created_at: any, updated_at: any, succeeded: bool, transaction_type: any, retained: bool, state: any, message_key: any, message: string, amount: int, gateway_transaction_id: any, retain_on_success: any, payment_method_added: any, on_test_gateway: any, response: any, payment_methods_submitted: any, payment_methods_included: any, payment_methods_excluded: any, gateway: record<token: string, name: string, gateway_type: string, state: string, redacted: bool, credentials: list, characteristics: list, payment_methods: list, gateway_specific_fields: list>, receiver: record<company_name: any, token: any, receiver_type: any, hostnames: any, state: string, credentials: list, protocol_user: any>, payment_method: record<token: any, created_at: any, updated_at: any, email: any, data: any, metadata: record, storage_state: any, redacted: any, test: any, payment_method_type: any, errors: list, last_four_digits: any, first_six_digits: any, card_type: string, first_name: any, last_name: any, full_name: any, address1: any, address2: any, city: any, state: any, zip: any, country: any, phone_number: any, company: any, shipping_address1: any, shipping_address2: any, shipping_city: any, shipping_state: any, shipping_zip: any, shipping_country: any, shipping_phone_number: any, verification_value: any, number: any, month: any, year: any, account_type: any, account_holder_type: any, routing_number_display_digits: any, account_number_display_digits: any, third_party_token: any, gateway_type: any>, basis_payment_method: record<token: any, created_at: any, updated_at: any, email: any, data: any, metadata: record, storage_state: any, redacted: any, test: any, payment_method_type: any, errors: list, last_four_digits: any, first_six_digits: any, card_type: string, first_name: any, last_name: any, full_name: any, address1: any, address2: any, city: any, state: any, zip: any, country: any, phone_number: any, company: any, shipping_address1: any, shipping_address2: any, shipping_city: any, shipping_state: any, shipping_zip: any, shipping_country: any, shipping_phone_number: any, verification_value: any, number: any, month: any, year: any, account_type: any, account_holder_type: any, routing_number_display_digits: any, account_number_display_digits: any, third_party_token: any, gateway_type: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_token).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transcript
#
# GET /transactions/{transaction_token}/transcript
# operationId: transactions.transcript
export def "transactions-transcript transactionstranscript" [
  transaction_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_token)/transcript")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purchase
#
# POST /gateways/{gateway_token}/purchase.json
# operationId: gateways.purchase
export def "gateways-purchasejson gatewayspurchase" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token)/purchase.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reference purchase
#
# POST /transactions/{transaction_token}/purchase.json
# operationId: transactions.purchase
# --transaction shape: {amount: int, currency_code: any, order_id?: any, description?: any, retain_on_success?: any, ip?: any, email?: any, shipping_address?: record, allow_blank_name?: bool, allow_expired_date?: bool, allow_blank_date?: bool}
export def "transactions-purchasejson transactionspurchase" [
  transaction_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: record # shape: {amount: int, currency_code: any, order_id?: any, description?: any, retain_on_success?: any, ip?: any, email?: any, shipping_address?: record, allow_blank_name?: bool, allow_expired_date?: bool, allow_blank_date?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_token)/purchase.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authorize
#
# POST /gateways/{gateway_token}/authorize.json
# operationId: gateways.authorize
export def "gateways-authorizejson gatewaysauthorize" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token)/authorize.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Capture
#
# POST /transactions/{transaction_token}/capture.json
# operationId: transactions.capture
# --transaction shape: {amount?: any, currency_code?: any}
export def "transactions-capturejson transactionscapture" [
  transaction_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: record # shape: {amount?: any, currency_code?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_token)/capture.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Void
#
# POST /transactions/{transaction_token}/void.json
# operationId: transactions.void
export def "transactions-voidjson transactionsvoid" [
  transaction_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_token)/void.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Credit (refund)
#
# POST /transactions/{transaction_token}/credit.json
# operationId: transactions.credit
# --transaction shape: {amount?: any, currency_code?: any}
export def "transactions-creditjson transactionscredit" [
  transaction_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: record # shape: {amount?: any, currency_code?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_token)/credit.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# General credit
#
# POST /gateways/{gateway_token}/general_credit.json
# operationId: gateways.general_credit
# --transaction shape: {payment_method_token: any, amount: any, currency_code: any, order_id?: any, description?: any, continue_caching?: any, ip?: any, email?: any}
export def "gateways-general-creditjson credit" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: record # shape: {payment_method_token: any, amount: any, currency_code: any, order_id?: any, description?: any, continue_caching?: any, ip?: any, email?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token)/general_credit.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify
#
# POST /gateways/{gateway_token}/verify.json
# operationId: gateways.verify
# --transaction shape: {payment_method_token?: any, retain_on_success?: any, currency_code?: any, ip?: any}
export def "gateways-verifyjson gatewaysverify" [
  gateway_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transaction: any # shape: {payment_method_token?: any, retain_on_success?: any, currency_code?: any, ip?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gateways/($gateway_token)/verify.json")
  let body = {transaction: $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deliver
#
# POST /receivers/{receiver_token}/deliver.json
# operationId: receivers.deliver
# --delivery shape: {continue_caching?: any, payment_method_token?: any, url?: any, request_method?: any, headers?: any, body?: any, encode_response?: any}
export def "receivers-deliverjson receiversdeliver" [
  receiver_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delivery: any # shape: {continue_caching?: any, payment_method_token?: any, url?: any, request_method?: any, headers?: any, body?: any, encode_response?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/receivers/($receiver_token)/deliver.json")
  let body = {delivery: $delivery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export
#
# POST /receivers/{receiver_token}/export.json
# operationId: receivers.export
# --delivery shape: {payment_method_tokens?: list, payment_method_data?: record, url?: any, body?: any, callback_url?: any}
export def "receivers-exportjson receiversexport" [
  receiver_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delivery: any # shape: {payment_method_tokens?: list, payment_method_data?: record, url?: any, body?: any, callback_url?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/receivers/($receiver_token)/export.json")
  let body = {delivery: $delivery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
