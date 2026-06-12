# Auto-generated client for  v1.0.0
# Source: https://api.apis.guru/v2/specs/ote-godaddy.com/certificates/1.0.0/openapi.json
# Auth: --token flag or $env._TOKEN

const BASE_URL = "http://localhost//api.ote-godaddy.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o _TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost//api.ote-godaddy.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def productType-completer [] { ["DV_SSL" "DV_WILDCARD_SSL" "EV_SSL" "OV_CS" "OV_DS" "OV_SSL" "OV_WILDCARD_SSL" "UCC_DV_SSL" "UCC_EV_SSL" "UCC_OV_SSL"] }
def rootType-completer [] { ["GODADDY_SHA_1" "GODADDY_SHA_2" "STARFIELD_SHA_1" "STARFIELD_SHA_2"] }
def slotSize-completer [] { ["FIFTEEN" "FIFTY" "FIVE" "FOURTY" "ONE_HUNDRED" "TEN" "THIRTY" "TWENTY"] }
def reason-completer [] { ["AFFILIATION_CHANGED" "CESSATION_OF_OPERATION" "KEY_COMPROMISE" "PRIVILEGE_WITHDRAWN" "SUPERSEDED"] }
def theme-completer [] { ["DARK" "LIGHT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "certificates create" } } | get name | first)
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

# Create a pending order for certificate
#
# POST /v1/certificates
# operationId: certificate_create
# --contact shape: {email: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, phone: string, suffix?: string}
# --organization shape: {address?: any, assumedName?: string, name: string, phone: string, registrationAgent?: string, registrationNumber?: string}
export def "certificates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Market-Id: string # Setting locale for communications such as emails and error messages
  --callbackUrl: string # Required if client would like to receive stateful actions via callback during certificate lifecyle
  --commonName: string # Name to be secured in certificate. If provided, CN field in CSR will be ignored.
  contact: any # shape: {email: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, phone: string, suffix?: string}
  csr: string # Certificate Signing Request
  --intelVPro: oneof<nothing, bool> # Only used for OV (default: false)
  --organization: any # shape: {address?: any, assumedName?: string, name: string, phone: string, registrationAgent?: string, registrationNumber?: string}
  period: int # Number of years for certificate validity period
  productType: string@productType-completer # Type of product requesting a certificate. Only required non-renewal
  --rootType: string@rootType-completer # Root Type. Depending on certificate expiration date, SHA_1 not be allowed. Will default to SHA_2 if expiration date exceeds sha1 allowed date (default: STARFIELD_SHA_2)
  --slotSize: string@slotSize-completer # Number of subject alternative names(SAN) to be included in certificate 
  --subjectAlternativeNames: list # Subject Alternative names. Collection of subjectAlternativeNames to be included in certificate.
]: any -> record<certificateId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/certificates")
  let body = {callbackUrl: $callbackUrl, commonName: $commonName, contact: $contact, csr: $csr, intelVPro: $intelVPro, organization: $organization, period: $period, productType: $productType, rootType: $rootType, slotSize: $slotSize, subjectAlternativeNames: $subjectAlternativeNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Market-Id": $X_Market_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate a pending order for certificate
#
# POST /v1/certificates/validate
# operationId: certificate_validate
# --contact shape: {email: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, phone: string, suffix?: string}
# --organization shape: {address?: any, assumedName?: string, name: string, phone: string, registrationAgent?: string, registrationNumber?: string}
export def "certificates-validate validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Market-Id: string # Setting locale for communications such as emails and error messages
  --callbackUrl: string # Required if client would like to receive stateful actions via callback during certificate lifecyle
  --commonName: string # Name to be secured in certificate. If provided, CN field in CSR will be ignored.
  contact: any # shape: {email: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, phone: string, suffix?: string}
  csr: string # Certificate Signing Request
  --intelVPro: oneof<nothing, bool> # Only used for OV (default: false)
  --organization: any # shape: {address?: any, assumedName?: string, name: string, phone: string, registrationAgent?: string, registrationNumber?: string}
  period: int # Number of years for certificate validity period
  productType: string@productType-completer # Type of product requesting a certificate. Only required non-renewal
  --rootType: string@rootType-completer # Root Type. Depending on certificate expiration date, SHA_1 not be allowed. Will default to SHA_2 if expiration date exceeds sha1 allowed date (default: STARFIELD_SHA_2)
  --slotSize: string@slotSize-completer # Number of subject alternative names(SAN) to be included in certificate 
  --subjectAlternativeNames: list # Subject Alternative names. Collection of subjectAlternativeNames to be included in certificate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/certificates/validate")
  let body = {callbackUrl: $callbackUrl, commonName: $commonName, contact: $contact, csr: $csr, intelVPro: $intelVPro, organization: $organization, period: $period, productType: $productType, rootType: $rootType, slotSize: $slotSize, subjectAlternativeNames: $subjectAlternativeNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Market-Id": $X_Market_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve certificate details
#
# GET /v1/certificates/{certificateId}
# operationId: certificate_get
export def "certificates get" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificateId: string, commonName: string, contact: record<email: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, phone: string, suffix: string>, createdAt: string, deniedReason: string, organization: record<address: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, assumedName: string, jurisdictionOfIncorporation: record<city: string, country: string, county: string, state: string>, name: string, phone: string, registrationAgent: string, registrationNumber: string>, period: int, productType: string, progress: int, revokedAt: string, rootType: string, serialNumber: string, serialNumberHex: string, slotSize: string, status: string, subjectAlternativeNames: table<status: string, subjectAlternativeName: string>, validEnd: string, validStart: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all certificate actions
#
# GET /v1/certificates/{certificateId}/actions
# operationId: certificate_action_retrieve
export def "certificates-actions get" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdAt: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unregister system callback
#
# DELETE /v1/certificates/{certificateId}/callback
# operationId: certificate_callback_delete
export def "certificates-callback delete" [
  certificateId: string
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
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/callback")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve system stateful action callback url
#
# GET /v1/certificates/{certificateId}/callback
# operationId: certificate_callback_get
export def "certificates-callback get" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callbackUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/callback")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register of certificate action callback
#
# PUT /v1/certificates/{certificateId}/callback
# operationId: certificate_callback_replace
export def "certificates-callback replace" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callbackUrl: string # Callback url registered/replaced to receive stateful actions
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callbackUrl" $callbackUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/callback" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a pending certificate
#
# POST /v1/certificates/{certificateId}/cancel
# operationId: certificate_cancel
export def "certificates-cancel cancel" [
  certificateId: string
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
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download certificate
#
# GET /v1/certificates/{certificateId}/download
# operationId: certificate_download
export def "certificates-download download" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pems: record<certificate: string, cross: string, intermediate: string, root: string>, serialNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve email history
#
# GET /v1/certificates/{certificateId}/email/history
# operationId: certificate_email_history
export def "certificates-email-history history" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountId: int, body: string, dateEntered: string, fromType: string, id: int, recipients: string, subject: string, templateType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/email/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add alternate email address
#
# POST /v1/certificates/{certificateId}/email/resend/{emailAddress}
# operationId: certificate_alternate_email_address
export def "certificates-email-resend address-by-certificateId-emailAddress" [
  certificateId: string
  emailAddress: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountId: int, body: string, dateEntered: string, fromType: string, id: int, recipients: string, subject: string, templateType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/email/resend/($emailAddress)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend an email
#
# POST /v1/certificates/{certificateId}/email/{emailId}/resend
# operationId: certificate_resend_email
export def "certificates-email-resend email" [
  certificateId: string
  emailId: string
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
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/email/($emailId)/resend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend email to email address
#
# POST /v1/certificates/{certificateId}/email/{emailId}/resend/{emailAddress}
# operationId: certificate_resend_email_address
export def "certificates-email-resend address-by-certificateId-emailId-emailAddress" [
  certificateId: string
  emailId: string
  emailAddress: string
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
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/email/($emailId)/resend/($emailAddress)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reissue active certificate
#
# POST /v1/certificates/{certificateId}/reissue
# operationId: certificate_reissue
export def "certificates-reissue reissue" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callbackUrl: string # Required if client would like to receive stateful action via callback during certificate lifecyle
  --commonName: string # The common name of certificate to be secured (default: Existing common name)
  --csr: string # Certificate Signing Request. (default: Existing CSR)
  --delayExistingRevoke: int # In hours, time to delay revoking existing certificate after issuance of new certificate. If revokeExistingCertOnIssuance is enabled, this value will be ignored (default: 72)
  --forceDomainRevetting: list # Optional field. Domain verification will be required for each domain listed here. Specify a value of * to indicate that all domains associated with the request should have their domain information reverified.
  --rootType: string@rootType-completer # Root Type. Depending on certificate expiration date, SHA_1 not be allowed. Will default to SHA_2 if expiration date exceeds sha1 allowed date (default: GODADDY_SHA_1)
  --subjectAlternativeNames: list # Only used for UCC products. An array of subject alternative names to include in certificate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/reissue")
  let body = {callbackUrl: $callbackUrl, commonName: $commonName, csr: $csr, delayExistingRevoke: $delayExistingRevoke, forceDomainRevetting: $forceDomainRevetting, rootType: $rootType, subjectAlternativeNames: $subjectAlternativeNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Renew active certificate
#
# POST /v1/certificates/{certificateId}/renew
# operationId: certificate_renew
export def "certificates-renew renew" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callbackUrl: string # Required if client would like to receive stateful actions via callback during certificate lifecyle
  --commonName: string # The common name of certificate to be secured (default: Existing common name)
  --csr: string # Certificate Signing Request. (default: Existing CSR)
  --period: int # Number of years for certificate validity period, if different from previous certificate (default: 0)
  --rootType: string@rootType-completer # Root Type. Depending on certificate expiration date, SHA_1 not be allowed. Will default to SHA_2 if expiration date exceeds sha1 allowed date (default: GODADDY_SHA_1)
  --subjectAlternativeNames: list # Only used for UCC products. An array of subject alternative names to include in certificate. Not including a subject alternative name that was in the previous certificate will remove it from the renewed certificate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/renew")
  let body = {callbackUrl: $callbackUrl, commonName: $commonName, csr: $csr, period: $period, rootType: $rootType, subjectAlternativeNames: $subjectAlternativeNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke active certificate
#
# POST /v1/certificates/{certificateId}/revoke
# operationId: certificate_revoke
export def "certificates-revoke revoke" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string@reason-completer # Reason for revocation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/revoke")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Site seal
#
# GET /v1/certificates/{certificateId}/siteSeal
# operationId: certificate_siteseal_get
export def "certificates-site-seal get" [
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --theme: string@theme-completer # This value represents the visual theme of the seal. If seal doesn't exist, default values are used if params not present. If seal does exist, default values will not be used to update unless params present. (default: LIGHT)
  --locale: string # Determine locale for text displayed in seal image and verification page. If seal doesn't exist, default values are used if params not present. If seal does exist, default values will not be used to update unless params present. (default: en)
]: nothing -> record<html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "theme" $theme "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/siteSeal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check Domain Control
#
# POST /v1/certificates/{certificateId}/verifyDomainControl
# operationId: certificate_verifydomaincontrol
export def "certificates-verify-domain-control verifydomaincontrol" [
  certificateId: string
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
  let full_url = (build-url $base $"/v1/certificates/($certificateId)/verifyDomainControl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for certificate details by entitlement
#
# GET /v2/certificates
# operationId: certificate_get_entitlement
export def "certificates entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entitlementId: string # Entitlement id to lookup
  --latest: oneof<nothing, bool> # Fetch only the most recent certificate (default: true)
]: nothing -> table<certificateId: string, commonName: string, contact: record<email: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, phone: string, suffix: string>, createdAt: string, deniedReason: string, organization: record<address: record, assumedName: string, jurisdictionOfIncorporation: record, name: string, phone: string, registrationAgent: string, registrationNumber: string>, period: int, productType: string, progress: int, revokedAt: string, rootType: string, serialNumber: string, serialNumberHex: string, slotSize: string, status: string, subjectAlternativeNames: list<record>, validEnd: string, validStart: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entitlementId" $entitlementId "scalar") (serialize-qp "latest" $latest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download certificate by entitlement
#
# GET /v2/certificates/download
# operationId: certificate_download_entitlement
export def "certificates-download entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entitlementId: string # Entitlement id to download
]: nothing -> record<pems: record<certificate: string, cross: string, intermediate: string, root: string>, serialNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entitlementId" $entitlementId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/certificates/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve customer's certificates
#
# GET /v2/customers/{customerId}/certificates
# operationId: getCustomerCertificatesByCustomerId
export def "customers-certificates list" [
  customerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number of results to skip for pagination (format: integer-positive)
  --limit: int # Maximum number of items to return (format: integer-positive)
]: nothing -> record<certificates: table<certificateId: string, commonName: string, completedAt: string, createdAt: string, period: int, renewalAvailable: bool, revokedAt: string, serialNumber: string, slotSize: string, status: string, subjectAlternativeNames: list, type: string, validEndAt: string, validStartAt: string>, pagination: record<first: string, last: string, next: string, previous: string, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customers/($customerId)/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the external account binding for the specified customer
#
# GET /v2/customers/{customerId}/certificates/acme/externalAccountBinding
# operationId: getAcmeExternalAccountBinding
export def "customers-certificates-acme-external-account-binding get" [
  customerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<directoryUrl: string, hmacKey: string, keyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customerId)/certificates/acme/externalAccountBinding")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve individual certificate details
#
# GET /v2/customers/{customerId}/certificates/{certificateId}
# operationId: getCertificateDetailByCertIdentifier
export def "customers-certificates get" [
  customerId: string
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificateId: string, commonName: string, completedAt: string, contact: record<email: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, phone: string, suffix: string>, createdAt: string, csr: string, deniedReason: string, organization: record<address: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, assumedName: string, jurisdictionOfIncorporation: record<city: string, country: string, county: string, state: string>, name: string, phone: string, registrationAgent: string, registrationNumber: string>, period: int, progress: int, renewalAvailable: bool, revokedAt: string, rootType: string, serialNumber: string, serialNumberHex: string, slotSize: string, status: string, subjectAlternativeNames: list<string>, type: string, validEndAt: string, validStartAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customerId)/certificates/($certificateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve domain verification status
#
# GET /v2/customers/{customerId}/certificates/{certificateId}/domainVerifications
# operationId: getDomainInformationByCertificateId
export def "customers-certificates-domain-verifications list" [
  customerId: string
  certificateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdAt: string, dceToken: string, domain: string, domainEntityId: int, modifiedAt: string, status: string, type: string, usage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customerId)/certificates/($certificateId)/domainVerifications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve detailed information for supplied domain
#
# GET /v2/customers/{customerId}/certificates/{certificateId}/domainVerifications/{domain}
# operationId: getDomainDetailsByDomain
export def "customers-certificates-domain-verifications get" [
  customerId: string
  certificateId: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, dceToken: string, domain: string, domainEntityId: int, modifiedAt: string, status: string, type: string, usage: string, certificateAuthorityAuthorization: record<completedAt: string, queryPaths: list<string>, recommendations: list<string>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customers/($customerId)/certificates/($certificateId)/domainVerifications/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
