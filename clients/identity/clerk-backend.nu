# Auto-generated client for Clerk Backend API v2026-05-12
# Source: https://raw.githubusercontent.com/clerk/openapi-specs/main/bapi/2026-05-12.yml
# Auth: --token flag or $env.CLERK_BACKEND_API_TOKEN

const BASE_URL = "https://api.clerk.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLERK_BACKEND_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.clerk.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def identification-status-completer [] { ["reserved" "verified"] }
def status-completer [] { ["abandoned" "active" "ended" "expired" "removed" "replaced" "revoked"] }
def format-completer [] { ["cookie" "token"] }
def action-completer [] { ["decrease" "increase"] }
def status-completer-1 [] { ["accepted" "expired" "pending" "revoked"] }
def template-slug-completer [] { ["invitation" "waitlist_invitation"] }
def is-satellite-completer [] { ["true"] }
def preferred-sign-in-strategy-when-password-required-completer [] { ["" "otp" "password"] }
def verified-completer [] { ["false" "true"] }
def provider-completer [] { ["saml_custom" "saml_google" "saml_microsoft" "saml_okta"] }
def provider-completer-1 [] { ["oidc_custom" "oidc_github_enterprise" "oidc_gitlab" "saml_custom" "saml_google" "saml_microsoft" "saml_okta"] }
def permissions-completer [] { ["*"] }
def status-completer-2 [] { ["completed" "invited" "pending" "rejected"] }
def payer-type-completer [] { ["org" "user"] }
def supported-billing-periods-completer [] { ["annual" "both" "month"] }
def status-completer-3 [] { ["active" "ended" "free_trial" "past_due" "upcoming"] }
def type-completer [] { ["custom" "initial"] }
def type-completer-1 [] { ["initial"] }
def include-invalid-completer [] { ["false" "true"] }
def token-format-completer [] { ["jwt" "opaque"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "public-interstitial GetPublicInterstitial" } } | get name | first)
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

