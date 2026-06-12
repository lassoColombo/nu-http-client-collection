# Auto-generated client for Otoroshi Admin API v1.5.0-dev
# Source: https://api.apis.guru/v2/specs/maif.local/otoroshi/1.5.0-dev/openapi.json
# Auth: --token flag or $env.OTOROSHI_ADMIN_API_TOKEN

const BASE_URL = "http://otoroshi-api.oto.tools"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OTOROSHI_ADMIN_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://otoroshi-api.oto.tools" "http://maif.local"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def typ-completer [] { ["console" "custom" "elastic" "file" "kafka" "mailer" "pulsar"] }
def accept-completer [] { ["application/json" "text/event-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apikeys allApiKeys" } } | get name | first)
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

# Get all api keys
#
# GET /api/apikeys
# operationId: allApiKeys
export def "apikeys allApiKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/apikeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all global auth. module configs
#
# GET /api/auths
# operationId: findAllGlobalAuthModules
export def "auths findAllGlobalAuthModules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/auths")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one global auth. module config
#
# POST /api/auths
# operationId: createGlobalAuthModule
# --users item shape: {email: string, metadata: record, name: string, password: string}
export def "auths createGlobalAuthModule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --adminPassword: string # The admin password (e.g. a string value)
  --adminUsername: string # The admin username (e.g. a string value)
  --desc: string # Description of the config (e.g. a string value)
  --emailField: string # Field name to get email from user profile (e.g. a string value)
  --groupFilter: string # Filter for groups (e.g. a string value)
  --id: string # Unique id of the config (e.g. a string value)
  --name: string # Name of the config (e.g. a string value)
  --nameField: string # Field name to get name from user profile (e.g. a string value)
  --otoroshiDataField: string # Field name to get otoroshi metadata from. You can specify sub fields using | as separator (e.g. a string value)
  --searchBase: string # LDAP search base (e.g. a string value)
  --searchFilter: string # Filter for users (e.g. a string value)
  --serverUrl: string # URL of the ldap server (e.g. a string value)
  --sessionMaxAge: int # Max age of the session (format: int32, e.g. 123123)
  --type: string # Type of settings. value is ldap (e.g. a string value)
  --userBase: string # LDAP user base DN (e.g. a string value)
  --users: list # List of users — item shape: {email: string, metadata: record, name: string, password: string}
  --accessTokenField: string # Field name to get access token (e.g. a string value)
  --authorizeUrl: string # OAuth authorize URL (e.g. a string value)
  --callbackUrl: string # Otoroshi callback URL (e.g. a string value)
  --claims: string # The claims of the token (e.g. a string value)
  --clientId: string # OAuth Client id (e.g. a string value)
  --clientSecret: string # OAuth Client secret (e.g. a string value)
  --jwtVerifier: any # Algo. settings to verify JWT token
  --loginUrl: string # OAuth login URL (e.g. a string value)
  --logoutUrl: string # OAuth logout URL (e.g. a string value)
  --oidConfig: string # URL of the OIDC config. file (e.g. a string value)
  --readProfileFromToken: oneof<nothing, bool> # The user profile will be read from the JWT token in id_token (e.g. true)
  --scope: string # The scope of the token (e.g. a string value)
  --tokenUrl: string # OAuth token URL (e.g. a string value)
  --useCookies: oneof<nothing, bool> # Use for redirection to actual service (e.g. true)
  --useJson: oneof<nothing, bool> # Use JSON or URL Form Encoded as payload with the OAuth provider (e.g. true)
  --userInfoUrl: string # OAuth userinfo to get user profile (e.g. a string value)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/auths")
  let body = {adminPassword: $adminPassword, adminUsername: $adminUsername, desc: $desc, emailField: $emailField, groupFilter: $groupFilter, id: $id, name: $name, nameField: $nameField, otoroshiDataField: $otoroshiDataField, searchBase: $searchBase, searchFilter: $searchFilter, serverUrl: $serverUrl, sessionMaxAge: $sessionMaxAge, type: $type, userBase: $userBase, users: $users, accessTokenField: $accessTokenField, authorizeUrl: $authorizeUrl, callbackUrl: $callbackUrl, claims: $claims, clientId: $clientId, clientSecret: $clientSecret, jwtVerifier: $jwtVerifier, loginUrl: $loginUrl, logoutUrl: $logoutUrl, oidConfig: $oidConfig, readProfileFromToken: $readProfileFromToken, scope: $scope, tokenUrl: $tokenUrl, useCookies: $useCookies, useJson: $useJson, userInfoUrl: $userInfoUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete one global auth. module config
#
# DELETE /api/auths/{id}
# operationId: deleteGlobalAuthModule
export def "auths delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/auths/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one global auth. module configs
#
# GET /api/auths/{id}
# operationId: findGlobalAuthModuleById
export def "auths findGlobalAuthModuleById" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/auths/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update one global auth. module config
#
# PATCH /api/auths/{id}
# operationId: patchGlobalAuthModule
export def "auths patch" [
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
  let full_url = (build-url $base $"/api/auths/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update one global auth. module config
#
# PUT /api/auths/{id}
# operationId: updateGlobalAuthModule
# --users item shape: {email: string, metadata: record, name: string, password: string}
export def "auths updateGlobalAuthModule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --adminPassword: string # The admin password (e.g. a string value)
  --adminUsername: string # The admin username (e.g. a string value)
  --desc: string # Description of the config (e.g. a string value)
  --emailField: string # Field name to get email from user profile (e.g. a string value)
  --groupFilter: string # Filter for groups (e.g. a string value)
  --body-id: string # Unique id of the config (e.g. a string value)
  --name: string # Name of the config (e.g. a string value)
  --nameField: string # Field name to get name from user profile (e.g. a string value)
  --otoroshiDataField: string # Field name to get otoroshi metadata from. You can specify sub fields using | as separator (e.g. a string value)
  --searchBase: string # LDAP search base (e.g. a string value)
  --searchFilter: string # Filter for users (e.g. a string value)
  --serverUrl: string # URL of the ldap server (e.g. a string value)
  --sessionMaxAge: int # Max age of the session (format: int32, e.g. 123123)
  --type: string # Type of settings. value is ldap (e.g. a string value)
  --userBase: string # LDAP user base DN (e.g. a string value)
  --users: list # List of users — item shape: {email: string, metadata: record, name: string, password: string}
  --accessTokenField: string # Field name to get access token (e.g. a string value)
  --authorizeUrl: string # OAuth authorize URL (e.g. a string value)
  --callbackUrl: string # Otoroshi callback URL (e.g. a string value)
  --claims: string # The claims of the token (e.g. a string value)
  --clientId: string # OAuth Client id (e.g. a string value)
  --clientSecret: string # OAuth Client secret (e.g. a string value)
  --jwtVerifier: any # Algo. settings to verify JWT token
  --loginUrl: string # OAuth login URL (e.g. a string value)
  --logoutUrl: string # OAuth logout URL (e.g. a string value)
  --oidConfig: string # URL of the OIDC config. file (e.g. a string value)
  --readProfileFromToken: oneof<nothing, bool> # The user profile will be read from the JWT token in id_token (e.g. true)
  --scope: string # The scope of the token (e.g. a string value)
  --tokenUrl: string # OAuth token URL (e.g. a string value)
  --useCookies: oneof<nothing, bool> # Use for redirection to actual service (e.g. true)
  --useJson: oneof<nothing, bool> # Use JSON or URL Form Encoded as payload with the OAuth provider (e.g. true)
  --userInfoUrl: string # OAuth userinfo to get user profile (e.g. a string value)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/auths/($id)")
  let body = {adminPassword: $adminPassword, adminUsername: $adminUsername, desc: $desc, emailField: $emailField, groupFilter: $groupFilter, id: $body_id, name: $name, nameField: $nameField, otoroshiDataField: $otoroshiDataField, searchBase: $searchBase, searchFilter: $searchFilter, serverUrl: $serverUrl, sessionMaxAge: $sessionMaxAge, type: $type, userBase: $userBase, users: $users, accessTokenField: $accessTokenField, authorizeUrl: $authorizeUrl, callbackUrl: $callbackUrl, claims: $claims, clientId: $clientId, clientSecret: $clientSecret, jwtVerifier: $jwtVerifier, loginUrl: $loginUrl, logoutUrl: $logoutUrl, oidConfig: $oidConfig, readProfileFromToken: $readProfileFromToken, scope: $scope, tokenUrl: $tokenUrl, useCookies: $useCookies, useJson: $useJson, userInfoUrl: $userInfoUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all certificates
#
# GET /api/certificates
# operationId: allCerts
export def "certificates allCerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/certificates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one certificate
#
# POST /api/certificates
# operationId: createCert
export def "certificates createCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  autoRenew: string # Allow Otoroshi to renew the certificate (if self signed) (e.g. a string value)
  ca: string # Certificate is a CA (read only) (e.g. a string value)
  caRef: string # Reference for a CA certificate in otoroshi (e.g. a string value)
  chain: string # Certificate chain of trust in PEM format (e.g. a string value)
  domain: string # Domain of the certificate (read only) (e.g. a string value)
  --body-from: string # Start date of validity (e.g. a string value)
  id: string # Id of the certificate (e.g. a string value)
  privateKey: string # PKCS8 private key in PEM format (e.g. a string value)
  selfSigned: string # Certificate is self signed  read only) (e.g. a string value)
  subject: string # Subject of the certificate (read only) (e.g. a string value)
  --body-to: string # End date of validity (e.g. a string value)
  valid: string # Certificate is valid (read only) (e.g. a string value)
]: any -> record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/certificates")
  let body = {autoRenew: $autoRenew, ca: $ca, caRef: $caRef, chain: $chain, domain: $domain, from: $body_from, id: $id, privateKey: $privateKey, selfSigned: $selfSigned, subject: $subject, to: $body_to, valid: $valid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete one certificate by id
#
# DELETE /api/certificates/{id}
# operationId: deleteCert
export def "certificates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/certificates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one certificate by id
#
# GET /api/certificates/{id}
# operationId: oneCert
export def "certificates oneCert" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/certificates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update one certificate by id
#
# PATCH /api/certificates/{id}
# operationId: patchCert
export def "certificates patch" [
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
]: any -> record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/certificates/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update one certificate by id
#
# PUT /api/certificates/{id}
# operationId: putCert
export def "certificates put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  autoRenew: string # Allow Otoroshi to renew the certificate (if self signed) (e.g. a string value)
  ca: string # Certificate is a CA (read only) (e.g. a string value)
  caRef: string # Reference for a CA certificate in otoroshi (e.g. a string value)
  chain: string # Certificate chain of trust in PEM format (e.g. a string value)
  domain: string # Domain of the certificate (read only) (e.g. a string value)
  --body-from: string # Start date of validity (e.g. a string value)
  --body-id: string # Id of the certificate (e.g. a string value)
  privateKey: string # PKCS8 private key in PEM format (e.g. a string value)
  selfSigned: string # Certificate is self signed  read only) (e.g. a string value)
  subject: string # Subject of the certificate (read only) (e.g. a string value)
  --body-to: string # End date of validity (e.g. a string value)
  valid: string # Certificate is valid (read only) (e.g. a string value)
]: any -> record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/certificates/($id)")
  let body = {autoRenew: $autoRenew, ca: $ca, caRef: $caRef, chain: $chain, domain: $domain, from: $body_from, id: $body_id, privateKey: $privateKey, selfSigned: $selfSigned, subject: $subject, to: $body_to, valid: $valid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all validation authoritiess
#
# GET /api/client-validators
# operationId: findAllClientValidators
export def "client-validators findAllClientValidators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client-validators")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one validation authorities
#
# POST /api/client-validators
# operationId: createClientValidator
export def "client-validators createClientValidator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alwaysValid: oneof<nothing, bool> # Bypass http calls, every certificates are valids (e.g. true)
  badTtl: int # The TTL for invalid access response caching (format: int64, e.g. 123)
  description: string # The description of the settings (e.g. a string value)
  goodTtl: int # The TTL for valid access response caching (format: int64, e.g. 123)
  headers: record # HTTP call headers (e.g. {key: value})
  host: string # The host of the server (e.g. a string value)
  id: string # The id of the settings (e.g. a string value)
  method: string # The HTTP method (e.g. a string value)
  name: string # The name of the settings (e.g. a string value)
  --noCache: oneof<nothing, bool> # Avoid caching responses (e.g. true)
  path: string # The URL path (e.g. a string value)
  timeout: int # The call timeout (format: int64, e.g. 123)
  --body-url: string # The URL of the server (e.g. a string value)
]: any -> record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client-validators")
  let body = {alwaysValid: $alwaysValid, badTtl: $badTtl, description: $description, goodTtl: $goodTtl, headers: $headers, host: $host, id: $id, method: $method, name: $name, noCache: $noCache, path: $path, timeout: $timeout, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete one validation authorities by id
#
# DELETE /api/client-validators/{id}
# operationId: deleteClientValidator
export def "client-validators delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/client-validators/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one validation authorities by id
#
# GET /api/client-validators/{id}
# operationId: findClientValidatorById
export def "client-validators findClientValidatorById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/client-validators/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update one validation authorities by id
#
# PATCH /api/client-validators/{id}
# operationId: patchClientValidator
export def "client-validators patch" [
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
]: any -> record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/client-validators/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update one validation authorities by id
#
# PUT /api/client-validators/{id}
# operationId: updateClientValidator
export def "client-validators updateClientValidator" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alwaysValid: oneof<nothing, bool> # Bypass http calls, every certificates are valids (e.g. true)
  badTtl: int # The TTL for invalid access response caching (format: int64, e.g. 123)
  description: string # The description of the settings (e.g. a string value)
  goodTtl: int # The TTL for valid access response caching (format: int64, e.g. 123)
  headers: record # HTTP call headers (e.g. {key: value})
  host: string # The host of the server (e.g. a string value)
  --body-id: string # The id of the settings (e.g. a string value)
  method: string # The HTTP method (e.g. a string value)
  name: string # The name of the settings (e.g. a string value)
  --noCache: oneof<nothing, bool> # Avoid caching responses (e.g. true)
  path: string # The URL path (e.g. a string value)
  timeout: int # The call timeout (format: int64, e.g. 123)
  --body-url: string # The URL of the server (e.g. a string value)
]: any -> record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/client-validators/($id)")
  let body = {alwaysValid: $alwaysValid, badTtl: $badTtl, description: $description, goodTtl: $goodTtl, headers: $headers, host: $host, id: $body_id, method: $method, name: $name, noCache: $noCache, path: $path, timeout: $timeout, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all data exporter configs
#
# GET /api/data-exporter-configs
# operationId: findAllDataExporters
export def "data-exporter-configs findAllDataExporters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list, include: list>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-exporter-configs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new data exporter config
#
# POST /api/data-exporter-configs
# operationId: createDataExporterConfig
# --filtering shape: {exclude?: list, include?: list}
# --location shape: {teams: list, tenant: string}
export def "data-exporter-configs createDataExporterConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bufferSize: int # buffer size (format: int32, e.g. 123123)
  --config: any # Data Exporter config
  --desc: string # Description (e.g. a string value)
  --enabled: string # Boolean (e.g. a string value)
  --filtering: record # shape: {exclude?: list, include?: list}
  --groupDuration: int # duration (format: int64, e.g. 123)
  --groupSize: int # Group size (format: int32, e.g. 123123)
  --id: string # Id (e.g. a string value)
  --jsonWorkers: int # nb workers (format: int32, e.g. 123123)
  --location: record # shape: {teams: list, tenant: string}
  --metadata: record # Metadata (e.g. {key: value})
  --name: string # Name (e.g. a string value)
  --projection: record # projection (e.g. {key: value})
  --sendWorkers: int # send workers (format: int32, e.g. 123123)
  --typ: string@typ-completer # Type of data exporter
]: any -> record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-exporter-configs")
  let body = {bufferSize: $bufferSize, config: $config, desc: $desc, enabled: $enabled, filtering: $filtering, groupDuration: $groupDuration, groupSize: $groupSize, id: $id, jsonWorkers: $jsonWorkers, location: $location, metadata: $metadata, name: $name, projection: $projection, sendWorkers: $sendWorkers, typ: $typ} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a data exporter config
#
# DELETE /api/data-exporter-configs/_bulk
# operationId: deletebulkDataExporterConfig
export def "data-exporter-configs-bulk deletebulkDataExporterConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<deleted: bool, id: bool, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-exporter-configs/_bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/ndjson" $body
}

# Update a data exporter configs with a diff
#
# PATCH /api/data-exporter-configs/_bulk
# operationId: patchBulkDataExporterConfig
export def "data-exporter-configs-bulk patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<id: bool, status: string, updated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-exporter-configs/_bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/ndjson" $body
}

