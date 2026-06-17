# Auto-generated client for Conjur v5.3.0
# Source: https://api.apis.guru/v2/specs/conjur.local/5.3.0/openapi.json
# Auth: --token flag or $env.CONJUR_TOKEN

const BASE_URL = "http://conjur.local"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONJUR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "mutual" => { {headers: {Authorization: $"Mutual ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://conjur.local" "http://localhost"] }
def auth-scheme-completer [] { ["basic" "bearer" "mutual"] }

# Completers for enum parameters
def accept-encoding-completer [] { ["application/json" "base64"] }
def accept-encoding-completer-1 [] { ["base64"] }
def accept-completer [] { ["application/json" "application/x-pem-file"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authenticators get" } } | get name | first)
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

# Details about which authenticators are on the Conjur Server
#
# GET /authenticators
# operationId: getAuthenticators
export def "authenticators get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> record<configured: list<string>, enabled: list<string>, installed: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authenticators")
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a short-lived access token for applications running in Azure.
#
# POST /authn-azure/{service_id}/{account}/{login}/authenticate
# operationId: getAccessTokenViaAzure
export def "authn-azure-authenticate get-access-token-via" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --jwt: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id, account: $account, login: $login} | format pattern "/authn-azure/{service_id}/{account}/{login}/authenticate"))
  let body = {"jwt": $jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets a short-lived access token for applications running in Google Cloud Platform.
#
# POST /authn-gcp/{account}/authenticate
# operationId: getAccessTokenViaGCP
export def "authn-gcp-authenticate get-access-token-via" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer-1 # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --jwt: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account} | format pattern "/authn-gcp/{account}/authenticate"))
  let body = {"jwt": $jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id, "Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Details whether an authentication service has been configured properly
#
# GET /authn-gcp/{account}/status
# operationId: getGCPAuthenticatorStatus
export def "authn-gcp-status get-gcp-authenticator" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account} | format pattern "/authn-gcp/{account}/status"))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a short-lived access token for applications running in AWS.
#
# POST /authn-iam/{service_id}/{account}/{login}/authenticate
# operationId: getAccessTokenViaAWS
export def "authn-iam-authenticate get-access-token-via-aws" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id, account: $account, login: $login} | format pattern "/authn-iam/{service_id}/{account}/{login}/authenticate"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Gets a short-lived access token for applications using JSON Web Token (JWT) to access the Conjur API.
#
# POST /authn-jwt/{service_id}/{account}/authenticate
# operationId: getAccessTokenViaJWT
export def "authn-jwt-authenticate get-access-token-via" [
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id, account: $account} | format pattern "/authn-jwt/{service_id}/{account}/authenticate"))
  let body = {"jwt": $jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets a short-lived access token for applications using JSON Web Token (JWT) to access the Conjur API. Covers the case of use of optional URL parameter "ID"
#
# POST /authn-jwt/{service_id}/{account}/{id}/authenticate
# operationId: getAccessTokenViaJWTWithId
export def "authn-jwt-authenticate get-access-token-via-jwt-with" [
  service_id: string
  account: string
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id, account: $account, id: $id} | format pattern "/authn-jwt/{service_id}/{account}/{id}/authenticate"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# For applications running in Kubernetes; sends Conjur a certificate signing request (CSR) and requests a client certificate injected into the application's Kubernetes pod.
#
# POST /authn-k8s/{service_id}/inject_client_cert
# operationId: k8sInjectClientCert
export def "authn-k8s-inject-client-cert k8sInjectClientCert" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id-prefix: string # Dot-separated policy tree, prefixed by `host.`, where the application identity is defined (e.g. host/conjur/authn-k8s/my-authenticator-id/apps)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/authn-k8s/{service_id}/inject_client_cert"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Host-Id-Prefix": $host_id_prefix} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Gets a short-lived access token for applications running in Kubernetes.
#
# POST /authn-k8s/{service_id}/{account}/{login}/authenticate
# operationId: getAccessTokenViaKubernetes
export def "authn-k8s-authenticate get-access-token-via-kubernetes" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "mutual"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id, account: $account, login: $login} | format pattern "/authn-k8s/{service_id}/{account}/{login}/authenticate"))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Conjur API key of a user given the LDAP username and password via HTTP Basic Authentication.
#
# GET /authn-ldap/{service_id}/{account}/login
# operationId: getAPIKeyViaLDAP
export def "authn-ldap-login get-pi-key-via" [
  service_id: string
  account: string
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
  let full_url = (build-url $base ({service_id: $service_id, account: $account} | format pattern "/authn-ldap/{service_id}/{account}/login"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a short-lived access token for users and hosts using their LDAP identity to access the Conjur API.
#
# POST /authn-ldap/{service_id}/{account}/{login}/authenticate
# operationId: getAccessTokenViaLDAP
export def "authn-ldap-authenticate get-access-token-via" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id, account: $account, login: $login} | format pattern "/authn-ldap/{service_id}/{account}/{login}/authenticate"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Gets a short-lived access token for applications using OpenID Connect (OIDC) to access the Conjur API.
#
# POST /authn-oidc/{service_id}/{account}/authenticate
# operationId: getAccessTokenViaOIDC
export def "authn-oidc-authenticate get-access-token-via" [
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id, account: $account} | format pattern "/authn-oidc/{service_id}/{account}/authenticate"))
  let body = {"id_token": $id_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Rotates a role's API key.
#
# PUT /authn/{account}/api_key
# operationId: rotateApiKey
export def "authn-api-key rotateApiKey" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # (**Optional**) role specifier in `{kind}:{identifier}` format  ##### Permissions required  `update` privilege on the role whose API key is being rotated.
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account} | format pattern "/authn/{account}/api_key") $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the API key of a user given the username and password via HTTP Basic Authentication.
#
# GET /authn/{account}/login
# operationId: getAPIKey
export def "authn-login get-pi-key" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account} | format pattern "/authn/{account}/login"))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Changes a user’s password.
#
# PUT /authn/{account}/password
# operationId: changePassword
export def "authn-password changePassword" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account} | format pattern "/authn/{account}/password"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Gets a short-lived access token, which is required in the header of most subsequent API requests.
#
# POST /authn/{account}/{login}/authenticate
# operationId: getAccessToken
export def "authn-authenticate get-access-token" [
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account, login: $login} | format pattern "/authn/{account}/{login}/authenticate"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id, "Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Gets a signed certificate from the configured Certificate Authority service.
#
# POST /ca/{account}/{service_id}/sign
# operationId: sign
export def "ca-sign sign" [
  account: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --hdr-accept: string # Setting the Accept header to `application/x-pem-file` allows Conjur to respond with a formatted certificate (e.g. application/x-pem-file)
  csr: string
  ttl: string
]: any -> record<certificate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account, service_id: $service_id} | format pattern "/ca/{account}/{service_id}/sign"))
  let body = {"csr": $csr, "ttl": $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Health info about conjur
#
# GET /health
# operationId: health
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Host using the Host Factory.
#
# POST /host_factories/hosts
# operationId: createHost
export def "host-factories-hosts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --annotations: record # Annotations to apply to the new host (e.g. {description: new db host, puppet: true})
  id: string # Identifier of the host to be created. It will be created within the account of the host factory. (e.g. my-new-host)
]: any -> record<annotations: list<string>, api_key: string, created_at: string, id: string, owner: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/host_factories/hosts")
  let body = {"annotations": $annotations, "id": $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Creates one or more host identity tokens.
#
# POST /host_factory_tokens
# operationId: createToken
export def "host-factory-tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --cidr: list # Number of host tokens to create (e.g. [127.0.0.1/32])
  --count: int # Number of host tokens to create (e.g. 2)
  expiration: string # `ISO 8601 datetime` denoting a requested expiration time. (e.g. 2017-08-04T22:27:20+00:00)
  host_factory: string # Fully qualified host factory ID (e.g. myorg:host_factory:hf-db)
]: any -> table<cidr: list<string>, expiration: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/host_factory_tokens")
  let body = {"cidr": $cidr, "count": $count, "expiration": $expiration, "host_factory": $host_factory} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Revokes a token, immediately disabling it.
