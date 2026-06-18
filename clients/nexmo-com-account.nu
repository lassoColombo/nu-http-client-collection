# Auto-generated client for Account API v1.0.4
# Source: https://api.apis.guru/v2/specs/nexmo.com/account/1.0.4/openapi.json
# Auth: --token flag or $env.ACCOUNT_API_TOKEN

const BASE_URL = "https://api.nexmo.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://api.nexmo.com" "https://rest.nexmo.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def provider-completer [] { ["email"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-get-balance get" } } | get name | first)
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

# Get Account Balance
#
# GET /account/get-balance
# operationId: getAccountBalance
export def "account-get-balance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-key: string # Your Vonage API key. You can find this in the [dashboard](https://dashboard.nexmo.com) (e.g. abcd1234)
  --api-secret: string # Your Vonage API secret. You can find this in the [dashboard](https://dashboard.nexmo.com) (e.g. ABCDEFGH01234abc)
]: nothing -> record<autoReload: bool, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://rest.nexmo.com")
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "api_secret" $api_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/get-balance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register an email sender
#
# POST /account/register-sender
# operationId: registerSender
export def "account-register-sender create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # Your Vonage API key. You can find this in the [dashboard](https://dashboard.nexmo.com) (e.g. abcd1234)
  --api-secret: string # Your Vonage API secret. You can find this in the [dashboard](https://dashboard.nexmo.com) (e.g. ABCDEFGH01234abc)
  --application-ids: record # An optional array of additional ApplicationID's that the value is to be assigned to. (e.g. [6ec9eb7de1d34e77ac2c0ad597c9554a, 5dba5838689f402dba0c77957e2181f3])
  --name: string # An optional name to be attached to this binding (e.g. my-email-link)
  provider: string@provider-completer # The delivery method by which the value would be assigned. Always `email` (format: enum, e.g. email)
  value: string # The email adress to attach to the application(s) (format: email, e.g. bob@company.com)
]: any -> record<application_ids: list<string>, name: string, provider: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://rest.nexmo.com")
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "api_secret" $api_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/register-sender" $qp)
  let req_body = {"application_ids": $application_ids, "name": $name, "provider": $provider, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Change Account Settings
#
# POST /account/settings
# operationId: changeAccountSettings
export def "account-settings create-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-key: string # Your Vonage API key. You can find this in the [dashboard](https://dashboard.nexmo.com) (e.g. abcd1234)
  --api-secret: string # Your Vonage API secret. You can find this in the [dashboard](https://dashboard.nexmo.com) (e.g. ABCDEFGH01234abc)
  --dr-call-back-url: string # The webhook URL that Vonage makes a request to when a delivery receipt is available for an SMS sent by one of your Vonage numbers. Send an empty string to unset this value. (format: url, e.g. https://example.com/webhooks/delivery-receipt)
  --mo-call-back-url: string # The default webhook URL for inbound SMS. If an SMS is received at a Vonage number that does not have its own inbound SMS webhook configured, Vonage makes a request here. Send an empty string to unset this value. (format: url, e.g. https://example.com/webhooks/inbound-sms)
]: any -> record<dr_callback_url: string, max_calls_per_second: int, max_inbound_request: int, max_outbound_request: int, mo_callback_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://rest.nexmo.com")
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "api_secret" $api_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/settings" $qp)
  let req_body = {"drCallBackUrl": $dr_call_back_url, "moCallBackUrl": $mo_call_back_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Top Up Account Balance
#
# POST /account/top-up
# Docs: https://help.nexmo.com/hc/en-us/articles/205603248-How-do-I-set-up-automatic-payments-using-PayPal-or-credit-card- — Read more about automatic payments on the Knowledgebase
# operationId: topUpAccountBalance
export def "account-top-up top-balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-key: string # Your Vonage API key. You can find this in the [dashboard](https://dashboard.nexmo.com) (e.g. abcd1234)
  --api-secret: string # Your Vonage API secret. You can find this in the [dashboard](https://dashboard.nexmo.com) (e.g. ABCDEFGH01234abc)
  trx: string # The transaction reference of the transaction when balance was added and auto-reload was enabled on your account. (e.g. 8ef2447e69604f642ae59363aa5f781b)
]: any -> record<error_code: any, error_code_label: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://rest.nexmo.com")
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "api_secret" $api_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/top-up" $qp)
  let req_body = {"trx": $trx} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve API Secrets
#
# GET /accounts/{api_key}/secrets
# operationId: retrieveAPISecrets
export def "accounts-secrets list" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_embedded: record<secrets: list<record>>, _links: record<self: record<href: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/accounts/{api_key}/secrets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create API Secret
#
# POST /accounts/{api_key}/secrets
# operationId: createAPISecret
export def "accounts-secrets create" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  secret: string # The new secret must follow these rules: * minimum 8 characters * maximum 25 characters * minimum 1 lower case character * minimum 1 upper case character * minimum 1 digit (e.g. example-4PI-secret)
]: any -> record<_links: record<self: record<href: string>>, created_at: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/accounts/{api_key}/secrets"))
  let req_body = {"secret": $secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Revoke an API Secret
#
# DELETE /accounts/{api_key}/secrets/{secret_id}
# operationId: revokeAPISecret
export def "accounts-secrets delete" [
  api_key: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), secret_id: (encode-path-segment $secret_id)} | format pattern "/accounts/{api_key}/secrets/{secret_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve one API Secret
#
# GET /accounts/{api_key}/secrets/{secret_id}
# operationId: retrieveAPISecret
export def "accounts-secrets get" [
  api_key: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, created_at: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key), secret_id: (encode-path-segment $secret_id)} | format pattern "/accounts/{api_key}/secrets/{secret_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
