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
export def "auths create-global-auth-module" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-password: string # The admin password (e.g. a string value)
  --admin-username: string # The admin username (e.g. a string value)
  --desc: string # Description of the config (e.g. a string value)
  --email-field: string # Field name to get email from user profile (e.g. a string value)
  --group-filter: string # Filter for groups (e.g. a string value)
  --id: string # Unique id of the config (e.g. a string value)
  --name: string # Name of the config (e.g. a string value)
  --name-field: string # Field name to get name from user profile (e.g. a string value)
  --otoroshi-data-field: string # Field name to get otoroshi metadata from. You can specify sub fields using | as separator (e.g. a string value)
  --search-base: string # LDAP search base (e.g. a string value)
  --search-filter: string # Filter for users (e.g. a string value)
  --server-url: string # URL of the ldap server (e.g. a string value)
  --session-max-age: int # Max age of the session (format: int32, e.g. 123123)
  --type: string # Type of settings. value is ldap (e.g. a string value)
  --user-base: string # LDAP user base DN (e.g. a string value)
  --users: list # List of users — item shape: {email: string, metadata: record, name: string, password: string}
  --access-token-field: string # Field name to get access token (e.g. a string value)
  --authorize-url: string # OAuth authorize URL (e.g. a string value)
  --callback-url: string # Otoroshi callback URL (e.g. a string value)
  --claims: string # The claims of the token (e.g. a string value)
  --client-id: string # OAuth Client id (e.g. a string value)
  --client-secret: string # OAuth Client secret (e.g. a string value)
  --jwt-verifier: any # Algo. settings to verify JWT token
  --login-url: string # OAuth login URL (e.g. a string value)
  --logout-url: string # OAuth logout URL (e.g. a string value)
  --oid-config: string # URL of the OIDC config. file (e.g. a string value)
  --read-profile-from-token: oneof<nothing, bool> # The user profile will be read from the JWT token in id_token (e.g. true)
  --scope: string # The scope of the token (e.g. a string value)
  --token-url: string # OAuth token URL (e.g. a string value)
  --use-cookies: oneof<nothing, bool> # Use for redirection to actual service (e.g. true)
  --use-json: oneof<nothing, bool> # Use JSON or URL Form Encoded as payload with the OAuth provider (e.g. true)
  --user-info-url: string # OAuth userinfo to get user profile (e.g. a string value)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/auths")
  let body = {"adminPassword": $admin_password, "adminUsername": $admin_username, "desc": $desc, "emailField": $email_field, "groupFilter": $group_filter, "id": $id, "name": $name, "nameField": $name_field, "otoroshiDataField": $otoroshi_data_field, "searchBase": $search_base, "searchFilter": $search_filter, "serverUrl": $server_url, "sessionMaxAge": $session_max_age, "type": $type, "userBase": $user_base, "users": $users, "accessTokenField": $access_token_field, "authorizeUrl": $authorize_url, "callbackUrl": $callback_url, "claims": $claims, "clientId": $client_id, "clientSecret": $client_secret, "jwtVerifier": $jwt_verifier, "loginUrl": $login_url, "logoutUrl": $logout_url, "oidConfig": $oid_config, "readProfileFromToken": $read_profile_from_token, "scope": $scope, "tokenUrl": $token_url, "useCookies": $use_cookies, "useJson": $use_json, "userInfoUrl": $user_info_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete one global auth. module config
#
# DELETE /api/auths/{id}
# operationId: deleteGlobalAuthModule
export def "auths delete-global-auth-module" [
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/auths/{id}"))
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/auths/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update one global auth. module config
#
# PATCH /api/auths/{id}
# operationId: patchGlobalAuthModule
export def "auths update-global-auth-module-by-id" [
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/auths/{id}"))
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
export def "auths update-global-auth-module-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-password: string # The admin password (e.g. a string value)
  --admin-username: string # The admin username (e.g. a string value)
  --desc: string # Description of the config (e.g. a string value)
  --email-field: string # Field name to get email from user profile (e.g. a string value)
  --group-filter: string # Filter for groups (e.g. a string value)
  --body-id: string # Unique id of the config (e.g. a string value)
  --name: string # Name of the config (e.g. a string value)
  --name-field: string # Field name to get name from user profile (e.g. a string value)
  --otoroshi-data-field: string # Field name to get otoroshi metadata from. You can specify sub fields using | as separator (e.g. a string value)
  --search-base: string # LDAP search base (e.g. a string value)
  --search-filter: string # Filter for users (e.g. a string value)
  --server-url: string # URL of the ldap server (e.g. a string value)
  --session-max-age: int # Max age of the session (format: int32, e.g. 123123)
  --type: string # Type of settings. value is ldap (e.g. a string value)
  --user-base: string # LDAP user base DN (e.g. a string value)
  --users: list # List of users — item shape: {email: string, metadata: record, name: string, password: string}
  --access-token-field: string # Field name to get access token (e.g. a string value)
  --authorize-url: string # OAuth authorize URL (e.g. a string value)
  --callback-url: string # Otoroshi callback URL (e.g. a string value)
  --claims: string # The claims of the token (e.g. a string value)
  --client-id: string # OAuth Client id (e.g. a string value)
  --client-secret: string # OAuth Client secret (e.g. a string value)
  --jwt-verifier: any # Algo. settings to verify JWT token
  --login-url: string # OAuth login URL (e.g. a string value)
  --logout-url: string # OAuth logout URL (e.g. a string value)
  --oid-config: string # URL of the OIDC config. file (e.g. a string value)
  --read-profile-from-token: oneof<nothing, bool> # The user profile will be read from the JWT token in id_token (e.g. true)
  --scope: string # The scope of the token (e.g. a string value)
  --token-url: string # OAuth token URL (e.g. a string value)
  --use-cookies: oneof<nothing, bool> # Use for redirection to actual service (e.g. true)
  --use-json: oneof<nothing, bool> # Use JSON or URL Form Encoded as payload with the OAuth provider (e.g. true)
  --user-info-url: string # OAuth userinfo to get user profile (e.g. a string value)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/auths/{id}"))
  let body = {"adminPassword": $admin_password, "adminUsername": $admin_username, "desc": $desc, "emailField": $email_field, "groupFilter": $group_filter, "id": $body_id, "name": $name, "nameField": $name_field, "otoroshiDataField": $otoroshi_data_field, "searchBase": $search_base, "searchFilter": $search_filter, "serverUrl": $server_url, "sessionMaxAge": $session_max_age, "type": $type, "userBase": $user_base, "users": $users, "accessTokenField": $access_token_field, "authorizeUrl": $authorize_url, "callbackUrl": $callback_url, "claims": $claims, "clientId": $client_id, "clientSecret": $client_secret, "jwtVerifier": $jwt_verifier, "loginUrl": $login_url, "logoutUrl": $logout_url, "oidConfig": $oid_config, "readProfileFromToken": $read_profile_from_token, "scope": $scope, "tokenUrl": $token_url, "useCookies": $use_cookies, "useJson": $use_json, "userInfoUrl": $user_info_url} | compact
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
export def "certificates create-cert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  auto_renew: string # Allow Otoroshi to renew the certificate (if self signed) (e.g. a string value)
  ca: string # Certificate is a CA (read only) (e.g. a string value)
  ca_ref: string # Reference for a CA certificate in otoroshi (e.g. a string value)
  chain: string # Certificate chain of trust in PEM format (e.g. a string value)
  domain: string # Domain of the certificate (read only) (e.g. a string value)
  --body-from: string # Start date of validity (e.g. a string value)
  id: string # Id of the certificate (e.g. a string value)
  private_key: string # PKCS8 private key in PEM format (e.g. a string value)
  self_signed: string # Certificate is self signed  read only) (e.g. a string value)
  subject: string # Subject of the certificate (read only) (e.g. a string value)
  --body-to: string # End date of validity (e.g. a string value)
  valid: string # Certificate is valid (read only) (e.g. a string value)
]: any -> record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/certificates")
  let body = {"autoRenew": $auto_renew, "ca": $ca, "caRef": $ca_ref, "chain": $chain, "domain": $domain, "from": $body_from, "id": $id, "privateKey": $private_key, "selfSigned": $self_signed, "subject": $subject, "to": $body_to, "valid": $valid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete one certificate by id
#
# DELETE /api/certificates/{id}
# operationId: deleteCert
export def "certificates delete-cert" [
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/certificates/{id}"))
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/certificates/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update one certificate by id
#
# PATCH /api/certificates/{id}
# operationId: patchCert
export def "certificates update-cert-by-id" [
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/certificates/{id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update one certificate by id
#
# PUT /api/certificates/{id}
# operationId: putCert
export def "certificates update-cert-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  auto_renew: string # Allow Otoroshi to renew the certificate (if self signed) (e.g. a string value)
  ca: string # Certificate is a CA (read only) (e.g. a string value)
  ca_ref: string # Reference for a CA certificate in otoroshi (e.g. a string value)
  chain: string # Certificate chain of trust in PEM format (e.g. a string value)
  domain: string # Domain of the certificate (read only) (e.g. a string value)
  --body-from: string # Start date of validity (e.g. a string value)
  --body-id: string # Id of the certificate (e.g. a string value)
  private_key: string # PKCS8 private key in PEM format (e.g. a string value)
  self_signed: string # Certificate is self signed  read only) (e.g. a string value)
  subject: string # Subject of the certificate (read only) (e.g. a string value)
  --body-to: string # End date of validity (e.g. a string value)
  valid: string # Certificate is valid (read only) (e.g. a string value)
]: any -> record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/certificates/{id}"))
  let body = {"autoRenew": $auto_renew, "ca": $ca, "caRef": $ca_ref, "chain": $chain, "domain": $domain, "from": $body_from, "id": $body_id, "privateKey": $private_key, "selfSigned": $self_signed, "subject": $subject, "to": $body_to, "valid": $valid} | compact
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
export def "client-validators create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --always-valid: oneof<nothing, bool> # Bypass http calls, every certificates are valids (e.g. true)
  bad_ttl: int # The TTL for invalid access response caching (format: int64, e.g. 123)
  description: string # The description of the settings (e.g. a string value)
  good_ttl: int # The TTL for valid access response caching (format: int64, e.g. 123)
  headers: record # HTTP call headers (e.g. {key: value})
  host: string # The host of the server (e.g. a string value)
  id: string # The id of the settings (e.g. a string value)
  method: string # The HTTP method (e.g. a string value)
  name: string # The name of the settings (e.g. a string value)
  --no-cache: oneof<nothing, bool> # Avoid caching responses (e.g. true)
  path: string # The URL path (e.g. a string value)
  timeout: int # The call timeout (format: int64, e.g. 123)
  --body-url: string # The URL of the server (e.g. a string value)
]: any -> record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client-validators")
  let body = {"alwaysValid": $always_valid, "badTtl": $bad_ttl, "description": $description, "goodTtl": $good_ttl, "headers": $headers, "host": $host, "id": $id, "method": $method, "name": $name, "noCache": $no_cache, "path": $path, "timeout": $timeout, "url": $body_url} | compact
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/client-validators/{id}"))
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/client-validators/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update one validation authorities by id
#
# PATCH /api/client-validators/{id}
# operationId: patchClientValidator
export def "client-validators update-by-id" [
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/client-validators/{id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update one validation authorities by id
#
# PUT /api/client-validators/{id}
# operationId: updateClientValidator
export def "client-validators update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --always-valid: oneof<nothing, bool> # Bypass http calls, every certificates are valids (e.g. true)
  bad_ttl: int # The TTL for invalid access response caching (format: int64, e.g. 123)
  description: string # The description of the settings (e.g. a string value)
  good_ttl: int # The TTL for valid access response caching (format: int64, e.g. 123)
  headers: record # HTTP call headers (e.g. {key: value})
  host: string # The host of the server (e.g. a string value)
  --body-id: string # The id of the settings (e.g. a string value)
  method: string # The HTTP method (e.g. a string value)
  name: string # The name of the settings (e.g. a string value)
  --no-cache: oneof<nothing, bool> # Avoid caching responses (e.g. true)
  path: string # The URL path (e.g. a string value)
  timeout: int # The call timeout (format: int64, e.g. 123)
  --body-url: string # The URL of the server (e.g. a string value)
]: any -> record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/client-validators/{id}"))
  let body = {"alwaysValid": $always_valid, "badTtl": $bad_ttl, "description": $description, "goodTtl": $good_ttl, "headers": $headers, "host": $host, "id": $body_id, "method": $method, "name": $name, "noCache": $no_cache, "path": $path, "timeout": $timeout, "url": $body_url} | compact
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
export def "data-exporter-configs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --buffer-size: int # buffer size (format: int32, e.g. 123123)
  --config: any # Data Exporter config
  --desc: string # Description (e.g. a string value)
  --enabled: string # Boolean (e.g. a string value)
  --filtering: record # shape: {exclude?: list, include?: list}
  --group-duration: int # duration (format: int64, e.g. 123)
  --group-size: int # Group size (format: int32, e.g. 123123)
  --id: string # Id (e.g. a string value)
  --json-workers: int # nb workers (format: int32, e.g. 123123)
  --location: record # shape: {teams: list, tenant: string}
  --metadata: record # Metadata (e.g. {key: value})
  --name: string # Name (e.g. a string value)
  --projection: record # projection (e.g. {key: value})
  --send-workers: int # send workers (format: int32, e.g. 123123)
  --typ: string@typ-completer # Type of data exporter
]: any -> record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-exporter-configs")
  let body = {"bufferSize": $buffer_size, "config": $config, "desc": $desc, "enabled": $enabled, "filtering": $filtering, "groupDuration": $group_duration, "groupSize": $group_size, "id": $id, "jsonWorkers": $json_workers, "location": $location, "metadata": $metadata, "name": $name, "projection": $projection, "sendWorkers": $send_workers, "typ": $typ} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a data exporter config
#
# DELETE /api/data-exporter-configs/_bulk
# operationId: deletebulkDataExporterConfig
export def "data-exporter-configs-bulk delete" [
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
export def "data-exporter-configs-bulk update" [
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
export def "data-exporter-configs-bulk create" [
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
export def "data-exporter-configs-bulk update-1" [
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
export def "data-exporter-configs-template get" [
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
  data_exporter_config_id: string
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
  let full_url = (build-url $base ({data_exporter_config_id: $data_exporter_config_id} | format pattern "/api/data-exporter-configs/{data_exporter_config_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a data exporter config
#
# GET /api/data-exporter-configs/{dataExporterConfigId}
# operationId: findDataExporterConfigById
export def "data-exporter-configs findDataExporterConfigById" [
  data_exporter_config_id: string
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
  let full_url = (build-url $base ({data_exporter_config_id: $data_exporter_config_id} | format pattern "/api/data-exporter-configs/{data_exporter_config_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a data exporter config with a diff
#
# PATCH /api/data-exporter-configs/{dataExporterConfigId}
# operationId: patchDataExporterConfig
export def "data-exporter-configs update-by-dataExporterConfigId" [
  data_exporter_config_id: string
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
  let full_url = (build-url $base ({data_exporter_config_id: $data_exporter_config_id} | format pattern "/api/data-exporter-configs/{data_exporter_config_id}"))
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
export def "data-exporter-configs update-by-dataExporterConfigId-1" [
  data_exporter_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --buffer-size: int # buffer size (format: int32, e.g. 123123)
  --config: any # Data Exporter config
  --desc: string # Description (e.g. a string value)
  --enabled: string # Boolean (e.g. a string value)
  --filtering: record # shape: {exclude?: list, include?: list}
  --group-duration: int # duration (format: int64, e.g. 123)
  --group-size: int # Group size (format: int32, e.g. 123123)
  --id: string # Id (e.g. a string value)
  --json-workers: int # nb workers (format: int32, e.g. 123123)
  --location: record # shape: {teams: list, tenant: string}
  --metadata: record # Metadata (e.g. {key: value})
  --name: string # Name (e.g. a string value)
  --projection: record # projection (e.g. {key: value})
  --send-workers: int # send workers (format: int32, e.g. 123123)
  --typ: string@typ-completer # Type of data exporter
]: any -> record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_exporter_config_id: $data_exporter_config_id} | format pattern "/api/data-exporter-configs/{data_exporter_config_id}"))
  let body = {"bufferSize": $buffer_size, "config": $config, "desc": $desc, "enabled": $enabled, "filtering": $filtering, "groupDuration": $group_duration, "groupSize": $group_size, "id": $id, "jsonWorkers": $json_workers, "location": $location, "metadata": $metadata, "name": $name, "projection": $projection, "sendWorkers": $send_workers, "typ": $typ} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the full configuration of Otoroshi
#
# GET /api/globalconfig
# operationId: globalConfig
export def "globalconfig get" [
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
export def "globalconfig update" [
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
export def "globalconfig update-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alerts_emails: list # Email addresses that will receive all Otoroshi alert events
  alerts_webhooks: list # Webhook that will receive all Otoroshi alert events — item shape: {headers: record, url: string}
  analytics_webhooks: list # Webhook that will receive all internal Otoroshi events — item shape: {headers: record, url: string}
  --api-read-only: oneof<nothing, bool> # If enabled, Admin API won't be able to write/update/delete entities (e.g. true)
  --auto-link-to-default-group: oneof<nothing, bool> # If not defined, every new service descriptor will be added to the default group (e.g. true)
  --backoffice-auth0-config: record # Configuration for Auth0 domain — shape: {callbackUrl: string, clientId: string, clientSecret: string, domain: string}
  --clever-settings: record # Configuration for CleverCloud client — shape: {consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string}
  --elastic-reads-config: record # The configuration for elastic access — shape: {clusterUri: string, headers: record, index: string, password: string, type: string, user: string}
  --elastic-writes-configs: list # Configs. for Elastic writes — item shape: {clusterUri: string, headers: record, index: string, password: string, type: string, user: string}
  endless_ip_addresses: list # IP addresses for which any request to Otoroshi will respond with 128 Gb of zeros
  ip_filtering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list, whitelist: list}
  --limit-concurrent-requests: oneof<nothing, bool> # If enabled, Otoroshi will reject new request if too much at the same time (e.g. true)
  --lines: list # Possibles lines for Otoroshi
  --mailer-settings: record # Configuration for mailgun api client — shape: {apiKey: string, apiKeyPrivate?: string, apiKeyPublic?: string, domain: string, eu?: bool, header?: record, type?: string, url?: string}
  max_concurrent_requests: int # The number of authorized request processed at the same time (format: int64, e.g. 123)
  --max-http10-response-size: int # The max size in bytes of an HTTP 1.0 response (format: int64, e.g. 123)
  --max-logs-size: int # Number of events kept locally (format: int32, e.g. 123123)
  --middle-fingers: oneof<nothing, bool> # Use middle finger emoji as a response character for endless HTTP responses (e.g. true)
  per_ip_throttling_quota: int # Authorized number of calls per second globally per IP address, measured on 10 seconds (format: int64, e.g. 123)
  --private-apps-auth0-config: record # Configuration for Auth0 domain — shape: {callbackUrl: string, clientId: string, clientSecret: string, domain: string}
  --stream-entity-only: oneof<nothing, bool> # HTTP will be streamed only. Doesn't work with old browsers (e.g. true)
  throttling_quota: int # Authorized number of calls per second globally, measured on 10 seconds (format: int64, e.g. 123)
  --u2f-login-only: oneof<nothing, bool> # If enabled, login to backoffice through Auth0 will be disabled (e.g. true)
  --use-circuit-breakers: oneof<nothing, bool> # If enabled, services will be authorized to use circuit breakers (e.g. true)
]: any -> record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/globalconfig")
  let body = {"alertsEmails": $alerts_emails, "alertsWebhooks": $alerts_webhooks, "analyticsWebhooks": $analytics_webhooks, "apiReadOnly": $api_read_only, "autoLinkToDefaultGroup": $auto_link_to_default_group, "backofficeAuth0Config": $backoffice_auth0_config, "cleverSettings": $clever_settings, "elasticReadsConfig": $elastic_reads_config, "elasticWritesConfigs": $elastic_writes_configs, "endlessIpAddresses": $endless_ip_addresses, "ipFiltering": $ip_filtering, "limitConcurrentRequests": $limit_concurrent_requests, "lines": $lines, "mailerSettings": $mailer_settings, "maxConcurrentRequests": $max_concurrent_requests, "maxHttp10ResponseSize": $max_http10_response_size, "maxLogsSize": $max_logs_size, "middleFingers": $middle_fingers, "perIpThrottlingQuota": $per_ip_throttling_quota, "privateAppsAuth0Config": $private_apps_auth0_config, "streamEntityOnly": $stream_entity_only, "throttlingQuota": $throttling_quota, "u2fLoginOnly": $u2f_login_only, "useCircuitBreakers": $use_circuit_breakers} | compact
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
export def "groups create" [
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
  let body = {"description": $description, "id": $id, "name": $name} | compact
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
  group_id: string
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
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/api/groups/{group_id}/apikeys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new api key for a group
#
# POST /api/groups/{groupId}/apikeys
# operationId: createApiKeyFromGroup
export def "groups-apikeys create-api-key-from" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authorized_entities: list # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  client_id: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  client_name: string # The name of the api key, for humans ;-) (e.g. a string value)
  client_secret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --daily-quota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthly-quota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttling-quota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/api/groups/{group_id}/apikeys"))
  let body = {"authorizedEntities": $authorized_entities, "clientId": $client_id, "clientName": $client_name, "clientSecret": $client_secret, "dailyQuota": $daily_quota, "enabled": $enabled, "metadata": $metadata, "monthlyQuota": $monthly_quota, "throttlingQuota": $throttling_quota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an api key
#
# DELETE /api/groups/{groupId}/apikeys/{clientId}
# operationId: deleteApiKeyFromGroup
export def "groups-apikeys delete-api-key-from" [
  group_id: string
  client_id: string
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
  let full_url = (build-url $base ({group_id: $group_id, client_id: $client_id} | format pattern "/api/groups/{group_id}/apikeys/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an api key
#
# GET /api/groups/{groupId}/apikeys/{clientId}
# operationId: apiKeyFromGroup
export def "groups-apikeys apiKeyFromGroup" [
  group_id: string
  client_id: string
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
  let full_url = (build-url $base ({group_id: $group_id, client_id: $client_id} | format pattern "/api/groups/{group_id}/apikeys/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an api key with a diff
#
# PATCH /api/groups/{groupId}/apikeys/{clientId}
# operationId: patchApiKeyFromGroup
export def "groups-apikeys update-api-key-from-by-groupId-clientId" [
  group_id: string
  client_id: string
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
  let full_url = (build-url $base ({group_id: $group_id, client_id: $client_id} | format pattern "/api/groups/{group_id}/apikeys/{client_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an api key
#
# PUT /api/groups/{groupId}/apikeys/{clientId}
# operationId: updateApiKeyFromGroup
export def "groups-apikeys update-api-key-from-by-groupId-clientId-1" [
  group_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authorized_entities: list # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  --body-client-id: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  client_name: string # The name of the api key, for humans ;-) (e.g. a string value)
  client_secret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --daily-quota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthly-quota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttling-quota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id, client_id: $client_id} | format pattern "/api/groups/{group_id}/apikeys/{client_id}"))
  let body = {"authorizedEntities": $authorized_entities, "clientId": $body_client_id, "clientName": $client_name, "clientSecret": $client_secret, "dailyQuota": $daily_quota, "enabled": $enabled, "metadata": $metadata, "monthlyQuota": $monthly_quota, "throttlingQuota": $throttling_quota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset the quota state of an api key
#
# DELETE /api/groups/{groupId}/apikeys/{clientId}/quotas
# operationId: resetApiKeyFromGroupQuotas
export def "groups-apikeys-quotas reset-api-key-from" [
  group_id: string
  client_id: string
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
  let full_url = (build-url $base ({group_id: $group_id, client_id: $client_id} | format pattern "/api/groups/{group_id}/apikeys/{client_id}/quotas"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the quota state of an api key
#
# GET /api/groups/{groupId}/apikeys/{clientId}/quotas
# operationId: apiKeyFromGroupQuotas
export def "groups-apikeys-quotas apiKeyFromGroupQuotas" [
  group_id: string
  client_id: string
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
  let full_url = (build-url $base ({group_id: $group_id, client_id: $client_id} | format pattern "/api/groups/{group_id}/apikeys/{client_id}/quotas"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service group
#
# DELETE /api/groups/{serviceGroupId}
# operationId: deleteGroup
export def "groups delete" [
  service_group_id: string
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
  let full_url = (build-url $base ({service_group_id: $service_group_id} | format pattern "/api/groups/{service_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service group
#
# GET /api/groups/{serviceGroupId}
# operationId: serviceGroup
export def "groups serviceGroup" [
  service_group_id: string
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
  let full_url = (build-url $base ({service_group_id: $service_group_id} | format pattern "/api/groups/{service_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service group with a diff
#
# PATCH /api/groups/{serviceGroupId}
# operationId: patchGroup
export def "groups update-by-serviceGroupId" [
  service_group_id: string
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
  let full_url = (build-url $base ({service_group_id: $service_group_id} | format pattern "/api/groups/{service_group_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a service group
#
# PUT /api/groups/{serviceGroupId}
# operationId: updateGroup
export def "groups update-by-serviceGroupId-1" [
  service_group_id: string
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
  let full_url = (build-url $base ({service_group_id: $service_group_id} | format pattern "/api/groups/{service_group_id}"))
  let body = {"description": $description, "id": $id, "name": $name} | compact
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
  service_group_id: string
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
  let full_url = (build-url $base ({service_group_id: $service_group_id} | format pattern "/api/groups/{service_group_id}/services"))
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
  api_keys: list # Current apik keys at the time of export — item shape: {authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota?: int, enabled: bool, metadata?: record, monthlyQuota?: int, throttlingQuota?: int}
  --app-config: record # Current env variables at the time of export (e.g. {key: value})
  config: record # The global config object of Otoroshi, used to customize settings of the current Otoroshi instance — shape: {alertsEmails: list, alertsWebhooks: list, analyticsWebhooks: list, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config?: record, cleverSettings?: record, elasticReadsConfig?: record, elasticWritesConfigs?: list, endlessIpAddresses: list, ipFiltering: record, limitConcurrentRequests: bool, lines?: list, mailerSettings?: record, maxConcurrentRequests: int, maxHttp10ResponseSize?: int, maxLogsSize?: int, middleFingers?: bool, perIpThrottlingQuota: int, privateAppsAuth0Config?: record, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool}
  date: string # format: date-time, e.g. 2017-07-21T17:32:28Z
  date_raw: int # format: int64, e.g. 123
  error_templates: list # Current error templates at the time of export — item shape: {messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string}
  label: string # e.g. a string value
  service_descriptors: list # Current service descriptors at the time of export — item shape: {Canary?: record, additionalHeaders?: record, api?: record, authConfigRef?: string, buildMode: bool, chaosConfig?: record, clientConfig?: record, clientValidatorRef?: string, cors?: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip?: record, headersVerification?: record, healthCheck?: record, id: string, ipFiltering?: record, jwtVerifier?: any, localHost?: string, localScheme?: string, maintenanceMode: bool, matchingHeaders?: record, matchingRoot?: string, metadata?: record, name: string, overrideHost?: bool, privateApp: bool, privatePatterns?: list, publicPatterns?: list, redirectToLocal?: bool, redirection?: record, root: string, secComExcludedPatterns?: list, secComSettings?: any, sendOtoroshiHeadersBack?: bool, statsdConfig?: record, subdomain: string, targets: list, transformerRef?: string, userFacing?: bool, xForwardedHeaders?: bool}
  service_groups: list # Current service groups at the time of export — item shape: {description?: string, id: string, name: string}
  simple_admins: list # Current simple admins at the time of export — item shape: {createdAt: int, label: string, password: string, username: string}
  stats: record # Global stats for the current Otoroshi instances — shape: {calls: int, dataIn: int, dataOut: int}
]: any -> record<done: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/import")
  let body = {"admins": $admins, "apiKeys": $api_keys, "appConfig": $app_config, "config": $config, "date": $date, "dateRaw": $date_raw, "errorTemplates": $error_templates, "label": $label, "serviceDescriptors": $service_descriptors, "serviceGroups": $service_groups, "simpleAdmins": $simple_admins, "stats": $stats} | compact
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/live/{id}"))
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
  api_keys: list # Current apik keys at the time of export — item shape: {authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota?: int, enabled: bool, metadata?: record, monthlyQuota?: int, throttlingQuota?: int}
  --app-config: record # Current env variables at the time of export (e.g. {key: value})
  config: record # The global config object of Otoroshi, used to customize settings of the current Otoroshi instance — shape: {alertsEmails: list, alertsWebhooks: list, analyticsWebhooks: list, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config?: record, cleverSettings?: record, elasticReadsConfig?: record, elasticWritesConfigs?: list, endlessIpAddresses: list, ipFiltering: record, limitConcurrentRequests: bool, lines?: list, mailerSettings?: record, maxConcurrentRequests: int, maxHttp10ResponseSize?: int, maxLogsSize?: int, middleFingers?: bool, perIpThrottlingQuota: int, privateAppsAuth0Config?: record, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool}
  date: string # format: date-time, e.g. 2017-07-21T17:32:28Z
  date_raw: int # format: int64, e.g. 123
  error_templates: list # Current error templates at the time of export — item shape: {messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string}
  label: string # e.g. a string value
  service_descriptors: list # Current service descriptors at the time of export — item shape: {Canary?: record, additionalHeaders?: record, api?: record, authConfigRef?: string, buildMode: bool, chaosConfig?: record, clientConfig?: record, clientValidatorRef?: string, cors?: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip?: record, headersVerification?: record, healthCheck?: record, id: string, ipFiltering?: record, jwtVerifier?: any, localHost?: string, localScheme?: string, maintenanceMode: bool, matchingHeaders?: record, matchingRoot?: string, metadata?: record, name: string, overrideHost?: bool, privateApp: bool, privatePatterns?: list, publicPatterns?: list, redirectToLocal?: bool, redirection?: record, root: string, secComExcludedPatterns?: list, secComSettings?: any, sendOtoroshiHeadersBack?: bool, statsdConfig?: record, subdomain: string, targets: list, transformerRef?: string, userFacing?: bool, xForwardedHeaders?: bool}
  service_groups: list # Current service groups at the time of export — item shape: {description?: string, id: string, name: string}
  simple_admins: list # Current simple admins at the time of export — item shape: {createdAt: int, label: string, password: string, username: string}
  stats: record # Global stats for the current Otoroshi instances — shape: {calls: int, dataIn: int, dataOut: int}
]: any -> record<done: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/otoroshi.json")
  let body = {"admins": $admins, "apiKeys": $api_keys, "appConfig": $app_config, "config": $config, "date": $date, "dateRaw": $date_raw, "errorTemplates": $error_templates, "label": $label, "serviceDescriptors": $service_descriptors, "serviceGroups": $service_groups, "simpleAdmins": $simple_admins, "stats": $stats} | compact
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
export def "scripts create" [
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
  let body = {"code": $code, "desc": $desc, "id": $id, "name": $name} | compact
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
  let body = {"code": $code, "desc": $desc, "id": $id, "name": $name} | compact
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
  script_id: string
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
  let full_url = (build-url $base ({script_id: $script_id} | format pattern "/api/scripts/{script_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a script
#
# GET /api/scripts/{scriptId}
# operationId: findScriptById
export def "scripts findScriptById" [
  script_id: string
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
  let full_url = (build-url $base ({script_id: $script_id} | format pattern "/api/scripts/{script_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a script with a diff
#
# PATCH /api/scripts/{scriptId}
# operationId: patchScript
export def "scripts update-by-scriptId" [
  script_id: string
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
  let full_url = (build-url $base ({script_id: $script_id} | format pattern "/api/scripts/{script_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a script
#
# PUT /api/scripts/{scriptId}
# operationId: updateScript
export def "scripts update-by-scriptId-1" [
  script_id: string
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
  let full_url = (build-url $base ({script_id: $script_id} | format pattern "/api/scripts/{script_id}"))
  let body = {"code": $code, "desc": $desc, "id": $id, "name": $name} | compact
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
export def "services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --canary: record # The configuration of the canary mode for a service descriptor — shape: {enabled: bool, root: string, targets: list, traffic: int}
  --additional-headers: record # Specify headers that will be added to each client request. Useful to add authentication (e.g. {key: value})
  --api: record # The Open API configuration for your service (if one) — shape: {exposeApi: bool, openApiDescriptorUrl?: string}
  --auth-config-ref: string # A reference to a global auth module config (e.g. a string value)
  --build-mode: oneof<nothing, bool> # Display a construction page when a user try to use the service (e.g. true)
  --chaos-config: record # Configuration for the faults that can be injected in requests — shape: {badResponsesFaultConfig?: record, enabled: bool, largeRequestFaultConfig?: record, largeResponseFaultConfig?: record, latencyInjectionFaultConfig?: record}
  --client-config: record # The configuration of the circuit breaker for a service descriptor — shape: {backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool}
  --client-validator-ref: string # A reference to validation authority (e.g. a string value)
  --cors: record # The configuration for cors support — shape: {allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int}
  domain: string # The domain on which the service is available. (e.g. a string value)
  --enabled: oneof<nothing, bool> # Activate or deactivate your service. Once disabled, users will get an error page saying the service does not exist (e.g. true)
  --enforce-secure-communication: oneof<nothing, bool> # When enabled, Otoroshi will try to exchange headers with downstream service to ensure no one else can use the service from outside (e.g. true)
  --body-env: string # The line on which the service is available. Based on that value, the name of the line will be appended to the subdomain. For line prod, nothing will be appended. For example, if the subdomain is 'foo' and line is 'preprod', then the exposed service will be available at 'foo.preprod.mydomain' (e.g. a string value)
  --force-https: oneof<nothing, bool> # Will force redirection to https:// if not present (e.g. true)
  groups: list # Each service descriptor is attached to groups. A group can have one or more services. Each API key is linked to a group and allow access to every service in the group (e.g. [a string value])
  --gzip: record # Configuration for gzip of service responses — shape: {blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list}
  --headers-verification: record # Specify headers that will be verified after routing. (e.g. {key: value})
  --health-check: record # The configuration for checking health of a service. Otoroshi will perform GET call on the URL to check if the service is still alive — shape: {enabled: bool, url?: string}
  id: string # A unique random string to identify your service (format: uuid, e.g. 110e8400-e29b-11d4-a716-446655440000)
  --ip-filtering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list, whitelist: list}
  --jwt-verifier: any
  --local-host: string # The host used localy, mainly localhost:xxxx (e.g. a string value)
  --local-scheme: string # The scheme used localy, mainly http (e.g. a string value)
  --maintenance-mode: oneof<nothing, bool> # Display a maintainance page when a user try to use the service (e.g. true)
  --matching-headers: record # Specify headers that MUST be present on client request to route it. Useful to implement versioning (e.g. {key: value})
  --matching-root: string # The root path on which the service is available (e.g. a string value)
  --metadata: record # Just a bunch of random properties (e.g. {key: value})
  name: string # The name of your service. Only for debug and human readability purposes (e.g. a string value)
  --override-host: oneof<nothing, bool> # Host header will be overriden with Host of the target (e.g. true)
  --private-app: oneof<nothing, bool> # When enabled, user will be allowed to use the service (UI) only if they are registered users of the private apps domain (e.g. true)
  --private-patterns: list # If you define a public pattern that is a little bit too much, you can make some of public URL private again
  --public-patterns: list # By default, every services are private only and you'll need an API key to access it. However, if you want to expose a public UI, you can define one or more public patterns (regex) to allow access to anybody. For example if you want to allow anybody on any URL, just use '/.*'
  --redirect-to-local: oneof<nothing, bool> # If you work locally with Otoroshi, you may want to use that feature to redirect one particuliar service to a local host. For example, you can relocate https://foo.preprod.bar.com to http://localhost:8080 to make some tests (e.g. true)
  --redirection: record # The configuration for redirection per service — shape: {code: int, enabled: bool, to: string}
  root: string # Otoroshi will append this root to any target choosen. If the specified root is '/api/foo', then a request to https://yyyyyyy/bar will actually hit https://xxxxxxxxx/api/foo/bar (e.g. a string value)
  --sec-com-excluded-patterns: list # URI patterns excluded from secured communications
  --sec-com-settings: any
  --send-otoroshi-headers-back: oneof<nothing, bool> # When enabled, Otoroshi will send headers to consumer like request id, client latency, overhead, etc ... (e.g. true)
  --statsd-config: record # The configuration for statsd metrics push — shape: {datadog: bool, host: string, port: int}
  subdomain: string # The subdomain on which the service is available (e.g. a string value)
  targets: list # The list of target that Otoroshi will proxy and expose through the subdomain defined before. Otoroshi will do round-robin load balancing between all those targets with circuit breaker mecanism to avoid cascading failures — item shape: {host: string, scheme: string}
  --transformer-ref: string # A reference to a request transformer (e.g. a string value)
  --user-facing: oneof<nothing, bool> # The fact that this service will be seen by users and cannot be impacted by the Snow Monkey (e.g. true)
  --x-forwarded-headers: oneof<nothing, bool> # Send X-Forwarded-* headers (e.g. true)
]: any -> record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/services")
  let body = {"Canary": $canary, "additionalHeaders": $additional_headers, "api": $api, "authConfigRef": $auth_config_ref, "buildMode": $build_mode, "chaosConfig": $chaos_config, "clientConfig": $client_config, "clientValidatorRef": $client_validator_ref, "cors": $cors, "domain": $domain, "enabled": $enabled, "enforceSecureCommunication": $enforce_secure_communication, "env": $body_env, "forceHttps": $force_https, "groups": $groups, "gzip": $gzip, "headersVerification": $headers_verification, "healthCheck": $health_check, "id": $id, "ipFiltering": $ip_filtering, "jwtVerifier": $jwt_verifier, "localHost": $local_host, "localScheme": $local_scheme, "maintenanceMode": $maintenance_mode, "matchingHeaders": $matching_headers, "matchingRoot": $matching_root, "metadata": $metadata, "name": $name, "overrideHost": $override_host, "privateApp": $private_app, "privatePatterns": $private_patterns, "publicPatterns": $public_patterns, "redirectToLocal": $redirect_to_local, "redirection": $redirection, "root": $root, "secComExcludedPatterns": $sec_com_excluded_patterns, "secComSettings": $sec_com_settings, "sendOtoroshiHeadersBack": $send_otoroshi_headers_back, "statsdConfig": $statsd_config, "subdomain": $subdomain, "targets": $targets, "transformerRef": $transformer_ref, "userFacing": $user_facing, "xForwardedHeaders": $x_forwarded_headers} | compact
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
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service descriptor
#
# GET /api/services/{serviceId}
# operationId: service
export def "services service" [
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service descriptor with a diff
#
# PATCH /api/services/{serviceId}
# operationId: patchService
export def "services update-by-serviceId" [
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}"))
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
export def "services update-by-serviceId-1" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --canary: record # The configuration of the canary mode for a service descriptor — shape: {enabled: bool, root: string, targets: list, traffic: int}
  --additional-headers: record # Specify headers that will be added to each client request. Useful to add authentication (e.g. {key: value})
  --api: record # The Open API configuration for your service (if one) — shape: {exposeApi: bool, openApiDescriptorUrl?: string}
  --auth-config-ref: string # A reference to a global auth module config (e.g. a string value)
  --build-mode: oneof<nothing, bool> # Display a construction page when a user try to use the service (e.g. true)
  --chaos-config: record # Configuration for the faults that can be injected in requests — shape: {badResponsesFaultConfig?: record, enabled: bool, largeRequestFaultConfig?: record, largeResponseFaultConfig?: record, latencyInjectionFaultConfig?: record}
  --client-config: record # The configuration of the circuit breaker for a service descriptor — shape: {backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool}
  --client-validator-ref: string # A reference to validation authority (e.g. a string value)
  --cors: record # The configuration for cors support — shape: {allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int}
  domain: string # The domain on which the service is available. (e.g. a string value)
  --enabled: oneof<nothing, bool> # Activate or deactivate your service. Once disabled, users will get an error page saying the service does not exist (e.g. true)
  --enforce-secure-communication: oneof<nothing, bool> # When enabled, Otoroshi will try to exchange headers with downstream service to ensure no one else can use the service from outside (e.g. true)
  --body-env: string # The line on which the service is available. Based on that value, the name of the line will be appended to the subdomain. For line prod, nothing will be appended. For example, if the subdomain is 'foo' and line is 'preprod', then the exposed service will be available at 'foo.preprod.mydomain' (e.g. a string value)
  --force-https: oneof<nothing, bool> # Will force redirection to https:// if not present (e.g. true)
  groups: list # Each service descriptor is attached to groups. A group can have one or more services. Each API key is linked to a group and allow access to every service in the group (e.g. [a string value])
  --gzip: record # Configuration for gzip of service responses — shape: {blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list}
  --headers-verification: record # Specify headers that will be verified after routing. (e.g. {key: value})
  --health-check: record # The configuration for checking health of a service. Otoroshi will perform GET call on the URL to check if the service is still alive — shape: {enabled: bool, url?: string}
  id: string # A unique random string to identify your service (format: uuid, e.g. 110e8400-e29b-11d4-a716-446655440000)
  --ip-filtering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list, whitelist: list}
  --jwt-verifier: any
  --local-host: string # The host used localy, mainly localhost:xxxx (e.g. a string value)
  --local-scheme: string # The scheme used localy, mainly http (e.g. a string value)
  --maintenance-mode: oneof<nothing, bool> # Display a maintainance page when a user try to use the service (e.g. true)
  --matching-headers: record # Specify headers that MUST be present on client request to route it. Useful to implement versioning (e.g. {key: value})
  --matching-root: string # The root path on which the service is available (e.g. a string value)
  --metadata: record # Just a bunch of random properties (e.g. {key: value})
  name: string # The name of your service. Only for debug and human readability purposes (e.g. a string value)
  --override-host: oneof<nothing, bool> # Host header will be overriden with Host of the target (e.g. true)
  --private-app: oneof<nothing, bool> # When enabled, user will be allowed to use the service (UI) only if they are registered users of the private apps domain (e.g. true)
  --private-patterns: list # If you define a public pattern that is a little bit too much, you can make some of public URL private again
  --public-patterns: list # By default, every services are private only and you'll need an API key to access it. However, if you want to expose a public UI, you can define one or more public patterns (regex) to allow access to anybody. For example if you want to allow anybody on any URL, just use '/.*'
  --redirect-to-local: oneof<nothing, bool> # If you work locally with Otoroshi, you may want to use that feature to redirect one particuliar service to a local host. For example, you can relocate https://foo.preprod.bar.com to http://localhost:8080 to make some tests (e.g. true)
  --redirection: record # The configuration for redirection per service — shape: {code: int, enabled: bool, to: string}
  root: string # Otoroshi will append this root to any target choosen. If the specified root is '/api/foo', then a request to https://yyyyyyy/bar will actually hit https://xxxxxxxxx/api/foo/bar (e.g. a string value)
  --sec-com-excluded-patterns: list # URI patterns excluded from secured communications
  --sec-com-settings: any
  --send-otoroshi-headers-back: oneof<nothing, bool> # When enabled, Otoroshi will send headers to consumer like request id, client latency, overhead, etc ... (e.g. true)
  --statsd-config: record # The configuration for statsd metrics push — shape: {datadog: bool, host: string, port: int}
  subdomain: string # The subdomain on which the service is available (e.g. a string value)
  targets: list # The list of target that Otoroshi will proxy and expose through the subdomain defined before. Otoroshi will do round-robin load balancing between all those targets with circuit breaker mecanism to avoid cascading failures — item shape: {host: string, scheme: string}
  --transformer-ref: string # A reference to a request transformer (e.g. a string value)
  --user-facing: oneof<nothing, bool> # The fact that this service will be seen by users and cannot be impacted by the Snow Monkey (e.g. true)
  --x-forwarded-headers: oneof<nothing, bool> # Send X-Forwarded-* headers (e.g. true)
]: any -> record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}"))
  let body = {"Canary": $canary, "additionalHeaders": $additional_headers, "api": $api, "authConfigRef": $auth_config_ref, "buildMode": $build_mode, "chaosConfig": $chaos_config, "clientConfig": $client_config, "clientValidatorRef": $client_validator_ref, "cors": $cors, "domain": $domain, "enabled": $enabled, "enforceSecureCommunication": $enforce_secure_communication, "env": $body_env, "forceHttps": $force_https, "groups": $groups, "gzip": $gzip, "headersVerification": $headers_verification, "healthCheck": $health_check, "id": $id, "ipFiltering": $ip_filtering, "jwtVerifier": $jwt_verifier, "localHost": $local_host, "localScheme": $local_scheme, "maintenanceMode": $maintenance_mode, "matchingHeaders": $matching_headers, "matchingRoot": $matching_root, "metadata": $metadata, "name": $name, "overrideHost": $override_host, "privateApp": $private_app, "privatePatterns": $private_patterns, "publicPatterns": $public_patterns, "redirectToLocal": $redirect_to_local, "redirection": $redirection, "root": $root, "secComExcludedPatterns": $sec_com_excluded_patterns, "secComSettings": $sec_com_settings, "sendOtoroshiHeadersBack": $send_otoroshi_headers_back, "statsdConfig": $statsd_config, "subdomain": $subdomain, "targets": $targets, "transformerRef": $transformer_ref, "userFacing": $user_facing, "xForwardedHeaders": $x_forwarded_headers} | compact
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
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/apikeys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new api key for a service
#
# POST /api/services/{serviceId}/apikeys
# operationId: createApiKey
export def "services-apikeys create" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authorized_entities: list # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  client_id: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  client_name: string # The name of the api key, for humans ;-) (e.g. a string value)
  client_secret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --daily-quota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthly-quota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttling-quota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/apikeys"))
  let body = {"authorizedEntities": $authorized_entities, "clientId": $client_id, "clientName": $client_name, "clientSecret": $client_secret, "dailyQuota": $daily_quota, "enabled": $enabled, "metadata": $metadata, "monthlyQuota": $monthly_quota, "throttlingQuota": $throttling_quota} | compact
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
  service_id: string
  client_id: string
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
  let full_url = (build-url $base ({service_id: $service_id, client_id: $client_id} | format pattern "/api/services/{service_id}/apikeys/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an api key
#
# GET /api/services/{serviceId}/apikeys/{clientId}
# operationId: apiKey
export def "services-apikeys apiKey" [
  service_id: string
  client_id: string
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
  let full_url = (build-url $base ({service_id: $service_id, client_id: $client_id} | format pattern "/api/services/{service_id}/apikeys/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an api key with a diff
#
# PATCH /api/services/{serviceId}/apikeys/{clientId}
# operationId: patchApiKey
export def "services-apikeys update-by-serviceId-clientId" [
  service_id: string
  client_id: string
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
  let full_url = (build-url $base ({service_id: $service_id, client_id: $client_id} | format pattern "/api/services/{service_id}/apikeys/{client_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an api key
#
# PUT /api/services/{serviceId}/apikeys/{clientId}
# operationId: updateApiKey
export def "services-apikeys update-by-serviceId-clientId-1" [
  service_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authorized_entities: list # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  --body-client-id: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  client_name: string # The name of the api key, for humans ;-) (e.g. a string value)
  client_secret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --daily-quota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthly-quota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttling-quota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id, client_id: $client_id} | format pattern "/api/services/{service_id}/apikeys/{client_id}"))
  let body = {"authorizedEntities": $authorized_entities, "clientId": $body_client_id, "clientName": $client_name, "clientSecret": $client_secret, "dailyQuota": $daily_quota, "enabled": $enabled, "metadata": $metadata, "monthlyQuota": $monthly_quota, "throttlingQuota": $throttling_quota} | compact
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
  service_id: string
  client_id: string
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
  let full_url = (build-url $base ({service_id: $service_id, client_id: $client_id} | format pattern "/api/services/{service_id}/apikeys/{client_id}/group"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset the quota state of an api key
#
# DELETE /api/services/{serviceId}/apikeys/{clientId}/quotas
# operationId: resetApiKeyQuotas
export def "services-apikeys-quotas reset" [
  service_id: string
  client_id: string
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
  let full_url = (build-url $base ({service_id: $service_id, client_id: $client_id} | format pattern "/api/services/{service_id}/apikeys/{client_id}/quotas"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the quota state of an api key
#
# GET /api/services/{serviceId}/apikeys/{clientId}/quotas
# operationId: apiKeyQuotas
export def "services-apikeys-quotas apiKeyQuotas" [
  service_id: string
  client_id: string
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
  let full_url = (build-url $base ({service_id: $service_id, client_id: $client_id} | format pattern "/api/services/{service_id}/apikeys/{client_id}/quotas"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service descriptor target
#
# DELETE /api/services/{serviceId}/targets
# operationId: serviceDeleteTarget
export def "services-targets serviceDeleteTarget" [
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/targets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service descriptor targets
#
# GET /api/services/{serviceId}/targets
# operationId: serviceTargets
export def "services-targets serviceTargets" [
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/targets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service descriptor targets
#
# PATCH /api/services/{serviceId}/targets
# operationId: updateServiceTargets
export def "services-targets update" [
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/targets"))
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
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/targets"))
  let body = {"host": $host, "scheme": $scheme} | compact
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
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/template"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a service descriptor error template
#
# GET /api/services/{serviceId}/template
# operationId: serviceTemplate
export def "services-template serviceTemplate" [
  service_id: string
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
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/template"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a service descriptor error template
#
# POST /api/services/{serviceId}/template
# operationId: createServiceTemplate
export def "services-template create" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  messages: record # Map for custom messages (e.g. {key: value})
  --body-service-id: string # The Id of the service for which the error template is enabled (e.g. a string value)
  template40x: string # The html template for 40x errors (e.g. a string value)
  template50x: string # The html template for 50x errors (e.g. a string value)
  template_build: string # The html template for build page (e.g. a string value)
  template_maintenance: string # The html template for maintenance page (e.g. a string value)
]: any -> record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/template"))
  let body = {"messages": $messages, "serviceId": $body_service_id, "template40x": $template40x, "template50x": $template50x, "templateBuild": $template_build, "templateMaintenance": $template_maintenance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an error template to a service descriptor
#
# PUT /api/services/{serviceId}/template
# operationId: updateServiceTemplate
export def "services-template update" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  messages: record # Map for custom messages (e.g. {key: value})
  --body-service-id: string # The Id of the service for which the error template is enabled (e.g. a string value)
  template40x: string # The html template for 40x errors (e.g. a string value)
  template50x: string # The html template for 50x errors (e.g. a string value)
  template_build: string # The html template for build page (e.g. a string value)
  template_maintenance: string # The html template for maintenance page (e.g. a string value)
]: any -> record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/api/services/{service_id}/template"))
  let body = {"messages": $messages, "serviceId": $body_service_id, "template40x": $template40x, "template50x": $template50x, "templateBuild": $template_build, "templateMaintenance": $template_maintenance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start the Snow Monkey
#
# POST /api/snowmonkey/_start
# operationId: startSnowMonkey
export def "snowmonkey-start start" [
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
export def "snowmonkey-stop stop" [
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
export def "snowmonkey-config update" [
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
  let body = {"description": $description, "id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update current Snow Monkey config
#
# PUT /api/snowmonkey/config
# operationId: updateSnowMonkey
export def "snowmonkey-config update-1" [
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
  let body = {"description": $description, "id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset Snow Monkey Outages for the day
#
# DELETE /api/snowmonkey/outages
# operationId: resetSnowMonkey
export def "snowmonkey-outages reset" [
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
export def "verifiers create-global-jwt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  algo_settings: any
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
  let body = {"algoSettings": $algo_settings, "desc": $desc, "enabled": $enabled, "id": $id, "name": $name, "source": $body_source, "strategy": $strategy, "strict": $strict} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete one global JWT verifiers
#
# DELETE /api/verifiers/{verifierId}
# operationId: deleteGlobalJwtVerifier
export def "verifiers delete-global-jwt" [
  verifier_id: string
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
  let full_url = (build-url $base ({verifier_id: $verifier_id} | format pattern "/api/verifiers/{verifier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one global JWT verifiers
#
# GET /api/verifiers/{verifierId}
# operationId: findGlobalJwtVerifiersById
export def "verifiers findGlobalJwtVerifiersById" [
  verifier_id: string
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
  let full_url = (build-url $base ({verifier_id: $verifier_id} | format pattern "/api/verifiers/{verifier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update one global JWT verifiers
#
# PATCH /api/verifiers/{verifierId}
# operationId: patchGlobalJwtVerifier
export def "verifiers update-global-jwt-by-verifierId" [
  verifier_id: string
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
  let full_url = (build-url $base ({verifier_id: $verifier_id} | format pattern "/api/verifiers/{verifier_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update one global JWT verifiers
#
# PUT /api/verifiers/{verifierId}
# operationId: updateGlobalJwtVerifier
export def "verifiers update-global-jwt-by-verifierId-1" [
  verifier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  algo_settings: any
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
  let full_url = (build-url $base ({verifier_id: $verifier_id} | format pattern "/api/verifiers/{verifier_id}"))
  let body = {"algoSettings": $algo_settings, "desc": $desc, "enabled": $enabled, "id": $id, "name": $name, "source": $body_source, "strategy": $strategy, "strict": $strict} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return current Otoroshi health
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
  let full_url = (build-url $base ({line: $line} | format pattern "/lines/{line}/services"))
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
