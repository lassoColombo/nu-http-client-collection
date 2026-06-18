# Auto-generated client for BillingManagementClient v2019-10-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/billing/2019-10-01-preview/swagger.json
# Auth: --token flag or $env.BILLINGMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BILLINGMANAGEMENTCLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-billing-billing-accounts list" } } | get name | first)
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

# Lists all billing accounts for a user which he has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts
# operationId: BillingAccounts_List
export def "providers-microsoft-billing-billing-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the address, invoiceSections and billingProfiles.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Billing/billingAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the billing account by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}
# operationId: BillingAccounts_Get
export def "providers-microsoft-billing-billing-accounts get" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the address, invoiceSections and billingProfiles.
]: nothing -> record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, agreementType: string, billingProfiles: list<record>, customerType: string, departments: list<record>, displayName: string, enrollmentAccounts: list<record>, enrollmentDetails: record<billingCycle: string, channel: string, countryCode: string, currency: string, endDate: string, language: string, policies: record, startDate: string, status: string>, organizationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to update a billing account.
#
# PATCH /providers/Microsoft.Billing/billingAccounts/{billingAccountName}
# operationId: BillingAccounts_Update
# --properties shape: {address?: any, billingProfiles?: list, departments?: list, enrollmentAccounts?: list, enrollmentDetails?: any}
export def "providers-microsoft-billing-billing-accounts update" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --properties: any # The properties of the billing account. — shape: {address?: any, billingProfiles?: list, departments?: list, enrollmentAccounts?: list, enrollmentDetails?: any}
]: any -> record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, agreementType: string, billingProfiles: list<record>, customerType: string, departments: list<record>, displayName: string, enrollmentAccounts: list<record>, enrollmentDetails: record<billingCycle: string, channel: string, countryCode: string, currency: string, endDate: string, language: string, policies: record, startDate: string, status: string>, organizationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all agreements for a billing account.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/agreements
# operationId: Agreements_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-agreements list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the participants.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/agreements") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the agreement by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/agreements/{agreementName}
# operationId: Agreements_Get
export def "providers-microsoft-billing-billing-accounts-agreements get" [
  billing_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the participants.
]: nothing -> record<properties: record<agreementLink: string, effectiveDate: string, expirationDate: string, participants: list<record>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/agreements/{agreement_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all billing permissions for the caller under a billing account.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingPermissions
# operationId: BillingPermissions_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-billing-permissions list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<actions: list, notActions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingPermissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all billing profiles for a user which that user has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles
# operationId: BillingProfiles_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-billing-profiles list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the invoiceSections.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the billing profile by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}
# operationId: BillingProfiles_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles get" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the invoiceSections.
]: nothing -> record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to update a billing profile.
#
# PATCH /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}
# operationId: BillingProfiles_Update
# --properties shape: {address?: any, displayName?: string, enabledAzurePlans?: list, invoiceEmailOptIn?: bool, invoiceSections?: list, poNumber?: string}
export def "providers-microsoft-billing-billing-accounts-billing-profiles update" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --properties: any # The properties of the billing profile. — shape: {address?: any, displayName?: string, enabledAzurePlans?: list, invoiceEmailOptIn?: bool, invoiceSections?: list, poNumber?: string}
]: any -> record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# The operation to create a BillingProfile.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}
# operationId: BillingProfiles_Create
# --address shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, city?: string, companyName?: string, country?: string, firstName?: string, lastName?: string, postalCode?: string, region?: string}
# --enabledAzurePlans item shape: {skuId?: string}
export def "providers-microsoft-billing-billing-accounts-billing-profiles create" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --address: any # Address details. — shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, city?: string, companyName?: string, country?: string, firstName?: string, lastName?: string, postalCode?: string, region?: string}
  --display-name: string # The billing profile name.
  --enabled-azure-plans: list # Enabled azure plans for this billing profile. — item shape: {skuId?: string}
  --invoice-email-opt-in: oneof<nothing, bool> # If the billing profile is opted in to receive invoices via email.
  --po-number: string # Purchase order number.
]: any -> record<properties: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, currency: string, displayName: string, enabledAzurePlans: list<record>, invoiceDay: int, invoiceEmailOptIn: bool, invoiceSections: list<record>, poNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}") $qp)
  let req_body = {"address": $address, "displayName": $display_name, "enabledAzurePlans": $enabled_azure_plans, "invoiceEmailOptIn": $invoice_email_opt_in, "poNumber": $po_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# The latest available credit balance for a given billingAccountName and billingProfileName.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/availableBalance/default
# operationId: AvailableBalances_GetByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-available-balance-default get" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<amount: record<currency: string, value: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/availableBalance/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all billing permissions the caller has for a billing account.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingPermissions
# operationId: BillingPermissions_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-billing-permissions list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<actions: list, notActions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/billingPermissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the role assignments on the Billing Profile
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments
# operationId: BillingRoleAssignments_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-billing-role-assignments list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/billingRoleAssignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete the role assignment on this Billing Profile
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments/{billingRoleAssignmentName}
# operationId: BillingRoleAssignments_DeleteByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-billing-role-assignments delete" [
  billing_account_name: string
  billing_profile_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), billing_role_assignment_name: (encode-path-segment $billing_role_assignment_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/billingRoleAssignments/{billing_role_assignment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the role assignment for the caller on the Billing Profile
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleAssignments/{billingRoleAssignmentName}
# operationId: BillingRoleAssignments_GetByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-billing-role-assignments get" [
  billing_account_name: string
  billing_profile_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), billing_role_assignment_name: (encode-path-segment $billing_role_assignment_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/billingRoleAssignments/{billing_role_assignment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the role definition for a Billing Profile
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleDefinitions
# operationId: BillingRoleDefinitions_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-billing-role-definitions list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/billingRoleDefinitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the role definition for a role
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingRoleDefinitions/{billingRoleDefinitionName}
# operationId: BillingRoleDefinitions_GetByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-billing-role-definitions get" [
  billing_account_name: string
  billing_profile_name: string
  billing_role_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<description: string, permissions: list<record>, roleName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), billing_role_definition_name: (encode-path-segment $billing_role_definition_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/billingRoleDefinitions/{billing_role_definition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists billing subscriptions by billing profile name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/billingSubscriptions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: BillingSubscriptions_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-billing-subscriptions list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/billingSubscriptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to add a role assignment to a billing profile.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/createBillingRoleAssignment
# operationId: BillingRoleAssignments_AddByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-create-billing-role-assignment create" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --billing-role-definition-id: string # The role definition id
  --principal-id: string # The user's principal id that the role gets assigned to
]: any -> record<value: table<properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/createBillingRoleAssignment") $qp)
  let req_body = {"billingRoleDefinitionId": $billing_role_definition_id, "principalId": $principal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists customers by billing profile which the current user can work with on-behalf of a partner.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers
# operationId: Customers_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-customers list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --filter: string # May be used to filter the list of customers.
  --skiptoken: string # Skiptoken is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skiptoken parameter that specifies a starting point to use for subsequent calls.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/customers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Initiates the request to transfer the legacy subscriptions or RIs.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/initiateTransfer
# operationId: PartnerTransfers_Initiate
# --properties shape: {recipientEmailId?: string, resellerId?: string}
export def "providers-microsoft-billing-billing-accounts-billing-profiles-customers-initiate-transfer create-partner" [
  billing_account_name: string
  billing_profile_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Request parameters to initiate transfer. — shape: {recipientEmailId?: string, resellerId?: string}
]: any -> record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/customers/{customer_name}/initiateTransfer"))
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all transfer's details initiated from given invoice section.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers
# operationId: PartnerTransfers_List
export def "providers-microsoft-billing-billing-accounts-billing-profiles-customers-transfers list-partner" [
  billing_account_name: string
  billing_profile_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/customers/{customer_name}/transfers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Cancels the transfer for given transfer Id.
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers/{transferName}
# operationId: PartnerTransfers_Cancel
export def "providers-microsoft-billing-billing-accounts-billing-profiles-customers-transfers cancel-partner" [
  billing_account_name: string
  billing_profile_name: string
  customer_name: string
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), customer_name: (encode-path-segment $customer_name), transfer_name: (encode-path-segment $transfer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/customers/{customer_name}/transfers/{transfer_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the transfer details for given transfer Id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/customers/{customerName}/transfers/{transferName}
# operationId: PartnerTransfers_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles-customers-transfers get-partner" [
  billing_account_name: string
  billing_profile_name: string
  customer_name: string
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), customer_name: (encode-path-segment $customer_name), transfer_name: (encode-path-segment $transfer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/customers/{customer_name}/transfers/{transfer_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the instructions by billing profile id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Instructions_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-instructions list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/instructions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the instruction by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions/{instructionName}
# operationId: Instructions_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles-instructions get" [
  billing_account_name: string
  billing_profile_name: string
  instruction_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<amount: float, endDate: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), instruction_name: (encode-path-segment $instruction_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/instructions/{instruction_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to create or update a instruction.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/instructions/{instructionName}
# operationId: Instructions_Put
# --properties shape: {amount: float, endDate: string, startDate: string}
export def "providers-microsoft-billing-billing-accounts-billing-profiles-instructions update" [
  billing_account_name: string
  billing_profile_name: string
  instruction_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --properties: any # A billing instruction used during invoice generation. — shape: {amount: float, endDate: string, startDate: string}
]: any -> record<properties: record<amount: float, endDate: string, startDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), instruction_name: (encode-path-segment $instruction_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/instructions/{instruction_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all invoice sections for a user which he has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections
# operationId: InvoiceSections_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the InvoiceSection by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}
# operationId: InvoiceSections_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<displayName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to update a InvoiceSection.
#
# PATCH /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}
# operationId: InvoiceSections_Update
# --properties shape: {displayName?: string}
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections update" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --properties: any # The properties of an InvoiceSection. — shape: {displayName?: string}
]: any -> record<properties: record<displayName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# The operation to create an invoice section.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}
# operationId: InvoiceSections_Create
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections create" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --display-name: string # The name of the InvoiceSection.
]: any -> record<properties: record<displayName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}") $qp)
  let req_body = {"displayName": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all billing permissions for the caller under invoice section.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingPermissions
# operationId: BillingPermissions_ListByInvoiceSections
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-permissions list" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<actions: list, notActions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingPermissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the role assignments on the invoice Section
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments
# operationId: BillingRoleAssignments_ListByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-role-assignments list" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingRoleAssignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete the role assignment on the invoice Section
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments/{billingRoleAssignmentName}
# operationId: BillingRoleAssignments_DeleteByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-role-assignments delete" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), billing_role_assignment_name: (encode-path-segment $billing_role_assignment_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingRoleAssignments/{billing_role_assignment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the role assignment for the caller on the invoice Section
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleAssignments/{billingRoleAssignmentName}
# operationId: BillingRoleAssignments_GetByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-role-assignments get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), billing_role_assignment_name: (encode-path-segment $billing_role_assignment_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingRoleAssignments/{billing_role_assignment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the role definition for an invoice Section
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleDefinitions
# operationId: BillingRoleDefinitions_ListByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-role-definitions list" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingRoleDefinitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the role definition for a role
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingRoleDefinitions/{billingRoleDefinitionName}
# operationId: BillingRoleDefinitions_GetByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-role-definitions get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_role_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<description: string, permissions: list<record>, roleName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), billing_role_definition_name: (encode-path-segment $billing_role_definition_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingRoleDefinitions/{billing_role_definition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists billing subscription by invoice section name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: BillingSubscriptions_ListByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-subscriptions list" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingSubscriptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single billing subscription by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: BillingSubscriptions_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-subscriptions get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastMonthCharges: record<currency: string, value: float>, monthToDateCharges: record<currency: string, value: float>, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, subscriptionBillingStatus: string, subscriptionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), billing_subscription_name: (encode-path-segment $billing_subscription_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingSubscriptions/{billing_subscription_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Transfers the subscription from one invoice section to another within a billing account.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}/transfer
# operationId: BillingSubscriptions_Transfer
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-subscriptions-transfer create" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination-billing-profile-id: string # The destination billing profile id.
  --destination-invoice-section-id: string # The destination invoice section id.
]: any -> record<properties: record<billingSubscriptionName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), billing_subscription_name: (encode-path-segment $billing_subscription_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingSubscriptions/{billing_subscription_name}/transfer"))
  let req_body = {"destinationBillingProfileId": $destination_billing_profile_id, "destinationInvoiceSectionId": $destination_invoice_section_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Validates the transfer of billing subscriptions across invoice sections.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/billingSubscriptions/{billingSubscriptionName}/validateTransferEligibility
# operationId: BillingSubscriptions_ValidateTransfer
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-billing-subscriptions-validate-transfer-eligibility validate" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination-billing-profile-id: string # The destination billing profile id.
  --destination-invoice-section-id: string # The destination invoice section id.
]: any -> record<errorDetails: record<code: string, details: string, message: string>, isTransferEligible: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), billing_subscription_name: (encode-path-segment $billing_subscription_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/billingSubscriptions/{billing_subscription_name}/validateTransferEligibility"))
  let req_body = {"destinationBillingProfileId": $destination_billing_profile_id, "destinationInvoiceSectionId": $destination_invoice_section_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# The operation to add a role assignment to a invoice Section.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/createBillingRoleAssignment
# operationId: BillingRoleAssignments_AddByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-create-billing-role-assignment create" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --billing-role-definition-id: string # The role definition id
  --principal-id: string # The user's principal id that the role gets assigned to
]: any -> record<value: table<properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/createBillingRoleAssignment") $qp)
  let req_body = {"billingRoleDefinitionId": $billing_role_definition_id, "principalId": $principal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Elevates the caller's access to match their billing profile access.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/elevate
# operationId: InvoiceSections_ElevateToBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-elevate create" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: string, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/elevate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Initiates the request to transfer the legacy subscriptions or RIs.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/initiateTransfer
# operationId: Transfers_Initiate
# --properties shape: {recipientEmailId?: string, resellerId?: string}
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-initiate-transfer create" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Request parameters to initiate transfer. — shape: {recipientEmailId?: string, resellerId?: string}
]: any -> record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/initiateTransfer"))
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists products by invoice section name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Products_ListByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-products list" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --filter: string # May be used to filter by product type. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single product by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Products_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-products get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), product_name: (encode-path-segment $product_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/products/{product_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to transfer a Product to another invoice section.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/transfer
# operationId: Products_Transfer
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-products-transfer create" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --destination-billing-profile-id: string # The destination billing profile id.
  --destination-invoice-section-id: string # The destination invoice section id.
]: any -> record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), product_name: (encode-path-segment $product_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/products/{product_name}/transfer") $qp)
  let req_body = {"destinationBillingProfileId": $destination_billing_profile_id, "destinationInvoiceSectionId": $destination_invoice_section_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancel auto renew for product by product id and invoice section name
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/updateAutoRenew
# operationId: Products_UpdateAutoRenewByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-products-update-auto-renew update" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<endDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), product_name: (encode-path-segment $product_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/products/{product_name}/updateAutoRenew") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Validates the transfer of products across invoice sections.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/products/{productName}/validateTransferEligibility
# operationId: Products_ValidateTransfer
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-products-validate-transfer-eligibility validate" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination-billing-profile-id: string # The destination billing profile id.
  --destination-invoice-section-id: string # The destination invoice section id.
]: any -> record<errorDetails: record<code: string, details: string, message: string>, isTransferEligible: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), product_name: (encode-path-segment $product_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/products/{product_name}/validateTransferEligibility"))
  let req_body = {"destinationBillingProfileId": $destination_billing_profile_id, "destinationInvoiceSectionId": $destination_invoice_section_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the transactions by invoice section name for given start date and end date.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transactions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Transactions_ListByInvoiceSection
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-transactions list" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --period-start-date: string # Start date
  --period-end-date: string # End date
  --filter: string # May be used to filter by transaction kind. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "periodStartDate" $period_start_date "scalar") (serialize-qp "periodEndDate" $period_end_date "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all transfer's details initiated from given invoice section.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers
# operationId: Transfers_List
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-transfers list" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/transfers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Cancels the transfer for given transfer Id.
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers/{transferName}
# operationId: Transfers_Cancel
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-transfers cancel" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), transfer_name: (encode-path-segment $transfer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/transfers/{transfer_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the transfer details for given transfer Id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}/transfers/{transferName}
# operationId: Transfers_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoice-sections-transfers get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_section_name: string
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: record<billingAccountId: string, billingProfileId: string, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, invoiceSectionId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_section_name: (encode-path-segment $invoice_section_name), transfer_name: (encode-path-segment $transfer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoiceSections/{invoice_section_name}/transfers/{transfer_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List of invoices for a billing profile.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices
# operationId: Invoices_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoices list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --period-start-date: string # Invoice period start date.
  --period-end-date: string # Invoice period end date.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "periodStartDate" $period_start_date "scalar") (serialize-qp "periodEndDate" $period_end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the invoice by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices/{invoiceName}
# operationId: Invoices_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoices get" [
  billing_account_name: string
  billing_profile_name: string
  invoice_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<amountDue: record<currency: string, value: float>, billedAmount: record<currency: string, value: float>, billingProfileDisplayName: string, billingProfileId: string, documents: list<record>, dueDate: string, invoiceDate: string, invoicePeriodEndDate: string, invoicePeriodStartDate: string, invoiceType: any, payments: list<record>, purchaseOrderNumber: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_name: (encode-path-segment $invoice_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoices/{invoice_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download price sheet for an invoice.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoices/{invoiceName}/pricesheet/default/download
# operationId: PriceSheet_Download
export def "providers-microsoft-billing-billing-accounts-billing-profiles-invoices-pricesheet-default-download download-price-sheet" [
  billing_account_name: string
  billing_profile_name: string
  invoice_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<expiryTime: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), invoice_name: (encode-path-segment $invoice_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/invoices/{invoice_name}/pricesheet/default/download") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the Payment Methods by billing profile Id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/paymentMethods
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: PaymentMethods_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-payment-methods list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/paymentMethods") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The policy for a given billing account name and billing profile name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/policies/default
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Policies_GetByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-policies-default get" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<marketplacePurchases: string, reservationPurchases: string, viewCharges: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/policies/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to update a policy.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/policies/default
# operationId: Policies_Update
# --properties shape: {marketplacePurchases?: "AllAllowed"|"OnlyFreeAllowed"|"NotAllowed", reservationPurchases?: "Allowed"|"NotAllowed", viewCharges?: "Allowed"|"NotAllowed"}
export def "providers-microsoft-billing-billing-accounts-billing-profiles-policies-default update" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --properties: any # The properties of policy. — shape: {marketplacePurchases?: "AllAllowed"|"OnlyFreeAllowed"|"NotAllowed", reservationPurchases?: "Allowed"|"NotAllowed", viewCharges?: "Allowed"|"NotAllowed"}
]: any -> record<properties: record<marketplacePurchases: string, reservationPurchases: string, viewCharges: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/policies/default") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Download price sheet for a billing profile.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/pricesheet/default/download
# operationId: PriceSheet_DownloadByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-pricesheet-default-download download-price-sheet" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<expiryTime: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/pricesheet/default/download") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the transactions by billing profile name for given start date and end date.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/transactions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Transactions_ListByBillingProfile
export def "providers-microsoft-billing-billing-accounts-billing-profiles-transactions list" [
  billing_account_name: string
  billing_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --period-start-date: string # Start date
  --period-end-date: string # End date
  --filter: string # May be used to filter by transaction kind. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "periodStartDate" $period_start_date "scalar") (serialize-qp "periodEndDate" $period_end_date "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the transaction.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/transactions/{transactionName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Transactions_Get
export def "providers-microsoft-billing-billing-accounts-billing-profiles-transactions get" [
  billing_account_name: string
  billing_profile_name: string
  transaction_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-start-date: string # Start date
  --period-end-date: string # End date
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, date: string, invoice: string, invoiceSectionDisplayName: string, invoiceSectionId: string, kind: string, orderId: string, orderName: string, productDescription: string, productFamily: string, productType: string, productTypeId: string, quantity: int, subscriptionId: string, subscriptionName: string, transactionAmount: record<currency: string, value: float>, transactionType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodStartDate" $period_start_date "scalar") (serialize-qp "periodEndDate" $period_end_date "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_profile_name: (encode-path-segment $billing_profile_name), transaction_name: (encode-path-segment $transaction_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingProfiles/{billing_profile_name}/transactions/{transaction_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the role assignments on the Billing Account
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments
# operationId: BillingRoleAssignments_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-billing-role-assignments list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingRoleAssignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete the role assignment on this billing account
#
# DELETE /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments/{billingRoleAssignmentName}
# operationId: BillingRoleAssignments_DeleteByBillingAccount
export def "providers-microsoft-billing-billing-accounts-billing-role-assignments delete" [
  billing_account_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_role_assignment_name: (encode-path-segment $billing_role_assignment_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingRoleAssignments/{billing_role_assignment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the role assignment for the caller
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleAssignments/{billingRoleAssignmentName}
# operationId: BillingRoleAssignments_GetByBillingAccount
export def "providers-microsoft-billing-billing-accounts-billing-role-assignments get" [
  billing_account_name: string
  billing_role_assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<createdByPrincipalId: string, createdByPrincipalTenantId: string, createdOn: string, name: string, principalId: string, roleDefinitionName: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_role_assignment_name: (encode-path-segment $billing_role_assignment_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingRoleAssignments/{billing_role_assignment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the role definition for a billing account
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleDefinitions
# operationId: BillingRoleDefinitions_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-billing-role-definitions list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingRoleDefinitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the role definition for a role
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingRoleDefinitions/{billingRoleDefinitionName}
# operationId: BillingRoleDefinitions_GetByBillingAccount
export def "providers-microsoft-billing-billing-accounts-billing-role-definitions get" [
  billing_account_name: string
  billing_role_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<description: string, permissions: list<record>, roleName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_role_definition_name: (encode-path-segment $billing_role_definition_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingRoleDefinitions/{billing_role_definition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists billing subscriptions by billing account name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: BillingSubscriptions_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-billing-subscriptions list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingSubscriptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists invoices by billing subscriptions name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions/{billingSubscriptionName}/invoices
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Invoices_ListByBillingSubscription
export def "providers-microsoft-billing-billing-accounts-billing-subscriptions-invoices list" [
  billing_account_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-start-date: string # Invoice period start date.
  --period-end-date: string # Invoice period end date.
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodStartDate" $period_start_date "scalar") (serialize-qp "periodEndDate" $period_end_date "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_subscription_name: (encode-path-segment $billing_subscription_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingSubscriptions/{billing_subscription_name}/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the invoice by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/billingSubscriptions/{billingSubscriptionName}/invoices/{invoiceName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Invoices_GetById
export def "providers-microsoft-billing-billing-accounts-billing-subscriptions-invoices get" [
  billing_account_name: string
  billing_subscription_name: string
  invoice_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<amountDue: record<currency: string, value: float>, billedAmount: record<currency: string, value: float>, billingProfileDisplayName: string, billingProfileId: string, documents: list<record>, dueDate: string, invoiceDate: string, invoicePeriodEndDate: string, invoicePeriodStartDate: string, invoiceType: any, payments: list<record>, purchaseOrderNumber: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), billing_subscription_name: (encode-path-segment $billing_subscription_name), invoice_name: (encode-path-segment $invoice_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/billingSubscriptions/{billing_subscription_name}/invoices/{invoice_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to add a role assignment to a billing account.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/createBillingRoleAssignment
# operationId: BillingRoleAssignments_AddByBillingAccount
export def "providers-microsoft-billing-billing-accounts-create-billing-role-assignment create" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --billing-role-definition-id: string # The role definition id
  --principal-id: string # The user's principal id that the role gets assigned to
]: any -> record<value: table<properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/createBillingRoleAssignment") $qp)
  let req_body = {"billingRoleDefinitionId": $billing_role_definition_id, "principalId": $principal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists customers which the current user can work with on-behalf of a partner.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers
# operationId: Customers_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-customers list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --filter: string # May be used to filter the list of customers.
  --skiptoken: string # Skiptoken is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skiptoken parameter that specifies a starting point to use for subsequent calls.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a customer by its id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}
# operationId: Customers_Get
export def "providers-microsoft-billing-billing-accounts-customers get" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand enabledAzurePlans, resellers.
]: nothing -> record<properties: record<displayName: string, enabledAzurePlans: list<record>, resellers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all billing permissions the caller has for a customer.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingPermissions
# operationId: BillingPermissions_ListByCustomer
export def "providers-microsoft-billing-billing-accounts-customers-billing-permissions list" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<value: table<actions: list, notActions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}/billingPermissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists billing subscription by customer id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingSubscriptions
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: BillingSubscriptions_ListByCustomer
export def "providers-microsoft-billing-billing-accounts-customers-billing-subscriptions list" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}/billingSubscriptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single billing subscription by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/billingSubscriptions/{billingSubscriptionName}
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: BillingSubscriptions_GetByCustomer
export def "providers-microsoft-billing-billing-accounts-customers-billing-subscriptions get" [
  billing_account_name: string
  customer_name: string
  billing_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastMonthCharges: record<currency: string, value: float>, monthToDateCharges: record<currency: string, value: float>, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, subscriptionBillingStatus: string, subscriptionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name), billing_subscription_name: (encode-path-segment $billing_subscription_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}/billingSubscriptions/{billing_subscription_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The policy for a given billing account name and customer name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/policies/default
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Policies_GetByCustomer
export def "providers-microsoft-billing-billing-accounts-customers-policies-default get" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<viewCharges: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}/policies/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# The operation to update a Customer policy.
#
# PUT /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/policies/default
# operationId: Policies_UpdateCustomer
# --properties shape: {viewCharges?: "Allowed"|"NotAllowed"}
export def "providers-microsoft-billing-billing-accounts-customers-policies-default update" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --properties: any # The properties of a Customer's policy. — shape: {viewCharges?: "Allowed"|"NotAllowed"}
]: any -> record<properties: record<viewCharges: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}/policies/default") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists products by customer id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/products
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Products_ListByCustomer
export def "providers-microsoft-billing-billing-accounts-customers-products list" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --filter: string # May be used to filter by product type. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a customer's product by name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/products/{productName}
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Products_GetByCustomer
export def "providers-microsoft-billing-billing-accounts-customers-products get" [
  billing_account_name: string
  customer_name: string
  product_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<availabilityId: string, billingFrequency: string, billingProfileDisplayName: string, billingProfileId: string, customerDisplayName: string, customerId: string, displayName: string, endDate: string, invoiceSectionDisplayName: string, invoiceSectionId: string, lastCharge: record<currency: string, value: float>, lastChargeDate: string, parentProductId: string, productType: string, productTypeId: string, purchaseDate: string, quantity: float, reseller: record<description: string, resellerId: string>, skuDescription: string, skuId: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name), product_name: (encode-path-segment $product_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}/products/{product_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the transactions by customer id for given start date and end date.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/customers/{customerName}/transactions
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Transactions_ListByCustomer
export def "providers-microsoft-billing-billing-accounts-customers-transactions list" [
  billing_account_name: string
  customer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --period-start-date: string # Start date
  --period-end-date: string # End date
  --filter: string # May be used to filter by transaction kind. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "periodStartDate" $period_start_date "scalar") (serialize-qp "periodEndDate" $period_end_date "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), customer_name: (encode-path-segment $customer_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/customers/{customer_name}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all departments for a user which he has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/departments
# operationId: Departments_ListByBillingAccountName
export def "providers-microsoft-billing-billing-accounts-departments list-by-name" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the enrollmentAccounts.
  --filter: string # The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/departments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the department by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/departments/{departmentName}
# operationId: Departments_Get
export def "providers-microsoft-billing-billing-accounts-departments get" [
  billing_account_name: string
  department_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the enrollmentAccounts.
  --filter: string # The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<properties: record<costCenter: string, departmentName: string, enrollmentAccounts: list<record>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), department_name: (encode-path-segment $department_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/departments/{department_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all Enrollment Accounts for a user which he has access to.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/enrollmentAccounts
# operationId: EnrollmentAccounts_ListByBillingAccountName
export def "providers-microsoft-billing-billing-accounts-enrollment-accounts list-by-name" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the department.
  --filter: string # The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/enrollmentAccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the enrollment account by id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/enrollmentAccounts/{enrollmentAccountName}
# operationId: EnrollmentAccounts_GetByEnrollmentAccountId
export def "providers-microsoft-billing-billing-accounts-enrollment-accounts get" [
  billing_account_name: string
  enrollment_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --expand: string # May be used to expand the Department.
  --filter: string # The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<properties: record<accountName: string, accountOwner: string, costCenter: string, department: record<properties: record>, endDate: string, startDate: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name), enrollment_account_name: (encode-path-segment $enrollment_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/enrollmentAccounts/{enrollment_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List of invoices for a billing account.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/invoices
# operationId: Invoices_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-invoices list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --period-start-date: string # Invoice period start date.
  --period-end-date: string # Invoice period end date.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "periodStartDate" $period_start_date "scalar") (serialize-qp "periodEndDate" $period_end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all invoice sections with create subscription permission for a user.
#
# POST /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/listInvoiceSectionsWithCreateSubscriptionPermission
# operationId: BillingAccounts_ListInvoiceSectionsByCreateSubscriptionPermission
export def "providers-microsoft-billing-billing-accounts-list-invoice-sections-with-create-subscription-permission list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<billingProfileDisplayName: string, billingProfileId: string, enabledAzurePlans: list, invoiceSectionDisplayName: string, invoiceSectionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/listInvoiceSectionsWithCreateSubscriptionPermission") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the Payment Methods by billing account Id.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/paymentMethods
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/2019-10-01-preview/paymentmethods
# operationId: PaymentMethods_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-payment-methods list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/paymentMethods") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists products by billing account name.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/products
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Products_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-products list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --filter: string # May be used to filter by product type. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the transactions by billing account name for given start and end date.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountName}/transactions
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: Transactions_ListByBillingAccount
export def "providers-microsoft-billing-billing-accounts-transactions list" [
  billing_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --period-start-date: string # Start date
  --period-end-date: string # End date
  --filter: string # May be used to filter by transaction kind. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "periodStartDate" $period_start_date "scalar") (serialize-qp "periodEndDate" $period_end_date "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_name: (encode-path-segment $billing_account_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_name}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all of the available billing REST API operations.
#
# GET /providers/Microsoft.Billing/operations
# operationId: Operations_List
export def "providers-microsoft-billing-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Billing/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the transfers received by caller.
#
# GET /providers/Microsoft.Billing/transfers
# operationId: RecipientTransfers_List
export def "providers-microsoft-billing-transfers list-recipient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/providers/Microsoft.Billing/transfers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the transfer with given transfer Id.
#
# GET /providers/Microsoft.Billing/transfers/{transferName}
# operationId: RecipientTransfers_Get
export def "providers-microsoft-billing-transfers get-recipient" [
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transfer_name: (encode-path-segment $transfer_name)} | format pattern "/providers/Microsoft.Billing/transfers/{transfer_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Accepts the transfer with given transfer Id.
#
# POST /providers/Microsoft.Billing/transfers/{transferName}/acceptTransfer
# operationId: RecipientTransfers_Accept
# --properties shape: {productDetails?: list}
export def "providers-microsoft-billing-transfers-accept-transfer create-recipient" [
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Request parameters to accept transfer. — shape: {productDetails?: list}
]: any -> record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transfer_name: (encode-path-segment $transfer_name)} | format pattern "/providers/Microsoft.Billing/transfers/{transfer_name}/acceptTransfer"))
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Declines the transfer with given transfer Id.
#
# POST /providers/Microsoft.Billing/transfers/{transferName}/declineTransfer
# operationId: RecipientTransfers_Decline
export def "providers-microsoft-billing-transfers-decline-transfer create-recipient" [
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: record<allowedProductType: list<string>, canceledBy: string, creationTime: string, detailedTransferStatus: list<record>, expirationTime: string, initiatorCustomerType: string, initiatorEmailId: string, lastModifiedTime: string, recipientEmailId: string, resellerId: string, resellerName: string, transferStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transfer_name: (encode-path-segment $transfer_name)} | format pattern "/providers/Microsoft.Billing/transfers/{transfer_name}/declineTransfer"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Validates if the products can be transferred in the context of the given transfer name.
#
# POST /providers/Microsoft.Billing/transfers/{transferName}/validateTransfer
# operationId: RecipientTransfers_Validate
# --properties shape: {productDetails?: list}
export def "providers-microsoft-billing-transfers-validate-transfer validate-recipient" [
  transfer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # Request parameters to accept transfer. — shape: {productDetails?: list}
]: any -> record<value: table<properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transfer_name: (encode-path-segment $transfer_name)} | format pattern "/providers/Microsoft.Billing/transfers/{transfer_name}/validateTransfer"))
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Validates the address.
#
# POST /providers/Microsoft.Billing/validateAddress
# operationId: Address_Validate
export def "providers-microsoft-billing-validate-address validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --address-line1: string # Address Line1.
  --address-line2: string # Address Line2.
  --address-line3: string # Address Line3.
  --city: string # Address City.
  --company-name: string # Company Name.
  --country: string # Country code uses ISO2, 2-digit format.
  --first-name: string # First Name.
  --last-name: string # Last Name.
  --postal-code: string # Address Postal Code.
  --region: string # Address Region.
]: any -> record<status: string, suggestedAddresses: table<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, country: string, firstName: string, lastName: string, postalCode: string, region: string>, validationMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Billing/validateAddress" $qp)
  let req_body = {"addressLine1": $address_line1, "addressLine2": $address_line2, "addressLine3": $address_line3, "city": $city, "companyName": $company_name, "country": $country, "firstName": $first_name, "lastName": $last_name, "postalCode": $postal_code, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get the current line of credit.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingAccounts/default/lineOfCredit/default
# operationId: LineOfCredits_Get
export def "subscriptions-providers-microsoft-billing-billing-accounts-default-line-of-credit-default get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<creditLimit: record<currency: string, value: float>, reason: string, remainingBalance: record<currency: string, value: float>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Billing/billingAccounts/default/lineOfCredit/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Increase the current line of credit.
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingAccounts/default/lineOfCredit/default
# operationId: LineOfCredits_Update
# --properties shape: {creditLimit?: any, remainingBalance?: any, status?: "Approved"|"Rejected"}
export def "subscriptions-providers-microsoft-billing-billing-accounts-default-line-of-credit-default update" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
  --properties: any # The properties of the line of credit. — shape: {creditLimit?: any, remainingBalance?: any, status?: "Approved"|"Rejected"}
]: any -> record<properties: record<creditLimit: record<currency: string, value: float>, reason: string, remainingBalance: record<currency: string, value: float>, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Billing/billingAccounts/default/lineOfCredit/default") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get billing property by subscription Id.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingProperty/default
# Docs: https://docs.microsoft.com/en-us/rest/api/billing/
# operationId: BillingProperty_Get
export def "subscriptions-providers-microsoft-billing-billing-property-default get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-10-01-preview.
]: nothing -> record<properties: record<billingAccountDisplayName: string, billingAccountId: string, billingProfileDisplayName: string, billingProfileId: string, billingTenantId: string, costCenter: string, invoiceSectionDisplayName: string, invoiceSectionId: string, productId: string, productName: string, skuDescription: string, skuId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Billing/billingProperty/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
