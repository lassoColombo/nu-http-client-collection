# Auto-generated client for KeyVaultClient v7.0-preview
# Source: https://api.apis.guru/v2/specs/azure.com/keyvault/7.0-preview/swagger.json
# Auth: --token flag or $env.KEYVAULTCLIENT_TOKEN

const BASE_URL = "{vaultBaseUrl}"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KEYVAULTCLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["{vaultBaseUrl}"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def crv-completer [] { ["P-256" "P-256K" "P-384" "P-521"] }
def kty-completer [] { ["EC" "EC-HSM" "RSA" "RSA-HSM" "oct"] }
def alg-completer [] { ["RSA-OAEP" "RSA-OAEP-256" "RSA1_5"] }
def alg-completer-1 [] { ["ES256" "ES256K" "ES384" "ES512" "PS256" "PS384" "PS512" "RS256" "RS384" "RS512" "RSNULL"] }
def sas-type-completer [] { ["account" "service"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "certificates get" } } | get name | first)
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
export def "certificates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --include-pending: oneof<nothing, bool> # Specifies whether to include certificates which are not completely provisioned.
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, id: string, tags: record, x5t: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "includePending" $include_pending "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "includePending": $include_pending, "api-version": $api_version} | compact), body: null}
}

# Deletes the certificate contacts for a specified key vault.
#
# DELETE /certificates/contacts
# operationId: DeleteCertificateContacts
export def "certificates-contacts delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<contacts: table<email: string, name: string, phone: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists the certificate contacts for a specified key vault.
#
# GET /certificates/contacts
# operationId: GetCertificateContacts
export def "certificates-contacts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<contacts: table<email: string, name: string, phone: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Sets the certificate contacts for the specified key vault.
#
# PUT /certificates/contacts
# operationId: SetCertificateContacts
# --contacts item shape: {email?: string, name?: string, phone?: string}
export def "certificates-contacts update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --contacts: list # The contact list for the vault certificates. — item shape: {email?: string, name?: string, phone?: string}
]: any -> record<contacts: table<email: string, name: string, phone: string>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/contacts" $qp)
  let req_body = {"contacts": $contacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List certificate issuers for a specified key vault.
#
# GET /certificates/issuers
# operationId: GetCertificateIssuers
export def "certificates-issuers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Deletes the specified certificate issuer.
#
# DELETE /certificates/issuers/{issuer-name}
# operationId: DeleteCertificateIssuer
export def "certificates-issuers delete" [
  issuer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($issuer_name | is-empty) { error make --unspanned { msg: "path parameter 'issuer-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issuer_name: (encode-path-segment $issuer_name)} | format pattern "/certificates/issuers/{issuer_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists the specified certificate issuer.
#
# GET /certificates/issuers/{issuer-name}
# operationId: GetCertificateIssuer
export def "certificates-issuers get" [
  issuer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($issuer_name | is-empty) { error make --unspanned { msg: "path parameter 'issuer-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issuer_name: (encode-path-segment $issuer_name)} | format pattern "/certificates/issuers/{issuer_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates the specified certificate issuer.
#
# PATCH /certificates/issuers/{issuer-name}
# operationId: UpdateCertificateIssuer
# --attributes shape: {enabled?: bool}
# --credentials shape: {account_id?: string, pwd?: string}
# --org_details shape: {admin_details?: list, id?: string}
export def "certificates-issuers update-by-issuer-name" [
  issuer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($issuer_name | is-empty) { error make --unspanned { msg: "path parameter 'issuer-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issuer_name: (encode-path-segment $issuer_name)} | format pattern "/certificates/issuers/{issuer_name}") $qp)
  let req_body = {"attributes": $attributes, "credentials": $credentials, "org_details": $org_details, "provider": $provider} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Sets the specified certificate issuer.
#
# PUT /certificates/issuers/{issuer-name}
# operationId: SetCertificateIssuer
# --attributes shape: {enabled?: bool}
# --credentials shape: {account_id?: string, pwd?: string}
# --org_details shape: {admin_details?: list, id?: string}
export def "certificates-issuers update-by-issuer-name-1" [
  issuer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($issuer_name | is-empty) { error make --unspanned { msg: "path parameter 'issuer-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issuer_name: (encode-path-segment $issuer_name)} | format pattern "/certificates/issuers/{issuer_name}") $qp)
  let req_body = {"attributes": $attributes, "credentials": $credentials, "org_details": $org_details, "provider": $provider} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Restores a backed up certificate to a vault.
#
# POST /certificates/restore
# operationId: RestoreCertificate
export def "certificates-restore create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  value: string # The backup blob associated with a certificate bundle. (format: base64url)
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates/restore" $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a certificate from a specified key vault.
#
# DELETE /certificates/{certificate-name}
# operationId: DeleteCertificate
export def "certificates delete" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Backs up the specified certificate.
#
# POST /certificates/{certificate-name}/backup
# operationId: BackupCertificate
export def "certificates-backup create" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/backup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates a new certificate.
#
# POST /certificates/{certificate-name}/create
# operationId: CreateCertificate
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --policy shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
export def "certificates-create create" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --policy: any # Management policy for a certificate. — shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/create") $qp)
  let req_body = {"attributes": $attributes, "policy": $policy, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Imports a certificate into a specified key vault.
#
# POST /certificates/{certificate-name}/import
# operationId: ImportCertificate
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --policy shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
export def "certificates-import import" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/import") $qp)
  let req_body = {"attributes": $attributes, "policy": $policy, "pwd": $pwd, "tags": $tags, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes the creation operation for a specific certificate.
#
# DELETE /certificates/{certificate-name}/pending
# operationId: DeleteCertificateOperation
export def "certificates-pending delete-operation" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/pending") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the creation operation of a certificate.
#
# GET /certificates/{certificate-name}/pending
# operationId: GetCertificateOperation
export def "certificates-pending get-operation" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/pending") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates a certificate operation.
#
# PATCH /certificates/{certificate-name}/pending
# operationId: UpdateCertificateOperation
export def "certificates-pending update-operation" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --cancellation-requested: oneof<nothing, bool> # Indicates if cancellation was requested on the certificate operation.
]: any -> record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/pending") $qp)
  let req_body = {"cancellation_requested": $cancellation_requested} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Merges a certificate or a certificate chain with a key pair existing on the server.
#
# POST /certificates/{certificate-name}/pending/merge
# operationId: MergeCertificate
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "certificates-pending-merge create" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --tags: record # Application specific metadata in the form of key-value pairs.
  x5c: list<string> # The certificate or the certificate chain to merge.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/pending/merge") $qp)
  let req_body = {"attributes": $attributes, "tags": $tags, "x5c": $x5c} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists the policy for a certificate.
#
# GET /certificates/{certificate-name}/policy
# operationId: GetCertificatePolicy
export def "certificates-policy get" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: table<action: record, trigger: record>, secret_props: record<contentType: string>, x509_props: record<ekus: list<string>, key_usage: list<string>, sans: record<dns_names: list, emails: list, upns: list>, subject: string, validity_months: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/policy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
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
# --x509_props shape: {ekus?: list<string>, key_usage?: list<string>, sans?: any, subject?: string, validity_months?: int}
export def "certificates-policy update" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --issuer: any # Parameters for the issuer of the X509 component of a certificate. — shape: {cert_transparency?: bool, cty?: string, name?: string}
  --key-props: any # Properties of the key pair backing a certificate. — shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", exportable?: bool, key_size?: int, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", reuse_key?: bool}
  --lifetime-actions: list # Actions that will be performed by Key Vault over the lifetime of a certificate. — item shape: {action?: any, trigger?: any}
  --secret-props: any # Properties of the key backing a certificate. — shape: {contentType?: string}
  --x509-props: any # Properties of the X509 component of a certificate. — shape: {ekus?: list<string>, key_usage?: list<string>, sans?: any, subject?: string, validity_months?: int}
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: table<action: record, trigger: record>, secret_props: record<contentType: string>, x509_props: record<ekus: list<string>, key_usage: list<string>, sans: record<dns_names: list, emails: list, upns: list>, subject: string, validity_months: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/policy") $qp)
  let req_body = {"attributes": $attributes, "issuer": $issuer, "key_props": $key_props, "lifetime_actions": $lifetime_actions, "secret_props": $secret_props, "x509_props": $x509_props} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List the versions of a certificate.
#
# GET /certificates/{certificate-name}/versions
# operationId: GetCertificateVersions
export def "certificates-versions get" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, id: string, tags: record, x5t: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/certificates/{certificate_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Gets information about a certificate.
#
# GET /certificates/{certificate-name}/{certificate-version}
# operationId: GetCertificate
export def "certificates get-by-certificate-name-certificate-version" [
  certificate_name: string
  certificate_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  if ($certificate_version | is-empty) { error make --unspanned { msg: "path parameter 'certificate-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name), certificate_version: (encode-path-segment $certificate_version)} | format pattern "/certificates/{certificate_name}/{certificate_version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates the specified attributes associated with the given certificate.
#
# PATCH /certificates/{certificate-name}/{certificate-version}
# operationId: UpdateCertificate
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --policy shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
export def "certificates update" [
  certificate_name: string
  certificate_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --policy: any # Management policy for a certificate. — shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  if ($certificate_version | is-empty) { error make --unspanned { msg: "path parameter 'certificate-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name), certificate_version: (encode-path-segment $certificate_version)} | format pattern "/certificates/{certificate_name}/{certificate_version}") $qp)
  let req_body = {"attributes": $attributes, "policy": $policy, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists the deleted certificates in the specified vault currently available for recovery.
#
# GET /deletedcertificates
# operationId: GetDeletedCertificates
export def "delete-dcertificates get-deleted-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --include-pending: oneof<nothing, bool> # Specifies whether to include certificates which are not completely provisioned.
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, tags: record, x5t: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "includePending" $include_pending "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deletedcertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "includePending": $include_pending, "api-version": $api_version} | compact), body: null}
}

# Permanently deletes the specified deleted certificate.
#
# DELETE /deletedcertificates/{certificate-name}
# operationId: PurgeDeletedCertificate
export def "delete-dcertificates delete-purge-deleted" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, innererror: any, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/deletedcertificates/{certificate_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Retrieves information about the specified deleted certificate.
#
# GET /deletedcertificates/{certificate-name}
# operationId: GetDeletedCertificate
export def "delete-dcertificates get-deleted" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/deletedcertificates/{certificate_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Recovers the deleted certificate back to its current version under /certificates.
#
# POST /deletedcertificates/{certificate-name}/recover
# operationId: RecoverDeletedCertificate
export def "delete-dcertificates-recover create-deleted" [
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_name | is-empty) { error make --unspanned { msg: "path parameter 'certificate-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_name: (encode-path-segment $certificate_name)} | format pattern "/deletedcertificates/{certificate_name}/recover") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists the deleted keys in the specified vault.
#
# GET /deletedkeys
# operationId: GetDeletedKeys
export def "delete-dkeys get-deleted-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Permanently deletes the specified key.
#
# DELETE /deletedkeys/{key-name}
# operationId: PurgeDeletedKey
export def "delete-dkeys delete-purge-deleted" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, innererror: any, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/deletedkeys/{key_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the public part of a deleted key.
#
# GET /deletedkeys/{key-name}
# operationId: GetDeletedKey
export def "delete-dkeys get-deleted" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/deletedkeys/{key_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Recovers the deleted key to its latest version.
#
# POST /deletedkeys/{key-name}/recover
# operationId: RecoverDeletedKey
export def "delete-dkeys-recover create-deleted" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/deletedkeys/{key_name}/recover") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists deleted secrets for the specified vault.
#
# GET /deletedsecrets
# operationId: GetDeletedSecrets
export def "delete-dsecrets get-deleted-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Permanently deletes the specified secret.
#
# DELETE /deletedsecrets/{secret-name}
# operationId: PurgeDeletedSecret
export def "delete-dsecrets delete-purge-deleted" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, innererror: any, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name)} | format pattern "/deletedsecrets/{secret_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the specified deleted secret.
#
# GET /deletedsecrets/{secret-name}
# operationId: GetDeletedSecret
export def "delete-dsecrets get-deleted" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name)} | format pattern "/deletedsecrets/{secret_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Recovers the deleted secret to the latest version.
#
# POST /deletedsecrets/{secret-name}/recover
# operationId: RecoverDeletedSecret
export def "delete-dsecrets-recover create-deleted" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name)} | format pattern "/deletedsecrets/{secret_name}/recover") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists deleted storage accounts for the specified vault.
#
# GET /deletedstorage
# operationId: GetDeletedStorageAccounts
export def "delete-dstorage get-deleted-storage-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Permanently deletes the specified storage account.
#
# DELETE /deletedstorage/{storage-account-name}
# operationId: PurgeDeletedStorageAccount
export def "delete-dstorage delete-purge-deleted" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, innererror: any, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/deletedstorage/{storage_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the specified deleted storage account.
#
# GET /deletedstorage/{storage-account-name}
# operationId: GetDeletedStorageAccount
export def "delete-dstorage get-deleted" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/deletedstorage/{storage_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Recovers the deleted storage account.
#
# POST /deletedstorage/{storage-account-name}/recover
# operationId: RecoverDeletedStorageAccount
export def "delete-dstorage-recover create-deleted" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/deletedstorage/{storage_account_name}/recover") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists deleted SAS definitions for the specified vault and storage account.
#
# GET /deletedstorage/{storage-account-name}/sas
# operationId: GetDeletedSasDefinitions
export def "delete-dstorage-sas get-deleted-definitions" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, sid: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/deletedstorage/{storage_account_name}/sas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Gets the specified deleted sas definition.
#
# GET /deletedstorage/{storage-account-name}/sas/{sas-definition-name}
# operationId: GetDeletedSasDefinition
export def "delete-dstorage-sas get-deleted" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  if ($sas_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'sas-definition-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name), sas_definition_name: (encode-path-segment $sas_definition_name)} | format pattern "/deletedstorage/{storage_account_name}/sas/{sas_definition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Recovers the deleted SAS definition.
#
# POST /deletedstorage/{storage-account-name}/sas/{sas-definition-name}/recover
# operationId: RecoverDeletedSasDefinition
export def "delete-dstorage-sas-recover create-deleted" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  if ($sas_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'sas-definition-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name), sas_definition_name: (encode-path-segment $sas_definition_name)} | format pattern "/deletedstorage/{storage_account_name}/sas/{sas_definition_name}/recover") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# List keys in the specified vault.
#
# GET /keys
# operationId: GetKeys
export def "keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Restores a backed up key to a vault.
#
# POST /keys/restore
# operationId: RestoreKey
export def "keys-restore create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  value: string # The backup blob associated with a key bundle. (format: base64url)
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/keys/restore" $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a key of any type from storage in Azure Key Vault.
#
# DELETE /keys/{key-name}
# operationId: DeleteKey
export def "keys delete" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/keys/{key_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Imports an externally created key, stores it, and returns key parameters and attributes to the client.
#
# PUT /keys/{key-name}
# operationId: ImportKey
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
# --key shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", d?: string, dp?: string, dq?: string, e?: string, k?: string, key_hsm?: string, key_ops?: list<string>, kid?: string, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", n?: string, p?: string, q?: string, qi?: string, x?: string, y?: string}
export def "keys import" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --hsm: oneof<nothing, bool> # Whether to import as a hardware key (HSM) or software key.
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  key: any # As of http://tools.ietf.org/html/draft-ietf-jose-json-web-key-18 — shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", d?: string, dp?: string, dq?: string, e?: string, k?: string, key_hsm?: string, key_ops?: list<string>, kid?: string, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", n?: string, p?: string, q?: string, qi?: string, x?: string, y?: string}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/keys/{key_name}") $qp)
  let req_body = {"Hsm": $hsm, "attributes": $attributes, "key": $key, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Requests that a backup of the specified key be downloaded to the client.
#
# POST /keys/{key-name}/backup
# operationId: BackupKey
export def "keys-backup create" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/keys/{key_name}/backup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates a new key, stores it, then returns key parameters and attributes to the client.
#
# POST /keys/{key-name}/create
# operationId: CreateKey
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "keys-create create" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --crv: string@crv-completer # Elliptic curve name. For valid values, see JsonWebKeyCurveName.
  --key-ops: list<string>
  --key-size: int # The key size in bits. For example: 2048, 3072, or 4096 for RSA. (format: int32)
  kty: string@kty-completer # The type of key to create. For valid values, see JsonWebKeyType.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/keys/{key_name}/create") $qp)
  let req_body = {"attributes": $attributes, "crv": $crv, "key_ops": $key_ops, "key_size": $key_size, "kty": $kty, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Retrieves a list of individual key versions with the same key name.
#
# GET /keys/{key-name}/versions
# operationId: GetKeyVersions
export def "keys-versions get" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, kid: string, managed: bool, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/keys/{key_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Gets the public part of a stored key.
#
# GET /keys/{key-name}/{key-version}
# operationId: GetKey
export def "keys get-by-key-name-key-version" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  if ($key_version | is-empty) { error make --unspanned { msg: "path parameter 'key-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name), key_version: (encode-path-segment $key_version)} | format pattern "/keys/{key_name}/{key_version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# The update key operation changes specified attributes of a stored key and can be applied to any key type and key version stored in Azure Key Vault.
#
# PATCH /keys/{key-name}/{key-version}
# operationId: UpdateKey
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "keys update" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --key-ops: list<string> # Json web key operations. For more information on possible key operations, see JsonWebKeyOperation.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  if ($key_version | is-empty) { error make --unspanned { msg: "path parameter 'key-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name), key_version: (encode-path-segment $key_version)} | format pattern "/keys/{key_name}/{key_version}") $qp)
  let req_body = {"attributes": $attributes, "key_ops": $key_ops, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Decrypts a single block of encrypted data.
#
# POST /keys/{key-name}/{key-version}/decrypt
# operationId: decrypt
export def "keys-decrypt create" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  if ($key_version | is-empty) { error make --unspanned { msg: "path parameter 'key-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name), key_version: (encode-path-segment $key_version)} | format pattern "/keys/{key_name}/{key_version}/decrypt") $qp)
  let req_body = {"alg": $alg, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Encrypts an arbitrary sequence of bytes using an encryption key that is stored in a key vault.
#
# POST /keys/{key-name}/{key-version}/encrypt
# operationId: encrypt
export def "keys-encrypt create" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  if ($key_version | is-empty) { error make --unspanned { msg: "path parameter 'key-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name), key_version: (encode-path-segment $key_version)} | format pattern "/keys/{key_name}/{key_version}/encrypt") $qp)
  let req_body = {"alg": $alg, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a signature from a digest using the specified key.
#
# POST /keys/{key-name}/{key-version}/sign
# operationId: sign
export def "keys-sign create" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer-1 # The signing/verification algorithm identifier. For more information on possible algorithm types, see JsonWebKeySignatureAlgorithm.
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  if ($key_version | is-empty) { error make --unspanned { msg: "path parameter 'key-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name), key_version: (encode-path-segment $key_version)} | format pattern "/keys/{key_name}/{key_version}/sign") $qp)
  let req_body = {"alg": $alg, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Unwraps a symmetric key using the specified key that was initially used for wrapping that key.
#
# POST /keys/{key-name}/{key-version}/unwrapkey
# operationId: unwrapKey
export def "keys-unwrapkey create-unwrap" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  if ($key_version | is-empty) { error make --unspanned { msg: "path parameter 'key-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name), key_version: (encode-path-segment $key_version)} | format pattern "/keys/{key_name}/{key_version}/unwrapkey") $qp)
  let req_body = {"alg": $alg, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer-1 # The signing/verification algorithm. For more information on possible algorithm types, see JsonWebKeySignatureAlgorithm.
  digest: string # The digest used for signing. (format: base64url)
  value: string # The signature to be verified. (format: base64url)
]: any -> record<value: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  if ($key_version | is-empty) { error make --unspanned { msg: "path parameter 'key-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name), key_version: (encode-path-segment $key_version)} | format pattern "/keys/{key_name}/{key_version}/verify") $qp)
  let req_body = {"alg": $alg, "digest": $digest, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Wraps a symmetric key using a specified key.
#
# POST /keys/{key-name}/{key-version}/wrapkey
# operationId: wrapKey
export def "keys-wrapkey create-wrap" [
  key_name: string
  key_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> record<kid: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'key-name' must be non-empty" } }
  if ($key_version | is-empty) { error make --unspanned { msg: "path parameter 'key-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name), key_version: (encode-path-segment $key_version)} | format pattern "/keys/{key_name}/{key_version}/wrapkey") $qp)
  let req_body = {"alg": $alg, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List secrets in a specified key vault.
#
# GET /secrets
# operationId: GetSecrets
export def "secrets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Restores a backed up secret to a vault.
#
# POST /secrets/restore
# operationId: RestoreSecret
export def "secrets-restore create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  value: string # The backup blob associated with a secret bundle. (format: base64url)
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets/restore" $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a secret from a specified key vault.
#
# DELETE /secrets/{secret-name}
# operationId: DeleteSecret
export def "secrets delete" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name)} | format pattern "/secrets/{secret_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Sets a secret in a specified key vault.
#
# PUT /secrets/{secret-name}
# operationId: SetSecret
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "secrets update-by-secret-name" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The secret management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --content-type: string # Type of the secret value such as a password.
  --tags: record # Application specific metadata in the form of key-value pairs.
  value: string # The value of the secret.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name)} | format pattern "/secrets/{secret_name}") $qp)
  let req_body = {"attributes": $attributes, "contentType": $content_type, "tags": $tags, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Backs up the specified secret.
#
# POST /secrets/{secret-name}/backup
# operationId: BackupSecret
export def "secrets-backup create" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name)} | format pattern "/secrets/{secret_name}/backup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# List all versions of the specified secret.
#
# GET /secrets/{secret-name}/versions
# operationId: GetSecretVersions
export def "secrets-versions get" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified, the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, contentType: string, id: string, managed: bool, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name)} | format pattern "/secrets/{secret_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Get a specified secret from a given key vault.
#
# GET /secrets/{secret-name}/{secret-version}
# operationId: GetSecret
export def "secrets get-by-secret-name-secret-version" [
  secret_name: string
  secret_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  if ($secret_version | is-empty) { error make --unspanned { msg: "path parameter 'secret-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name), secret_version: (encode-path-segment $secret_version)} | format pattern "/secrets/{secret_name}/{secret_version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates the attributes associated with a specified secret in a given key vault.
#
# PATCH /secrets/{secret-name}/{secret-version}
# operationId: UpdateSecret
# --attributes shape: {enabled?: bool, exp?: int, nbf?: int}
export def "secrets update-by-secret-name-secret-version" [
  secret_name: string
  secret_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The secret management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --content-type: string # Type of the secret value such as a password.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_name | is-empty) { error make --unspanned { msg: "path parameter 'secret-name' must be non-empty" } }
  if ($secret_version | is-empty) { error make --unspanned { msg: "path parameter 'secret-version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_name: (encode-path-segment $secret_name), secret_version: (encode-path-segment $secret_version)} | format pattern "/secrets/{secret_name}/{secret_version}") $qp)
  let req_body = {"attributes": $attributes, "contentType": $content_type, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List storage accounts managed by the specified key vault. This operation requires the storage/list permission.
#
# GET /storage
# operationId: GetStorageAccounts
export def "storage get-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Restores a backed up storage account to a vault.
#
# POST /storage/restore
# operationId: RestoreStorageAccount
export def "storage-restore create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  value: string # The backup blob associated with a storage account. (format: base64url)
]: any -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storage/restore" $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a storage account. This operation requires the storage/delete permission.
#
# DELETE /storage/{storage-account-name}
# operationId: DeleteStorageAccount
export def "storage delete" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/storage/{storage_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets information about a specified storage account. This operation requires the storage/get permission.
#
# GET /storage/{storage-account-name}
# operationId: GetStorageAccount
export def "storage get" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/storage/{storage_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates the specified attributes associated with the given storage account. This operation requires the storage/set/update permission.
#
# PATCH /storage/{storage-account-name}
# operationId: UpdateStorageAccount
# --attributes shape: {enabled?: bool}
export def "storage update-by-storage-account-name" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --active-key-name: string # The current active storage account key name.
  --attributes: any # The storage account management attributes. — shape: {enabled?: bool}
  --auto-regenerate-key: oneof<nothing, bool> # whether keyvault should manage the storage account for the user.
  --regeneration-period: string # The key regeneration time duration specified in ISO-8601 format.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/storage/{storage_account_name}") $qp)
  let req_body = {"activeKeyName": $active_key_name, "attributes": $attributes, "autoRegenerateKey": $auto_regenerate_key, "regenerationPeriod": $regeneration_period, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates or updates a new storage account. This operation requires the storage/set permission.
#
# PUT /storage/{storage-account-name}
# operationId: SetStorageAccount
# --attributes shape: {enabled?: bool}
export def "storage update-by-storage-account-name-1" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  active_key_name: string # Current active storage account key name.
  --attributes: any # The storage account management attributes. — shape: {enabled?: bool}
  --auto-regenerate-key: oneof<nothing, bool> # whether keyvault should manage the storage account for the user.
  --regeneration-period: string # The key regeneration time duration specified in ISO-8601 format.
  resource_id: string # Storage account resource id.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/storage/{storage_account_name}") $qp)
  let req_body = {"activeKeyName": $active_key_name, "attributes": $attributes, "autoRegenerateKey": $auto_regenerate_key, "regenerationPeriod": $regeneration_period, "resourceId": $resource_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Backs up the specified storage account.
#
# POST /storage/{storage-account-name}/backup
# operationId: BackupStorageAccount
export def "storage-backup create" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/storage/{storage_account_name}/backup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Regenerates the specified key value for the given storage account. This operation requires the storage/regeneratekey permission.
#
# POST /storage/{storage-account-name}/regeneratekey
# operationId: RegenerateStorageAccountKey
export def "storage-regeneratekey create-regenerate-key" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  key_name: string # The storage account key name.
]: any -> record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/storage/{storage_account_name}/regeneratekey") $qp)
  let req_body = {"keyName": $key_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List storage SAS definitions for the given storage account. This operation requires the storage/listsas permission.
#
# GET /storage/{storage-account-name}/sas
# operationId: GetSasDefinitions
export def "storage-sas get-definitions" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<attributes: record, id: string, sid: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name)} | format pattern "/storage/{storage_account_name}/sas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "api-version": $api_version} | compact), body: null}
}

# Deletes a SAS definition from a specified storage account. This operation requires the storage/deletesas permission.
#
# DELETE /storage/{storage-account-name}/sas/{sas-definition-name}
# operationId: DeleteSasDefinition
export def "storage-sas delete" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  if ($sas_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'sas-definition-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name), sas_definition_name: (encode-path-segment $sas_definition_name)} | format pattern "/storage/{storage_account_name}/sas/{sas_definition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets information about a SAS definition for the specified storage account. This operation requires the storage/getsas permission.
#
# GET /storage/{storage-account-name}/sas/{sas-definition-name}
# operationId: GetSasDefinition
export def "storage-sas get" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  if ($sas_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'sas-definition-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name), sas_definition_name: (encode-path-segment $sas_definition_name)} | format pattern "/storage/{storage_account_name}/sas/{sas_definition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates the specified attributes associated with the given SAS definition. This operation requires the storage/setsas permission.
#
# PATCH /storage/{storage-account-name}/sas/{sas-definition-name}
# operationId: UpdateSasDefinition
# --attributes shape: {enabled?: bool}
export def "storage-sas update-by-storage-account-name-sas-definition-name" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The SAS definition management attributes. — shape: {enabled?: bool}
  --sas-type: string@sas-type-completer # The type of SAS token the SAS definition will create.
  --tags: record # Application specific metadata in the form of key-value pairs.
  --template-uri: string # The SAS definition token template signed with an arbitrary key. Tokens created according to the SAS definition will have the same properties as the template.
  --validity-period: string # The validity period of SAS tokens created according to the SAS definition.
]: any -> record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  if ($sas_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'sas-definition-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name), sas_definition_name: (encode-path-segment $sas_definition_name)} | format pattern "/storage/{storage_account_name}/sas/{sas_definition_name}") $qp)
  let req_body = {"attributes": $attributes, "sasType": $sas_type, "tags": $tags, "templateUri": $template_uri, "validityPeriod": $validity_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates or updates a new SAS definition for the specified storage account. This operation requires the storage/setsas permission.
#
# PUT /storage/{storage-account-name}/sas/{sas-definition-name}
# operationId: SetSasDefinition
# --attributes shape: {enabled?: bool}
export def "storage-sas update-by-storage-account-name-sas-definition-name-1" [
  storage_account_name: string
  sas_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --attributes: any # The SAS definition management attributes. — shape: {enabled?: bool}
  sas_type: string@sas-type-completer # The type of SAS token the SAS definition will create.
  --tags: record # Application specific metadata in the form of key-value pairs.
  template_uri: string # The SAS definition token template signed with an arbitrary key. Tokens created according to the SAS definition will have the same properties as the template.
  validity_period: string # The validity period of SAS tokens created according to the SAS definition.
]: any -> record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($storage_account_name | is-empty) { error make --unspanned { msg: "path parameter 'storage-account-name' must be non-empty" } }
  if ($sas_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'sas-definition-name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({storage_account_name: (encode-path-segment $storage_account_name), sas_definition_name: (encode-path-segment $sas_definition_name)} | format pattern "/storage/{storage_account_name}/sas/{sas_definition_name}") $qp)
  let req_body = {"attributes": $attributes, "sasType": $sas_type, "tags": $tags, "templateUri": $template_uri, "validityPeriod": $validity_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}