# Returns the markup for the interstitial page
#
# GET /public/interstitial
# operationId: GetPublicInterstitial
@deprecated --flag frontendApi
export def "public-interstitial GetPublicInterstitial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --frontendApi: string # Please use `frontend_api` instead (DEPRECATED)
  --frontend-api: string # The Frontend API key of your instance
  --publishable-key: string # The publishable key of your instance
  --proxy-url: string # The proxy URL of your instance
  --domain: string # The domain of your instance
  --sign-in-url: string # The sign in URL of your instance
  --use-domain-for-script: oneof<nothing, bool> # Whether to use the domain for the script URL
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "frontendApi" $frontendApi "scalar") (serialize-qp "frontend_api" $frontend_api "scalar") (serialize-qp "publishable_key" $publishable_key "scalar") (serialize-qp "proxy_url" $proxy_url "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "sign_in_url" $sign_in_url "scalar") (serialize-qp "use_domain_for_script" $use_domain_for_script "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/interstitial" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the JSON Web Key Set of the instance
#
# GET /jwks
# operationId: GetJWKS
export def "jwks GetJWKS" [
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
  let full_url = (build-url $base "/jwks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all clients
#
# GET /clients
# DEPRECATED
# operationId: GetClientList
@deprecated
export def "clients GetClientList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify a client
#
# POST /clients/verify
# operationId: VerifyClient
export def "clients-verify VerifyClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # A JWT that represents the active client.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clients/verify")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a client
#
# GET /clients/{client_id}
# operationId: GetClient
export def "clients GetClient" [
  client_id: string
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
  let full_url = (build-url $base $"/clients/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an email address
#
# POST /email_addresses
# operationId: CreateEmailAddress
export def "email-addresses CreateEmailAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The ID representing the user
  email_address: string # The new email address. Must adhere to the RFC 5322 specification for email address format.
  --verified: oneof<nothing, bool> # When created, the email address will be marked as verified. (nullable)
  --primary: oneof<nothing, bool> # Create this email address as the primary email address for the user. Default: false, unless it is the first email address. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email_addresses")
  let body = {user_id: $user_id, email_address: $email_address, verified: $verified, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an email address
#
# GET /email_addresses/{email_address_id}
# operationId: GetEmailAddress
export def "email-addresses GetEmailAddress" [
  email_address_id: string
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
  let full_url = (build-url $base $"/email_addresses/($email_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an email address
#
# DELETE /email_addresses/{email_address_id}
# operationId: DeleteEmailAddress
export def "email-addresses DeleteEmailAddress" [
  email_address_id: string
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
  let full_url = (build-url $base $"/email_addresses/($email_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an email address
#
# PATCH /email_addresses/{email_address_id}
# operationId: UpdateEmailAddress
export def "email-addresses UpdateEmailAddress" [
  email_address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --verified: oneof<nothing, bool> # The email address will be marked as verified. (nullable)
  --primary: oneof<nothing, bool> # Set this email address as the primary email address for the user. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/email_addresses/($email_address_id)")
  let body = {verified: $verified, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a verification code to an email address
#
# POST /email_addresses/{email_address_id}/prepare_verification
# operationId: PrepareEmailAddressVerification
export def "email-addresses-prepare-verification PrepareEmailAddressVerification" [
  email_address_id: string
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
  let full_url = (build-url $base $"/email_addresses/($email_address_id)/prepare_verification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify a code sent to an email address
#
# POST /email_addresses/{email_address_id}/attempt_verification
# operationId: AttemptEmailAddressVerification
export def "email-addresses-attempt-verification AttemptEmailAddressVerification" [
  email_address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  verification_id: string # The ID of the verification to check, such as one returned by prepare_verification
  code: string # The verification code that was sent to the email address
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/email_addresses/($email_address_id)/attempt_verification")
  let body = {verification_id: $verification_id, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace a user's email address
#
# PUT /users/{user_id}/email_address
# operationId: ReplaceUserEmailAddress
export def "users-email-address ReplaceUserEmailAddress" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email_address: string # The new email address. Must adhere to the RFC 5322 specification for email address format.
  --identification-status: string@identification-status-completer # Controls the status of the replacement email address. Defaults to `verified`. Set to `reserved` to create it reserved (unverified but usable for sign-in and locked) instead of verified. (default: verified)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/email_address")
  let body = {email_address: $email_address, identification_status: $identification_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a phone number
#
# POST /phone_numbers
# operationId: CreatePhoneNumber
export def "phone-numbers CreatePhoneNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The ID representing the user
  phone_number: string # The new phone number. Must adhere to the E.164 standard for phone number format.
  --verified: oneof<nothing, bool> # When created, the phone number will be marked as verified. (nullable)
  --primary: oneof<nothing, bool> # Create this phone number as the primary phone number for the user. Default: false, unless it is the first phone number. (nullable)
  --reserved-for-second-factor: oneof<nothing, bool> # Create this phone number as reserved for multi-factor authentication. The phone number must also be verified. If there are no other reserved second factors, the phone number will be set as the default second factor. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_numbers")
  let body = {user_id: $user_id, phone_number: $phone_number, verified: $verified, primary: $primary, reserved_for_second_factor: $reserved_for_second_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a phone number
#
# GET /phone_numbers/{phone_number_id}
# operationId: GetPhoneNumber
export def "phone-numbers GetPhoneNumber" [
  phone_number_id: string
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
  let full_url = (build-url $base $"/phone_numbers/($phone_number_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a phone number
#
# DELETE /phone_numbers/{phone_number_id}
# operationId: DeletePhoneNumber
export def "phone-numbers DeletePhoneNumber" [
  phone_number_id: string
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
  let full_url = (build-url $base $"/phone_numbers/($phone_number_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a phone number
#
# PATCH /phone_numbers/{phone_number_id}
# operationId: UpdatePhoneNumber
export def "phone-numbers UpdatePhoneNumber" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --verified: oneof<nothing, bool> # The phone number will be marked as verified. (nullable)
  --primary: oneof<nothing, bool> # Set this phone number as the primary phone number for the user. (nullable)
  --reserved-for-second-factor: oneof<nothing, bool> # Set this phone number as reserved for multi-factor authentication. The phone number must also be verified. If there are no other reserved second factors, the phone number will be set as the default second factor. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/phone_numbers/($phone_number_id)")
  let body = {verified: $verified, primary: $primary, reserved_for_second_factor: $reserved_for_second_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a verification code to a phone number
#
# POST /phone_numbers/{phone_number_id}/prepare_verification
# operationId: PreparePhoneNumberVerification
export def "phone-numbers-prepare-verification PreparePhoneNumberVerification" [
  phone_number_id: string
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
  let full_url = (build-url $base $"/phone_numbers/($phone_number_id)/prepare_verification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify a code sent to a phone number
#
# POST /phone_numbers/{phone_number_id}/attempt_verification
# operationId: AttemptPhoneNumberVerification
export def "phone-numbers-attempt-verification AttemptPhoneNumberVerification" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  verification_id: string # The ID of the verification to check, such as one returned by prepare_verification
  code: string # The verification code that was sent to the phone number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/phone_numbers/($phone_number_id)/attempt_verification")
  let body = {verification_id: $verification_id, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace a user's phone number
#
# PUT /users/{user_id}/phone_number
# operationId: ReplaceUserPhoneNumber
export def "users-phone-number ReplaceUserPhoneNumber" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # The new phone number. Must adhere to the E.164 standard for phone number format.
  --identification-status: string@identification-status-completer # Controls the status of the replacement phone number. Defaults to `verified`. Set to `reserved` to create it reserved (unverified but usable for sign-in and locked) instead of verified. (default: verified)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/phone_number")
  let body = {phone_number: $phone_number, identification_status: $identification_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all sessions
#
# GET /sessions
# operationId: GetSessionList
export def "sessions GetSessionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # List sessions for the given client
  --user-id: string # List sessions for the given user
  --status: string@status-completer # Filter sessions by the provided status
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new active session
#
# POST /sessions
# operationId: createSession
export def "sessions createSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The ID representing the user
  --active-organization-id: string # The ID of the organization to set as active for this session
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sessions")
  let body = {user_id: $user_id, active_organization_id: $active_organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a session
#
# GET /sessions/{session_id}
# operationId: GetSession
export def "sessions GetSession" [
  session_id: string
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
  let full_url = (build-url $base $"/sessions/($session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh a session
#
# POST /sessions/{session_id}/refresh
# operationId: RefreshSession
export def "sessions-refresh RefreshSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  expired_token: string # The JWT that is sent via the `__session` cookie from your frontend. Note: this JWT must be associated with the supplied session ID.
  refresh_token: string # The refresh token from the `__refresh` cookie set via FAPI's handshake flow.
  request_origin: string # The origin of the request.
  --request-headers: record # The headers of the request. (nullable)
  --format: string@format-completer # The format of the response. (nullable, default: token)
  --request-originating-ip: string # The IP address of the request. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sessions/($session_id)/refresh")
  let body = {expired_token: $expired_token, refresh_token: $refresh_token, request_origin: $request_origin, request_headers: $request_headers, format: $format, request_originating_ip: $request_originating_ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke a session
#
# POST /sessions/{session_id}/revoke
# operationId: RevokeSession
export def "sessions-revoke RevokeSession" [
  session_id: string
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
  let full_url = (build-url $base $"/sessions/($session_id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a session token
#
# POST /sessions/{session_id}/tokens
# operationId: CreateSessionToken
export def "sessions-tokens CreateSessionToken" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-in-seconds: int # Use this parameter to override the default session token lifetime. (nullable)
]: any -> record<object: string, jwt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sessions/($session_id)/tokens")
  let body = {expires_in_seconds: $expires_in_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a session token from a JWT template
#
# POST /sessions/{session_id}/tokens/{template_name}
# operationId: CreateSessionTokenFromTemplate
export def "sessions-tokens CreateSessionTokenFromTemplate" [
  session_id: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-in-seconds: int # Use this parameter to override the JWT lifetime. (nullable)
]: any -> record<object: string, jwt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sessions/($session_id)/tokens/($template_name)")
  let body = {expires_in_seconds: $expires_in_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all templates
#
# GET /templates/{template_type}
# DEPRECATED
# operationId: GetTemplateList
@deprecated
export def "templates GetTemplateList" [
  template_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($template_type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a template
#
# GET /templates/{template_type}/{slug}
# DEPRECATED
# operationId: GetTemplate
@deprecated
export def "templates GetTemplate" [
  template_type: string
  slug: string
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
  let full_url = (build-url $base $"/templates/($template_type)/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a template for a given type and slug
#
# PUT /templates/{template_type}/{slug}
# DEPRECATED
# operationId: UpsertTemplate
@deprecated
export def "templates UpsertTemplate" [
  template_type: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The user-friendly name of the template
  --subject: string # The email subject. Applicable only to email templates. (nullable)
  --markup: string # The editor markup used to generate the body of the template (nullable)
  --body-body: string # The template body before variable interpolation
  --delivered-by-clerk: oneof<nothing, bool> # Whether Clerk should deliver emails or SMS messages based on the current template (nullable)
  --from-email-name: string # The local part of the From email address that will be used for emails. For example, in the address 'hello@example.com', the local part is 'hello'. Applicable only to email templates.
  --reply-to-email-name: string # The local part of the Reply To email address that will be used for emails. For example, in the address 'hello@example.com', the local part is 'hello'. Applicable only to email templates.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_type)/($slug)")
  let body = {name: $name, subject: $subject, markup: $markup, body: $body_body, delivered_by_clerk: $delivered_by_clerk, from_email_name: $from_email_name, reply_to_email_name: $reply_to_email_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revert a template
#
# POST /templates/{template_type}/{slug}/revert
# DEPRECATED
# operationId: RevertTemplate
@deprecated
export def "templates-revert RevertTemplate" [
  template_type: string
  slug: string
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
  let full_url = (build-url $base $"/templates/($template_type)/($slug)/revert")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview changes to a template
#
# POST /templates/{template_type}/{slug}/preview
# DEPRECATED
# operationId: PreviewTemplate
@deprecated
export def "templates-preview PreviewTemplate" [
  template_type: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string # The email subject. Applicable only to email templates. (nullable)
  --body-body: string # The template body before variable interpolation
  --from-email-name: string # The local part of the From email address that will be used for emails. For example, in the address 'hello@example.com', the local part is 'hello'. Applicable only to email templates.
  --reply-to-email-name: string # The local part of the Reply To email address that will be used for emails. For example, in the address 'hello@example.com', the local part is 'hello'. Applicable only to email templates.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_type)/($slug)/preview")
  let body = {subject: $subject, body: $body_body, from_email_name: $from_email_name, reply_to_email_name: $reply_to_email_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Toggle the delivery by Clerk for a template of a given type and slug
#
# POST /templates/{template_type}/{slug}/toggle_delivery
# DEPRECATED
# operationId: ToggleTemplateDelivery
@deprecated
export def "templates-toggle-delivery ToggleTemplateDelivery" [
  template_type: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delivered-by-clerk: oneof<nothing, bool> # Whether Clerk should deliver emails or SMS messages based on the current template
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_type)/($slug)/toggle_delivery")
  let body = {delivered_by_clerk: $delivered_by_clerk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all users
#
# GET /users
# operationId: GetUserList
@deprecated --flag last-active-at-since
export def "users GetUserList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-address: list # Returns users with the specified email addresses. Accepts up to 100 email addresses. Any email addresses not found are ignored.
  --phone-number: list # Returns users with the specified phone numbers. Accepts up to 100 phone numbers. Any phone numbers not found are ignored.
  --external-id: list # Returns users with the specified external IDs. For each external ID, the `+` and `-` can be prepended to the ID, which denote whether the respective external ID should be included or excluded from the result set. Accepts up to 100 external IDs. Any external IDs not found are ignored.
  --username: list # Returns users with the specified usernames. Accepts up to 100 usernames. Any usernames not found are ignored.
  --web3-wallet: list # Returns users with the specified web3 wallet addresses. Accepts up to 100 web3 wallet addresses. Any web3 wallet addresses not found are ignored.
  --user-id: list # Returns users with the user IDs specified. For each user ID, the `+` and `-` can be prepended to the ID, which denote whether the respective user ID should be included or excluded from the result set. Accepts up to 100 user IDs. Any user IDs not found are ignored.
  --organization-id: list # Returns users that have memberships to the given organizations. For each organization ID, the `+` and `-` can be prepended to the ID, which denote whether the respective organization should be included or excluded from the result set. Accepts up to 100 organization IDs.
  --qp-query: string # Returns users that match the given query. For possible matches, we check the email addresses, phone numbers, usernames, web3 wallets, user IDs, first and last names. The query value doesn't need to match the exact value you are looking for, it is capable of partial matches as well.
  --email-address-query: string # Returns users with emails that match the given query, via case-insensitive partial match. For example, `email_address_query=ello` will match a user with the email `HELLO@example.com`.
  --phone-number-query: string # Returns users with phone numbers that match the given query, via case-insensitive partial match. For example, `phone_number_query=555` will match a user with the phone number `+1555xxxxxxx`.
  --username-query: string # Returns users with usernames that match the given query, via case-insensitive partial match. For example, `username_query=CoolUser` will match a user with the username `SomeCoolUser`.
  --name-query: string # Returns users with names that match the given query, via case-insensitive partial match.
  --banned: oneof<nothing, bool> # Returns users which are either banned (`banned=true`) or not banned (`banned=false`).
  --last-active-at-before: int # Returns users whose last session activity was before the given date (with millisecond precision). Example: use 1700690400000 to retrieve users whose last session activity was before 2023-11-23. (e.g. 1700690400000)
  --last-active-at-after: int # Returns users whose last session activity was after the given date (with millisecond precision). Example: use 1700690400000 to retrieve users whose last session activity was after 2023-11-23. (e.g. 1700690400000)
  --last-active-at-since: int # Returns users that had session activity since the given date. Example: use 1700690400000 to retrieve users that had session activity from 2023-11-23 until the current day. Deprecated in favor of `last_active_at_after`. (DEPRECATED, e.g. 1700690400000)
  --created-at-before: int # Returns users who have been created before the given date (with millisecond precision). Example: use 1730160000000 to retrieve users who have been created before 2024-10-29. (e.g. 1730160000000)
  --created-at-after: int # Returns users who have been created after the given date (with millisecond precision). Example: use 1730160000000 to retrieve users who have been created after 2024-10-29. (e.g. 1730160000000)
  --last-sign-in-at-before: int # Returns users whose last sign-in was before the given date (with millisecond precision). Example: use 1700690400000 to retrieve users whose last sign-in was before 2023-11-23. (e.g. 1700690400000)
  --last-sign-in-at-after: int # Returns users whose last sign-in was after the given date (with millisecond precision). Example: use 1700690400000 to retrieve users whose last sign-in was after 2023-11-23. (e.g. 1700690400000)
  --provider: string # Returns users with external accounts for the specified OAuth provider. Must be used in combination with the `provider_user_id` parameter. For example, use `provider=oauth_google&provider_user_id=12345` to retrieve a user with Google provider user ID 12345.
  --provider-user-id: list # Returns users with the specified provider user IDs for a specific provider. Must be used in combination with the `provider` parameter. For example, use `provider=oauth_google&provider_user_id=12345` to retrieve a user with Google provider user ID 12345. Accepts up to 100 provider user IDs. Any provider user IDs not found are ignored.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --order-by: string # Allows to return users in a particular order. At the moment, you can order the returned users by their `created_at`,`updated_at`,`email_address`,`web3wallet`,`first_name`,`last_name`,`phone_number`,`username`,`last_active_at`,`last_sign_in_at`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want users to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. We only support one `order_by` parameter, and if multiple `order_by` parameters are provided, we will only keep the first one. For example, if you pass `order_by=username&order_by=created_at`, we will consider only the first `order_by` parameter, which is `username`. The `created_at` parameter will be ignored in this case. (default: -created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email_address" $email_address "multi") (serialize-qp "phone_number" $phone_number "multi") (serialize-qp "external_id" $external_id "multi") (serialize-qp "username" $username "multi") (serialize-qp "web3_wallet" $web3_wallet "multi") (serialize-qp "user_id" $user_id "multi") (serialize-qp "organization_id" $organization_id "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "email_address_query" $email_address_query "scalar") (serialize-qp "phone_number_query" $phone_number_query "scalar") (serialize-qp "username_query" $username_query "scalar") (serialize-qp "name_query" $name_query "scalar") (serialize-qp "banned" $banned "scalar") (serialize-qp "last_active_at_before" $last_active_at_before "scalar") (serialize-qp "last_active_at_after" $last_active_at_after "scalar") (serialize-qp "last_active_at_since" $last_active_at_since "scalar") (serialize-qp "created_at_before" $created_at_before "scalar") (serialize-qp "created_at_after" $created_at_after "scalar") (serialize-qp "last_sign_in_at_before" $last_sign_in_at_before "scalar") (serialize-qp "last_sign_in_at_after" $last_sign_in_at_after "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "provider_user_id" $provider_user_id "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /users
# operationId: CreateUser
export def "users CreateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # The ID of the user as used in your external systems or your previous authentication solution. Must be unique across your instance. (nullable)
  --first-name: string # The first name to assign to the user (nullable)
  --last-name: string # The last name to assign to the user (nullable)
  --locale: string # The locale to assign to the user (e.g., "en-US", "fr-FR") (nullable)
  --email-address: list # Email addresses to add to the user. Must be unique across your instance. The first email address will be set as the user's primary email address. Created verified by default; see `email_address_identification_status` to create them reserved.
  --email-address-identification-status: list # Controls the status each email address is created with. Runs parallel to `email_address`: when provided, it must contain exactly one item per email address, applied by position. When omitted or empty, every email address is created `verified`. Set an item to `reserved` to create the corresponding email address reserved instead (unverified but usable for sign-in and locked so no other user can claim it).
  --phone-number: list # Phone numbers to add to the user. Must be unique across your instance. The first phone number will be set as the user's primary phone number. Created verified by default; see `phone_number_identification_status` to create them reserved.
  --phone-number-identification-status: list # Controls the status each phone number is created with. Runs parallel to `phone_number`: when provided, it must contain exactly one item per phone number, applied by position. When omitted or empty, every phone number is created `verified`. Set an item to `reserved` to create the corresponding phone number reserved instead (unverified but usable for sign-in and locked so no other user can claim it).
  --web3-wallet: list # Web3 wallets to add to the user. Must be unique across your instance. The first wallet will be set as the user's primary wallet.
  --username: string # The username to give to the user. It must be unique across your instance. (nullable)
  --password: string # The plaintext password to give the user. Must be at least 8 characters long, and cannot be in any list of hacked passwords. (nullable)
  --password-digest: string # In case you already have the password digests and not the passwords, you can use them for the newly created user via this property. The digests should be generated with one of the supported algorithms. The hashing algorithm can be specified using the `password_hasher` property. (nullable)
  --password-hasher: string # The hashing algorithm that was used to generate the password digest.  The algorithms we support at the moment are [`bcrypt`](https://en.wikipedia.org/wiki/Bcrypt), [`bcrypt_sha256_django`](https://docs.djangoproject.com/en/4.0/topics/auth/passwords/), [`md5`](https://en.wikipedia.org/wiki/MD5), `pbkdf2_sha1`, `pbkdf2_sha256`, [`pbkdf2_sha256_django`](https://docs.djangoproject.com/en/4.0/topics/auth/passwords/), `pbkdf2_sha512`, [`phpass`](https://www.openwall.com/phpass/), `md5_phpass`, [`scrypt_firebase`](https://firebaseopensource.com/projects/firebase/scrypt/), [`scrypt_werkzeug`](https://werkzeug.palletsprojects.com/en/3.0.x/utils/#werkzeug.security.generate_password_hash), [`sha256`](https://en.wikipedia.org/wiki/SHA-2), [`ldap_ssha`](https://www.openldap.org/faq/data/cache/347.html), the [`argon2`](https://argon2.online/) variants: `argon2i` and `argon2id`, `sha512_symfony`, the SHA-512 variant of the [Symfony](https://symfony.com/doc/current/security/passwords.html) legacy hasher, and `pbkdf2_sha512_hex`, a variant of `pbkdf2_sha512` that accepts hex-encoded salt and hash.  Each of the supported hashers expects the incoming digest to be in a particular format. See the [Clerk docs](https://clerk.com/docs/references/backend/user/create-user) for more information.
  --skip-password-checks: oneof<nothing, bool> # When set to `true` all password checks are skipped. It is recommended to use this method only when migrating plaintext passwords to Clerk. Upon migration the user base should be prompted to pick stronger password. (nullable)
  --skip-password-requirement: oneof<nothing, bool> # When set to `true`, `password` is not required anymore when creating the user and can be omitted. This is useful when you are trying to create a user that doesn't have a password, in an instance that is using passwords. Please note that you cannot use this flag if password is the only way for a user to sign into your instance. (nullable)
  --totp-secret: string # In case TOTP is configured on the instance, you can provide the secret to enable it on the newly created user without the need to reset it. Please note that currently the supported options are: * Period: 30 seconds * Code length: 6 digits * Algorithm: SHA1 (nullable)
  --backup-codes: list # If Backup Codes are configured on the instance, you can provide them to enable it on the newly created user without the need to reset them. You must provide the backup codes in plain format or the corresponding bcrypt digest.
  --public-metadata: record # Metadata saved on the user, that is visible to both your Frontend and Backend APIs
  --private-metadata: record # Metadata saved on the user, that is only visible to your Backend API
  --unsafe-metadata: record # Metadata saved on the user, that can be updated from both the Frontend and Backend APIs. Note: Since this data can be modified from the frontend, it is not guaranteed to be safe.
  --delete-self-enabled: oneof<nothing, bool> # If enabled, user can delete themselves via FAPI.  (nullable)
  --legal-accepted-at: string # A custom timestamp denoting _when_ the user accepted legal requirements, specified in RFC3339 format (e.g. `2012-10-20T07:15:20.902Z`). (nullable)
  --skip-legal-checks: oneof<nothing, bool> # When set to `true` all legal checks are skipped. It is not recommended to skip legal checks unless you are migrating a user to Clerk. (nullable)
  --skip-user-requirement: oneof<nothing, bool> # When set to `true`, identification types are not enforced. At least one identification type must be enabled and provided on your instance (email, phone, web3 wallet, or username). Users created without required identification types cannot use those authentication strategies It is not recommended to use this flag unless you need to allow Clerk UI components to prompt for required fields while BAPI creates users with minimal data, or for migration a user to Clerk. (nullable)
  --create-organization-enabled: oneof<nothing, bool> # If enabled, user can create organizations via FAPI.  (nullable)
  --create-organizations-limit: int # The maximum number of organizations the user can create. 0 means unlimited.  (nullable)
  --created-at: string # A custom date/time denoting _when_ the user signed up to the application, specified in RFC3339 format (e.g. `2012-10-20T07:15:20.902Z`). (nullable)
  --bypass-client-trust: oneof<nothing, bool> # When set to `true`, the user will bypass client trust checks during sign-in. (nullable)
  --banned: oneof<nothing, bool> # When set to `true`, the user is created already banned and cannot sign in. Requires the same plan support as the ban user endpoint. (nullable)
  --locked: oneof<nothing, bool> # When set to `true`, the user is created already locked. Requires the user lockout feature to be enabled on the instance. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {external_id: $external_id, first_name: $first_name, last_name: $last_name, locale: $locale, email_address: $email_address, email_address_identification_status: $email_address_identification_status, phone_number: $phone_number, phone_number_identification_status: $phone_number_identification_status, web3_wallet: $web3_wallet, username: $username, password: $password, password_digest: $password_digest, password_hasher: $password_hasher, skip_password_checks: $skip_password_checks, skip_password_requirement: $skip_password_requirement, totp_secret: $totp_secret, backup_codes: $backup_codes, public_metadata: $public_metadata, private_metadata: $private_metadata, unsafe_metadata: $unsafe_metadata, delete_self_enabled: $delete_self_enabled, legal_accepted_at: $legal_accepted_at, skip_legal_checks: $skip_legal_checks, skip_user_requirement: $skip_user_requirement, create_organization_enabled: $create_organization_enabled, create_organizations_limit: $create_organizations_limit, created_at: $created_at, bypass_client_trust: $bypass_client_trust, banned: $banned, locked: $locked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count users
#
# GET /users/count
# operationId: GetUsersCount
@deprecated --flag last-active-at-since
export def "users-count GetUsersCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-address: list # Counts users with the specified email addresses. Accepts up to 100 email addresses. Any email addresses not found are ignored.
  --phone-number: list # Counts users with the specified phone numbers. Accepts up to 100 phone numbers. Any phone numbers not found are ignored.
  --external-id: list # Counts users with the specified external IDs. Accepts up to 100 external IDs. Any external IDs not found are ignored.
  --username: list # Counts users with the specified usernames. Accepts up to 100 usernames. Any usernames not found are ignored.
  --web3-wallet: list # Counts users with the specified web3 wallet addresses. Accepts up to 100 web3 wallet addresses. Any web3 wallet addresses not found are ignored.
  --user-id: list # Counts users with the user IDs specified. Accepts up to 100 user IDs. Any user IDs not found are ignored.
  --organization-id: list # Returns users that have memberships to the given organizations. For each organization ID, the `+` and `-` can be prepended to the ID, which denote whether the respective organization should be included or excluded from the result set. Accepts up to 100 organization IDs.
  --qp-query: string # Counts users that match the given query. For possible matches, we check the email addresses, phone numbers, usernames, web3 wallets, user IDs, first and last names. The query value doesn't need to match the exact value you are looking for, it is capable of partial matches as well.
  --email-address-query: string # Counts users with emails that match the given query, via case-insensitive partial match. For example, `email_address_query=ello` will match a user with the email `HELLO@example.com`, and will be included in the resulting count.
  --phone-number-query: string # Counts users with phone numbers that match the given query, via case-insensitive partial match. For example, `phone_number_query=555` will match a user with the phone number `+1555xxxxxxx`, and will be included in the resulting count.
  --username-query: string # Counts users with usernames that match the given query, via case-insensitive partial match. For example, `username_query=CoolUser` will match a user with the username `SomeCoolUser`, and will be included in the resulting count.
  --name-query: string # Returns users with names that match the given query, via case-insensitive partial match.
  --banned: oneof<nothing, bool> # Counts users which are either banned (`banned=true`) or not banned (`banned=false`).
  --last-active-at-before: int # Returns users whose last session activity was before the given date (with millisecond precision). Example: use 1700690400000 to retrieve users whose last session activity was before 2023-11-23. (e.g. 1700690400000)
  --last-active-at-after: int # Returns users whose last session activity was after the given date (with millisecond precision). Example: use 1700690400000 to retrieve users whose last session activity was after 2023-11-23. (e.g. 1700690400000)
  --last-active-at-since: int # Returns users that had session activity since the given date. Example: use 1700690400000 to retrieve users that had session activity from 2023-11-23 until the current day. Deprecated in favor of `last_active_at_after`. (DEPRECATED, e.g. 1700690400000)
  --created-at-before: int # Returns users who have been created before the given date (with millisecond precision). Example: use 1730160000000 to retrieve users who have been created before 2024-10-29. (e.g. 1730160000000)
  --created-at-after: int # Returns users who have been created after the given date (with millisecond precision). Example: use 1730160000000 to retrieve users who have been created after 2024-10-29. (e.g. 1730160000000)
  --last-sign-in-at-before: int # Counts users whose last sign-in was before the given date (with millisecond precision). Example: use 1700690400000 to count users whose last sign-in was before 2023-11-23. (e.g. 1700690400000)
  --last-sign-in-at-after: int # Counts users whose last sign-in was after the given date (with millisecond precision). Example: use 1700690400000 to count users whose last sign-in was after 2023-11-23. (e.g. 1700690400000)
  --provider: string # Counts users with external accounts for the specified OAuth provider. Must be used in combination with the `provider_user_id` parameter. For example, use `provider=oauth_google&provider_user_id=12345` to count users with Google provider user ID 12345. Accepts up to 100 providers.
  --provider-user-id: list # Counts users with the specified provider user IDs for a specific provider. Must be used in combination with the `provider` parameter. For example, use `provider=oauth_google&provider_user_id=12345` to count users with Google provider user ID 12345. Accepts up to 100 provider user IDs. Any provider user IDs not found are ignored.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email_address" $email_address "multi") (serialize-qp "phone_number" $phone_number "multi") (serialize-qp "external_id" $external_id "multi") (serialize-qp "username" $username "multi") (serialize-qp "web3_wallet" $web3_wallet "multi") (serialize-qp "user_id" $user_id "multi") (serialize-qp "organization_id" $organization_id "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "email_address_query" $email_address_query "scalar") (serialize-qp "phone_number_query" $phone_number_query "scalar") (serialize-qp "username_query" $username_query "scalar") (serialize-qp "name_query" $name_query "scalar") (serialize-qp "banned" $banned "scalar") (serialize-qp "last_active_at_before" $last_active_at_before "scalar") (serialize-qp "last_active_at_after" $last_active_at_after "scalar") (serialize-qp "last_active_at_since" $last_active_at_since "scalar") (serialize-qp "created_at_before" $created_at_before "scalar") (serialize-qp "created_at_after" $created_at_after "scalar") (serialize-qp "last_sign_in_at_before" $last_sign_in_at_before "scalar") (serialize-qp "last_sign_in_at_after" $last_sign_in_at_after "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "provider_user_id" $provider_user_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/users/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a user
#
# GET /users/{user_id}
# operationId: GetUser
export def "users GetUser" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /users/{user_id}
# operationId: UpdateUser
export def "users UpdateUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # The ID of the user as used in your external systems or your previous authentication solution. Must be unique across your instance. (nullable)
  --first-name: string # The first name to assign to the user (nullable)
  --last-name: string # The last name to assign to the user (nullable)
  --locale: string # The locale to assign to the user (e.g., "en-US", "fr-FR") (nullable)
  --primary-email-address-id: string # The ID of the email address to set as primary. It must be verified, and present on the current user. (nullable)
  --notify-primary-email-address-changed: oneof<nothing, bool> # If set to `true`, the user will be notified that their primary email address has changed. By default, no notification is sent. (nullable, default: false)
  --primary-phone-number-id: string # The ID of the phone number to set as primary. It must be verified, and present on the current user. (nullable)
  --primary-web3-wallet-id: string # The ID of the web3 wallets to set as primary. It must be verified, and present on the current user. (nullable)
  --username: string # The username to give to the user. It must be unique across your instance. (nullable)
  --profile-image-id: string # The ID of the image to set as the user's profile image (nullable)
  --password: string # The plaintext password to give the user. Must be at least 8 characters long, and cannot be in any list of hacked passwords. (nullable)
  --password-digest: string # In case you already have the password digests and not the passwords, you can use them for the newly created user via this property. The digests should be generated with one of the supported algorithms. The hashing algorithm can be specified using the `password_hasher` property.
  --password-hasher: string # The hashing algorithm that was used to generate the password digest.  The algorithms we support at the moment are [`bcrypt`](https://en.wikipedia.org/wiki/Bcrypt), [`bcrypt_sha256_django`](https://docs.djangoproject.com/en/4.0/topics/auth/passwords/), [`md5`](https://en.wikipedia.org/wiki/MD5), `pbkdf2_sha1`, `pbkdf2_sha256`, [`pbkdf2_sha256_django`](https://docs.djangoproject.com/en/4.0/topics/auth/passwords/), `pbkdf2_sha512`, [`phpass`](https://www.openwall.com/phpass/), `md5_phpass`, [`scrypt_firebase`](https://firebaseopensource.com/projects/firebase/scrypt/), [`scrypt_werkzeug`](https://werkzeug.palletsprojects.com/en/3.0.x/utils/#werkzeug.security.generate_password_hash), [`sha256`](https://en.wikipedia.org/wiki/SHA-2), [`ldap_ssha`](https://www.openldap.org/faq/data/cache/347.html), the [`argon2`](https://argon2.online/) variants: `argon2i` and `argon2id`, `sha512_symfony`, the SHA-512 variant of the [Symfony](https://symfony.com/doc/current/security/passwords.html) legacy hasher, and `pbkdf2_sha512_hex`, a variant of `pbkdf2_sha512` that accepts hex-encoded salt and hash.  Each of the supported hashers expects the incoming digest to be in a particular format. See the [Clerk docs](https://clerk.com/docs/references/backend/user/create-user) for more information.
  --skip-password-checks: oneof<nothing, bool> # Set it to `true` if you're updating the user's password and want to skip any password policy settings check. This parameter can only be used when providing a `password`. (nullable)
  --sign-out-of-other-sessions: oneof<nothing, bool> # Set to `true` to sign out the user from all their active sessions once their password is updated. This parameter can only be used when providing a `password`. (nullable)
  --totp-secret: string # In case TOTP is configured on the instance, you can provide the secret to enable it on the specific user without the need to reset it. (nullable)
  --backup-codes: list # If Backup Codes are configured on the instance, you can provide them to enable it on the specific user without the need to reset them.
  --delete-self-enabled: oneof<nothing, bool> # If true, the user can delete themselves with the Frontend API. (nullable)
  --create-organization-enabled: oneof<nothing, bool> # If true, the user can create organizations with the Frontend API. (nullable)
  --legal-accepted-at: string # A custom timestamp denoting _when_ the user accepted legal requirements, specified in RFC3339 format. (nullable)
  --skip-legal-checks: oneof<nothing, bool> # When set to `true` all legal checks are skipped. (nullable)
  --create-organizations-limit: int # The maximum number of organizations the user can create. 0 means unlimited. (nullable)
  --created-at: string # A custom date/time denoting _when_ the user signed up to the application. (nullable)
  --bypass-client-trust: oneof<nothing, bool> # When set to `true`, the user will bypass client trust checks during sign-in. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let body = {external_id: $external_id, first_name: $first_name, last_name: $last_name, locale: $locale, primary_email_address_id: $primary_email_address_id, notify_primary_email_address_changed: $notify_primary_email_address_changed, primary_phone_number_id: $primary_phone_number_id, primary_web3_wallet_id: $primary_web3_wallet_id, username: $username, profile_image_id: $profile_image_id, password: $password, password_digest: $password_digest, password_hasher: $password_hasher, skip_password_checks: $skip_password_checks, sign_out_of_other_sessions: $sign_out_of_other_sessions, totp_secret: $totp_secret, backup_codes: $backup_codes, delete_self_enabled: $delete_self_enabled, create_organization_enabled: $create_organization_enabled, legal_accepted_at: $legal_accepted_at, skip_legal_checks: $skip_legal_checks, create_organizations_limit: $create_organizations_limit, created_at: $created_at, bypass_client_trust: $bypass_client_trust} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /users/{user_id}
# operationId: DeleteUser
export def "users DeleteUser" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ban a user
#
# POST /users/{user_id}/ban
# operationId: BanUser
export def "users-ban BanUser" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/ban")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unban a user
#
# POST /users/{user_id}/unban
# operationId: UnbanUser
export def "users-unban UnbanUser" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/unban")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ban multiple users
#
# POST /users/ban
# operationId: UsersBan
export def "users-ban UsersBan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list # Array of user IDs to ban
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/ban")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unban multiple users
#
# POST /users/unban
# operationId: UsersUnban
export def "users-unban UsersUnban" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list # Array of user IDs to unban
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/unban")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lock a user
#
# POST /users/{user_id}/lock
# operationId: LockUser
export def "users-lock LockUser" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlock a user
#
# POST /users/{user_id}/unlock
# operationId: UnlockUser
export def "users-unlock UnlockUser" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set user profile image
#
# POST /users/{user_id}/profile_image
# operationId: SetUserProfileImage
export def "users-profile-image SetUserProfileImage" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/profile_image")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete user profile image
#
# DELETE /users/{user_id}/profile_image
# operationId: DeleteUserProfileImage
export def "users-profile-image DeleteUserProfileImage" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/profile_image")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merge and update a user's metadata
#
# PATCH /users/{user_id}/metadata
# operationId: UpdateUserMetadata
export def "users-metadata UpdateUserMetadata" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-metadata: record # Metadata saved on the user, that is visible to both your frontend and backend. The new object will be merged with the existing value.
  --private-metadata: record # Metadata saved on the user that is only visible to your backend. The new object will be merged with the existing value.
  --unsafe-metadata: record # Metadata saved on the user, that can be updated from both the Frontend and Backend APIs. The new object will be merged with the existing value.  Note: Since this data can be modified from the frontend, it is not guaranteed to be safe.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/metadata")
  let body = {public_metadata: $public_metadata, private_metadata: $private_metadata, unsafe_metadata: $unsafe_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace a user's metadata
#
# PUT /users/{user_id}/metadata
# operationId: ReplaceUserMetadata
export def "users-metadata ReplaceUserMetadata" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-metadata: record # Metadata saved on the user, that is visible to both your frontend and backend. The existing value will be replaced entirely with the new object.
  --private-metadata: record # Metadata saved on the user that is only visible to your backend. The existing value will be replaced entirely with the new object.
  --unsafe-metadata: record # Metadata saved on the user, that can be updated from both the Frontend and Backend APIs. The existing value will be replaced entirely with the new object.  Note: Since this data can be modified from the frontend, it is not guaranteed to be safe.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/metadata")
  let body = {public_metadata: $public_metadata, private_metadata: $private_metadata, unsafe_metadata: $unsafe_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a user's billing subscription
#
# GET /users/{user_id}/billing/subscription
# operationId: GetUserBillingSubscription
export def "users-billing-subscription GetUserBillingSubscription" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/billing/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a user's credit balance
#
# GET /users/{user_id}/billing/credits
# operationId: GetUserBillingCreditBalance
export def "users-billing-credits GetUserBillingCreditBalance" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/billing/credits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adjust a user's credit balance
#
# POST /users/{user_id}/billing/credits
# operationId: AdjustUserBillingCreditBalance
export def "users-billing-credits AdjustUserBillingCreditBalance" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # The credit amount in cents. Must be greater than zero. (format: int64)
  action: string@action-completer # Whether to increase or decrease the credit balance.
  --currency: string # The currency code (e.g. "USD"). Defaults to USD if not provided.
  idempotency_key: string # A unique key to ensure the adjustment is applied only once. Repeated requests with the same key return the original ledger entry.
  --note: string # An optional note to attach to the ledger entry.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/billing/credits")
  let body = {amount: $amount, action: $action, currency: $currency, idempotency_key: $idempotency_key, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the OAuth access token of a user
#
# GET /users/{user_id}/oauth_access_tokens/{provider}
# operationId: GetOAuthAccessToken
export def "users-oauth-access-tokens GetOAuthAccessToken" [
  user_id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/oauth_access_tokens/($provider)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all memberships for a user
#
# GET /users/{user_id}/organization_memberships
# operationId: UsersGetOrganizationMemberships
export def "users-organization-memberships UsersGetOrganizationMemberships" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/organization_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all invitations for a user
#
# GET /users/{user_id}/organization_invitations
# operationId: UsersGetOrganizationInvitations
export def "users-organization-invitations UsersGetOrganizationInvitations" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --status: string@status-completer-1 # Filter organization invitations based on their status
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/organization_invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify the password of a user
#
# POST /users/{user_id}/verify_password
# operationId: VerifyPassword
export def "users-verify-password VerifyPassword" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The user password to verify
]: any -> record<verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/verify_password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify a TOTP or backup code for a user
#
# POST /users/{user_id}/verify_totp
# operationId: VerifyTOTP
export def "users-verify-totp VerifyTOTP" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # The TOTP or backup code to verify
]: any -> record<verified: bool, code_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/verify_totp")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a user's MFA methods
#
# DELETE /users/{user_id}/mfa
# operationId: DisableMFA
export def "users-mfa DisableMFA" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/mfa")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable all user's Backup codes
#
# DELETE /users/{user_id}/backup_code
# operationId: DeleteBackupCode
export def "users-backup-code DeleteBackupCode" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/backup_code")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user passkey
#
# DELETE /users/{user_id}/passkeys/{passkey_identification_id}
# operationId: UserPasskeyDelete
export def "users-passkeys UserPasskeyDelete" [
  user_id: string
  passkey_identification_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/passkeys/($passkey_identification_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user web3 wallet
#
# DELETE /users/{user_id}/web3_wallets/{web3_wallet_identification_id}
# operationId: UserWeb3WalletDelete
export def "users-web3-wallets UserWeb3WalletDelete" [
  user_id: string
  web3_wallet_identification_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/web3_wallets/($web3_wallet_identification_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all the user's TOTPs
#
# DELETE /users/{user_id}/totp
# operationId: DeleteTOTP
export def "users-totp DeleteTOTP" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/totp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete External Account
#
# DELETE /users/{user_id}/external_accounts/{external_account_id}
# operationId: DeleteExternalAccount
export def "users-external-accounts DeleteExternalAccount" [
  user_id: string
  external_account_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/external_accounts/($external_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a user's password as compromised
#
# POST /users/{user_id}/password/set_compromised
# operationId: SetUserPasswordCompromised
export def "users-password-set-compromised SetUserPasswordCompromised" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revoke-all-sessions: oneof<nothing, bool> # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/password/set_compromised")
  let body = {revoke_all_sessions: $revoke_all_sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unset a user's password as compromised
#
# POST /users/{user_id}/password/unset_compromised
# operationId: UnsetUserPasswordCompromised
export def "users-password-unset-compromised UnsetUserPasswordCompromised" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/password/unset_compromised")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an invitation
#
# POST /invitations
# operationId: CreateInvitation
export def "invitations CreateInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email_address: string # The email address the invitation will be sent to
  --public-metadata: record # Metadata that will be attached to the newly created invitation. The value of this property should be a well-formed JSON object. Once the user accepts the invitation and signs up, these metadata will end up in the user's public metadata.
  --redirect-url: string # Optional URL which specifies where to redirect the user once they click the invitation link. This is only required if you have implemented a [custom flow](https://clerk.com/docs/authentication/invitations#custom-flow) and you're not using Clerk Hosted Pages or Clerk Components.
  --notify: oneof<nothing, bool> # Optional flag which denotes whether an email invitation should be sent to the given email address. Defaults to `true`. (nullable, default: true)
  --ignore-existing: oneof<nothing, bool> # Whether an invitation should be created if there is already an existing invitation for this email address, or it's claimed by another user. (nullable, default: false)
  --expires-in-days: int # The number of days the invitation will be valid for. By default, the invitation expires after 30 days. (nullable)
  --template-slug: string@template-slug-completer # The slug of the email template to use for the invitation email.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invitations")
  let body = {email_address: $email_address, public_metadata: $public_metadata, redirect_url: $redirect_url, notify: $notify, ignore_existing: $ignore_existing, expires_in_days: $expires_in_days, template_slug: $template_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all invitations
#
# GET /invitations
# operationId: ListInvitations
export def "invitations ListInvitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Filter invitations based on their status
  --qp-query: string # Filter invitations based on their `email_address` or `id`
  --order-by: string # Allows to return invitations in a particular order. At the moment, you can order the returned invitations either by their `created_at`, `email_address` or `expires_at`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want invitations to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. Defaults to `-created_at`. (default: -created_at)
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple invitations
#
# POST /invitations/bulk
# operationId: CreateBulkInvitations
export def "invitations-bulk CreateBulkInvitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invitations/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revokes an invitation
#
# POST /invitations/{invitation_id}/revoke
# operationId: RevokeInvitation
export def "invitations-revoke RevokeInvitation" [
  invitation_id: string
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
  let full_url = (build-url $base $"/invitations/($invitation_id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of organization invitations for the current instance
#
# GET /organization_invitations
# operationId: ListInstanceOrganizationInvitations
export def "organization-invitations ListInstanceOrganizationInvitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # Allows to return organization invitations in a particular order. At the moment, you can order the returned organization invitations either by their `created_at` or `email_address`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want organization invitations to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. Defaults to `-created_at`. (default: -created_at)
  --status: string@status-completer-1 # Filter organization invitations based on their status
  --qp-query: string # Filter organization invitations based on their `email_address`
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization_invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all identifiers on the allow-list
#
# GET /allowlist_identifiers
# operationId: ListAllowlistIdentifiers
export def "allowlist-identifiers ListAllowlistIdentifiers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/allowlist_identifiers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add identifier to the allow-list
#
# POST /allowlist_identifiers
# operationId: CreateAllowlistIdentifier
export def "allowlist-identifiers CreateAllowlistIdentifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string # The identifier to be added in the allow-list. This can be an email address, a phone number, or a web3 wallet.
  --notify: oneof<nothing, bool> # This flag denotes whether the given identifier will receive an invitation to join the application. Note that this only works for email address and phone number identifiers. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/allowlist_identifiers")
  let body = {identifier: $identifier, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete identifier from allow-list
#
# DELETE /allowlist_identifiers/{identifier_id}
# operationId: DeleteAllowlistIdentifier
export def "allowlist-identifiers DeleteAllowlistIdentifier" [
  identifier_id: string
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
  let full_url = (build-url $base $"/allowlist_identifiers/($identifier_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all identifiers on the block-list
#
# GET /blocklist_identifiers
# operationId: ListBlocklistIdentifiers
export def "blocklist-identifiers ListBlocklistIdentifiers" [
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
  let full_url = (build-url $base "/blocklist_identifiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add identifier to the block-list
#
# POST /blocklist_identifiers
# operationId: CreateBlocklistIdentifier
export def "blocklist-identifiers CreateBlocklistIdentifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string # The identifier to be added in the block-list. This can be an email address, a phone number, or a web3 wallet.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocklist_identifiers")
  let body = {identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete identifier from block-list
#
# DELETE /blocklist_identifiers/{identifier_id}
# operationId: DeleteBlocklistIdentifier
export def "blocklist-identifiers DeleteBlocklistIdentifier" [
  identifier_id: string
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
  let full_url = (build-url $base $"/blocklist_identifiers/($identifier_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update instance settings
#
# PATCH /beta_features/instance_settings
# operationId: UpdateInstanceAuthConfig
export def "beta-features-instance-settings UpdateInstanceAuthConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --restricted-to-allowlist: oneof<nothing, bool> # Whether sign up is restricted to email addresses, phone numbers and usernames that are on the allowlist. (nullable, default: false)
  --from-email-address: string # The local part of the email address from which authentication-related emails (e.g. OTP code, magic links) will be sent. Only alphanumeric values are allowed. Note that this value should contain only the local part of the address (e.g. `foo` for `foo@example.com`). (nullable)
  --progressive-sign-up: oneof<nothing, bool> # Enable the Progressive Sign Up algorithm. This feature is deprecated, please contact support if you need assistance. (nullable)
  --test-mode: oneof<nothing, bool> # Toggles test mode for this instance, allowing the use of test email addresses and phone numbers. Defaults to true for development instances. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta_features/instance_settings")
  let body = {restricted_to_allowlist: $restricted_to_allowlist, from_email_address: $from_email_address, progressive_sign_up: $progressive_sign_up, test_mode: $test_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update production instance domain
#
# PUT /beta_features/domain
# DEPRECATED
# operationId: UpdateProductionInstanceDomain
@deprecated
export def "beta-features-domain UpdateProductionInstanceDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-url: string # The new home URL of the production instance e.g. https://www.example.com
  --is-secondary: oneof<nothing, bool> # Whether the domain is a secondary app.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta_features/domain")
  let body = {home_url: $home_url, is_secondary: $is_secondary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create actor token
#
# POST /actor_tokens
# operationId: CreateActorToken
# --actor shape: {sub: string}
export def "actor-tokens CreateActorToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The ID of the user being impersonated.
  actor: record # The actor payload. It needs to include a sub property which should contain the ID of the actor. This whole payload will be also included in the JWT session token. (e.g. {sub: user_2OEpKhcCN1Lat9NQ0G6puh7q5Rb}) — shape: {sub: string}
  --expires-in-seconds: int # Optional parameter to specify the life duration of the actor token in seconds. By default, the duration is 1 hour. (default: 3600)
  --session-max-duration-in-seconds: int # The maximum duration that the session which will be created by the generated actor token should last. By default, the duration of a session created via an actor token, lasts 30 minutes. (default: 1800)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/actor_tokens")
  let body = {user_id: $user_id, actor: $actor, expires_in_seconds: $expires_in_seconds, session_max_duration_in_seconds: $session_max_duration_in_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke actor token
#
# POST /actor_tokens/{actor_token_id}/revoke
# operationId: RevokeActorToken
export def "actor-tokens-revoke RevokeActorToken" [
  actor_token_id: string
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
  let full_url = (build-url $base $"/actor_tokens/($actor_token_id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all instance domains
#
# GET /domains
# operationId: ListDomains
export def "domains ListDomains" [
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
  let full_url = (build-url $base "/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a domain
#
# POST /domains
# operationId: AddDomain
export def "domains AddDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The new domain name. Can contain the port for development instances.
  --is-satellite: oneof<nothing, bool> # Marks the new domain as satellite. Only `true` is accepted at the moment.
  --proxy-url: string # The full URL of the proxy which will forward requests to the Clerk Frontend API for this domain. Applicable only to production instances. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let body = {name: $name, is_satellite: $is_satellite, proxy_url: $proxy_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a satellite domain
#
# DELETE /domains/{domain_id}
# operationId: DeleteDomain
export def "domains DeleteDomain" [
  domain_id: string
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
  let full_url = (build-url $base $"/domains/($domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a domain
#
# PATCH /domains/{domain_id}
# operationId: UpdateDomain
export def "domains UpdateDomain" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new domain name. For development instances, can contain the port, i.e `myhostname:3000`. For production instances, must be a valid FQDN, i.e `mysite.com`. Cannot contain protocol scheme. (nullable)
  --proxy-url: string # The full URL of the proxy that will forward requests to Clerk's Frontend API. Can only be updated for production instances. (nullable)
  --is-secondary: oneof<nothing, bool> # Whether this is a domain for a secondary app, meaning that any subdomain provided is significant and will be stored as part of the domain. This is useful for supporting multiple apps (one primary and multiple secondaries) on the same root domain (eTLD+1). (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domain_id)")
  let body = {name: $name, proxy_url: $proxy_url, is_secondary: $is_secondary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch the current instance
#
# GET /instance
# operationId: GetInstance
export def "instance GetInstance" [
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
  let full_url = (build-url $base "/instance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update instance settings
#
# PATCH /instance
# operationId: UpdateInstance
@deprecated --flag cookieless-dev
export def "instance UpdateInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # Toggles test mode for this instance, allowing the use of test email addresses and phone numbers. Defaults to true for development instances. (nullable)
  --hibp: oneof<nothing, bool> # Whether the instance should be using the HIBP service to check passwords for breaches (nullable)
  --support-email: string # nullable
  --clerk-js-version: string # nullable
  --development-origin: string # nullable
  --allowed-origins: list # For browser-like stacks such as browser extensions, Electron (not officially supported), or Capacitor.js (not officially supported), the instance allowed origins need to be updated with the request origin value. For Chrome extensions popup, background, or service worker pages, the origin is chrome-extension://extension_uuid. For Electron apps the default origin is http://localhost:3000. For Capacitor, the origin is capacitor://localhost.
  --cookieless-dev: oneof<nothing, bool> # Whether the instance should operate in cookieless development mode (i.e. without third-party cookies). Deprecated: Please use `url_based_session_syncing` instead. (DEPRECATED, nullable)
  --url-based-session-syncing: oneof<nothing, bool> # Whether the instance should use URL-based session syncing in development mode (i.e. without third-party cookies). (nullable)
  --preferred-sign-in-strategy-when-password-required: string@preferred-sign-in-strategy-when-password-required-completer # When password is required at the instance level, sets the preferred sign-in strategy surfaced to Clerk components. Has no effect when password is not required. Defaults to `password`. Set to an empty string to clear the override. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance")
  let body = {test_mode: $test_mode, hibp: $hibp, support_email: $support_email, clerk_js_version: $clerk_js_version, development_origin: $development_origin, allowed_origins: $allowed_origins, cookieless_dev: $cookieless_dev, url_based_session_syncing: $url_based_session_syncing, preferred_sign_in_strategy_when_password_required: $preferred_sign_in_strategy_when_password_required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update instance restrictions
#
# PATCH /instance/restrictions
# operationId: UpdateInstanceRestrictions
export def "instance-restrictions UpdateInstanceRestrictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowlist: oneof<nothing, bool> # nullable
  --blocklist: oneof<nothing, bool> # nullable
  --allowlist-blocklist-disabled-on-sign-in: oneof<nothing, bool> # nullable
  --block-email-subaddresses: oneof<nothing, bool> # nullable
  --block-disposable-email-domains: oneof<nothing, bool> # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance/restrictions")
  let body = {allowlist: $allowlist, blocklist: $blocklist, allowlist_blocklist_disabled_on_sign_in: $allowlist_blocklist_disabled_on_sign_in, block_email_subaddresses: $block_email_subaddresses, block_disposable_email_domains: $block_disposable_email_domains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get instance protect settings
#
# GET /instance/protect
# operationId: GetInstanceProtect
export def "instance-protect GetInstanceProtect" [
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
  let full_url = (build-url $base "/instance/protect")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update instance protect settings
#
# PATCH /instance/protect
# operationId: UpdateInstanceProtect
export def "instance-protect UpdateInstanceProtect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules-enabled: oneof<nothing, bool> # nullable
  --specter-enabled: oneof<nothing, bool> # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance/protect")
  let body = {rules_enabled: $rules_enabled, specter_enabled: $specter_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get instance communication settings
#
# GET /instance/communication
# operationId: GetInstanceCommunication
export def "instance-communication GetInstanceCommunication" [
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
  let full_url = (build-url $base "/instance/communication")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update instance communication settings
#
# PATCH /instance/communication
# operationId: UpdateInstanceCommunication
export def "instance-communication UpdateInstanceCommunication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --blocked-country-codes: list # ISO 3166-1 alpha-2 country codes to block for SMS delivery. Whole-list replacement. Codes must be uppercase, 2-letter, and unique within the array. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance/communication")
  let body = {blocked_country_codes: $blocked_country_codes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get OAuth application settings
#
# GET /instance/oauth_application_settings
# operationId: GetInstanceOAuthApplicationSettings
export def "instance-oauth-application-settings GetInstanceOAuthApplicationSettings" [
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
  let full_url = (build-url $base "/instance/oauth_application_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update OAuth application settings
#
# PATCH /instance/oauth_application_settings
# operationId: UpdateInstanceOAuthApplicationSettings
export def "instance-oauth-application-settings UpdateInstanceOAuthApplicationSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dynamic-oauth-client-registration: oneof<nothing, bool> # Whether dynamic OAuth client registration is enabled for the instance (RFC 7591). (nullable)
  --oauth-jwt-access-tokens: oneof<nothing, bool> # Whether OAuth JWT access tokens are enabled for the instance (disabled indicates opaque access tokens). (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance/oauth_application_settings")
  let body = {dynamic_oauth_client_registration: $dynamic_oauth_client_registration, oauth_jwt_access_tokens: $oauth_jwt_access_tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update production instance domain
#
# POST /instance/change_domain
# operationId: ChangeProductionInstanceDomain
export def "instance-change-domain ChangeProductionInstanceDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-url: string # The new home URL of the production instance e.g. https://www.example.com
  --is-secondary: oneof<nothing, bool> # Whether this is a domain for a secondary app, meaning that any subdomain provided is significant and will be stored as part of the domain. This is useful for supporting multiple apps (one primary and multiple secondaries) on the same root domain (eTLD+1).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance/change_domain")
  let body = {home_url: $home_url, is_secondary: $is_secondary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get instance organization settings
#
# GET /instance/organization_settings
# operationId: GetInstanceOrganizationSettings
export def "instance-organization-settings GetInstanceOrganizationSettings" [
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
  let full_url = (build-url $base "/instance/organization_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update instance organization settings
#
# PATCH /instance/organization_settings
# operationId: UpdateInstanceOrganizationSettings
export def "instance-organization-settings UpdateInstanceOrganizationSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # nullable
  --max-allowed-memberships: int # nullable
  --admin-delete-enabled: oneof<nothing, bool> # nullable
  --domains-enabled: oneof<nothing, bool> # nullable
  --slug-disabled: oneof<nothing, bool> # nullable
  --domains-enrollment-modes: list # Specify which enrollment modes to enable for your Organization Domains. Supported modes are 'automatic_invitation' & 'automatic_suggestion'.
  --creator-role-id: string # Specify what the default organization role is for an organization creator. (nullable)
  --domains-default-role-id: string # Specify what the default organization role is for the organization domains. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance/organization_settings")
  let body = {enabled: $enabled, max_allowed_memberships: $max_allowed_memberships, admin_delete_enabled: $admin_delete_enabled, domains_enabled: $domains_enabled, slug_disabled: $slug_disabled, domains_enrollment_modes: $domains_enrollment_modes, creator_role_id: $creator_role_id, domains_default_role_id: $domains_default_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a Svix app
#
# POST /webhooks/svix
# operationId: CreateSvixApp
export def "webhooks-svix CreateSvixApp" [
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
  let full_url = (build-url $base "/webhooks/svix")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Svix app
#
# DELETE /webhooks/svix
# operationId: DeleteSvixApp
export def "webhooks-svix DeleteSvixApp" [
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
  let full_url = (build-url $base "/webhooks/svix")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Svix Dashboard URL
#
# POST /webhooks/svix_url
# operationId: GenerateSvixAuthURL
export def "webhooks-svix-url GenerateSvixAuthURL" [
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
  let full_url = (build-url $base "/webhooks/svix_url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all templates
#
# GET /jwt_templates
# operationId: ListJWTTemplates
export def "jwt-templates ListJWTTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jwt_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a JWT template
#
# POST /jwt_templates
# operationId: CreateJWTTemplate
export def "jwt-templates CreateJWTTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # JWT template name
  claims: record # JWT template claims in JSON format
  --lifetime: int # JWT lifetime (nullable)
  --allowed-clock-skew: int # JWT allowed clock skew (nullable)
  --custom-signing-key: oneof<nothing, bool> # Whether a custom signing key/algorithm is also provided for this template
  --signing-algorithm: string # The custom signing algorithm to use when minting JWTs. Required if `custom_signing_key` is `true`. (nullable)
  --signing-key: string # The custom signing private key to use when minting JWTs. Required if `custom_signing_key` is `true`. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jwt_templates")
  let body = {name: $name, claims: $claims, lifetime: $lifetime, allowed_clock_skew: $allowed_clock_skew, custom_signing_key: $custom_signing_key, signing_algorithm: $signing_algorithm, signing_key: $signing_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a template
#
# GET /jwt_templates/{template_id}
# operationId: GetJWTTemplate
export def "jwt-templates GetJWTTemplate" [
  template_id: string
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
  let full_url = (build-url $base $"/jwt_templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a JWT template
#
# PATCH /jwt_templates/{template_id}
# operationId: UpdateJWTTemplate
export def "jwt-templates UpdateJWTTemplate" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # JWT template name
  claims: record # JWT template claims in JSON format
  --lifetime: int # JWT lifetime (nullable)
  --allowed-clock-skew: int # JWT allowed clock skew (nullable)
  --custom-signing-key: oneof<nothing, bool> # Whether a custom signing key/algorithm is also provided for this template
  --signing-algorithm: string # The custom signing algorithm to use when minting JWTs. Required if `custom_signing_key` is `true`. (nullable)
  --signing-key: string # The custom signing private key to use when minting JWTs. Required if `custom_signing_key` is `true`. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jwt_templates/($template_id)")
  let body = {name: $name, claims: $claims, lifetime: $lifetime, allowed_clock_skew: $allowed_clock_skew, custom_signing_key: $custom_signing_key, signing_algorithm: $signing_algorithm, signing_key: $signing_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Template
#
# DELETE /jwt_templates/{template_id}
# operationId: DeleteJWTTemplate
export def "jwt-templates DeleteJWTTemplate" [
  template_id: string
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
  let full_url = (build-url $base $"/jwt_templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of machines for an instance
#
# GET /machines
# operationId: ListMachines
export def "machines ListMachines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --qp-query: string # Returns machines with ID or name that match the given query. Uses exact match for machine ID and partial match for name. (allows empty value)
  --order-by: string # Allows to return machines in a particular order. You can order the returned machines by their `name` or `created_at`. To specify the direction, use the `+` or `-` symbols prepended to the property to order by. For example, to return machines in descending order by `created_at`, use `-created_at`. If you don't use `+` or `-`, then `+` is implied. Defaults to `-created_at`. (default: -created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/machines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a machine
#
# POST /machines
# operationId: CreateMachine
export def "machines CreateMachine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the machine
  --scoped-machines: list # Array of machine IDs that this machine will have access to. Maximum of 150 scopes per machine.
  --default-token-ttl: int # The default time-to-live (TTL) in seconds for tokens created by this machine. Must be at least 1 second. (default: 3600)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/machines")
  let body = {name: $name, scoped_machines: $scoped_machines, default_token_ttl: $default_token_ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a machine
#
# GET /machines/{machine_id}
# operationId: GetMachine
export def "machines GetMachine" [
  machine_id: string
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
  let full_url = (build-url $base $"/machines/($machine_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a machine
#
# PATCH /machines/{machine_id}
# operationId: UpdateMachine
export def "machines UpdateMachine" [
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the machine
  --default-token-ttl: int # The default time-to-live (TTL) in seconds for tokens created by this machine. Must be at least 1 second.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/machines/($machine_id)")
  let body = {name: $name, default_token_ttl: $default_token_ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a machine
#
# DELETE /machines/{machine_id}
# operationId: DeleteMachine
export def "machines DeleteMachine" [
  machine_id: string
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
  let full_url = (build-url $base $"/machines/($machine_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a machine secret key
#
# GET /machines/{machine_id}/secret_key
# operationId: GetMachineSecretKey
export def "machines-secret-key GetMachineSecretKey" [
  machine_id: string
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
  let full_url = (build-url $base $"/machines/($machine_id)/secret_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rotate a machine's secret key
#
# POST /machines/{machine_id}/secret_key/rotate
# operationId: RotateMachineSecretKey
export def "machines-secret-key-rotate RotateMachineSecretKey" [
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  previous_token_ttl: int # The time in seconds that the previous secret key will remain valid after rotation. This ensures a graceful transition period for updating applications with the new secret key. Set to 0 to immediately expire the previous key. Maximum value is 8 hours (28800 seconds).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/machines/($machine_id)/secret_key/rotate")
  let body = {previous_token_ttl: $previous_token_ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a machine scope
#
# POST /machines/{machine_id}/scopes
# operationId: CreateMachineScope
export def "machines-scopes CreateMachineScope" [
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  to_machine_id: string # The ID of the machine that will be scoped to the current machine
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/machines/($machine_id)/scopes")
  let body = {to_machine_id: $to_machine_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a machine scope
#
# DELETE /machines/{machine_id}/scopes/{other_machine_id}
# operationId: DeleteMachineScope
export def "machines-scopes DeleteMachineScope" [
  machine_id: string
  other_machine_id: string
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
  let full_url = (build-url $base $"/machines/($machine_id)/scopes/($other_machine_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of organizations for an instance
#
# GET /organizations
# operationId: ListOrganizations
export def "organizations ListOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-members-count: oneof<nothing, bool> # Flag to denote whether the member counts of each organization should be included in the response or not.
  --include-missing-member-with-elevated-permissions: oneof<nothing, bool> # Flag to denote whether or not to include a member with elevated permissions who is not currently a member of the organization.
  --qp-query: string # Returns organizations with ID, name, or slug that match the given query. Uses exact match for organization ID and partial match for name and slug.
  --user-id: list # Returns organizations that include any of the specified user IDs as members. Any user IDs not found are ignored. For each user ID, the `+` and `-` can be prepended to the ID, which denote whether the respective organization should be included or excluded from the result set.
  --organization-id: list # Returns organizations with the organization IDs specified. Any organization IDs not found are ignored. For each organization ID, the `+` and `-` can be prepended to the ID, which denote whether the respective organization should be included or excluded from the result set. Accepts up to 100 organization IDs. Example: ?organization_id=+org_1&organization_id=-org_2
  --order-by: string # Allows to return organizations in a particular order. At the moment, you can order the returned organizations either by their `name`, `created_at` or `members_count`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want organizations to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. Defaults to `-created_at`. (default: -created_at)
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_members_count" $include_members_count "scalar") (serialize-qp "include_missing_member_with_elevated_permissions" $include_missing_member_with_elevated_permissions "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "user_id" $user_id "multi") (serialize-qp "organization_id" $organization_id "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /organizations
# operationId: CreateOrganization
export def "organizations CreateOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new organization. May not contain URLs or HTML. Max length: 256
  --created-by: string # The ID of the User who will become the administrator for the new organization (nullable)
  --private-metadata: record # Metadata saved on the organization, accessible only from the Backend API (nullable)
  --public-metadata: record # Metadata saved on the organization, read-only from the Frontend API and fully accessible (read/write) from the Backend API (nullable)
  --slug: string # A slug for the new organization. Can contain only lowercase alphanumeric characters and the dash "-". Must be unique for the instance. This field should only be included when slugs are enabled in the organization settings, refer to our [documentation](https://clerk.com/docs/guides/organizations/overview#organization-slugs). (nullable)
  --max-allowed-memberships: int # The maximum number of memberships allowed for this organization (nullable)
  --created-at: string # A custom date/time denoting _when_ the organization was created, specified in RFC3339 format (e.g. `2012-10-20T07:15:20.902Z`). (nullable)
  --role-set-key: string # The key of the [role set](https://clerk.com/docs/guides/organizations/control-access/role-sets) to assign to this organization. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {name: $name, created_by: $created_by, private_metadata: $private_metadata, public_metadata: $public_metadata, slug: $slug, max_allowed_memberships: $max_allowed_memberships, created_at: $created_at, role_set_key: $role_set_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an organization by ID or slug
#
# GET /organizations/{organization_id}
# operationId: GetOrganization
export def "organizations GetOrganization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-members-count: oneof<nothing, bool> # Flag to denote whether or not the organization's members count should be included in the response.
  --include-missing-member-with-elevated-permissions: oneof<nothing, bool> # Flag to denote whether or not to include a member with elevated permissions who is not currently a member of the organization.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_members_count" $include_members_count "scalar") (serialize-qp "include_missing_member_with_elevated_permissions" $include_missing_member_with_elevated_permissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization
#
# PATCH /organizations/{organization_id}
# operationId: UpdateOrganization
export def "organizations UpdateOrganization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the organization. May not contain URLs or HTML. Max length: 256 (nullable)
  --slug: string # The new slug of the organization, which needs to be unique in the instance (nullable)
  --max-allowed-memberships: int # The maximum number of memberships allowed for this organization (nullable)
  --admin-delete-enabled: oneof<nothing, bool> # If true, an admin can delete this organization with the Frontend API. (nullable)
  --created-at: string # A custom date/time denoting _when_ the organization was created, specified in RFC3339 format (e.g. `2012-10-20T07:15:20.902Z`). (nullable)
  --role-set-key: string # The key of the [role set](https://clerk.com/docs/guides/organizations/control-access/role-sets) to assign to this organization. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)")
  let body = {name: $name, slug: $slug, max_allowed_memberships: $max_allowed_memberships, admin_delete_enabled: $admin_delete_enabled, created_at: $created_at, role_set_key: $role_set_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an organization
#
# DELETE /organizations/{organization_id}
# operationId: DeleteOrganization
export def "organizations DeleteOrganization" [
  organization_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merge and update metadata for an organization
#
# PATCH /organizations/{organization_id}/metadata
# operationId: MergeOrganizationMetadata
export def "organizations-metadata MergeOrganizationMetadata" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-metadata: record # Metadata saved on the organization, that is visible to both your frontend and backend. The new object will be merged with the existing value.
  --private-metadata: record # Metadata saved on the organization that is only visible to your backend. The new object will be merged with the existing value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/metadata")
  let body = {public_metadata: $public_metadata, private_metadata: $private_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace metadata for an organization
#
# PUT /organizations/{organization_id}/metadata
# operationId: ReplaceOrganizationMetadata
export def "organizations-metadata ReplaceOrganizationMetadata" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-metadata: record # Metadata saved on the organization, that is visible to both your frontend and backend. The existing value will be replaced entirely with the new object.
  --private-metadata: record # Metadata saved on the organization that is only visible to your backend. The existing value will be replaced entirely with the new object.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/metadata")
  let body = {public_metadata: $public_metadata, private_metadata: $private_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload a logo for the organization
#
# PUT /organizations/{organization_id}/logo
# operationId: UploadOrganizationLogo
export def "organizations-logo UploadOrganizationLogo" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uploader-user-id: string # The ID of the user that will be credited with the image upload.
  file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/logo")
  let body = {uploader_user_id: $uploader_user_id, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete the organization's logo.
#
# DELETE /organizations/{organization_id}/logo
# operationId: DeleteOrganizationLogo
export def "organizations-logo DeleteOrganizationLogo" [
  organization_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an organization's billing subscription
#
# GET /organizations/{organization_id}/billing/subscription
# operationId: GetOrganizationBillingSubscription
export def "organizations-billing-subscription GetOrganizationBillingSubscription" [
  organization_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/billing/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an organization's credit balance
#
# GET /organizations/{organization_id}/billing/credits
# operationId: GetOrganizationBillingCreditBalance
export def "organizations-billing-credits GetOrganizationBillingCreditBalance" [
  organization_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/billing/credits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adjust an organization's credit balance
#
# POST /organizations/{organization_id}/billing/credits
# operationId: AdjustOrganizationBillingCreditBalance
export def "organizations-billing-credits AdjustOrganizationBillingCreditBalance" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # The credit amount in cents. Must be greater than zero. (format: int64)
  action: string@action-completer # Whether to increase or decrease the credit balance.
  --currency: string # The currency code (e.g. "USD"). Defaults to USD if not provided.
  idempotency_key: string # A unique key to ensure the adjustment is applied only once. Repeated requests with the same key return the original ledger entry.
  --note: string # An optional note to attach to the ledger entry.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/billing/credits")
  let body = {amount: $amount, action: $action, currency: $currency, idempotency_key: $idempotency_key, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create and send an organization invitation
#
# POST /organizations/{organization_id}/invitations
# operationId: CreateOrganizationInvitation
export def "organizations-invitations CreateOrganizationInvitation" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email_address: string # The email address of the new member that is going to be invited to the organization
  --inviter-user-id: string # The ID of the user that invites the new member to the organization. Must be an administrator in the organization. (nullable)
  role: string # The role of the new member in the organization
  --public-metadata: record # Metadata saved on the organization invitation, read-only from the Frontend API and fully accessible (read/write) from the Backend API. When the organization invitation is accepted, the metadata will be transferred to the newly created organization membership. (nullable)
  --private-metadata: record # Metadata saved on the organization invitation, fully accessible (read/write) from the Backend API but not visible from the Frontend API. When the organization invitation is accepted, the metadata will be transferred to the newly created organization membership. (nullable)
  --redirect-url: string # Optional URL that the invitee will be redirected to once they accept the invitation by clicking the join link in the invitation email. (nullable)
  --expires-in-days: int # The number of days the invitation will be valid for. By default, the invitation has a 30 days expire. (nullable)
  --notify: oneof<nothing, bool> # Optional flag which denotes whether an email invitation should be sent to the given email address. Defaults to `true`. (nullable, default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations")
  let body = {email_address: $email_address, inviter_user_id: $inviter_user_id, role: $role, public_metadata: $public_metadata, private_metadata: $private_metadata, redirect_url: $redirect_url, expires_in_days: $expires_in_days, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of organization invitations
#
# GET /organizations/{organization_id}/invitations
# operationId: ListOrganizationInvitations
export def "organizations-invitations ListOrganizationInvitations" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Filter organization invitations based on their status
  --email-address: string # Returns organization invitations inviting the specified email address.
  --order-by: string # Allows to return organization invitations in a particular order. You can order the returned organization invitations either by their `created_at` or `email_address`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want organization invitations to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. Defaults to `-created_at`. (default: -created_at)
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "email_address" $email_address "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk create and send organization invitations
#
# POST /organizations/{organization_id}/invitations/bulk
# operationId: CreateOrganizationInvitationBulk
export def "organizations-invitations-bulk CreateOrganizationInvitationBulk" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of pending organization invitations
#
# GET /organizations/{organization_id}/invitations/pending
# DEPRECATED
# operationId: ListPendingOrganizationInvitations
@deprecated
export def "organizations-invitations-pending ListPendingOrganizationInvitations" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an organization invitation by ID
#
# GET /organizations/{organization_id}/invitations/{invitation_id}
# operationId: GetOrganizationInvitation
export def "organizations-invitations GetOrganizationInvitation" [
  organization_id: string
  invitation_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations/($invitation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke a pending organization invitation
#
# POST /organizations/{organization_id}/invitations/{invitation_id}/revoke
# operationId: RevokeOrganizationInvitation
export def "organizations-invitations-revoke RevokeOrganizationInvitation" [
  organization_id: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requesting-user-id: string # The ID of the user that revokes the invitation. Must be an administrator in the organization. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations/($invitation_id)/revoke")
  let body = {requesting_user_id: $requesting_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of organization roles
#
# GET /organization_roles
# operationId: ListOrganizationRoles
export def "organization-roles ListOrganizationRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Returns organization roles with ID, name, or key that match the given query. Uses exact match for organization role ID and partial match for name and key.
  --order-by: string # Allows to return organization roles in a particular order. At the moment, you can order the returned organization roles by their `created_at`, `name`, or `key`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want organization roles to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. Defaults to `-created_at`. (default: -created_at)
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization_roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organization role
#
# POST /organization_roles
# operationId: CreateOrganizationRole
export def "organization-roles CreateOrganizationRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new organization role
  key: string # A unique key for the organization role. Must start with 'org:' and contain only lowercase alphanumeric characters and underscores.
  --description: string # Optional description for the role (nullable)
  --permissions: list # Array of permission IDs to assign to the role (nullable)
  --include-in-initial-role-set: oneof<nothing, bool> # Whether this role should be included in the initial role set (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization_roles")
  let body = {name: $name, key: $key, description: $description, permissions: $permissions, include_in_initial_role_set: $include_in_initial_role_set} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an organization role
#
# GET /organization_roles/{organization_role_id}
# operationId: GetOrganizationRole
export def "organization-roles GetOrganizationRole" [
  organization_role_id: string
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
  let full_url = (build-url $base $"/organization_roles/($organization_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization role
#
# PATCH /organization_roles/{organization_role_id}
# operationId: UpdateOrganizationRole
export def "organization-roles UpdateOrganizationRole" [
  organization_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the organization role (nullable)
  --key: string # A unique key for the organization role. Must start with 'org:' and contain only lowercase alphanumeric characters and underscores. (nullable)
  --description: string # Optional description for the role (nullable)
  --permissions: list # Array of permission IDs to assign to the role. If provided, this will replace the existing permissions. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization_roles/($organization_role_id)")
  let body = {name: $name, key: $key, description: $description, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an organization role
#
# DELETE /organization_roles/{organization_role_id}
# operationId: DeleteOrganizationRole
export def "organization-roles DeleteOrganizationRole" [
  organization_role_id: string
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
  let full_url = (build-url $base $"/organization_roles/($organization_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign a permission to an organization role
#
# POST /organization_roles/{organization_role_id}/permissions/{permission_id}
# operationId: AssignPermissionToOrganizationRole
export def "organization-roles-permissions AssignPermissionToOrganizationRole" [
  organization_role_id: string
  permission_id: string
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
  let full_url = (build-url $base $"/organization_roles/($organization_role_id)/permissions/($permission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a permission from an organization role
#
# DELETE /organization_roles/{organization_role_id}/permissions/{permission_id}
# operationId: RemovePermissionFromOrganizationRole
export def "organization-roles-permissions RemovePermissionFromOrganizationRole" [
  organization_role_id: string
  permission_id: string
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
  let full_url = (build-url $base $"/organization_roles/($organization_role_id)/permissions/($permission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new organization membership
#
# POST /organizations/{organization_id}/memberships
# operationId: CreateOrganizationMembership
export def "organizations-memberships CreateOrganizationMembership" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The ID of the user that will be added as a member in the organization. The user needs to exist in the same instance as the organization and must not be a member of the given organization already.
  role: string # The role that the new member will have in the organization.
  --public-metadata: record # Metadata saved on the organization membership, that is visible to both your frontend and backend. (nullable)
  --private-metadata: record # Metadata saved on the organization membership that is only visible to your backend. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/memberships")
  let body = {user_id: $user_id, role: $role, public_metadata: $public_metadata, private_metadata: $private_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of all members of an organization
#
# GET /organizations/{organization_id}/memberships
# operationId: ListOrganizationMemberships
export def "organizations-memberships ListOrganizationMemberships" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # Sorts organizations memberships by phone_number, email_address, created_at, first_name, last_name or username. By prepending one of those values with + or -, we can choose to sort in ascending (ASC) or descending (DESC) order."
  --user-id: list # Returns users with the user IDs specified. For each user ID, the `+` and `-` can be prepended to the ID, which denote whether the respective user ID should be included or excluded from the result set. Accepts up to 100 user IDs. Any user IDs not found are ignored.
  --email-address: list # Returns users with the specified email addresses. Accepts up to 100 email addresses. Any email addresses not found are ignored.
  --phone-number: list # Returns users with the specified phone numbers. Accepts up to 100 phone numbers. Any phone numbers not found are ignored.
  --username: list # Returns users with the specified usernames. Accepts up to 100 usernames. Any usernames not found are ignored.
  --web3-wallet: list # Returns users with the specified web3 wallet addresses. Accepts up to 100 web3 wallet addresses. Any web3 wallet addresses not found are ignored.
  --role: list # Returns users with the specified roles. Accepts up to 100 roles. Any roles not found are ignored.
  --qp-query: string # Returns users that match the given query. For possible matches, we check the email addresses, phone numbers, usernames, web3 wallets, user IDs, first and last names. The query value doesn't need to match the exact value you are looking for, it is capable of partial matches as well.
  --email-address-query: string # Returns users with emails that match the given query, via case-insensitive partial match. For example, `email_address_query=ello` will match a user with the email `HELLO@example.com`.
  --phone-number-query: string # Returns users with phone numbers that match the given query, via case-insensitive partial match. For example, `phone_number_query=555` will match a user with the phone number `+1555xxxxxxx`.
  --username-query: string # Returns users with usernames that match the given query, via case-insensitive partial match. For example, `username_query=CoolUser` will match a user with the username `SomeCoolUser`.
  --name-query: string # Returns users with names that match the given query, via case-insensitive partial match.
  --last-active-at-before: int # Returns users whose last session activity was before the given date (with millisecond precision). Example: use 1700690400000 to retrieve users whose last session activity was before 2023-11-23. (e.g. 1700690400000)
  --last-active-at-after: int # Returns users whose last session activity was after the given date (with millisecond precision). Example: use 1700690400000 to retrieve users whose last session activity was after 2023-11-23. (e.g. 1700690400000)
  --created-at-before: int # Returns users who have been created before the given date (with millisecond precision). Example: use 1730160000000 to retrieve users who have been created before 2024-10-29. (e.g. 1730160000000)
  --created-at-after: int # Returns users who have been created after the given date (with millisecond precision). Example: use 1730160000000 to retrieve users who have been created after 2024-10-29. (e.g. 1730160000000)
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "user_id" $user_id "multi") (serialize-qp "email_address" $email_address "multi") (serialize-qp "phone_number" $phone_number "multi") (serialize-qp "username" $username "multi") (serialize-qp "web3_wallet" $web3_wallet "multi") (serialize-qp "role" $role "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "email_address_query" $email_address_query "scalar") (serialize-qp "phone_number_query" $phone_number_query "scalar") (serialize-qp "username_query" $username_query "scalar") (serialize-qp "name_query" $name_query "scalar") (serialize-qp "last_active_at_before" $last_active_at_before "scalar") (serialize-qp "last_active_at_after" $last_active_at_after "scalar") (serialize-qp "created_at_before" $created_at_before "scalar") (serialize-qp "created_at_after" $created_at_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization membership
#
# PATCH /organizations/{organization_id}/memberships/{user_id}
# operationId: UpdateOrganizationMembership
export def "organizations-memberships UpdateOrganizationMembership" [
  organization_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role: string # The new role of the given membership.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/memberships/($user_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from an organization
#
# DELETE /organizations/{organization_id}/memberships/{user_id}
# operationId: DeleteOrganizationMembership
export def "organizations-memberships DeleteOrganizationMembership" [
  organization_id: string
  user_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/memberships/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merge and update organization membership metadata
#
# PATCH /organizations/{organization_id}/memberships/{user_id}/metadata
# operationId: UpdateOrganizationMembershipMetadata
export def "organizations-memberships-metadata UpdateOrganizationMembershipMetadata" [
  organization_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-metadata: record # Metadata saved on the organization membership, that is visible to both your frontend and backend. The new object will be merged with the existing value.
  --private-metadata: record # Metadata saved on the organization membership that is only visible to your backend. The new object will be merged with the existing value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/memberships/($user_id)/metadata")
  let body = {public_metadata: $public_metadata, private_metadata: $private_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new organization domain.
#
# POST /organizations/{organization_id}/domains
# operationId: CreateOrganizationDomain
export def "organizations-domains CreateOrganizationDomain" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the new domain
  --enrollment-mode: string # The enrollment_mode for the new domain. This can be `automatic_invitation`, `automatic_suggestion` or `manual_invitation`
  --verified: oneof<nothing, bool> # The status of domain's verification. Defaults to true (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/domains")
  let body = {name: $name, enrollment_mode: $enrollment_mode, verified: $verified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of all domains of an organization.
#
# GET /organizations/{organization_id}/domains
# operationId: ListOrganizationDomains
export def "organizations-domains ListOrganizationDomains" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --verified: string # Filter domains by their verification status. `true` or `false`
  --enrollment-mode: string # Filter domains by their enrollment mode
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verified" $verified "scalar") (serialize-qp "enrollment_mode" $enrollment_mode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization domain.
#
# PATCH /organizations/{organization_id}/domains/{domain_id}
# operationId: UpdateOrganizationDomain
export def "organizations-domains UpdateOrganizationDomain" [
  organization_id: string
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enrollment-mode: string # The enrollment_mode for the new domain. This can be `automatic_invitation`, `automatic_suggestion` or `manual_invitation` (nullable)
  --verified: oneof<nothing, bool> # The status of the domain's verification (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/domains/($domain_id)")
  let body = {enrollment_mode: $enrollment_mode, verified: $verified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a domain from an organization.
#
# DELETE /organizations/{organization_id}/domains/{domain_id}
# operationId: DeleteOrganizationDomain
export def "organizations-domains DeleteOrganizationDomain" [
  organization_id: string
  domain_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/domains/($domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark an organization domain's ownership as verified
#
# POST /organizations/{organization_id}/domains/{domain_id}/verify_ownership
# operationId: VerifyOrganizationDomainOwnership
export def "organizations-domains-verify-ownership VerifyOrganizationDomainOwnership" [
  organization_id: string
  domain_id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/domains/($domain_id)/verify_ownership")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all organization domains
#
# GET /organization_domains
# operationId: ListAllOrganizationDomains
export def "organization-domains ListAllOrganizationDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # The ID of the organization to filter domains by
  --verified: string@verified-completer # Filter by verification status
  --enrollment-mode: list # Filter by enrollment mode
  --qp-query: string # Search domains by name or organization ID. If the query starts with "org_", it will search by exact organization ID match. Otherwise, it performs a case-insensitive partial match on the domain name.  Note: An empty string or whitespace-only value is not allowed and will result in a validation error.
  --domains: list # Filter by exact domain names. Accepts multiple values (e.g. domains=example.com&domains=test.org).
  --order-by: string # Allows to return organization domains in a particular order. At the moment, you can order the returned domains by their `name` or `created_at`. In order to specify the direction, you can use the `+/-` symbols prepended to the property to order by. For example, if you want domains to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. Defaults to `-created_at`.  (default: -created_at)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "verified" $verified "scalar") (serialize-qp "enrollment_mode" $enrollment_mode "csv") (serialize-qp "query" $qp_query "scalar") (serialize-qp "domains" $domains "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization_domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify the proxy configuration for your domain
#
# POST /proxy_checks
# operationId: VerifyDomainProxy
export def "proxy-checks VerifyDomainProxy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-id: string # The ID of the domain that will be updated.
  --proxy-url: string # The full URL of the proxy which will forward requests to the Clerk Frontend API for this domain. e.g. https://example.com/__clerk
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/proxy_checks")
  let body = {domain_id: $domain_id, proxy_url: $proxy_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all redirect URLs
#
# GET /redirect_urls
# operationId: ListRedirectURLs
export def "redirect-urls ListRedirectURLs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/redirect_urls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a redirect URL
#
# POST /redirect_urls
# operationId: CreateRedirectURL
export def "redirect-urls CreateRedirectURL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The full URL value prefixed with `https://` or a custom scheme e.g. `"https://my-app.com/oauth-callback"` or `"my-app://oauth-callback"`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/redirect_urls")
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a redirect URL
#
# GET /redirect_urls/{id}
# operationId: GetRedirectURL
export def "redirect-urls GetRedirectURL" [
  id: string
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
  let full_url = (build-url $base $"/redirect_urls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a redirect URL
#
# DELETE /redirect_urls/{id}
# operationId: DeleteRedirectURL
export def "redirect-urls DeleteRedirectURL" [
  id: string
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
  let full_url = (build-url $base $"/redirect_urls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create sign-in token
#
# POST /sign_in_tokens
# operationId: CreateSignInToken
export def "sign-in-tokens CreateSignInToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The ID of the user that can use the newly created sign in token
  --expires-in-seconds: int # Optional parameter to specify the life duration of the sign in token in seconds. By default, the duration is 30 days. (nullable, default: 2592000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sign_in_tokens")
  let body = {user_id: $user_id, expires_in_seconds: $expires_in_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke the given sign-in token
#
# POST /sign_in_tokens/{sign_in_token_id}/revoke
# operationId: RevokeSignInToken
export def "sign-in-tokens-revoke RevokeSignInToken" [
  sign_in_token_id: string
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
  let full_url = (build-url $base $"/sign_in_tokens/($sign_in_token_id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a sign-up by ID
#
# GET /sign_ups/{id}
# operationId: GetSignUp
export def "sign-ups GetSignUp" [
  id: string
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
  let full_url = (build-url $base $"/sign_ups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a sign-up
#
# PATCH /sign_ups/{id}
# operationId: UpdateSignUp
export def "sign-ups UpdateSignUp" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # The ID of the guest attempting to sign up as used in your external systems or your previous authentication solution. This will be copied to the resulting user when the sign-up is completed. (nullable)
  --custom-action: oneof<nothing, bool> # If true, the sign-up will be marked as a custom action. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sign_ups/($id)")
  let body = {external_id: $external_id, custom_action: $custom_action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of OAuth applications for an instance
#
# GET /oauth_applications
# operationId: ListOAuthApplications
export def "oauth-applications ListOAuthApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --order-by: string # Allows to return OAuth applications in a particular order. At the moment, you can order the returned OAuth applications by their `created_at` and `name`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want OAuth applications to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. We only support one `order_by` parameter, and if multiple `order_by` parameters are provided, we will only keep the first one. For example, if you pass `order_by=name&order_by=created_at`, we will consider only the first `order_by` parameter, which is `name`. The `created_at` parameter will be ignored in this case. (default: +created_at)
  --name-query: string # Returns OAuth applications with names that match the given query, via case-insensitive partial match.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "name_query" $name_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth_applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an OAuth application
#
# POST /oauth_applications
# operationId: CreateOAuthApplication
@deprecated --flag callback-url
export def "oauth-applications CreateOAuthApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new OAuth application. Max length: 256
  --redirect-uris: list # An array of redirect URIs of the new OAuth application (nullable)
  --callback-url: string # The callback URL of the new OAuth application (DEPRECATED, nullable)
  --scopes: string # Define the allowed scopes for the new OAuth applications that dictate the user payload of the OAuth user info endpoint. Available scopes are `profile`, `email`, `public_metadata`, `private_metadata`. Provide the requested scopes as a string, separated by spaces. (nullable, default: profile email, e.g. profile email public_metadata)
  --consent-screen-enabled: oneof<nothing, bool> # True to enable a consent screen to display in the authentication flow. (nullable, default: true)
  --pkce-required: oneof<nothing, bool> # True to require the Proof Key of Code Exchange (PKCE) flow. (nullable, default: false)
  --public: oneof<nothing, bool> # If true, this client is public and you can use the Proof Key of Code Exchange (PKCE) flow. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth_applications")
  let body = {name: $name, redirect_uris: $redirect_uris, callback_url: $callback_url, scopes: $scopes, consent_screen_enabled: $consent_screen_enabled, pkce_required: $pkce_required, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an OAuth application by ID
#
# GET /oauth_applications/{oauth_application_id}
# operationId: GetOAuthApplication
export def "oauth-applications GetOAuthApplication" [
  oauth_application_id: string
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
  let full_url = (build-url $base $"/oauth_applications/($oauth_application_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an OAuth application
#
# PATCH /oauth_applications/{oauth_application_id}
# operationId: UpdateOAuthApplication
@deprecated --flag callback-url
export def "oauth-applications UpdateOAuthApplication" [
  oauth_application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the OAuth application. Max length: 256 (nullable)
  --redirect-uris: list # An array of redirect URIs of the new OAuth application (nullable)
  --callback-url: string # The new callback URL of the OAuth application (DEPRECATED, nullable)
  --scopes: string # Define the allowed scopes for the new OAuth applications that dictate the user payload of the OAuth user info endpoint. Available scopes are `profile`, `email`, `public_metadata`, `private_metadata`. Provide the requested scopes as a string, separated by spaces. (nullable, default: profile email, e.g. profile email public_metadata private_metadata)
  --consent-screen-enabled: oneof<nothing, bool> # True to enable a consent screen to display in the authentication flow. This cannot be disabled for dynamically registered OAuth Applications. (nullable)
  --pkce-required: oneof<nothing, bool> # True to require the Proof Key of Code Exchange (PKCE) flow. (nullable)
  --public: oneof<nothing, bool> # If true, this client is public and you can use the Proof Key of Code Exchange (PKCE) flow. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth_applications/($oauth_application_id)")
  let body = {name: $name, redirect_uris: $redirect_uris, callback_url: $callback_url, scopes: $scopes, consent_screen_enabled: $consent_screen_enabled, pkce_required: $pkce_required, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an OAuth application
#
# DELETE /oauth_applications/{oauth_application_id}
# operationId: DeleteOAuthApplication
export def "oauth-applications DeleteOAuthApplication" [
  oauth_application_id: string
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
  let full_url = (build-url $base $"/oauth_applications/($oauth_application_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a logo for the OAuth application
#
# PUT /oauth_applications/{oauth_application_id}/logo
# operationId: UploadOAuthApplicationLogo
export def "oauth-applications-logo UploadOAuthApplicationLogo" [
  oauth_application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uploader-user-id: string # The ID of the user that will be credited with the image upload.
  file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth_applications/($oauth_application_id)/logo")
  let body = {uploader_user_id: $uploader_user_id, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Rotate the client secret of the given OAuth application
#
# POST /oauth_applications/{oauth_application_id}/rotate_secret
# operationId: RotateOAuthApplicationSecret
export def "oauth-applications-rotate-secret RotateOAuthApplicationSecret" [
  oauth_application_id: string
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
  let full_url = (build-url $base $"/oauth_applications/($oauth_application_id)/rotate_secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of SAML Connections for an instance
#
# GET /saml_connections
# DEPRECATED
# operationId: ListSAMLConnections
@deprecated
export def "saml-connections ListSAMLConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --qp-query: string # Returns SAML connections that have a name that matches the given query, via case-insensitive partial match.
  --order-by: string # Sorts organizations memberships by phone_number, email_address, created_at, first_name, last_name or username. By prepending one of those values with + or -, we can choose to sort in ascending (ASC) or descending (DESC) order.
  --organization-id: list # Returns SAML connections that have an associated organization ID to the given organizations. For each organization ID, the `+` and `-` can be prepended to the ID, which denote whether the respective organization should be included or excluded from the result set. Accepts up to 100 organization IDs.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "organization_id" $organization_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/saml_connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a SAML Connection
#
# POST /saml_connections
# DEPRECATED
# operationId: CreateSAMLConnection
# --attribute_mapping shape: {user_id?: string, email_address?: string, first_name?: string, last_name?: string}
@deprecated
@deprecated --flag domain
export def "saml-connections CreateSAMLConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name to use as a label for this SAML Connection
  --domain: string # The domain of your organization. Sign in flows using an email with this domain, will use this SAML Connection. (DEPRECATED)
  --domains: list # The domains of your organization. Sign in flows using an email with one of these domains, will use this SAML Connection.
  provider: string@provider-completer # The IdP provider of the connection.
  --idp-entity-id: string # The Entity ID as provided by the IdP (nullable)
  --idp-sso-url: string # The Single-Sign On URL as provided by the IdP (nullable)
  --idp-certificate: string # The X.509 certificate as provided by the IdP (nullable)
  --idp-metadata-url: string # The URL which serves the IdP metadata. If present, it takes priority over the corresponding individual properties (nullable)
  --idp-metadata: string # The XML content of the IdP metadata file. If present, it takes priority over the corresponding individual properties (nullable)
  --organization-id: string # The ID of the organization to which users of this SAML Connection will be added (nullable)
  --attribute-mapping: record # Define the attribute name mapping between Identity Provider and Clerk's user properties (nullable) — shape: {user_id?: string, email_address?: string, first_name?: string, last_name?: string}
  --force-authn: oneof<nothing, bool> # Enable or deactivate ForceAuthn
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/saml_connections")
  let body = {name: $name, domain: $domain, domains: $domains, provider: $provider, idp_entity_id: $idp_entity_id, idp_sso_url: $idp_sso_url, idp_certificate: $idp_certificate, idp_metadata_url: $idp_metadata_url, idp_metadata: $idp_metadata, organization_id: $organization_id, attribute_mapping: $attribute_mapping, force_authn: $force_authn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a SAML Connection by ID
#
# GET /saml_connections/{saml_connection_id}
# DEPRECATED
# operationId: GetSAMLConnection
@deprecated
export def "saml-connections GetSAMLConnection" [
  saml_connection_id: string
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
  let full_url = (build-url $base $"/saml_connections/($saml_connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a SAML Connection
#
# PATCH /saml_connections/{saml_connection_id}
# DEPRECATED
# operationId: UpdateSAMLConnection
# --attribute_mapping shape: {user_id?: string, email_address?: string, first_name?: string, last_name?: string}
@deprecated
@deprecated --flag domain
export def "saml-connections UpdateSAMLConnection" [
  saml_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the new SAML Connection (nullable)
  --domain: string # The domain to use for the new SAML Connection (DEPRECATED, nullable)
  --domains: list # A list of the domains on use for the SAML connection (nullable)
  --idp-entity-id: string # The Entity ID as provided by the IdP (nullable)
  --idp-sso-url: string # The SSO URL as provided by the IdP (nullable)
  --idp-certificate: string # The x509 certificated as provided by the IdP (nullable)
  --idp-metadata-url: string # The URL which serves the IdP metadata. If present, it takes priority over the corresponding individual properties and replaces them (nullable)
  --idp-metadata: string # The XML content of the IdP metadata file. If present, it takes priority over the corresponding individual properties (nullable)
  --organization-id: string # The ID of the organization to which users of this SAML Connection will be added (nullable)
  --attribute-mapping: record # Define the attribute name mapping between Identity Provider and Clerk's user properties (nullable) — shape: {user_id?: string, email_address?: string, first_name?: string, last_name?: string}
  --active: oneof<nothing, bool> # Activate or de-activate the SAML Connection (nullable)
  --sync-user-attributes: oneof<nothing, bool> # Controls whether to update the user's attributes in each sign-in (nullable)
  --allow-subdomains: oneof<nothing, bool> # Allow users with an email address subdomain to use this connection in order to authenticate (nullable)
  --allow-idp-initiated: oneof<nothing, bool> # Enable or deactivate IdP-initiated flows (nullable)
  --disable-additional-identifications: oneof<nothing, bool> # Enable or deactivate additional identifications (nullable)
  --allow-organization-account-linking: oneof<nothing, bool> # Whether this connection supports account linking via organization membership (nullable)
  --force-authn: oneof<nothing, bool> # Enable or deactivate ForceAuthn
  --consent-verified-domains-deletion: oneof<nothing, bool> # When enabling the connection, controls behavior when verified domains used for enrollment modes like automatic invitation or automatic suggestion already exist for the same domain. If true, those verified domains are removed and the connection is enabled. If false or omitted, the request fails when any such verified domain exists. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saml_connections/($saml_connection_id)")
  let body = {name: $name, domain: $domain, domains: $domains, idp_entity_id: $idp_entity_id, idp_sso_url: $idp_sso_url, idp_certificate: $idp_certificate, idp_metadata_url: $idp_metadata_url, idp_metadata: $idp_metadata, organization_id: $organization_id, attribute_mapping: $attribute_mapping, active: $active, sync_user_attributes: $sync_user_attributes, allow_subdomains: $allow_subdomains, allow_idp_initiated: $allow_idp_initiated, disable_additional_identifications: $disable_additional_identifications, allow_organization_account_linking: $allow_organization_account_linking, force_authn: $force_authn, consent_verified_domains_deletion: $consent_verified_domains_deletion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a SAML Connection
#
# DELETE /saml_connections/{saml_connection_id}
# DEPRECATED
# operationId: DeleteSAMLConnection
@deprecated
export def "saml-connections DeleteSAMLConnection" [
  saml_connection_id: string
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
  let full_url = (build-url $base $"/saml_connections/($saml_connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List enterprise connections
#
# GET /enterprise_connections
# operationId: ListEnterpriseConnections
export def "enterprise-connections ListEnterpriseConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --organization-id: string # Filter enterprise connections by organization ID
  --active: oneof<nothing, bool> # Filter by active status. If true, only active connections are returned. If false, only inactive connections are returned. If omitted, all connections are returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/enterprise_connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an enterprise connection
#
# POST /enterprise_connections
# operationId: CreateEnterpriseConnection
# --saml shape: {idp_entity_id?: string, idp_sso_url?: string, idp_certificate?: string, idp_metadata_url?: string, idp_metadata?: string, attribute_mapping?: record, allow_subdomains?: bool, allow_idp_initiated?: bool, force_authn?: bool}
# --oidc shape: {client_id?: string, client_secret?: string, discovery_url?: string, auth_url?: string, token_url?: string, user_info_url?: string, requires_pkce?: bool}
# --custom_attributes item shape: {name: string, key: string, sso_path?: string, scim_path?: string, multi_valued?: bool}
export def "enterprise-connections CreateEnterpriseConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The display name of the connection
  provider: string@provider-completer-1 # The identity provider (e.g. saml_custom, oidc_custom, oidc_github_enterprise, oidc_gitlab)
  domains: list # Domains associated with the enterprise connection (required; at least one). Values are normalized to lowercase. Each domain must be a valid fully qualified domain name.
  --organization-id: string # Organization ID when the connection is linked to an organization (nullable)
  --allow-organization-account-linking: oneof<nothing, bool> # Whether this connection supports account linking via organization membership (nullable)
  --active: oneof<nothing, bool> # Whether the enterprise connection is active. When true, IdP metadata must be provided via the `saml` object. (nullable)
  --saml: record # SAML connection-specific properties. Only applied when the enterprise connection uses SAML (e.g. provider is saml_custom). Use this to set IdP configuration, attribute mapping, and other SAML-specific settings at creation time. (nullable) — shape: {idp_entity_id?: string, idp_sso_url?: string, idp_certificate?: string, idp_metadata_url?: string, idp_metadata?: string, attribute_mapping?: record, allow_subdomains?: bool, allow_idp_initiated?: bool, force_authn?: bool}
  --oidc: record # OIDC connection-specific properties. Only applied when the enterprise connection uses OIDC (e.g. provider is oidc_custom, oidc_github_enterprise, or oidc_gitlab). (nullable) — shape: {client_id?: string, client_secret?: string, discovery_url?: string, auth_url?: string, token_url?: string, user_info_url?: string, requires_pkce?: bool}
  --custom-attributes: list # Custom attributes to map from the IdP to the user's profile via SSO or SCIM provisioning. Requires the custom attributes feature to be enabled for the instance. — item shape: {name: string, key: string, sso_path?: string, scim_path?: string, multi_valued?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enterprise_connections")
  let body = {name: $name, provider: $provider, domains: $domains, organization_id: $organization_id, allow_organization_account_linking: $allow_organization_account_linking, active: $active, saml: $saml, oidc: $oidc, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an enterprise connection
#
# GET /enterprise_connections/{enterprise_connection_id}
# operationId: GetEnterpriseConnection
export def "enterprise-connections GetEnterpriseConnection" [
  enterprise_connection_id: string
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
  let full_url = (build-url $base $"/enterprise_connections/($enterprise_connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an enterprise connection
#
# PATCH /enterprise_connections/{enterprise_connection_id}
# operationId: UpdateEnterpriseConnection
# --saml shape: {name?: string, idp_entity_id?: string, idp_sso_url?: string, idp_certificate?: string, idp_metadata_url?: string, idp_metadata?: string, attribute_mapping?: record, allow_subdomains?: bool, allow_idp_initiated?: bool, force_authn?: bool}
# --oidc shape: {client_id?: string, client_secret?: string, discovery_url?: string, auth_url?: string, token_url?: string, user_info_url?: string, requires_pkce?: bool}
# --custom_attributes item shape: {name: string, key: string, sso_path?: string, scim_path?: string, multi_valued?: bool}
export def "enterprise-connections UpdateEnterpriseConnection" [
  enterprise_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The display name of the enterprise connection (nullable)
  --domains: list # Domains associated with the enterprise connection. Values are normalized to lowercase. Empty array means ignored (no change); non-empty array means set domains to the given list (replaces existing). (nullable)
  --active: oneof<nothing, bool> # Whether the enterprise connection is active. When set to true (enabling), any existing verified organization domains for the same domain(s) will be removed so the connection can be enabled. (nullable)
  --sync-user-attributes: oneof<nothing, bool> # Whether to sync user attributes on sign-in (nullable)
  --disable-additional-identifications: oneof<nothing, bool> # Whether to disable additional identifications (nullable)
  --allow-organization-account-linking: oneof<nothing, bool> # Whether this connection supports account linking via organization membership (nullable)
  --organization-id: string # Organization ID to link to this enterprise connection. Only linking is supported; sending this field sets or changes the linked organization. There is no way to unlink an organization once linked. (nullable)
  --saml: record # SAML connection-specific properties. Only applied when the enterprise connection uses SAML. Use this to update IdP configuration, attribute mapping, and other SAML-specific settings. (nullable) — shape: {name?: string, idp_entity_id?: string, idp_sso_url?: string, idp_certificate?: string, idp_metadata_url?: string, idp_metadata?: string, attribute_mapping?: record, allow_subdomains?: bool, allow_idp_initiated?: bool, force_authn?: bool}
  --oidc: record # OIDC connection-specific properties. Only applied when the enterprise connection uses OIDC (e.g. oidc_custom, oidc_github_enterprise, or oidc_gitlab). (nullable) — shape: {client_id?: string, client_secret?: string, discovery_url?: string, auth_url?: string, token_url?: string, user_info_url?: string, requires_pkce?: bool}
  --custom-attributes: list # Custom attributes to map from the IdP to the user's profile via SSO or SCIM provisioning. Requires the custom attributes feature to be enabled for the instance. (nullable) — item shape: {name: string, key: string, sso_path?: string, scim_path?: string, multi_valued?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enterprise_connections/($enterprise_connection_id)")
  let body = {name: $name, domains: $domains, active: $active, sync_user_attributes: $sync_user_attributes, disable_additional_identifications: $disable_additional_identifications, allow_organization_account_linking: $allow_organization_account_linking, organization_id: $organization_id, saml: $saml, oidc: $oidc, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an enterprise connection
#
# DELETE /enterprise_connections/{enterprise_connection_id}
# operationId: DeleteEnterpriseConnection
export def "enterprise-connections DeleteEnterpriseConnection" [
  enterprise_connection_id: string
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
  let full_url = (build-url $base $"/enterprise_connections/($enterprise_connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List enterprise connection test runs
#
# GET /enterprise_connections/{enterprise_connection_id}/test_runs
# operationId: ListEnterpriseConnectionTestRuns
export def "enterprise-connections-test-runs ListEnterpriseConnectionTestRuns" [
  enterprise_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: list # Filter test runs by status (may be repeated)
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprise_connections/($enterprise_connection_id)/test_runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an enterprise connection test run
#
# POST /enterprise_connections/{enterprise_connection_id}/test_runs
# operationId: CreateEnterpriseConnectionTestRun
export def "enterprise-connections-test-runs CreateEnterpriseConnectionTestRun" [
  enterprise_connection_id: string
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
  let full_url = (build-url $base $"/enterprise_connections/($enterprise_connection_id)/test_runs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a new testing token
#
# POST /testing_tokens
# operationId: CreateTestingToken
export def "testing-tokens CreateTestingToken" [
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
  let full_url = (build-url $base "/testing_tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create agent task
#
# POST /agents/tasks
# operationId: CreateAgentTask
# --on_behalf_of shape: {user_id?: string, identifier?: string}
export def "agents-tasks CreateAgentTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  on_behalf_of: record # Identifies the user on whose behalf the agent task is created. Exactly one of user_id or identifier must be provided. — shape: {user_id?: string, identifier?: string}
  permissions: string@permissions-completer # The permissions granted to the agent task. Must be "*" (all permissions).
  agent_name: string # A name identifying the agent. Used to derive a stable agent_id per instance. Logged for audit purposes.
  task_description: string # A description of the task being performed. Logged for audit purposes.
  redirect_url: string # The URL the user is redirected to after the agent task is accepted. Must be a valid absolute URL with an `https` scheme in production instances. In development instances, `http` is also permitted. The URL's domain must belong to one of the instance's associated domains (primary or satellite); otherwise the redirect will be rejected when the task ticket is consumed. (format: uri)
  --session-max-duration-in-seconds: int # The maximum duration that the session which will be created by the generated agent task should last. By default, the duration of a session created via an agent task lasts 30 minutes. (default: 1800)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/agents/tasks")
  let body = {on_behalf_of: $on_behalf_of, permissions: $permissions, agent_name: $agent_name, task_description: $task_description, redirect_url: $redirect_url, session_max_duration_in_seconds: $session_max_duration_in_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke agent task
#
# POST /agents/tasks/{agent_task_id}/revoke
# operationId: RevokeAgentTask
export def "agents-tasks-revoke RevokeAgentTask" [
  agent_task_id: string
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
  let full_url = (build-url $base $"/agents/tasks/($agent_task_id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all organization memberships within an instance.
#
# GET /organization_memberships
# operationId: InstanceGetOrganizationMemberships
export def "organization-memberships InstanceGetOrganizationMemberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # Sorts organizations memberships by phone_number, email_address, created_at, first_name, last_name or username. By prepending one of those values with + or -, we can choose to sort in ascending (ASC) or descending (DESC) order.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all waitlist entries
#
# GET /waitlist_entries
# operationId: ListWaitlistEntries
export def "waitlist-entries ListWaitlistEntries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --qp-query: string # Filter waitlist entries by `email_address` or `id`
  --status: string@status-completer-2 # Filter waitlist entries by their status
  --order-by: string # Specify the order of results. Supported values are: - `created_at` - `email_address` - `invited_at`  Use `+` for ascending or `-` for descending order. Defaults to `-created_at`. (default: -created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/waitlist_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a waitlist entry
#
# POST /waitlist_entries
# operationId: CreateWaitlistEntry
export def "waitlist-entries CreateWaitlistEntry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email_address: string # The email address to add to the waitlist
  --notify: oneof<nothing, bool> # Optional flag which denotes whether a confirmation email should be sent to the given email address. Defaults to `true`. (nullable, default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/waitlist_entries")
  let body = {email_address: $email_address, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create multiple waitlist entries
#
# POST /waitlist_entries/bulk
# operationId: CreateBulkWaitlistEntries
export def "waitlist-entries-bulk CreateBulkWaitlistEntries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/waitlist_entries/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a pending waitlist entry
#
# DELETE /waitlist_entries/{waitlist_entry_id}
# operationId: DeleteWaitlistEntry
export def "waitlist-entries DeleteWaitlistEntry" [
  waitlist_entry_id: string
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
  let full_url = (build-url $base $"/waitlist_entries/($waitlist_entry_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite a waitlist entry
#
# POST /waitlist_entries/{waitlist_entry_id}/invite
# operationId: InviteWaitlistEntry
export def "waitlist-entries-invite InviteWaitlistEntry" [
  waitlist_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignore-existing: oneof<nothing, bool> # Whether an invitation should be created if there is already an existing invitation for this email address, or it's claimed by another user. (nullable, default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/waitlist_entries/($waitlist_entry_id)/invite")
  let body = {ignore_existing: $ignore_existing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reject a waitlist entry
#
# POST /waitlist_entries/{waitlist_entry_id}/reject
# operationId: RejectWaitlistEntry
export def "waitlist-entries-reject RejectWaitlistEntry" [
  waitlist_entry_id: string
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
  let full_url = (build-url $base $"/waitlist_entries/($waitlist_entry_id)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all billing plans
#
# GET /billing/plans
# operationId: GetCommercePlanList
export def "billing-plans GetCommercePlanList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --payer-type: string@payer-type-completer # Filter plans by payer type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "payer_type" $payer_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billing/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all billing prices
#
# GET /billing/prices
# operationId: GetBillingPriceList
export def "billing-prices GetBillingPriceList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --plan-id: string # Filter prices by plan ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "plan_id" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billing/prices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a custom billing price
#
# POST /billing/prices
# operationId: CreateBillingPrice
export def "billing-prices CreateBillingPrice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  plan_id: string # The ID of the plan this price belongs to.
  --currency: string # The currency code (e.g., "USD"). Defaults to USD. (default: USD)
  --amount: int # The monthly amount in cents. Must be at least $1 (100 cents) if not null. (nullable, format: int64)
  --annual-monthly-amount: int # The monthly amount in cents when billed annually. Must be at least $1 (100 cents) if not null. (nullable, format: int64)
  --description: string # An optional description for this custom price.
  --supported-billing-periods: string@supported-billing-periods-completer # Which billing periods this price supports. Inferred from amounts if omitted.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/prices")
  let body = {plan_id: $plan_id, currency: $currency, amount: $amount, annual_monthly_amount: $annual_monthly_amount, description: $description, supported_billing_periods: $supported_billing_periods} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all subscription items
#
# GET /billing/subscription_items
# operationId: GetCommerceSubscriptionItemList
export def "billing-subscription-items GetCommerceSubscriptionItemList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --status: string@status-completer-3 # Filter subscription items by status
  --payer-type: string@payer-type-completer # Filter subscription items by payer type
  --plan-id: string # Filter subscription items by plan ID
  --include-free: oneof<nothing, bool> # Whether to include free plan subscription items (default: false)
  --qp-query: string # Search query to filter subscription items
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "payer_type" $payer_type "scalar") (serialize-qp "plan_id" $plan_id "scalar") (serialize-qp "include_free" $include_free "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billing/subscription_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a subscription item
#
# DELETE /billing/subscription_items/{subscription_item_id}
# operationId: CancelCommerceSubscriptionItem
export def "billing-subscription-items CancelCommerceSubscriptionItem" [
  subscription_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-now: oneof<nothing, bool> # Whether to cancel the subscription immediately (true) or at the end of the current billing period (false, default) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "end_now" $end_now "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/subscription_items/($subscription_item_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Extend free trial for a subscription item
#
# POST /billing/subscription_items/{subscription_item_id}/extend_free_trial
# operationId: ExtendBillingSubscriptionItemFreeTrial
export def "billing-subscription-items-extend-free-trial ExtendBillingSubscriptionItemFreeTrial" [
  subscription_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  extend_to: string # RFC3339 timestamp to extend the free trial to. Must be in the future and not more than 365 days from now. (format: date-time, e.g. 2026-01-08T00:00:00Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billing/subscription_items/($subscription_item_id)/extend_free_trial")
  let body = {extend_to: $extend_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a price transition for a subscription item
#
# POST /billing/subscription_items/{subscription_item_id}/price_transition
# operationId: CreateBillingPriceTransition
export def "billing-subscription-items-price-transition CreateBillingPriceTransition" [
  subscription_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  from_price_id: string # The current price ID of the subscription item.
  to_price_id: string # The target price ID to transition to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billing/subscription_items/($subscription_item_id)/price_transition")
  let body = {from_price_id: $from_price_id, to_price_id: $to_price_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all billing statements
#
# GET /billing/statements
# operationId: GetBillingStatementList
export def "billing-statements GetBillingStatementList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billing/statements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a billing statement
#
# GET /billing/statements/{statementID}
# operationId: GetBillingStatement
export def "billing-statements GetBillingStatement" [
  statementID: string
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
  let full_url = (build-url $base $"/billing/statements/($statementID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List payment attempts for a billing statement
#
# GET /billing/statements/{statementID}/payment_attempts
# operationId: GetBillingStatementPaymentAttempts
export def "billing-statements-payment-attempts GetBillingStatementPaymentAttempts" [
  statementID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginated: oneof<nothing, bool> # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paginated" $paginated "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/statements/($statementID)/payment_attempts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all organization permissions
#
# GET /organization_permissions
# operationId: ListOrganizationPermissions
export def "organization-permissions ListOrganizationPermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Returns organization permissions with ID, name, or key that match the given query. Uses exact match for permission ID and partial match for name and key.
  --order-by: string # Allows to return organization permissions in a particular order. At the moment, you can order the returned permissions by their `created_at`, `name`, or `key`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want permissions to be returned in descending order according to their `created_at` property, you can use `-created_at`.
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization_permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new organization permission
#
# POST /organization_permissions
# operationId: CreateOrganizationPermission
export def "organization-permissions CreateOrganizationPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the permission.
  key: string # The key of the permission. Must have the format "org:feature:action" where feature and action are segments consisting of lowercase letters, digits, or underscores, for example "org:billing:manage" or "org:team:read". Cannot begin with "org:sys_" as that prefix is reserved for system permissions.
  --description: string # A description of the permission.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization_permissions")
  let body = {name: $name, key: $key, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an organization permission
#
# GET /organization_permissions/{permission_id}
# operationId: GetOrganizationPermission
export def "organization-permissions GetOrganizationPermission" [
  permission_id: string
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
  let full_url = (build-url $base $"/organization_permissions/($permission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization permission
#
# PATCH /organization_permissions/{permission_id}
# operationId: UpdateOrganizationPermission
export def "organization-permissions UpdateOrganizationPermission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the permission.
  --key: string # The key of the permission. Must have the format "org:feature:action" where feature and action are segments consisting of lowercase letters, digits, or underscores. Cannot begin with "org:sys_" as that prefix is reserved for system permissions.
  --description: string # A description of the permission.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization_permissions/($permission_id)")
  let body = {name: $name, key: $key, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an organization permission
#
# DELETE /organization_permissions/{permission_id}
# operationId: DeleteOrganizationPermission
export def "organization-permissions DeleteOrganizationPermission" [
  permission_id: string
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
  let full_url = (build-url $base $"/organization_permissions/($permission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of role sets
#
# GET /role_sets
# operationId: ListRoleSets
export def "role-sets ListRoleSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Returns role sets with ID, name, or key that match the given query. Uses exact match for role set ID and partial match for name and key.
  --order-by: string # Allows to return role sets in a particular order. At the moment, you can order the returned role sets by their `created_at`, `name`, or `key`. In order to specify the direction, you can use the `+/-` symbols prepended in the property to order by. For example, if you want role sets to be returned in descending order according to their `created_at` property, you can use `-created_at`. If you don't use `+` or `-`, then `+` is implied. Defaults to `-created_at`. (default: -created_at)
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/role_sets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role set
#
# POST /role_sets
# operationId: CreateRoleSet
export def "role-sets CreateRoleSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new role set
  --key: string # A unique key for the role set. Must start with 'role_set:' and contain only lowercase alphanumeric characters and underscores. If not provided, a key will be generated from the name.
  --description: string # Optional description for the role set (nullable)
  default_role_key: string # The key of the role to use as the default role for new organization members. Must be one of the roles in the `roles` array.
  creator_role_key: string # The key of the role to assign to organization creators. Must be one of the roles in the `roles` array.
  --type: string@type-completer # The type of the role set. "initial" role sets are the default for new organizations. Only one role set can be "initial" per instance.
  roles: list # Array of role keys to include in the role set. Must contain at least one role and no more than 10 roles.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/role_sets")
  let body = {name: $name, key: $key, description: $description, default_role_key: $default_role_key, creator_role_key: $creator_role_key, type: $type, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a role set
#
# GET /role_sets/{role_set_key_or_id}
# operationId: GetRoleSet
export def "role-sets GetRoleSet" [
  role_set_key_or_id: string
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
  let full_url = (build-url $base $"/role_sets/($role_set_key_or_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role set
#
# PATCH /role_sets/{role_set_key_or_id}
# operationId: UpdateRoleSet
export def "role-sets UpdateRoleSet" [
  role_set_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the role set (nullable)
  --key: string # A unique key for the role set. Must start with 'role_set:' and contain only lowercase alphanumeric characters and underscores. (nullable)
  --description: string # Optional description for the role set (nullable)
  --type: string@type-completer-1 # Set to "initial" to make this the default role set for new organizations. Only one role set can be "initial" per instance; setting this will change any existing initial role set to "custom". (nullable)
  --default-role-key: string # The key of the role to use as the default role for new organization members. Must be an existing role in the role set. (nullable)
  --creator-role-key: string # The key of the role to assign to organization creators. Must be an existing role in the role set. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/role_sets/($role_set_key_or_id)")
  let body = {name: $name, key: $key, description: $description, type: $type, default_role_key: $default_role_key, creator_role_key: $creator_role_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace a role set
#
# POST /role_sets/{role_set_key_or_id}/replace
# operationId: ReplaceRoleSet
export def "role-sets-replace ReplaceRoleSet" [
  role_set_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dest_role_set_key: string # The key of the destination role set
  --reassignment-mappings: any # Mappings from source role keys to destination role keys. Required if members have roles that need to be reassigned.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/role_sets/($role_set_key_or_id)/replace")
  let body = {dest_role_set_key: $dest_role_set_key, reassignment_mappings: $reassignment_mappings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add roles to a role set
#
# POST /role_sets/{role_set_key_or_id}/roles
# operationId: AddRolesToRoleSet
export def "role-sets-roles AddRolesToRoleSet" [
  role_set_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role_keys: list # Array of role keys to add to the role set. Must contain at least one role and no more than 10 roles.
  --default-role-key: string # Optionally update the default role to one of the newly added roles.
  --creator-role-key: string # Optionally update the creator role to one of the newly added roles.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/role_sets/($role_set_key_or_id)/roles")
  let body = {role_keys: $role_keys, default_role_key: $default_role_key, creator_role_key: $creator_role_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace a role in a role set
#
# POST /role_sets/{role_set_key_or_id}/roles/replace
# operationId: ReplaceRoleInRoleSet
export def "role-sets-roles-replace ReplaceRoleInRoleSet" [
  role_set_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role_key: string # The key of the role to remove from the role set
  to_role_key: string # The key of the role to reassign members to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/role_sets/($role_set_key_or_id)/roles/replace")
  let body = {role_key: $role_key, to_role_key: $to_role_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an Admin Portal Link Token
#
# POST /admin_portal_link_tokens
# operationId: createAdminPortalLinkToken
export def "admin-portal-link-tokens createAdminPortalLinkToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string
  --it-contact-id: string
  --scopes: list
  --seconds-until-expiration: int # default: 3600
]: any -> record<object: string, id: string, admin_portal_link_id: string, instance_id: string, organization_id: string, it_contact_id: string, scopes: list<string>, token: string, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin_portal_link_tokens")
  let body = {organization_id: $organization_id, it_contact_id: $it_contact_id, scopes: $scopes, seconds_until_expiration: $seconds_until_expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke an Admin Portal Link Token
#
# POST /admin_portal_link_tokens/{adminPortalLinkTokenID}/revoke
# operationId: revokeAdminPortalLinkToken
export def "admin-portal-link-tokens-revoke revokeAdminPortalLinkToken" [
  adminPortalLinkTokenID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revocation-reason: string # nullable
]: any -> record<object: string, id: string, admin_portal_link_id: string, instance_id: string, organization_id: string, it_contact_id: string, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin_portal_link_tokens/($adminPortalLinkTokenID)/revoke")
  let body = {revocation_reason: $revocation_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an API Key
#
# POST /api_keys
# operationId: createApiKey
export def "api-keys createApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # default: api_key
  name: string
  --description: string # nullable
  subject: string
  --claims: any # nullable
  --scopes: list # default: []
  --created-by: string # nullable
  --seconds-until-expiration: float # nullable
]: any -> record<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list<string>, secret: string, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_keys")
  let body = {type: $type, name: $name, description: $description, subject: $subject, claims: $claims, scopes: $scopes, created_by: $created_by, seconds_until_expiration: $seconds_until_expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get API Keys
#
# GET /api_keys
# operationId: getApiKeys
export def "api-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # default: api_key
  --subject: string
  --include-invalid: string@include-invalid-completer # default: false
  --limit: float # default: 10
  --offset: float # nullable, default: 0
  --qp-query: string
]: nothing -> record<data: table<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float>, total_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "include_invalid" $include_invalid "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an API Key by ID
#
# GET /api_keys/{apiKeyID}
# operationId: getApiKey
export def "api-keys get" [
  apiKeyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($apiKeyID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an API Key
#
# PATCH /api_keys/{apiKeyID}
# operationId: updateApiKey
export def "api-keys updateApiKey" [
  apiKeyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --claims: any # nullable
  --scopes: list
  --description: string # nullable
  --subject: string
  --seconds-until-expiration: float # nullable
]: any -> record<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($apiKeyID)")
  let body = {claims: $claims, scopes: $scopes, description: $description, subject: $subject, seconds_until_expiration: $seconds_until_expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an API Key
#
# DELETE /api_keys/{apiKeyID}
# operationId: deleteApiKey
export def "api-keys delete" [
  apiKeyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($apiKeyID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an API Key Secret
#
# GET /api_keys/{apiKeyID}/secret
# operationId: getApiKeySecret
export def "api-keys-secret get" [
  apiKeyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($apiKeyID)/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke an API Key
#
# POST /api_keys/{apiKeyID}/revoke
# operationId: revokeApiKey
export def "api-keys-revoke revokeApiKey" [
  apiKeyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revocation-reason: string # nullable
]: any -> record<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($apiKeyID)/revoke")
  let body = {revocation_reason: $revocation_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify an API Key
#
# POST /api_keys/verify
# operationId: verifyApiKey
export def "api-keys-verify verifyApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  secret: string
]: any -> record<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_keys/verify")
  let body = {secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a M2M Token
#
# POST /m2m_tokens
# operationId: createM2MToken
export def "m2m-tokens createM2MToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --token-format: string@token-format-completer # default: opaque
  --seconds-until-expiration: float # nullable
  --claims: any # nullable
  --min-remaining-ttl-seconds: int # Enables server-side token reuse for opaque-format tokens. When set, if a non-revoked, non-expired M2M token already exists for this machine with identical `claims` and `scopes` and at least this many seconds of remaining lifetime, that existing token is returned and no new token is minted.  Use this when caching tokens in application memory across requests is impractical — for example, in serverless functions, short-lived job workers, or autoscaling containers that churn faster than the token TTL. Pooling at the server collapses many redundant create calls into reuse of a single live token, which is the recommended pattern for high-volume M2M traffic.  Must be strictly less than the effective token lifetime — that is, `seconds_until_expiration` when provided, or the machine's default TTL otherwise. A value greater than or equal to the lifetime is rejected with a 400, since no freshly-minted token would ever satisfy the requirement.  Only applies to opaque-format tokens (`token_format` defaults to `opaque`). JWT-format tokens are stateless and are never deduplicated. (e.g. 240)
]: any -> record<object: string, id: string, subject: string, claims: any, scopes: list<string>, token: string, revoked: bool, revocation_reason: string, expired: bool, expiration: float, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/m2m_tokens")
  let body = {token_format: $token_format, seconds_until_expiration: $seconds_until_expiration, claims: $claims, min_remaining_ttl_seconds: $min_remaining_ttl_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get M2M Tokens
#
# GET /m2m_tokens
# operationId: getM2MTokens
export def "m2m-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string
  --revoked: oneof<nothing, bool> # nullable, default: false
  --expired: oneof<nothing, bool> # nullable, default: false
  --limit: float # default: 10
  --offset: float # nullable, default: 0
]: nothing -> record<m2m_tokens: table<object: string, id: string, subject: string, claims: any, scopes: list, revoked: bool, revocation_reason: string, expired: bool, expiration: float, last_used_at: float, created_at: float, updated_at: float>, total_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "scalar") (serialize-qp "revoked" $revoked "scalar") (serialize-qp "expired" $expired "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/m2m_tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke a M2M Token
#
# POST /m2m_tokens/{m2m_token_id}/revoke
# operationId: revokeM2MToken
export def "m2m-tokens-revoke revokeM2MToken" [
  m2m_token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revocation-reason: string # nullable
]: any -> record<object: string, id: string, subject: string, claims: any, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/m2m_tokens/($m2m_token_id)/revoke")
  let body = {revocation_reason: $revocation_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify a M2M Token
#
# POST /m2m_tokens/verify
# operationId: verifyM2MToken
export def "m2m-tokens-verify verifyM2MToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
]: any -> record<object: string, id: string, subject: string, claims: any, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/m2m_tokens/verify")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify an OAuth Access Token
#
# POST /oauth_applications/access_tokens/verify
# operationId: verifyOAuthAccessToken
@deprecated --flag secret
export def "oauth-applications-access-tokens-verify verifyOAuthAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The access token to verify. (e.g. XXXXXXXXXXXXXX)
  --secret: string # The access token to verify. This is deprecated, use `access_token` instead. (DEPRECATED, e.g. XXXXXXXXXXXXXX)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth_applications/access_tokens/verify")
  let body = {access_token: $access_token, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
