# Auto-generated client for Account and Transaction API Specification - UK vv3.1.5
# Source: https://api.apis.guru/v2/specs/nbg.gr/v3.1.5/openapi.json
# Auth: --token flag or $env.ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_TOKEN

const BASE_URL = "https://apis.nbg.gr/sandbox/uk.openbanking.accountinfo/oauth2/v3.1.5"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "client-id" => { {headers: {Client-Id: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://apis.nbg.gr/sandbox/uk.openbanking.accountinfo/oauth2/v3.1.5" "https://services.nbg.gr/apis/open-banking/v3.1.5/aisp"] }
def auth-scheme-completer [] { ["bearer" "client-id"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/json; charset=utf-8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-access-consents post" } } | get name | first)
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

# Create Account Access Consents
#
# POST /account-access-consents
# --Data shape: {ExpirationDateTime?: string, Permissions: list, TransactionFromDateTime?: string, TransactionToDateTime?: string}
export def "account-access-consents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
  data: record # shape: {ExpirationDateTime?: string, Permissions: list, TransactionFromDateTime?: string, TransactionToDateTime?: string}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Account Info.
]: any -> record<Data: record<ConsentId: string, CreationDateTime: string, ExpirationDateTime: string, Permissions: list<string>, Status: string, StatusUpdateDateTime: string, TransactionFromDateTime: string, TransactionToDateTime: string>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>, Risk: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account-access-consents")
  let body = {"Data": $data, "Risk": $risk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Account Access Consents
#
# DELETE /account-access-consents/{consentId}
export def "account-access-consents delete" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({consent_id: $consent_id} | format pattern "/account-access-consents/{consent_id}"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Account Access Consents
#
# GET /account-access-consents/{consentId}
export def "account-access-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<ConsentId: string, CreationDateTime: string, ExpirationDateTime: string, Permissions: list<string>, Status: string, StatusUpdateDateTime: string, TransactionFromDateTime: string, TransactionToDateTime: string>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>, Risk: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({consent_id: $consent_id} | format pattern "/account-access-consents/{consent_id}"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Accounts
#
# GET /accounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Account: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Accounts
#
# GET /accounts/{accountId}
export def "accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Account: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Balances
#
# GET /accounts/{accountId}/balances
export def "accounts-balances get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Balance: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}/balances"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Beneficiaries
#
# GET /accounts/{accountId}/beneficiaries
export def "accounts-beneficiaries get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Beneficiary: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}/beneficiaries"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Parties
#
# GET /accounts/{accountId}/parties
export def "accounts-parties get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Party: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}/parties"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Party
#
# GET /accounts/{accountId}/party
export def "accounts-party get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Party: record<Name: string, PartyId: string>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}/party"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Scheduled Payments
#
# GET /accounts/{accountId}/scheduled-payments
export def "accounts-scheduled-payments get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<ScheduledPayment: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}/scheduled-payments"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Standing Orders
#
# GET /accounts/{accountId}/standing-orders
export def "accounts-standing-orders get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<StandingOrder: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}/standing-orders"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Statements
#
# GET /accounts/{accountId}/statements
export def "accounts-statements list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from-statement-date-time: string # The UTC ISO 8601 Date Time to filter statements FROM NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (nullable, format: date-time)
  --to-statement-date-time: string # The UTC ISO 8601 Date Time to filter statements TO NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (nullable, format: date-time)
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Statement: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromStatementDateTime" $from_statement_date_time "scalar") (serialize-qp "toStatementDateTime" $to_statement_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}/statements") $qp)
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Statements
#
# GET /accounts/{accountId}/statements/{statementId}
export def "accounts-statements get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Statement: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id, statement_id: $statement_id} | format pattern "/accounts/{account_id}/statements/{statement_id}"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Statements
#
# GET /accounts/{accountId}/statements/{statementId}/file
export def "accounts-statements-file get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id, statement_id: $statement_id} | format pattern "/accounts/{account_id}/statements/{statement_id}/file"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Transactions
#
# GET /accounts/{accountId}/statements/{statementId}/transactions
export def "accounts-statements-transactions get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Transaction: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id, statement_id: $statement_id} | format pattern "/accounts/{account_id}/statements/{statement_id}/transactions"))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Transactions
#
# GET /accounts/{accountId}/transactions
export def "accounts-transactions get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from-booking-date-time: string # The UTC ISO 8601 Date Time to filter transactions FROM NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (nullable, format: date-time)
  --to-booking-date-time: string # The UTC ISO 8601 Date Time to filter transactions TO NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (nullable, format: date-time)
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Transaction: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromBookingDateTime" $from_booking_date_time "scalar") (serialize-qp "toBookingDateTime" $to_booking_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}/transactions") $qp)
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Party
#
# GET /party
export def "party get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Party: record<Name: string, PartyId: string>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/party")
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Sandbox
#
# POST /sandbox
export def "sandbox post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  sandbox_id: string # Sandbox Id
]: any -> record<sandboxId: string, users: table<accounts: list, cards: list, retryCacheEntries: list, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox")
  let body = {"sandboxId": $sandbox_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Import Sandbox
#
# PUT /sandbox
# --users item shape: {accounts?: list, cards?: list, retryCacheEntries?: list, userId?: string}
export def "sandbox put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sandbox_id: string # Sandbox id
  --users: list # List of users (nullable) — item shape: {accounts?: list, cards?: list, retryCacheEntries?: list, userId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox")
  let body = {"sandboxId": $sandbox_id, "users": $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Sandbox
#
# DELETE /sandbox/{sandboxId}
export def "sandbox delete" [
  sandbox_id: string
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
  let full_url = (build-url $base ({sandbox_id: $sandbox_id} | format pattern "/sandbox/{sandbox_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export Sandbox
#
# GET /sandbox/{sandboxId}
export def "sandbox get" [
  sandbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<sandboxId: string, users: table<accounts: list, cards: list, retryCacheEntries: list, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sandbox_id: $sandbox_id} | format pattern "/sandbox/{sandbox_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