#
# DELETE /host_factory_tokens/{token}
# operationId: revokeToken
export def "host-factory-tokens delete" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/host_factory_tokens/{token_arg}"))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Basic information about the Conjur Enterprise server
#
# GET /info
# operationId: info
export def "info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authenticators: record<configured: list<string>, enabled: list<string>, installed: list<string>>, configuration: record, container: string, release: string, role: string, services: record, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modifies an existing Conjur policy.
#
# PATCH /policies/{account}/policy/{identifier}
# operationId: updatePolicy
export def "policies-policy update-by-account-identifier" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account, identifier: $identifier} | format pattern "/policies/{account}/policy/{identifier}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Adds data to the existing Conjur policy.
#
# POST /policies/{account}/policy/{identifier}
# operationId: loadPolicy
export def "policies-policy loadPolicy" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account, identifier: $identifier} | format pattern "/policies/{account}/policy/{identifier}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Loads or replaces a Conjur policy document.
#
# PUT /policies/{account}/policy/{identifier}
# operationId: replacePolicy
export def "policies-policy update-by-account-identifier-1" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --body: record
]: any -> record<created_roles: record, version: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account, identifier: $identifier} | format pattern "/policies/{account}/policy/{identifier}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Shows all public keys for a resource.
#
# GET /public_keys/{account}/{kind}/{identifier}
# operationId: showPublicKeys
export def "public-keys showPublicKeys" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: $account, kind: $kind, identifier: $identifier} | format pattern "/public_keys/{account}/{kind}/{identifier}"))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Health info about a given Conjur Enterprise server
#
# GET /remote_health/{remote}
# operationId: remoteHealth
export def "remote-health remoteHealth" [
  remote: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({remote: $remote} | format pattern "/remote_health/{remote}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists resources within an organization account.
#
# GET /resources
# operationId: showResourcesForAllAccounts
export def "resources showResourcesForAllAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string # Organization account name (e.g. default)
  --kind: string # Type of resource (e.g. variable)
  --search: string # Filter resources based on this value by name (e.g. password)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> table<annotations: list<string>, created_at: string, id: string, owner: string, permissions: list<record>, policy: string, policy_versions: list<record>, restricted_to: list<string>, secrets: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "acting_as" $acting_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources" $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists resources within an organization account.
#
# GET /resources/{account}
# operationId: showResourcesForAccount
export def "resources showResourcesForAccount" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string # Type of resource (e.g. variable)
  --search: string # Filter resources based on this value by name (e.g. db)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kind" $kind "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "acting_as" $acting_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account} | format pattern "/resources/{account}") $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists resources of the same kind within an organization account.
#
# GET /resources/{account}/{kind}
# operationId: showResourcesForKind
export def "resources showResourcesForKind" [
  account: string
  kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter resources based on this value by name (e.g. db)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "acting_as" $acting_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account, kind: $kind} | format pattern "/resources/{account}/{kind}") $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shows a description of a single resource.
#
# GET /resources/{account}/{kind}/{identifier}
# operationId: showResource
export def "resources showResource" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permitted-roles: oneof<nothing, bool> # Lists the roles which have the named privilege on a resource. (e.g. true)
  --privilege: string # Level of privilege to filter on. Can only be used in combination with `permitted_roles` or `check` parameter. (e.g. execute)
  --check: oneof<nothing, bool> # Check whether a role has a privilege on a resource. (e.g. true)
  --role: string # Role to check privilege on. Can only be used in combination with `check` parameter. (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permitted_roles" $permitted_roles "scalar") (serialize-qp "privilege" $privilege "scalar") (serialize-qp "check" $check "scalar") (serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account, kind: $kind, identifier: $identifier} | format pattern "/resources/{account}/{kind}/{identifier}") $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing role membership
#
# DELETE /roles/{account}/{kind}/{identifier}
# operationId: removeMemberFromRole
export def "roles delete-member-from" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --members: string # Returns a list of the Role's members.
  --member: string # The identifier of the Role to be added as a member.
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "members" $members "scalar") (serialize-qp "member" $member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account, kind: $kind, identifier: $identifier} | format pattern "/roles/{account}/{kind}/{identifier}") $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get role information
#
# GET /roles/{account}/{kind}/{identifier}
# operationId: showRole
export def "roles showRole" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: string # Returns an array of Role IDs representing all role memberships, expanded recursively.
  --memberships: string # Returns all direct role memberships (members not expanded recursively).
  --members: string # Returns a list of the Role's members.
  --offset: int # When listing members, start at this item number. (e.g. 20)
  --limit: int # When listing members, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing members, if `true`, return only the count of members. (e.g. true)
  --search: string # When listing members, the results will be narrowed to only those matching the provided string (e.g. user)
  --graph: string # If included in the query returns a graph view of the role (e.g. )
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "graph" $graph "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account, kind: $kind, identifier: $identifier} | format pattern "/roles/{account}/{kind}/{identifier}") $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update or modify an existing role membership
#
# POST /roles/{account}/{kind}/{identifier}
# operationId: addMemberToRole
export def "roles create-member-to" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --members: string # Returns a list of the Role's members.
  --member: string # The identifier of the Role to be added as a member.
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "members" $members "scalar") (serialize-qp "member" $member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account, kind: $kind, identifier: $identifier} | format pattern "/roles/{account}/{kind}/{identifier}") $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch multiple secrets
#
# GET /secrets
# operationId: getSecrets
export def "secrets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --variable-ids: string # Comma-delimited, URL-encoded resource IDs of the variables. (e.g. myorg:variable:secret1,myorg:variable:secret1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer-1 # Set the encoding of the response object
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variable_ids" $variable_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets" $qp)
  let extra_headers = {"X-Request-Id": $x_request_id, "Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches the value of a secret from the specified Secret.
#
# GET /secrets/{account}/{kind}/{identifier}
# operationId: getSecret
export def "secrets get-by-account-kind-identifier" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # (**Optional**) Version you want to retrieve (Conjur keeps the last 20 versions of a secret) (e.g. 1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account, kind: $kind, identifier: $identifier} | format pattern "/secrets/{account}/{kind}/{identifier}") $qp)
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a secret value within the specified variable.
#
# POST /secrets/{account}/{kind}/{identifier}
# operationId: createSecret
export def "secrets create" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expirations: string # Tells the server to reset the variables expiration date
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expirations" $expirations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: $account, kind: $kind, identifier: $identifier} | format pattern "/secrets/{account}/{kind}/{identifier}") $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Provides information about the client making an API request.
#
# GET /whoami
# operationId: whoAmI
export def "whoami get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
]: nothing -> record<account: string, client_ip: string, token_issued_at: string, user_agent: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whoami")
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enables or disables authenticator defined without service_id.
#
# PATCH /{authenticator}/{account}
# operationId: enableAuthenticator
export def "authentication enable" [
  authenticator: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one.  (e.g. test-id)
  --enabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({authenticator: $authenticator, account: $account} | format pattern "/{authenticator}/{account}"))
  let body = {"enabled": $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enables or disables authenticator service instances.
#
# PATCH /{authenticator}/{service_id}/{account}
# operationId: enableAuthenticatorInstance
export def "authentication enable-instance" [
  authenticator: string
  service_id: string
  account: string
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
  let full_url = (build-url $base ({authenticator: $authenticator, service_id: $service_id, account: $account} | format pattern "/{authenticator}/{service_id}/{account}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Details whether an authentication service has been configured properly
#
# GET /{authenticator}/{service_id}/{account}/status
# operationId: getServiceAuthenticatorStatus
export def "status get-service" [
  authenticator: string
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({authenticator: $authenticator, service_id: $service_id, account: $account} | format pattern "/{authenticator}/{service_id}/{account}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
