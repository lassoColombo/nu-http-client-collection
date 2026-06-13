# Auto-generated client for Management API v1
# Source: https://api.apis.guru/v2/specs/adyen.com/ManagementService/1/openapi.json
# Auth: --token flag or $env.MANAGEMENT_API_TOKEN

const BASE_URL = "https://management-test.adyen.com/v1"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MANAGEMENT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://management-test.adyen.com/v1"] }
def auth-scheme-completer [] { ["x-api-key" "basic"] }

# Completers for enum parameters
def communicationFormat-completer [] { ["http" "json" "soap"] }
def filterMerchantAccountType-completer [] { ["allAccounts" "excludeAccounts" "includeAccounts"] }
def networkType-completer [] { ["LOCAL" "PUBLIC"] }
def sslVersion-completer [] { ["HTTP" "SSL" "SSLv3" "TLS" "TLSv1" "TLSv1.1" "TLSv1.2" "TLSv1.3"] }
def shopperInteraction-completer [] { ["contAuth" "eCommerce" "moto" "pos"] }
def type-completer [] { ["afterpaytouch" "alipay" "alipay_hk" "amex" "applepay" "bcmc" "blik" "cartebancaire" "clearpay" "cup" "diners" "directEbanking" "directdebit_GB" "discover" "ebanking_FI" "eftpos_australia" "elo" "elocredit" "elodebit" "girocard" "giropay" "googlepay" "hiper" "hipercard" "ideal" "interac_card" "jcb" "klarna" "klarna_account" "klarna_paynow" "maestro" "mbway" "mc" "mcdebit" "mealVoucher_FR" "mobilepay" "multibanco" "onlineBanking_PL" "paypal" "payshop" "swish" "trustly" "vipps" "visa" "visadebit" "vpay" "wechatpay" "wechatpay_pos"] }
def status-completer [] { ["active" "closed" "inactive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "companies get-companies" } } | get name | first)
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

# Get a list of company accounts
#
# GET /companies
# operationId: get-companies
export def "companies get-companies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, dataCenters: list, description: string, id: string, name: string, reference: string, status: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/companies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a company account
#
# GET /companies/{companyId}
# operationId: get-companies-companyId
export def "companies get-companies-companyId" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<apiCredentials: record<href: string>, self: record<href: string>, users: record<href: string>, webhooks: record<href: string>>, dataCenters: table<livePrefix: string, name: string>, description: string, id: string, name: string, reference: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of Android apps
#
# GET /companies/{companyId}/androidApps
# operationId: get-companies-companyId-androidApps
export def "companies-android-apps get-companies-companyId-androidApps" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 20 items on a page. (format: int32)
]: nothing -> record<data: table<description: string, id: string, label: string, packageName: string, status: string, versionCode: int, versionName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/androidApps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of Android certificates
#
# GET /companies/{companyId}/androidCertificates
# operationId: get-companies-companyId-androidCertificates
export def "companies-android-certificates get-companies-companyId-androidCertificates" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 20 items on a page. (format: int32)
]: nothing -> record<data: table<description: string, extension: string, id: string, name: string, notAfter: string, notBefore: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/androidCertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of API credentials
#
# GET /companies/{companyId}/apiCredentials
# operationId: get-companies-companyId-apiCredentials
export def "companies-api-credentials get-companies-companyId-apiCredentials" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, active: bool, allowedIpAddresses: list, allowedOrigins: list, associatedMerchantAccounts: list, clientKey: string, description: string, id: string, roles: list, username: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an API credential.
#
# POST /companies/{companyId}/apiCredentials
# operationId: post-companies-companyId-apiCredentials
export def "companies-api-credentials post-companies-companyId-apiCredentials" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedOrigins: list # List of [allowed origins](https://docs.adyen.com/development-resources/client-side-authentication#allowed-origins) for the new API credential.
  --associatedMerchantAccounts: list # List of merchant accounts that the API credential has access to.
  --description: string # Description of the API credential.
  --roles: list # List of [roles](https://docs.adyen.com/development-resources/api-credentials#roles-1) of the API credential.
]: any -> record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, apiKey: string, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, password: string, roles: list<string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials")
  let body = {allowedOrigins: $allowedOrigins, associatedMerchantAccounts: $associatedMerchantAccounts, description: $description, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an API credential
#
# GET /companies/{companyId}/apiCredentials/{apiCredentialId}
# operationId: get-companies-companyId-apiCredentials-apiCredentialId
export def "companies-api-credentials get-companies-companyId-apiCredentials-apiCredentialId" [
  companyId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, roles: list<string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials/($apiCredentialId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an API credential.
#
# PATCH /companies/{companyId}/apiCredentials/{apiCredentialId}
# operationId: patch-companies-companyId-apiCredentials-apiCredentialId
export def "companies-api-credentials patch-companies-companyId-apiCredentials-apiCredentialId" [
  companyId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Indicates if the API credential is enabled.
  --allowedOrigins: list # The new list of [allowed origins](https://docs.adyen.com/development-resources/client-side-authentication#allowed-origins) for the API credential.
  --associatedMerchantAccounts: list # List of merchant accounts that the API credential has access to.
  --description: string # Description of the API credential.
  --roles: list # List of [roles](https://docs.adyen.com/development-resources/api-credentials#roles-1) of the API credential.
]: any -> record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, description: string, id: string, roles: list<string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials/($apiCredentialId)")
  let body = {active: $active, allowedOrigins: $allowedOrigins, associatedMerchantAccounts: $associatedMerchantAccounts, description: $description, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of allowed origins
#
# GET /companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins
# operationId: get-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins
export def "companies-api-credentials-allowed-origins get-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins" [
  companyId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<_links: record, domain: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials/($apiCredentialId)/allowedOrigins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an allowed origin
#
# POST /companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins
# operationId: post-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins
# --_links shape: {self: record}
export def "companies-api-credentials-allowed-origins post-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins" [
  companyId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {self: record}
  domain: string # Domain of the allowed origin.
  --id: string # Unique identifier of the allowed origin.
]: any -> record<data: table<_links: record, domain: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials/($apiCredentialId)/allowedOrigins")
  let body = {_links: $links, domain: $domain, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an allowed origin
#
# DELETE /companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}
# operationId: delete-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins-originId
export def "companies-api-credentials-allowed-origins delete-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins-originId" [
  companyId: string
  apiCredentialId: string
  originId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials/($apiCredentialId)/allowedOrigins/($originId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an allowed origin
#
# GET /companies/{companyId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}
# operationId: get-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins-originId
export def "companies-api-credentials-allowed-origins get-companies-companyId-apiCredentials-apiCredentialId-allowedOrigins-originId" [
  companyId: string
  apiCredentialId: string
  originId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, domain: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials/($apiCredentialId)/allowedOrigins/($originId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate new API key
#
# POST /companies/{companyId}/apiCredentials/{apiCredentialId}/generateApiKey
# operationId: post-companies-companyId-apiCredentials-apiCredentialId-generateApiKey
export def "companies-api-credentials-generate-api-key post-companies-companyId-apiCredentials-apiCredentialId-generateApiKey" [
  companyId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials/($apiCredentialId)/generateApiKey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate new client key
#
# POST /companies/{companyId}/apiCredentials/{apiCredentialId}/generateClientKey
# operationId: post-companies-companyId-apiCredentials-apiCredentialId-generateClientKey
export def "companies-api-credentials-generate-client-key post-companies-companyId-apiCredentials-apiCredentialId-generateClientKey" [
  companyId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/apiCredentials/($apiCredentialId)/generateClientKey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of billing entities
#
# GET /companies/{companyId}/billingEntities
# operationId: get-companies-companyId-billingEntities
export def "companies-billing-entities get-companies-companyId-billingEntities" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the billing entity.
]: nothing -> record<data: table<address: record, email: string, id: string, name: string, taxId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/billingEntities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of merchant accounts
#
# GET /companies/{companyId}/merchants
# operationId: get-companies-companyId-merchants
export def "companies-merchants get-companies-companyId-merchants" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, captureDelay: string, companyId: string, dataCenters: list, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/merchants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of shipping locations
#
# GET /companies/{companyId}/shippingLocations
# operationId: get-companies-companyId-shippingLocations
export def "companies-shipping-locations get-companies-companyId-shippingLocations" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the shipping location.
  --offset: int # The number of locations to skip. (format: int32)
  --limit: int # The number of locations to return. (format: int32)
]: nothing -> record<data: table<address: record, contact: record, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/shippingLocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a shipping location
#
# POST /companies/{companyId}/shippingLocations
# operationId: post-companies-companyId-shippingLocations
# --address shape: {city?: string, companyName?: string, country?: string, postalCode?: string, stateOrProvince?: string, streetAddress?: string, streetAddress2?: string}
# --contact shape: {email?: string, firstName?: string, infix?: string, lastName?: string, phoneNumber?: string}
export def "companies-shipping-locations post-companies-companyId-shippingLocations" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {city?: string, companyName?: string, country?: string, postalCode?: string, stateOrProvince?: string, streetAddress?: string, streetAddress2?: string}
  --contact: record # shape: {email?: string, firstName?: string, infix?: string, lastName?: string, phoneNumber?: string}
  --id: string # The unique identifier of the shipping location, for use as `shippingLocationId` when creating an order.
  --name: string # The unique name of the shipping location.
]: any -> record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/shippingLocations")
  let body = {address: $address, contact: $contact, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of terminal actions
#
# GET /companies/{companyId}/terminalActions
# operationId: get-companies-companyId-terminalActions
export def "companies-terminal-actions get-companies-companyId-terminalActions" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 20 items on a page. (format: int32)
  --status: string # Returns terminal actions with the specified status.  Allowed values: **pending**, **successful**, **failed**, **cancelled**, **tryLater**.
  --type: string # Returns terminal actions of the specified type.  Allowed values: **InstallAndroidApp**, **UninstallAndroidApp**, **InstallAndroidCertificate**, **UninstallAndroidCertificate**.
]: nothing -> record<data: table<actionType: string, config: string, confirmedAt: string, id: string, result: string, scheduledAt: string, status: string, terminalId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/terminalActions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get terminal action
#
# GET /companies/{companyId}/terminalActions/{actionId}
# operationId: get-companies-companyId-terminalActions-actionId
export def "companies-terminal-actions get-companies-companyId-terminalActions-actionId" [
  companyId: string
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actionType: string, config: string, confirmedAt: string, id: string, result: string, scheduledAt: string, status: string, terminalId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/terminalActions/($actionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the terminal logo
#
# GET /companies/{companyId}/terminalLogos
# operationId: get-companies-companyId-terminalLogos
export def "companies-terminal-logos get-companies-companyId-terminalLogos" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T.
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/terminalLogos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the terminal logo
#
# PATCH /companies/{companyId}/terminalLogos
# operationId: patch-companies-companyId-terminalLogos
export def "companies-terminal-logos patch-companies-companyId-terminalLogos" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T.
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> record<data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/terminalLogos" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of terminal models
#
# GET /companies/{companyId}/terminalModels
# operationId: get-companies-companyId-terminalModels
export def "companies-terminal-models get-companies-companyId-terminalModels" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/terminalModels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of orders
#
# GET /companies/{companyId}/terminalOrders
# operationId: get-companies-companyId-terminalOrders
export def "companies-terminal-orders get-companies-companyId-terminalOrders" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customerOrderReference: string # Your purchase order number.
  --status: string # The order status. Possible values (not case-sensitive): Placed, Confirmed, Cancelled, Shipped, Delivered.
  --offset: int # The number of orders to skip. (format: int32)
  --limit: int # The number of orders to return. (format: int32)
]: nothing -> record<data: table<billingEntity: record, customerOrderReference: string, id: string, items: list, orderDate: string, shippingLocation: record, status: string, trackingUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customerOrderReference" $customerOrderReference "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/terminalOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an order
#
# POST /companies/{companyId}/terminalOrders
# operationId: post-companies-companyId-terminalOrders
# --items item shape: {id?: string, installments?: int, name?: string, quantity?: int}
export def "companies-terminal-orders post-companies-companyId-terminalOrders" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billingEntityId: string # The identification of the billing entity to use for the order.
  --customerOrderReference: string # The merchant-defined purchase order reference.
  --items: list # The products included in the order. — item shape: {id?: string, installments?: int, name?: string, quantity?: int}
  --shippingLocationId: string # The identification of the shipping location to use for the order.
  --taxId: string # The tax number of the billing entity.
]: any -> record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/terminalOrders")
  let body = {billingEntityId: $billingEntityId, customerOrderReference: $customerOrderReference, items: $items, shippingLocationId: $shippingLocationId, taxId: $taxId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an order
#
# GET /companies/{companyId}/terminalOrders/{orderId}
# operationId: get-companies-companyId-terminalOrders-orderId
export def "companies-terminal-orders get-companies-companyId-terminalOrders-orderId" [
  companyId: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/terminalOrders/($orderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an order
#
# PATCH /companies/{companyId}/terminalOrders/{orderId}
# operationId: patch-companies-companyId-terminalOrders-orderId
# --items item shape: {id?: string, installments?: int, name?: string, quantity?: int}
export def "companies-terminal-orders patch-companies-companyId-terminalOrders-orderId" [
  companyId: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billingEntityId: string # The identification of the billing entity to use for the order.
  --customerOrderReference: string # The merchant-defined purchase order reference.
  --items: list # The products included in the order. — item shape: {id?: string, installments?: int, name?: string, quantity?: int}
  --shippingLocationId: string # The identification of the shipping location to use for the order.
  --taxId: string # The tax number of the billing entity.
]: any -> record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/terminalOrders/($orderId)")
  let body = {billingEntityId: $billingEntityId, customerOrderReference: $customerOrderReference, items: $items, shippingLocationId: $shippingLocationId, taxId: $taxId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel an order
#
# POST /companies/{companyId}/terminalOrders/{orderId}/cancel
# operationId: post-companies-companyId-terminalOrders-orderId-cancel
export def "companies-terminal-orders-cancel post-companies-companyId-terminalOrders-orderId-cancel" [
  companyId: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/terminalOrders/($orderId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of terminal products
#
# GET /companies/{companyId}/terminalProducts
# operationId: get-companies-companyId-terminalProducts
export def "companies-terminal-products get-companies-companyId-terminalProducts" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # The country to return products for, in [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) format. For example, **US**
  --terminalModelId: string # The terminal model to return products for. Use the ID returned in the [GET `/terminalModels`](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/companies/{companyId}/terminalModels) response. For example, **Verifone.M400**
  --offset: int # The number of products to skip. (format: int32)
  --limit: int # The number of products to return. (format: int32)
]: nothing -> record<data: table<description: string, id: string, itemsIncluded: list, name: string, price: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "terminalModelId" $terminalModelId "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/terminalProducts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get terminal settings
#
# GET /companies/{companyId}/terminalSettings
# operationId: get-companies-companyId-terminalSettings
export def "companies-terminal-settings get-companies-companyId-terminalSettings" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/terminalSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update terminal settings
#
# PATCH /companies/{companyId}/terminalSettings
# operationId: patch-companies-companyId-terminalSettings
# --cardholderReceipt shape: {headerForAuthorizedReceipt?: string}
# --connectivity shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
# --gratuities item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
# --hardware shape: {displayMaximumBackLight?: int}
# --nexo shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
# --offlineProcessing shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
# --opi shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
# --passcodes shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
# --payAtTable shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
# --payment shape: {hideMinorUnitsInCurrencies?: list}
# --receiptOptions shape: {logo?: string, qrCodeData?: string}
# --receiptPrinting shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
# --signature shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
# --standalone shape: {currencyCode?: string, enableStandalone?: bool}
# --surcharge shape: {askConfirmation?: bool, configurations?: list}
# --timeouts shape: {fromActiveToSleep?: int}
# --wifiProfiles shape: {profiles?: list, settings?: record}
export def "companies-terminal-settings patch-companies-companyId-terminalSettings" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholderReceipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
  --offlineProcessing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --payAtTable: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list}
  --receiptOptions: record # shape: {logo?: string, qrCodeData?: string}
  --receiptPrinting: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifiProfiles: record # shape: {profiles?: list, settings?: record}
]: any -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/terminalSettings")
  let body = {cardholderReceipt: $cardholderReceipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offlineProcessing: $offlineProcessing, opi: $opi, passcodes: $passcodes, payAtTable: $payAtTable, payment: $payment, receiptOptions: $receiptOptions, receiptPrinting: $receiptPrinting, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifiProfiles: $wifiProfiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of users
#
# GET /companies/{companyId}/users
# operationId: get-companies-companyId-users
export def "companies-users get-companies-companyId-users" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to return. (format: int32)
  --pageSize: int # The number of items to have on a page. Maximum value is **100**. The default is **10** items on a page. (format: int32)
  --username: string # The partial or complete username to select all users that match.
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, accountGroups: list, active: bool, associatedMerchantAccounts: list, authnApps: list, email: string, id: string, name: record, roles: list, timeZoneCode: string, username: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /companies/{companyId}/users
# operationId: post-companies-companyId-users
# --name shape: {firstName: string, lastName: string}
export def "companies-users post-companies-companyId-users" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountGroups: list # The list of [account groups](https://docs.adyen.com/account/account-structure#account-groups) associated with this user.
  --associatedMerchantAccounts: list # The list of [merchant accounts](https://docs.adyen.com/account/account-structure#merchant-accounts) associated with this user.
  --authnApps: list # Set of authn apps to add to this user
  email: string # The email address of the user.
  name: record # shape: {firstName: string, lastName: string}
  --roles: list # The list of [roles](https://docs.adyen.com/account/user-roles) for this user.
  --timeZoneCode: string # The [tz database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the time zone of the user. For example, **Europe/Amsterdam**.
  username: string # The username for this user. Allowed length: 255 alphanumeric characters.
]: any -> record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/users")
  let body = {accountGroups: $accountGroups, associatedMerchantAccounts: $associatedMerchantAccounts, authnApps: $authnApps, email: $email, name: $name, roles: $roles, timeZoneCode: $timeZoneCode, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get user details
#
# GET /companies/{companyId}/users/{userId}
# operationId: get-companies-companyId-users-userId
export def "companies-users get-companies-companyId-users-userId" [
  companyId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user details
#
# PATCH /companies/{companyId}/users/{userId}
# operationId: patch-companies-companyId-users-userId
# --name shape: {firstName?: string, lastName?: string}
export def "companies-users patch-companies-companyId-users-userId" [
  companyId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountGroups: list # The list of [account groups](https://docs.adyen.com/account/account-structure#account-groups) associated with this user.
  --active: oneof<nothing, bool> # Indicates whether this user is active.
  --associatedMerchantAccounts: list # The list of [merchant accounts](https://docs.adyen.com/account/account-structure#merchant-accounts) to associate the user with.
  --authnAppsToAdd: list # Set of authn apps to add to this user
  --authnAppsToRemove: list # Set of authn apps to remove from this user
  --email: string # The email address of the user.
  --name: record # shape: {firstName?: string, lastName?: string}
  --roles: list # The list of [roles](https://docs.adyen.com/account/user-roles) for this user.
  --timeZoneCode: string # The [tz database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the time zone of the user. For example, **Europe/Amsterdam**.
]: any -> record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, associatedMerchantAccounts: list<string>, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/users/($userId)")
  let body = {accountGroups: $accountGroups, active: $active, associatedMerchantAccounts: $associatedMerchantAccounts, authnAppsToAdd: $authnAppsToAdd, authnAppsToRemove: $authnAppsToRemove, email: $email, name: $name, roles: $roles, timeZoneCode: $timeZoneCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all webhooks
#
# GET /companies/{companyId}/webhooks
# operationId: get-companies-companyId-webhooks
export def "companies-webhooks get-companies-companyId-webhooks" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, accountReference: string, data: table<_links: record, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set up a webhook
#
# POST /companies/{companyId}/webhooks
# operationId: post-companies-companyId-webhooks
# --additionalSettings shape: {includeEventCodes?: list, properties?: record}
export def "companies-webhooks post-companies-companyId-webhooks" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acceptsExpiredCertificate: oneof<nothing, bool> # Indicates if expired SSL certificates are accepted. Default value: **false**.
  --acceptsSelfSignedCertificate: oneof<nothing, bool> # Indicates if self-signed SSL certificates are accepted. Default value: **false**.
  --acceptsUntrustedRootCertificate: oneof<nothing, bool> # Indicates if untrusted SSL certificates are accepted. Default value: **false**.
  --active: oneof<nothing, bool> # Indicates if the webhook configuration is active. The field must be **true** for us to send webhooks about events related an account.
  --additionalSettings: record # shape: {includeEventCodes?: list, properties?: record}
  communicationFormat: string@communicationFormat-completer # Format or protocol for receiving webhooks. Possible values: * **soap** * **http** * **json** 
  --description: string # Your description for this webhook configuration.
  filterMerchantAccountType: string@filterMerchantAccountType-completer # Shows how merchant accounts are filtered when configuring the webhook. Possible values: * **includeAccounts**: The webhook is configured for the merchant accounts listed in `filterMerchantAccounts`. * **excludeAccounts**: The webhook is not configured for the merchant accounts listed in `filterMerchantAccounts`. * **allAccounts**: Includes all merchant accounts, and does not require specifying `filterMerchantAccounts`.
  filterMerchantAccounts: list # A list of merchant account names that are included or excluded from receiving the webhook. Inclusion or exclusion is based on the value defined for `filterMerchantAccountType`.  Required if `filterMerchantAccountType` is either: * **includeAccounts** * **excludeAccounts**  Not needed for `filterMerchantAccountType`: **allAccounts**.
  --networkType: string@networkType-completer # Network type for Terminal API notification webhooks. Possible values: * **public** * **local**  Default Value: **public**.
  --password: string # Password to access the webhook URL.
  --populateSoapActionHeader: oneof<nothing, bool> # Indicates if the SOAP action header needs to be populated. Default value: **false**.  Only applies if `communicationFormat`: **soap**.
  --sslVersion: string@sslVersion-completer # SSL version to access the public webhook URL specified in the `url` field. Possible values: * **TLSv1.3** * **TLSv1.2** * **HTTP** - Only allowed on Test environment.  If not specified, the webhook will use `sslVersion`: **TLSv1.2**.
  type: string # The type of webhook that is being created. Possible values are:  - **standard** - **account-settings-notification** - **banktransfer-notification** - **boletobancario-notification** - **directdebit-notification** - **pending-notification** - **ideal-notification** - **ideal-pending-notification** - **report-notification** - **rreq-notification**  Find out more about [standard notification webhooks](https://docs.adyen.com/development-resources/webhooks/understand-notifications#event-codes) and [other types of notifications](https://docs.adyen.com/development-resources/webhooks/understand-notifications#other-notifications).
  --body-url: string # Public URL where webhooks will be sent, for example **https://www.domain.com/webhook-endpoint**.
  --username: string # Username to access the webhook URL.
]: any -> record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/webhooks")
  let body = {acceptsExpiredCertificate: $acceptsExpiredCertificate, acceptsSelfSignedCertificate: $acceptsSelfSignedCertificate, acceptsUntrustedRootCertificate: $acceptsUntrustedRootCertificate, active: $active, additionalSettings: $additionalSettings, communicationFormat: $communicationFormat, description: $description, filterMerchantAccountType: $filterMerchantAccountType, filterMerchantAccounts: $filterMerchantAccounts, networkType: $networkType, password: $password, populateSoapActionHeader: $populateSoapActionHeader, sslVersion: $sslVersion, type: $type, url: $body_url, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a webhook
#
# DELETE /companies/{companyId}/webhooks/{webhookId}
# operationId: delete-companies-companyId-webhooks-webhookId
export def "companies-webhooks delete-companies-companyId-webhooks-webhookId" [
  companyId: string
  webhookId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a webhook
#
# GET /companies/{companyId}/webhooks/{webhookId}
# operationId: get-companies-companyId-webhooks-webhookId
export def "companies-webhooks get-companies-companyId-webhooks-webhookId" [
  companyId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /companies/{companyId}/webhooks/{webhookId}
# operationId: patch-companies-companyId-webhooks-webhookId
# --additionalSettings shape: {includeEventCodes?: list, properties?: record}
export def "companies-webhooks patch-companies-companyId-webhooks-webhookId" [
  companyId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acceptsExpiredCertificate: oneof<nothing, bool> # Indicates if expired SSL certificates are accepted. Default value: **false**.
  --acceptsSelfSignedCertificate: oneof<nothing, bool> # Indicates if self-signed SSL certificates are accepted. Default value: **false**.
  --acceptsUntrustedRootCertificate: oneof<nothing, bool> # Indicates if untrusted SSL certificates are accepted. Default value: **false**.
  --active: oneof<nothing, bool> # Indicates if the webhook configuration is active. The field must be **true** for us to send webhooks about events related an account.
  --additionalSettings: record # shape: {includeEventCodes?: list, properties?: record}
  --communicationFormat: string@communicationFormat-completer # Format or protocol for receiving webhooks. Possible values: * **soap** * **http** * **json** 
  --description: string # Your description for this webhook configuration.
  --filterMerchantAccountType: string@filterMerchantAccountType-completer # Shows how merchant accounts are filtered when configuring the webhook. Possible values: * **includeAccounts**: The webhook is configured for the merchant accounts listed in `filterMerchantAccounts`. * **excludeAccounts**: The webhook is not configured for the merchant accounts listed in `filterMerchantAccounts`. * **allAccounts**: Includes all merchant accounts, and does not require specifying `filterMerchantAccounts`.
  --filterMerchantAccounts: list # A list of merchant account names that are included or excluded from receiving the webhook. Inclusion or exclusion is based on the value defined for `filterMerchantAccountType`.  Required if `filterMerchantAccountType` is either: * **includeAccounts** * **excludeAccounts**  Not needed for `filterMerchantAccountType`: **allAccounts**.
  --networkType: string@networkType-completer # Network type for Terminal API notification webhooks. Possible values: * **public** * **local**  Default Value: **public**.
  --password: string # Password to access the webhook URL.
  --populateSoapActionHeader: oneof<nothing, bool> # Indicates if the SOAP action header needs to be populated. Default value: **false**.  Only applies if `communicationFormat`: **soap**.
  --sslVersion: string@sslVersion-completer # SSL version to access the public webhook URL specified in the `url` field. Possible values: * **TLSv1.3** * **TLSv1.2** * **HTTP** - Only allowed on Test environment.  If not specified, the webhook will use `sslVersion`: **TLSv1.2**.
  --body-url: string # Public URL where webhooks will be sent, for example **https://www.domain.com/webhook-endpoint**.
  --username: string # Username to access the webhook URL.
]: any -> record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/webhooks/($webhookId)")
  let body = {acceptsExpiredCertificate: $acceptsExpiredCertificate, acceptsSelfSignedCertificate: $acceptsSelfSignedCertificate, acceptsUntrustedRootCertificate: $acceptsUntrustedRootCertificate, active: $active, additionalSettings: $additionalSettings, communicationFormat: $communicationFormat, description: $description, filterMerchantAccountType: $filterMerchantAccountType, filterMerchantAccounts: $filterMerchantAccounts, networkType: $networkType, password: $password, populateSoapActionHeader: $populateSoapActionHeader, sslVersion: $sslVersion, url: $body_url, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate an HMAC key
#
# POST /companies/{companyId}/webhooks/{webhookId}/generateHmac
# operationId: post-companies-companyId-webhooks-webhookId-generateHmac
export def "companies-webhooks-generate-hmac post-companies-companyId-webhooks-webhookId-generateHmac" [
  companyId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hmacKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/webhooks/($webhookId)/generateHmac")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test a webhook
#
# POST /companies/{companyId}/webhooks/{webhookId}/test
# operationId: post-companies-companyId-webhooks-webhookId-test
# --notification shape: {amount?: record, eventCode?: string, eventDate?: string, merchantReference?: string, paymentMethod?: string, reason?: string, success?: bool}
export def "companies-webhooks-test post-companies-companyId-webhooks-webhookId-test" [
  companyId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --merchantIds: list # List of `merchantId` values for which test webhooks will be sent. The list can have a maximum of 20 `merchantId` values.  If not specified, we send sample notifications to all the merchant accounts that the webhook is configured for. If this is more than 20 merchant accounts, use this list to specify a subset of the merchant accounts for which to send test notifications.
  --notification: record # shape: {amount?: record, eventCode?: string, eventDate?: string, merchantReference?: string, paymentMethod?: string, reason?: string, success?: bool}
  --types: list # List of event codes for which to send test notifications. Only the webhook types below are supported.   Possible values if webhook `type`: **standard**:  * **AUTHORISATION** * **CHARGEBACK_REVERSED** * **ORDER_CLOSED** * **ORDER_OPENED** * **PAIDOUT_REVERSED** * **PAYOUT_THIRDPARTY** * **REFUNDED_REVERSED** * **REFUND_WITH_DATA** * **REPORT_AVAILABLE** * **CUSTOM** - set your custom notification fields in the [`notification`](https://docs.adyen.com/api-explorer/#/ManagementService/v1/post/companies/{companyId}/webhooks/{webhookId}/test__reqParam_notification) object.  Possible values if webhook `type`: **banktransfer-notification**:  * **PENDING**  Possible values if webhook `type`: **report-notification**:  * **REPORT_AVAILABLE**  Possible values if webhook `type`: **ideal-notification**:  * **AUTHORISATION**  Possible values if webhook `type`: **pending-notification**:  * **PENDING**
]: any -> record<data: table<merchantId: string, output: string, requestSent: string, responseCode: string, responseTime: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/webhooks/($webhookId)/test")
  let body = {merchantIds: $merchantIds, notification: $notification, types: $types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get API credential details
#
# GET /me
# operationId: get-me
export def "me get-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, associatedMerchantAccounts: list<string>, clientKey: string, companyName: string, description: string, id: string, roles: list<string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get allowed origins
#
# GET /me/allowedOrigins
# operationId: get-me-allowedOrigins
export def "me-allowed-origins get-me-allowedOrigins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<_links: record, domain: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/allowedOrigins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add allowed origin
#
# POST /me/allowedOrigins
# operationId: post-me-allowedOrigins
# --_links shape: {self: record}
export def "me-allowed-origins post-me-allowedOrigins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {self: record}
  domain: string # Domain of the allowed origin.
  --id: string # Unique identifier of the allowed origin.
]: any -> record<_links: record<self: record<href: string>>, domain: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/allowedOrigins")
  let body = {_links: $links, domain: $domain, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove allowed origin
#
# DELETE /me/allowedOrigins/{originId}
# operationId: delete-me-allowedOrigins-originId
export def "me-allowed-origins delete-me-allowedOrigins-originId" [
  originId: string
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
  let full_url = (build-url $base $"/me/allowedOrigins/($originId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get allowed origin details
#
# GET /me/allowedOrigins/{originId}
# operationId: get-me-allowedOrigins-originId
export def "me-allowed-origins get-me-allowedOrigins-originId" [
  originId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, domain: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/allowedOrigins/($originId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of merchant accounts
#
# GET /merchants
# operationId: get-merchants
export def "merchants get-merchants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, captureDelay: string, companyId: string, dataCenters: list, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/merchants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a merchant account
#
# POST /merchants
# operationId: post-merchants
export def "merchants post-merchants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --businessLineId: string # The unique identifier of the [business line](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businessLines). Required for an Adyen for Platforms Manage integration.
  companyId: string # The unique identifier of the company account.
  --description: string # Your description for the merchant account, maximum 300 characters.
  --legalEntityId: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities). Required for an Adyen for Platforms Manage integration.
  --pricingPlan: string # Sets the pricing plan for the merchant account. Required for an Adyen for Platforms Manage integration. Your Adyen contact will provide the values that you can use.
  --reference: string # Your reference for the merchant account. To make this reference the unique identifier of the merchant account, your Adyen contact can set up a template on your company account. The template can have 6 to 255 characters with upper- and lower-case letters, underscores, and numbers. When your company account has a template, then the `reference` is required and must be unique within the company account.
  --salesChannels: list # List of sales channels that the merchant will process payments with
]: any -> record<businessLineId: string, companyId: string, description: string, id: string, legalEntityId: string, pricingPlan: string, reference: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/merchants")
  let body = {businessLineId: $businessLineId, companyId: $companyId, description: $description, legalEntityId: $legalEntityId, pricingPlan: $pricingPlan, reference: $reference, salesChannels: $salesChannels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a merchant account
#
# GET /merchants/{merchantId}
# operationId: get-merchants-merchantId
export def "merchants get-merchants-merchantId" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<apiCredentials: record<href: string>, self: record<href: string>, users: record<href: string>, webhooks: record<href: string>>, captureDelay: string, companyId: string, dataCenters: table<livePrefix: string, name: string>, defaultShopperInteraction: string, description: string, id: string, merchantCity: string, name: string, pricingPlan: string, primarySettlementCurrency: string, reference: string, shopWebAddress: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request to activate a merchant account
#
# POST /merchants/{merchantId}/activate
# operationId: post-merchants-merchantId-activate
export def "merchants-activate post-merchants-merchantId-activate" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<companyId: string, merchantId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of API credentials
#
# GET /merchants/{merchantId}/apiCredentials
# operationId: get-merchants-merchantId-apiCredentials
export def "merchants-api-credentials get-merchants-merchantId-apiCredentials" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, active: bool, allowedIpAddresses: list, allowedOrigins: list, clientKey: string, description: string, id: string, roles: list, username: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an API credential
#
# POST /merchants/{merchantId}/apiCredentials
# operationId: post-merchants-merchantId-apiCredentials
export def "merchants-api-credentials post-merchants-merchantId-apiCredentials" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedOrigins: list # The list of [allowed origins](https://docs.adyen.com/development-resources/client-side-authentication#allowed-origins) for the new API credential.
  --description: string # Description of the API credential.
  --roles: list # List of [roles](https://docs.adyen.com/development-resources/api-credentials#roles-1) for the API credential.
]: any -> record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, apiKey: string, clientKey: string, description: string, id: string, password: string, roles: list<string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials")
  let body = {allowedOrigins: $allowedOrigins, description: $description, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an API credential
#
# GET /merchants/{merchantId}/apiCredentials/{apiCredentialId}
# operationId: get-merchants-merchantId-apiCredentials-apiCredentialId
export def "merchants-api-credentials get-merchants-merchantId-apiCredentials-apiCredentialId" [
  merchantId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, clientKey: string, description: string, id: string, roles: list<string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials/($apiCredentialId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an API credential
#
# PATCH /merchants/{merchantId}/apiCredentials/{apiCredentialId}
# operationId: patch-merchants-merchantId-apiCredentials-apiCredentialId
export def "merchants-api-credentials patch-merchants-merchantId-apiCredentials-apiCredentialId" [
  merchantId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Indicates if the API credential is enabled.
  --allowedOrigins: list # The new list of [allowed origins](https://docs.adyen.com/development-resources/client-side-authentication#allowed-origins) for the API credential.
  --description: string # Description of the API credential.
  --roles: list # List of [roles](https://docs.adyen.com/development-resources/api-credentials#roles-1) for the API credential.
]: any -> record<_links: record<allowedOrigins: record<href: string>, company: record<href: string>, generateApiKey: record<href: string>, generateClientKey: record<href: string>, merchant: record<href: string>, self: record<href: string>>, active: bool, allowedIpAddresses: list<string>, allowedOrigins: table<_links: record, domain: string, id: string>, clientKey: string, description: string, id: string, roles: list<string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials/($apiCredentialId)")
  let body = {active: $active, allowedOrigins: $allowedOrigins, description: $description, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of allowed origins
#
# GET /merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins
# operationId: get-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins
export def "merchants-api-credentials-allowed-origins get-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins" [
  merchantId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<_links: record, domain: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials/($apiCredentialId)/allowedOrigins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an allowed origin
#
# POST /merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins
# operationId: post-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins
# --_links shape: {self: record}
export def "merchants-api-credentials-allowed-origins post-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins" [
  merchantId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {self: record}
  domain: string # Domain of the allowed origin.
  --id: string # Unique identifier of the allowed origin.
]: any -> record<data: table<_links: record, domain: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials/($apiCredentialId)/allowedOrigins")
  let body = {_links: $links, domain: $domain, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an allowed origin
#
# DELETE /merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}
# operationId: delete-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins-originId
export def "merchants-api-credentials-allowed-origins delete-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins-originId" [
  merchantId: string
  apiCredentialId: string
  originId: string
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
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials/($apiCredentialId)/allowedOrigins/($originId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an allowed origin
#
# GET /merchants/{merchantId}/apiCredentials/{apiCredentialId}/allowedOrigins/{originId}
# operationId: get-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins-originId
export def "merchants-api-credentials-allowed-origins get-merchants-merchantId-apiCredentials-apiCredentialId-allowedOrigins-originId" [
  merchantId: string
  apiCredentialId: string
  originId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, domain: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials/($apiCredentialId)/allowedOrigins/($originId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate new API key
#
# POST /merchants/{merchantId}/apiCredentials/{apiCredentialId}/generateApiKey
# operationId: post-merchants-merchantId-apiCredentials-apiCredentialId-generateApiKey
export def "merchants-api-credentials-generate-api-key post-merchants-merchantId-apiCredentials-apiCredentialId-generateApiKey" [
  merchantId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials/($apiCredentialId)/generateApiKey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate new client key
#
# POST /merchants/{merchantId}/apiCredentials/{apiCredentialId}/generateClientKey
# operationId: post-merchants-merchantId-apiCredentials-apiCredentialId-generateClientKey
export def "merchants-api-credentials-generate-client-key post-merchants-merchantId-apiCredentials-apiCredentialId-generateClientKey" [
  merchantId: string
  apiCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/apiCredentials/($apiCredentialId)/generateClientKey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of billing entities
#
# GET /merchants/{merchantId}/billingEntities
# operationId: get-merchants-merchantId-billingEntities
export def "merchants-billing-entities get-merchants-merchantId-billingEntities" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the billing entity.
]: nothing -> record<data: table<address: record, email: string, id: string, name: string, taxId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/billingEntities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all payment methods
#
# GET /merchants/{merchantId}/paymentMethodSettings
# operationId: get-merchants-merchantId-paymentMethodSettings
export def "merchants-payment-method-settings get-merchants-merchantId-paymentMethodSettings" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The unique identifier of the store for which to return the payment methods.
  --businessLineId: string # The unique identifier of the Business Line for which to return the payment methods.
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
  --pageNumber: int # The number of the page to fetch. (format: int32)
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<allowed: bool, applePay: record, bcmc: record, businessLineId: string, cartesBancaires: record, countries: list, currencies: list, customRoutingFlags: list, enabled: bool, giroPay: record, googlePay: record, id: string, klarna: record, mealVoucher_FR: record, paypal: record, reference: string, shopperInteraction: string, sofort: record, storeId: string, swish: record, type: string, verificationStatus: string, vipps: record>, itemsTotal: int, pagesTotal: int, typesWithErrors: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar") (serialize-qp "businessLineId" $businessLineId "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/paymentMethodSettings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a payment method
#
# POST /merchants/{merchantId}/paymentMethodSettings
# operationId: post-merchants-merchantId-paymentMethodSettings
# --applePay shape: {domains?: list}
# --bcmc shape: {enableBcmcMobile?: bool}
# --cartesBancaires shape: {siret: string}
# --giroPay shape: {supportEmail: string}
# --googlePay shape: {merchantId: string, reuseMerchantId?: bool}
# --klarna shape: {autoCapture?: bool, disputeEmail: string, region?: "NA"|"EU"|"CH"|"AU", supportEmail: string}
# --mealVoucher_FR shape: {conecsId: string, siret: string, subTypes: list}
# --paypal shape: {directCapture?: bool, payerId: string, subject: string}
# --sofort shape: {currencyCode: string, logo: string}
# --swish shape: {swishNumber?: string}
# --vipps shape: {logo: string, subscriptionCancelUrl?: string}
export def "merchants-payment-method-settings post-merchants-merchantId-paymentMethodSettings" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --applePay: record # shape: {domains?: list}
  --bcmc: record # shape: {enableBcmcMobile?: bool}
  --businessLineId: string # The unique identifier of the business line.
  --cartesBancaires: record # shape: {siret: string}
  --countries: list # The list of countries where a payment method is available. By default, all countries supported by the payment method.
  --currencies: list # The list of currencies that a payment method supports. By default, all currencies supported by the payment method.
  --customRoutingFlags: list # The list of custom routing flags to route payment to the intended acquirer.
  --giroPay: record # shape: {supportEmail: string}
  --googlePay: record # shape: {merchantId: string, reuseMerchantId?: bool}
  --klarna: record # shape: {autoCapture?: bool, disputeEmail: string, region?: "NA"|"EU"|"CH"|"AU", supportEmail: string}
  --mealVoucher-FR: record # shape: {conecsId: string, siret: string, subTypes: list}
  --paypal: record # shape: {directCapture?: bool, payerId: string, subject: string}
  --reference: string # Your reference for the payment method. Supported characters a-z, A-Z, 0-9.
  --shopperInteraction: string@shopperInteraction-completer # The sales channel. Required if the merchant account does not have a sales channel. When you provide this field, it overrides the default sales channel set on the merchant account.  Possible values: **eCommerce**, **pos**, **contAuth**, and **moto**. 
  --sofort: record # shape: {currencyCode: string, logo: string}
  --storeId: string # The ID of the [store](https://docs.adyen.com/api-explorer/#/ManagementService/latest/post/stores__resParam_id), if any.
  --swish: record # shape: {swishNumber?: string}
  --type: string@type-completer # Payment method [variant](https://docs.adyen.com/development-resources/paymentmethodvariant#management-api).
  --vipps: record # shape: {logo: string, subscriptionCancelUrl?: string}
]: any -> record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/paymentMethodSettings")
  let body = {applePay: $applePay, bcmc: $bcmc, businessLineId: $businessLineId, cartesBancaires: $cartesBancaires, countries: $countries, currencies: $currencies, customRoutingFlags: $customRoutingFlags, giroPay: $giroPay, googlePay: $googlePay, klarna: $klarna, mealVoucher_FR: $mealVoucher_FR, paypal: $paypal, reference: $reference, shopperInteraction: $shopperInteraction, sofort: $sofort, storeId: $storeId, swish: $swish, type: $type, vipps: $vipps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment method details
#
# GET /merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}
# operationId: get-merchants-merchantId-paymentMethodSettings-paymentMethodId
export def "merchants-payment-method-settings get-merchants-merchantId-paymentMethodSettings-paymentMethodId" [
  merchantId: string
  paymentMethodId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/paymentMethodSettings/($paymentMethodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a payment method
#
# PATCH /merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}
# operationId: patch-merchants-merchantId-paymentMethodSettings-paymentMethodId
# --shopperStatement shape: {doingBusinessAsName?: string, type?: "append"|"dynamic"|"fixed"}
export def "merchants-payment-method-settings patch-merchants-merchantId-paymentMethodSettings-paymentMethodId" [
  merchantId: string
  paymentMethodId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countries: list # The list of countries where a payment method is available. By default, all countries supported by the payment method.
  --currencies: list # The list of currencies that a payment method supports. By default, all currencies supported by the payment method.
  --customRoutingFlags: list # Custom routing flags for acquirer routing.
  --enabled: oneof<nothing, bool> # Indicates whether the payment method is enabled (**true**) or disabled (**false**).
  --shopperStatement: record # shape: {doingBusinessAsName?: string, type?: "append"|"dynamic"|"fixed"}
  --storeIds: list # The list of stores for this payment method
]: any -> record<allowed: bool, applePay: record<domains: list<string>>, bcmc: record<enableBcmcMobile: bool>, businessLineId: string, cartesBancaires: record<siret: string>, countries: list<string>, currencies: list<string>, customRoutingFlags: list<string>, enabled: bool, giroPay: record<supportEmail: string>, googlePay: record<merchantId: string, reuseMerchantId: bool>, id: string, klarna: record<autoCapture: bool, disputeEmail: string, region: string, supportEmail: string>, mealVoucher_FR: record<conecsId: string, siret: string, subTypes: list<string>>, paypal: record<directCapture: bool, payerId: string, subject: string>, reference: string, shopperInteraction: string, sofort: record<currencyCode: string, logo: string>, storeId: string, swish: record<swishNumber: string>, type: string, verificationStatus: string, vipps: record<logo: string, subscriptionCancelUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/paymentMethodSettings/($paymentMethodId)")
  let body = {countries: $countries, currencies: $currencies, customRoutingFlags: $customRoutingFlags, enabled: $enabled, shopperStatement: $shopperStatement, storeIds: $storeIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add an Apple Pay domain
#
# POST /merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}/addApplePayDomains
# operationId: post-merchants-merchantId-paymentMethodSettings-paymentMethodId-addApplePayDomains
export def "merchants-payment-method-settings-add-apple-pay-domains post-merchants-merchantId-paymentMethodSettings-paymentMethodId-addApplePayDomains" [
  merchantId: string
  paymentMethodId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domains: list # The list of merchant domains. Maximum: 99 domains per request.  For more information, see [Apple Pay documentation](https://docs.adyen.com/payment-methods/apple-pay/web-drop-in?tab=adyen-certificate-live_1#going-live).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/paymentMethodSettings/($paymentMethodId)/addApplePayDomains")
  let body = {domains: $domains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Apple Pay domains
#
# GET /merchants/{merchantId}/paymentMethodSettings/{paymentMethodId}/getApplePayDomains
# operationId: get-merchants-merchantId-paymentMethodSettings-paymentMethodId-getApplePayDomains
export def "merchants-payment-method-settings-get-apple-pay-domains get-merchants-merchantId-paymentMethodSettings-paymentMethodId-getApplePayDomains" [
  merchantId: string
  paymentMethodId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domains: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/paymentMethodSettings/($paymentMethodId)/getApplePayDomains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of payout settings
#
# GET /merchants/{merchantId}/payoutSettings
# operationId: get-merchants-merchantId-payoutSettings
export def "merchants-payout-settings get-merchants-merchantId-payoutSettings" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/payoutSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a payout setting
#
# POST /merchants/{merchantId}/payoutSettings
# operationId: post-merchants-merchantId-payoutSettings
export def "merchants-payout-settings post-merchants-merchantId-payoutSettings" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Indicates if payouts to this bank account are enabled. Default: **true**.  To receive payouts into this bank account, both `enabled` and `allowed` must be **true**.
  --enabledFromDate: string # The date when Adyen starts paying out to this bank account.  Format: [ISO 8601](https://www.w3.org/TR/NOTE-datetime), for example, **2019-11-23T12:25:28Z** or **2020-05-27T20:25:28+08:00**.  If not specified, the `enabled` field indicates if payouts are enabled for this bank account.  If a date is specified and:  * `enabled`: **true**, payouts are enabled starting the specified date. * `enabled`: **false**, payouts are disabled until the specified date. On the specified date, `enabled` changes to **true** and this field is reset to **null**.
  transferInstrumentId: string # The unique identifier of the [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments) that contains the details of the bank account.
]: any -> record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/payoutSettings")
  let body = {enabled: $enabled, enabledFromDate: $enabledFromDate, transferInstrumentId: $transferInstrumentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a payout setting
#
# DELETE /merchants/{merchantId}/payoutSettings/{payoutSettingsId}
# operationId: delete-merchants-merchantId-payoutSettings-payoutSettingsId
export def "merchants-payout-settings delete-merchants-merchantId-payoutSettings-payoutSettingsId" [
  merchantId: string
  payoutSettingsId: string
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
  let full_url = (build-url $base $"/merchants/($merchantId)/payoutSettings/($payoutSettingsId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a payout setting
#
# GET /merchants/{merchantId}/payoutSettings/{payoutSettingsId}
# operationId: get-merchants-merchantId-payoutSettings-payoutSettingsId
export def "merchants-payout-settings get-merchants-merchantId-payoutSettings-payoutSettingsId" [
  merchantId: string
  payoutSettingsId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/payoutSettings/($payoutSettingsId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a payout setting
#
# PATCH /merchants/{merchantId}/payoutSettings/{payoutSettingsId}
# operationId: patch-merchants-merchantId-payoutSettings-payoutSettingsId
export def "merchants-payout-settings patch-merchants-merchantId-payoutSettings-payoutSettingsId" [
  merchantId: string
  payoutSettingsId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Indicates if payouts to this bank account are enabled. Default: **true**.  To receive payouts into this bank account, both `enabled` and `allowed` must be **true**.
]: any -> record<allowed: bool, enabled: bool, enabledFromDate: string, id: string, priority: string, transferInstrumentId: string, verificationStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/payoutSettings/($payoutSettingsId)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of shipping locations
#
# GET /merchants/{merchantId}/shippingLocations
# operationId: get-merchants-merchantId-shippingLocations
export def "merchants-shipping-locations get-merchants-merchantId-shippingLocations" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the shipping location.
  --offset: int # The number of locations to skip. (format: int32)
  --limit: int # The number of locations to return. (format: int32)
]: nothing -> record<data: table<address: record, contact: record, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/shippingLocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a shipping location
#
# POST /merchants/{merchantId}/shippingLocations
# operationId: post-merchants-merchantId-shippingLocations
# --address shape: {city?: string, companyName?: string, country?: string, postalCode?: string, stateOrProvince?: string, streetAddress?: string, streetAddress2?: string}
# --contact shape: {email?: string, firstName?: string, infix?: string, lastName?: string, phoneNumber?: string}
export def "merchants-shipping-locations post-merchants-merchantId-shippingLocations" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {city?: string, companyName?: string, country?: string, postalCode?: string, stateOrProvince?: string, streetAddress?: string, streetAddress2?: string}
  --contact: record # shape: {email?: string, firstName?: string, infix?: string, lastName?: string, phoneNumber?: string}
  --id: string # The unique identifier of the shipping location, for use as `shippingLocationId` when creating an order.
  --name: string # The unique name of the shipping location.
]: any -> record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/shippingLocations")
  let body = {address: $address, contact: $contact, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of stores
#
# GET /merchants/{merchantId}/stores
# operationId: get-merchants-merchantId-stores
export def "merchants-stores get-merchants-merchantId-stores" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
  --reference: string # The reference of the store.
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, address: record, businessLineIds: list, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record, status: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a store
#
# POST /merchants/{merchantId}/stores
# operationId: post-merchants-merchantId-stores
# --address shape: {city?: string, country: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
# --splitConfiguration shape: {balanceAccountId?: string, splitConfigurationId?: string}
export def "merchants-stores post-merchants-merchantId-stores" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # shape: {city?: string, country: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
  --businessLineIds: list # The unique identifiers of the [business lines](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businesslines__resParam_id) that the store is associated with. If not specified, the business line of the merchant account is used. Required when there are multiple business lines under the merchant account.
  description: string # Your description of the store.
  --externalReferenceId: string # When using the Zip payment method: The location ID that Zip has assigned to your store.
  phoneNumber: string # The phone number of the store, including '+' and country code.
  --reference: string # Your reference to recognize the store by. Also known as the store code.  Allowed characters: Lowercase and uppercase letters without diacritics, numbers 0 through 9, hyphen (-), and underscore (_).
  shopperStatement: string # The store name to be shown on the shopper's bank or credit card statement and on the shopper receipt. Maximum length: 22 characters; can't be all numbers.
  --splitConfiguration: record # shape: {balanceAccountId?: string, splitConfigurationId?: string}
]: any -> record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/stores")
  let body = {address: $address, businessLineIds: $businessLineIds, description: $description, externalReferenceId: $externalReferenceId, phoneNumber: $phoneNumber, reference: $reference, shopperStatement: $shopperStatement, splitConfiguration: $splitConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the terminal logo
#
# GET /merchants/{merchantId}/stores/{reference}/terminalLogos
# operationId: get-merchants-merchantId-stores-reference-terminalLogos
export def "merchants-stores-terminal-logos get-merchants-merchantId-stores-reference-terminalLogos" [
  merchantId: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T.
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/stores/($reference)/terminalLogos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the terminal logo
#
# PATCH /merchants/{merchantId}/stores/{reference}/terminalLogos
# operationId: patch-merchants-merchantId-stores-reference-terminalLogos
export def "merchants-stores-terminal-logos patch-merchants-merchantId-stores-reference-terminalLogos" [
  merchantId: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> record<data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/stores/($reference)/terminalLogos" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get terminal settings
#
# GET /merchants/{merchantId}/stores/{reference}/terminalSettings
# operationId: get-merchants-merchantId-stores-reference-terminalSettings
export def "merchants-stores-terminal-settings get-merchants-merchantId-stores-reference-terminalSettings" [
  merchantId: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/stores/($reference)/terminalSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update terminal settings
#
# PATCH /merchants/{merchantId}/stores/{reference}/terminalSettings
# operationId: patch-merchants-merchantId-stores-reference-terminalSettings
# --cardholderReceipt shape: {headerForAuthorizedReceipt?: string}
# --connectivity shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
# --gratuities item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
# --hardware shape: {displayMaximumBackLight?: int}
# --nexo shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
# --offlineProcessing shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
# --opi shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
# --passcodes shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
# --payAtTable shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
# --payment shape: {hideMinorUnitsInCurrencies?: list}
# --receiptOptions shape: {logo?: string, qrCodeData?: string}
# --receiptPrinting shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
# --signature shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
# --standalone shape: {currencyCode?: string, enableStandalone?: bool}
# --surcharge shape: {askConfirmation?: bool, configurations?: list}
# --timeouts shape: {fromActiveToSleep?: int}
# --wifiProfiles shape: {profiles?: list, settings?: record}
export def "merchants-stores-terminal-settings patch-merchants-merchantId-stores-reference-terminalSettings" [
  merchantId: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholderReceipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
  --offlineProcessing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --payAtTable: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list}
  --receiptOptions: record # shape: {logo?: string, qrCodeData?: string}
  --receiptPrinting: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifiProfiles: record # shape: {profiles?: list, settings?: record}
]: any -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/stores/($reference)/terminalSettings")
  let body = {cardholderReceipt: $cardholderReceipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offlineProcessing: $offlineProcessing, opi: $opi, passcodes: $passcodes, payAtTable: $payAtTable, payment: $payment, receiptOptions: $receiptOptions, receiptPrinting: $receiptPrinting, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifiProfiles: $wifiProfiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a store
#
# GET /merchants/{merchantId}/stores/{storeId}
# operationId: get-merchants-merchantId-stores-storeId
export def "merchants-stores get-merchants-merchantId-stores-storeId" [
  merchantId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/stores/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a store
#
# PATCH /merchants/{merchantId}/stores/{storeId}
# operationId: patch-merchants-merchantId-stores-storeId
# --address shape: {city?: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
# --splitConfiguration shape: {balanceAccountId?: string, splitConfigurationId?: string}
export def "merchants-stores patch-merchants-merchantId-stores-storeId" [
  merchantId: string
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {city?: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
  --businessLineIds: list # The unique identifiers of the [business lines](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businesslines__resParam_id) that the store is associated with.
  --description: string # The description of the store.
  --externalReferenceId: string # When using the Zip payment method: The location ID that Zip has assigned to your store.
  --splitConfiguration: record # shape: {balanceAccountId?: string, splitConfigurationId?: string}
  --status: string@status-completer # The status of the store. Possible values are:  - **active**: This value is assigned automatically when a store is created.  - **inactive**: The maximum [transaction limits and number of Store-and-Forward transactions](https://docs.adyen.com/point-of-sale/determine-account-structure/configure-features#payment-features) for the store are set to 0. This blocks new transactions, but captures are still possible. - **closed**: The terminals of the store are reassigned to the merchant inventory, so they can't process payments.  You can change the status from **active** to **inactive**, and from **inactive** to **active** or **closed**.  Once **closed**, a store can't be reopened.
]: any -> record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/stores/($storeId)")
  let body = {address: $address, businessLineIds: $businessLineIds, description: $description, externalReferenceId: $externalReferenceId, splitConfiguration: $splitConfiguration, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the terminal logo
#
# GET /merchants/{merchantId}/terminalLogos
# operationId: get-merchants-merchantId-terminalLogos
export def "merchants-terminal-logos get-merchants-merchantId-terminalLogos" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T.
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalLogos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the terminal logo
#
# PATCH /merchants/{merchantId}/terminalLogos
# operationId: patch-merchants-merchantId-terminalLogos
export def "merchants-terminal-logos patch-merchants-merchantId-terminalLogos" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Allowed values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T.
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> record<data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalLogos" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of terminal models
#
# GET /merchants/{merchantId}/terminalModels
# operationId: get-merchants-merchantId-terminalModels
export def "merchants-terminal-models get-merchants-merchantId-terminalModels" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalModels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of orders
#
# GET /merchants/{merchantId}/terminalOrders
# operationId: get-merchants-merchantId-terminalOrders
export def "merchants-terminal-orders get-merchants-merchantId-terminalOrders" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customerOrderReference: string # Your purchase order number.
  --status: string # The order status. Possible values (not case-sensitive): Placed, Confirmed, Cancelled, Shipped, Delivered.
  --offset: int # The number of orders to skip. (format: int32)
  --limit: int # The number of orders to return. (format: int32)
]: nothing -> record<data: table<billingEntity: record, customerOrderReference: string, id: string, items: list, orderDate: string, shippingLocation: record, status: string, trackingUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customerOrderReference" $customerOrderReference "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an order
#
# POST /merchants/{merchantId}/terminalOrders
# operationId: post-merchants-merchantId-terminalOrders
# --items item shape: {id?: string, installments?: int, name?: string, quantity?: int}
export def "merchants-terminal-orders post-merchants-merchantId-terminalOrders" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billingEntityId: string # The identification of the billing entity to use for the order.
  --customerOrderReference: string # The merchant-defined purchase order reference.
  --items: list # The products included in the order. — item shape: {id?: string, installments?: int, name?: string, quantity?: int}
  --shippingLocationId: string # The identification of the shipping location to use for the order.
  --taxId: string # The tax number of the billing entity.
]: any -> record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalOrders")
  let body = {billingEntityId: $billingEntityId, customerOrderReference: $customerOrderReference, items: $items, shippingLocationId: $shippingLocationId, taxId: $taxId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an order
#
# GET /merchants/{merchantId}/terminalOrders/{orderId}
# operationId: get-merchants-merchantId-terminalOrders-orderId
export def "merchants-terminal-orders get-merchants-merchantId-terminalOrders-orderId" [
  merchantId: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalOrders/($orderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an order
#
# PATCH /merchants/{merchantId}/terminalOrders/{orderId}
# operationId: patch-merchants-merchantId-terminalOrders-orderId
# --items item shape: {id?: string, installments?: int, name?: string, quantity?: int}
export def "merchants-terminal-orders patch-merchants-merchantId-terminalOrders-orderId" [
  merchantId: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billingEntityId: string # The identification of the billing entity to use for the order.
  --customerOrderReference: string # The merchant-defined purchase order reference.
  --items: list # The products included in the order. — item shape: {id?: string, installments?: int, name?: string, quantity?: int}
  --shippingLocationId: string # The identification of the shipping location to use for the order.
  --taxId: string # The tax number of the billing entity.
]: any -> record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalOrders/($orderId)")
  let body = {billingEntityId: $billingEntityId, customerOrderReference: $customerOrderReference, items: $items, shippingLocationId: $shippingLocationId, taxId: $taxId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel an order
#
# POST /merchants/{merchantId}/terminalOrders/{orderId}/cancel
# operationId: post-merchants-merchantId-terminalOrders-orderId-cancel
export def "merchants-terminal-orders-cancel post-merchants-merchantId-terminalOrders-orderId-cancel" [
  merchantId: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billingEntity: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, email: string, id: string, name: string, taxId: string>, customerOrderReference: string, id: string, items: table<id: string, installments: int, name: string, quantity: int>, orderDate: string, shippingLocation: record<address: record<city: string, companyName: string, country: string, postalCode: string, stateOrProvince: string, streetAddress: string, streetAddress2: string>, contact: record<email: string, firstName: string, infix: string, lastName: string, phoneNumber: string>, id: string, name: string>, status: string, trackingUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalOrders/($orderId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of terminal products
#
# GET /merchants/{merchantId}/terminalProducts
# operationId: get-merchants-merchantId-terminalProducts
export def "merchants-terminal-products get-merchants-merchantId-terminalProducts" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # The country to return products for, in [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) format. For example, **US**
  --terminalModelId: string # The terminal model to return products for. Use the ID returned in the [GET `/terminalModels`](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/merchants/{merchantId}/terminalModels) response. For example, **Verifone.M400**
  --offset: int # The number of products to skip. (format: int32)
  --limit: int # The number of products to return. (format: int32)
]: nothing -> record<data: table<description: string, id: string, itemsIncluded: list, name: string, price: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "terminalModelId" $terminalModelId "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalProducts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get terminal settings
#
# GET /merchants/{merchantId}/terminalSettings
# operationId: get-merchants-merchantId-terminalSettings
export def "merchants-terminal-settings get-merchants-merchantId-terminalSettings" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update terminal settings
#
# PATCH /merchants/{merchantId}/terminalSettings
# operationId: patch-merchants-merchantId-terminalSettings
# --cardholderReceipt shape: {headerForAuthorizedReceipt?: string}
# --connectivity shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
# --gratuities item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
# --hardware shape: {displayMaximumBackLight?: int}
# --nexo shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
# --offlineProcessing shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
# --opi shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
# --passcodes shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
# --payAtTable shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
# --payment shape: {hideMinorUnitsInCurrencies?: list}
# --receiptOptions shape: {logo?: string, qrCodeData?: string}
# --receiptPrinting shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
# --signature shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
# --standalone shape: {currencyCode?: string, enableStandalone?: bool}
# --surcharge shape: {askConfirmation?: bool, configurations?: list}
# --timeouts shape: {fromActiveToSleep?: int}
# --wifiProfiles shape: {profiles?: list, settings?: record}
export def "merchants-terminal-settings patch-merchants-merchantId-terminalSettings" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholderReceipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
  --offlineProcessing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --payAtTable: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list}
  --receiptOptions: record # shape: {logo?: string, qrCodeData?: string}
  --receiptPrinting: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifiProfiles: record # shape: {profiles?: list, settings?: record}
]: any -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/terminalSettings")
  let body = {cardholderReceipt: $cardholderReceipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offlineProcessing: $offlineProcessing, opi: $opi, passcodes: $passcodes, payAtTable: $payAtTable, payment: $payment, receiptOptions: $receiptOptions, receiptPrinting: $receiptPrinting, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifiProfiles: $wifiProfiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of users
#
# GET /merchants/{merchantId}/users
# operationId: get-merchants-merchantId-users
export def "merchants-users get-merchants-merchantId-users" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page. Maximum value is **100**. The default is **10** items on a page. (format: int32)
  --username: string # The partial or complete username to select all users that match.
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, accountGroups: list, active: bool, authnApps: list, email: string, id: string, name: record, roles: list, timeZoneCode: string, username: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /merchants/{merchantId}/users
# operationId: post-merchants-merchantId-users
# --name shape: {firstName: string, lastName: string}
export def "merchants-users post-merchants-merchantId-users" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountGroups: list # The list of [account groups](https://docs.adyen.com/account/account-structure#account-groups) associated with this user.
  --authnApps: list # Set of authn apps to add to this user
  email: string # The email address of the user.
  name: record # shape: {firstName: string, lastName: string}
  --roles: list # The list of [roles](https://docs.adyen.com/account/user-roles) for this user.
  --timeZoneCode: string # The [tz database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the time zone of the user. For example, **Europe/Amsterdam**.
  username: string # The username for this user. Allowed length: 255 alphanumeric characters.
]: any -> record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/users")
  let body = {accountGroups: $accountGroups, authnApps: $authnApps, email: $email, name: $name, roles: $roles, timeZoneCode: $timeZoneCode, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get user details
#
# GET /merchants/{merchantId}/users/{userId}
# operationId: get-merchants-merchantId-users-userId
export def "merchants-users get-merchants-merchantId-users-userId" [
  merchantId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /merchants/{merchantId}/users/{userId}
# operationId: patch-merchants-merchantId-users-userId
# --name shape: {firstName?: string, lastName?: string}
export def "merchants-users patch-merchants-merchantId-users-userId" [
  merchantId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountGroups: list # The list of [account groups](https://docs.adyen.com/account/account-structure#account-groups) associated with this user.
  --active: oneof<nothing, bool> # Sets the status of the user to active (**true**) or inactive (**false**).
  --authnAppsToAdd: list # Set of authn apps to add to this user
  --authnAppsToRemove: list # Set of authn apps to remove from this user
  --email: string # The email address of the user.
  --name: record # shape: {firstName?: string, lastName?: string}
  --roles: list # The list of [roles](https://docs.adyen.com/account/user-roles) for this user.
  --timeZoneCode: string # The [tz database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the time zone of the user. For example, **Europe/Amsterdam**.
]: any -> record<_links: record<self: record<href: string>>, accountGroups: list<string>, active: bool, authnApps: list<string>, email: string, id: string, name: record<firstName: string, lastName: string>, roles: list<string>, timeZoneCode: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/users/($userId)")
  let body = {accountGroups: $accountGroups, active: $active, authnAppsToAdd: $authnAppsToAdd, authnAppsToRemove: $authnAppsToRemove, email: $email, name: $name, roles: $roles, timeZoneCode: $timeZoneCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all webhooks
#
# GET /merchants/{merchantId}/webhooks
# operationId: get-merchants-merchantId-webhooks
export def "merchants-webhooks get-merchants-merchantId-webhooks" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, accountReference: string, data: table<_links: record, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/merchants/($merchantId)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set up a webhook
#
# POST /merchants/{merchantId}/webhooks
# operationId: post-merchants-merchantId-webhooks
# --additionalSettings shape: {includeEventCodes?: list, properties?: record}
export def "merchants-webhooks post-merchants-merchantId-webhooks" [
  merchantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acceptsExpiredCertificate: oneof<nothing, bool> # Indicates if expired SSL certificates are accepted. Default value: **false**.
  --acceptsSelfSignedCertificate: oneof<nothing, bool> # Indicates if self-signed SSL certificates are accepted. Default value: **false**.
  --acceptsUntrustedRootCertificate: oneof<nothing, bool> # Indicates if untrusted SSL certificates are accepted. Default value: **false**.
  --active: oneof<nothing, bool> # Indicates if the webhook configuration is active. The field must be **true** for us to send webhooks about events related an account.
  --additionalSettings: record # shape: {includeEventCodes?: list, properties?: record}
  communicationFormat: string@communicationFormat-completer # Format or protocol for receiving webhooks. Possible values: * **soap** * **http** * **json** 
  --description: string # Your description for this webhook configuration.
  --networkType: string@networkType-completer # Network type for Terminal API notification webhooks. Possible values: * **public** * **local**  Default Value: **public**.
  --password: string # Password to access the webhook URL.
  --populateSoapActionHeader: oneof<nothing, bool> # Indicates if the SOAP action header needs to be populated. Default value: **false**.  Only applies if `communicationFormat`: **soap**.
  --sslVersion: string@sslVersion-completer # SSL version to access the public webhook URL specified in the `url` field. Possible values: * **TLSv1.3** * **TLSv1.2** * **HTTP** - Only allowed on Test environment.  If not specified, the webhook will use `sslVersion`: **TLSv1.2**.
  type: string # The type of webhook that is being created. Possible values are:  - **standard** - **account-settings-notification** - **banktransfer-notification** - **boletobancario-notification** - **directdebit-notification** - **pending-notification** - **ideal-notification** - **ideal-pending-notification** - **report-notification** - **rreq-notification**  Find out more about [standard notification webhooks](https://docs.adyen.com/development-resources/webhooks/understand-notifications#event-codes) and [other types of notifications](https://docs.adyen.com/development-resources/webhooks/understand-notifications#other-notifications).
  --body-url: string # Public URL where webhooks will be sent, for example **https://www.domain.com/webhook-endpoint**.
  --username: string # Username to access the webhook URL.
]: any -> record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/webhooks")
  let body = {acceptsExpiredCertificate: $acceptsExpiredCertificate, acceptsSelfSignedCertificate: $acceptsSelfSignedCertificate, acceptsUntrustedRootCertificate: $acceptsUntrustedRootCertificate, active: $active, additionalSettings: $additionalSettings, communicationFormat: $communicationFormat, description: $description, networkType: $networkType, password: $password, populateSoapActionHeader: $populateSoapActionHeader, sslVersion: $sslVersion, type: $type, url: $body_url, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a webhook
#
# DELETE /merchants/{merchantId}/webhooks/{webhookId}
# operationId: delete-merchants-merchantId-webhooks-webhookId
export def "merchants-webhooks delete-merchants-merchantId-webhooks-webhookId" [
  merchantId: string
  webhookId: string
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
  let full_url = (build-url $base $"/merchants/($merchantId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a webhook
#
# GET /merchants/{merchantId}/webhooks/{webhookId}
# operationId: get-merchants-merchantId-webhooks-webhookId
export def "merchants-webhooks get-merchants-merchantId-webhooks-webhookId" [
  merchantId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /merchants/{merchantId}/webhooks/{webhookId}
# operationId: patch-merchants-merchantId-webhooks-webhookId
# --additionalSettings shape: {includeEventCodes?: list, properties?: record}
export def "merchants-webhooks patch-merchants-merchantId-webhooks-webhookId" [
  merchantId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acceptsExpiredCertificate: oneof<nothing, bool> # Indicates if expired SSL certificates are accepted. Default value: **false**.
  --acceptsSelfSignedCertificate: oneof<nothing, bool> # Indicates if self-signed SSL certificates are accepted. Default value: **false**.
  --acceptsUntrustedRootCertificate: oneof<nothing, bool> # Indicates if untrusted SSL certificates are accepted. Default value: **false**.
  --active: oneof<nothing, bool> # Indicates if the webhook configuration is active. The field must be **true** for us to send webhooks about events related an account.
  --additionalSettings: record # shape: {includeEventCodes?: list, properties?: record}
  --communicationFormat: string@communicationFormat-completer # Format or protocol for receiving webhooks. Possible values: * **soap** * **http** * **json** 
  --description: string # Your description for this webhook configuration.
  --networkType: string@networkType-completer # Network type for Terminal API notification webhooks. Possible values: * **public** * **local**  Default Value: **public**.
  --password: string # Password to access the webhook URL.
  --populateSoapActionHeader: oneof<nothing, bool> # Indicates if the SOAP action header needs to be populated. Default value: **false**.  Only applies if `communicationFormat`: **soap**.
  --sslVersion: string@sslVersion-completer # SSL version to access the public webhook URL specified in the `url` field. Possible values: * **TLSv1.3** * **TLSv1.2** * **HTTP** - Only allowed on Test environment.  If not specified, the webhook will use `sslVersion`: **TLSv1.2**.
  --body-url: string # Public URL where webhooks will be sent, for example **https://www.domain.com/webhook-endpoint**.
  --username: string # Username to access the webhook URL.
]: any -> record<_links: record<company: record<href: string>, generateHmac: record<href: string>, merchant: record<href: string>, self: record<href: string>, testWebhook: record<href: string>>, acceptsExpiredCertificate: bool, acceptsSelfSignedCertificate: bool, acceptsUntrustedRootCertificate: bool, accountReference: string, active: bool, additionalSettings: record<excludeEventCodes: list<string>, includeEventCodes: list<string>, properties: record>, certificateAlias: string, communicationFormat: string, description: string, filterMerchantAccountType: string, filterMerchantAccounts: list<string>, hasError: bool, hasPassword: bool, hmacKeyCheckValue: string, id: string, networkType: string, populateSoapActionHeader: bool, sslVersion: string, type: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/webhooks/($webhookId)")
  let body = {acceptsExpiredCertificate: $acceptsExpiredCertificate, acceptsSelfSignedCertificate: $acceptsSelfSignedCertificate, acceptsUntrustedRootCertificate: $acceptsUntrustedRootCertificate, active: $active, additionalSettings: $additionalSettings, communicationFormat: $communicationFormat, description: $description, networkType: $networkType, password: $password, populateSoapActionHeader: $populateSoapActionHeader, sslVersion: $sslVersion, url: $body_url, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate an HMAC key
#
# POST /merchants/{merchantId}/webhooks/{webhookId}/generateHmac
# operationId: post-merchants-merchantId-webhooks-webhookId-generateHmac
export def "merchants-webhooks-generate-hmac post-merchants-merchantId-webhooks-webhookId-generateHmac" [
  merchantId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hmacKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/webhooks/($webhookId)/generateHmac")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test a webhook
#
# POST /merchants/{merchantId}/webhooks/{webhookId}/test
# operationId: post-merchants-merchantId-webhooks-webhookId-test
# --notification shape: {amount?: record, eventCode?: string, eventDate?: string, merchantReference?: string, paymentMethod?: string, reason?: string, success?: bool}
export def "merchants-webhooks-test post-merchants-merchantId-webhooks-webhookId-test" [
  merchantId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification: record # shape: {amount?: record, eventCode?: string, eventDate?: string, merchantReference?: string, paymentMethod?: string, reason?: string, success?: bool}
  --types: list # List of event codes for which to send test notifications. Only the webhook types below are supported.   Possible values if webhook `type`: **standard**:  * **AUTHORISATION** * **CHARGEBACK_REVERSED** * **ORDER_CLOSED** * **ORDER_OPENED** * **PAIDOUT_REVERSED** * **PAYOUT_THIRDPARTY** * **REFUNDED_REVERSED** * **REFUND_WITH_DATA** * **REPORT_AVAILABLE** * **CUSTOM** - set your custom notification fields in the [`notification`](https://docs.adyen.com/api-explorer/#/ManagementService/v1/post/companies/{companyId}/webhooks/{webhookId}/test__reqParam_notification) object.  Possible values if webhook `type`: **banktransfer-notification**:  * **PENDING**  Possible values if webhook `type`: **report-notification**:  * **REPORT_AVAILABLE**  Possible values if webhook `type`: **ideal-notification**:  * **AUTHORISATION**  Possible values if webhook `type`: **pending-notification**:  * **PENDING**
]: any -> record<data: table<merchantId: string, output: string, requestSent: string, responseCode: string, responseTime: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/merchants/($merchantId)/webhooks/($webhookId)/test")
  let body = {notification: $notification, types: $types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of stores
#
# GET /stores
# operationId: get-stores
export def "stores get-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 10 items on a page. (format: int32)
  --reference: string # The reference of the store.
  --merchantId: string # The unique identifier of the merchant account.
]: nothing -> record<_links: record<first: record<href: string>, last: record<href: string>, next: record<href: string>, prev: record<href: string>, self: record<href: string>>, data: table<_links: record, address: record, businessLineIds: list, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record, status: string>, itemsTotal: int, pagesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "reference" $reference "scalar") (serialize-qp "merchantId" $merchantId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a store
#
# POST /stores
# operationId: post-stores
# --address shape: {city?: string, country: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
# --splitConfiguration shape: {balanceAccountId?: string, splitConfigurationId?: string}
export def "stores post-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # shape: {city?: string, country: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
  --businessLineIds: list # The unique identifiers of the [business lines](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businesslines__resParam_id) that the store is associated with. If not specified, the business line of the merchant account is used. Required when there are multiple business lines under the merchant account.
  description: string # Your description of the store.
  --externalReferenceId: string # When using the Zip payment method: The location ID that Zip has assigned to your store.
  merchantId: string # The unique identifier of the merchant account that the store belongs to.
  phoneNumber: string # The phone number of the store, including '+' and country code.
  --reference: string # Your reference to recognize the store by. Also known as the store code.  Allowed characters: Lowercase and uppercase letters without diacritics, numbers 0 through 9, hyphen (-), and underscore (_).
  shopperStatement: string # The store name to be shown on the shopper's bank or credit card statement and on the shopper receipt. Maximum length: 22 characters; can't be all numbers.
  --splitConfiguration: record # shape: {balanceAccountId?: string, splitConfigurationId?: string}
]: any -> record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stores")
  let body = {address: $address, businessLineIds: $businessLineIds, description: $description, externalReferenceId: $externalReferenceId, merchantId: $merchantId, phoneNumber: $phoneNumber, reference: $reference, shopperStatement: $shopperStatement, splitConfiguration: $splitConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a store
#
# GET /stores/{storeId}
# operationId: get-stores-storeId
export def "stores get-stores-storeId" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a store
#
# PATCH /stores/{storeId}
# operationId: patch-stores-storeId
# --address shape: {city?: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
# --splitConfiguration shape: {balanceAccountId?: string, splitConfigurationId?: string}
export def "stores patch-stores-storeId" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {city?: string, line1?: string, line2?: string, line3?: string, postalCode?: string, stateOrProvince?: string}
  --businessLineIds: list # The unique identifiers of the [business lines](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/businesslines__resParam_id) that the store is associated with.
  --description: string # The description of the store.
  --externalReferenceId: string # When using the Zip payment method: The location ID that Zip has assigned to your store.
  --splitConfiguration: record # shape: {balanceAccountId?: string, splitConfigurationId?: string}
  --status: string@status-completer # The status of the store. Possible values are:  - **active**: This value is assigned automatically when a store is created.  - **inactive**: The maximum [transaction limits and number of Store-and-Forward transactions](https://docs.adyen.com/point-of-sale/determine-account-structure/configure-features#payment-features) for the store are set to 0. This blocks new transactions, but captures are still possible. - **closed**: The terminals of the store are reassigned to the merchant inventory, so they can't process payments.  You can change the status from **active** to **inactive**, and from **inactive** to **active** or **closed**.  Once **closed**, a store can't be reopened.
]: any -> record<_links: record<self: record<href: string>>, address: record<city: string, country: string, line1: string, line2: string, line3: string, postalCode: string, stateOrProvince: string>, businessLineIds: list<string>, description: string, externalReferenceId: string, id: string, merchantId: string, phoneNumber: string, reference: string, shopperStatement: string, splitConfiguration: record<balanceAccountId: string, splitConfigurationId: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($storeId)")
  let body = {address: $address, businessLineIds: $businessLineIds, description: $description, externalReferenceId: $externalReferenceId, splitConfiguration: $splitConfiguration, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the terminal logo
#
# GET /stores/{storeId}/terminalLogos
# operationId: get-stores-storeId-terminalLogos
export def "stores-terminal-logos get-stores-storeId-terminalLogos" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T.
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stores/($storeId)/terminalLogos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the terminal logo
#
# PATCH /stores/{storeId}/terminalLogos
# operationId: patch-stores-storeId-terminalLogos
export def "stores-terminal-logos patch-stores-storeId-terminalLogos" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # The terminal model. Possible values: E355, VX675WIFIBT, VX680, VX690, VX700, VX820, M400, MX925, P400Plus, UX300, UX410, V200cPlus, V240mPlus, V400cPlus, V400m, e280, e285, e285p, S1E, S1EL, S1F2, S1L, S1U, S7T.
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> record<data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stores/($storeId)/terminalLogos" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get terminal settings
#
# GET /stores/{storeId}/terminalSettings
# operationId: get-stores-storeId-terminalSettings
export def "stores-terminal-settings get-stores-storeId-terminalSettings" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($storeId)/terminalSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update terminal settings
#
# PATCH /stores/{storeId}/terminalSettings
# operationId: patch-stores-storeId-terminalSettings
# --cardholderReceipt shape: {headerForAuthorizedReceipt?: string}
# --connectivity shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
# --gratuities item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
# --hardware shape: {displayMaximumBackLight?: int}
# --nexo shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
# --offlineProcessing shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
# --opi shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
# --passcodes shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
# --payAtTable shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
# --payment shape: {hideMinorUnitsInCurrencies?: list}
# --receiptOptions shape: {logo?: string, qrCodeData?: string}
# --receiptPrinting shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
# --signature shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
# --standalone shape: {currencyCode?: string, enableStandalone?: bool}
# --surcharge shape: {askConfirmation?: bool, configurations?: list}
# --timeouts shape: {fromActiveToSleep?: int}
# --wifiProfiles shape: {profiles?: list, settings?: record}
export def "stores-terminal-settings patch-stores-storeId-terminalSettings" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholderReceipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
  --offlineProcessing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --payAtTable: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list}
  --receiptOptions: record # shape: {logo?: string, qrCodeData?: string}
  --receiptPrinting: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifiProfiles: record # shape: {profiles?: list, settings?: record}
]: any -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($storeId)/terminalSettings")
  let body = {cardholderReceipt: $cardholderReceipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offlineProcessing: $offlineProcessing, opi: $opi, passcodes: $passcodes, payAtTable: $payAtTable, payment: $payment, receiptOptions: $receiptOptions, receiptPrinting: $receiptPrinting, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifiProfiles: $wifiProfiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of terminals
#
# GET /terminals
# operationId: get-terminals
export def "terminals get-terminals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --searchQuery: string # Returns terminals with an ID that contains the specified string. If present, other query parameters are ignored.
  --countries: string # Returns terminals located in the countries specified by their [two-letter country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
  --merchantIds: string # Returns terminals that belong to the merchant accounts specified by their unique merchant account ID.
  --storeIds: string # Returns terminals that are assigned to the [stores](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/stores) specified by their unique store ID.
  --brandModels: string # Returns terminals of the [models](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/companies/{companyId}/terminalModels) specified in the format *brand.model*.
  --pageNumber: int # The number of the page to fetch. (format: int32)
  --pageSize: int # The number of items to have on a page, maximum 100. The default is 20 items on a page. (format: int32)
]: nothing -> record<data: table<assigned: bool, bluetoothIp: string, bluetoothMac: string, city: string, companyAccount: string, countryCode: string, deviceModel: string, ethernetIp: string, ethernetMac: string, firmwareVersion: string, iccid: string, id: string, lastActivityDateTime: string, lastTransactionDateTime: string, linkNegotiation: string, serialNumber: string, simStatus: string, status: string, storeStatus: string, wifiIp: string, wifiMac: string, wifiSsid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchQuery" $searchQuery "scalar") (serialize-qp "countries" $countries "scalar") (serialize-qp "merchantIds" $merchantIds "scalar") (serialize-qp "storeIds" $storeIds "scalar") (serialize-qp "brandModels" $brandModels "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/terminals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a terminal action
#
# POST /terminals/scheduleActions
# operationId: post-terminals-scheduleActions
export def "terminals-schedule-actions post-terminals-scheduleActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actionDetails: any # Information about the action to take.
  --scheduledAt: string # The date and time when the action should happen.  Format: [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339), but without the **Z** before the time offset. For example, **2021-11-15T12:16:21+01:00**  The action is sent with the first [maintenance call](https://docs.adyen.com/point-of-sale/automating-terminal-management/terminal-actions-api#when-actions-take-effect) after the specified date and time in the time zone of the terminal.  An empty value causes the action to be sent as soon as possible: at the next maintenance call.
  --storeId: string # The unique ID of the [store](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/stores). If present, all terminals in the `terminalIds` list must be assigned to this store.
  --terminalIds: list # A list of unique IDs of the terminals to apply the action to. You can extract the IDs from the [GET `/terminals`](https://docs.adyen.com/api-explorer/#/ManagementService/latest/get/terminals) response. Maximum length: 100 IDs.
]: any -> record<actionDetails: any, items: table<id: string, terminalId: string>, scheduledAt: string, storeId: string, terminalIds: list<string>, terminalsWithErrors: record, totalErrors: int, totalScheduled: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/terminals/scheduleActions")
  let body = {actionDetails: $actionDetails, scheduledAt: $scheduledAt, storeId: $storeId, terminalIds: $terminalIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the terminal logo
#
# GET /terminals/{terminalId}/terminalLogos
# operationId: get-terminals-terminalId-terminalLogos
export def "terminals-terminal-logos get-terminals-terminalId-terminalLogos" [
  terminalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminals/($terminalId)/terminalLogos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the logo
#
# PATCH /terminals/{terminalId}/terminalLogos
# operationId: patch-terminals-terminalId-terminalLogos
export def "terminals-terminal-logos patch-terminals-terminalId-terminalLogos" [
  terminalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # The image file, converted to a Base64-encoded string, of the logo to be shown on the terminal.
]: any -> record<data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminals/($terminalId)/terminalLogos")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get terminal settings
#
# GET /terminals/{terminalId}/terminalSettings
# operationId: get-terminals-terminalId-terminalSettings
export def "terminals-terminal-settings get-terminals-terminalId-terminalSettings" [
  terminalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminals/($terminalId)/terminalSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update terminal settings
#
# PATCH /terminals/{terminalId}/terminalSettings
# operationId: patch-terminals-terminalId-terminalSettings
# --cardholderReceipt shape: {headerForAuthorizedReceipt?: string}
# --connectivity shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
# --gratuities item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
# --hardware shape: {displayMaximumBackLight?: int}
# --nexo shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
# --offlineProcessing shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
# --opi shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
# --passcodes shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
# --payAtTable shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
# --payment shape: {hideMinorUnitsInCurrencies?: list}
# --receiptOptions shape: {logo?: string, qrCodeData?: string}
# --receiptPrinting shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
# --signature shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
# --standalone shape: {currencyCode?: string, enableStandalone?: bool}
# --surcharge shape: {askConfirmation?: bool, configurations?: list}
# --timeouts shape: {fromActiveToSleep?: int}
# --wifiProfiles shape: {profiles?: list, settings?: record}
export def "terminals-terminal-settings patch-terminals-terminalId-terminalSettings" [
  terminalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cardholderReceipt: record # shape: {headerForAuthorizedReceipt?: string}
  --connectivity: record # shape: {simcardStatus?: "ACTIVATED"|"INVENTORY"}
  --gratuities: list # Settings for tipping with or without predefined options to choose from. The maximum number of predefined options is four, or three plus the option to enter a custom tip. — item shape: {allowCustomAmount?: bool, currency?: string, predefinedTipEntries?: list, usePredefinedTipEntries?: bool}
  --hardware: record # shape: {displayMaximumBackLight?: int}
  --nexo: record # shape: {displayUrls?: record, encryptionKey?: record, eventUrls?: record, nexoEventUrls?: list}
  --offlineProcessing: record # shape: {chipFloorLimit?: int, offlineSwipeLimits?: list}
  --opi: record # shape: {enablePayAtTable?: bool, payAtTableStoreNumber?: string, payAtTableURL?: string}
  --passcodes: record # shape: {adminMenuPin?: string, refundPin?: string, screenLockPin?: string, txMenuPin?: string}
  --payAtTable: record # shape: {authenticationMethod?: "MAGSWIPE"|"MKE", enablePayAtTable?: bool}
  --payment: record # shape: {hideMinorUnitsInCurrencies?: list}
  --receiptOptions: record # shape: {logo?: string, qrCodeData?: string}
  --receiptPrinting: record # shape: {merchantApproved?: bool, merchantCancelled?: bool, merchantCaptureApproved?: bool, merchantCaptureRefused?: bool, merchantRefundApproved?: bool, merchantRefundRefused?: bool, merchantRefused?: bool, merchantVoid?: bool, shopperApproved?: bool, shopperCancelled?: bool, shopperCaptureApproved?: bool, shopperCaptureRefused?: bool, shopperRefundApproved?: bool, shopperRefundRefused?: bool, shopperRefused?: bool, shopperVoid?: bool}
  --signature: record # shape: {askSignatureOnScreen?: bool, deviceName?: string, deviceSlogan?: string, skipSignature?: bool}
  --standalone: record # shape: {currencyCode?: string, enableStandalone?: bool}
  --surcharge: record # shape: {askConfirmation?: bool, configurations?: list}
  --timeouts: record # shape: {fromActiveToSleep?: int}
  --wifiProfiles: record # shape: {profiles?: list, settings?: record}
]: any -> record<cardholderReceipt: record<headerForAuthorizedReceipt: string>, connectivity: record<simcardStatus: string>, gratuities: table<allowCustomAmount: bool, currency: string, predefinedTipEntries: list, usePredefinedTipEntries: bool>, hardware: record<displayMaximumBackLight: int>, nexo: record<displayUrls: record<localUrls: list, publicUrls: list>, encryptionKey: record<identifier: string, passphrase: string, version: int>, eventUrls: record<eventLocalUrls: list, eventPublicUrls: list>, nexoEventUrls: list<string>>, offlineProcessing: record<chipFloorLimit: int, offlineSwipeLimits: list<record>>, opi: record<enablePayAtTable: bool, payAtTableStoreNumber: string, payAtTableURL: string>, passcodes: record<adminMenuPin: string, refundPin: string, screenLockPin: string, txMenuPin: string>, payAtTable: record<authenticationMethod: string, enablePayAtTable: bool>, payment: record<hideMinorUnitsInCurrencies: list<string>>, receiptOptions: record<logo: string, qrCodeData: string>, receiptPrinting: record<merchantApproved: bool, merchantCancelled: bool, merchantCaptureApproved: bool, merchantCaptureRefused: bool, merchantRefundApproved: bool, merchantRefundRefused: bool, merchantRefused: bool, merchantVoid: bool, shopperApproved: bool, shopperCancelled: bool, shopperCaptureApproved: bool, shopperCaptureRefused: bool, shopperRefundApproved: bool, shopperRefundRefused: bool, shopperRefused: bool, shopperVoid: bool>, signature: record<askSignatureOnScreen: bool, deviceName: string, deviceSlogan: string, skipSignature: bool>, standalone: record<currencyCode: string, enableStandalone: bool>, surcharge: record<askConfirmation: bool, configurations: list<record>>, timeouts: record<fromActiveToSleep: int>, wifiProfiles: record<profiles: list<record>, settings: record<band: string, roaming: bool, timeout: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminals/($terminalId)/terminalSettings")
  let body = {cardholderReceipt: $cardholderReceipt, connectivity: $connectivity, gratuities: $gratuities, hardware: $hardware, nexo: $nexo, offlineProcessing: $offlineProcessing, opi: $opi, passcodes: $passcodes, payAtTable: $payAtTable, payment: $payment, receiptOptions: $receiptOptions, receiptPrinting: $receiptPrinting, signature: $signature, standalone: $standalone, surcharge: $surcharge, timeouts: $timeouts, wifiProfiles: $wifiProfiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