# Create a new data exporter configs
#
# POST /api/data-exporter-configs/_bulk
# operationId: createBulkDataExporterConfigs
export def "data-exporter-configs-bulk createBulkDataExporterConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<created: bool, id: bool, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-exporter-configs/_bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/ndjson" $body
}

# Update a data exporter configs
#
# PUT /api/data-exporter-configs/_bulk
# operationId: updateBulkDataExporterConfig
export def "data-exporter-configs-bulk updateBulkDataExporterConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<id: bool, status: string, updated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-exporter-configs/_bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/ndjson" $body
}

# Get all data exporter configs
#
# GET /api/data-exporter-configs/_template
# operationId: DataExporterTemplate
export def "data-exporter-configs-template DataExporterTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The data exporter config type
]: nothing -> record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/data-exporter-configs/_template" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a data exporter config
#
# DELETE /api/data-exporter-configs/{dataExporterConfigId}
# operationId: deleteDataExporterConfig
export def "data-exporter-configs delete" [
  dataExporterConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data-exporter-configs/($dataExporterConfigId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a data exporter config
#
# GET /api/data-exporter-configs/{dataExporterConfigId}
# operationId: findDataExporterConfigById
export def "data-exporter-configs findDataExporterConfigById" [
  dataExporterConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data-exporter-configs/($dataExporterConfigId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a data exporter config with a diff
#
# PATCH /api/data-exporter-configs/{dataExporterConfigId}
# operationId: patchDataExporterConfig
export def "data-exporter-configs patch" [
  dataExporterConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data-exporter-configs/($dataExporterConfigId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a data exporter config
#
# PUT /api/data-exporter-configs/{dataExporterConfigId}
# operationId: updateDataExporterConfig
# --filtering shape: {exclude?: list, include?: list}
# --location shape: {teams: list, tenant: string}
export def "data-exporter-configs updateDataExporterConfig" [
  dataExporterConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bufferSize: int # buffer size (format: int32, e.g. 123123)
  --config: any # Data Exporter config
  --desc: string # Description (e.g. a string value)
  --enabled: string # Boolean (e.g. a string value)
  --filtering: record # shape: {exclude?: list, include?: list}
  --groupDuration: int # duration (format: int64, e.g. 123)
  --groupSize: int # Group size (format: int32, e.g. 123123)
  --id: string # Id (e.g. a string value)
  --jsonWorkers: int # nb workers (format: int32, e.g. 123123)
  --location: record # shape: {teams: list, tenant: string}
  --metadata: record # Metadata (e.g. {key: value})
  --name: string # Name (e.g. a string value)
  --projection: record # projection (e.g. {key: value})
  --sendWorkers: int # send workers (format: int32, e.g. 123123)
  --typ: string@typ-completer # Type of data exporter
]: any -> record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data-exporter-configs/($dataExporterConfigId)")
  let body = {bufferSize: $bufferSize, config: $config, desc: $desc, enabled: $enabled, filtering: $filtering, groupDuration: $groupDuration, groupSize: $groupSize, id: $id, jsonWorkers: $jsonWorkers, location: $location, metadata: $metadata, name: $name, projection: $projection, sendWorkers: $sendWorkers, typ: $typ} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the full configuration of Otoroshi
#
# GET /api/globalconfig
# operationId: globalConfig
export def "globalconfig globalConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/globalconfig")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the global configuration with a diff
#
# PATCH /api/globalconfig
# operationId: patchGlobalConfig
export def "globalconfig patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/globalconfig")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the global configuration
#
# PUT /api/globalconfig
# operationId: putGlobalConfig
# --alertsWebhooks item shape: {headers: record, url: string}
# --analyticsWebhooks item shape: {headers: record, url: string}
# --backofficeAuth0Config shape: {callbackUrl: string, clientId: string, clientSecret: string, domain: string}
# --cleverSettings shape: {consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string}
# --elasticReadsConfig shape: {clusterUri: string, headers: record, index: string, password: string, type: string, user: string}
# --elasticWritesConfigs item shape: {clusterUri: string, headers: record, index: string, password: string, type: string, user: string}
# --ipFiltering shape: {blacklist: list, whitelist: list}
# --mailerSettings shape: {apiKey: string, apiKeyPrivate?: string, apiKeyPublic?: string, domain: string, eu?: bool, header?: record, type?: string, url?: string}
# --privateAppsAuth0Config shape: {callbackUrl: string, clientId: string, clientSecret: string, domain: string}
export def "globalconfig put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alertsEmails: list # Email addresses that will receive all Otoroshi alert events
  alertsWebhooks: list # Webhook that will receive all Otoroshi alert events — item shape: {headers: record, url: string}
  analyticsWebhooks: list # Webhook that will receive all internal Otoroshi events — item shape: {headers: record, url: string}
  --apiReadOnly: oneof<nothing, bool> # If enabled, Admin API won't be able to write/update/delete entities (e.g. true)
  --autoLinkToDefaultGroup: oneof<nothing, bool> # If not defined, every new service descriptor will be added to the default group (e.g. true)
  --backofficeAuth0Config: record # Configuration for Auth0 domain — shape: {callbackUrl: string, clientId: string, clientSecret: string, domain: string}
  --cleverSettings: record # Configuration for CleverCloud client — shape: {consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string}
  --elasticReadsConfig: record # The configuration for elastic access — shape: {clusterUri: string, headers: record, index: string, password: string, type: string, user: string}
  --elasticWritesConfigs: list # Configs. for Elastic writes — item shape: {clusterUri: string, headers: record, index: string, password: string, type: string, user: string}
  endlessIpAddresses: list # IP addresses for which any request to Otoroshi will respond with 128 Gb of zeros
  ipFiltering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list, whitelist: list}
  --limitConcurrentRequests: oneof<nothing, bool> # If enabled, Otoroshi will reject new request if too much at the same time (e.g. true)
  --lines: list # Possibles lines for Otoroshi
  --mailerSettings: record # Configuration for mailgun api client — shape: {apiKey: string, apiKeyPrivate?: string, apiKeyPublic?: string, domain: string, eu?: bool, header?: record, type?: string, url?: string}
  maxConcurrentRequests: int # The number of authorized request processed at the same time (format: int64, e.g. 123)
  --maxHttp10ResponseSize: int # The max size in bytes of an HTTP 1.0 response (format: int64, e.g. 123)
  --maxLogsSize: int # Number of events kept locally (format: int32, e.g. 123123)
  --middleFingers: oneof<nothing, bool> # Use middle finger emoji as a response character for endless HTTP responses (e.g. true)
  perIpThrottlingQuota: int # Authorized number of calls per second globally per IP address, measured on 10 seconds (format: int64, e.g. 123)
  --privateAppsAuth0Config: record # Configuration for Auth0 domain — shape: {callbackUrl: string, clientId: string, clientSecret: string, domain: string}
  --streamEntityOnly: oneof<nothing, bool> # HTTP will be streamed only. Doesn't work with old browsers (e.g. true)
  throttlingQuota: int # Authorized number of calls per second globally, measured on 10 seconds (format: int64, e.g. 123)
  --u2fLoginOnly: oneof<nothing, bool> # If enabled, login to backoffice through Auth0 will be disabled (e.g. true)
  --useCircuitBreakers: oneof<nothing, bool> # If enabled, services will be authorized to use circuit breakers (e.g. true)
]: any -> record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/globalconfig")
  let body = {alertsEmails: $alertsEmails, alertsWebhooks: $alertsWebhooks, analyticsWebhooks: $analyticsWebhooks, apiReadOnly: $apiReadOnly, autoLinkToDefaultGroup: $autoLinkToDefaultGroup, backofficeAuth0Config: $backofficeAuth0Config, cleverSettings: $cleverSettings, elasticReadsConfig: $elasticReadsConfig, elasticWritesConfigs: $elasticWritesConfigs, endlessIpAddresses: $endlessIpAddresses, ipFiltering: $ipFiltering, limitConcurrentRequests: $limitConcurrentRequests, lines: $lines, mailerSettings: $mailerSettings, maxConcurrentRequests: $maxConcurrentRequests, maxHttp10ResponseSize: $maxHttp10ResponseSize, maxLogsSize: $maxLogsSize, middleFingers: $middleFingers, perIpThrottlingQuota: $perIpThrottlingQuota, privateAppsAuth0Config: $privateAppsAuth0Config, streamEntityOnly: $streamEntityOnly, throttlingQuota: $throttlingQuota, u2fLoginOnly: $u2fLoginOnly, useCircuitBreakers: $useCircuitBreakers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all service groups
#
# GET /api/groups
# operationId: allServiceGroups
export def "groups allServiceGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new service group
#
# POST /api/groups
# operationId: createGroup
export def "groups createGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The descriptoin of the group (e.g. a string value)
  id: string # The unique id of the group. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  name: string # The name of the group (e.g. a string value)
]: any -> record<description: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/groups")
  let body = {description: $description, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all api keys for the group of a service
#
# GET /api/groups/{groupId}/apikeys
# operationId: apiKeysFromGroup
export def "groups-apikeys apiKeysFromGroup" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($groupId)/apikeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new api key for a group
#
# POST /api/groups/{groupId}/apikeys
# operationId: createApiKeyFromGroup
export def "groups-apikeys createApiKeyFromGroup" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authorizedEntities: list # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  clientId: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  clientName: string # The name of the api key, for humans ;-) (e.g. a string value)
  clientSecret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --dailyQuota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthlyQuota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttlingQuota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($groupId)/apikeys")
  let body = {authorizedEntities: $authorizedEntities, clientId: $clientId, clientName: $clientName, clientSecret: $clientSecret, dailyQuota: $dailyQuota, enabled: $enabled, metadata: $metadata, monthlyQuota: $monthlyQuota, throttlingQuota: $throttlingQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an api key
#
# DELETE /api/groups/{groupId}/apikeys/{clientId}
# operationId: deleteApiKeyFromGroup
export def "groups-apikeys delete" [
  groupId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($groupId)/apikeys/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an api key
#
# GET /api/groups/{groupId}/apikeys/{clientId}
# operationId: apiKeyFromGroup
export def "groups-apikeys apiKeyFromGroup" [
  groupId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($groupId)/apikeys/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an api key with a diff
#
# PATCH /api/groups/{groupId}/apikeys/{clientId}
# operationId: patchApiKeyFromGroup
export def "groups-apikeys patch" [
  groupId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($groupId)/apikeys/($clientId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an api key
#
# PUT /api/groups/{groupId}/apikeys/{clientId}
# operationId: updateApiKeyFromGroup
export def "groups-apikeys updateApiKeyFromGroup" [
  groupId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authorizedEntities: list # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  --body-clientId: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  clientName: string # The name of the api key, for humans ;-) (e.g. a string value)
  clientSecret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --dailyQuota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthlyQuota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttlingQuota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($groupId)/apikeys/($clientId)")
  let body = {authorizedEntities: $authorizedEntities, clientId: $body_clientId, clientName: $clientName, clientSecret: $clientSecret, dailyQuota: $dailyQuota, enabled: $enabled, metadata: $metadata, monthlyQuota: $monthlyQuota, throttlingQuota: $throttlingQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset the quota state of an api key
#
# DELETE /api/groups/{groupId}/apikeys/{clientId}/quotas
# operationId: resetApiKeyFromGroupQuotas
export def "groups-apikeys-quotas resetApiKeyFromGroupQuotas" [
  groupId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($groupId)/apikeys/($clientId)/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the quota state of an api key
#
# GET /api/groups/{groupId}/apikeys/{clientId}/quotas
# operationId: apiKeyFromGroupQuotas
export def "groups-apikeys-quotas apiKeyFromGroupQuotas" [
  groupId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($groupId)/apikeys/($clientId)/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service group
#
# DELETE /api/groups/{serviceGroupId}
# operationId: deleteGroup
export def "groups delete" [
  serviceGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($serviceGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service group
#
# GET /api/groups/{serviceGroupId}
# operationId: serviceGroup
export def "groups serviceGroup" [
  serviceGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($serviceGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service group with a diff
#
# PATCH /api/groups/{serviceGroupId}
# operationId: patchGroup
export def "groups patch" [
  serviceGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<description: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($serviceGroupId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a service group
#
# PUT /api/groups/{serviceGroupId}
# operationId: updateGroup
export def "groups updateGroup" [
  serviceGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The descriptoin of the group (e.g. a string value)
  id: string # The unique id of the group. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  name: string # The name of the group (e.g. a string value)
]: any -> record<description: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($serviceGroupId)")
  let body = {description: $description, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all services descriptor for a group
#
# GET /api/groups/{serviceGroupId}/services
# operationId: serviceGroupServices
export def "groups-services serviceGroupServices" [
  serviceGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/groups/($serviceGroupId)/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import the full state of Otoroshi as a file
#
# POST /api/import
# operationId: fullImportFromFile
# --admins item shape: {createdAt: int, label: string, password: string, registration: record, username: string}
# --apiKeys item shape: {authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota?: int, enabled: bool, metadata?: record, monthlyQuota?: int, throttlingQuota?: int}
# --config shape: {alertsEmails: list, alertsWebhooks: list, analyticsWebhooks: list, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config?: record, cleverSettings?: record, elasticReadsConfig?: record, elasticWritesConfigs?: list, endlessIpAddresses: list, ipFiltering: record, limitConcurrentRequests: bool, lines?: list, mailerSettings?: record, maxConcurrentRequests: int, maxHttp10ResponseSize?: int, maxLogsSize?: int, middleFingers?: bool, perIpThrottlingQuota: int, privateAppsAuth0Config?: record, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool}
# --errorTemplates item shape: {messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string}
# --serviceDescriptors item shape: {Canary?: record, additionalHeaders?: record, api?: record, authConfigRef?: string, buildMode: bool, chaosConfig?: record, clientConfig?: record, clientValidatorRef?: string, cors?: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip?: record, headersVerification?: record, healthCheck?: record, id: string, ipFiltering?: record, jwtVerifier?: any, localHost?: string, localScheme?: string, maintenanceMode: bool, matchingHeaders?: record, matchingRoot?: string, metadata?: record, name: string, overrideHost?: bool, privateApp: bool, privatePatterns?: list, publicPatterns?: list, redirectToLocal?: bool, redirection?: record, root: string, secComExcludedPatterns?: list, secComSettings?: any, sendOtoroshiHeadersBack?: bool, statsdConfig?: record, subdomain: string, targets: list, transformerRef?: string, userFacing?: bool, xForwardedHeaders?: bool}
# --serviceGroups item shape: {description?: string, id: string, name: string}
# --simpleAdmins item shape: {createdAt: int, label: string, password: string, username: string}
# --stats shape: {calls: int, dataIn: int, dataOut: int}
export def "import fullImportFromFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  admins: list # Current U2F admin at the time of export — item shape: {createdAt: int, label: string, password: string, registration: record, username: string}
  apiKeys: list # Current apik keys at the time of export — item shape: {authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota?: int, enabled: bool, metadata?: record, monthlyQuota?: int, throttlingQuota?: int}
  --appConfig: record # Current env variables at the time of export (e.g. {key: value})
  config: record # The global config object of Otoroshi, used to customize settings of the current Otoroshi instance — shape: {alertsEmails: list, alertsWebhooks: list, analyticsWebhooks: list, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config?: record, cleverSettings?: record, elasticReadsConfig?: record, elasticWritesConfigs?: list, endlessIpAddresses: list, ipFiltering: record, limitConcurrentRequests: bool, lines?: list, mailerSettings?: record, maxConcurrentRequests: int, maxHttp10ResponseSize?: int, maxLogsSize?: int, middleFingers?: bool, perIpThrottlingQuota: int, privateAppsAuth0Config?: record, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool}
  date: string # format: date-time, e.g. 2017-07-21T17:32:28Z
  dateRaw: int # format: int64, e.g. 123
  errorTemplates: list # Current error templates at the time of export — item shape: {messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string}
  label: string # e.g. a string value
  serviceDescriptors: list # Current service descriptors at the time of export — item shape: {Canary?: record, additionalHeaders?: record, api?: record, authConfigRef?: string, buildMode: bool, chaosConfig?: record, clientConfig?: record, clientValidatorRef?: string, cors?: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip?: record, headersVerification?: record, healthCheck?: record, id: string, ipFiltering?: record, jwtVerifier?: any, localHost?: string, localScheme?: string, maintenanceMode: bool, matchingHeaders?: record, matchingRoot?: string, metadata?: record, name: string, overrideHost?: bool, privateApp: bool, privatePatterns?: list, publicPatterns?: list, redirectToLocal?: bool, redirection?: record, root: string, secComExcludedPatterns?: list, secComSettings?: any, sendOtoroshiHeadersBack?: bool, statsdConfig?: record, subdomain: string, targets: list, transformerRef?: string, userFacing?: bool, xForwardedHeaders?: bool}
  serviceGroups: list # Current service groups at the time of export — item shape: {description?: string, id: string, name: string}
  simpleAdmins: list # Current simple admins at the time of export — item shape: {createdAt: int, label: string, password: string, username: string}
  stats: record # Global stats for the current Otoroshi instances — shape: {calls: int, dataIn: int, dataOut: int}
]: any -> record<done: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/import")
  let body = {admins: $admins, apiKeys: $apiKeys, appConfig: $appConfig, config: $config, date: $date, dateRaw: $dateRaw, errorTemplates: $errorTemplates, label: $label, serviceDescriptors: $serviceDescriptors, serviceGroups: $serviceGroups, simpleAdmins: $simpleAdmins, stats: $stats} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get global otoroshi stats
#
# GET /api/live
# operationId: globalLiveStats
export def "live globalLiveStats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<calls: int, concurrentHandledRequests: int, dataIn: int, dataInRate: float, dataOut: int, dataOutRate: float, duration: float, overhead: float, rate: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/live")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get live feed of otoroshi stats
#
# GET /api/live/{id}
# operationId: serviceLiveStats
export def "live serviceLiveStats" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<calls: int, concurrentHandledRequests: int, dataIn: int, dataInRate: float, dataOut: int, dataOutRate: float, duration: float, overhead: float, rate: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/live/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export the full state of Otoroshi
#
# GET /api/otoroshi.json
# operationId: fullExport
export def "otoroshijson fullExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admins: table<createdAt: int, label: string, password: string, registration: record, username: string>, apiKeys: table<authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>, appConfig: record, config: record<alertsEmails: list<string>, alertsWebhooks: list<record>, analyticsWebhooks: list<record>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: list<record>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list, whitelist: list>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>, date: string, dateRaw: int, errorTemplates: table<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>, label: string, serviceDescriptors: table<Canary: record, additionalHeaders: record, api: record, authConfigRef: string, buildMode: bool, chaosConfig: record, clientConfig: record, clientValidatorRef: string, cors: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip: record, headersVerification: record, healthCheck: record, id: string, ipFiltering: record, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list, publicPatterns: list, redirectToLocal: bool, redirection: record, root: string, secComExcludedPatterns: list, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record, subdomain: string, targets: list, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>, serviceGroups: table<description: string, id: string, name: string>, simpleAdmins: table<createdAt: int, label: string, password: string, username: string>, stats: record<calls: int, dataIn: int, dataOut: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/otoroshi.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import the full state of Otoroshi
#
# POST /api/otoroshi.json
# operationId: fullImport
# --admins item shape: {createdAt: int, label: string, password: string, registration: record, username: string}
# --apiKeys item shape: {authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota?: int, enabled: bool, metadata?: record, monthlyQuota?: int, throttlingQuota?: int}
# --config shape: {alertsEmails: list, alertsWebhooks: list, analyticsWebhooks: list, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config?: record, cleverSettings?: record, elasticReadsConfig?: record, elasticWritesConfigs?: list, endlessIpAddresses: list, ipFiltering: record, limitConcurrentRequests: bool, lines?: list, mailerSettings?: record, maxConcurrentRequests: int, maxHttp10ResponseSize?: int, maxLogsSize?: int, middleFingers?: bool, perIpThrottlingQuota: int, privateAppsAuth0Config?: record, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool}
# --errorTemplates item shape: {messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string}
# --serviceDescriptors item shape: {Canary?: record, additionalHeaders?: record, api?: record, authConfigRef?: string, buildMode: bool, chaosConfig?: record, clientConfig?: record, clientValidatorRef?: string, cors?: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip?: record, headersVerification?: record, healthCheck?: record, id: string, ipFiltering?: record, jwtVerifier?: any, localHost?: string, localScheme?: string, maintenanceMode: bool, matchingHeaders?: record, matchingRoot?: string, metadata?: record, name: string, overrideHost?: bool, privateApp: bool, privatePatterns?: list, publicPatterns?: list, redirectToLocal?: bool, redirection?: record, root: string, secComExcludedPatterns?: list, secComSettings?: any, sendOtoroshiHeadersBack?: bool, statsdConfig?: record, subdomain: string, targets: list, transformerRef?: string, userFacing?: bool, xForwardedHeaders?: bool}
# --serviceGroups item shape: {description?: string, id: string, name: string}
# --simpleAdmins item shape: {createdAt: int, label: string, password: string, username: string}
# --stats shape: {calls: int, dataIn: int, dataOut: int}
export def "otoroshijson fullImport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  admins: list # Current U2F admin at the time of export — item shape: {createdAt: int, label: string, password: string, registration: record, username: string}
  apiKeys: list # Current apik keys at the time of export — item shape: {authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota?: int, enabled: bool, metadata?: record, monthlyQuota?: int, throttlingQuota?: int}
  --appConfig: record # Current env variables at the time of export (e.g. {key: value})
  config: record # The global config object of Otoroshi, used to customize settings of the current Otoroshi instance — shape: {alertsEmails: list, alertsWebhooks: list, analyticsWebhooks: list, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config?: record, cleverSettings?: record, elasticReadsConfig?: record, elasticWritesConfigs?: list, endlessIpAddresses: list, ipFiltering: record, limitConcurrentRequests: bool, lines?: list, mailerSettings?: record, maxConcurrentRequests: int, maxHttp10ResponseSize?: int, maxLogsSize?: int, middleFingers?: bool, perIpThrottlingQuota: int, privateAppsAuth0Config?: record, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool}
  date: string # format: date-time, e.g. 2017-07-21T17:32:28Z
  dateRaw: int # format: int64, e.g. 123
  errorTemplates: list # Current error templates at the time of export — item shape: {messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string}
  label: string # e.g. a string value
  serviceDescriptors: list # Current service descriptors at the time of export — item shape: {Canary?: record, additionalHeaders?: record, api?: record, authConfigRef?: string, buildMode: bool, chaosConfig?: record, clientConfig?: record, clientValidatorRef?: string, cors?: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip?: record, headersVerification?: record, healthCheck?: record, id: string, ipFiltering?: record, jwtVerifier?: any, localHost?: string, localScheme?: string, maintenanceMode: bool, matchingHeaders?: record, matchingRoot?: string, metadata?: record, name: string, overrideHost?: bool, privateApp: bool, privatePatterns?: list, publicPatterns?: list, redirectToLocal?: bool, redirection?: record, root: string, secComExcludedPatterns?: list, secComSettings?: any, sendOtoroshiHeadersBack?: bool, statsdConfig?: record, subdomain: string, targets: list, transformerRef?: string, userFacing?: bool, xForwardedHeaders?: bool}
  serviceGroups: list # Current service groups at the time of export — item shape: {description?: string, id: string, name: string}
  simpleAdmins: list # Current simple admins at the time of export — item shape: {createdAt: int, label: string, password: string, username: string}
  stats: record # Global stats for the current Otoroshi instances — shape: {calls: int, dataIn: int, dataOut: int}
]: any -> record<done: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/otoroshi.json")
  let body = {admins: $admins, apiKeys: $apiKeys, appConfig: $appConfig, config: $config, date: $date, dateRaw: $dateRaw, errorTemplates: $errorTemplates, label: $label, serviceDescriptors: $serviceDescriptors, serviceGroups: $serviceGroups, simpleAdmins: $simpleAdmins, stats: $stats} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all scripts
#
# GET /api/scripts
# operationId: findAllScripts
export def "scripts findAllScripts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: record, desc: record, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scripts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new script
#
# POST /api/scripts
# operationId: createScript
export def "scripts createScript" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: record # The code of the script (e.g. {key: value})
  desc: record # The description of the script (e.g. {key: value})
  id: string # The id of the script (e.g. a string value)
  name: string # The name of the script (e.g. a string value)
]: any -> record<code: record, desc: record, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scripts")
  let body = {code: $code, desc: $desc, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Compile a script
#
# POST /api/scripts/_compile
# operationId: compileScript
export def "scripts-compile compileScript" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: record # The code of the script (e.g. {key: value})
  desc: record # The description of the script (e.g. {key: value})
  id: string # The id of the script (e.g. a string value)
  name: string # The name of the script (e.g. a string value)
]: any -> record<done: bool, error: record<column: string, file: record, line: string, message: record, rawMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scripts/_compile")
  let body = {code: $code, desc: $desc, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a script
#
# DELETE /api/scripts/{scriptId}
# operationId: deleteScript
export def "scripts delete" [
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scripts/($scriptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a script
#
# GET /api/scripts/{scriptId}
# operationId: findScriptById
export def "scripts findScriptById" [
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: record, desc: record, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scripts/($scriptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a script with a diff
#
# PATCH /api/scripts/{scriptId}
# operationId: patchScript
export def "scripts patch" [
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<code: record, desc: record, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scripts/($scriptId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a script
#
# PUT /api/scripts/{scriptId}
# operationId: updateScript
export def "scripts updateScript" [
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: record # The code of the script (e.g. {key: value})
  desc: record # The description of the script (e.g. {key: value})
  id: string # The id of the script (e.g. a string value)
  name: string # The name of the script (e.g. a string value)
]: any -> record<code: record, desc: record, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scripts/($scriptId)")
  let body = {code: $code, desc: $desc, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all services
#
# GET /api/services
# operationId: allServices
export def "services allServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Canary: record<enabled: bool, root: string, targets: list, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record, enabled: bool, largeRequestFaultConfig: record, largeResponseFaultConfig: record, latencyInjectionFaultConfig: record>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list, whitelist: list>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: list<record>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new service descriptor
#
# POST /api/services
# operationId: createService
# --Canary shape: {enabled: bool, root: string, targets: list, traffic: int}
# --api shape: {exposeApi: bool, openApiDescriptorUrl?: string}
# --chaosConfig shape: {badResponsesFaultConfig?: record, enabled: bool, largeRequestFaultConfig?: record, largeResponseFaultConfig?: record, latencyInjectionFaultConfig?: record}
# --clientConfig shape: {backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool}
# --cors shape: {allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int}
# --gzip shape: {blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list}
# --healthCheck shape: {enabled: bool, url?: string}
# --ipFiltering shape: {blacklist: list, whitelist: list}
# --redirection shape: {code: int, enabled: bool, to: string}
# --statsdConfig shape: {datadog: bool, host: string, port: int}
# --targets item shape: {host: string, scheme: string}
export def "services createService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Canary: record # The configuration of the canary mode for a service descriptor — shape: {enabled: bool, root: string, targets: list, traffic: int}
  --additionalHeaders: record # Specify headers that will be added to each client request. Useful to add authentication (e.g. {key: value})
  --api: record # The Open API configuration for your service (if one) — shape: {exposeApi: bool, openApiDescriptorUrl?: string}
  --authConfigRef: string # A reference to a global auth module config (e.g. a string value)
  --buildMode: oneof<nothing, bool> # Display a construction page when a user try to use the service (e.g. true)
  --chaosConfig: record # Configuration for the faults that can be injected in requests — shape: {badResponsesFaultConfig?: record, enabled: bool, largeRequestFaultConfig?: record, largeResponseFaultConfig?: record, latencyInjectionFaultConfig?: record}
  --clientConfig: record # The configuration of the circuit breaker for a service descriptor — shape: {backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool}
  --clientValidatorRef: string # A reference to validation authority (e.g. a string value)
  --cors: record # The configuration for cors support — shape: {allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int}
  domain: string # The domain on which the service is available. (e.g. a string value)
  --enabled: oneof<nothing, bool> # Activate or deactivate your service. Once disabled, users will get an error page saying the service does not exist (e.g. true)
  --enforceSecureCommunication: oneof<nothing, bool> # When enabled, Otoroshi will try to exchange headers with downstream service to ensure no one else can use the service from outside (e.g. true)
  env: string # The line on which the service is available. Based on that value, the name of the line will be appended to the subdomain. For line prod, nothing will be appended. For example, if the subdomain is 'foo' and line is 'preprod', then the exposed service will be available at 'foo.preprod.mydomain' (e.g. a string value)
  --forceHttps: oneof<nothing, bool> # Will force redirection to https:// if not present (e.g. true)
  groups: list # Each service descriptor is attached to groups. A group can have one or more services. Each API key is linked to a group and allow access to every service in the group (e.g. [a string value])
  --gzip: record # Configuration for gzip of service responses — shape: {blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list}
  --headersVerification: record # Specify headers that will be verified after routing. (e.g. {key: value})
  --healthCheck: record # The configuration for checking health of a service. Otoroshi will perform GET call on the URL to check if the service is still alive — shape: {enabled: bool, url?: string}
  id: string # A unique random string to identify your service (format: uuid, e.g. 110e8400-e29b-11d4-a716-446655440000)
  --ipFiltering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list, whitelist: list}
  --jwtVerifier: any
  --localHost: string # The host used localy, mainly localhost:xxxx (e.g. a string value)
  --localScheme: string # The scheme used localy, mainly http (e.g. a string value)
  --maintenanceMode: oneof<nothing, bool> # Display a maintainance page when a user try to use the service (e.g. true)
  --matchingHeaders: record # Specify headers that MUST be present on client request to route it. Useful to implement versioning (e.g. {key: value})
  --matchingRoot: string # The root path on which the service is available (e.g. a string value)
  --metadata: record # Just a bunch of random properties (e.g. {key: value})
  name: string # The name of your service. Only for debug and human readability purposes (e.g. a string value)
  --overrideHost: oneof<nothing, bool> # Host header will be overriden with Host of the target (e.g. true)
  --privateApp: oneof<nothing, bool> # When enabled, user will be allowed to use the service (UI) only if they are registered users of the private apps domain (e.g. true)
  --privatePatterns: list # If you define a public pattern that is a little bit too much, you can make some of public URL private again
  --publicPatterns: list # By default, every services are private only and you'll need an API key to access it. However, if you want to expose a public UI, you can define one or more public patterns (regex) to allow access to anybody. For example if you want to allow anybody on any URL, just use '/.*'
  --redirectToLocal: oneof<nothing, bool> # If you work locally with Otoroshi, you may want to use that feature to redirect one particuliar service to a local host. For example, you can relocate https://foo.preprod.bar.com to http://localhost:8080 to make some tests (e.g. true)
  --redirection: record # The configuration for redirection per service — shape: {code: int, enabled: bool, to: string}
  root: string # Otoroshi will append this root to any target choosen. If the specified root is '/api/foo', then a request to https://yyyyyyy/bar will actually hit https://xxxxxxxxx/api/foo/bar (e.g. a string value)
  --secComExcludedPatterns: list # URI patterns excluded from secured communications
  --secComSettings: any
  --sendOtoroshiHeadersBack: oneof<nothing, bool> # When enabled, Otoroshi will send headers to consumer like request id, client latency, overhead, etc ... (e.g. true)
  --statsdConfig: record # The configuration for statsd metrics push — shape: {datadog: bool, host: string, port: int}
  subdomain: string # The subdomain on which the service is available (e.g. a string value)
  targets: list # The list of target that Otoroshi will proxy and expose through the subdomain defined before. Otoroshi will do round-robin load balancing between all those targets with circuit breaker mecanism to avoid cascading failures — item shape: {host: string, scheme: string}
  --transformerRef: string # A reference to a request transformer (e.g. a string value)
  --userFacing: oneof<nothing, bool> # The fact that this service will be seen by users and cannot be impacted by the Snow Monkey (e.g. true)
  --xForwardedHeaders: oneof<nothing, bool> # Send X-Forwarded-* headers (e.g. true)
]: any -> record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/services")
  let body = {Canary: $Canary, additionalHeaders: $additionalHeaders, api: $api, authConfigRef: $authConfigRef, buildMode: $buildMode, chaosConfig: $chaosConfig, clientConfig: $clientConfig, clientValidatorRef: $clientValidatorRef, cors: $cors, domain: $domain, enabled: $enabled, enforceSecureCommunication: $enforceSecureCommunication, env: $env, forceHttps: $forceHttps, groups: $groups, gzip: $gzip, headersVerification: $headersVerification, healthCheck: $healthCheck, id: $id, ipFiltering: $ipFiltering, jwtVerifier: $jwtVerifier, localHost: $localHost, localScheme: $localScheme, maintenanceMode: $maintenanceMode, matchingHeaders: $matchingHeaders, matchingRoot: $matchingRoot, metadata: $metadata, name: $name, overrideHost: $overrideHost, privateApp: $privateApp, privatePatterns: $privatePatterns, publicPatterns: $publicPatterns, redirectToLocal: $redirectToLocal, redirection: $redirection, root: $root, secComExcludedPatterns: $secComExcludedPatterns, secComSettings: $secComSettings, sendOtoroshiHeadersBack: $sendOtoroshiHeadersBack, statsdConfig: $statsdConfig, subdomain: $subdomain, targets: $targets, transformerRef: $transformerRef, userFacing: $userFacing, xForwardedHeaders: $xForwardedHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a service descriptor
#
# DELETE /api/services/{serviceId}
# operationId: deleteService
export def "services delete" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service descriptor
#
# GET /api/services/{serviceId}
# operationId: service
export def "services service" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service descriptor with a diff
#
# PATCH /api/services/{serviceId}
# operationId: patchService
export def "services patch" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a service descriptor
#
# PUT /api/services/{serviceId}
# operationId: updateService
# --Canary shape: {enabled: bool, root: string, targets: list, traffic: int}
# --api shape: {exposeApi: bool, openApiDescriptorUrl?: string}
# --chaosConfig shape: {badResponsesFaultConfig?: record, enabled: bool, largeRequestFaultConfig?: record, largeResponseFaultConfig?: record, latencyInjectionFaultConfig?: record}
# --clientConfig shape: {backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool}
# --cors shape: {allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int}
# --gzip shape: {blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list}
# --healthCheck shape: {enabled: bool, url?: string}
# --ipFiltering shape: {blacklist: list, whitelist: list}
# --redirection shape: {code: int, enabled: bool, to: string}
# --statsdConfig shape: {datadog: bool, host: string, port: int}
# --targets item shape: {host: string, scheme: string}
export def "services updateService" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Canary: record # The configuration of the canary mode for a service descriptor — shape: {enabled: bool, root: string, targets: list, traffic: int}
  --additionalHeaders: record # Specify headers that will be added to each client request. Useful to add authentication (e.g. {key: value})
  --api: record # The Open API configuration for your service (if one) — shape: {exposeApi: bool, openApiDescriptorUrl?: string}
  --authConfigRef: string # A reference to a global auth module config (e.g. a string value)
  --buildMode: oneof<nothing, bool> # Display a construction page when a user try to use the service (e.g. true)
  --chaosConfig: record # Configuration for the faults that can be injected in requests — shape: {badResponsesFaultConfig?: record, enabled: bool, largeRequestFaultConfig?: record, largeResponseFaultConfig?: record, latencyInjectionFaultConfig?: record}
  --clientConfig: record # The configuration of the circuit breaker for a service descriptor — shape: {backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool}
  --clientValidatorRef: string # A reference to validation authority (e.g. a string value)
  --cors: record # The configuration for cors support — shape: {allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int}
  domain: string # The domain on which the service is available. (e.g. a string value)
  --enabled: oneof<nothing, bool> # Activate or deactivate your service. Once disabled, users will get an error page saying the service does not exist (e.g. true)
  --enforceSecureCommunication: oneof<nothing, bool> # When enabled, Otoroshi will try to exchange headers with downstream service to ensure no one else can use the service from outside (e.g. true)
  env: string # The line on which the service is available. Based on that value, the name of the line will be appended to the subdomain. For line prod, nothing will be appended. For example, if the subdomain is 'foo' and line is 'preprod', then the exposed service will be available at 'foo.preprod.mydomain' (e.g. a string value)
  --forceHttps: oneof<nothing, bool> # Will force redirection to https:// if not present (e.g. true)
  groups: list # Each service descriptor is attached to groups. A group can have one or more services. Each API key is linked to a group and allow access to every service in the group (e.g. [a string value])
  --gzip: record # Configuration for gzip of service responses — shape: {blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list}
  --headersVerification: record # Specify headers that will be verified after routing. (e.g. {key: value})
  --healthCheck: record # The configuration for checking health of a service. Otoroshi will perform GET call on the URL to check if the service is still alive — shape: {enabled: bool, url?: string}
  id: string # A unique random string to identify your service (format: uuid, e.g. 110e8400-e29b-11d4-a716-446655440000)
  --ipFiltering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list, whitelist: list}
  --jwtVerifier: any
  --localHost: string # The host used localy, mainly localhost:xxxx (e.g. a string value)
  --localScheme: string # The scheme used localy, mainly http (e.g. a string value)
  --maintenanceMode: oneof<nothing, bool> # Display a maintainance page when a user try to use the service (e.g. true)
  --matchingHeaders: record # Specify headers that MUST be present on client request to route it. Useful to implement versioning (e.g. {key: value})
  --matchingRoot: string # The root path on which the service is available (e.g. a string value)
  --metadata: record # Just a bunch of random properties (e.g. {key: value})
  name: string # The name of your service. Only for debug and human readability purposes (e.g. a string value)
  --overrideHost: oneof<nothing, bool> # Host header will be overriden with Host of the target (e.g. true)
  --privateApp: oneof<nothing, bool> # When enabled, user will be allowed to use the service (UI) only if they are registered users of the private apps domain (e.g. true)
  --privatePatterns: list # If you define a public pattern that is a little bit too much, you can make some of public URL private again
  --publicPatterns: list # By default, every services are private only and you'll need an API key to access it. However, if you want to expose a public UI, you can define one or more public patterns (regex) to allow access to anybody. For example if you want to allow anybody on any URL, just use '/.*'
  --redirectToLocal: oneof<nothing, bool> # If you work locally with Otoroshi, you may want to use that feature to redirect one particuliar service to a local host. For example, you can relocate https://foo.preprod.bar.com to http://localhost:8080 to make some tests (e.g. true)
  --redirection: record # The configuration for redirection per service — shape: {code: int, enabled: bool, to: string}
  root: string # Otoroshi will append this root to any target choosen. If the specified root is '/api/foo', then a request to https://yyyyyyy/bar will actually hit https://xxxxxxxxx/api/foo/bar (e.g. a string value)
  --secComExcludedPatterns: list # URI patterns excluded from secured communications
  --secComSettings: any
  --sendOtoroshiHeadersBack: oneof<nothing, bool> # When enabled, Otoroshi will send headers to consumer like request id, client latency, overhead, etc ... (e.g. true)
  --statsdConfig: record # The configuration for statsd metrics push — shape: {datadog: bool, host: string, port: int}
  subdomain: string # The subdomain on which the service is available (e.g. a string value)
  targets: list # The list of target that Otoroshi will proxy and expose through the subdomain defined before. Otoroshi will do round-robin load balancing between all those targets with circuit breaker mecanism to avoid cascading failures — item shape: {host: string, scheme: string}
  --transformerRef: string # A reference to a request transformer (e.g. a string value)
  --userFacing: oneof<nothing, bool> # The fact that this service will be seen by users and cannot be impacted by the Snow Monkey (e.g. true)
  --xForwardedHeaders: oneof<nothing, bool> # Send X-Forwarded-* headers (e.g. true)
]: any -> record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)")
  let body = {Canary: $Canary, additionalHeaders: $additionalHeaders, api: $api, authConfigRef: $authConfigRef, buildMode: $buildMode, chaosConfig: $chaosConfig, clientConfig: $clientConfig, clientValidatorRef: $clientValidatorRef, cors: $cors, domain: $domain, enabled: $enabled, enforceSecureCommunication: $enforceSecureCommunication, env: $env, forceHttps: $forceHttps, groups: $groups, gzip: $gzip, headersVerification: $headersVerification, healthCheck: $healthCheck, id: $id, ipFiltering: $ipFiltering, jwtVerifier: $jwtVerifier, localHost: $localHost, localScheme: $localScheme, maintenanceMode: $maintenanceMode, matchingHeaders: $matchingHeaders, matchingRoot: $matchingRoot, metadata: $metadata, name: $name, overrideHost: $overrideHost, privateApp: $privateApp, privatePatterns: $privatePatterns, publicPatterns: $publicPatterns, redirectToLocal: $redirectToLocal, redirection: $redirection, root: $root, secComExcludedPatterns: $secComExcludedPatterns, secComSettings: $secComSettings, sendOtoroshiHeadersBack: $sendOtoroshiHeadersBack, statsdConfig: $statsdConfig, subdomain: $subdomain, targets: $targets, transformerRef: $transformerRef, userFacing: $userFacing, xForwardedHeaders: $xForwardedHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all api keys for the group of a service
#
# GET /api/services/{serviceId}/apikeys
# operationId: apiKeys
export def "services-apikeys apiKeys" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new api key for a service
#
# POST /api/services/{serviceId}/apikeys
# operationId: createApiKey
export def "services-apikeys createApiKey" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authorizedEntities: list # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  clientId: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  clientName: string # The name of the api key, for humans ;-) (e.g. a string value)
  clientSecret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --dailyQuota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthlyQuota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttlingQuota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys")
  let body = {authorizedEntities: $authorizedEntities, clientId: $clientId, clientName: $clientName, clientSecret: $clientSecret, dailyQuota: $dailyQuota, enabled: $enabled, metadata: $metadata, monthlyQuota: $monthlyQuota, throttlingQuota: $throttlingQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an api key
#
# DELETE /api/services/{serviceId}/apikeys/{clientId}
# operationId: deleteApiKey
export def "services-apikeys delete" [
  serviceId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an api key
#
# GET /api/services/{serviceId}/apikeys/{clientId}
# operationId: apiKey
export def "services-apikeys apiKey" [
  serviceId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an api key with a diff
#
# PATCH /api/services/{serviceId}/apikeys/{clientId}
# operationId: patchApiKey
export def "services-apikeys patch" [
  serviceId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys/($clientId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an api key
#
# PUT /api/services/{serviceId}/apikeys/{clientId}
# operationId: updateApiKey
export def "services-apikeys updateApiKey" [
  serviceId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authorizedEntities: list # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  --body-clientId: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  clientName: string # The name of the api key, for humans ;-) (e.g. a string value)
  clientSecret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --dailyQuota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthlyQuota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttlingQuota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys/($clientId)")
  let body = {authorizedEntities: $authorizedEntities, clientId: $body_clientId, clientName: $clientName, clientSecret: $clientSecret, dailyQuota: $dailyQuota, enabled: $enabled, metadata: $metadata, monthlyQuota: $monthlyQuota, throttlingQuota: $throttlingQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the group of an api key
#
# GET /api/services/{serviceId}/apikeys/{clientId}/group
# operationId: apiKeyGroup
export def "services-apikeys-group apiKeyGroup" [
  serviceId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys/($clientId)/group")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset the quota state of an api key
#
# DELETE /api/services/{serviceId}/apikeys/{clientId}/quotas
# operationId: resetApiKeyQuotas
export def "services-apikeys-quotas resetApiKeyQuotas" [
  serviceId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys/($clientId)/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the quota state of an api key
#
# GET /api/services/{serviceId}/apikeys/{clientId}/quotas
# operationId: apiKeyQuotas
export def "services-apikeys-quotas apiKeyQuotas" [
  serviceId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/apikeys/($clientId)/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service descriptor target
#
# DELETE /api/services/{serviceId}/targets
# operationId: serviceDeleteTarget
export def "services-targets serviceDeleteTarget" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<host: string, scheme: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/targets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service descriptor targets
#
# GET /api/services/{serviceId}/targets
# operationId: serviceTargets
export def "services-targets serviceTargets" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<host: string, scheme: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/targets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service descriptor targets
#
# PATCH /api/services/{serviceId}/targets
# operationId: updateServiceTargets
export def "services-targets updateServiceTargets" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<host: string, scheme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/targets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a target to a service descriptor
#
# POST /api/services/{serviceId}/targets
# operationId: serviceAddTarget
export def "services-targets serviceAddTarget" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string # The host on which the HTTP call will be forwarded. Can be a domain name, or an IP address. Can also have a port (format: hostname, e.g. www.google.com)
  scheme: string # The protocol used for communication. Can be http or https (e.g. a string value)
]: any -> table<host: string, scheme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/targets")
  let body = {host: $host, scheme: $scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a service descriptor error template
#
# DELETE /api/services/{serviceId}/template
# operationId: deleteServiceTemplate
export def "services-template delete" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/template")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service descriptor error template
#
# GET /api/services/{serviceId}/template
# operationId: serviceTemplate
export def "services-template serviceTemplate" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/template")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a service descriptor error template
#
# POST /api/services/{serviceId}/template
# operationId: createServiceTemplate
export def "services-template createServiceTemplate" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  messages: record # Map for custom messages (e.g. {key: value})
  --body-serviceId: string # The Id of the service for which the error template is enabled (e.g. a string value)
  template40x: string # The html template for 40x errors (e.g. a string value)
  template50x: string # The html template for 50x errors (e.g. a string value)
  templateBuild: string # The html template for build page (e.g. a string value)
  templateMaintenance: string # The html template for maintenance page (e.g. a string value)
]: any -> record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/template")
  let body = {messages: $messages, serviceId: $body_serviceId, template40x: $template40x, template50x: $template50x, templateBuild: $templateBuild, templateMaintenance: $templateMaintenance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an error template to a service descriptor
#
# PUT /api/services/{serviceId}/template
# operationId: updateServiceTemplate
export def "services-template updateServiceTemplate" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  messages: record # Map for custom messages (e.g. {key: value})
  --body-serviceId: string # The Id of the service for which the error template is enabled (e.g. a string value)
  template40x: string # The html template for 40x errors (e.g. a string value)
  template50x: string # The html template for 50x errors (e.g. a string value)
  templateBuild: string # The html template for build page (e.g. a string value)
  templateMaintenance: string # The html template for maintenance page (e.g. a string value)
]: any -> record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/services/($serviceId)/template")
  let body = {messages: $messages, serviceId: $body_serviceId, template40x: $template40x, template50x: $template50x, templateBuild: $templateBuild, templateMaintenance: $templateMaintenance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start the Snow Monkey
#
# POST /api/snowmonkey/_start
# operationId: startSnowMonkey
export def "snowmonkey-start startSnowMonkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<done: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snowmonkey/_start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop the Snow Monkey
#
# POST /api/snowmonkey/_stop
# operationId: stopSnowMonkey
export def "snowmonkey-stop stopSnowMonkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<done: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snowmonkey/_stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current Snow Monkey config
#
# GET /api/snowmonkey/config
# operationId: getSnowMonkeyConfig
export def "snowmonkey-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snowmonkey/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update current Snow Monkey config
#
# PATCH /api/snowmonkey/config
# operationId: patchSnowMonkey
export def "snowmonkey-config patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The descriptoin of the group (e.g. a string value)
  id: string # The unique id of the group. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  name: string # The name of the group (e.g. a string value)
]: any -> record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snowmonkey/config")
  let body = {description: $description, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update current Snow Monkey config
#
# PUT /api/snowmonkey/config
# operationId: updateSnowMonkey
export def "snowmonkey-config updateSnowMonkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The descriptoin of the group (e.g. a string value)
  id: string # The unique id of the group. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  name: string # The name of the group (e.g. a string value)
]: any -> record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snowmonkey/config")
  let body = {description: $description, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset Snow Monkey Outages for the day
#
# DELETE /api/snowmonkey/outages
# operationId: resetSnowMonkey
export def "snowmonkey-outages resetSnowMonkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<done: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snowmonkey/outages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all current Snow Monkey ourages
#
# GET /api/snowmonkey/outages
# operationId: getSnowMonkeyOutages
export def "snowmonkey-outages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<descriptorId: string, descriptorName: string, duration: int, until: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snowmonkey/outages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all global JWT verifiers
#
# GET /api/verifiers
# operationId: findAllGlobalJwtVerifiers
export def "verifiers findAllGlobalJwtVerifiers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/verifiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one global JWT verifiers
#
# POST /api/verifiers
# operationId: createGlobalJwtVerifier
export def "verifiers createGlobalJwtVerifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  algoSettings: any
  desc: string # Verifier description (e.g. a string value)
  --enabled: oneof<nothing, bool> # Is it enabled (e.g. true)
  id: string # Verifier id (e.g. a string value)
  name: string # Verifier name (e.g. a string value)
  --body-source: any
  strategy: any
  --strict: oneof<nothing, bool> # Does it fail if JWT not found (e.g. true)
]: any -> record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/verifiers")
  let body = {algoSettings: $algoSettings, desc: $desc, enabled: $enabled, id: $id, name: $name, source: $body_source, strategy: $strategy, strict: $strict} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete one global JWT verifiers
#
# DELETE /api/verifiers/{verifierId}
# operationId: deleteGlobalJwtVerifier
export def "verifiers delete" [
  verifierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/verifiers/($verifierId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one global JWT verifiers
#
# GET /api/verifiers/{verifierId}
# operationId: findGlobalJwtVerifiersById
export def "verifiers findGlobalJwtVerifiersById" [
  verifierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/verifiers/($verifierId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update one global JWT verifiers
#
# PATCH /api/verifiers/{verifierId}
# operationId: patchGlobalJwtVerifier
export def "verifiers patch" [
  verifierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/verifiers/($verifierId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update one global JWT verifiers
#
# PUT /api/verifiers/{verifierId}
# operationId: updateGlobalJwtVerifier
export def "verifiers updateGlobalJwtVerifier" [
  verifierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  algoSettings: any
  desc: string # Verifier description (e.g. a string value)
  --enabled: oneof<nothing, bool> # Is it enabled (e.g. true)
  id: string # Verifier id (e.g. a string value)
  name: string # Verifier name (e.g. a string value)
  --body-source: any
  strategy: any
  --strict: oneof<nothing, bool> # Does it fail if JWT not found (e.g. true)
]: any -> record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/verifiers/($verifierId)")
  let body = {algoSettings: $algoSettings, desc: $desc, enabled: $enabled, id: $id, name: $name, source: $body_source, strategy: $strategy, strict: $strict} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return current Otoroshi health
#
# GET /health
# operationId: health
export def "health health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<datastore: string, otoroshi: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all environments
#
# GET /lines
# operationId: allLines
export def "lines allLines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lines")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all services for an environment
#
# GET /lines/{line}/services
# operationId: servicesForALine
export def "lines-services servicesForALine" [
  line: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Canary: record<enabled: bool, root: string, targets: list, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record, enabled: bool, largeRequestFaultConfig: record, largeResponseFaultConfig: record, latencyInjectionFaultConfig: record>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list, whitelist: list>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: list<record>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lines/($line)/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a template of an Otoroshi Api Key
#
# GET /new/apikey
# operationId: initiateApiKey
export def "new-apikey initiateApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/new/apikey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a template of an Otoroshi service group
#
# GET /new/group
# operationId: initiateServiceGroup
export def "new-group initiateServiceGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/new/group")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a template of an Otoroshi service descriptor
#
# GET /new/service
# operationId: initiateService
export def "new-service initiateService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/new/service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
