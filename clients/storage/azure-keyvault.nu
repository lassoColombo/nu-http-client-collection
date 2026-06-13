# Auto-generated client for KeyVaultClient v7.0-preview
# Source: https://api.apis.guru/v2/specs/azure.com/keyvault/7.0-preview/swagger.json
# Auth: --token flag or $env.KEYVAULTCLIENT_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KEYVAULTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def crv-completer [] { ["P-256" "P-256K" "P-384" "P-521"] }
def kty-completer [] { ["EC" "EC-HSM" "RSA" "RSA-HSM" "oct"] }
def alg-completer [] { ["RSA-OAEP" "RSA-OAEP-256" "RSA1_5"] }
def alg-completer-1 [] { ["ES256" "ES256K" "ES384" "ES512" "PS256" "PS384" "PS512" "RS256" "RS384" "RS512" "RSNULL"] }
def sasType-completer [] { ["account" "service"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "certificates GetCertificates" } } | get name | first)
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

# List certificates in a specified key vault
#
# GET /certificates
# operationId: GetCertificates
export def "certificates GetCertificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --includePending: oneof<nothing, bool> # Specifies whether to include certificates which are not completely provisioned.
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, id: string, tags: record, x5t: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "includePending" $includePending "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the certificate contacts for a specified key vault.
#
# DELETE /certificates/contacts
# operationId: DeleteCertificateContacts
export def "certificates-contacts DeleteCertificateContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<contacts: table<email: string, name: string, phone: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the certificate contacts for a specified key vault.
#
# GET /certificates/contacts
# operationId: GetCertificateContacts
export def "certificates-contacts GetCertificateContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<contacts: table<email: string, name: string, phone: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the certificate contacts for the specified key vault.
#
# PUT /certificates/contacts
# operationId: SetCertificateContacts
# --contacts item shape: {email?: string, name?: string, phone?: string}
export def "certificates-contacts SetCertificateContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --contacts: list # The contact list for the vault certificates. — item shape: {email?: string, name?: string, phone?: string}
]: any -> record<contacts: table<email: string, name: string, phone: string>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/contacts" $qp)
  let body = {contacts: $contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List certificate issuers for a specified key vault.
#
# GET /certificates/issuers
# operationId: GetCertificateIssuers
export def "certificates-issuers GetCertificateIssuers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<id: string, provider: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/issuers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified certificate issuer.
#
# DELETE /certificates/issuers/{issuer-name}
# operationId: DeleteCertificateIssuer
export def "certificates-issuers DeleteCertificateIssuer" [
  issuer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/issuers/($issuer_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the specified certificate issuer.
#
# GET /certificates/issuers/{issuer-name}
# operationId: GetCertificateIssuer
export def "certificates-issuers GetCertificateIssuer" [
  issuer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/issuers/($issuer_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified certificate issuer.
#
# PATCH /certificates/issuers/{issuer-name}
# operationId: UpdateCertificateIssuer
# --attributes shape: {enabled?: bool}
# --credentials shape: {account_id?: string, pwd?: string}
# --org_details shape: {admin_details?: list, id?: string}
export def "certificates-issuers UpdateCertificateIssuer" [
  issuer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The attributes of an issuer managed by the Key Vault service. — shape: {enabled?: bool}
  --credentials: any # The credentials to be used for the certificate issuer. — shape: {account_id?: string, pwd?: string}
  --org-details: any # Details of the organization of the certificate issuer. — shape: {admin_details?: list, id?: string}
  --provider: string # The issuer provider.
]: any -> record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/issuers/($issuer_name)" $qp)
  let body = {attributes: $attributes, credentials: $credentials, org_details: $org_details, provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets the specified certificate issuer.
#
# PUT /certificates/issuers/{issuer-name}
# operationId: SetCertificateIssuer
# --attributes shape: {enabled?: bool}
# --credentials shape: {account_id?: string, pwd?: string}
# --org_details shape: {admin_details?: list, id?: string}
export def "certificates-issuers SetCertificateIssuer" [
  issuer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The attributes of an issuer managed by the Key Vault service. — shape: {enabled?: bool}
  --credentials: any # The credentials to be used for the certificate issuer. — shape: {account_id?: string, pwd?: string}
  --org-details: any # Details of the organization of the certificate issuer. — shape: {admin_details?: list, id?: string}
  provider: string # The issuer provider.
]: any -> record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/issuers/($issuer_name)" $qp)
  let body = {attributes: $attributes, credentials: $credentials, org_details: $org_details, provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a backed up certificate to a vault.
#
# POST /certificates/restore
# operationId: RestoreCertificate
export def "certificates-restore RestoreCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  value: string # The backup blob associated with a certificate bundle. (format: base64url)
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/restore" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a certificate from a specified key vault.
#
# DELETE /certificates/{certificate-name}
# operationId: DeleteCertificate
export def "certificates DeleteCertificate" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Backs up the specified certificate.
#
# POST /certificates/{certificate-name}/backup
# operationId: BackupCertificate
export def "certificates-backup BackupCertificate" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/backup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new certificate.
#
# POST /certificates/{certificate-name}/create
# operationId: CreateCertificate
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --policy shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
export def "certificates-create CreateCertificate" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --policy: any # Management policy for a certificate. — shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/create" $qp)
  let body = {attributes: $attributes, policy: $policy, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Imports a certificate into a specified key vault.
#
# POST /certificates/{certificate-name}/import
# operationId: ImportCertificate
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --policy shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
export def "certificates-import ImportCertificate" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --policy: any # Management policy for a certificate. — shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
  --pwd: string # If the private key in base64EncodedCertificate is encrypted, the password used for encryption.
  --tags: record # Application specific metadata in the form of key-value pairs.
  value: string # Base64 encoded representation of the certificate object to import. This certificate needs to contain the private key.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/import" $qp)
  let body = {attributes: $attributes, policy: $policy, pwd: $pwd, tags: $tags, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the creation operation for a specific certificate.
#
# DELETE /certificates/{certificate-name}/pending
# operationId: DeleteCertificateOperation
export def "certificates-pending DeleteCertificateOperation" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the creation operation of a certificate.
#
# GET /certificates/{certificate-name}/pending
# operationId: GetCertificateOperation
export def "certificates-pending GetCertificateOperation" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a certificate operation.
#
# PATCH /certificates/{certificate-name}/pending
# operationId: UpdateCertificateOperation
export def "certificates-pending UpdateCertificateOperation" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --cancellation-requested: oneof<nothing, bool> # Indicates if cancellation was requested on the certificate operation.
]: any -> record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/pending" $qp)
  let body = {cancellation_requested: $cancellation_requested} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Merges a certificate or a certificate chain with a key pair existing on the server.
#
# POST /certificates/{certificate-name}/pending/merge
# operationId: MergeCertificate
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "certificates-pending-merge MergeCertificate" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --tags: record # Application specific metadata in the form of key-value pairs.
  x5c: list # The certificate or the certificate chain to merge.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/pending/merge" $qp)
  let body = {attributes: $attributes, tags: $tags, x5c: $x5c} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the policy for a certificate.
#
# GET /certificates/{certificate-name}/policy
# operationId: GetCertificatePolicy
export def "certificates-policy GetCertificatePolicy" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: table<action: record, trigger: record>, secret_props: record<contentType: string>, x509_props: record<ekus: list<string>, key_usage: list<string>, sans: record<dns_names: list, emails: list, upns: list>, subject: string, validity_months: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/policy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the policy for a certificate.
#
# PATCH /certificates/{certificate-name}/policy
# operationId: UpdateCertificatePolicy
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --issuer shape: {cert_transparency?: bool, cty?: string, name?: string}
# --key_props shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", exportable?: bool, key_size?: int, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", reuse_key?: bool}
# --lifetime_actions item shape: {action?: any, trigger?: any}
# --secret_props shape: {contentType?: string}
# --x509_props shape: {ekus?: list, key_usage?: list, sans?: any, subject?: string, validity_months?: int}
export def "certificates-policy UpdateCertificatePolicy" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --issuer: any # Parameters for the issuer of the X509 component of a certificate. — shape: {cert_transparency?: bool, cty?: string, name?: string}
  --key-props: any # Properties of the key pair backing a certificate. — shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", exportable?: bool, key_size?: int, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", reuse_key?: bool}
  --lifetime-actions: list # Actions that will be performed by Key Vault over the lifetime of a certificate. — item shape: {action?: any, trigger?: any}
  --secret-props: any # Properties of the key backing a certificate. — shape: {contentType?: string}
  --x509-props: any # Properties of the X509 component of a certificate. — shape: {ekus?: list, key_usage?: list, sans?: any, subject?: string, validity_months?: int}
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: table<action: record, trigger: record>, secret_props: record<contentType: string>, x509_props: record<ekus: list<string>, key_usage: list<string>, sans: record<dns_names: list, emails: list, upns: list>, subject: string, validity_months: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/policy" $qp)
  let body = {attributes: $attributes, issuer: $issuer, key_props: $key_props, lifetime_actions: $lifetime_actions, secret_props: $secret_props, x509_props: $x509_props} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the versions of a certificate.
#
# GET /certificates/{certificate-name}/versions
# operationId: GetCertificateVersions
export def "certificates-versions GetCertificateVersions" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, id: string, tags: record, x5t: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a certificate.
#
# GET /certificates/{certificate-name}/{certificate-version}
# operationId: GetCertificate
export def "certificates GetCertificate" [
  certificate_name: string
  certificate_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/($certificate_version)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified attributes associated with the given certificate.
#
# PATCH /certificates/{certificate-name}/{certificate-version}
# operationId: UpdateCertificate
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --policy shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
export def "certificates UpdateCertificate" [
  certificate_name: string
  certificate_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --policy: any # Management policy for a certificate. — shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($certificate_name)/($certificate_version)" $qp)
  let body = {attributes: $attributes, policy: $policy, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the deleted certificates in the specified vault currently available for recovery.
#
# GET /deletedcertificates
# operationId: GetDeletedCertificates
export def "deletedcertificates GetDeletedCertificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --includePending: oneof<nothing, bool> # Specifies whether to include certificates which are not completely provisioned.
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, tags: record, x5t: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "includePending" $includePending "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deletedcertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently deletes the specified deleted certificate.
#
# DELETE /deletedcertificates/{certificate-name}
# operationId: PurgeDeletedCertificate
export def "deletedcertificates PurgeDeletedCertificate" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, innererror: any, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedcertificates/($certificate_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about the specified deleted certificate.
#
# GET /deletedcertificates/{certificate-name}
# operationId: GetDeletedCertificate
export def "deletedcertificates GetDeletedCertificate" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedcertificates/($certificate_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recovers the deleted certificate back to its current version under /certificates.
#
# POST /deletedcertificates/{certificate-name}/recover
# operationId: RecoverDeletedCertificate
export def "deletedcertificates-recover RecoverDeletedCertificate" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedcertificates/($certificate_name)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the deleted keys in the specified vault.
#
# GET /deletedkeys
# operationId: GetDeletedKeys
export def "deletedkeys GetDeletedKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, kid: string, managed: bool, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deletedkeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently deletes the specified key.
#
# DELETE /deletedkeys/{key-name}
# operationId: PurgeDeletedKey
export def "deletedkeys PurgeDeletedKey" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, innererror: any, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedkeys/($key_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the public part of a deleted key.
#
# GET /deletedkeys/{key-name}
# operationId: GetDeletedKey
export def "deletedkeys GetDeletedKey" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedkeys/($key_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recovers the deleted key to its latest version.
#
# POST /deletedkeys/{key-name}/recover
# operationId: RecoverDeletedKey
export def "deletedkeys-recover RecoverDeletedKey" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedkeys/($key_name)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists deleted secrets for the specified vault.
#
# GET /deletedsecrets
# operationId: GetDeletedSecrets
export def "deletedsecrets GetDeletedSecrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, contentType: string, id: string, managed: bool, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deletedsecrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently deletes the specified secret.
#
# DELETE /deletedsecrets/{secret-name}
# operationId: PurgeDeletedSecret
export def "deletedsecrets PurgeDeletedSecret" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, innererror: any, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedsecrets/($secret_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified deleted secret.
#
# GET /deletedsecrets/{secret-name}
# operationId: GetDeletedSecret
export def "deletedsecrets GetDeletedSecret" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedsecrets/($secret_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recovers the deleted secret to the latest version.
#
# POST /deletedsecrets/{secret-name}/recover
# operationId: RecoverDeletedSecret
export def "deletedsecrets-recover RecoverDeletedSecret" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedsecrets/($secret_name)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists deleted storage accounts for the specified vault.
#
# GET /deletedstorage
# operationId: GetDeletedStorageAccounts
export def "deletedstorage GetDeletedStorageAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, resourceId: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deletedstorage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently deletes the specified storage account.
#
# DELETE /deletedstorage/{storage-account-name}
# operationId: PurgeDeletedStorageAccount
export def "deletedstorage PurgeDeletedStorageAccount" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, innererror: any, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedstorage/($storage_account_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified deleted storage account.
#
# GET /deletedstorage/{storage-account-name}
# operationId: GetDeletedStorageAccount
export def "deletedstorage GetDeletedStorageAccount" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedstorage/($storage_account_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recovers the deleted storage account.
#
# POST /deletedstorage/{storage-account-name}/recover
# operationId: RecoverDeletedStorageAccount
export def "deletedstorage-recover RecoverDeletedStorageAccount" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedstorage/($storage_account_name)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists deleted SAS definitions for the specified vault and storage account.
#
# GET /deletedstorage/{storage-account-name}/sas
# operationId: GetDeletedSasDefinitions
export def "deletedstorage-sas GetDeletedSasDefinitions" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, sid: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedstorage/($storage_account_name)/sas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified deleted sas definition.
#
# GET /deletedstorage/{storage-account-name}/sas/{sas-definition-name}
# operationId: GetDeletedSasDefinition
export def "deletedstorage-sas GetDeletedSasDefinition" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedstorage/($storage_account_name)/sas/($sas_definition_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recovers the deleted SAS definition.
#
# POST /deletedstorage/{storage-account-name}/sas/{sas-definition-name}/recover
# operationId: RecoverDeletedSasDefinition
export def "deletedstorage-sas-recover RecoverDeletedSasDefinition" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deletedstorage/($storage_account_name)/sas/($sas_definition_name)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List keys in the specified vault.
#
# GET /keys
# operationId: GetKeys
export def "keys GetKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, kid: string, managed: bool, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores a backed up key to a vault.
#
# POST /keys/restore
# operationId: RestoreKey
export def "keys-restore RestoreKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  value: string # The backup blob associated with a key bundle. (format: base64url)
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/keys/restore" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a key of any type from storage in Azure Key Vault.
#
# DELETE /keys/{key-name}
# operationId: DeleteKey
export def "keys DeleteKey" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Imports an externally created key, stores it, and returns key parameters and attributes to the client.
#
# PUT /keys/{key-name}
# operationId: ImportKey
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --key shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", d?: string, dp?: string, dq?: string, e?: string, k?: string, key_hsm?: string, key_ops?: list, kid?: string, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", n?: string, p?: string, q?: string, qi?: string, x?: string, y?: string}
export def "keys ImportKey" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --Hsm: oneof<nothing, bool> # Whether to import as a hardware key (HSM) or software key.
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  key: any # As of http://tools.ietf.org/html/draft-ietf-jose-json-web-key-18 — shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", d?: string, dp?: string, dq?: string, e?: string, k?: string, key_hsm?: string, key_ops?: list, kid?: string, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", n?: string, p?: string, q?: string, qi?: string, x?: string, y?: string}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)" $qp)
  let body = {Hsm: $Hsm, attributes: $attributes, key: $key, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Requests that a backup of the specified key be downloaded to the client.
#
# POST /keys/{key-name}/backup
# operationId: BackupKey
export def "keys-backup BackupKey" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/backup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new key, stores it, then returns key parameters and attributes to the client.
#
# POST /keys/{key-name}/create
# operationId: CreateKey
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "keys-create CreateKey" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --crv: string@crv-completer # Elliptic curve name. For valid values, see JsonWebKeyCurveName.
  --key-ops: list
  --key-size: int # The key size in bits. For example: 2048, 3072, or 4096 for RSA. (format: int32)
  kty: string@kty-completer # The type of key to create. For valid values, see JsonWebKeyType.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/create" $qp)
  let body = {attributes: $attributes, crv: $crv, key_ops: $key_ops, key_size: $key_size, kty: $kty, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of individual key versions with the same key name.
#
# GET /keys/{key-name}/versions
# operationId: GetKeyVersions
export def "keys-versions GetKeyVersions" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, kid: string, managed: bool, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the public part of a stored key.
#
# GET /keys/{key-name}/{key-version}
# operationId: GetKey
export def "keys GetKey" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/($key_version)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The update key operation changes specified attributes of a stored key and can be applied to any key type and key version stored in Azure Key Vault.
#
# PATCH /keys/{key-name}/{key-version}
# operationId: UpdateKey
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "keys UpdateKey" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --key-ops: list # Json web key operations. For more information on possible key operations, see JsonWebKeyOperation.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/($key_version)" $qp)
  let body = {attributes: $attributes, key_ops: $key_ops, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Decrypts a single block of encrypted data.
#
# POST /keys/{key-name}/{key-version}/decrypt
# operationId: decrypt
export def "keys-decrypt decrypt" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/($key_version)/decrypt" $qp)
  let body = {alg: $alg, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Encrypts an arbitrary sequence of bytes using an encryption key that is stored in a key vault.
#
# POST /keys/{key-name}/{key-version}/encrypt
# operationId: encrypt
export def "keys-encrypt encrypt" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/($key_version)/encrypt" $qp)
  let body = {alg: $alg, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a signature from a digest using the specified key.
#
# POST /keys/{key-name}/{key-version}/sign
# operationId: sign
export def "keys-sign sign" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer-1 # The signing/verification algorithm identifier. For more information on possible algorithm types, see JsonWebKeySignatureAlgorithm.
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/($key_version)/sign" $qp)
  let body = {alg: $alg, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unwraps a symmetric key using the specified key that was initially used for wrapping that key.
#
# POST /keys/{key-name}/{key-version}/unwrapkey
# operationId: unwrapKey
export def "keys-unwrapkey unwrapKey" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/($key_version)/unwrapkey" $qp)
  let body = {alg: $alg, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verifies a signature using a specified key.
#
# POST /keys/{key-name}/{key-version}/verify
# operationId: verify
export def "keys-verify verify" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer-1 # The signing/verification algorithm. For more information on possible algorithm types, see JsonWebKeySignatureAlgorithm.
  digest: string # The digest used for signing. (format: base64url)
  value: string # The signature to be verified. (format: base64url)
]: any -> record<value: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/($key_version)/verify" $qp)
  let body = {alg: $alg, digest: $digest, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Wraps a symmetric key using a specified key.
#
# POST /keys/{key-name}/{key-version}/wrapkey
# operationId: wrapKey
export def "keys-wrapkey wrapKey" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key_name)/($key_version)/wrapkey" $qp)
  let body = {alg: $alg, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List secrets in a specified key vault.
#
# GET /secrets
# operationId: GetSecrets
export def "secrets GetSecrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified, the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, contentType: string, id: string, managed: bool, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores a backed up secret to a vault.
#
# POST /secrets/restore
# operationId: RestoreSecret
export def "secrets-restore RestoreSecret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  value: string # The backup blob associated with a secret bundle. (format: base64url)
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets/restore" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a secret from a specified key vault.
#
# DELETE /secrets/{secret-name}
# operationId: DeleteSecret
export def "secrets DeleteSecret" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/secrets/($secret_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets a secret in a specified key vault.
#
# PUT /secrets/{secret-name}
# operationId: SetSecret
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "secrets SetSecret" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The secret management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --contentType: string # Type of the secret value such as a password.
  --tags: record # Application specific metadata in the form of key-value pairs.
  value: string # The value of the secret.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/secrets/($secret_name)" $qp)
  let body = {attributes: $attributes, contentType: $contentType, tags: $tags, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Backs up the specified secret.
#
# POST /secrets/{secret-name}/backup
# operationId: BackupSecret
export def "secrets-backup BackupSecret" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/secrets/($secret_name)/backup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all versions of the specified secret.
#
# GET /secrets/{secret-name}/versions
# operationId: GetSecretVersions
export def "secrets-versions GetSecretVersions" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified, the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, contentType: string, id: string, managed: bool, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/secrets/($secret_name)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specified secret from a given key vault.
#
# GET /secrets/{secret-name}/{secret-version}
# operationId: GetSecret
export def "secrets GetSecret" [
  secret_name: string
  secret_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/secrets/($secret_name)/($secret_version)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the attributes associated with a specified secret in a given key vault.
#
# PATCH /secrets/{secret-name}/{secret-version}
# operationId: UpdateSecret
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "secrets UpdateSecret" [
  secret_name: string
  secret_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The secret management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --contentType: string # Type of the secret value such as a password.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/secrets/($secret_name)/($secret_version)" $qp)
  let body = {attributes: $attributes, contentType: $contentType, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List storage accounts managed by the specified key vault. This operation requires the storage/list permission.
#
# GET /storage
# operationId: GetStorageAccounts
export def "storage GetStorageAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, id: string, resourceId: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores a backed up storage account to a vault.
#
# POST /storage/restore
# operationId: RestoreStorageAccount
export def "storage-restore RestoreStorageAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  value: string # The backup blob associated with a storage account. (format: base64url)
]: any -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storage/restore" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a storage account. This operation requires the storage/delete permission.
#
# DELETE /storage/{storage-account-name}
# operationId: DeleteStorageAccount
export def "storage DeleteStorageAccount" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a specified storage account. This operation requires the storage/get permission.
#
# GET /storage/{storage-account-name}
# operationId: GetStorageAccount
export def "storage GetStorageAccount" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified attributes associated with the given storage account. This operation requires the storage/set/update permission.
#
# PATCH /storage/{storage-account-name}
# operationId: UpdateStorageAccount
# --attributes shape: {enabled?: bool}
export def "storage UpdateStorageAccount" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --activeKeyName: string # The current active storage account key name.
  --attributes: any # The storage account management attributes. — shape: {enabled?: bool}
  --autoRegenerateKey: oneof<nothing, bool> # whether keyvault should manage the storage account for the user.
  --regenerationPeriod: string # The key regeneration time duration specified in ISO-8601 format.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)" $qp)
  let body = {activeKeyName: $activeKeyName, attributes: $attributes, autoRegenerateKey: $autoRegenerateKey, regenerationPeriod: $regenerationPeriod, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a new storage account. This operation requires the storage/set permission.
#
# PUT /storage/{storage-account-name}
# operationId: SetStorageAccount
# --attributes shape: {enabled?: bool}
export def "storage SetStorageAccount" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  activeKeyName: string # Current active storage account key name.
  --attributes: any # The storage account management attributes. — shape: {enabled?: bool}
  --autoRegenerateKey: oneof<nothing, bool> # whether keyvault should manage the storage account for the user.
  --regenerationPeriod: string # The key regeneration time duration specified in ISO-8601 format.
  resourceId: string # Storage account resource id.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)" $qp)
  let body = {activeKeyName: $activeKeyName, attributes: $attributes, autoRegenerateKey: $autoRegenerateKey, regenerationPeriod: $regenerationPeriod, resourceId: $resourceId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Backs up the specified storage account.
#
# POST /storage/{storage-account-name}/backup
# operationId: BackupStorageAccount
export def "storage-backup BackupStorageAccount" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)/backup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerates the specified key value for the given storage account. This operation requires the storage/regeneratekey permission.
#
# POST /storage/{storage-account-name}/regeneratekey
# operationId: RegenerateStorageAccountKey
export def "storage-regeneratekey RegenerateStorageAccountKey" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  keyName: string # The storage account key name.
]: any -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)/regeneratekey" $qp)
  let body = {keyName: $keyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List storage SAS definitions for the given storage account. This operation requires the storage/listsas permission.
#
# GET /storage/{storage-account-name}/sas
# operationId: GetSasDefinitions
export def "storage-sas GetSasDefinitions" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, id: string, sid: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)/sas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a SAS definition from a specified storage account. This operation requires the storage/deletesas permission.
#
# DELETE /storage/{storage-account-name}/sas/{sas-definition-name}
# operationId: DeleteSasDefinition
export def "storage-sas DeleteSasDefinition" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)/sas/($sas_definition_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a SAS definition for the specified storage account. This operation requires the storage/getsas permission.
#
# GET /storage/{storage-account-name}/sas/{sas-definition-name}
# operationId: GetSasDefinition
export def "storage-sas GetSasDefinition" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)/sas/($sas_definition_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified attributes associated with the given SAS definition. This operation requires the storage/setsas permission.
#
# PATCH /storage/{storage-account-name}/sas/{sas-definition-name}
# operationId: UpdateSasDefinition
# --attributes shape: {enabled?: bool}
export def "storage-sas UpdateSasDefinition" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The SAS definition management attributes. — shape: {enabled?: bool}
  --sasType: string@sasType-completer # The type of SAS token the SAS definition will create.
  --tags: record # Application specific metadata in the form of key-value pairs.
  --templateUri: string # The SAS definition token template signed with an arbitrary key.  Tokens created according to the SAS definition will have the same properties as the template.
  --validityPeriod: string # The validity period of SAS tokens created according to the SAS definition.
]: any -> record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)/sas/($sas_definition_name)" $qp)
  let body = {attributes: $attributes, sasType: $sasType, tags: $tags, templateUri: $templateUri, validityPeriod: $validityPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a new SAS definition for the specified storage account. This operation requires the storage/setsas permission.
#
# PUT /storage/{storage-account-name}/sas/{sas-definition-name}
# operationId: SetSasDefinition
# --attributes shape: {enabled?: bool}
export def "storage-sas SetSasDefinition" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The SAS definition management attributes. — shape: {enabled?: bool}
  sasType: string@sasType-completer # The type of SAS token the SAS definition will create.
  --tags: record # Application specific metadata in the form of key-value pairs.
  templateUri: string # The SAS definition token template signed with an arbitrary key.  Tokens created according to the SAS definition will have the same properties as the template.
  validityPeriod: string # The validity period of SAS tokens created according to the SAS definition.
]: any -> record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/storage/($storage_account_name)/sas/($sas_definition_name)" $qp)
  let body = {attributes: $attributes, sasType: $sasType, tags: $tags, templateUri: $templateUri, validityPeriod: $validityPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
